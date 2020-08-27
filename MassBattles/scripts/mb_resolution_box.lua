
function update()
	nACommandResult = DB.getValue(getDatabaseNode(),"armyacommandresult",0)
	nBCommandResult = DB.getValue(getDatabaseNode(),"armybcommandresult",0)
	if (nACommandResult-nBCommandResult>=4) then
		-- A wins with a raise
		getDatabaseNode().createChild("armyalosses","number").setValue(0)
		getDatabaseNode().createChild("armyblosses","number").setValue(2)
	elseif (nACommandResult-nBCommandResult>=1) then
		-- A wins a marginal victory
		getDatabaseNode().createChild("armyalosses","number").setValue(1)
		getDatabaseNode().createChild("armyblosses","number").setValue(2)
	elseif(nACommandResult-nBCommandResult==0) then
		-- a tie
		getDatabaseNode().createChild("armyalosses","number").setValue(1)
		getDatabaseNode().createChild("armyblosses","number").setValue(1)
	elseif(nACommandResult-nBCommandResult<=-4) then
		-- B wins a victory
		getDatabaseNode().createChild("armyalosses","number").setValue(2)
		getDatabaseNode().createChild("armyblosses","number").setValue(0)
	else
		-- B wins a marginal victory
		getDatabaseNode().createChild("armyalosses","number").setValue(2)
		getDatabaseNode().createChild("armyblosses","number").setValue(1)
	end
end
