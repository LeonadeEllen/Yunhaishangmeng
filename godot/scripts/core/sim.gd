class_name Sim
extends RefCounted
## Whole-game simulation. Pure logic: no nodes, so it runs headless in tests.
## All state lives in `s` (JSON-safe Dictionary) so save/load is a straight dump.

signal message(text: String, kind: String)     # kind: info / good / bad / major
signal game_over(result: Dictionary)


const NEUTRAL_EQ := 180.0
const REVERT := 0.06
const MAKE_EQ := 2.0
const WANT_EQ := 0.45
const EQ_NEUTRAL := 150.0                  # a good nobody here makes or craves
const EQ_SCARCE := [0.0, 150.0, 25.0, 6.0]  # per tier, for goods no city makes naturally: only players supply them

var s: Dictionary = {}
var rng := RandomNumberGenerator.new()


# ---------------------------------------------------------------- setup

func pid() -> String:
	return s.get("player", "lamp")


func perk(hid: String) -> String:
	return GameData.HOUSES[hid].get("perk", "")


func rep_level(hid: String = "") -> int:
	if hid == "":
		hid = pid()
	return GameData.rep_level(int(house(hid)["rep"]))


func add_rep(hid: String, pts: int) -> void:
	if pts <= 0:
		return
	var h := house(hid)
	var before := GameData.rep_level(int(h["rep"]))
	h["rep"] = int(h["rep"]) + pts
	var after := GameData.rep_level(int(h["rep"]))
	if after > before:
		if hid == pid():
			_say("名声提升：你的商会升为「%s」。%s。" % [GameData.REP_NAMES[after - 1], GameData.REP_UNLOCK[after - 1]], "major")
		else:
			_say("%s 升为「%s」。" % [GameData.HOUSES[hid]["name"], GameData.REP_NAMES[after - 1]], "rival")


func friend_pts(port: String, hid: String = "") -> int:
	if hid == "":
		hid = pid()
	return int(s["ports"][port]["friend"].get(hid, 0))


func friend_level(port: String, hid: String = "") -> int:
	return GameData.friend_level(friend_pts(port, hid))


func add_friend(port: String, hid: String, pts: int) -> void:
	if pts <= 0:
		return
	var f: Dictionary = s["ports"][port]["friend"]
	var before := GameData.friend_level(int(f.get(hid, 0)))
	if hid == pid():
		pts = int(ceil(float(pts) * (1.0 + 0.1 * float(hero_abil("charm") - 1))))
	f[hid] = int(f.get(hid, 0)) + pts
	var after := GameData.friend_level(int(f[hid]))
	if after > before and hid == pid():
		_say("%s 对你的看法变为「%s」。" % [GameData.port_name(port), GameData.FRIEND_NAMES[after]], "good")


# ------------------------------------------------------------------ protagonist
func hero() -> Dictionary:
	return s["hero"]


func hero_abil(k: String) -> int:
	return int(s["hero"]["abil"].get(k, 1))


## Experience from trading, sailing, contracts and building. Levels grant one ability point.
func add_exp(n: int) -> void:
	if n <= 0:
		return
	var h: Dictionary = s["hero"]
	h["exp"] = int(h["exp"]) + int(roundf(float(n) * (1.0 + 0.1 * spec_bonus("research"))))
	while int(h["lvl"]) < GameData.HERO_MAX_LVL and int(h["exp"]) >= GameData.hero_exp_needed(int(h["lvl"])):
		h["exp"] = int(h["exp"]) - GameData.hero_exp_needed(int(h["lvl"]))
		h["lvl"] = int(h["lvl"]) + 1
		h["pts"] = int(h["pts"]) + 1
		_say("%s 升到 %d 级，获得 1 点能力点。" % [GameData.HOUSES[pid()]["leader"], int(h["lvl"])], "good")


func spend_hero_pt(k: String) -> Dictionary:
	var h: Dictionary = s["hero"]
	if int(h["pts"]) <= 0:
		return _fail("没有可用的能力点。")
	if not GameData.HERO_ABIL.has(k):
		return _fail("没有这项能力。")
	if int(h["abil"][k]) >= GameData.HERO_MAX_ABIL:
		return _fail("这项能力已经满级。")
	h["pts"] = int(h["pts"]) - 1
	h["abil"][k] = int(h["abil"][k]) + 1
	return {"ok": true, "msg": "%s提升到 %d。" % [GameData.HERO_ABIL_NAMES[k], int(h["abil"][k])]}


## Travel time for a house's ship; the protagonist's seamanship shortens the player's voyages.
func travel_days(from: String, to: String, type: String, hid: String = "", sh: Dictionary = {}) -> int:
	if hid == "":
		hid = pid()
	var d := float(GameData.travel_days(from, to, type))
	if not sh.is_empty():
		d /= speed_mult(sh)
	if hid == pid():
		d *= 1.0 - 0.03 * float(hero_abil("sail") - 1)
		d *= (1.0 - 0.01 * float(post_level("nav"))) * (1.0 - 0.03 * spec_bonus("fog_nav")) * (1.0 - 0.05 * spec_bonus("survey"))
	d *= GameData.wind_factor(from, to, int(s.get("day", 0)))
	return maxi(1, int(roundf(d)))


## Days for a specific ship (its refits count); a flagship moves at its slowest escort's pace.
func ship_days(sh: Dictionary, to: String) -> int:
	var d := 0
	for o in fleet_ships(sh):
		d = maxi(d, travel_days(o["port"], to, o["type"], o["owner"], o))
	return d


func has_bp(good: String, hid: String = "") -> bool:
	if hid == "":
		hid = pid()
	return house(hid)["bp"].has(good)


func max_ships(hid: String = "") -> int:
	if hid == "":
		hid = pid()
	return mini(GameData.MAX_SHIPS, GameData.REP_MAX_SHIPS[rep_level(hid) - 1])


func new_game(seed_value: int = 0, player: String = "lamp", difficulty: int = 1) -> void:
	if seed_value == 0:
		seed_value = int(Time.get_unix_time_from_system())
	rng.seed = seed_value
	s = {
		"seed": seed_value, "day": 0, "over": null, "next_ship_id": 1,
		"ports": {}, "houses": {}, "ships": [], "intel": {}, "log": [],
		"event": null, "story": 0, "stats": {"trades": 0, "profit": 0, "best_trade": 0, "handled": {}, "contracts": 0},
		"crown": null,
		"hero": {"lvl": 1, "exp": 0, "pts": 0, "abil": {"sail": 1, "trade": 1, "fight": 1, "charm": 1}, "days_sailed": 0, "visited": {}},
		"tutorial": 0, "player": player, "fashion": null, "difficulty": difficulty,
		"contracts": [], "next_contract_id": 1,
		"encounter": null, "battle": null, "battle_result": null,
		"crew": {}, "roam": {"port": "", "until": 0},
	}
	for pid in GameData.PORT_IDS:
		var p: Dictionary = GameData.PORTS[pid]
		var m := {}
		for g in GameData.GOOD_IDS:
			var eq := EQ_NEUTRAL
			if GameData.GOODS[g]["home"] == "":
				eq = EQ_SCARCE[GameData.tier(g)]
			if g in p["make"]:
				eq = NEUTRAL_EQ * MAKE_EQ
			elif g in p["want"]:
				eq *= WANT_EQ
			if g in p["make"] or g in p["want"]:
				eq *= rng.randf_range(0.8, 1.25)   # every run has its own strong and weak routes
			m[g] = {"stock": eq * rng.randf_range(0.85, 1.15), "eq": eq}
		s["ports"][pid] = {"market": m, "friend": {}}
		Industry.init_port(self, pid)
	for hid in GameData.HOUSE_IDS:
		var h: Dictionary = GameData.HOUSES[hid]
		s["houses"][hid] = {
			"gold": float(h["gold"]), "debt": 0.0, "crisis": 0, "bankrupt": false,
			"lh": {"stage": 0, "building": false, "end": 0, "mats": {}},
			"month_in": 0.0, "month_out": 0.0, "last_net": 0.0,
			"rep": 0, "bp": {},
		}
		_add_ship(hid, "freighter", h["home"], "飞云号" if hid == pid() else "")
		Industry.open_wh(self, h["home"], hid, true)
		if hid != pid():
			for g in GameData.PORTS[h["home"]]["make"]:
				s["houses"][hid]["bp"][g] = true   # rivals start with their home city's deeds
	for pid in GameData.PORT_IDS:
		s["intel"][pid] = null
	_update_intel(GameData.HOUSES[pid()]["home"])


func _add_ship(hid: String, type: String, port: String, ship_name: String = "") -> Dictionary:
	var id: int = s["next_ship_id"]
	s["next_ship_id"] = id + 1
	if ship_name == "":
		ship_name = ["飞云号", "逐霞号", "听风号", "鸣鹤号", "望舒号", "长庚号", "照夜号", "揽月号"][id % 8]
	var sh := {
		"id": id, "owner": hid, "type": type, "name": ship_name, "port": port,
		"from": port, "to": "", "depart": 0, "arrive": 0, "cargo": {}, "route": null,
		"flagship": hid == pid() and _ships_of(hid).is_empty(),
		"mods": {"hull": 0, "sail": 0, "hold": 0, "guns": 0}, "fleet": 0, "slot": "main", "dmg": 0,
	}
	s["ships"].append(sh)
	return sh


# ---------------------------------------------------------------- queries

func house(hid: String = "") -> Dictionary:
	if hid == "":
		hid = pid()
	return s["houses"][hid]


func ship(id: int) -> Dictionary:
	for sh in s["ships"]:
		if sh["id"] == id:
			return sh
	return {}


func _ships_of(hid: String) -> Array:
	return s["ships"].filter(func(x): return x["owner"] == hid)


func ships_of(hid: String = "") -> Array:
	if hid == "":
		hid = pid()
	return _ships_of(hid)


func flagship() -> Dictionary:
	for sh in _ships_of(pid()):
		if sh["flagship"]:
			return sh
	var all := _ships_of(pid())
	return all[0] if not all.is_empty() else {}


func docked(sh: Dictionary) -> bool:
	return sh["to"] == ""


func cargo_used(sh: Dictionary) -> int:
	var n := 0
	for g in sh["cargo"]:
		n += int(sh["cargo"][g]["qty"])
	return n


func cargo_cap(sh: Dictionary) -> int:
	var base := float(GameData.SHIPS[sh["type"]]["cargo"])
	return int(roundf(base * (1.0 + 0.15 * float(sh.get("mods", {}).get("hold", 0)))))


func mod_lvl(sh: Dictionary, k: String) -> int:
	return int(sh.get("mods", {}).get(k, 0))


## Speed multiplier from refits: sails help, the first hold extension drags.
func speed_mult(sh: Dictionary) -> float:
	var cap := 1.0
	if sh["owner"] == pid():
		cap += 0.015 * float(captain_level(int(sh["id"])))
	return cap * _speed_mult_base(sh)


func _speed_mult_base(sh: Dictionary) -> float:
	return (1.0 + 0.1 * float(mod_lvl(sh, "sail"))) * (0.92 if mod_lvl(sh, "hold") > 0 else 1.0)


# ------------------------------------------------------------------ fleet (escorts sail with the flagship)
## The flagship plus every escort attached to it; a lone ship is a fleet of one.
func fleet_ships(sh: Dictionary) -> Array:
	if sh.is_empty():
		return []
	if not sh.get("flagship", false):
		return [sh]
	var out := [sh]
	for o in _ships_of(sh["owner"]):
		if int(o.get("fleet", 0)) == int(sh["id"]) and o["id"] != sh["id"]:
			out.append(o)
	return out


