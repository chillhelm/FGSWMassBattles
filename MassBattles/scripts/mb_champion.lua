--
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
--

function onInit()


	wildcard.getDatabaseNode().onUpdate = onWildcardChanged
	onWildcardChanged()

	kind.getDatabaseNode().onUpdate = onTypeChanged
	onTypeChanged()
	updateDisplay()

	updateMenuOptions()

	DB.createChild(getDatabaseNode(), "inc", "number").onUpdate = updateIncapacitated
	updateBackground()

	tokenrefnode.getDatabaseNode().onUpdate = token.onTokenUpdate
	tokenrefid.getDatabaseNode().onUpdate = token.onTokenUpdate
	update()

	getDatabaseNode().onObserverUpdate = update
end

function getActorShortcut()
	return CharacterManager.getActorShortcut("ct", getDatabaseNode())
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

function onTypeChanged()
    local sType = kind.getValue()
	if StringManager.isNotBlank(sType) and sType == "pc" then
		self.linkPcFields()
	elseif sType == "npc" then
		self.linkNpcFields()
	end
	wildcard_icon.updateMenuOptions()
end

function onIDChanged()
	local sType = kind.getValue()
	if StringManager.isNotBlank(sType) and sType ~= "pc" then
		local bID = LibraryData.getIDState(sType, getDatabaseNode(), true)
		name.setVisible(bID)
	else
		name.setVisible(true)
	end
end

function updateDisplay()
    local sType = kind.getValue()
	if StringManager.isNotBlank(sType) and sType ~= "pc" then
		name.setFrame("textline",0,0,0,0)
	end
end

--
-- UTILITY METHODS
--

function linkPcFields()
	local nodeSource = link.getTargetDatabaseNode()
	if nodeSource then
		name.setLink(nodeSource.getChild("name"))
        token.setLink(DB.getChild(nodeSource, "token"))
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

function getVisibleName()
	return CombatManager.getVisibleName(getDatabaseNode(), true)
end

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
	local participatedNode = getDatabaseNode().getChild("participated")
	local bAlreadyApplied = getDatabaseNode().getChild("pendingResultsActivated") and getDatabaseNode().getChild("pendingResultsActivated").getValue()==1 or false
	if bAlreadyApplied then
		participateButton.setEnabled(false)
		participateButton.setVisible(false)
	else
		participateButton.setEnabled(true)
		participateButton.setVisible(true)
	end
	participation_skill.update()
end

function makeParticipationRoll(bReroll)
	MassBattles.deleteBEChildNodes(getDatabaseNode())
	local sActorType, sActorLink = link.getValue()
	local sSkill = participation_skill.getValue()
	local nodeActor = DB.findNode(sActorLink)
	ModifierManagerSW.applyEffectModifierOnEntity(sActorType, nodeActor, "battleparticipation")
	local sDescPrefix = Interface.getString("mb_participation_roll_prefix")
	local nodeTrait = SkillManager.getSkillNode(nodeActor, sSkill, true)
	local CustomData = {mb_entry=getDatabaseNode().getPath()}
	if bReroll then
		CustomData.reroll=true
	end
	local rActor = CharacterManager.getActorShortcut(sActorType,nodeActor)
	if bReroll then
		ModifierManagerSW.applyTraitModifiers(sActorType, nodeActor, "reroll")
	end
	TraitManager.rollTrait(rActor, nodeTrait, CustomData, sDescPrefix, "battleparticipation")
end

function updateOwnership()
	if (Session.IsHost or User.isLocal()) then
		if(link.getTargetDatabaseNode()) then
			local sNodeOwner = link.getTargetDatabaseNode().getOwner()
			if sNodeOwner and sNodeOwner ~= "" then
				DB.setOwner(getDatabaseNode(),sNodeOwner)
			end
		end
	end
end

function loadPC(nodeSource)
	kind.setValue("pc")
	-- Link
	link.setValue("charsheet", nodeSource.getNodeName())
	participation_skill.update()

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
	participation_skill.update()

	initializeNpc(nodeSource)

	linkNpcFields()
end

function initializeNpc(nodeSource, vData)
	local sBaseName = DB.getValue(nodeSource, "name")
	kind.setValue("npc")

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

function isPC()
    local sType = kind.getValue()
    return StringManager.isNotBlank(sType) and sType == "pc"
end

function onLinkChanged()
    if self.isPC() then
        linkPcFields()
    end
    self.onIDChanged()
    self.updateDisplay()
end
