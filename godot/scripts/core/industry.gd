class_name Industry
## Workshops (one per good), trading posts (商馆 = warehouse) and production.
## Per port (in sim.s["ports"][pid]):
##   plots: Array of null or {b: good id, lvl 1..3, owner, in_mode ("wh"|"buy"), out_mode ("wh"|"sell"|"lh"), status}
##   wh: {hid: {good: qty}}, whcap: {hid: int}
## Everything produced is in whole units: a level-1 workshop makes TIER_OUTPUT[tier] units a day.


static func init_port(sim: Sim, pid: String) -> void:
	var p: Dictionary = sim.s["ports"][pid]
	var plots := []
	for i in GameData.PORTS[pid]["plots"].size():
		plots.append(null)
	p["plots"] = plots
	p["wh"] = {}
	p["whcap"] = {}


# ------------------------------------------------------------------ queries

static func terrain(pid: String, i: int) -> String:
	return GameData.PORTS[pid]["plots"][i]


static func terrain_name(pid: String, i: int) -> String:
	var t := terrain(pid, i)
	return "工坊地" if t == "workshop" else GameData.good_name(t) + "产地"


## Goods whose workshop fits plot i (blueprint not considered).
static func goods_for(pid: String, i: int) -> Array:
	return GameData.GOOD_IDS.filter(func(g): return GameData.plot_fits(pid, i, g))


static func build_cost(sim: Sim, g: String, hid: String) -> int:
	return int(float(GameData.build_cost(g)) * (0.75 if sim.perk(hid) == "industry" else 1.0))


static func upgrade_cost(sim: Sim, g: String, hid: String) -> int:
	return int(float(build_cost(sim, g, hid)) * GameData.BUILD_LEVEL_MULT)


## Units per day.
static func output(sim: Sim, pid: String, pl: Dictionary) -> int:
	var g: String = pl["b"]
	var n: int = GameData.TIER_OUTPUT[GameData.tier(g)] + int(pl["lvl"]) - 1
	if g in GameData.PORTS[pid]["make"]:
		n += GameData.SIGNATURE_BONUS
	if sim.perk(pl["owner"]) == "industry":
		n += 1
	if pl["owner"] == sim.pid():
		n = int(roundf(float(n) * (1.0 + 0.15 * sim.spec_bonus("forge"))))
	return n


static func count_buildings(sim: Sim, pid: String, hid: String) -> int:
	var n := 0
	for pl in sim.s["ports"][pid]["plots"]:
		if pl != null and pl["owner"] == hid:
			n += 1
	return n


## How many buildings `hid` may own in this city: 1 + friendliness level (rivals: 3).
static func build_limit(sim: Sim, pid: String, hid: String) -> int:
	if hid != sim.pid():
		return 2
	return 1 + sim.friend_level(pid, hid)


static func all_buildings(sim: Sim, hid: String) -> Array:
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


## Profit per day if the workshop buys inputs and sells output at this port's market right now.
static func est_daily(sim: Sim, pid: String, g: String, hid: String, lvl: int = 1) -> float:
	var v := float(sim.sell_price(pid, g, hid))
	for k in GameData.GOODS[g].get("recipe", {}):
		v -= float(sim.buy_price(pid, k, hid)) * float(GameData.GOODS[g]["recipe"][k])
	var n: int = GameData.TIER_OUTPUT[GameData.tier(g)] + lvl - 1
	if g in GameData.PORTS[pid]["make"]:
		n += GameData.SIGNATURE_BONUS
	return v * float(n) - float(GameData.upkeep_of(g)) / 30.0


## Value of one unit at base prices minus its inputs at base prices.
static func margin_hint(g: String) -> int:
	var v: int = GameData.GOODS[g]["base"]
	for k in GameData.GOODS[g].get("recipe", {}):
		v -= int(GameData.GOODS[k]["base"]) * int(GameData.GOODS[g]["recipe"][k])
	return v


# ------------------------------------------------------------------ actions