func fleet_cargo_used(sh: Dictionary) -> int:
	var n := 0
	for o in fleet_ships(sh):
		n += cargo_used(o)
	return n


func fleet_cargo_cap(sh: Dictionary) -> int:
	var n := 0
	for o in fleet_ships(sh):
		n += cargo_cap(o)
	return n


## Merged hold of a fleet: {good: {qty, cost}} with cost averaged across ships.
func fleet_cargo(sh: Dictionary) -> Dictionary:
	var out := {}
	for o in fleet_ships(sh):
		for g in o["cargo"]:
			var c: Dictionary = o["cargo"][g]
			var e: Dictionary = out.get(g, {"qty": 0, "cost": 0.0})
			var total: float = float(e["qty"]) * float(e["cost"]) + float(c["qty"]) * float(c["cost"])
			e["qty"] = int(e["qty"]) + int(c["qty"])
			e["cost"] = total / float(e["qty"])
			out[g] = e
	return out


func in_fleet(sh: Dictionary) -> bool:
	return int(sh.get("fleet", 0)) != 0


func join_fleet(ship_id: int) -> Dictionary:
	var sh := ship(ship_id)
	var fl := flagship()
	if sh.is_empty() or fl.is_empty() or sh["owner"] != pid() or sh["flagship"]:
		return _fail("无效飞艇。")
	if not docked(sh) or not docked(fl) or sh["port"] != fl["port"]:
		return _fail("这艘船要和旗舰停在同一座港口。")
	if sh["route"] != null:
		return _fail("先清除它的自动航线。")
	if fleet_ships(fl).size() >= GameData.FLEET_MAX:
		return _fail("一支船队最多 %d 艘。" % GameData.FLEET_MAX)
	sh["fleet"] = int(fl["id"])
	if not sh.has("slot"):
		sh["slot"] = "main"
	return {"ok": true, "msg": "%s 加入旗舰队。" % sh["name"]}


func leave_fleet(ship_id: int) -> Dictionary:
	var sh := ship(ship_id)
	if sh.is_empty() or not in_fleet(sh):
		return _fail("这艘船不在船队里。")
	if not docked(sh):
		return _fail("航行中不能脱队。")
	sh["fleet"] = 0
	return {"ok": true, "msg": "%s 脱离船队。" % sh["name"]}


func set_slot(ship_id: int, slot: String) -> Dictionary:
	var sh := ship(ship_id)
	if sh.is_empty() or not GameData.SLOTS.has(slot):
		return _fail("无效编队位置。")
	sh["slot"] = slot
	return {"ok": true, "msg": "%s 编入%s。" % [sh["name"], GameData.SLOTS[slot]]}


func rename_ship(ship_id: int, new_name: String) -> Dictionary:
	var sh := ship(ship_id)
	new_name = new_name.strip_edges()
	if sh.is_empty() or sh["owner"] != pid():
		return _fail("无效飞艇。")
	if new_name == "" or new_name.length() > 8:
		return _fail("船名要在 1–8 个字之间。")
	sh["name"] = new_name
	return {"ok": true, "msg": "改名为「%s」。" % new_name}


## Refit a docked ship at the shipyard: gold plus goods pulled from hold, warehouse, then market.
func refit_cost(sh: Dictionary, k: String) -> Dictionary:
	var r: Dictionary = GameData.REFITS[k]
	var lvl := mod_lvl(sh, k)
	var gold := int(float(GameData.SHIPS[sh["type"]]["price"]) * float(r["gold"]) * float(lvl + 1) * (1.0 - 0.25 * spec_bonus("shipwright")))
	var mats := {}
	for g in r["mats"]:
		mats[g] = int(r["mats"][g]) * (lvl + 1)
	return {"gold": gold, "mats": mats}


## Where the refit goods would come from and what the market part would cost.
func refit_plan(sh: Dictionary, k: String) -> Dictionary:
	var need := refit_cost(sh, k)
	var port: String = sh["port"]
	var hid: String = sh["owner"]
	var buy_gold := 0
	var ok := true
	var parts := []
	for g in need["mats"]:
		var want: int = need["mats"][g]
		var from_hold := mini(want, int(sh["cargo"].get(g, {}).get("qty", 0)))
		want -= from_hold
		var from_wh := 0
		if want > 0 and Industry.has_wh(self, port, hid):
			from_wh = mini(want, int(Industry.wh(self, port, hid).get(g, 0)))
			want -= from_wh
		var from_mkt := 0
		if want > 0:
			var st := int(s["ports"][port]["market"][g]["stock"])
			from_mkt = mini(want, maxi(0, st - 1))
			buy_gold += quote_buy(port, g, from_mkt, hid)["cost"]
			want -= from_mkt
		if want > 0:
			ok = false
		parts.append({"good": g, "hold": from_hold, "wh": from_wh, "mkt": from_mkt, "short": want})
	return {"ok": ok, "gold": int(need["gold"]) + buy_gold, "fee": int(need["gold"]), "parts": parts}


func refit(ship_id: int, k: String) -> Dictionary:
	var sh := ship(ship_id)
	if sh.is_empty() or sh["owner"] != pid() or not docked(sh):
		return _fail("只能改造停在港口的飞艇。")
	if not GameData.REFITS.has(k):
		return _fail("没有这项改造。")
	if mod_lvl(sh, k) >= GameData.REFIT_MAX:
		return _fail("%s已是最高级。" % GameData.REFITS[k]["name"])
	var plan := refit_plan(sh, k)
	if not plan["ok"]:
		var shorts := []
		for pt in plan["parts"]:
			if int(pt["short"]) > 0:
				shorts.append("%s ×%d" % [GameData.good_name(pt["good"]), int(pt["short"])])
		return _fail("物料不够：缺 " + "、".join(shorts) + "。")
	var h := house()
	if h["gold"] < plan["gold"]:
		return _fail("需要 %d 金（含采购物料）。" % plan["gold"])
	var port: String = sh["port"]
	for pt in plan["parts"]:
		var g: String = pt["good"]
		if int(pt["hold"]) > 0:
			sh["cargo"][g]["qty"] = int(sh["cargo"][g]["qty"]) - int(pt["hold"])
			if int(sh["cargo"][g]["qty"]) <= 0:
				sh["cargo"].erase(g)
		if int(pt["wh"]) > 0:
			Industry.wh_take(self, port, pid(), g, int(pt["wh"]))
		if int(pt["mkt"]) > 0:
			var q := quote_buy(port, g, int(pt["mkt"]), pid())
			h["gold"] -= q["cost"]
			h["month_out"] += q["cost"]
			s["ports"][port]["market"][g]["stock"] -= q["qty"]
			_note_trade(port, g, int(q["qty"]))
	h["gold"] -= plan["fee"]
	h["month_out"] += plan["fee"]
	if not sh.has("mods"):
		sh["mods"] = {"hull": 0, "sail": 0, "hold": 0, "guns": 0}
	sh["mods"][k] = mod_lvl(sh, k) + 1
	add_exp(30)
	return {"ok": true, "msg": "%s：%s升到 %d 级。" % [sh["name"], GameData.REFITS[k]["name"], mod_lvl(sh, k)]}


func price_factor(stock: float, eq_ref: float = NEUTRAL_EQ) -> float:
	return clampf(pow(eq_ref / maxf(stock, 1.0), 0.7), 0.4, 2.8)


func unit_price(port: String, good: String, stock_override: float = -1.0) -> float:
	var st: float = s["ports"][port]["market"][good]["stock"] if stock_override < 0.0 else stock_override
	return float(GameData.GOODS[good]["base"]) * price_factor(st)


func _discount(hid: String, port: String) -> float:
	var pat := patron(port)
	var d := GameData.PATRON_FEE if pat != "" and pat != hid else 1.0
	if hid == pid():
		d *= 1.0 - 0.01 * float(hero_abil("trade") - 1)
		d *= (1.0 - 0.004 * float(post_level("acct"))) * (1.0 - 0.03 * spec_bonus("haggle"))
	return d


## The house with the most buildings in a port (ties: nobody). Others pay a harbour fee there.
func patron(port: String) -> String:
	var counts := {}
	for pl in s["ports"][port]["plots"]:
		if pl != null:
			counts[pl["owner"]] = int(counts.get(pl["owner"], 0)) + 1
	var best := ""
	var best_n := 0
	var tie := false
	for hid in counts:
		if counts[hid] > best_n:
			best = hid
			best_n = counts[hid]
			tie = false
		elif counts[hid] == best_n:
			tie = true
	return "" if tie else best


func buy_price(port: String, good: String, hid: String = "") -> int:
	if hid == "":
		hid = pid()
	return int(roundf(unit_price(port, good) * 1.06 * _discount(hid, port)))


const AI_BONUS := [0.98, 1.025, 1.06]   # rivals' selling edge per difficulty (easy / normal / hard)


func _sell_mult(hid: String) -> float:
	var m := 0.94 * (1.05 if perk(hid) == "sell" else 1.0)
	if hid != pid():
		m *= AI_BONUS[clampi(int(s.get("difficulty", 1)), 0, 2)]
	else:
		m *= 1.0 + 0.01 * float(hero_abil("trade") - 1)
		m *= 1.0 + 0.004 * float(post_level("acct"))
	return m


func sell_price(port: String, good: String, hid: String = "") -> int:
	if hid == "":
		hid = pid()
	var m := _sell_mult(hid)
	if hid == pid():
		if port == "hongxiao":
			m *= 1.0 + 0.05 * spec_bonus("blackmarket")
		if GameData.tier(good) == 3:
			m *= 1.0 + 0.08 * spec_bonus("foreign")
	return int(roundf(unit_price(port, good) * m))


## Quote buying `qty` units: price climbs as stock drops. Returns {qty, cost}.
func quote_buy(port: String, good: String, qty: int, hid: String = "", budget: float = INF) -> Dictionary:
	if hid == "":
		hid = pid()
	var st: float = s["ports"][port]["market"][good]["stock"]
	var cost := 0.0
	var n := 0
	var disc := _discount(hid, port)
	while n < qty and st > 1.0:
		var p := roundf(unit_price(port, good, st) * 1.06 * disc)
		if cost + p > budget:
			break
		cost += p
		st -= 1.0
		n += 1
	return {"qty": n, "cost": int(cost)}


func quote_sell(port: String, good: String, qty: int, hid: String = "") -> Dictionary:
	if hid == "":
		hid = pid()
	var mult := _sell_mult(hid)
	var st: float = s["ports"][port]["market"][good]["stock"]
	var rev := 0.0
	for i in qty:
		rev += roundf(unit_price(port, good, st) * mult)
		st += 1.0
	return {"qty": qty, "revenue": int(rev)}


## Fast 3-point estimates of quote_buy / quote_sell for AI planning (exact quotes loop per unit).
func est_buy(port: String, good: String, qty: int, hid: String, budget: float) -> Dictionary:
	var st: float = s["ports"][port]["market"][good]["stock"]
	qty = mini(qty, int(st) - 1)
	if qty <= 0:
		return {"qty": 0, "cost": 0}
	var disc := _discount(hid, port)
	var avg := (unit_price(port, good, st) + 2.0 * unit_price(port, good, st - qty * 0.5) + unit_price(port, good, st - qty)) * 0.25 * 1.06 * disc
	var cost := avg * qty
	if cost > budget:
		qty = int(budget / avg)
		cost = avg * qty
	return {"qty": qty, "cost": int(cost)}


func est_sell(port: String, good: String, qty: int, hid: String) -> Dictionary:
	if qty <= 0:
		return {"qty": 0, "revenue": 0}
	var st: float = s["ports"][port]["market"][good]["stock"]
	var avg := (unit_price(port, good, st) + 2.0 * unit_price(port, good, st + qty * 0.5) + unit_price(port, good, st + qty)) * 0.25 * _sell_mult(hid)
	return {"qty": qty, "revenue": int(avg * qty)}


