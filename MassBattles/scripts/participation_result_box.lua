local bSuccess, bFail, bCritFail, bRaise;
function onInit()
	DB.addHandler(getDatabaseNode().getPath(),"onUpdate",update)
	DB.addHandler(getDatabaseNode().getPath(),"onChildUpdate",update)
	update()
end

function update()

	local node = getDatabaseNode()
	bSuccess = node.getChild("success") and node.getChild("success").getValue()==1
	bFail = node.getChild("fail") and node.getChild("fail").getValue()==1
	bCritFail = node.getChild("critfail") and node.getChild("critfail").getValue()==1
	bRaise = node.getChild("raise") and node.getChild("raise").getValue()==1

	critfail_indicator.setVisible(false)
	success_indicator.setVisible(false)
	raise_indicator.setVisible(false)
	fail_indicator.setVisible(false)
	apply_result_button.setVisible(true)

	if bCritFail then
		critfail_indicator.setVisible(true)
		hideRaiseChoice()
	elseif bFail then
		fail_indicator.setVisible(true)
		hideRaiseChoice()
	elseif bRaise then
		apply_result_button.setVisible(false)
		raise_indicator.setVisible(true)
        raise_choice_battleeffect_button.setText(node.getChild("raise_choice_battleeffect") and node.getChild("raise_choice_battleeffect").getValue() or "")
		showRaiseChoice()
	elseif bSuccess then
		success_indicator.setVisible(true)
		hideRaiseChoice()
	end
	local alreadyApplied = node.getParent().getChild("pendingResultsActivated") and node.getParent().getChild("pendingResultsActivated").getValue()==1 or false
	if alreadyApplied or bRaise then
		apply_result_button.setEnabled(false)
		apply_result_button.setVisible(false)
	else
		apply_result_button.setEnabled(true)
		apply_result_button.setVisible(true)
	end

	if alreadyApplied then
		hideRaiseChoice()
	end

	nPendingWounds = DB.getValue(getDatabaseNode(), "pending_wounds",0)
	nPendingFatigues = DB.getValue(getDatabaseNode(), "pending_fatigues",0)
	if nPendingWounds > 0 and not alreadyApplied then
		part_wounds.setVisible(true)
		pending_wounds.setVisible(true)
	else
		part_wounds.setVisible(false)
		pending_wounds.setVisible(false)
	end
	if nPendingFatigues > 0  and not alreadyApplied then
		part_fatigues.setVisible(true)
		pending_fatigues.setVisible(true)
	else
		part_fatigues.setVisible(false)
		pending_fatigues.setVisible(false)
	end
end

function showRaiseChoice()
	raise_choice_1.setVisible(true)
	raise_choice_or.setVisible(true)
	raise_choice_battleeffect_button.setVisible(true)
	-- reference.tables.battleeffects@SWADE Player Guide
end

function hideRaiseChoice()
	raise_choice_1.setVisible(false)
	raise_choice_or.setVisible(false)
	raise_choice_battleeffect_button.setVisible(false)
	-- reference.tables.battleeffects@SWADE Player Guide
end

function activateRaiseChoicep1()
	MassBattles.setPendingBonus(getDatabaseNode(),2)
	hideRaiseChoice()
	applyParticipationResult()
end

function activateRaiseChoiceBE()
	MassBattles.setPendingBonus(getDatabaseNode(),1)
	hideRaiseChoice()
	getDatabaseNode().createChild("battle_impact_effect","string").setValue(getDatabaseNode().getChild("raise_choice_battleeffect").getValue())
	applyParticipationResult()
end

function removeBattleImpactEffect()
	getDatabaseNode().createChild("battle_impact_effect","string").setValue("")
	MassBattles.updateClientsMassBattleWindows()
end

function applyParticipationResult()
	MassBattles.applyParticipationResult(getDatabaseNode())
end

function deleteParticipationResult()
	getDatabaseNode().delete()
end
