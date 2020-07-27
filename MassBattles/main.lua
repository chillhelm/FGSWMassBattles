
aMassBattleShortcutHost = {
    icon="button_ct",
    icon_down="button_ct_down",
    tooltipres="sidebar_tooltip_mb",
    class="massbattle_host",
    path="massbattle",
}

aMassBattleShortcutClient = {
    icon="button_ct",
    icon_down="button_ct_down",
    tooltipres="sidebar_tooltip_mb",
    class="massbattle_client",
    path="massbattle",
}
sBattleEffectTableRoll = "battleeffecttableroll"

function onInit()
    --ActionsManager.registerResultHandler("table", MassBattles.onBattleEffectTableRolled)
    --GameSystem.actions[sBattleEffectTableRoll] = { bUseModStack = "false" };
    --RollsManager.registerResolutionHandler(sBattleEffectTableRoll, MassBattles.onBattleEffectTableRolled)
    RollsManager.registerResolutionHandler("table", MassBattles.onTableRolled)
    Debug.chat("registered result handlers")
    if User.isHost() or User.isLocal() then
        Debug.console("User is host or local")
		local mbNode = DB.createNode("massbattle")
        mbNode.setPublic(true);
        armyaNode = mbNode.createChild("ArmyA")
        armyaNode.setPublic(true)
        armyaNode.createChild("champions")
        mbNode.createChild("ArmyB").setPublic(true);
        armybNode = mbNode.createChild("ArmyB")
        armybNode.setPublic(true)
        armybNode.createChild("champions")
        mbNode.createChild("CommanderA").setPublic(true)
        mbNode.createChild("CommanderB").setPublic(true)
        mbNode.createChild("ForceTokensA","number").setPublic(true)
        mbNode.createChild("ForceTokensB","number").setPublic(true)

        DesktopManager.registerStackShortcuts({aMassBattleShortcutHost})
    elseif User.isClient() then
        Debug.console("User is client")
        DesktopManager.registerStackShortcuts({aMassBattleShortcutClient})
    end
    RollsManager.registerTraitResolutionSubHandler("battleparticipation", resolveBattleParticipationRoll)
	
end

function resolveBattleParticipationRoll(rRoll, rRollResult, rSource, vTargets, rContext)
    local participant = DB.findNode(extractMBEntryFromUserdata(rRoll.rCustom.userdata))
    applyParticipationResult(participant, rRollResult.nTotalScore, rRollResult.bCriticalFailure)
end

function extractMBEntryFromUserdata(sUserdata)
    local mb_entry_start, mb_entry_end = sUserdata:find("mb_entry")
    local path_start = mb_entry_end+2
    local path_end,_ = sUserdata:find(",",path_start)
    if(path_end) then
		path_end = path_end-1
		return string.sub(sUserdata,path_start,path_end)
	else
        return string.sub(sUserdata,path_start)
	end
end

function applyParticipationResult(participant, total_score, bCriticalFailure)
    Debug.chat(participant, "achieved")
    bRaise=false
    bSuccess=false
    bFail=False
    bCritFail=bCriticalFailure
    if total_score>=4 then
        bSuccess = true and not bCritFail
		if(total_score>=8) then
			bRaise = true and not bCritFail
		end 
    end
    bFail = bCriticalFailure or total_score<4
    local participation_result_node = participant.createChild("participation_result")
    participation_result_node.createChild("total","number").setValue(total_score)
	participation_result_node.createChild("success","number").setValue(bSuccess and 1 or 0)
	participation_result_node.createChild("raise","number").setValue(bRaise and 1 or 0)
	participation_result_node.createChild("fail","number").setValue(bFail and 1 or 0)
	participation_result_node.createChild("critfail","number").setValue(bCritFail and 1 or 0)
    participant.createChild("participated","number").setValue(1)
    if(bRaise and bSuccess) then
        Debug.chat("a success with a raise!")
    elseif (bSuccess) then
        Debug.chat("a success")
    elseif bFail then
        Debug.chat("nothing")
    end
    if bCriticalFailure then
        Debug.chat("Actually worse than nothing")
	end
    local active_massbattle = getMassbattleFromParticipant(participant)
    local massbattle_window = nil
    if User.isHost() or User.isLocal() then
		massbattle_window = Interface.findWindow("massbattle_host", active_massbattle)
	else
		massbattle_window = Interface.findWindow("massbattle_client", active_massbattle)
	end
    if(massbattle_window)then
        massbattle_window.update()
    end
end

function getMassbattleFromParticipant(participant)
    if(participant) then
        return participant.getParent().getParent().getParent()
    end
    return nil
 end

 function onTableRolled(rRoll, rSource, rTargets)
    if(rSource and rRoll.mb_entry) then
        onBattleEffectTableRolled(rRoll, rSource, rTargets)
    end
 end

 function onBattleEffectTableRolled(rRoll, rSource, rTargets)
    local rRollResult = RollsManager.buildRollResult(rRoll)
    local mb_entry = DB.findNode(rRoll.mb_entry)
    local nodeTable = DB.findNode(rRoll.sNodeTable)
    local table_result = TableManager.getResults(nodeTable, rRollResult.nTotalScore)
    local result_keyword = string.sub(table_result[1].sText, 0, table_result[1].sText:find(":")-1)
    local part_result = mb_entry.getChild("participation_result")
    part_result.createChild("battleeffect","string").setValue(result_keyword)

    --get participation result window
 end

