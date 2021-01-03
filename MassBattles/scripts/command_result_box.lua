function onInit()
	DB.addHandler(getDatabaseNode().getPath(),"onUpdate",update)
	DB.addHandler(getDatabaseNode().getPath(),"onChildUpdate",update)
	update()
end

function update()
	local bIsOwner = getDatabaseNode().isOwner()

	local node = getDatabaseNode()
	apply_result_button.setVisible(bIsOwner)
	apply_result_button.setEnabled(bIsOwner)
	clear_result_button.setVisible(bIsOwner)
	clear_result_button.setEnabled(bIsOwner)
end

function applyParticipationResult()
	MassBattles.applyCommandResult(getDatabaseNode())
end

function deleteParticipationResult()
	getDatabaseNode().delete()
end
