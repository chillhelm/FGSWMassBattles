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
		armyID = MassBattles.getArmyIDFromCommanderNode(getDatabaseNode())
		if(armyID=="a") then
			MassBattles.removeLeaderA()
		elseif(armyID=="b") then
			MassBattles.removeLeaderB()
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
-- DROP HANDLING
--

function onDrop(x, y, draginfo)
	Debug.chat("onDrop",self, getDatabaseNode())
	if draginfo.isType("shortcut") then
	  armyID = MassBattles.getArmyIDFromCommanderNode(getDatabaseNode())
	  local sClass, sRecord = draginfo.getShortcutData()
	  if sClass == "charsheet" then
		if armyID=="a" then
			MassBattles.removeLeaderA()
			parentcontrol.window.setLeaderA("pc", sClass, sRecord)
		else
			MassBattles.removeLeaderB()
			parentcontrol.window.setLeaderB("pc", sClass, sRecord)
		end
		setPC(DB.findNode(sRecord),draginfo)
	  elseif sClass == "npc" then
		if armyID=="a" then
			MassBattles.removeLeaderA()
			parentcontrol.window.setLeaderA("npc", sClass, sRecord)
		else
			MassBattles.removeLeaderB()
			parentcontrol.window.setLeaderB("npc", sClass, sRecord)
		end
		setNPC(DB.findNode(sRecord),draginfo)
	  end
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
		if not bWildCard then
			bennies.setVisible(false)
		elseif bennies then
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
	command_skill.update()
end

function setPC(nodeSource, draginfo, vData)
	local tokenData = draginfo.getTokenData()
	type.setValue("pc")

	wildcard.setValue(1)

	-- Token
	if tokenData then
		token.setPrototype(tokenData)
	end

	-- Link
	link.setValue("charsheet", nodeSource.getNodeName())
	command_skill.update()

	linkPcFields(nodeSource) -- this will have been skipped during onInit, as type / link were not set
end

function setNPC(nodeSource, draginfo, vData)
	local sClass = draginfo.getShortcutData()
	link.setValue(sClass, nodeSource.getNodeName())
	command_skill.update()

	initializeNpc(nodeSource, vData)

	linkNpcFields()
end

function initializeNpc(nodeSource, vData)
	local sBaseName = DB.getValue(nodeSource, "name")
	type.setValue("npc")
	DerivedStatManager.copyDerivedStatNodes(nodeSource, getDatabaseNode(), "ct")

	initializeChampion(nodeSource, sBaseName, vData)

	if CharacterManager.isWildCard(nodeSource) then
		DB.setValue(getDatabaseNode(), "bennies", "number", BennyManager.getMaxNPCBennies(nodeSource))
	end

	local sGear = DB.getValue(nodeSource, "gear", "")
	if StringManager.isNotBlank(sGear) then
		local rActor = ActorManager.getActor("ct", getDatabaseNode())
		if rActor then
			local sGearRe = "%[[^%]]+%]"
			while sGear:find(sGearRe) do
				local nStart, nEnd = sGear:find(sGearRe)
				local sEffect = StringManager.trim(sGear:sub(nStart, nEnd))
				local sItem = StringManager.trim(sGear:sub(0, nStart-1):match("([^%.,;]+)$"))
				if StringManager.isNotBlank(sItem) then
					local rEffect = ActionEffect.createStateEffect(sItem .. " " .. sEffect)
					ActionEffect.applyEffect(rActor, rActor, rEffect)
				end
				sGear = sGear:sub(nEnd+1)
			end
		end
	end
end

function initializeChampion(nodeSource, sBaseName, vData)
	local rData = (vData and MassBattles.typeOf(vData) == "table") and vData
	local nodeCT = getDatabaseNode()
	local sType = type.getValue()

	-- Name
	local sName = (rData and rData.name) or sBaseName
	name.setValue(sName)

	-- Token
	if rData and StringManager.isNotBlank(rData.token) then
		token.setPrototype(rData.token)
	else
		local sToken = DB.getValue(nodeSource, "token", "")
		if StringManager.isNotBlank(sToken) then
			token.setPrototype(sToken)
		else
			DB.setValue(nodeCT, "token", "token", CharacterManager.getTokenPrototype(nodeCT))
		end
	end

end


function loadPC(nodeSource)
	local tokenData = CharacterManager.getTokenPrototype(nodeSource)
	type.setValue("pc")

	wildcard.setValue(1)

	-- Token
	if tokenData then
		token.setPrototype(tokenData)
	end

	-- Link
	link.setValue("charsheet", nodeSource.getNodeName())
	command_skill.update()

	linkPcFields(nodeSource) -- this will have been skipped during onInit, as type / link were not set
end

function loadNPC(class, nodeSource)
	local sClass = class
	link.setValue(sClass, nodeSource.getNodeName())
	command_skill.update()

	initializeNpc(nodeSource)

	linkNpcFields()
end
