
aMassBattleShortcutHost = {
    icon="button_mb",
    icon_down="button_mb_down",
    tooltipres="sidebar_tooltip_mb",
    class="massbattle_host",
    path="massbattle",
}

aMassBattleShortcutClient = {
    icon="button_mb",
    icon_down="button_mb_down",
    tooltipres="sidebar_tooltip_mb",
    class="massbattle_client",
    path="massbattle",
}
sBattleEffectTableRoll = "battleeffecttableroll"

function onInit()
    RollsManager.registerResolutionHandler("table", MassBattles.onTableRolled)
    RollsManager.registerTraitResolutionSubHandler("battleparticipation", resolveBattleParticipationRoll)
    RollsManager.registerTraitResolutionSubHandler("battlecommand", resolveBattleCommandRoll)
    RollsManager.registerTraitResolutionSubHandler("battlemorale", resolveBattleMoraleRoll)
    RollsManager.registerTraitRollModHandler(applyCommandBonus)
    RollsManager.registerTraitRollModHandler(applyMoraleBonus)
    OOBManager.registerOOBMsgHandler("MassBattleWindowUpdate", onOOBMBWUpdate)
    if User.isHost() or User.isLocal() then
		OOBManager.registerOOBMsgHandler("MassBattleApplyCommandResult", onOOBMBApplyCommandResult)
    end
    ChatManager.registerRollHandler("massbattleCritFailInjury", processMassbattleCritFailInjury)
    if User.isHost() or User.isLocal() then
		local mbNode = DB.createNode("massbattle")
        mbNode.setPublic(true);
        armyaNode = mbNode.createChild("ArmyA")
        armyaNode.setPublic(true)
        armyaNode.createChild("champions")
        mbNode.createChild("ArmyB").setPublic(true);
        armybNode = mbNode.createChild("ArmyB")
        armybNode.setPublic(true)
        armybNode.createChild("champions")
        mbNode.createChild("ForceTokensA","number").setPublic(true)
        mbNode.createChild("ForceTokensB","number").setPublic(true)

        DesktopManager.registerStackShortcuts({aMassBattleShortcutHost})
    else
        DesktopManager.registerStackShortcuts({aMassBattleShortcutClient})
    end
    if(User.isHost() or User.isLocal()) then
		Module.setModulePermissions("SWADE Player Guide", true, true)
    else
        Module.activate("SWADE Player Guide")
    end
	--Module.activate()
    updateClientsMassBattleWindows()
end

function resolveBattleMoraleRoll(rRoll, rRollResult, rSource, vTargets, rContext)
    local participant = DB.findNode(extractMBEntryFromUserdata(rRoll.rCustom.userdata))
    local armyid = getArmyIDFromCommanderNode(participant)
    nodeMassbattle = DB.findNode("massbattle")
    local armyName = DB.getValue(nodeMassbattle, "Army"..string.upper(armyid).."Name","")
    
    local bCritFail = rRollResult.bCriticalFailure or false
    local bRaise=false
    local bSuccess=false
    local bFail=false
    local total_score = rRollResult.nTotalScore
    if total_score>=4 and not bCritFail then
        bSuccess = true
		if(total_score>=8) then
			bRaise = true
		end 
    end
    bFail = bCritFail or total_score<4

    rMessage = {}
    if bSuccess then
        rMessage.text = string.format(Interface.getString("mb_morale_success"),armyName)
    elseif not bCritFail then
        rMessage.text = string.format(Interface.getString("mb_morale_fail"),armyName)
    else
        rMessage.text = string.format(Interface.getString("mb_morale_critfail"),armyName)
    end
	Comm.deliverChatMessage(rMessage)
    updateClientsMassBattleWindows()
end

function resolveBattleCommandRoll(rRoll, rRollResult, rSource, vTargets, rContext)
    local participant = DB.findNode(extractMBEntryFromUserdata(rRoll.rCustom.userdata))
    local commandResultsNode = DB.createChild(participant,"command_results")
    local commandResultNode = DB.createChild(commandResultsNode)
    DB.setValue(commandResultNode,"total", "number",rRollResult.nTotalScore)
	local windowMassbattle = getMassbattleWindow()
	windowMassbattle.update()
    updateClientsMassBattleWindows()
end

function getArmyIDFromCommanderNode(commander)
    return string.sub(commander.getName(),7,7)