static func open_wh(sim: Sim, pid: String, hid: String = "", free: bool = false) -> Dictionary:
	if hid == "":
		hid = sim.pid()
	if has_wh(sim, pid, hid):
		return sim._fail("这里已经有你的商馆。")
	var h := sim.house(hid)
	if not free:
		if hid == sim.pid() and sim.rep_level(hid) < 2:
			return sim._fail("名声达到「船东」（2 级）才能开设商馆。")
		if h["gold"] < GameData.WH_OPEN:
			return sim._fail("需要 %d 金。" % GameData.WH_OPEN)
		h["gold"] -= GameData.WH_OPEN
		h["month_out"] += GameData.WH_OPEN
	sim.s["ports"][pid]["whcap"][hid] = GameData.WH_START
	wh(sim, pid, hid)
	if not free and hid == sim.pid():
		sim.add_rep(hid, 15)
	return {"ok": true, "msg": "在 %s 开设了商馆（仓库容量 %d）。" % [GameData.port_name(pid), GameData.WH_START]}


static func upgrade_wh(sim: Sim, pid: String, hid: String = "") -> Dictionary:
	if hid == "":
		hid = sim.pid()
	var cap := wh_cap(sim, pid, hid)
	if cap <= 0:
		return sim._fail("先开设商馆。")
	if cap >= GameData.WH_MAX:
		return sim._fail("仓库已是最大。")
	var h := sim.house(hid)
	if h["gold"] < GameData.WH_UPGRADE:
		return sim._fail("需要 %d 金。" % GameData.WH_UPGRADE)
	h["gold"] -= GameData.WH_UPGRADE
	h["month_out"] += GameData.WH_UPGRADE
	sim.s["ports"][pid]["whcap"][hid] = cap + GameData.WH_STEP
	return {"ok": true, "msg": "仓库扩建到 %d。" % (cap + GameData.WH_STEP)}


static func can_build(sim: Sim, pid: String, i: int, g: String, hid: String) -> Dictionary:
	var plots: Array = sim.s["ports"][pid]["plots"]
	if not GameData.GOODS.has(g):
		return sim._fail("没有这种货物。")
	if plots[i] != null:
		return sim._fail("这块地已经有建筑了。")
	if not GameData.plot_fits(pid, i, g):
		return sim._fail("%s上不能建%s工坊。" % [terrain_name(pid, i), GameData.good_name(g)])
	if not sim.has_bp(g, hid):
		var t := GameData.tier(g)
		return sim._fail(["", "需要这座城的%s地契（城主府）。", "需要%s的工艺图纸（工匠行会）。", "需要%s的秘传图纸。"][t] % GameData.good_name(g))
	if hid == sim.pid() and sim.rep_level(hid) < 2:
		return sim._fail("名声达到「船东」（2 级）才能建工坊。")
	if count_buildings(sim, pid, hid) >= build_limit(sim, pid, hid):
		return sim._fail("你在这座城最多建 %d 座（提升友好度可以增加）。" % build_limit(sim, pid, hid))
	var cost := build_cost(sim, g, hid)
	if sim.house(hid)["gold"] < cost:
		return sim._fail("需要 %d 金。" % cost)
	return {"ok": true}


static func build(sim: Sim, pid: String, i: int, g: String, hid: String = "") -> Dictionary:
	if hid == "":
		hid = sim.pid()
	var r := can_build(sim, pid, i, g, hid)
	if not r["ok"]:
		return r
	var h := sim.house(hid)
	var cost := build_cost(sim, g, hid)
	h["gold"] -= cost
	h["month_out"] += cost
	if not has_wh(sim, pid, hid):
		open_wh(sim, pid, hid, true)
	var mine := hid == sim.pid()
	sim.s["ports"][pid]["plots"][i] = {"b": g, "lvl": 1, "owner": hid, "in_mode": "wh" if mine else "buy", "out_mode": "wh" if mine else "sell", "status": "ok"}
	sim.add_rep(hid, 20)
	if hid == sim.pid():
		sim.add_exp(50)
	var msg := "%s 在 %s 建起了%s工坊。" % [GameData.HOUSES[hid]["name"], GameData.port_name(pid), GameData.good_name(g)]
	if not mine:
		sim._say(msg, "rival")
	else:
		sim.add_friend(pid, hid, 30)
	return {"ok": true, "msg": msg}


