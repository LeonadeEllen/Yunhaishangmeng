class_name Industry
## Town building, production chains, warehouses and city prosperity.
## State per port (in sim.s["ports"][pid]):
##   plots: Array of null or {b, owner, in_mode ("wh"|"buy"), out_mode ("wh"|"sell"|"lh"), acc, status}
##   wh: {hid: {good: qty}}, whcap: {hid: int}, prosp: int 1..5, growth: int


static func init_port(sim: Sim, pid: String) -> void:
	var p: Dictionary = sim.s["ports"][pid]
	var plots := []
	for i in GameData.PORTS[pid]["plots"].size():
		plots.append(null)
	p["plots"] = plots
	p["wh"] = {}
	p["whcap"] = {}
	p["prosp"] = int(GameData.PORTS[pid]["prosp"])
	p["growth"] = 0


# ------------------------------------------------------------------ queries

static func open_plots(sim: Sim, pid: String) -> int:
	return mini(GameData.PORTS[pid]["plots"].size(), 2 + int(sim.s["ports"][pid]["prosp"]))


static func terrain(pid: String, i: int) -> String:
	return GameData.PORTS[pid]["plots"][i]


static func buildings_for(pid: String, i: int) -> Array:
	var t := terrain(pid, i)
	return GameData.BUILDING_IDS.filter(func(b): return GameData.BUILDINGS[b]["plot"] == t)


static func build_cost(sim: Sim, b: String, hid: String) -> int:
	return int(float(GameData.BUILDINGS[b]["cost"]) * (0.75 if sim.perk(hid) == "industry" else 1.0))


static func rate(sim: Sim, pid: String, b: String, hid: String) -> float:
	var d: Dictionary = GameData.BUILDINGS[b]
	var r: float = d["rate"]
	if GameData.PORTS[pid]["signature"] in d["out"]:
		r *= GameData.SIGNATURE_BONUS
	if sim.perk(hid) == "industry":
		r *= 1.15
	return r


static func count_buildings(sim: Sim, pid: String, hid: String) -> int:
	var n := 0
	for pl in sim.s["ports"][pid]["plots"]:
		if pl != null and pl["owner"] == hid:
			n += 1
	return n


static func all_buildings(sim: Sim, hid: String) -> Array:
	## [{port, idx, plot}] for every building `hid` owns.
	var out := []
	for pid in GameData.PORT_IDS:
		var plots: Array = sim.s["ports"][pid]["plots"]
		for i in plots.size():
			if plots[i] != null and plots[i]["owner"] == hid:
				out.append({"port": pid, "idx": i, "plot": plots[i]})
	return out


static func has_wh(sim: Sim, pid: String, hid: String) -> bool:
	return sim.s["ports"][pid]["whcap"].has(hid)


static func wh(sim: Sim, pid: String, hid: String) -> Dictionary:
	var w: Dictionary = sim.s["ports"][pid]["wh"]
	if not w.has(hid):
		w[hid] = {}
	return w[hid]


static func wh_used(sim: Sim, pid: String, hid: String) -> int:
	var n := 0
	var w := wh(sim, pid, hid)
	for g in w:
		n += int(w[g])
	return n


static func wh_cap(sim: Sim, pid: String, hid: String) -> int:
	return int(sim.s["ports"][pid]["whcap"].get(hid, 0))


static func wh_add(sim: Sim, pid: String, hid: String, g: String, qty: int) -> int:
	## Adds up to qty; returns how many fit.
	var room := wh_cap(sim, pid, hid) - wh_used(sim, pid, hid)
	var n := mini(qty, room)
	if n <= 0:
		return 0
	var w := wh(sim, pid, hid)
	w[g] = int(w.get(g, 0)) + n
	return n


static func wh_take(sim: Sim, pid: String, hid: String, g: String, qty: int) -> int:
	var w := wh(sim, pid, hid)
	var n := mini(qty, int(w.get(g, 0)))
	if n <= 0:
		return 0
	w[g] = int(w[g]) - n
	if int(w[g]) <= 0:
		w.erase(g)
	return n