end

function resetParticipationResult(participant)
    local nodeParticipationResult = DB.deleteChildren(participant,"participation_results")
    DB.setValue(nodeParticipationResult,"pending_wounds","number",0)
    DB.setValue(nodeParticipationResult,"pending_fatigues","number",0)
    DB.setValue(nodeParticipationResult,"pending_bouns","number",0)
    
    updateClientsMassBattleWindows()
end

function updateParticipationResultData(participant, total_score, bCritFail)
    local bRaise=false
    local bSuccess=false
    local bFail=false
    if total_score>=4 and not bCritFail then
        bSuccess = true
		if(total_score>=8) then
			bRaise = true
		end 
    end
    bFail = bCriticalFailure or total_score<4
    local participation_results_node = DB.createChild(participant,"participation_results")
    local participation_result_node = DB.createChild(participation_results_node)
    participation_result_node.createChild("total","number").setValue(total_score)
	participation_result_node.createChild("success","number").setValue(bSuccess and 1 or 0)
	participation_result_node.createChild("raise","number").setValue(bRaise and 1 or 0)
	participation_result_node.createChild("fail","number").setValue(bFail and 1 or 0)
	participation_result_node.createChild("critfail","number").setValue(bCritFail and 1 or 0)
    participant.createChild("participated","number").setValue(1)
    if(bRaise and bSuccess) then
        makeBattleTableRoll(participant, participation_result_node, "raise")
        setPendingBonus(participation_result_node, 1)
        setBonus(participant,1)
    elseif (bSuccess) then
        setPendingBonus(participation_result_node, 1)
        setPendingFatigue(participation_result_node, 1)
    elseif bCritFail then
		setPendingBonus(participation_result_node, 0)
		makeCritFailRolls(participant, participation_result_node)
    elseif bFail then
        setPendingWoundsParticipant(participation_result_node,1)
        setPendingBonus(participation_result_node,0)
    end
    local active_massbattle = getMassbattleFromParticipant(participant)
    windowMassbattle = getMassbattleWindow()
    if(windowMassbattle)then
        windowMassbattle.update()
    end
end

function resolveBattleParticipationRoll(rRoll, rRollResult, rSource, vTargets, rContext)
    local participant = DB.findNode(extractMBEntryFromUserdata(rRoll.rCustom.userdata))
    local bCritFail = rRollResult.bCriticalFailure or false
    local total_score = rRollResult.nTotalScore

    updateParticipationResultData(participant, total_score, bCritFail)
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

function applyParticipationResult(participationResultNode)
    activatePendingEffects(participationResultNode)
    local windowMassbattle = getMassbattleWindow()
    if windowMassbattle then
        windowMassbattle.update()
	end
	MassBattles.updateClientsMassBattleWindows()
end

function applyCommandResult(participationResultNode)
    if true then
		Comm.deliverOOBMessage({type="MassBattleApplyCommandResult",node=participationResultNode.getPath()})
    end
    local windowMassbattle = getMassbattleWindow()
    if windowMassbattle then
        windowMassbattle.update()
	end
	MassBattles.updateClientsMassBattleWindows()
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
    local part_result = DB.findNode(rRoll.participationResultNode)
    local cause = rRoll.cause
    if cause == "critfail" then
		part_result.createChild("critfail_battleeffect","string").setValue(result_keyword)
	elseif cause == "raise" then
		part_result.createChild("raise_choice_battleeffect","string").setValue(result_keyword)
    end

    local active_massbattle = getMassbattleFromParticipant(mb_entry)
    local massbattle_window = nil
    if User.isHost() or User.isLocal() then
		massbattle_window = Interface.findWindow("massbattle_host", active_massbattle)
	else
		massbattle_window = Interface.findWindow("massbattle_client", active_massbattle)
	end
    if(massbattle_window)then
        massbattle_window.update()
    end
    --get participation result window
    
    updateClientsMassBattleWindows()
 end

function makeCritFailRolls(participant, participationResultNode)
	makeBattleTableRoll(participant, participationResultNode, "critfail")
    makeCritFailInjuryRoll(participationResultNode)
end