static func upgrade(sim: Sim, pid: String, i: int) -> Dictionary:
	var pl = sim.s["ports"][pid]["plots"][i]
	if pl == null or pl["owner"] != sim.pid():
		return sim._fail("不是你的建筑。")
	if int(pl["lvl"]) >= GameData.MAX_BUILD_LEVEL:
		return sim._fail("工坊已是最高级。")
	var cost := upgrade_cost(sim, pl["b"], sim.pid())
	var h := sim.house()
	if h["gold"] < cost:
		return sim._fail("需要 %d 金。" % cost)
	h["gold"] -= cost
	h["month_out"] += cost
	pl["lvl"] = int(pl["lvl"]) + 1
	return {"ok": true, "msg": "%s工坊升到 %d 级，每天产 %d 件。" % [GameData.good_name(pl["b"]), int(pl["lvl"]), output(sim, pid, pl)]}


static func set_mode(sim: Sim, pid: String, i: int, key: String, value: String) -> Dictionary:
	var pl = sim.s["ports"][pid]["plots"][i]
	if pl == null or pl["owner"] != sim.pid():
		return sim._fail("不是你的建筑。")
	if key == "out_mode" and value == "lh" and pid != GameData.HOUSES[sim.pid()]["home"]:
		return sim._fail("只有母港的工坊能直送灯塔工地。")
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
	return {"ok": true, "msg": "拆除%s工坊，回收 %d 金。" % [GameData.good_name(pl["b"]), refund]}


static func buyout_cost(sim: Sim, pid: String, i: int) -> int:
	var pl = sim.s["ports"][pid]["plots"][i]
	if pl == null:
		return 0
	return int(float(GameData.build_cost(pl["b"])) * float(pl["lvl"]) * GameData.BUYOUT_MULT)


static func buyout(sim: Sim, pid: String, i: int, hid: String = "") -> Dictionary:
	if hid == "":
		hid = sim.pid()
	var pl = sim.s["ports"][pid]["plots"][i]
	if pl == null or pl["owner"] == hid:
		return sim._fail("没有可收购的建筑。")
	if not sim.has_bp(pl["b"], hid):
		return sim._fail("没有%s的图纸，接手了也开不了工。" % GameData.good_name(pl["b"]))
	if count_buildings(sim, pid, hid) >= build_limit(sim, pid, hid):
		return sim._fail("你在这座城最多建 %d 座。" % build_limit(sim, pid, hid))
	var cost := buyout_cost(sim, pid, i)
	var h := sim.house(hid)
	if h["gold"] < cost:
		return sim._fail("需要 %d 金。" % cost)
	var target: String = pl["owner"]
	var before := sim.patron(pid)
	h["gold"] -= cost
	h["month_out"] += cost
	var comp := float(GameData.build_cost(pl["b"])) * float(pl["lvl"])
	sim.house(target)["gold"] += comp
	sim.house(target)["month_in"] += comp
	pl["owner"] = hid
	pl["status"] = "ok"
	var mine := hid == sim.pid()
	pl["in_mode"] = "wh" if mine else "buy"
	pl["out_mode"] = "wh" if mine else "sell"
	if not has_wh(sim, pid, hid):
		open_wh(sim, pid, hid, true)
	var who: String = GameData.HOUSES[hid]["name"]
	var msg := "%s 收购了 %s 在 %s 的%s工坊。" % [who, GameData.HOUSES[target]["name"], GameData.port_name(pid), GameData.good_name(pl["b"])]
	if sim.patron(pid) != before and sim.patron(pid) == hid:
		msg += " %s 成为 %s 港主。" % [who, GameData.port_name(pid)]
	sim._say(msg, "good" if mine else ("bad" if target == sim.pid() else "major"))
	return {"ok": true, "msg": msg}


# ------------------------------------------------------------------ simulation

static func tick(sim: Sim) -> void:
	for pid in GameData.PORT_IDS:
		for pl in sim.s["ports"][pid]["plots"]:
			if pl == null or sim.house(pl["owner"])["bankrupt"]:
				continue
			var n := output(sim, pid, pl)
			var made := 0
			for k in n:
				if not _cycle(sim, pid, pl):
					break
				made += 1
			if made > 0:
				pl["status"] = "ok"


