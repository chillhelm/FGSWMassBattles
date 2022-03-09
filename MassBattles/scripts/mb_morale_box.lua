function update()

	local bMoraleCheckRequiredA = DB.getValue(getDatabaseNode(), "requireMoraleCheckA",0)==1
	local bMoraleCheckRequiredB = DB.getValue(getDatabaseNode(), "requireMoraleCheckB",0)==1
	local bIsCommanderA = DB.findNode("massbattle.leaderadetails").isOwner()
	local bIsCommanderB = DB.findNode("massbattle.leaderbdetails").isOwner()
	armyAMoraleButton.setVisible(bMoraleCheckRequiredA)
	armyBMoraleButton.setVisible(bMoraleCheckRequiredB)
	armyAMoraleButton.setEnabled(bMoraleCheckRequiredA and bIsCommanderA)
	armyBMoraleButton.setEnabled(bMoraleCheckRequiredB and bIsCommanderB)
	armyANoCheckRequiredLabel.setVisible(not bMoraleCheckRequiredA)
	armyBNoCheckRequiredLabel.setVisible(not bMoraleCheckRequiredB)
end

function makeMoraleRoll(armyID, bReroll)
	local sActorType=""
	local sActorLink=""
	if armyID=="B" then
		sActorType, sActorLink = MassBattles.getLeaderB()
	elseif armyID=="A" then
		sActorType, sActorLink = MassBattles.getLeaderA()
	else
		return
	end

	local sAttribute = "Spirit"
	local nodeActor = DB.findNode(sActorLink)
	ModifierManagerSW.applyEffectModifierOnEntity(sActorType, nodeActor, "battlemorale")
	local sDescPrefix = Interface.getString("mb_morale_roll_prefix")
	local nodeAttribute = AttributeManager.getAttributeNode(nodeActor, sAttribute)
	CustomData = {}
	if armyID=="B" then
		CustomData.mb_entry = MassBattles.getLeaderBDetails().getPath()
	elseif armyID=="A" then
		CustomData.mb_entry = MassBattles.getLeaderADetails().getPath()
	end
	if bReroll then
		ModifierManager.applyTraitModifiers(sActorType, nodeActor, "reroll")
	end
	TraitManager.rollPreDefinedRoll(sActorType, nodeActor, nodeAttribute, sDescPrefix, "battlemorale",CustomData)
end
