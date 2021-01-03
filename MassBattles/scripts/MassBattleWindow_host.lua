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
	moralebox.setVisible(bMoraleBoxVisible)
	if bMoraleBoxVisible then
		moralebox.setVisible(true)
		moralebox.bringToFront()
		if moralebox.subwindow then
			moralebox.subwindow.update()
		end
    else
        moralebox.setVisible(false)
	end
	local windowHints = HintWindowBox.subwindow
	if windowHints then
		HintWindowBox.setVisible(true)
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

function setLeaderA(sType, sClass, sRecord)
	if DB.isOwner(getDatabaseNode()) and DB.findNode(sRecord) then
		leaderAtype.setValue(sType)
		leadera.setValue(sClass, sRecord)
		local owner = DB.getOwner(sRecord)
		if owner and owner~="" then
			DB.setOwner(getDatabaseNode().getPath()..".leaderadetails", owner)
			DB.setOwner(getDatabaseNode().getPath().."armyacommandresult",owner)
			DB.setOwner(getDatabaseNode().getPath().."armyacommanded",owner)

		end
	end
    MassBattles.updateClientsMassBattleWindows()
end

function setLeaderB(sType, sClass, sRecord)
	if DB.isOwner(getDatabaseNode()) and DB.findNode(sRecord) then
		leaderBtype.setValue(sType)
		leaderb.setValue(sClass, sRecord)
		local owner = DB.getOwner(sRecord)
		if owner and owner~="" then
			DB.setOwner(getDatabaseNode().getPath()..".leaderbdetails", owner)
			DB.setOwner(getDatabaseNode().getPath().."armybcommandresult",owner)
			DB.setOwner(getDatabaseNode().getPath().."armybcommanded",owner)
		end
	end
    MassBattles.updateClientsMassBattleWindows()
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
        if not getDatabaseNode().getChild("leaderadetails") then
            getDatabaseNode().createChild("leaderadetails")
        end
        if self.mbLeaderADisplayBox then
            self.mbLeaderADisplayBox.destroy()
        end
		createControl("mbLeaderADisplayBox", "mbLeaderADisplayBox", ".leaderadetails")
		cl,va = mbLeaderADisplayBox.getValue()
		mbLeaderADisplayBox.setValue(cl,getDatabaseNode().getPath()..".leaderadetails")
		mbLeaderADisplayBox.setVisible(true)
		if leaderAclass == "charsheet" then
			mbLeaderADisplayBox.subwindow.loadPC(DB.findNode(leaderArecord))
		else
			mbLeaderADisplayBox.subwindow.loadNPC(leaderAclass, DB.findNode(leaderArecord))
		end
	end
end

function createWidgetLeaderBDisplay()
    local leaderBclass, leaderBrecord = leaderb.getValue()
    if leaderBrecord and leaderBrecord ~= "" then
        if not getDatabaseNode().getChild("leaderbdetails") then
            getDatabaseNode().createChild("leaderbdetails")
        end
        if self.mbLeaderBDisplayBox then
            self.mbLeaderBDisplayBox.destroy()
        end
		createControl("mbLeaderBDisplayBox", "mbLeaderBDisplayBox", ".leaderbdetails")
		cl,va = mbLeaderBDisplayBox.getValue()
		mbLeaderBDisplayBox.setValue(cl,getDatabaseNode().getPath()..".leaderbdetails")
		mbLeaderBDisplayBox.setVisible(true)
		if leaderBclass == "charsheet" then
			mbLeaderBDisplayBox.subwindow.loadPC(DB.findNode(leaderBrecord))
		else
			mbLeaderBDisplayBox.subwindow.loadNPC(leaderBclass, DB.findNode(leaderBrecord))
		end
	end
end

function openArmyASettings()
	Interface.openWindow("ArmyASettingsWindow","massbattle")
end

function openArmyBSettings()
	Interface.openWindow("ArmyBSettingsWindow","massbattle")
end

