function onInit()
    local nodeArmyACommandResult = DB.getChild(getDatabaseNode(),"armyacommandresult")
    if(nodeArmyACommandResult)then
        nodeArmyACommandResult.onUpdate = update
    end
    local nodeArmyBCommandResult = DB.getChild(getDatabaseNode(),"armybcommandresult")
    if(nodeArmyBCommandResult)then
        nodeArmyBCommandResult.onUpdate = update
    end
end

function update()
	if not (Session.IsHost or Session.IsLocal) then
		accept_round_results.setVisible(false)
		accept_round_results.setEnabled(false)
	else
		accept_round_results.setVisible(true)
		accept_round_results.setEnabled(true)
	end
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
