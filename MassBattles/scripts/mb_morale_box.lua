function update()
	bMoraleCheckRequiredA = DB.getValue(getDatabaseNode(), "requireMoraleCheckA",0)==1
	bMoraleCheckRequiredB = DB.getValue(getDatabaseNode(), "requireMoraleCheckB",0)==1
	armyAMoraleButton.setVisible(bMoraleCheckRequiredA)
	armyBMoraleButton.setVisible(bMoraleCheckRequiredB)

	armyANoCheckRequiredLabel.setVisible(not bMoraleCheckRequiredA)
	armyBNoCheckRequiredLabel.setVisible(not bMoraleCheckRequiredB)
end