func fuel_cost(type: String, from: String, to: String) -> int:
	return GameData.travel_days(from, to, type) * int(GameData.SHIPS[type]["fuel_day"]) * GameData.FUEL_PRICE


## Supplies for one of the player's own voyages (shorter trips burn less).
func fuel_cost_for(sh: Dictionary, to: String) -> int:
	var days := ship_days(sh, to)
	var c := 0
	for o in fleet_ships(sh):
		c += days * int(GameData.SHIPS[o["type"]]["fuel_day"]) * GameData.FUEL_PRICE
	return c


func net_worth(hid: String = "") -> float:
	if hid == "":
		hid = pid()
	var h := house(hid)
	var v: float = h["gold"] - h["debt"]
	for sh in _ships_of(hid):
		v += float(GameData.SHIPS[sh["type"]]["price"]) * 0.6
		for g in sh["cargo"]:
			v += float(sh["cargo"][g]["qty"]) * float(sh["cargo"][g]["cost"])
	for b in Industry.all_buildings(self, hid):
		v += float(GameData.build_cost(b["plot"]["b"])) * 0.5 * float(b["plot"]["lvl"])
	for pid in GameData.PORT_IDS:
		var w: Dictionary = s["ports"][pid]["wh"].get(hid, {})
		for g in w:
			v += float(w[g]) * float(GameData.GOODS[g]["base"]) * 0.6
	return v


func loan_limit(hid: String = "") -> float:
	if hid == "":
		hid = pid()
	return maxf(10000.0, net_worth(hid) * 0.5 + house(hid)["debt"])


func ship_pos(sh: Dictionary) -> Vector2:
	if docked(sh):
		return GameData.PORTS[sh["port"]]["pos"]
	var a: Vector2 = GameData.PORTS[sh["from"]]["pos"]
	var b: Vector2 = GameData.PORTS[sh["to"]]["pos"]
	var span := maxf(1.0, float(sh["arrive"] - sh["depart"]))
	var t := clampf((float(s["day"]) + float(s.get("frac", 0.0)) - float(sh["depart"])) / span, 0.0, 1.0)
	return a.lerp(b, t)


# ---------------------------------------------------------------- actions (return {ok, msg})

func buy(ship_id: int, good: String, qty: int) -> Dictionary:
	var sh := ship(ship_id)
	if sh.is_empty() or not docked(sh):
		return _fail("飞艇不在港口。")
	if not GameData.trades(sh["port"], good):
		return _fail("%s 的交易所不收%s。" % [GameData.port_name(sh["port"]), GameData.good_name(good)])
	var h := house(sh["owner"])
	qty = mini(qty, fleet_cargo_cap(sh) - fleet_cargo_used(sh))
	if qty <= 0:
		return _fail("货舱已满。")
	var q := quote_buy(sh["port"], good, qty, sh["owner"], h["gold"])
	if q["qty"] <= 0:
		return _fail("金币不足。")
	h["gold"] -= q["cost"]
	h["month_out"] += q["cost"]
	s["ports"][sh["port"]]["market"][good]["stock"] -= q["qty"]
	_stow(sh, good, int(q["qty"]), float(q["cost"]) / float(q["qty"]))
	if sh["owner"] == pid():
		_note_trade(sh["port"], good, int(q["qty"]))
		_update_intel(sh["port"])
	return {"ok": true, "msg": "买入 %s ×%d，花费 %d 金。" % [GameData.good_name(good), q["qty"], q["cost"]], "qty": q["qty"], "cost": q["cost"]}


## Put bought goods into the ship, spilling over into its escorts.
func _stow(sh: Dictionary, good: String, qty: int, unit: float) -> void:
	for o in fleet_ships(sh):
		var room := cargo_cap(o) - cargo_used(o)
		var n := mini(room, qty)
		if n <= 0:
			continue
		var c: Dictionary = o["cargo"].get(good, {"qty": 0, "cost": 0.0})
		var total: float = float(c["qty"]) * float(c["cost"]) + unit * n
		c["qty"] = int(c["qty"]) + n
		c["cost"] = total / float(c["qty"])
		o["cargo"][good] = c
		qty -= n
		if qty <= 0:
			break


## Take goods out of a fleet's holds (escorts first, so the flagship keeps the rest).
## Returns {qty, cost}: units removed and their average cost.
func _unstow(sh: Dictionary, good: String, qty: int) -> Dictionary:
	var took := 0
	var total := 0.0
	var ships := fleet_ships(sh)
	ships.reverse()
	for o in ships:
		if not o["cargo"].has(good) or qty <= 0:
			continue
		var c: Dictionary = o["cargo"][good]
		var n := mini(int(c["qty"]), qty)
		took += n
		total += float(c["cost"]) * n
		qty -= n
		c["qty"] = int(c["qty"]) - n
		if int(c["qty"]) <= 0:
			o["cargo"].erase(good)
	return {"qty": took, "cost": (total / float(took)) if took > 0 else 0.0}


func sell(ship_id: int, good: String, qty: int) -> Dictionary:
	var sh := ship(ship_id)
	if sh.is_empty() or not docked(sh):
		return _fail("飞艇不在港口。")
	var c: Dictionary = fleet_cargo(sh).get(good, {})
	if c.is_empty():
		return _fail("货舱里没有这种货。")
	if not GameData.trades(sh["port"], good):
		return _fail("%s 的交易所不收%s，可以存进仓库或运去别处。" % [GameData.port_name(sh["port"]), GameData.good_name(good)])
	qty = mini(qty, int(c["qty"]))
	if qty <= 0:
		return _fail("数量无效。")
	var q := quote_sell(sh["port"], good, qty, sh["owner"])
	var h := house(sh["owner"])
	h["gold"] += q["revenue"]
	h["month_in"] += q["revenue"]
	s["ports"][sh["port"]]["market"][good]["stock"] += qty
	var taken := _unstow(sh, good, qty)
	var profit := int(q["revenue"] - float(taken["cost"]) * qty)
	if sh["owner"] == pid():
		s["stats"]["trades"] += 1
		s["stats"]["profit"] += profit
		s["stats"]["best_trade"] = maxi(int(s["stats"]["best_trade"]), profit)
		_note_trade(sh["port"], good, qty)
		add_rep(pid(), profit / 60)
		add_exp(maxi(profit, 0) / 40)
		_update_intel(sh["port"])
	else:
		add_rep(sh["owner"], profit / 60)
	return {"ok": true, "msg": "卖出 %s ×%d，收入 %d 金（利润 %+d）。" % [GameData.good_name(good), qty, q["revenue"], profit], "profit": profit, "revenue": q["revenue"]}


func _note_trade(port: String, good: String, qty: int) -> void:
	var hd: Dictionary = s["stats"]["handled"]
	hd[good] = int(hd.get(good, 0)) + qty
	add_friend(port, pid(), qty / 2)


func depart(ship_id: int, dest: String) -> Dictionary:
	var sh := ship(ship_id)
	if sh.is_empty() or not docked(sh):
		return _fail("飞艇不在港口。")
	if dest == sh["port"] or not GameData.PORTS.has(dest):
		return _fail("目的地无效。")
	if in_fleet(sh):
		return _fail("%s 随旗舰队行动。" % sh["name"])
	var h := house(sh["owner"])
	var fc := fuel_cost_for(sh, dest)
	if h["gold"] < fc:
		return _fail("补给费用 %d 金，金币不足。" % fc)
	h["gold"] -= fc
	h["month_out"] += fc
	var days := ship_days(sh, dest)
	for o in fleet_ships(sh):
		o["from"] = o["port"]
		o["to"] = dest
		o["depart"] = s["day"]
		o["arrive"] = s["day"] + days
		o["port"] = ""
	if sh["owner"] == pid() and sh["flagship"]:
		s["sailed"] = true
	var n := fleet_ships(sh).size()
	return {"ok": true, "msg": "%s%s 起航前往 %s，预计 %d 天，补给 %d 金。" % [sh["name"], ("等 %d 艘" % n) if n > 1 else "", GameData.port_name(dest), days, fc]}


func buy_ship(type: String, port: String) -> Dictionary:
	var h := house()
	if _ships_of(pid()).size() >= max_ships():
		return _fail("当前名声下船队最多 %d 艘。" % max_ships())
	var price: int = ship_price(type)
	if h["gold"] < price:
		return _fail("需要 %d 金。" % price)
	h["gold"] -= price
	h["month_out"] += price
	var sh := _add_ship(pid(), type, port)
	return {"ok": true, "msg": "购得 %s「%s」。" % [GameData.SHIPS[type]["name"], sh["name"]], "ship": sh["id"]}


func ship_price(type: String, hid: String = "") -> int:
	if hid == "":
		hid = pid()
	return int(GameData.SHIPS[type]["price"] * (0.8 if perk(hid) == "ships" else 1.0))


func sell_ship(ship_id: int) -> Dictionary:
	var sh := ship(ship_id)
	if sh.is_empty() or sh["owner"] != pid() or not docked(sh):
		return _fail("只能出售停在港口的飞艇。")
	if _ships_of(pid()).size() <= 1:
		return _fail("至少保留一艘飞艇。")
	if not sh["cargo"].is_empty():
		return _fail("请先清空货舱。")
	var v := int(GameData.SHIPS[sh["type"]]["price"] * 0.6 * (1.0 - 0.5 * float(sh.get("dmg", 0)) / 100.0))
	house()["gold"] += v
	_remove_ship(sh)
	return {"ok": true, "msg": "出售 %s，回收 %d 金。" % [sh["name"], v]}


func _remove_ship(sh: Dictionary) -> void:
	var was_flag: bool = sh["flagship"]
	s["ships"].erase(sh)
	if was_flag and not _ships_of(pid()).is_empty():
		var nf: Dictionary = _ships_of(pid())[0]
		nf["flagship"] = true
		nf["fleet"] = 0
		nf["route"] = null
		for o in _ships_of(pid()):
			if int(o.get("fleet", 0)) == int(sh["id"]):
				o["fleet"] = int(nf["id"])


func repair_cost(sh: Dictionary) -> int:
	return int(roundf(float(GameData.SHIPS[sh["type"]]["price"]) * float(sh.get("dmg", 0)) / 100.0 * GameData.REPAIR_RATE * (1.0 - 0.25 * spec_bonus("shipwright"))))


## Pay the yard to mend battle damage at once (a docked ship also mends a little every day).
func repair_ship(ship_id: int) -> Dictionary:
	var sh := ship(ship_id)
	if sh.is_empty() or not docked(sh):
		return _fail("飞艇不在港口。")
	if int(sh.get("dmg", 0)) <= 0:
		return _fail("%s 完好无损。" % sh["name"])
	var cost := repair_cost(sh)
	var h := house(sh["owner"])
	if h["gold"] < cost:
		return _fail("修理费 %d 金，金币不足。" % cost)
	h["gold"] -= cost
	h["month_out"] += cost
	sh["dmg"] = 0
	return {"ok": true, "msg": "%s 修理完毕，花费 %d 金。" % [sh["name"], cost]}