function makeCritFailInjuryRoll(participationResultNode)
	sActorClass, sLink = participationResultNode.getParent().getParent().getChild("link").getValue()
	rActor = ActorManager.getActor(sActorClass, sLink)
	rRoll = {};
	rRoll.sType = "massbattleCritFailInjury";
	rRoll.sDesc = "Critical Fail Injury";
	rRoll.aDice = {"d4"};
	rRoll.nMod = 1
	rRoll.bApplyModifiersStack = false
	rRoll.mb_entry = participationResultNode.getPath()
	ActionsManager.performAction(nil, rActor, rRoll)
end

function fatigueParticipant(participant, nFatigues)
    applyFatigue("mb", participant, nFatigues, false)
end

function setBonus(participant,nValue)
	participant.createChild("battle_impact_bonus","number").setValue(nValue)
end

function woundParticipant(participant, nWounds)
    applyWounds("mb", participant, nWounds)
end

function makeBattleTableRoll(participant, participationResultNode, cause)
	sActorClass, sLink = participant.getChild("link").getValue()
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
	rRoll.mb_entry = participant.getPath()
    rRoll.participationResultNode = participationResultNode.getPath()
    rRoll.cause = cause
	TableManager.prepareTableDice(rRoll)
	--bHost = User.isHost() or User.isLocal()
	--if bHost then
		--rRoll.sOutput = DB.getValue(nodeTable, "output", "");
	--end
	ActionsManager.performAction(nil, rActor, rRoll)

end

 function deleteBEChildNodes(node) 
     if node.getChild("participation_result.raise_choice_battleeffect") then
        node.getChild("participation_result.raise_choice_battleeffect").setValue("")
	end
    if node.getChild("participation_result.critfail_battleeffect") then
		node.getChild("participation_result.critfail_battleeffect").setValue("")
	end
	if node.getChild("participation_result.battle_impact_effect") then
		node.getChild("participation_result.battle_impact_effect").setValue("")
	end

    updateClientsMassBattleWindows()
 end

 
 
function applyWounds(sTargetType, nodeTarget, nWounds)
	if nodeTarget and DB.isOwner(nodeTarget) then
		local rActor = CharacterManager.getActorShortcut(sTargetType, nodeTarget)
		local nCurrentWounds = DB.getValue(nodeTarget, "main.wounds", 0)
		local nNewWound = nCurrentWounds - nWounds
		local nMaxWounds = DamageTypeManager.getDamageThreshold(rActor, "main.wounds") * -1
		local bIncapacitated = nNewWound < nMaxWounds
		if bIncapacitated then
			local rMessage = RollsManager.createResultMessage(sTargetType, nodeTarget, true)
			rMessage.icon = "state_inc"
			if bNonLethal then
				local rEffectActor = ActorManager.getActor(sTargetType, nodeTarget.getNodeName()) ActionEffect.applyEffect(rEffectActor, rEffectActor, ActionEffect.knockedOutEffect()) rMessage.text = Interface.getString("damage_x_knockedout"):format(rMessage.text)
			else
				rMessage.text = Interface.getString("damage_x_incapacitated"):format(rMessage.text)
			end
			Comm.deliverChatMessage(rMessage)
			nNewWound = nMaxWounds
		end
		DB.setValue(nodeTarget, "main.wounds", "number", nNewWound)
		if bIncapacitated then
			DB.setValue(nodeTarget, "inc", "number", 1)
		end
	end
end
function applyFatigue(sTargetType, nodeTarget, nFatigues, bNonLethal)
	if nodeTarget and DB.isOwner(nodeTarget) then
		local rActor = CharacterManager.getActorShortcut(sTargetType, nodeTarget)
		local nCurrentFatigues = DB.getValue(nodeTarget, "main.fatigue", 0)
		local nNewFatigue = nCurrentFatigues - nFatigues
		local nMaxFatigues = DamageTypeManager.getDamageThreshold(rActor, "main.fatigue") * -1
		local bIncapacitated = nNewFatigue < nMaxFatigues
		if bIncapacitated then
			local rMessage = RollsManager.createResultMessage(sTargetType, nodeTarget, true)
			rMessage.icon = "state_inc"
			if bNonLethal then
				local rEffectActor = ActorManager.getActor(sTargetType, nodeTarget.getNodeName()) ActionEffect.applyEffect(rEffectActor, rEffectActor, ActionEffect.knockedOutEffect()) rMessage.text = Interface.getString("damage_x_knockedout"):format(rMessage.text)
			else
				rMessage.text = Interface.getString("damage_x_incapacitated"):format(rMessage.text)
			end
			Comm.deliverChatMessage(rMessage)
			nNewFatigue = nMaxFatigues
		end
		DB.setValue(nodeTarget, "main.fatigue", "number", nNewFatigue)
		if bIncapacitated then
			DB.setValue(nodeTarget, "inc", "number", 1)
		end
	end