## Rough profit per day if a building runs flat out buying inputs and selling output at this port's market.
static func est_daily(sim: Sim, pid: String, b: String, hid: String) -> float:
	var d: Dictionary = GameData.BUILDINGS[b]
	var v := 0.0
	for g in d["out"]:
		if not GameData.trades(pid, g):
			return -INF
		v += float(sim.sell_price(pid, g, hid)) * float(d["out"][g])
	for g in d["in"]:
		if not GameData.trades(pid, g):
			return -INF
		v -= float(sim.buy_price(pid, g, hid)) * float(d["in"][g])
	return v * rate(sim, pid, b, hid) - float(d["upkeep"]) / 30.0


## Value of one cycle's output at the best price you know of (for UI hints), minus inputs at local prices.
static func cycle_value_hint(sim: Sim, pid: String, b: String, hid: String) -> float:
	var d: Dictionary = GameData.BUILDINGS[b]
	var v := 0.0
	for g in d["out"]:
		v += float(GameData.GOODS[g]["base"]) * float(d["out"][g])
	for g in d["in"]:
		v -= float(GameData.GOODS[g]["base"]) * float(d["in"][g])
	return v * rate(sim, pid, b, hid)


# ------------------------------------------------------------------ actions

static func open_wh(sim: Sim, pid: String, hid: String = "", free: bool = false) -> Dictionary:
	if hid == "":
		hid = sim.pid()
	if has_wh(sim, pid, hid):
		return sim._fail("这里已经有你的仓库。")
	var h := sim.house(hid)
	if not free:
		if h["gold"] < GameData.WH_RENT:
			return sim._fail("需要 %d 金。" % GameData.WH_RENT)
		h["gold"] -= GameData.WH_RENT
		h["month_out"] += GameData.WH_RENT
	sim.s["ports"][pid]["whcap"][hid] = GameData.WH_START
	wh(sim, pid, hid)
	return {"ok": true, "msg": "在 %s 开设了仓库（容量 %d）。" % [GameData.port_name(pid), GameData.WH_START]}


static func upgrade_wh(sim: Sim, pid: String, hid: String = "") -> Dictionary:
	if hid == "":
		hid = sim.pid()
	var cap := wh_cap(sim, pid, hid)
	if cap <= 0:
		return sim._fail("先开设仓库。")
	if cap >= GameData.WH_MAX:
		return sim._fail("仓库已是最大。")
	var h := sim.house(hid)
	if h["gold"] < GameData.WH_UPGRADE:
		return sim._fail("需要 %d 金。" % GameData.WH_UPGRADE)
	h["gold"] -= GameData.WH_UPGRADE
	h["month_out"] += GameData.WH_UPGRADE
	sim.s["ports"][pid]["whcap"][hid] = cap + GameData.WH_STEP
	return {"ok": true, "msg": "仓库扩建到 %d。" % (cap + GameData.WH_STEP)}


static func build(sim: Sim, pid: String, i: int, b: String, hid: String = "") -> Dictionary:
	if hid == "":
		hid = sim.pid()
	var plots: Array = sim.s["ports"][pid]["plots"]
	if i < 0 or i >= open_plots(sim, pid):
		return sim._fail("这块地还没开放，城市繁荣后才能用。")
	if plots[i] != null:
		return sim._fail("这块地已经有建筑了。")
	if not b in buildings_for(pid, i):
		return sim._fail("%s 上不能建 %s。" % [GameData.TERRAIN[terrain(pid, i)], GameData.BUILDINGS[b]["name"]])
	var cost := build_cost(sim, b, hid)
	var h := sim.house(hid)
	if h["gold"] < cost:
		return sim._fail("需要 %d 金。" % cost)
	h["gold"] -= cost
	h["month_out"] += cost
	if not has_wh(sim, pid, hid):
		open_wh(sim, pid, hid, true)
	var out_mode := "wh"
	if hid != sim.pid():
		out_mode = "sell"
	plots[i] = {"b": b, "owner": hid, "in_mode": "buy" if hid != sim.pid() else "wh", "out_mode": out_mode, "acc": 0.0, "status": "ok"}
	var msg := "%s 在 %s 建起了%s。" % [GameData.HOUSES[hid]["name"], GameData.port_name(pid), GameData.BUILDINGS[b]["name"]]
	if hid != sim.pid():
		sim._say(msg, "rival")
	return {"ok": true, "msg": msg}


