/**
 * # Techweb Node
 *
 * A datum representing a researchable node in the techweb.
 *
 * Techweb nodes are GLOBAL, there should only be one instance of them in the game. Persistant
 * changes should never be made to them in-game. USE SSRESEARCH PROCS TO OBTAIN REFERENCES.
 * DO NOT REFERENCE OUTSIDE OF SSRESEARCH OR YOU WILL FUCK UP GC.
 */
/datum/techweb_node
	/// Internal ID of the node
	var/id
	/// The name of the node as it is shown on UIs
	var/display_name = "Errored Node"
	/// A description of the node to show on UIs
	var/description = "Why are you seeing this?"
	/// Whether it starts off hidden
	var/hidden = FALSE
	/// If the tech can be randomly generated by the BEPIS as a reward. MEant to be fully given in tech disks, not researched
	var/experimental = FALSE
	/// Whether it's available without any research
	var/starting_node = FALSE
	var/list/prereq_ids = list()
	var/list/design_ids = list()
	/// CALCULATED FROM OTHER NODE'S PREREQUISITIES. Associated list id = TRUE
	var/list/unlock_ids = list()
	/// Associative list, path = list(point type = point_value)
	var/list/boost_item_paths = list()
	/// Boosting this will autounlock this node
	var/autounlock_by_boost = TRUE
	/// The points cost to research the node, type = amount
	var/list/research_costs = list()
	/// The category of the node
	var/category = "Misc"
	/// The list of experiments required to research the node
	var/list/required_experiments = list()
	/// If completed, these experiments give a specific point amount discount to the node.area
	var/list/discount_experiments = list()
	/// Departament channels, segregate nodes to their respective department channels
	var/list/channel_tag


/datum/techweb_node/error_node
	id = "ERROR"
	display_name = "ERROR"
	description = "This usually means something in the database has corrupted. If it doesn't go away automatically, inform Central Command for their techs to fix it ASAP(tm)"

/datum/techweb_node/proc/Initialize()
	//Make lists associative for lookup
	for(var/id in prereq_ids)
		prereq_ids[id] = TRUE
	for(var/id in design_ids)
		design_ids[id] = TRUE
	for(var/id in unlock_ids)
		unlock_ids[id] = TRUE

/datum/techweb_node/Destroy()
	SSresearch.techweb_nodes -= id
	return ..()

/datum/techweb_node/serialize_list(list/options)
	. = list()
	VARSET_TO_LIST(., id)
	VARSET_TO_LIST(., display_name)
	VARSET_TO_LIST(., hidden)
	VARSET_TO_LIST(., starting_node)
	VARSET_TO_LIST(., assoc_list_strip_value(prereq_ids))
	VARSET_TO_LIST(., assoc_list_strip_value(design_ids))
	VARSET_TO_LIST(., assoc_list_strip_value(unlock_ids))
	VARSET_TO_LIST(., boost_item_paths)
	VARSET_TO_LIST(., autounlock_by_boost)
	VARSET_TO_LIST(., research_costs)
	VARSET_TO_LIST(., category)
	VARSET_TO_LIST(., required_experiments)

/datum/techweb_node/deserialize_list(list/input, list/options)
	if(!input["id"])
		return
	VARSET_FROM_LIST(input, id)
	VARSET_FROM_LIST(input, display_name)
	VARSET_FROM_LIST(input, hidden)
	VARSET_FROM_LIST(input, starting_node)
	VARSET_FROM_LIST(input, prereq_ids)
	VARSET_FROM_LIST(input, design_ids)
	VARSET_FROM_LIST(input, unlock_ids)
	VARSET_FROM_LIST(input, boost_item_paths)
	VARSET_FROM_LIST(input, autounlock_by_boost)
	VARSET_FROM_LIST(input, research_costs)
	VARSET_FROM_LIST(input, category)
	VARSET_FROM_LIST(input, required_experiments)
	Initialize()
	return src

/datum/techweb_node/proc/on_design_deletion(datum/design/D)
	prune_design_id(D.id)

/datum/techweb_node/proc/on_node_deletion(datum/techweb_node/TN)
	prune_node_id(TN.id)

/datum/techweb_node/proc/prune_design_id(design_id)
	design_ids -= design_id

/datum/techweb_node/proc/prune_node_id(node_id)
	prereq_ids -= node_id
	unlock_ids -= node_id

/datum/techweb_node/proc/get_price(datum/techweb/host)
	if(host)
		var/list/actual_costs = research_costs
		if(host.boosted_nodes[id])
			var/list/boostlist = host.boosted_nodes[id]
			for(var/booster in boostlist)
				if(actual_costs[booster])
					actual_costs[booster] -= boostlist[booster]
		for(var/cost_type in actual_costs)
			for(var/experiment_type in discount_experiments)
				if(host.completed_experiments[experiment_type]) //do we have this discount_experiment unlocked?
					actual_costs[cost_type] -= discount_experiments[experiment_type]
		return actual_costs
	else
		return research_costs

/datum/techweb_node/proc/price_display(datum/techweb/TN)
	return techweb_point_display_generic(get_price(TN))

/datum/techweb_node/proc/on_research() //new proc, not currently in file
	return

/datum/techweb_node/proc/announce_node(obj/machinery/computer/rdconsole/console)
	for(var/channel_check in channel_tag)
		console.console_radio.talk_into(console, "[display_name] has been researched!", channel_check)