end

function typeOf(var)
    return type(var)
end

function applyMoraleBonus(rActor, sTrait, nodeTrait, sTraitType, vAttack)
    if(sTraitType~="battlemorale")then
        return
	end
    local nodeMassbattle = DB.findNode("massbattle")
    local forceTokensA = DB.getValue(nodeMassbattle, "ForceTokensA",0) + DB.getValue(nodeMassbattle,"AoOLossesThisRoundA",0)
    local forceTokensB = DB.getValue(nodeMassbattle, "ForceTokensB",0) + DB.getValue(nodeMassbattle,"AoOLossesThisRoundB",0)
    local StartForceTokensA = DB.getValue(nodeMassbattle, "StartForceTokensA",10)
    local StartForceTokensB = DB.getValue(nodeMassbattle, "StartForceTokensB",10)
    local leaderAcl, leaderArec = DB.getValue(nodeMassbattle,"leadera")
    local leaderBcl, leaderBrec = DB.getValue(nodeMassbattle,"leaderb")
    local nArmyALossesPenalty = forceTokensA-StartForceTokensA
    local nArmyBLossesPenalty = forceTokensB-StartForceTokensB
    local nodeArmy=nil
    local nodeOtherArmy=nil
    local armyA = false
    if(leaderAcl == rActor.class and leaderArec == rActor.recordname) then
        nodeArmy = nodeMassbattle.getChild("ArmyA")
        nodeOtherArmy = nodeMassbattle.getChild("ArmyB")
        if nArmyALossesPenalty<0 then
			ModifierStack.addOrUpdateSlot("Army Losses", nArmyALossesPenalty)
        end
        armyA = true
	elseif(leaderBcl == rActor.class and leaderBrec == rActor.recordname) then 
        nodeArmy = nodeMassbattle.getChild("ArmyB")
        nodeOtherArmy = nodeMassbattle.getChild("ArmyA")
        if nArmyBLossesPenalty<0 then
			ModifierStack.addOrUpdateSlot("Army Losses", nArmyBLossesPenalty)
        end
	end
    local armyB = not armyA
    if nodeOtherArmy then
        nodeChampions = nodeOtherArmy.getChild("champions")
        for _,participant in pairs(nodeChampions.getChildren()) do
            sBattleEffect = DB.getValue(participant,"battle_effect","")
            if(sBattleEffect=="Terrorize") then
				name = DB.getValue(participant,"name")
				ModifierStack.addOrUpdateSlot(name.."'s Terrorize", -2)
			end
        end
	end
    if armyA then
        local nDefaultMoraleBonus = DB.getValue(nodeMassbattle,"moraleBonusA",0)
        ModifierStack.addOrUpdateSlot("Morale Bonus", nDefaultMoraleBonus)
    else
        local nDefaultMoraleBonus = DB.getValue(nodeMassbattle,"moraleBonusB",0)
        ModifierStack.addOrUpdateSlot("Morale Bonus", nDefaultMoraleBonus)
    end
end

