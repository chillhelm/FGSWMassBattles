function onInit()
	update()
end

function update()
	mb_center_anchor.reposition()
	--ForceTokensA.update()
	--ForceTokensB.update()
	ArmyA.update()
	ArmyB.update()
	leaderASlot.updateWidget()
	leaderBSlot.updateWidget()
	local bArmyAHasCommanded = getDatabaseNode().getChild("armyacommanded") and (getDatabaseNode().getChild("armyacommanded").getValue()==1)
	local bArmyBHasCommanded =  getDatabaseNode().getChild("armybcommanded") and (getDatabaseNode().getChild("armybcommanded").getValue()==1)
	local bCommandResultsApplied = getDatabaseNode().getChild("commandResultsApplied")~=nil and (getDatabaseNode().getChild("commandResultsApplied").getValue() == 1)
	local bResolutionboxVisible = (bArmyAHasCommanded or bArmyBHasCommanded) and not bCommandResultsApplied
	resolutionbox.setVisible(bResolutionboxVisible)
	if bResolutionboxVisible then
		resolutionbox.bringToFront()
		if resolutionbox.subwindow then
			resolutionbox.subwindow.update()
		end
    else
        resolutionbox.setVisible(false)
	end
	local bMoraleBoxVisible =  bCommandResultsApplied and not bResolutionboxVisible
	moralebox.setVisible("bMoraleBoxVisible",bMoraleBoxVisible)
	if bMoraleBoxVisible then
		moralebox.bringToFront()
		if moralebox.subwindow then
			moralebox.subwindow.update()
		end
    else
        moralebox.setVisible(false)
	end
	local windowHints = HintWindowBox.subwindow
	if windowHints then
		windowHints.setHintState(1)
		local bIsParticipant = false
		local bIsCommander = false
		local mbNode = nil
		local activeIdentities = User.getActiveIdentities()
		for _, identity    in pairs(activeIdentities) do
			local nodeCharacter = CharacterManager.getCharsheetNodeForIdentity(identity)
			local nodeMBParticipant = MassBattles.getMBEntry(nodeCharacter)
			if nodeMBParticipant then
				bIsParticipant = true
				mbNode = nodeMBParticipant
			end
			bIsCommander = MassBattles.isLeader(nodeCharacter)
		end
		if bIsParticipant then
			windowHints.setHintState(2)
			if DB.getValue(mbNode,"participated",0)==1 then
				windowHints.setHintState(3)
			end
			if DB.getValue(mbNode,"pendingResultsActivated", 0)==1 then
				windowHints.setHintState(4)
			end
		end

		if bIsCommander then
			windowHints.setHintState(5)
			local nodeMBCommander = DB.findNode("massbattle.leader"..bIsCommander.."details")
			if nodeMBCommander then
				local nodeCommandResultList = DB.getChild(nodeMBCommander,"command_results")
				if (nodeCommandResultList.getChildCount()>0) then
					windowHints.setHintState(6)
				end
				if (DB.getValue("massbattle.armyacommanded",0)==1) then
					windowHints.setHintState(7)
				end
			end
		end
		windowHints.update()
	end
end

function getLeaderAShortcut()
	local sActorType = leaderAtype.getValue()
	local nodeActor = leaderA.getTargetDatabaseNode()
	if StringManager.isNotBlank(sActorType) and nodeActor then
		return CharacterManager.resolveActor(nodeActor)
	end
end

function hasWidgetLeaderDisplay()
	return self.mbLeaderADisplayBox~=nil
end

function createWidgetLeaderADisplay()
	local leaderAclass, leaderArecord = leadera.getValue()
    if leaderArecord and leaderArecord ~= "" then
        if self.mbLeaderADisplayBox then
            self.mbLeaderADisplayBox.destroy()
        end
		createControl("mbLeaderADisplayBox_client", "mbLeaderADisplayBox", ".leaderadetails")
		cl,va = mbLeaderADisplayBox.getValue()
		mbLeaderADisplayBox.setValue(cl,getDatabaseNode().getPath()..".leaderadetails")
		mbLeaderADisplayBox.setVisible(true)
	end
end

function createWidgetLeaderBDisplay()
    local leaderBclass, leaderBrecord = leaderb.getValue()
    if leaderBrecord and leaderBrecord ~= "" then
        if self.mbLeaderBDisplayBox then
            self.mbLeaderBDisplayBox.destroy()
        end
		createControl("mbLeaderBDisplayBox_client", "mbLeaderBDisplayBox", ".leaderbdetails")
		cl,va = mbLeaderBDisplayBox.getValue()
		mbLeaderBDisplayBox.setValue(cl,getDatabaseNode().getPath()..".leaderbdetails")
		mbLeaderBDisplayBox.setVisible(true)
	end
end


