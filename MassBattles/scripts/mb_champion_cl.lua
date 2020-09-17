--
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
--
local isOwner=false
function onInit()
	updateDisplay()

	updateMenuOptions()

	updateBackground()

	tokenrefnode.getDatabaseNode().onUpdate = token.onTokenUpdate
	tokenrefid.getDatabaseNode().onUpdate = token.onTokenUpdate
	DB.addHandler(getDatabaseNode().getPath(),"onChildUpdate",update)
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

function onVisibilityChanged()
	TokenManager.updateVisibility(getDatabaseNode())
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
	
	if not isOwner then
		participateButton.setVisible(false)
		participation_skill.setVisible(false)
		mb_participation_label.setVisible(false)
	end
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