function applyCommandBonus(rActor, sTrait, nodeTrait, sTraitType, vAttack)
    if(sTraitType~="battlecommand")then
        return
	end
    local nodeMassbattle = DB.findNode("massbattle")
    local forceTokensA = DB.getValue(nodeMassbattle, "ForceTokensA",0) + DB.getValue(nodeMassbattle,"AoOLossesThisRoundA",0)
    local forceTokensB = DB.getValue(nodeMassbattle, "ForceTokensB",0) + DB.getValue(nodeMassbattle,"AoOLossesThisRoundB",0)
    local forceBonusA = forceTokensA>forceTokensB and forceTokensA-forceTokensB or 0
    local forceBonusB = forceTokensB>forceTokensA and forceTokensB-forceTokensA or 0
    local leaderAcl, leaderArec = DB.getValue(nodeMassbattle,"leadera")
    local leaderBcl, leaderBrec = DB.getValue(nodeMassbattle,"leaderb")
    local nodeArmy=nil
    local nodeOtherArmy=nil
    local armyA = false
    if(leaderAcl == rActor.class and leaderArec == rActor.recordname) then
        nodeArmy = nodeMassbattle.getChild("ArmyA")
        nodeOtherArmy = nodeMassbattle.getChild("ArmyB")
        if forceBonusA>0 then
			ModifierStack.addOrUpdateSlot("Force Advantage", forceBonusA)
        end
        armyA = true
	elseif(leaderBcl == rActor.class and leaderBrec == rActor.recordname) then 
        nodeArmy = nodeMassbattle.getChild("ArmyB")
        nodeOtherArmy = nodeMassbattle.getChild("ArmyA")
        if forceBonusB>0 then
			ModifierStack.addOrUpdateSlot("Force Advantage", forceBonusB)
        end
	end
    local armyB = not armyA
    if armyA then
        local nTacticalAdvantage = DB.getValue(nodeMassbattle,"tacticalAdvantageA",0)
        if nTacticalAdvantage > 0 then
            ModifierStack.addOrUpdateSlot("Tactical Advantage", nTacticalAdvantage)
		end
        local nBattlePlan = DB.getValue(nodeMassbattle,"battlePlanA",0)
        if nBattlePlan > 0 then
            ModifierStack.addOrUpdateSlot("Battle Plan", nBattlePlan)
		end
	else 
        local nTacticalAdvantage = DB.getValue(nodeMassbattle,"tacticalAdvantageB",0)
        if nTacticalAdvantage > 0 then
            ModifierStack.addOrUpdateSlot("Tactical Advantage", nTacticalAdvantage)
		end
        local nBattlePlan = DB.getValue(nodeMassbattle,"battlePlanB",0)
        if nBattlePlan > 0 then
            ModifierStack.addOrUpdateSlot("Battle Plan", nBattlePlan)
		end
	end
    if nodeArmy then
        nodeChampions = nodeArmy.getChild("champions")
        for _,participant in pairs(nodeChampions.getChildren()) do
            name = DB.getValue(participant,"name")
            battle_impact_bonus = DB.getValue(participant,"battle_impact_bonus",0)
			ModifierStack.addOrUpdateSlot(name.."'s contribution", battle_impact_bonus)
        end
    end
    if nodeOtherArmy then
        nodeChampions = nodeOtherArmy.getChild("champions")
        for _,participant in pairs(nodeChampions.getChildren()) do
            sBattleEffect = DB.getValue(participant,"battle_effect","")
            if(sBattleEffect=="Slaughter") then
				name = DB.getValue(participant,"name")
				ModifierStack.addOrUpdateSlot(name.."'s Slaughter", -2)
			end
        end
	end
end

function removeLeaderA()
    local windowMassbattle = getMassbattleWindow()
    local nodeMassbattle = DB.findNode("massbattle")
    if nodeMassbattle and nodeMassbattle.getChild("leadera") then
		nodeMassbattle.getChild("leadera").setValue("","")
    end
    if nodeMassbattle and nodeMassbattle.getChild("leadera") then
		nodeMassbattle.getChild("leaderadetails").delete()
        nodeMassbattle.createChild("leaderadetails")
    end
    if nodeMassbattle and nodeMassbattle.getChild("leaderAtype") then
		nodeMassbattle.getChild("leaderAtype").setValue("")
    end
    windowMassbattle.update()
end

function removeLeaderB()
    local windowMassbattle = getMassbattleWindow()
    local nodeMassbattle = DB.findNode("massbattle")
    if nodeMassbattle and nodeMassbattle.getChild("leaderb") then
		nodeMassbattle.getChild("leaderb").setValue("","")
    end
    if nodeMassbattle and nodeMassbattle.getChild("leaderb") then
		nodeMassbattle.getChild("leaderbdetails").delete()
        nodeMassbattle.createChild("leaderbdetails")
    end
    if nodeMassbattle and nodeMassbattle.getChild("leaderBtype") then
		nodeMassbattle.getChild("leaderBtype").setValue("")
    end
    windowMassbattle.update()
end

function getLeaderA()
    local nodeMassbattle = DB.findNode("massbattle")
    return nodeMassbattle.getChild("leadera").getValue()
end

function getLeaderB()
    local nodeMassbattle = DB.findNode("massbattle")
    return nodeMassbattle.getChild("leaderb").getValue()
