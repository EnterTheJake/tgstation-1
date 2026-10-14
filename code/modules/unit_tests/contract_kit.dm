/// Buying the contract kit shuts down the buyer's normal uplink, but not the item it was hidden in or the contractor's own uplink
/datum/unit_test/contract_kit_bricks_uplink

/datum/unit_test/contract_kit_bricks_uplink/Run()
	var/mob/living/carbon/human/buyer = allocate(/mob/living/carbon/human/consistent)
	var/obj/item/modular_computer/pda/pda = allocate(/obj/item/modular_computer/pda)
	var/datum/component/uplink/uplink = pda.AddComponent(/datum/component/uplink, lockable = FALSE, enabled = TRUE, uplink_flag = UPLINK_TRAITORS, starting_tc = 25)
	uplink.uplink_handler.debug_mode = TRUE

	var/datum/uplink_item/contract_kit = SStraitor.uplink_items_by_type[/datum/uplink_item/bundles_tc/contract_kit]
	TEST_ASSERT(uplink.uplink_handler.purchase_item(buyer, contract_kit, pda), "Could not buy the contract kit")

	TEST_ASSERT_NULL(pda.GetComponent(/datum/component/uplink), "The PDA still has its uplink after buying the contract kit")
	TEST_ASSERT(!QDELETED(pda), "Buying the contract kit deleted the PDA the uplink was hidden in")

	var/obj/item/stack/telecrystal/refund = locate() in buyer.held_items
	TEST_ASSERT_NOTNULL(refund, "Leftover telecrystals were not handed back")
	TEST_ASSERT_EQUAL(refund.amount, 5, "Wrong amount of telecrystals handed back")

	var/obj/item/storage/box/syndicate/contract_kit/kit = locate() in buyer.held_items
	TEST_ASSERT_NOTNULL(kit, "The contract kit did not end up in the buyer's hands")
	var/obj/item/mod/module/contractor_uplink/contractor_module = locate() in kit.get_all_contents()
	TEST_ASSERT_NOTNULL(contractor_module, "The contract kit has no contractor uplink module")
	TEST_ASSERT_NOTNULL(contractor_module.GetComponent(/datum/component/uplink/contractor), "Buying the contract kit shut down the contractor uplink too")