## Auto route: a loop of 2–4 stops; at each stop the ship sells what it carries (except goods
## it is told to buy there) and loads the stop's shopping list. Empty dict clears the route.
## The old {a, b, good} shape is still accepted and converted.
func set_route(ship_id: int, route: Dictionary) -> Dictionary:
	var sh := ship(ship_id)
	if sh.is_empty() or sh["owner"] != pid():
		return _fail("无效飞艇。")
	if route.is_empty():
		sh["route"] = null
		return {"ok": true, "msg": "航线已清除。"}
	if sh["flagship"]:
		return _fail("旗舰由你亲自指挥，不能设自动航线。")
	if in_fleet(sh):
		return _fail("随行的船不能单独跑航线，先让它脱队。")
	route = normalize_route(route)
	var stops: Array = route["stops"]
	if stops.size() < 2 or stops.size() > GameData.ROUTE_MAX_STOPS:
		return _fail("航线要有 2–%d 站。" % GameData.ROUTE_MAX_STOPS)
	for i in stops.size():
		var st: Dictionary = stops[i]
		if not GameData.PORTS.has(st["port"]):
			return _fail("无效港口。")
		if st["port"] == stops[(i + 1) % stops.size()]["port"]:
			return _fail("相邻两站不能是同一座港口。")
		if st["buy"].size() > GameData.ROUTE_MAX_BUYS:
			return _fail("每站最多买 %d 种货。" % GameData.ROUTE_MAX_BUYS)
	var any_buy := false
	for st in stops:
		if not st["buy"].is_empty():
			any_buy = true
	if not any_buy:
		return _fail("至少有一站要买点什么。")
	sh["route"] = {"stops": stops, "i": 0, "total": int(route.get("total", 0))}
	return {"ok": true, "msg": "航线已更新：%s。" % route_text(sh["route"])}


static func normalize_route(r: Dictionary) -> Dictionary:
	if r.has("stops"):
		var stops := []
		for st in r["stops"]:
			var buys := []
			for g in st.get("buy", []):
				buys.append(str(g))
			stops.append({"port": str(st["port"]), "buy": buys})
		return {"stops": stops, "i": int(r.get("i", 0)), "total": int(r.get("total", 0))}
	return {"stops": [{"port": str(r["a"]), "buy": [str(r["good"])]}, {"port": str(r["b"]), "buy": []}], "i": 0, "total": int(r.get("total", 0))}


static func route_text(r: Dictionary) -> String:
	var parts := []
	for st in r["stops"]:
		var buys := []
		for g in st["buy"]:
			buys.append(GameData.good_name(g))
		parts.append(GameData.port_name(st["port"]) + (("（买" + "、".join(buys) + "）") if not buys.is_empty() else ""))
	return " → ".join(parts)


func take_loan(amount: int) -> Dictionary:
	var h := house()
	if h["debt"] + amount > loan_limit():
		return _fail("超过贷款上限 %d 金。" % int(loan_limit() - h["debt"]))
	h["debt"] += amount
	h["gold"] += amount
	return {"ok": true, "msg": "贷款 %d 金，月息 2%%。" % amount}


func repay(amount: int) -> Dictionary:
	var h := house()
	amount = mini(amount, int(ceil(h["debt"])))
	if amount <= 0 or h["gold"] < amount:
		return _fail("金币不足或没有欠款。")
	h["debt"] -= amount
	h["gold"] -= amount
	return {"ok": true, "msg": "还款 %d 金。" % amount}


## ---- blueprints and the city hall

func deed_ok(port: String, good: String, hid: String = "") -> Dictionary:
	if hid == "":
		hid = pid()
	if GameData.tier(good) != 1 or GameData.GOODS[good]["home"] != port:
		return _fail("%s 不出产%s。" % [GameData.port_name(port), GameData.good_name(good)])
	if has_bp(good, hid):
		return _fail("你已经有这份地契。")
	if friend_level(port, hid) < 2:
		return _fail("城主只把地契卖给相识的商会（友好度 2）。")
	if house(hid)["gold"] < GameData.DEED_COST:
		return _fail("需要 %d 金。" % GameData.DEED_COST)
	return {"ok": true}


func buy_deed(port: String, good: String) -> Dictionary:
	var r := deed_ok(port, good)
	if not r["ok"]:
		return r
	var h := house()
	h["gold"] -= GameData.DEED_COST
	h["month_out"] += GameData.DEED_COST
	h["bp"][good] = true
	add_rep(pid(), 20)
	return {"ok": true, "msg": "取得 %s 的%s地契，现在可以在这里建%s工坊。" % [GameData.port_name(port), GameData.good_name(good), GameData.good_name(good)]}


func craft_ok(good: String, hid: String = "") -> Dictionary:
	if hid == "":
		hid = pid()
	if GameData.tier(good) != 2:
		return _fail("这不是工艺图纸。")
	if has_bp(good, hid):
		return _fail("你已经有这份图纸。")
	if rep_level(hid) < 3:
		return _fail("工匠行会只把图纸卖给商董以上的商会（名声 3 级）。")
	var mi := GameData.main_input(good)
	var handled := int(s["stats"]["handled"].get(mi, 0)) if hid == pid() else GameData.CRAFT_HANDLED
	if handled < GameData.CRAFT_HANDLED:
		return _fail("先经手 %d 件%s（目前 %d）。" % [GameData.CRAFT_HANDLED, GameData.good_name(mi), handled])
	if house(hid)["gold"] < GameData.CRAFT_BP_COST:
		return _fail("需要 %d 金。" % GameData.CRAFT_BP_COST)
	return {"ok": true}


func buy_craft_bp(good: String) -> Dictionary:
	var r := craft_ok(good)
	if not r["ok"]:
		return r
	var h := house()
	var cost := bp_cost(GameData.CRAFT_BP_COST)
	h["gold"] -= cost
	h["month_out"] += cost
	h["bp"][good] = true
	add_rep(pid(), 40)
	return {"ok": true, "msg": "买下%s的工艺图纸。" % GameData.good_name(good)}


func secret_ok(port: String, good: String, hid: String = "") -> Dictionary:
	if hid == "":
		hid = pid()
	if GameData.tier(good) != 3 or GameData.SECRET_BP_CITY[good] != port:
		return _fail("这里没有这份秘传。")
	if has_bp(good, hid):
		return _fail("你已经有这份图纸。")
	if rep_level(hid) < 4:
		return _fail("秘传图纸只传给行首以上的商会（名声 4 级）。")
	if friend_level(port, hid) < 3:
		return _fail("行会只把秘传交给信赖的商会（友好度 3）。")
	if house(hid)["gold"] < GameData.SECRET_BP_COST:
		return _fail("需要 %d 金。" % GameData.SECRET_BP_COST)
	return {"ok": true}


func buy_secret_bp(port: String, good: String) -> Dictionary:
	var r := secret_ok(port, good)
	if not r["ok"]:
		return r
	var h := house()
	var cost := bp_cost(GameData.SECRET_BP_COST)
	h["gold"] -= cost
	h["month_out"] += cost
	h["bp"][good] = true
	add_rep(pid(), 120)
	_say("%s 的行会把%s的秘传图纸交给了你。" % [GameData.port_name(port), GameData.good_name(good)], "major")
	return {"ok": true, "msg": "取得%s的秘传图纸。" % GameData.good_name(good)}


func donate(port: String) -> Dictionary:
	var h := house()
	if h["gold"] < GameData.DONATION:
		return _fail("需要 %d 金。" % GameData.DONATION)
	h["gold"] -= GameData.DONATION
	h["month_out"] += GameData.DONATION
	add_friend(port, pid(), GameData.DONATION_FRIEND)
	add_rep(pid(), 5)
	return {"ok": true, "msg": "向 %s 捐助 %d 金，友好度 +%d。" % [GameData.port_name(port), GameData.DONATION, GameData.DONATION_FRIEND]}


## ---- contracts: ports post delivery orders; first house to deliver gets the reward.

func open_contracts(port: String = "") -> Array:
	return s["contracts"].filter(func(c): return port == "" or c["port"] == port)


func _post_contract() -> void:
	var port: String = GameData.PORT_IDS[rng.randi() % GameData.PORT_IDS.size()]
	var choices: Array = GameData.traded_goods(port).filter(func(g): return not g in GameData.PORTS[port]["make"])
	var g: String = choices[rng.randi() % choices.size()]
	for c in s["contracts"]:
		if c["port"] == port and c["good"] == g:
			return
	var base: float = GameData.GOODS[g]["base"]
	var qty := int(clampf(roundf(rng.randf_range(2400.0, 5200.0) / base / 5.0) * 5.0, 10.0, 80.0))
	var reward := int(roundf(qty * base * rng.randf_range(1.5, 1.9) / 100.0) * 100.0)
	var c := {"id": s["next_contract_id"], "port": port, "good": g, "qty": qty, "reward": reward,
		"end": int(s["day"]) + rng.randi_range(60, 100), "chasers": []}
	s["next_contract_id"] = int(s["next_contract_id"]) + 1
	s["contracts"].append(c)
	_say("新委托：%s 求购 %s %d 件，酬金 %d 金，%d 天内交付，先到先得。" % [GameData.port_name(port), GameData.good_name(g), qty, reward, int(c["end"]) - int(s["day"])], "contract")


func _tick_contracts() -> void:
	var day: int = s["day"]
	for c in s["contracts"].duplicate():
		if day > int(c["end"]):
			s["contracts"].erase(c)
			if c.get("kind", "trade") == "bounty":
				_say("%s 附近的云盗转移了，悬赏作废。" % GameData.port_name(c["port"]), "month")
			else:
				_say("%s 的 %s 委托过期了。" % [GameData.port_name(c["port"]), GameData.good_name(c["good"])], "month")
	if day >= 20 and day % 20 == 0 and s["contracts"].size() < GameData.MAX_CONTRACTS and rng.randf() < 0.5:
		if day > 120 and rng.randf() < 0.3 and open_bounties().is_empty():
			_post_bounty()
		else:
			_post_contract()


func contract(cid: int) -> Dictionary:
	for c in s["contracts"]:
		if int(c["id"]) == cid:
			return c
	return {}


func can_fulfill(sh: Dictionary, c: Dictionary) -> bool:
	if c.get("kind", "trade") != "trade":
		return false
	return docked(sh) and sh["port"] == c["port"] and int(fleet_cargo(sh).get(c["good"], {}).get("qty", 0)) >= int(c["qty"])


func fulfill(ship_id: int, cid: int) -> Dictionary:
	var sh := ship(ship_id)
	var c := contract(cid)
	if sh.is_empty() or c.is_empty():
		return _fail("委托已被别人抢先完成。")
	if not can_fulfill(sh, c):
		return _fail("需要在 %s 停靠，并带着 %d 件%s。" % [GameData.port_name(c["port"]), int(c["qty"]), GameData.good_name(c["good"])])
	var hid: String = sh["owner"]
	var taken := _unstow(sh, c["good"], int(c["qty"]))
	var unit_cost := float(taken["cost"])
	var h := house(hid)
	h["gold"] += float(c["reward"])
	h["month_in"] += float(c["reward"])
	s["contracts"].erase(c)
	var profit := int(float(c["reward"]) - unit_cost * float(c["qty"]))
	add_rep(hid, 40)
	if hid == pid():
		s["stats"]["profit"] = int(s["stats"]["profit"]) + profit
		s["stats"]["contracts"] = int(s["stats"].get("contracts", 0)) + 1
		add_friend(c["port"], hid, 60)
		add_exp(60)
		for mate in s["crew"]:
			add_affinity(mate, 4)
	var msg := "%s 完成了 %s 的委托（%s %d 件），获得 %d 金。" % [GameData.HOUSES[hid]["name"], GameData.port_name(c["port"]), GameData.good_name(c["good"]), int(c["qty"]), int(c["reward"])]
	_say(msg, "good" if hid == pid() else "major")
	return {"ok": true, "msg": msg, "profit": profit}


