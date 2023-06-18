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

	DB.createChild(getDatabaseNode(), "inc", "number").onUpdate = updateIncapacitated
	updateBackground()

	tokenrefnode.getDatabaseNode().onUpdate = token.onTokenUpdate
	tokenrefid.getDatabaseNode().onUpdate = token.onTokenUpdate
	getDatabaseNode().onObserverUpdate = update
	link.getDatabaseNode().onUpdate = update
	update()
end

function updateOwnership()
	champion_type, champion_record = link.getValue()
	isOwner = DB.isOwner(champion_record)
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


--
-- UPDATE AND EVENT HANDLERS
--

function onWildcardChanged()
	local bWildCard = wildcard.getValue() == 1
	wildcard_icon.setIcon(bWildCard and "wildcard" or "nowildcard")
	if bennies then
		bennies.setVisible(bWildCard)
	end
end

function onTypeChanged()
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
	champion_type, champion_record = link.getValue()
	isOwner = DB.isOwner(champion_record)

	if not isOwner then
		commandButton.setVisible(false)
		command_skill.setComboBoxVisible(false)
		mb_command_label.setVisible(false)
	else
		commandButton.setVisible(true)
		command_skill.setComboBoxVisible(true)
		mb_command_label.setVisible(true)
		command_skill.update()
	end
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