end

function getLeaderADetails()
    local nodeMassbattle = DB.findNode("massbattle")
    return nodeMassbattle.getChild("leaderadetails")
end

function getLeaderBDetails()
    local nodeMassbattle = DB.findNode("massbattle")
    return nodeMassbattle.getChild("leaderbdetails")
end


function getMassbattleWindow()
    if User.isHost() or User.isLocal() then
		massbattle_window = Interface.findWindow("massbattle_host", "massbattle")
	else
		massbattle_window = Interface.findWindow("massbattle_client", "massbattle")
	end
    return massbattle_window
end

function acceptCommandResults()
    local nodeMassbattle = DB.findNode("massbattle")
	-- apply army losses
	local nArmyALosses = DB.getValue(nodeMassbattle,"armyalosses",0)
	local nArmyBLosses = DB.getValue(nodeMassbattle,"armyblosses",0)
    if nArmyALosses > 0 then
        requireMoraleCheck("A")
	end
    if nArmyBLosses > 0 then
        requireMoraleCheck("B")
	end
	local nodeArmyAForceTokens = nodeMassbattle.getChild("ForceTokensA")
	local nodeArmyBForceTokens = nodeMassbattle.getChild("ForceTokensB")
	nArmyAForceTokens = nodeArmyAForceTokens.getValue()
	nArmyBForceTokens = nodeArmyBForceTokens.getValue()
	nodeArmyAForceTokens.setValue(math.max(nArmyAForceTokens-nArmyALosses,0))
	nodeArmyBForceTokens.setValue(math.max(nArmyBForceTokens-nArmyBLosses,0))
    nodeMassbattle.createChild("commandResultsApplied","number").setValue(1)
    DB.deleteChildren(nodeMassbattle, "leaderadetails.command_results")
    DB.deleteChildren(nodeMassbattle, "leaderbdetails.command_results")
    local windowMassbattle = getMassbattleWindow()
    windowMassbattle.update()
    updateClientsMassBattleWindows()
end

function startNextRound()
    local nodeMassbattle = DB.findNode("massbattle")
    local nRound = DB.getValue(nodeMassbattle,"round",1)
    local windowMassbattle = getMassbattleWindow()
    DB.setValue(nodeMassbattle, "armyacommandresult","number",0)
    DB.setValue(nodeMassbattle, "armybcommandresult","number",0)
    DB.deleteChild(nodeMassbattle, "armyacommanded")
    DB.deleteChild(nodeMassbattle, "armybcommanded")
    DB.deleteChild(nodeMassbattle, "commandResultsApplied")
    DB.deleteChildren(nodeMassbattle, "leaderadetails.command_results")
    DB.deleteChildren(nodeMassbattle, "leaderbdetails.command_results")
    DB.setValue(nodeMassbattle, "armyalosses","number",0)
    DB.setValue(nodeMassbattle, "armyblosses","number",0)
    DB.deleteChild(nodeMassbattle, "requireMoraleCheckA")
    DB.deleteChild(nodeMassbattle, "requireMoraleCheckB")
    DB.setValue(nodeMassbattle,"AoOLossesThisRoundA","number",0)
    DB.setValue(nodeMassbattle,"AoOLossesThisRoundB","number",0)
    for _,participant in pairs(DB.getChildren(nodeMassbattle,"ArmyA.champions")) do
        DB.setValue(participant,"participated","number",0)
		DB.deleteChildren(participant,"participation_results")
        DB.setValue(participant,"results_activated","number",0)
        DB.setValue(participant,"battle_effect","string","")
        DB.setValue(participant,"battle_impact_bonus","number",0)
        DB.setValue(participant,"pendingResultsActivated","number",0)
    end
    for _,participant in pairs(DB.getChildren(nodeMassbattle,"ArmyB.champions")) do
        DB.setValue(participant,"participated","number",0)
		DB.deleteChildren(participant,"participation_results")
        DB.setValue(participant,"results_activated","number",0)
        DB.setValue(participant,"battle_effect","string","")
        DB.setValue(participant,"battle_impact_bonus","number",0)
        DB.setValue(participant,"pendingResultsActivated","number",0)
    end

    DB.setValue(nodeMassbattle,"round","number",nRound+1)
    windowMassbattle.update()
    updateClientsMassBattleWindows()