## Deliver cargo from a docked ship at the house's home port toward the current lighthouse stage.
func deliver_mats(ship_id: int) -> Dictionary:
	var sh := ship(ship_id)
	var hid: String = sh["owner"]
	var home: String = GameData.HOUSES[hid]["home"]
	if not docked(sh) or sh["port"] != home:
		return _fail("物资只能在母港 %s 交付。" % GameData.port_name(home))
	var lh: Dictionary = house(hid)["lh"]
	if lh["stage"] >= GameData.LIGHTHOUSE.size() or lh["building"]:
		return _fail("当前没有需要物资的工程。")
	var need: Dictionary = GameData.LIGHTHOUSE[lh["stage"]]["mats"]
	var parts := []
	for g in need:
		var have: int = int(lh["mats"].get(g, 0))
		var want: int = int(need[g]) - have
		if want <= 0:
			continue
		var taken := _unstow(sh, g, want)
		var n: int = taken["qty"]
		if n <= 0:
			continue
		lh["mats"][g] = have + n
		parts.append("%s ×%d" % [GameData.good_name(g), n])
	if parts.is_empty():
		return _fail("货舱里没有灯塔需要的物资。")
	return {"ok": true, "msg": "交付 " + "、".join(parts) + "。"}


## Move goods between a docked ship and its owner's warehouse in that port.
func load_wh(ship_id: int, good: String, qty: int) -> Dictionary:
	var sh := ship(ship_id)
	if sh.is_empty() or not docked(sh):
		return _fail("飞艇不在港口。")
	var port: String = sh["port"]
	var hid: String = sh["owner"]
	if not Industry.has_wh(self, port, hid):
		return _fail("这里没有你的仓库。")
	qty = mini(qty, fleet_cargo_cap(sh) - fleet_cargo_used(sh))
	var n := Industry.wh_take(self, port, hid, good, qty)
	if n <= 0:
		return _fail("仓库里没有可装的%s，或货舱已满。" % GameData.good_name(good))
	_stow(sh, good, n, float(GameData.GOODS[good]["base"]) * 0.6)
	return {"ok": true, "msg": "从仓库装上 %s ×%d。" % [GameData.good_name(good), n], "qty": n}


func unload_wh(ship_id: int, good: String, qty: int) -> Dictionary:
	var sh := ship(ship_id)
	if sh.is_empty() or not docked(sh):
		return _fail("飞艇不在港口。")
	var port: String = sh["port"]
	var hid: String = sh["owner"]
	if not Industry.has_wh(self, port, hid):
		return _fail("这里没有你的仓库。")
	var c: Dictionary = fleet_cargo(sh).get(good, {})
	if c.is_empty():
		return _fail("货舱里没有%s。" % GameData.good_name(good))
	var n := Industry.wh_add(self, port, hid, good, mini(qty, int(c["qty"])))
	if n <= 0:
		return _fail("仓库满了。")
	_unstow(sh, good, n)
	return {"ok": true, "msg": "卸入仓库 %s ×%d。" % [GameData.good_name(good), n], "qty": n}


## Buy from the market straight into the player's warehouse in that port (商馆 ⇄ 市场).
func buy_to_wh(port: String, good: String, qty: int, hid: String = "") -> Dictionary:
	if hid == "":
		hid = pid()
	if not Industry.has_wh(self, port, hid):
		return _fail("这里没有你的商馆。")
	var h := house(hid)
	qty = mini(qty, Industry.wh_cap(self, port, hid) - Industry.wh_used(self, port, hid))
	if qty <= 0:
		return _fail("仓库满了。")
	var q := quote_buy(port, good, qty, hid, h["gold"])
	if q["qty"] <= 0:
		return _fail("金币不足。")
	h["gold"] -= q["cost"]
	h["month_out"] += q["cost"]
	s["ports"][port]["market"][good]["stock"] -= q["qty"]
	Industry.wh_add(self, port, hid, good, int(q["qty"]))
	if hid == pid():
		_note_trade(port, good, int(q["qty"]))
		_update_intel(port)
	return {"ok": true, "msg": "买入 %s ×%d 存进商馆，花费 %d 金。" % [GameData.good_name(good), q["qty"], q["cost"]], "qty": q["qty"], "cost": q["cost"]}


func sell_from_wh(port: String, good: String, qty: int, hid: String = "") -> Dictionary:
	if hid == "":
		hid = pid()
	if not Industry.has_wh(self, port, hid):
		return _fail("这里没有你的商馆。")
	var n := Industry.wh_take(self, port, hid, good, qty)
	if n <= 0:
		return _fail("商馆里没有%s。" % GameData.good_name(good))
	var q := quote_sell(port, good, n, hid)
	var h := house(hid)
	h["gold"] += q["revenue"]
	h["month_in"] += q["revenue"]
	s["ports"][port]["market"][good]["stock"] += n
	var profit := int(q["revenue"] - float(GameData.GOODS[good]["base"]) * 0.6 * n)
	if hid == pid():
		s["stats"]["trades"] += 1
		s["stats"]["profit"] += profit
		_note_trade(port, good, n)
		add_rep(pid(), maxi(profit, 0) / 60)
		_update_intel(port)
	else:
		add_rep(hid, maxi(profit, 0) / 60)
	return {"ok": true, "msg": "从商馆卖出 %s ×%d，收入 %d 金。" % [GameData.good_name(good), n, q["revenue"]], "profit": profit, "revenue": q["revenue"]}


## Hand lighthouse materials from the home warehouse to the building site.
func deliver_from_wh(hid: String = "") -> Dictionary:
	if hid == "":
		hid = pid()
	var home: String = GameData.HOUSES[hid]["home"]
	var lh: Dictionary = house(hid)["lh"]
	if lh["stage"] >= GameData.LIGHTHOUSE.size() or lh["building"]:
		return _fail("当前没有需要物资的工程。")
	var need: Dictionary = GameData.LIGHTHOUSE[lh["stage"]]["mats"]
	var parts := []
	for g in need:
		var have: int = int(lh["mats"].get(g, 0))
		var n := Industry.wh_take(self, home, hid, g, int(need[g]) - have)
		if n > 0:
			lh["mats"][g] = have + n
			parts.append("%s ×%d" % [GameData.good_name(g), n])
	if parts.is_empty():
		return _fail("母港仓库里没有灯塔需要的物资。")
	return {"ok": true, "msg": "从仓库交付 " + "、".join(parts) + "。"}


func mats_ready(hid: String = "") -> bool:
	if hid == "":
		hid = pid()
	var lh: Dictionary = house(hid)["lh"]
	if lh["stage"] >= GameData.LIGHTHOUSE.size():
		return false
	var need: Dictionary = GameData.LIGHTHOUSE[lh["stage"]]["mats"]
	for g in need:
		if int(lh["mats"].get(g, 0)) < int(need[g]):
			return false
	return true


func start_lighthouse(hid: String = "") -> Dictionary:
	if hid == "":
		hid = pid()
	var h := house(hid)
	var lh: Dictionary = h["lh"]
	if lh["building"] or lh["stage"] >= GameData.LIGHTHOUSE.size():
		return _fail("现在不能开工。")
	var st: Dictionary = GameData.LIGHTHOUSE[lh["stage"]]
	if rep_level(hid) < int(st["rep"]):
		return _fail("建%s需要名声达到「%s」（%d 级）。" % [st["name"], GameData.REP_NAMES[int(st["rep"]) - 1], int(st["rep"])])
	if not mats_ready(hid):
		return _fail("物资尚未备齐。")
	if h["gold"] < st["gold"]:
		return _fail("需要 %d 金。" % st["gold"])
	h["gold"] -= st["gold"]
	h["month_out"] += st["gold"]
	lh["building"] = true
	lh["end"] = s["day"] + int(st["days"])
	if hid != pid():
		_say("%s 开始建造灯塔%s（第 %d 层）。" % [GameData.HOUSES[hid]["name"], st["name"], int(lh["stage"]) + 1], "major")
	return {"ok": true, "msg": "灯塔%s开工，%d 天后完工。" % [st["name"], st["days"]]}


func buy_intel() -> Dictionary:
	var h := house()
	if h["gold"] < 400:
		return _fail("需要 400 金。")
	h["gold"] -= 400
	h["month_out"] += 400
	for pid in GameData.PORT_IDS:
		_update_intel(pid)
	return {"ok": true, "msg": "酒馆的消息贩子带来了全部港口的最新行情。"}


func _update_intel(port: String) -> void:
	var old = s["intel"].get(port)
	if old != null and int(old["day"]) != int(s["day"]):
		if not s.has("intel_prev"):
			s["intel_prev"] = {}
		s["intel_prev"][port] = old
	var prices := {}
	for g in GameData.GOOD_IDS:
		prices[g] = [buy_price(port, g), sell_price(port, g)]
	s["intel"][port] = {"day": s["day"], "prices": prices}


func _fail(msg: String) -> Dictionary:
	return {"ok": false, "msg": msg}


func _say(text: String, kind: String = "info") -> void:
	s["log"].append([s["day"], text, kind])
	if s["log"].size() > 200:
		s["log"].pop_front()
	message.emit(text, kind)


# ---------------------------------------------------------------- companions (伙伴)

func crew() -> Dictionary:
	return s["crew"]


func crew_cap() -> int:
	return Characters.CREW_CAP[clampi(rep_level() - 1, 0, 5)]


func crew_wages() -> int:
	var w := 0
	for cid in s["crew"]:
		w += int(Characters.CHARS[cid]["wage"])
	return w


## Strength of a companion's special perk: 0 when absent, 1.0 normally, 1.5 after their story.
func spec_bonus(spec: String) -> float:
	for cid in s["crew"]:
		if Characters.CHARS[cid]["spec"] == spec:
			return 1.5 if int(s["crew"][cid].get("spec_lvl", 1)) >= 2 else 1.0
	return 0.0


## Ability level of whoever holds a fleet post (0 when vacant).
func post_level(post: String) -> int:
	for cid in s["crew"]:
		if s["crew"][cid]["post"] == post:
			return int(Characters.CHARS[cid]["abil"][Characters.POSTS[post]["abil"]])
	return 0


func captain_level(ship_id: int) -> int:
	for cid in s["crew"]:
		var m: Dictionary = s["crew"][cid]
		if m["post"] == "captain" and int(m["ship"]) == ship_id:
			return int(Characters.CHARS[cid]["abil"]["sail"])
	return 0


func post_holder(post: String, ship_id: int = -1) -> String:
	for cid in s["crew"]:
		var m: Dictionary = s["crew"][cid]
		if m["post"] == post and (post != "captain" or int(m["ship"]) == ship_id):
			return cid
	return ""


## Hero block handed to a battle: command points, morale and gunnery/boarding from the crew.
func battle_hero() -> Dictionary:
	return {
		"fight": hero_abil("fight"), "lvl": int(s["hero"]["lvl"]),
		"fire_mult": 1.0 + 0.025 * float(post_level("gunner")) + 0.15 * spec_bonus("gunnery"),
		"board_mult": 1.0 + 0.03 * float(post_level("boarder")) + 0.2 * spec_bonus("boarding"),
		"cp_bonus": 1 if spec_bonus("spirit") > 0.0 else 0,
		"morale_bonus": int(10.0 * spec_bonus("spirit")),
	}


func bp_cost(base: int) -> int:
	return int(roundf(float(base) * (1.0 - 0.25 * spec_bonus("research"))))