static func set_mode(sim: Sim, pid: String, i: int, key: String, value: String) -> Dictionary:
	var pl = sim.s["ports"][pid]["plots"][i]
	if pl == null or pl["owner"] != sim.pid():
		return sim._fail("不是你的建筑。")
	if key == "out_mode" and value == "lh" and pid != GameData.HOUSES[sim.pid()]["home"]:
		return sim._fail("只有母港的建筑能直送灯塔工地。")
	pl[key] = value
	pl["status"] = "ok"
	return {"ok": true, "msg": "已更新。"}


static func demolish(sim: Sim, pid: String, i: int) -> Dictionary:
	var pl = sim.s["ports"][pid]["plots"][i]
	if pl == null or pl["owner"] != sim.pid():
		return sim._fail("不是你的建筑。")
	var refund := int(float(build_cost(sim, pl["b"], sim.pid())) * 0.3)
	sim.house()["gold"] += refund
	sim.s["ports"][pid]["plots"][i] = null
	return {"ok": true, "msg": "拆除%s，回收 %d 金。" % [GameData.BUILDINGS[pl["b"]]["name"], refund]}


static func buyout_cost(sim: Sim, pid: String, i: int, hid: String = "") -> int:
	var pl = sim.s["ports"][pid]["plots"][i]
	if pl == null:
		return 0
	return int(float(GameData.BUILDINGS[pl["b"]]["cost"]) * GameData.BUYOUT_MULT)


static func buyout(sim: Sim, pid: String, i: int, hid: String = "") -> Dictionary:
	if hid == "":
		hid = sim.pid()
	var pl = sim.s["ports"][pid]["plots"][i]
	if pl == null or pl["owner"] == hid:
		return sim._fail("没有可收购的建筑。")
	var cost := buyout_cost(sim, pid, i, hid)
	var h := sim.house(hid)
	if h["gold"] < cost:
		return sim._fail("需要 %d 金。" % cost)
	var target: String = pl["owner"]
	var before := sim.patron(pid)
	h["gold"] -= cost
	h["month_out"] += cost
	var comp := float(GameData.BUILDINGS[pl["b"]]["cost"])
	sim.house(target)["gold"] += comp
	sim.house(target)["month_in"] += comp
	pl["owner"] = hid
	pl["acc"] = 0.0
	pl["status"] = "ok"
	if hid == sim.pid():
		pl["in_mode"] = "buy"
		pl["out_mode"] = "wh"
	else:
		pl["in_mode"] = "buy"
		pl["out_mode"] = "sell"
	if not has_wh(sim, pid, hid):
		open_wh(sim, pid, hid, true)
	var who: String = GameData.HOUSES[hid]["name"]
	var msg := "%s 收购了 %s 在 %s 的%s。" % [who, GameData.HOUSES[target]["name"], GameData.port_name(pid), GameData.BUILDINGS[pl["b"]]["name"]]
	if sim.patron(pid) != before and sim.patron(pid) == hid:
		msg += " %s 成为 %s 港主。" % [who, GameData.port_name(pid)]
	sim._say(msg, "good" if hid == sim.pid() else ("bad" if target == sim.pid() else "major"))
	return {"ok": true, "msg": msg}


# ------------------------------------------------------------------ simulation