end

function processMassbattleCritFailInjury(draginfo)
    local nWounds = draginfo.getDieList()[1].result + 1
    local sParticipationResultNodePath = draginfo.getMetaData("mb_entry")
    local nodeParticipationResult = DB.findNode(sParticipationResultNodePath)
    local nodeParticipant = nodeParticipationResult.getParent().getParent()
    local sName = DB.getValue(nodeParticipant,"name")
    nodeParticipationResult.createChild("pending_wounds","number").setValue(nWounds)
    sChatMessageText = string.format(Interface.getString("mb_wound_notification_string"),sName,nWounds)
    chat_message = {text = sChatMessageText, dice=draginfo.getDieList(),secret=false,icon="indicator_wounds",diemodifier=1, dicedisplay=1}
    Comm.addChatMessage(chat_message)
end

function setPendingBonus(participationResultNode, nBonus)
	participationResultNode.createChild("pending_battle_impact_bonus","number").setValue(nBonus)
end

function setPendingFatigue(participationResultNode, nFatigues)
	participationResultNode.createChild("pending_fatigues","number").setValue(nFatigues)
end

function setPendingWoundsParticipant(participationResultNode, nWounds)
	participationResultNode.createChild("pending_wounds","number").setValue(nWounds)
end

function activatePendingEffects(participationResultNode)
	local participantNode = participationResultNode.getParent().getParent()
    if participationResultNode and participantNode then
        local nPendingFatigues = DB.getValue(participationResultNode,"pending_fatigues",0)
        local nPendingWounds = DB.getValue(participationResultNode,"pending_wounds",0)
        local nPendingBonus = DB.getValue(participationResultNode,"pending_battle_impact_bonus",0)

        fatigueParticipant(participantNode, nPendingFatigues)
        woundParticipant(participantNode, nPendingWounds)
        setBonus(participantNode, nPendingBonus)

        local bCritFail = DB.getValue(participationResultNode, "critfail", 0) == 1
        local bFail = DB.getValue(participationResultNode, "fail", 0) == 1
        local bSuccess = DB.getValue(participationResultNode, "success", 0) == 1
        local bRaise = DB.getValue(participationResultNode, "raise", 0) == 1
        
        local sCritFailEffect = (participationResultNode.getChild("critfail_battleeffect") and participationResultNode.getChild("critfail_battleeffect").getValue())
        local sRaiseEffect = (participationResultNode.getChild("battle_impact_effect") and participationResultNode.getChild("battle_impact_effect").getValue())
        local sBattleEffect = (bCritFail and sCritFailEffect) or (bRaise and sRaiseEffect) or ""
        if sBattleEffect == "Inspire" then
            recoverForceToken(getForceIDFromParticipant(participantNode))
        elseif sBattleEffect == "Terrorize" then
            -- nothing to do right now
        elseif sBattleEffect == "Valor" then
            setBonus(participantNode, 2)
        elseif sBattleEffect == "Slaughter" then
            -- nothing to do right now
        elseif sBattleEffect == "An Army of One" then
            local sForceID = getForceIDFromParticipant(participantNode)
            local sEnemyForceID = "A"
            if sForceID == "A" then
                sEnemyForceID = "B"
			end
            addAoOReduction(sEnemyForceID)
        end
        if sBattleEffect~="" then
            setBattleEffect(participantNode, sBattleEffect)
        end
    end
    participantNode.createChild("pendingResultsActivated","number").setValue(1)
    local participation_results_list = DB.getChild(participantNode,"participation_results")
    DB.deleteChildren(participation_results_list,".")
end

function setBattleEffect(participant, sBattleEffect)
    DB.setValue(participant,"battle_effect", "string", sBattleEffect)
end

function recoverForceToken(sForceID)
    if string.lower(sForceID) == "a" then
        local nCurForceTokens = DB.getValue(DB.findNode("massbattle"),"ForceTokensA",10)
        local nMaxForceTokens = DB.getValue(DB.findNode("massbattle"), "StartForceTokensA", 10)
        local nNewForceTokens = math.min(nCurForceTokens+1,nMaxForceTokens)
        DB.setValue(DB.findNode("massbattle"),"ForceTokensA","number",nNewForceTokens)
    end
    if string.lower(sForceID) == "b" then
        local nCurForceTokens = DB.getValue(DB.findNode("massbattle"),"ForceTokensB",10)
        local nNewForceTokens = math.min(nCurForceTokens+1,10)
        DB.setValue(DB.findNode("massbattle"),"ForceTokensB","number",nNewForceTokens)
    end