## Can this companion be hired here? {ok, msg}
func recruit_ok(cid: String, port: String, where: String) -> Dictionary:
	var c: Dictionary = Characters.CHARS[cid]
	if s["crew"].has(cid):
		return _fail("已经在你的商会。")
	if s.get("fired", {}).has(cid):
		return _fail("%s 不愿再回来了。" % c["name"])
	if c["where"] == "roam":
		if s["roam"]["port"] != port or where != "tavern" or int(s["roam"]["until"]) < int(s["day"]):
			return _fail("不在这里。")
	elif c["where"] == "any":
		if where != "tavern":
			return _fail("不在这里。")
	elif c["where"] != where or c["port"] != port:
		return _fail("不在这里。")
	var cond: Dictionary = c["cond"]
	if cond.has("story") and int(s["story"]) < int(cond["story"]):
		return _fail("还没到相遇的时候。")
	if cond.has("rep") and rep_level() < int(cond["rep"]):
		return _fail("名声要到「%s」。" % GameData.REP_NAMES[int(cond["rep"]) - 1])
	if cond.has("friend") and friend_level(port) < int(cond["friend"]):
		return _fail("本城友好度要到「%s」。" % GameData.FRIEND_NAMES[int(cond["friend"])])
	if cond.has("wins") and int(s["stats"].get("wins", 0)) < int(cond["wins"]):
		return _fail("先打赢一场云盗。")
	if cond.has("visited") and s["hero"]["visited"].size() < int(cond["visited"]):
		return _fail("先走遍全部港口（%d/%d）。" % [s["hero"]["visited"].size(), int(cond["visited"])])
	if cond.has("craft_bp"):
		var n := 0
		for g in house()["bp"]:
			if GameData.tier(g) == 2:
				n += 1
		if n < int(cond["craft_bp"]):
			return _fail("先买一份工艺图纸。")
	if cond.has("workshops") and Industry.all_buildings(self, pid()).size() < int(cond["workshops"]):
		return _fail("先建 %d 座工坊。" % int(cond["workshops"]))
	if s["crew"].size() >= crew_cap():
		return _fail("伙伴已满（%d 人，名声更高才能多带）。" % crew_cap())
	if house()["gold"] < int(c["fee"]):
		return _fail("安家费 %d 金，金币不足。" % int(c["fee"]))
	return {"ok": true, "msg": ""}


## Companions on offer in a building (those present, whether or not you qualify yet).
func recruitable_at(port: String, where: String) -> Array:
	var out := []
	for cid in Characters.IDS:
		if s["crew"].has(cid) or s.get("fired", {}).has(cid):
			continue
		var c: Dictionary = Characters.CHARS[cid]
		var here := false
		match c["where"]:
			"roam":
				here = where == "tavern" and s["roam"]["port"] == port and int(s["roam"]["until"]) >= int(s["day"])
			"any":
				here = where == "tavern" and int(s["stats"].get("wins", 0)) >= 1
			_:
				here = c["where"] == where and c["port"] == port
		if here and (not c["cond"].has("story") or int(s["story"]) >= int(c["cond"]["story"])):
			out.append(cid)
	return out


func recruit(cid: String, port: String, where: String) -> Dictionary:
	var ok := recruit_ok(cid, port, where)
	if not ok["ok"]:
		return ok
	var c: Dictionary = Characters.CHARS[cid]
	house()["gold"] -= float(c["fee"])
	house()["month_out"] += float(c["fee"])
	s["crew"][cid] = {"aff": 10, "post": "", "ship": -1, "chapter": 0, "joined": int(s["day"]), "gift_month": -1, "spec_lvl": 1}
	var msg := "%s 加入了商会。" % c["name"]
	if c["spec"] == "shipwright" and not has_bp("astro"):
		house()["bp"]["astro"] = true
		msg += "他带来了星盘的秘传图纸。"
	_say(msg, "good")
	return {"ok": true, "msg": msg}


func dismiss(cid: String) -> Dictionary:
	if not s["crew"].has(cid):
		return _fail("没有这个人。")
	s["crew"].erase(cid)
	if not s.has("fired"):
		s["fired"] = {}
	s["fired"][cid] = true
	_say("%s 离开了商会。" % Characters.name_of(cid), "info")
	return {"ok": true, "msg": "%s 离开了。" % Characters.name_of(cid)}


## Assign a fleet post ("" clears it); captain needs a non-flagship ship.
func set_post(cid: String, post: String, ship_id: int = -1) -> Dictionary:
	if not s["crew"].has(cid):
		return _fail("没有这个人。")
	if post != "" and not Characters.POSTS.has(post):
		return _fail("没有这个岗位。")
	if post == "captain":
		var sh := ship(ship_id)
		if sh.is_empty() or sh["owner"] != pid() or sh["flagship"]:
			return _fail("船长只能带非旗舰的船。")
	var holder := post_holder(post, ship_id) if post != "" else ""
	if holder != "" and holder != cid:
		s["crew"][holder]["post"] = ""
		s["crew"][holder]["ship"] = -1
	s["crew"][cid]["post"] = post
	s["crew"][cid]["ship"] = ship_id if post == "captain" else -1
	return {"ok": true, "msg": "%s 任%s。" % [Characters.name_of(cid), Characters.POSTS[post]["name"]] if post != "" else "%s 卸下了岗位。" % Characters.name_of(cid)}


func gift(cid: String) -> Dictionary:
	if not s["crew"].has(cid):
		return _fail("没有这个人。")
	var m: Dictionary = s["crew"][cid]
	var month := int(s["day"]) / GameData.DAYS_MONTH
	if int(m["gift_month"]) == month:
		return _fail("这个月已经送过了。")
	if house()["gold"] < Characters.GIFT_COST:
		return _fail("金币不足。")
	house()["gold"] -= Characters.GIFT_COST
	house()["month_out"] += Characters.GIFT_COST
	m["gift_month"] = month
	add_affinity(cid, Characters.GIFT_AFF)
	return {"ok": true, "msg": "%s 很高兴，好感 +%d。" % [Characters.name_of(cid), Characters.GIFT_AFF]}


func add_affinity(cid: String, n: int) -> void:
	if not s["crew"].has(cid):
		return
	var m: Dictionary = s["crew"][cid]
	m["aff"] = clampi(int(m["aff"]) + n, 0, 100)


func _tick_crew() -> void:
	if int(s["day"]) % 10 == 0:
		for cid in s["crew"]:
			add_affinity(cid, 1)
	# a personal story chapter opens when the fleet is in port and nothing else is going on
	if s["event"] != null or s.get("encounter") != null:
		return
	var fl := flagship()
	if fl.is_empty() or not docked(fl):
		return
	for cid in s["crew"]:
		var m: Dictionary = s["crew"][cid]
		var ch := int(m["chapter"])
		if ch < 3 and int(m["aff"]) >= Characters.CHAPTER_AFF[ch]:
			EventBook.open_chapter(self, cid, ch)
			return


func _crew_monthly() -> void:
	if spec_bonus("rumours") > 0.0:
		for port in s["hero"]["visited"]:
			_update_intel(port)
		if spec_bonus("rumours") >= 1.5:
			for port in GameData.PORT_IDS:
				_update_intel(port)
	# the foreign merchant drifts between taverns from the second year on
	var day: int = s["day"]
	if day >= GameData.DAYS_YEAR and not s["crew"].has("helan") and int(s["roam"]["until"]) < day and rng.randf() < 0.35:
		s["roam"] = {"port": GameData.PORT_IDS[rng.randi() % GameData.PORT_IDS.size()], "until": day + 60}
		_say("传闻：一位语言不通的异乡商人在 %s 的酒馆落脚。" % GameData.port_name(s["roam"]["port"]), "info")


# ---------------------------------------------------------------- encounters & battle

var battle: Battle = null


## Battle unit for one of the player's ships.
func unit_of(sh: Dictionary) -> Dictionary:
	return Battle.unit(sh["type"], sh["name"], sh["mods"], sh.get("slot", "main"), sh["flagship"], int(sh.get("dmg", 0)), int(sh["id"]))


func fleet_power(sh: Dictionary) -> int:
	var p := 0
	for o in fleet_ships(sh):
		p += Battle.power(unit_of(o))
	return p


## Compose a pirate fleet of roughly the given power (at least one sloop).
func _pirate_fleet(target: int) -> Array:
	var out := []
	var flag := "p_sloop"
	if target >= 600:
		flag = "p_lord"
	elif target >= 300:
		flag = "p_raider"
	out.append(flag)
	var total := Battle.power(Battle.unit(flag, "", {}, "main", true))
	while total < int(float(target) * 0.8) and out.size() < 4:
		var t := "p_raider" if target - total >= 240 and rng.randf() < 0.5 else "p_sloop"
		out.append(t)
		total += Battle.power(Battle.unit(t, "", {}, "van", false))
	return out


func _fleet_power_of(types: Array) -> int:
	var p := 0
	for i in types.size():
		p += Battle.power(Battle.unit(types[i], "", {}, "main" if i == 0 else "van", i == 0))
	return p


func open_bounties() -> Array:
	return s["contracts"].filter(func(c): return c.get("kind", "trade") == "bounty")


func _post_bounty() -> void:
	var fl := flagship()
	if fl.is_empty():
		return
	var port: String = GameData.PORT_IDS[rng.randi() % GameData.PORT_IDS.size()]
	var power := int(float(fleet_power(fl)) * rng.randf_range(0.8, 1.2))
	var reward := int(roundf(float(power) * rng.randf_range(14.0, 20.0) / 100.0) * 100.0)
	var c := {"id": s["next_contract_id"], "kind": "bounty", "port": port, "good": "", "qty": 0, "reward": reward,
		"end": int(s["day"]) + rng.randi_range(90, 150), "chasers": [], "power": power, "taker": ""}
	s["next_contract_id"] = int(s["next_contract_id"]) + 1
	s["contracts"].append(c)
	_say("悬赏：云盗在 %s 外海劫船，城主悬赏 %d 金，%d 天内有效。到酒馆接下悬赏，驶抵该港即可迎战。" % [GameData.port_name(port), reward, int(c["end"]) - int(s["day"])], "contract")


func take_bounty(cid: int) -> Dictionary:
	var c := contract(cid)
	if c.is_empty() or c.get("kind", "trade") != "bounty":
		return _fail("这张悬赏已经撤下了。")
	for o in open_bounties():
		if o.get("taker", "") == pid() and int(o["id"]) != cid:
			return _fail("先了结手上那张悬赏。")
	if c.get("taker", "") == pid():
		c["taker"] = ""
		return {"ok": true, "msg": "放弃了 %s 的悬赏。" % GameData.port_name(c["port"])}
	c["taker"] = pid()
	return {"ok": true, "msg": "接下悬赏：驶抵 %s 即与云盗交战。" % GameData.port_name(c["port"])}


## Pirates (or a bounty target) cross the flagship's path; the game stops until the player chooses.
func start_encounter(kind: String, cid: int = -1) -> void:
	var fl := flagship()
	if fl.is_empty() or s["encounter"] != null:
		return
	var year := int(s["day"]) / GameData.DAYS_YEAR
	var diff_mult: float = [0.85, 1.0, 1.15][clampi(int(s["difficulty"]), 0, 2)]
	var target: int
	if kind == "bounty":
		var c := contract(cid)
		target = int(float(c.get("power", fleet_power(fl))) * 1.25 * diff_mult)
	else:
		target = int(float(fleet_power(fl)) * rng.randf_range(0.45, 0.85) * (1.0 + 0.05 * float(year)) * diff_mult)
	var enemies := _pirate_fleet(maxi(100, target))
	target = _fleet_power_of(enemies)
	var where: String = (GameData.port_name(fl["port"]) + " 外海") if docked(fl) else ("前往 %s 的航路上" % GameData.port_name(fl["to"]))
	s["encounter"] = {"kind": kind, "cid": cid, "enemies": enemies, "power": target, "where": where}
	_say("%s，%d 艘云盗船拦住了 %s 的去路！" % [where, enemies.size(), fl["name"]], "bad")


func encounter_text() -> String:
	var e = s["encounter"]
	if e == null:
		return ""
	var names := []
	for t in e["enemies"]:
		names.append(GameData.SHIPS[t]["name"])
	return "%s，%s 挂着云盗旗冲了过来。你的船队战力约 %d，对方约 %d。" % [e["where"], "、".join(names), fleet_power(flagship()), int(e["power"])]