## One unit of output. Returns false (and sets status) when it cannot run.
static func _cycle(sim: Sim, pid: String, pl: Dictionary) -> bool:
	var g: String = pl["b"]
	var recipe: Dictionary = GameData.GOODS[g].get("recipe", {})
	var hid: String = pl["owner"]
	var h := sim.house(hid)
	var from_wh := {}
	var to_buy := {}
	for k in recipe:
		var need: int = recipe[k]
		var have := mini(need, int(wh(sim, pid, hid).get(k, 0)))
		from_wh[k] = have
		if have < need:
			if pl["in_mode"] == "buy":
				to_buy[k] = need - have
			else:
				pl["status"] = "缺" + GameData.good_name(k)
				return false
	var buy_cost := 0.0
	for k in to_buy:
		var q := sim.quote_buy(pid, k, to_buy[k], hid)
		if q["qty"] < to_buy[k]:
			pl["status"] = "本港%s断货" % GameData.good_name(k)
			return false
		buy_cost += q["cost"]
	if buy_cost > 0.0 and h["gold"] - buy_cost < 0.0:
		pl["status"] = "金币不足，买不起原料"
		return false
	var out_mode: String = pl["out_mode"]
	if out_mode == "lh" and not _lh_needs(sim, hid, g):
		out_mode = "wh" if hid == sim.pid() else "sell"
	if out_mode == "wh" and wh_cap(sim, pid, hid) - wh_used(sim, pid, hid) < 1:
		if hid != sim.pid():
			out_mode = "sell"
		else:
			pl["status"] = "仓库已满"
			return false
	for k in from_wh:
		wh_take(sim, pid, hid, k, from_wh[k])
	for k in to_buy:
		var q2 := sim.quote_buy(pid, k, to_buy[k], hid)
		h["gold"] -= q2["cost"]
		h["month_out"] += q2["cost"]
		sim.s["ports"][pid]["market"][k]["stock"] -= q2["qty"]
	match out_mode:
		"sell":
			var r := sim.quote_sell(pid, g, 1, hid)
			h["gold"] += r["revenue"]
			h["month_in"] += r["revenue"]
			sim.s["ports"][pid]["market"][g]["stock"] += 1
		"lh":
			var lh: Dictionary = h["lh"]
			lh["mats"][g] = int(lh["mats"].get(g, 0)) + 1
		_:
			wh_add(sim, pid, hid, g, 1)
	return true


static func _lh_needs(sim: Sim, hid: String, g: String) -> bool:
	var lh: Dictionary = sim.house(hid)["lh"]
	if lh["building"] or lh["stage"] >= GameData.LIGHTHOUSE.size():
		return false
	var need: Dictionary = GameData.LIGHTHOUSE[lh["stage"]]["mats"]
	return need.has(g) and int(lh["mats"].get(g, 0)) < int(need[g])


## Monthly upkeep: workshops plus warehouse rent.
static func upkeep(sim: Sim, hid: String) -> float:
	var c := 0.0
	for b in all_buildings(sim, hid):
		c += float(GameData.upkeep_of(b["plot"]["b"]))
	for pid in GameData.PORT_IDS:
		var cap := wh_cap(sim, pid, hid)
		if cap > 0:
			c += float(cap) / 100.0 * float(GameData.WH_RENT_PER_100)
	return c


# ------------------------------------------------------------------ rivals