end

function reduceForceToken(sForceID)
    if string.lower(sForceID) == "a" then
        local nCurForceTokens = DB.getValue(DB.findNode("massbattle"),"ForceTokensA",10)
        local nNewForceTokens = math.max(nCurForceTokens-1,0)
        DB.setValue(DB.findNode("massbattle"),"ForceTokensA","number",nNewForceTokens)
    end
    if string.lower(sForceID) == "b" then
        local nCurForceTokens = DB.getValue(DB.findNode("massbattle"),"ForceTokensB",10)
        local nNewForceTokens = math.max(nCurForceTokens-1,0)
        DB.setValue(DB.findNode("massbattle"),"ForceTokensB","number",nNewForceTokens)
    end
end

function getForceIDFromParticipant(participant)
    local sArmyName = participant.getParent().getParent().getName()
    return string.sub(sArmyName,5,5)
end

function requireMoraleCheck(sForceID)
    local nodeMassbattle = DB.findNode("massbattle")
    DB.setValue(nodeMassbattle,"requireMoraleCheck"..sForceID,"number",1)
end

function addAoOReduction(sForceID)
	reduceForceToken(sForceID)
	requireMoraleCheck(sForceID)
    local nodeMassbattle = DB.findNode("massbattle")
    local nAoOLossesThisRound = DB.getValue(nodeMassbattle,"AoOLossesThisRound"..sForceID,0)
    DB.setValue(nodeMassbattle,"AoOLossesThisRound"..sForceID,"number",nAoOLossesThisRound+1)
end

function updateClientsMassBattleWindows()
    tableMessageData={}
    tableMessageData.type="MassBattleWindowUpdate"
    Comm.deliverOOBMessage(tableMessageData)
end

function onOOBMBWUpdate(data)
    windowMassbattle = getMassbattleWindow()
    if windowMassbattle then
		windowMassbattle.update()
    end
end

function onOOBMBApplyCommandResult(data)
    local commandResultNode = DB.findNode(data.node)
    if(commandResultNode)then
		local nResult = DB.getValue(commandResultNode, "total", 0)
		local massbattleNode = DB.findNode("massbattle")
		local armyid = getArmyIDFromCommanderNode(commandResultNode.getParent().getParent())
		DB.setValue(massbattleNode,"army"..armyid.."commandresult","number",nResult)
		DB.setValue(massbattleNode,"army"..armyid.."commanded","number",1)
    end
end

function getMBEntry(nodeChampion)
    local nodeMassbattle = DB.findNode("massbattle")
    local nodeArmyAChampions = DB.getChild(nodeMassbattle, "ArmyA.champions")
    if nodeArmyAChampions then
        for _, participant in pairs(nodeArmyAChampions.getChildren()) do
            local link = participant.getChild("link")
            if link then
                local sLinkType, sLinkValue = link.getValue()
                if sLinkValue == nodeChampion.getPath() then
                    return participant
                end
            end
        end
    end
    local nodeArmyBChampions = DB.getChild(nodeMassbattle, "ArmyB.champions")
    if nodeArmyBChampions then
        for _, participant in pairs(nodeArmyBChampions.getChildren()) do
            local link = participant.getChild("link")
            if link then
                local sLinkType, sLinkValue = link.getValue()
                if sLinkValue == nodeChampion.getPath() then
                    return participant
                end
            end
        end
    end
    return nil
end

function isLeader(nodeChampion)
    local nodeMassbattle = DB.findNode("massbattle")
    local nodeLeaderA = DB.getChild(nodeMassbattle,"leadera")
    if nodeLeaderA then
        local sLeaderAType, sLeaderALink = nodeLeaderA.getValue()
        if sLeaderALink == nodeChampion.getPath() then
            return "a"
		end
    end
    local nodeLeaderB = DB.getChild(nodeMassbattle,"leaderb")
    if nodeLeaderB then
        local sLeaderBType, sLeaderBLink = nodeLeaderB.getValue()
        if sLeaderBLink == nodeChampion.getPath() then
            return "b"
		end
    end
    return false
end
