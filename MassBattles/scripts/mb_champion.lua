--
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
--

function onInit()


	wildcard.getDatabaseNode().onUpdate = onWildcardChanged
	onWildcardChanged()

	type.getDatabaseNode().onUpdate = onTypeChanged
	onTypeChanged()
	updateDisplay()

	effecticon.initialize()

	updateMenuOptions()

	DB.createChild(getDatabaseNode(), "inc", "number").onUpdate = updateIncapacitated
	updateBackground()

	tokenrefnode.getDatabaseNode().onUpdate = token.onTokenUpdate
	tokenrefid.getDatabaseNode().onUpdate = token.onTokenUpdate
	update()
end

function getActorShortcut()
	return CharacterManager.getActorShortcut("ct", getDatabaseNode())
end

function updateMenuOptions()
	resetMenuItems()
	if User.isHost() then
		registerMenuItem(Interface.getString("ct_menu_delete_combatants"), "delete", 6)
		registerMenuItem(Interface.getString("ct_menu_delete_combatants_confirm"), "delete", 6, 7)
	end
end

function getGroupWindow()
	return windowlist.window
end

function getCombatantGroupList()
	return getGroupWindow().windowlist
end

function getCombatTrackerWindow()
	return getCombatantGroupList().window
end

function isFirstCombatant()
	return NodeManager.equals(self, getGroupWindow().firstCombatant())
end

--
-- UPDATE AND EVENT HANDLERS
--

function onMenuSelection(nOption, nSubOption)
	if nOption == 6 and nSubOption == 7 then
		if windowlist and windowlist.applyFilter then
			windowlist.applyFilter()
		end
		if Input.isAltPressed() then
			for _,w in pairs(windowlist.window.getCombatants()) do
				w.delete()
			end
		else
			delete()
		end
	end
end

function onWildcardChanged()
	local bWildCard = wildcard.getValue() == 1
	wildcard_icon.setIcon(bWildCard and "wildcard" or "nowildcard")
	if bennies then
		bennies.setVisible(bWildCard)
	end
end

function onVisibilityChanged()
	TokenManager.updateVisibility(getDatabaseNode())
end

function onTypeChanged()
	if type.is("pc") then
		self.linkPcFields()
	elseif type.is("npc") then
		self.linkNpcFields()
	end
	wildcard_icon.updateMenuOptions()
	name.updateMenuOptions()
end

function onIDChanged()
	local sType = type.getValue()
	if StringManager.isNotBlank(sType) and sType ~= "pc" then
		local bID = LibraryData.getIDState(sType, getDatabaseNode(), true)
		name.setVisible(bID)
		nonid_name.setVisible(not bID)
		isidentified.setVisible(true)
	else
		name.setVisible(true)
		nonid_name.setVisible(false)
		isidentified.setVisible(false)
	end
end

function updateDisplay()
	if type.isNot("pc") then
		name.setFrame("textline",0,0,0,0)
	end
end

--
-- UTILITY METHODS
--

function isVisibleEntry()
	return type.is("pc") or tokenvis.getState()
end

function setMain(bState)
	newgroup.setEnabled(bState)
	newgroup.setVisible(bState)
	local nIndentOffset = bState and 31 or 74
	token.setStaticBounds(nIndentOffset,6,25,25)

	if bState then
		isidentified.getDatabaseNode().onUpdate = windowlist.window.mainIdentifiedUpdated
		if friendfoe.getSourceNode then
			friendfoe.getSourceNode().onUpdate = windowlist.window.mainFriendFoeUpdated
		end
		if tokenvis.getSourceNode then
			tokenvis.getSourceNode().onUpdate = windowlist.window.mainTokenVisibilityUpdated
		end
	end
end

function updateActive()
	local nodeCT = getDatabaseNode()
	if DB.getValue(nodeCT, "locked", 0) == 1 then
		return
	end
	local bState = active.getState()
	updateDisplay()
	if bState then
		getCombatantGroupList().scrollToWindow(self)
		sendNotification()
		if OptionsManager.isOption("RING", "on") then
			local bOwned, nodeOwnerChar = CombatManager.isOwnedSource(nodeCT, true)
			if bOwned and nodeOwnerChar then
				local sOwnerIdentity = User.getIdentityOwner(nodeOwnerChar.getName())
				if sOwnerIdentity then
					User.ringBell(sOwnerIdentity)
				end
			end
		end
	end
	updateBackground()