func toll() -> int:
	var t := maxf(float(GameData.TOLL_MIN), maxf(0.0, float(house()["gold"])) * GameData.TOLL_RATE)
	return int(t * maxf(0.4, 1.0 - 0.5 * spec_bonus("blackmarket")))


func encounter_pay() -> Dictionary:
	if s["encounter"] == null:
		return _fail("没有遭遇。")
	if s["encounter"]["kind"] == "bounty":
		return _fail("悬赏目标不收买路钱。")
	var t := toll()
	house()["gold"] -= t
	house()["month_out"] += t
	s["encounter"] = null
	_say("交了 %d 金过路费，云盗大笑着钻回云里。" % t, "info")
	return {"ok": true, "msg": "交了 %d 金过路费。" % t}


## Chance that the fleet outruns the pirates (seamanship and sails help).
func flee_chance() -> float:
	var fl := flagship()
	var slowest := 9.0
	for o in fleet_ships(fl):
		slowest = minf(slowest, float(GameData.SHIPS[o["type"]]["speed"]) * speed_mult(o))
	return clampf(0.3 + 0.07 * float(hero_abil("sail") - 1) + (slowest - 1.0) * 0.6 + 0.02 * float(post_level("nav")) + 0.15 * spec_bonus("fog_nav"), 0.1, 0.95)


func encounter_flee() -> Dictionary:
	if s["encounter"] == null:
		return _fail("没有遭遇。")
	if s["encounter"]["kind"] == "bounty":
		return _fail("你是来剿匪的。")
	if rng.randf() < flee_chance():
		var fl := flagship()
		for o in fleet_ships(fl):
			if not docked(o):
				o["arrive"] = int(o["arrive"]) + 1
		s["encounter"] = null
		_say("船队钻进云层甩开了云盗，多绕了一天。", "good")
		return {"ok": true, "msg": "甩开了云盗，航程多了一天。", "escaped": true}
	_say("云盗咬得太紧，甩不掉，只能迎战！", "bad")
	var r := encounter_fight()
	r["escaped"] = false
	for u in battle.alive(0):
		u["morale"] = maxi(0, int(u["morale"]) - 10)
	return r


func encounter_fight() -> Dictionary:
	if s["encounter"] == null:
		return _fail("没有遭遇。")
	var fl := flagship()
	var mine := []
	for o in fleet_ships(fl):
		mine.append(unit_of(o))
	var foes := []
	var i := 0
	for t in s["encounter"]["enemies"]:
		foes.append(Battle.unit(t, ["黑帆号", "夜枭号", "断桅号", "蚀月号"][i % 4], {}, "main" if i == 0 else "van", i == 0))
		i += 1
	battle = Battle.new()
	battle.setup(mine, foes, battle_hero(), int(s["seed"]) + int(s["day"]) * 7, int(s["difficulty"]))
	s["battle"] = battle.b
	return {"ok": true, "msg": "接战！"}


## Apply the finished battle to the world: damage, lost and captured ships, loot, reputation.
func end_battle() -> Dictionary:
	if battle == null or battle.b["over"] == "":
		return _fail("战斗还没结束。")
	var res: String = battle.b["over"]
	var fl := flagship()
	var h := house()
	var out := {"res": res, "gold": 0, "goods": [], "lost": [], "won": [], "rep": 0, "exp": 0, "bounty": 0}
	for u in battle.b["units"]:
		if int(u["home"]) == 0:
			var sh := ship(int(u["ship_id"]))
			if sh.is_empty():
				continue
			var gone: bool = u["status"] == "sunk" or (u["status"] == "ok" and int(u["side"]) == 1 and res != "win")
			if gone and not sh["flagship"]:
				out["lost"].append(sh["name"])
				_remove_ship(sh)
			elif gone:
				sh["dmg"] = 85
				sh["cargo"] = {}
			else:
				sh["dmg"] = clampi(int(roundf(100.0 * (1.0 - float(u["hp"]) / float(u["hp_max"])))), 0, 95)
		elif res == "win":
			if u["status"] == "ok" and int(u["side"]) == 0:
				var price := int(GameData.SHIPS[u["type"]]["price"])
				if _ships_of(pid()).size() < max_ships():
					var ns := _add_ship(pid(), u["type"], fl["port"])
					ns["dmg"] = clampi(int(roundf(100.0 * (1.0 - float(u["hp"]) / float(u["hp_max"])))), 0, 95)
					for k in ["from", "to", "depart", "arrive"]:
						ns[k] = fl[k]
					ns["fleet"] = int(fl["id"])
					ns["slot"] = "rear"
					out["won"].append("%s（%s）" % [ns["name"], GameData.SHIPS[u["type"]]["name"]])
				else:
					out["gold"] = int(out["gold"]) + int(price * 0.4)
					out["won"].append("%s（船队已满，折价 %d 金）" % [GameData.SHIPS[u["type"]]["name"], int(price * 0.4)])
				out["gold"] = int(out["gold"]) + int(price * 0.06)
			elif u["status"] == "sunk":
				out["gold"] = int(out["gold"]) + int(int(u["value"]) * 0.06)
			elif u["status"] == "fled":
				out["gold"] = int(out["gold"]) + int(int(u["value"]) * 0.02)
			else:
				out["gold"] = int(out["gold"]) + int(int(u["value"]) * 0.12)
	var n: int = s["encounter"]["enemies"].size() if s["encounter"] != null else 1
	if res == "win":
		var free := fleet_cargo_cap(fl) - fleet_cargo_used(fl)
		var pool := GameData.GOOD_IDS.filter(func(g): return GameData.tier(g) <= 2 and GameData.GOODS[g]["home"] != "")
		var g: String = pool[rng.randi() % pool.size()]
		var qty := mini(free, 15 + 10 * n + rng.randi_range(0, 10))
		if qty > 0:
			_stow(fl, g, qty, 0.0)
			out["goods"].append([g, qty])
		out["rep"] = 60
		out["exp"] = 60 + 25 * n
		if s["encounter"] != null and s["encounter"]["kind"] == "bounty":
			var c := contract(int(s["encounter"]["cid"]))
			if not c.is_empty():
				out["bounty"] = int(c["reward"])
				out["rep"] = int(out["rep"]) + GameData.BOUNTY_REP
				add_friend(c["port"], pid(), 120)
				s["contracts"].erase(c)
		h["gold"] += float(out["gold"]) + float(out["bounty"])
		h["month_in"] += float(out["gold"]) + float(out["bounty"])
		add_rep(pid(), int(out["rep"]))
		add_exp(int(out["exp"]))
		s["stats"]["wins"] = int(s["stats"].get("wins", 0)) + 1
		for cid in s["crew"]:
			add_affinity(cid, 8)
	elif res == "loss":
		var t := int(maxf(300.0, maxf(0.0, float(h["gold"])) * 0.10))
		h["gold"] -= t
		h["month_out"] += t
		out["gold"] = -t
		for o in fleet_ships(fl):
			o["cargo"] = {}
		out["exp"] = 20
		add_exp(20)
		for cid in s["crew"]:
			add_affinity(cid, -5)
	else:
		out["exp"] = 15
		add_exp(15)
	s["stats"]["battles"] = int(s["stats"].get("battles", 0)) + 1
	var text: String = {"win": "击退云盗", "loss": "败给了云盗", "withdraw": "撤出了战斗"}[res]
	if int(out["gold"]) != 0 or int(out["bounty"]) != 0:
		text += "，金币 %+d" % (int(out["gold"]) + int(out["bounty"]))
	if not out["lost"].is_empty():
		text += "，失去 " + "、".join(out["lost"])
	if not out["won"].is_empty():
		text += "，俘获 " + "、".join(out["won"])
	_say(text + "。", "good" if res == "win" else "bad")
	out["text"] = text
	s["battle"] = null
	s["encounter"] = null
	s["battle_result"] = out
	battle = null
	return out


## Bots and tests: fight when the odds look fair, otherwise pay.
func auto_encounter() -> Dictionary:
	if s["encounter"] == null:
		return _fail("没有遭遇。")
	var fl := flagship()
	if s["encounter"]["kind"] != "bounty" and fleet_power(fl) < int(float(s["encounter"]["power"]) * 1.25):
		if house()["gold"] >= toll():
			return encounter_pay()
		var r := encounter_flee()
		if r.get("escaped", false):
			return r
	else:
		encounter_fight()
	battle.auto_play()
	return end_battle()


# ---------------------------------------------------------------- time

func blocked() -> bool:
	return s["over"] != null or s["event"] != null or s.get("encounter") != null


func advance_day() -> void:
	if blocked():
		return
	s["day"] += 1
	var day: int = s["day"]
	_tick_markets()
	Industry.tick(self)
	_tick_fashion()
	_tick_contracts()
	_tick_ships()
	_tick_lighthouses()
	_tick_crew()
	if day % GameData.DAYS_MONTH == 0:
		_monthly()
	_tick_crisis()
	EventBook.maybe_trigger(self)


func _tick_markets() -> void:
	for pid in GameData.PORT_IDS:
		var m: Dictionary = s["ports"][pid]["market"]
		for g in GameData.GOOD_IDS:
			var e: Dictionary = m[g]
			e["stock"] = maxf(0.0, e["stock"] + (e["eq"] - e["stock"]) * REVERT)


func _tick_fashion() -> void:
	var f = s.get("fashion")
	if f != null:
		if int(s["day"]) >= int(f["end"]):
			s["ports"][f["port"]]["market"][f["good"]]["eq"] = float(f["eq"])
			_say("风尚退潮：%s 的%s价格回落。" % [GameData.port_name(f["port"]), GameData.good_name(f["good"])], "info")
			s["fashion"] = null
		return
	if int(s["day"]) > 45 and rng.randf() < 1.0 / 75.0:
		var port: String = GameData.PORT_IDS[rng.randi() % GameData.PORT_IDS.size()]
		var options: Array = GameData.traded_goods(port).filter(func(g): return not g in GameData.PORTS[port]["make"])
		var good: String = options[rng.randi() % options.size()]
		var m: Dictionary = s["ports"][port]["market"][good]
		s["fashion"] = {"port": port, "good": good, "eq": m["eq"], "end": int(s["day"]) + 60}
		m["eq"] = m["eq"] * 0.35
		_say("风尚：%s 突然追捧%s，未来两个月价格会大涨。" % [GameData.port_name(port), GameData.good_name(good)], "major")


func _tick_ships() -> void:
	for sh in s["ships"].duplicate():
		if not docked(sh) and s["day"] >= sh["arrive"]:
			sh["port"] = sh["to"]
			sh["to"] = ""
			_on_arrive(sh)
		elif docked(sh):
			if int(sh.get("dmg", 0)) > 0:
				sh["dmg"] = maxi(0, int(sh["dmg"]) - GameData.DOCK_REPAIR)
			if sh["owner"] == pid() and sh["route"] != null:
				_run_route(sh)
			elif sh["owner"] != pid():
				AiPlayer.ship_turn(self, sh)


func _on_arrive(sh: Dictionary) -> void:
	if sh["owner"] == pid():
		_update_intel(sh["port"])
		if sh["flagship"]:
			var hero: Dictionary = s["hero"]
			hero["days_sailed"] = int(hero["days_sailed"]) + int(sh["arrive"]) - int(sh["depart"])
			var first: bool = not hero["visited"].has(sh["port"])
			hero["visited"][sh["port"]] = true
			add_exp((int(sh["arrive"]) - int(sh["depart"])) * 3 + (40 if first else 0))
		if sh["route"] != null:
			_run_route(sh)
		elif sh["flagship"]:
			_say("%s 抵达 %s。" % [sh["name"], GameData.port_name(sh["port"])])
			s["arrived"] = sh["id"]
			for c in s["contracts"]:
				if c.get("kind", "trade") == "bounty" and c.get("taker", "") == pid() and c["port"] == sh["port"]:
					start_encounter("bounty", int(c["id"]))
					break
	else:
		AiPlayer.ship_turn(self, sh)


