function onInit()
	Debug.chat("what.")
	Debug.chat(self)
end

function update()
	Debug.chat("participation_result_box.lua update")
	local node = getDatabaseNode()
	bSuccess = node.getChild("success") and node.getChild("success").getValue()==1
	bFail = node.getChild("fail") and node.getChild("fail").getValue()==1
	bCritFail = node.getChild("critfail") and node.getChild("critfail").getValue()==1
	bRaise = node.getChild("raise") and node.getChild("raise").getValue()==1

	critfail_indicator.setVisible(false)
	success_indicator.setVisible(false)
	raise_indicator.setVisible(false)
	fail_indicator.setVisible(false)

    if (bRaise and not node.getChild("raise_choice_battleeffect")) then
        makeBattleTableRoll("raise")
    end
    if (bCritFail and not node.getChild("crit_fail_battleeffect")) then
        makeBattleTableRoll("critfail")
    end
	if bCritFail then
		critfail_indicator.setVisible(true)
		
	elseif bFail then
		fail_indicator.setVisible(true)
        MassBattles.deleteBEChildNodes(node);
	elseif bRaise then
		raise_indicator.setVisible(true)
		node.createChild("bonus","number",1)
        raise_choice_battleeffect_button.setText(node.getChild("raise_choice_battleeffect") and node.getChild("raise_choice_battleeffect").getValue() or "")
		showRaiseChoice()
	elseif bSuccess then
		success_indicator.setVisible(true)
        MassBattle.deleteBEChildNodes(node);
		node.createChild("bonus","number",1)
	end
end

function makeBattleTableRoll(cause)
	sActorClass, sLink = parentcontrol.window.link.getValue()
	rActor = ActorManager.getActor("pc", sLink)
	nodeTable = TableManager.findTable("Battle Effects")
	rRoll = {};
	rRoll.sType = "table";
	--rRoll.sType = MassBattles.sBattleEffectTableRoll
	rRoll.sDesc = "[" .. Interface.getString("table_tag") .. "] " .. DB.getValue(nodeTable, "name", "");
	rRoll.aDice = DB.getValue(nodeTable,"dice", {})
	rRoll.nMod = 0
	rRoll.bApplyModifiersStack = false
	rRoll.sNodeTable = nodeTable.getNodeName()
	rRoll.mb_entry = parentcontrol.window.getDatabaseNode().getPath()
    rRoll.cause = cause
	TableManager.prepareTableDice(rRoll)
	--bHost = User.isHost() or User.isLocal()
	--if bHost then
		--rRoll.sOutput = DB.getValue(nodeTable, "output", "");
	--end
	ActionsManager.performAction(nil, rActor, rRoll)

end

function showRaiseChoice()
	parentcontrol.window.participation_result_box.subwindow.raise_choice_1.setVisible(true)
	parentcontrol.window.participation_result_box.subwindow.raise_choice_or.setVisible(true)
	parentcontrol.window.participation_result_box.subwindow.raise_choice_battleeffect_button.setVisible(true)
	-- reference.tables.battleeffects@SWADE Player Guide
end