## Rivals pick up blueprints as their reputation grows, then build what pays best.
static func ai_blueprints(sim: Sim, hid: String) -> void:
	var h := sim.house(hid)
	var lvl := sim.rep_level(hid)
	var home: String = GameData.HOUSES[hid]["home"]
	# the bot player has to buy its home deeds like anyone else
	if hid == sim.pid():
		for g in GameData.PORTS[home]["make"]:
			if GameData.tier(g) == 1 and not sim.has_bp(g, hid) and h["gold"] > GameData.DEED_COST * 4 and sim.deed_ok(home, g)["ok"]:
				sim.buy_deed(home, g)
				return
	# lighthouse materials nobody sells: learn to make them
	var lh: Dictionary = h["lh"]
	for st in range(int(lh["stage"]), GameData.LIGHTHOUSE.size()):
		for g in GameData.LIGHTHOUSE[st]["mats"]:
			if sim.has_bp(g, hid) or GameData.GOODS[g].get("home", "") != "":
				continue
			var t := GameData.tier(g)
			if t == 2 and lvl >= 3 and h["gold"] > GameData.CRAFT_BP_COST * 3:
				h["gold"] -= GameData.CRAFT_BP_COST
				h["bp"][g] = true
				sim._say("%s 买下了%s的工艺图纸。" % [GameData.HOUSES[hid]["name"], GameData.good_name(g)], "rival")
				return
			if t == 3 and lvl >= 4 and h["gold"] > GameData.SECRET_BP_COST * 2:
				h["gold"] -= GameData.SECRET_BP_COST
				h["bp"][g] = true
				sim._say("%s 取得了%s的秘传图纸。" % [GameData.HOUSES[hid]["name"], GameData.good_name(g)], "rival")
				return
	if lvl >= 3:
		# craft blueprints for goods whose main input they already make
		for g in GameData.GOOD_IDS:
			if GameData.tier(g) == 2 and not sim.has_bp(g, hid) and GameData.main_input(g) in GameData.PORTS[home]["make"] and h["gold"] > GameData.CRAFT_BP_COST * 3:
				h["gold"] -= GameData.CRAFT_BP_COST
				h["bp"][g] = true
				sim._say("%s 买下了%s的工艺图纸。" % [GameData.HOUSES[hid]["name"], GameData.good_name(g)], "rival")
				return
	if lvl >= 4 and h["gold"] > GameData.SECRET_BP_COST * 2:
		for g in GameData.SECRET_BP_CITY:
			if sim.has_bp(g, hid):
				continue
			# a secret they can actually feed: at least one input they already produce
			var feed := false
			for k in GameData.GOODS[g]["recipe"]:
				if sim.has_bp(k, hid):
					feed = true
			if feed:
				h["gold"] -= GameData.SECRET_BP_COST
				h["bp"][g] = true
				sim._say("%s 取得了%s的秘传图纸。" % [GameData.HOUSES[hid]["name"], GameData.good_name(g)], "rival")
				return


## Rich houses raise their workshops a level at a time (a money sink that keeps them competitive).
static func ai_upgrade(sim: Sim, hid: String, budget: float) -> void:
	var best := {}
	var best_lvl := GameData.MAX_BUILD_LEVEL
	for b in all_buildings(sim, hid):
		var pl: Dictionary = b["plot"]
		if int(pl["lvl"]) < best_lvl and upgrade_cost(sim, pl["b"], hid) <= budget:
			best_lvl = int(pl["lvl"])
			best = pl
	if best.is_empty():
		return
	var h := sim.house(hid)
	var cost := upgrade_cost(sim, best["b"], hid)
	h["gold"] -= cost
	h["month_out"] += cost
	best["lvl"] = int(best["lvl"]) + 1


static func ai_build(sim: Sim, hid: String, budget: float) -> void:
	if all_buildings(sim, hid).size() >= 8:
		return
	var best := {}
	var best_score := 0.0
	var home: String = GameData.HOUSES[hid]["home"]
	for pid in sim.open_ports():
		if count_buildings(sim, pid, hid) >= build_limit(sim, pid, hid):
			continue
		var plots: Array = sim.s["ports"][pid]["plots"]
		for i in plots.size():
			if plots[i] != null:
				continue
			for g in goods_for(pid, i):
				if not sim.has_bp(g, hid):
					continue
				var cost := build_cost(sim, g, hid)
				if cost > budget:
					continue
				var daily := est_daily(sim, pid, g, hid)
				var lh_bonus := 0.0
				if pid == home and _lh_needs(sim, hid, g):
					lh_bonus = float(GameData.GOODS[g]["base"]) * float(GameData.TIER_OUTPUT[GameData.tier(g)]) * 0.8
				var score := (daily + lh_bonus) * 30.0 / float(cost) * (1.3 if pid == home else 1.0)
				if score > best_score and score > 0.1:
					best_score = score
					best = {"port": pid, "idx": i, "g": g}
	if best.is_empty():
		return
	var r := build(sim, best["port"], best["idx"], best["g"], hid)
	if r["ok"]:
		var pl: Dictionary = sim.s["ports"][best["port"]]["plots"][best["idx"]]
		# the bot has no hands to empty its warehouse: sell at the gate like a rival does
		pl["in_mode"] = "buy"
		pl["out_mode"] = "lh" if best["port"] == home else "sell"