func _run_route(sh: Dictionary) -> void:
	if not sh["route"].has("stops"):
		sh["route"] = normalize_route(sh["route"])
	var r: Dictionary = sh["route"]
	var stops: Array = r["stops"]
	var port: String = sh["port"]
	var idx := -1
	for i in stops.size():
		if stops[i]["port"] == port:
			idx = i
	if idx < 0:
		# off the loop: head for the first stop
		var res0 := depart(sh["id"], stops[0]["port"])
		if not res0["ok"]:
			r["stalled"] = res0["msg"]
		return
	var here: Dictionary = stops[idx]
	var buys: Array = here["buy"]
	# sell everything this stop is not meant to load
	for g in sh["cargo"].keys():
		if g in buys or not GameData.trades(port, g):
			continue
		var res := sell(sh["id"], g, int(sh["cargo"][g]["qty"]))
		if res["ok"]:
			r["last_profit"] = res["profit"]
			r["total"] = int(r.get("total", 0)) + int(res["profit"])
	# load the shopping list, an even share of the hold per good, while it still pays somewhere ahead
	if not buys.is_empty():
		var share := maxi(1, (cargo_cap(sh) - cargo_used(sh)) / buys.size())
		var h := house()
		var reserve := 1500.0
		for g in buys:
			var best_sell := 0
			for j in range(1, stops.size()):
				var other: Dictionary = stops[(idx + j) % stops.size()]
				if not g in other["buy"]:
					best_sell = maxi(best_sell, sell_price(other["port"], g))
			var limit := float(best_sell) * 0.85
			var n := 0
			while n < share and cargo_used(sh) < cargo_cap(sh) and buy_price(port, g) <= limit and h["gold"] - buy_price(port, g) > reserve:
				if not buy(sh["id"], g, 1)["ok"]:
					break
				n += 1
	var nxt: Dictionary = stops[(idx + 1) % stops.size()]
	r["i"] = (idx + 1) % stops.size()
	var res2 := depart(sh["id"], nxt["port"])
	if not res2["ok"]:
		r["stalled"] = res2["msg"]
	else:
		r.erase("stalled")


func _tick_lighthouses() -> void:
	for hid in GameData.HOUSE_IDS:
		var h: Dictionary = s["houses"][hid]
		if h["bankrupt"]:
			continue
		var lh: Dictionary = h["lh"]
		if lh["building"] and s["day"] >= lh["end"]:
			lh["building"] = false
			var st: Dictionary = GameData.LIGHTHOUSE[lh["stage"]]
			lh["stage"] += 1
			lh["mats"] = {}
			var who: String = GameData.HOUSES[hid]["name"]
			_say("%s 的灯塔%s落成（%d/3）。" % [who, st["name"], lh["stage"]], "good" if hid == pid() else "major")
			add_rep(hid, [300, 600, 2000][lh["stage"] - 1])
			if lh["stage"] >= GameData.LIGHTHOUSE.size() and s["crown"] == null:
				s["crown"] = {"hid": hid, "day": s["day"]}
				if hid == pid():
					_say("你的灯冠第一个点亮。云海诸港奉%s为盟主！" % who, "major")
				else:
					_say("%s 先一步点亮灯冠，被诸港奉为盟主。你还可以继续经营，但盟主之位已定。" % who, "bad")


func _monthly() -> void:
	for hid in GameData.HOUSE_IDS:
		var h: Dictionary = s["houses"][hid]
		if h["bankrupt"]:
			continue
		var cost := 0.0
		for sh in _ships_of(hid):
			cost += float(GameData.SHIPS[sh["type"]]["wage"]) + float(GameData.SHIPS[sh["type"]]["price"]) * 0.01
		var interest: float = h["debt"] * GameData.LOAN_RATE
		cost += Industry.upkeep(self, hid)
		if hid == pid():
			cost += float(crew_wages())
		h["gold"] -= cost + interest
		h["month_out"] += cost + interest
		h["last_net"] = h["month_in"] - h["month_out"]
		h["last_upkeep"] = cost + interest
		h["month_in"] = 0.0
		h["month_out"] = 0.0
		if hid != pid():
			AiPlayer.monthly(self, hid)
		else:
			_say("月结：上月净收支 %+d 金（固定开支 %d）。" % [int(h["last_net"]), int(cost + interest)], "month")
			_crew_monthly()
		if hid == pid() and h["gold"] < 0.0:
			# automatic emergency loan before a crisis starts
			var room: float = loan_limit() - h["debt"]
			var need: float = -h["gold"] + 500.0
			if room >= need:
				h["debt"] += need
				h["gold"] += need
				_say("金库见底，商会银行自动放贷 %d 金。" % int(need), "bad")


func _tick_crisis() -> void:
	for hid in GameData.HOUSE_IDS:
		var h: Dictionary = s["houses"][hid]
		if h["bankrupt"]:
			continue
		if h["gold"] < 0.0:
			if h["crisis"] == 0 and hid == pid():
				_say("债务危机：%d 天内金币必须转正，否则商会破产！" % GameData.CRISIS_DAYS, "bad")
			h["crisis"] += 1
			if h["crisis"] >= GameData.CRISIS_DAYS:
				_bankrupt(hid)
		else:
			h["crisis"] = 0


func _bankrupt(hid: String) -> void:
	var h: Dictionary = s["houses"][hid]
	h["bankrupt"] = true
	if hid == pid():
		_end("bankrupt", hid)
		return
	_say("%s 宣告破产，退出云海。" % GameData.HOUSES[hid]["name"], "major")
	s["ships"] = s["ships"].filter(func(x): return x["owner"] != hid)
	for pid in GameData.PORT_IDS:
		var plots: Array = s["ports"][pid]["plots"]
		for i in plots.size():
			if plots[i] != null and plots[i]["owner"] == hid:
				plots[i] = null


const ENDINGS := {
	"bankrupt": {"title": "破产", "win": false, "text": "债主收走了最后一艘飞艇。{house}的旗帜从{home}降下。"},
}


func _end(kind: String, hid: String) -> void:
	if s["over"] != null:
		return
	var e: Dictionary = ENDINGS[kind]
	var score := int(net_worth() / 100.0) + int(house()["lh"]["stage"]) * 500 + int(s["story"]) * 150
	var me: Dictionary = GameData.HOUSES[pid()]
	var text: String = e["text"].format({"house": me["name"], "home": GameData.port_name(me["home"]), "winner": GameData.HOUSES[hid]["name"]})
	s["over"] = {"kind": kind, "title": e["title"], "text": text, "win": e["win"], "by": hid, "day": s["day"], "score": score}
	_say("结局 · " + e["title"], "major")
	game_over.emit(s["over"])


# ---------------------------------------------------------------- save / load

func to_json() -> String:
	s["rng_state"] = str(rng.state)
	return JSON.stringify(s)


func from_json(text: String) -> bool:
	var parsed = JSON.parse_string(text)
	if typeof(parsed) != TYPE_DICTIONARY:
		return false
	if not parsed.has("ports") or not parsed["ports"].get("qianqi", {}).has("friend"):
		return false   # save from before the production-chain update
	s = parsed
	rng.seed = int(s["seed"])
	rng.state = int(s.get("rng_state", "0"))
	# JSON turns ints into floats; normalise the ones we use as ints/ids
	for k in ["day", "next_ship_id", "story", "tutorial"]:
		s[k] = int(s[k])
	if s["crown"] != null:
		s["crown"]["day"] = int(s["crown"]["day"])
	if not s.has("hero"):
		s["hero"] = {"lvl": 1, "exp": 0, "pts": 0, "abil": {"sail": 1, "trade": 1, "fight": 1, "charm": 1}, "days_sailed": 0, "visited": {}}
	for k in ["lvl", "exp", "pts", "days_sailed"]:
		s["hero"][k] = int(s["hero"][k])
	for k in s["hero"]["abil"]:
		s["hero"]["abil"][k] = int(s["hero"]["abil"][k])
	for g in s["stats"]["handled"]:
		s["stats"]["handled"][g] = int(s["stats"]["handled"][g])
	for sh in s["ships"]:
		for k in ["id", "depart", "arrive"]:
			sh[k] = int(sh[k])
		for g in sh["cargo"]:
			sh["cargo"][g]["qty"] = int(sh["cargo"][g]["qty"])
		if not sh.has("mods"):
			sh["mods"] = {"hull": 0, "sail": 0, "hold": 0, "guns": 0}
		for k in sh["mods"]:
			sh["mods"][k] = int(sh["mods"][k])
		sh["fleet"] = int(sh.get("fleet", 0))
		sh["dmg"] = int(sh.get("dmg", 0))
		if not sh.has("slot"):
			sh["slot"] = "main"
		if sh["route"] != null:
			sh["route"] = normalize_route(sh["route"])
	if not s.has("contracts"):
		s["contracts"] = []
		s["next_contract_id"] = 1
	s["next_contract_id"] = int(s["next_contract_id"])
	for c in s["contracts"]:
		for k in ["id", "qty", "reward", "end"]:
			c[k] = int(c[k])
		if c.has("power"):
			c["power"] = int(c["power"])
	for k in ["encounter", "battle", "battle_result"]:
		if not s.has(k):
			s[k] = null
	if not s.has("crew"):
		s["crew"] = {}
	if not s.has("roam"):
		s["roam"] = {"port": "", "until": 0}
	s["roam"]["until"] = int(s["roam"]["until"])
	for cid in s["crew"]:
		var m: Dictionary = s["crew"][cid]
		for k in ["aff", "chapter", "ship", "joined", "gift_month", "spec_lvl"]:
			m[k] = int(m.get(k, 0))
	if s["encounter"] != null:
		for k in ["cid", "power"]:
			s["encounter"][k] = int(s["encounter"][k])
	if s["battle"] != null:
		var bb: Dictionary = s["battle"]
		for k in ["round", "cur", "cp", "cp_max", "fight", "hero_lvl", "focus", "bonus_move", "difficulty"]:
			bb[k] = int(bb[k])
		bb["order"] = bb["order"].map(func(x): return int(x))
		bb["events"] = []
		for k in bb["smoke"]:
			bb["smoke"][k] = int(bb["smoke"][k])
		for u in bb["units"]:
			for k in ["id", "side", "home", "hp", "hp_max", "crew", "crew_max", "guns", "move", "col", "row", "morale", "moved", "value", "ship_id", "sprite"]:
				u[k] = int(u[k])
		battle = Battle.new()
		battle.b = bb
		battle.rng.seed = int(s["seed"]) + int(s["day"]) * 7
	for pid in s["ports"]:
		var p: Dictionary = s["ports"][pid]
		for hid in p["friend"]:
			p["friend"][hid] = int(p["friend"][hid])
		for hid in p["whcap"]:
			p["whcap"][hid] = int(p["whcap"][hid])
		for hid in p["wh"]:
			for g in p["wh"][hid]:
				p["wh"][hid][g] = int(p["wh"][hid][g])
	for hid in s["houses"]:
		var lh: Dictionary = s["houses"][hid]["lh"]
		lh["stage"] = int(lh["stage"])
		lh["end"] = int(lh["end"])
		s["houses"][hid]["crisis"] = int(s["houses"][hid]["crisis"])
		s["houses"][hid]["rep"] = int(s["houses"][hid]["rep"])
	return true