end

function sendNotification()
	local displayData = function(sName)
		local nodeActor = link.getTargetDatabaseNode()
		if CharacterManager.isPCAlly(nodeActor) then
			local nodeChar = CharacterManager.getCharsheetNodeRoot(nodeActor)
			sName = "[" .. DB.getValue(nodeChar, "name", "") .. "] " .. sName
		end
		if inc.getState() then
			if type.is("vehicle") then
				return sName .. " (" .. Interface.getString("common_destroyed") .. ")", "state_inc"
			else
				return sName .. " (" .. Interface.getString("common_incapacitated") .. ")", "state_inc"
			end
		elseif shaken.getState() then
			return sName .. " (" .. Interface.getString("common_shaken") .. ")", "state_shaken"
		end
		return sName, "turn_flag"
	end

	local sName, sIcon = displayData(getVisibleName())
	local rMessage = { text = sName, font = "narratorfont", icon = sIcon }

	-- Always show real name to host
	Comm.addChatMessage(rMessage)

	-- Chase notification
	local rChaseNotificationInfo = getChaseNotification()
	local rChaseNotificationHeader = nil
	local rChaseNotification = nil
	if rChaseNotificationInfo then
		if rChaseNotificationInfo.bComplication then
			rChaseNotificationHeader = { 
				font = "narratorfont", 
				icon = "indicator_star_off", 
				text = Interface.getString("ct_chase_complication")
			}
			if rChaseNotificationInfo.nMod then
				rChaseNotificationHeader.dice = {}
				rChaseNotificationHeader.diemodifier = rChaseNotificationInfo.nMod
			end
		end
		rChaseNotification = { 
			font = "systemfont", 
			text = rChaseNotificationInfo.sText or ""
		}

		Comm.addChatMessage(rChaseNotificationHeader)
		Comm.addChatMessage(rChaseNotification)
	end

	if isVisibleEntry() then
		local aIdentities = User.getAllActiveIdentities()
		local aPlayers = {}
		for _,sIdentity in ipairs(aIdentities) do
			table.insert(aPlayers, User.getIdentityOwner(sIdentity))
		end
		if #aPlayers > 0 then
			local sName, sIcon = displayData(getVisibleName())
			rMessage.text = sName
			rMessage.icon = sIcon
			Comm.deliverChatMessage(rMessage, aPlayers)
			if rChaseNotificationHeader and rChaseNotification then
				Comm.deliverChatMessage(rChaseNotificationHeader, aPlayers)
				Comm.deliverChatMessage(rChaseNotification, aPlayers)
			end
		end
	end
end

function linkPcFields()
	local nodeSource = link.getTargetDatabaseNode()
	if nodeSource then
		name.setLink(nodeSource.getChild("name"))
		for _,w in pairs(damages.getDamageTypeControls()) do
			w.setLink(nodeSource.getChild(w.getName()))
		end
		inc.setLink(nodeSource.getChild("inc"))
		if bennies then
			bennies.setLink(nodeSource.getChild("main.bennies"))
		end
	end
end

function linkNpcFields()
	local nodeSource = link.getTargetDatabaseNode()
	if nodeSource then
		local bWildCard = wildcard.getValue() == 1 or DB.getValue(nodeSource, "wildcard", 0) == 1
		wildcard.setValue(bWildCard and 1 or 0)
		if bennies then
			bennies.setLink(DB.createChild(getDatabaseNode(), "bennies", "number"))
		end
	end
end

function delete()
	getDatabaseNode().delete()
end

--
-- ACCESSOR METHODS
--

function hasAbility(sAbility)
	return AbilityManager.hasAbility("ct", getDatabaseNode(), sAbility)
end

function getVisibleName()
	return CombatManager.getVisibleName(getDatabaseNode(), true)
end

function onFactionChanged()
	updateBackgroundColor()
end

function toggleTargetedBy(nodeTargeterCombatant)
	if nodeTargeterCombatant then
		setTargeted(not isTargetedBy(nodeTargeterCombatant), nodeTargeterCombatant)
	end
end