static func tick(sim: Sim) -> void:
	for pid in GameData.PORT_IDS:
		var plots: Array = sim.s["ports"][pid]["plots"]
		for i in plots.size():
			var pl = plots[i]
			if pl == null or sim.house(pl["owner"])["bankrupt"]:
				continue
			pl["acc"] = minf(float(pl["acc"]) + rate(sim, pid, pl["b"], pl["owner"]), 3.0)
			var guard := 0
			while float(pl["acc"]) >= 1.0 and guard < 8:
				guard += 1
				if not _cycle(sim, pid, pl):
					pl["acc"] = minf(float(pl["acc"]), 1.0)
					break
				pl["acc"] = float(pl["acc"]) - 1.0


static func _cycle(sim: Sim, pid: String, pl: Dictionary) -> bool:
	var d: Dictionary = GameData.BUILDINGS[pl["b"]]
	var hid: String = pl["owner"]
	var h := sim.house(hid)
	# 1. check inputs: warehouse first, then the market if allowed
	var from_wh := {}
	var to_buy := {}
	for g in d["in"]:
		var need: int = d["in"][g]
		var have := mini(need, int(wh(sim, pid, hid).get(g, 0)))
		from_wh[g] = have
		if have < need:
			if pl["in_mode"] == "buy" and GameData.trades(pid, g):
				to_buy[g] = need - have
			else:
				pl["status"] = "缺" + GameData.good_name(g)
				return false
	var buy_cost := 0.0
	for g in to_buy:
		var q := sim.quote_buy(pid, g, to_buy[g], hid)
		if q["qty"] < to_buy[g]:
			pl["status"] = "本港%s断货" % GameData.good_name(g)
			return false
		buy_cost += q["cost"]
	if buy_cost > 0.0 and h["gold"] - buy_cost < 0.0:
		pl["status"] = "金币不足，买不起原料"
		return false
	# 2. where does the output go?
	var out_mode: String = pl["out_mode"]
	for g in d["out"]:
		if out_mode == "lh" and not _lh_needs(sim, hid, g):
			out_mode = "wh" if hid == sim.pid() else "sell"
		if out_mode == "sell" and not GameData.trades(pid, g):
			out_mode = "wh"
		if out_mode == "wh" and wh_cap(sim, pid, hid) - wh_used(sim, pid, hid) < int(d["out"][g]):
			if GameData.trades(pid, g) and hid != sim.pid():
				out_mode = "sell"
			else:
				pl["status"] = "仓库已满"
				return false
	# 3. run the cycle
	for g in from_wh:
		wh_take(sim, pid, hid, g, from_wh[g])
	for g in to_buy:
		var q2 := sim.quote_buy(pid, g, to_buy[g], hid)
		h["gold"] -= q2["cost"]
		h["month_out"] += q2["cost"]
		sim.s["ports"][pid]["market"][g]["stock"] -= q2["qty"]
	for g in d["out"]:
		var n: int = d["out"][g]
		match out_mode:
			"sell":
				var r := sim.quote_sell(pid, g, n, hid)
				h["gold"] += r["revenue"]
				h["month_in"] += r["revenue"]
				sim.s["ports"][pid]["market"][g]["stock"] += n
			"lh":
				var lh: Dictionary = h["lh"]
				lh["mats"][g] = int(lh["mats"].get(g, 0)) + n
			_:
				wh_add(sim, pid, hid, g, n)
	pl["status"] = "ok"
	return true


static func _lh_needs(sim: Sim, hid: String, g: String) -> bool:
	var lh: Dictionary = sim.house(hid)["lh"]
	if lh["building"] or lh["stage"] >= GameData.LIGHTHOUSE.size():
		return false
	var need: Dictionary = GameData.LIGHTHOUSE[lh["stage"]]["mats"]
	return need.has(g) and int(lh["mats"].get(g, 0)) < int(need[g])


static func upkeep(sim: Sim, hid: String) -> float:
	var c := 0.0
	for b in all_buildings(sim, hid):
		c += float(GameData.BUILDINGS[b["plot"]["b"]]["upkeep"])
	for pid in GameData.PORT_IDS:
		var cap := wh_cap(sim, pid, hid)
		if cap > 0:
			c += float(cap) * 0.5
	return c


