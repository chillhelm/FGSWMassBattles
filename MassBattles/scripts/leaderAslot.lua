local widgetEmpty = nil
local armyID = nil

function onInit()
  if(getName()=="leaderASlot")then
    armyID="A"
	window.leadera.getDatabaseNode().onUpdate = updateWidget
  else
    armyID="B"
	window.leaderb.getDatabaseNode().onUpdate = updateWidget
  end
  if not widgetEmpty then
	widgetEmpty = addTextWidget("list-empty", Interface.getString("vehicle_operator_empty"))
	widgetEmpty.setPosition("center",0,0)
	widgetEmpty.setVisible(false)
  end

  updateWidget()
end

function updateWidget()
  if(armyID=="A") then
	  widgetEmpty.setVisible(window.leadera.isEmpty())
	  if not window.leadera.isEmpty() then
		window.createWidgetLeaderADisplay()
		--widgetLeaderDisplay.subwindow.update()
	  end
  else
	  widgetEmpty.setVisible(window.leaderb.isEmpty())
	  if not window.leaderb.isEmpty() then
		window.createWidgetLeaderBDisplay()
		--widgetLeaderDisplay.subwindow.update()
	  end
  end
end


function update(bReadOnly)
  local bLocalVisible = not bReadOnly or CharacterManager.isOwner(window.getLeaderAShortcut())

  setReadOnly(bReadOnly)
  setVisible(bLocalVisible)

  return bVisible
end

function onDrop(x, y, draginfo)
	Debug.chat("onDrop", self, draginfo)
	if draginfo.isType("shortcut") then
	  local sClass, sRecord = draginfo.getShortcutData()
	  if sClass == "charsheet" then
		if armyID and armyID=="A" then
			window.setLeaderA("pc", sClass, sRecord)
		elseif armyID and armyID=="B" then
			window.setLeaderB("pc", sClass, sRecord)
		end
	  elseif sClass == "npc" then
		if armyID and armyID=="A" then
			window.setLeaderA("npc", sClass, sRecord)
		elseif armyID and armyID=="B" then
			window.setLeaderB("npc", sClass, sRecord)
		end
	  end
	end
end