function setTargeted(bStatus, nodeTargeterCT)
	local tokenTargeter = CombatManager.getTokenFromCT(nodeTargeterCT)
	local tokenTarget = CombatManager.getTokenFromCT(getDatabaseNode())
	if tokenTargeter and tokenTarget then
		if bStatus then
			tokenTargeter.setTarget(true, tokenTarget)
		else
			local aTargetNodes = {}
			for _,node in pairs(DB.getChildren(nodeTargeterCT, "targets")) do
				if DB.getValue(node, "noderef") == getDatabaseNode().getNodeName() then
					table.insert(aTargetNodes, node)
				end
			end
			for _,node in pairs(aTargetNodes) do
				if node then
					node.delete()
				end
			end
			if #aTargetNodes > 0 then
				tokenTargeter.setTarget(false, tokenTarget)
			end
		end
	elseif nodeTargeterCT then
		TargetingManager.updateTargeting(bStatus, nodeTargeterCT, getDatabaseNode())
	end
end

function updateBackground()
	effecticon.setSectionVisible()
	updateBackgroundColor()
end

function updateTargetedBackground()
	setBackColor("33" .. CombatManager2.CT_ENTRY_COLORS.targeted)
end

function updateBackgroundColor()
	setBackColor(nil)
end

function updateIncapacitated()
	local nodeCT = getDatabaseNode()
	if ActionTrait.isAutoRollIncapacitation(nodeCT) then
		ActionTrait.rollIncapacitation(nodeCT)
	end
end

--
-- Helpers
--

function isIncapacitated()
	return CharacterManager.isIncapacitated(getDatabaseNode())
end

function update()
	updateOwnership()
	local participatedNode = getDatabaseNode().getChild("participated")
	--[[if(participatedNode and participatedNode.getValue()==1)then
		self.participationResultList.setVisible(true)
	else
		self.participationResultList.setVisible(false)
	end]]--
	local bAlreadyApplied = getDatabaseNode().getChild("pendingResultsActivated") and getDatabaseNode().getChild("pendingResultsActivated").getValue()==1 or false
	if bAlreadyApplied then
		participateButton.setEnabled(false)
		participateButton.setVisible(false)
	else
		participateButton.setEnabled(true)
		participateButton.setVisible(true)
	end
end

function createParticipationResultBox()
	if participation_result_box and participation_result_box.subwindow then
		participation_result_box.subwindow.update()
	elseif participation_result_box then
		destroyParticipationResultBox()
	end
	if not participation_result_box then
		createControl("participationResultBox", "participation_result_box",".participation_result")
		cl,va = participation_result_box.getValue()
        participation_result_node = DB.findNode(getDatabaseNode().getPath()..".participation_result")
		participation_result_box.setValue(cl,getDatabaseNode().getPath()..".participation_result")
		participation_result_box.setVisible(true)
        bSuccess = participation_result_node.getChild("success") and participation_result_node.getChild("success").getValue()==1
        bFail = participation_result_node.getChild("fail") and participation_result_node.getChild("fail").getValue()==1
        bCritFail = participation_result_node.getChild("critfail") and participation_result_node.getChild("critfail").getValue()==1
        bRaise = participation_result_node.getChild("raise") and participation_result_node.getChild("raise").getValue()==1
		spacer.setAnchoredHeight("10")
		createControl("vspace","spacer2")
	end
end

function destroyParticipationResultBox()
	if(participation_result_box)then
		participation_result_box.destroy()
	end
	if(spacer2)then
		spacer2.destroy()
	end
	spacer.setAnchoredHeight("20")
end

function makeParticipationRoll(bReroll)
	MassBattles.deleteBEChildNodes(getDatabaseNode())
	local sActorType, sActorLink = link.getValue()
	local sSkill = participation_skill.getValue()
	local nodeActor = DB.findNode(sActorLink)
	ModifierManager.applyEffectModifierOnEntity(sActorType, nodeActor, "battleparticipation")
	local sDescPrefix = Interface.getString("mb_participation_roll_prefix")
	local nodeTrait = SkillManager.getSkillNode(nodeActor, sSkill, true)
	local CustomData = {["mb_entry"]=getDatabaseNode().getPath()}
	if bReroll then
		CustomData["reroll"]=true
	end
	TraitManager.rollPreDefinedRoll(sActorType, nodeActor, nodeTrait, sDescPrefix, "battleparticipation", CustomData)
end

function updateOwnership()
	if (User.isHost() or User.isLocal()) then
		if(link.getTargetDatabaseNode()) then
			local sNodeOwner = link.getTargetDatabaseNode().getOwner()
			if sNodeOwner and sNodeOwner ~= "" then
				DB.setOwner(getDatabaseNode(),sNodeOwner)
			end
		end
	end
end
