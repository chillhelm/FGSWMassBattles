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
	end
	local bMoraleBoxVisible =  bCommandResultsApplied and not bResolutionboxVisible
	moralebox.setVisible("bMoraleBoxVisible",bMoraleBoxVisible)
	if bMoraleBoxVisible then
		moralebox.bringToFront()
		if moralebox.subwindow then
			moralebox.subwindow.update()
		end
	end
	local windowHints = HintWindowBox.subwindow
	if windowHints then
		windowHints.setHintState(2)
		if leadera.isEmpty() and leaderb.isEmpty() then
			windowHints.setHintState(1)
		elseif bArmyAHasCommanded or bArmyBHasCommanded then
			windowHints.setHintState(3)
		end
		if bMoraleBoxVisible then
			windowHints.setHintState(4)
		end
		windowHints.update()
	end
end

function getLeaderAShortcut()
	local sActorType = leaderAtype.getValue()
	local nodeActor = leaderA.getTargetDatabaseNode()
	if StringManager.isNotBlank(sActorType) and nodeActor then
		return CharacterManager.getActorShortcut(sActorType, nodeActor)
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


