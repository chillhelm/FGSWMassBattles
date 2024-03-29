--
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
--

function onInit()
	wildcard.getDatabaseNode().onUpdate = onWildcardChanged
	onWildcardChanged()
	DB.addHandler(DB.getPath(kind.getDatabaseNode()), "onUpdate", onTypeChanged);
	onTypeChanged()
	updateDisplay()

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

function getVisibleName()
	return CombatManager.getVisibleName(getDatabaseNode(), true)
end

function updateMenuOptions()
	resetMenuItems()
	if Session.IsHost then
		registerMenuItem(Interface.getString("ct_menu_delete_combatants"), "delete", 6)
		registerMenuItem(Interface.getString("ct_menu_delete_combatants_confirm"), "delete", 6, 7)
	end
end

--
-- UPDATE AND EVENT HANDLERS
--

function onMenuSelection(nOption, nSubOption)
    if not getDatabaseNode() then
        return
    end

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

function onTypeChanged()
	if kind.is("pc") then
		self.linkPcFields()
	elseif kind.is("npc") then
		self.linkNpcFields()
	end
	wildcard_icon.updateMenuOptions()
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
	if kind.isNot("pc") then
		name.setFrame("textline",0,0,0,0)
	end
end

--
-- DROP HANDLING
--

function onDrop(x, y, draginfo)
    if not getDatabaseNode() then
        return
    end
    if draginfo.isType("shortcut") then
      armyID = MassBattles.getArmyIDFromCommanderNode(getDatabaseNode())
      if armyID=="a" then
          self.parentcontrol.window.leaderASlot.onDrop(x,y,draginfo)
      else
          self.parentcontrol.window.leaderBSlot.onDrop(x,y,draginfo)
      end
    end
end

--
-- UTILITY METHODS
--

function isVisibleEntry()
	return kind.is("pc") or tokenvis.getState()
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
	updateOwnership()
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

function updateBackground()
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

	initializeChampion(nodeSource, sBaseName, vData)

	if CharacterManager.isWildCard(nodeSource) then
		DB.setValue(getDatabaseNode(), "bennies", "number", BennyManager.getMaxNPCBennies(nodeSource))
	end

	local sGear = DB.getValue(nodeSource, "gear", "")
	if StringManager.isNotBlank(sGear) then
		local rActor = ActorManager.resolveActor(getDatabaseNode())
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
	type.setValue("pc")
	-- Link
	link.setValue("charsheet", nodeSource.getNodeName())
	command_skill.update()

	linkPcFields(nodeSource) -- this will have been skipped during onInit, as type / link were not set

	wildcard.setValue(1)

	-- Token
	local tokenData = CharacterManager.getTokenPrototype(nodeSource)
	if tokenData then
		token.setPrototype(tokenData)
	end

end

function loadNPC(class, nodeSource)
	local sClass = class
	link.setValue(sClass, nodeSource.getNodeName())
	command_skill.update()

	initializeNpc(nodeSource)

	linkNpcFields()
end

function makeCommandRoll(bReroll)
	local sActorType, sActorLink = link.getValue()
	local sSkill = command_skill.getValue()
	local nodeActor = DB.findNode(sActorLink)
	ModifierManagerSW.applyEffectModifierOnEntity(sActorType, nodeActor, "battlecommand")
	local sDescPrefix = Interface.getString("mb_command_roll_prefix")
	local nodeTrait = SkillManager.getSkillNode(nodeActor, sSkill, true)
	if bReroll then
		ModifierManagerSW.applyTraitModifiers(sActorType, nodeActor, "reroll")
	end
	TraitManager.rollPreDefinedRoll(sActorType, nodeActor, nodeTrait, sDescPrefix, "battlecommand", {["mb_entry"]=getDatabaseNode().getPath()})
end

function updateOwnership()
	if (Session.IsHost or Session.IsLocal) then
		if(link.getTargetDatabaseNode()) then
			local sNodeOwner = link.getTargetDatabaseNode().getOwner()
			if sNodeOwner and sNodeOwner ~= "" then
				DB.setOwner(getDatabaseNode(),sNodeOwner)
			end
		end
	end
end

