local bSuccess, bFail, bCritFail, bRaise;
function onInit()
	DB.addHandler(getDatabaseNode().getPath(),"onUpdate",update)
	DB.addHandler(getDatabaseNode().getPath(),"onChildUpdate",update)
    DB.addHandler(getDatabaseNode().getChild("soak").getPath(),"onUpdate", update)
    DB.addHandler(getDatabaseNode().getChild("total").getPath(),"onUpdate", update)
    local sRaiseChoiceEffect = DB.getValue(node, "raise_choice_battleeffect")
    if Session.isHost or Session.isLocal then
        if sRaiseChoiceEffect == nil then
            DB.setValue(getDatabaseNode(),"raise_choice_battleeffect","string","")
        end
    end
    DB.addHandler(getDatabaseNode().getPath()..".raise_choice_battleeffect","onUpdate", update)
	--DB.addHandler(getDatabaseNode().getPath(),"onChildUpdate",update)
	update()
end

function update()

	local bIsOwner = getDatabaseNode().isOwner()

	local node = getDatabaseNode()

	local bCritFail = node.getChild("critfail") and node.getChild("critfail").getValue()==1
    local nTotal = DB.getValue(node, "total", 0)
    if Session.isLocal or Session.isHost then
        if nTotal >= 8 and not bCritFail then
            DB.setValue(node, "raise", "number", 1)
            DB.setValue(node, "success", "number", 1)
            DB.setValue(node, "fail", "number", 0)
            DB.setValue(node, "pending_fatigues", "number", 0)
            DB.setValue(node, "pending_wounds", "number", 0)
        elseif nTotal >= 4 and not bCritFail then
            DB.setValue(node, "raise", "number", 0)
            DB.setValue(node, "success", "number", 1)
            DB.setValue(node, "fail", "number", 0)
            DB.setValue(node, "pending_fatigues", "number", 1)
            DB.setValue(node, "pending_wounds", "number", 0)
        elseif not bCritFail then
            DB.setValue(node, "raise", "number", 0)
            DB.setValue(node, "success", "number", 0)
            DB.setValue(node, "fail", "number", 1)
            DB.setValue(node, "pending_fatigues", "number", 0)
            DB.setValue(node, "pending_wounds", "number", 1)
        end
    end
	local bSuccess = node.getChild("success") and node.getChild("success").getValue()==1
	local bFail = node.getChild("fail") and node.getChild("fail").getValue()==1
	local bRaise = node.getChild("raise") and node.getChild("raise").getValue()==1

	local nSoak = DB.getValue(getDatabaseNode(), "soak",0)
    local nSoakedWounds = math.max(math.ceil((nSoak-3)/4),0)
	local nSoakCount = DB.getValue(getDatabaseNode(), "soakcount",0)
    local bShowSoakResult = (nSoakCount ~= 0) and (bFail or bCritFail)
    participation_result_soak_label.setVisible(bShowSoakResult)
    soak.setVisible(bShowSoakResult)
    if bShowSoakResult then
         critfail_indicator.setAnchor("left","soak","right","absolute",15)
         success_indicator.setAnchor("left","soak","right","absolute",15)
         raise_indicator.setAnchor("left","soak","right","absolute",15)
         fail_indicator.setAnchor("left","soak","right","absolute",15)
    else
         critfail_indicator.setAnchor("left","total","right","absolute",15)
         success_indicator.setAnchor("left","total","right","absolute",15)
         raise_indicator.setAnchor("left","total","right","absolute",15)
         fail_indicator.setAnchor("left","total","right","absolute",15)
    end
	critfail_indicator.setVisible(false)
	success_indicator.setVisible(false)
	raise_indicator.setVisible(false)
	fail_indicator.setVisible(false)
	apply_result_button.setVisible(bIsOwner)

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
		if bIsOwner then
			showRaiseChoice()
		end
	elseif bSuccess then
		success_indicator.setVisible(true)
		hideRaiseChoice()
	end
	local alreadyApplied = node.getParent().getChild("pendingResultsActivated") and node.getParent().getChild("pendingResultsActivated").getValue()==1 or false
	if bIsOwner and (alreadyApplied or bRaise) then
		apply_result_button.setEnabled(false)
		apply_result_button.setVisible(false)
	elseif bIsOwner then
		apply_result_button.setEnabled(true)
		apply_result_button.setVisible(true)
	else
		apply_result_button.setEnabled(false)
		apply_result_button.setVisible(false)
		clear_result_button.setVisible(false)
		clear_result_button.setEnabled(false)
	end


	if alreadyApplied then
		hideRaiseChoice()
	end

	local nPendingWounds = DB.getValue(getDatabaseNode(), "pending_wounds",0)
	local nPendingFatigues = DB.getValue(getDatabaseNode(), "pending_fatigues",0)
    if Session.isLocal or Session.isHost then
        DB.setValue(getDatabaseNode(), "result_wounds", "number", math.max(nPendingWounds - nSoakedWounds,0))
    end
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

    if not (Session.isHost or Session.isLocal) then
        total.setReadOnly(true)
        soak.setReadOnly(true)
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

function onDrop(x,y,dragdata)
    if dragdata.getType() == "benny" then
      if (DB.getValue(getDatabaseNode(), "pending_wounds", 0) > 0) then
          local sBennySource_ = dragdata.getStringData()
          local actor = dragdata.getDescription()
          --[[if actor == "GM" then
            rActor["recordname"]="GM"
          else
            local sLinkClass, sLinkRecord = DB.getValue(getDatabaseNode().getParent().getParent(),"link")
            rActor["recordname"]=sLinkRecord
          end
          rActor["class"] = "mb"]]--
          local rActor = CharacterManager.getActorShortcut("ct", windowlist.window)
          local rUserData = {sPendingEntryNodeName = getDatabaseNode().getNodeName()}
          BennyManager.consumeBennyToSoak(rActor, {sBennySource = sBennySource_,sConsumerName=dragdata.getDescription()},rUserData)
      end
    end
end