## Monthly: a city grows when the goods it wants are in good supply, shrinks when they are scarce.
static func monthly_prosperity(sim: Sim) -> void:
	for pid in GameData.PORT_IDS:
		var p: Dictionary = sim.s["ports"][pid]
		var wants: Array = GameData.PORTS[pid]["want"]
		var ok := 0
		for g in wants:
			var e: Dictionary = p["market"][g]
			if float(e["stock"]) >= float(e["eq"]) * 0.75:
				ok += 1
		var ratio := float(ok) / float(maxi(1, wants.size()))
		if ratio >= 0.5:
			p["growth"] = int(p["growth"]) + 1
		elif ratio < 0.25:
			p["growth"] = int(p["growth"]) - 1
		if int(p["growth"]) >= 4 and int(p["prosp"]) < GameData.PROSP_MAX:
			p["prosp"] = int(p["prosp"]) + 1
			p["growth"] = 0
			_apply_demand(sim, pid)
			sim._say("%s 日渐繁荣（%d 级）：需求变大，开放了新的地块。" % [GameData.port_name(pid), int(p["prosp"])], "major")
		elif int(p["growth"]) <= -4 and int(p["prosp"]) > 1:
			p["prosp"] = int(p["prosp"]) - 1
			p["growth"] = 0
			_apply_demand(sim, pid)
			sim._say("%s 因长期短缺而衰落（%d 级）。" % [GameData.port_name(pid), int(p["prosp"])], "bad")


## Wanted goods: richer cities consume more, so their equilibrium stock sits lower (higher prices, more volume).
static func _apply_demand(sim: Sim, pid: String) -> void:
	var p: Dictionary = sim.s["ports"][pid]
	var k := 1.0 + 0.12 * float(int(p["prosp"]) - int(GameData.PORTS[pid]["prosp"]))
	for g in GameData.PORTS[pid]["want"]:
		var e: Dictionary = p["market"][g]
		if not e.has("eq0"):
			e["eq0"] = e["eq"]
		e["eq"] = float(e["eq0"]) / maxf(0.5, k)


## How well a city's wants are being met right now, 0..1 per good.
static func supply(sim: Sim, pid: String) -> Dictionary:
	var out := {}
	for g in GameData.PORTS[pid]["want"]:
		var e: Dictionary = sim.s["ports"][pid]["market"][g]
		out[g] = clampf(float(e["stock"]) / (float(e["eq"]) * 0.75), 0.0, 1.0)
	return out


# ------------------------------------------------------------------ rivals

## A rival builds the most profitable building it can afford, preferring its home port.
static func ai_build(sim: Sim, hid: String, budget: float) -> void:
	if all_buildings(sim, hid).size() >= 6:
		return
	var best := {}
	var best_score := 0.0
	var home: String = GameData.HOUSES[hid]["home"]
	for pid in GameData.PORT_IDS:
		var plots: Array = sim.s["ports"][pid]["plots"]
		for i in open_plots(sim, pid):
			if plots[i] != null:
				continue
			for b in buildings_for(pid, i):
				var cost := build_cost(sim, b, hid)
				if cost > budget:
					continue
				var daily := est_daily(sim, pid, b, hid)
				var lh_bonus := 0.0
				if pid == home:
					for g in GameData.BUILDINGS[b]["out"]:
						if _lh_needs(sim, hid, g):
							lh_bonus = float(GameData.GOODS[g]["base"]) * rate(sim, pid, b, hid) * 0.8
				var score := (daily + lh_bonus) * 30.0 / float(cost) * (1.3 if pid == home else 1.0)
				if score > best_score and score > 0.12:
					best_score = score
					best = {"port": pid, "idx": i, "b": b}
	if best.is_empty():
		return
	var r := build(sim, best["port"], best["idx"], best["b"], hid)
	if r["ok"] and best["port"] == home:
		sim.s["ports"][home]["plots"][best["idx"]]["out_mode"] = "lh"
