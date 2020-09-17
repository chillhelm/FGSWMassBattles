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
