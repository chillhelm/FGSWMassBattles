--
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
--

local bExpanded = true

function onInit()
	if super and super.onInit then
		super.onInit()
	end
end

--
-- EVENT FUNCTIONS AND HANDLERS
--

function onFilter(win)
	return bExpanded or win.getDatabaseNode() == getFirstChildNode() or win.isTargetedByActiveCombatant() or win.hasPendingResults()
end

-- click events don't seem to pass through ?
--[[function onClickRelease(button, x, y )
	local base_x, base_y = window.groupcount.getPosition()
	local size_x, size_y = window.groupcount.getSize()
	if base_x <= x and x <= base_x + size_x and base_y <= y and y <= base_y + size_y then
		return window.groupcount.onClickRelease(button, x - base_x, y - base_y)
	end
end

function onDoubleClick(x, y)
	local base_x, base_y = window.initcontrol.getPosition()
	local size_x, size_y = window.initcontrol.getSize()
	if base_x <= x and x <= base_x + size_x and base_y <= y and y <= base_y + size_y then
		return window.initcontrol.onDoubleClick(x - base_x, y - base_y)
	end
end]]--

-- Change expansion when the active flag is set or unset
function updateGroupActive()
	setExpanded(window.groupactive.getValue() ~= 0)
end

function onSectionToggle()
	window.windowlist.onSectionToggle()
end

--
-- HELPER FUNCTIONS AND UTIL METHODS
--

function duplicateActor()
	local winSource = window.firstCombatant()
	if winSource and winSource.type.is("npc", "vehicle") then

		local nodeSource = winSource.link.getTargetDatabaseNode()
		local sClass = winSource.link.getValue()

		if not nodeSource or not sClass then
			return
		end

		setExpanded(true)

		local win = createWindow()
		win.link.setValue(sClass, nodeSource.getNodeName())

		local rData = {
			name = winSource.name.getValue(),
			token = winSource.token.getPrototype(),
			friendfoe = winSource.friendfoe.getStringValue(),
			isidentified = winSource.isidentified.getValue(),
			nonid_name = winSource.nonid_name.getValue(),
			size = winSource.size.getValue(),
			space = winSource.space.getValue(),
			reach = winSource.reach.getValue(),
			rundie = DB.getValue(winSource.getDatabaseNode(), "rundie", {})
		}
		local aDerivedStats = {}
		for _,ctrl in pairs(winSource.derivedstats.getDerivedStatControls()) do
			local vValue = ctrl.getValue()
			table.insert(aDerivedStats, { name = ctrl.getName(), type = type(vValue), value = vValue })
		end
		rData.derivedstats = aDerivedStats

		rData.weaponSource = winSource.getDatabaseNode()
		rData.powerSource = winSource.getDatabaseNode()

		if winSource.type.is("npc") then
			initializeNpc(nodeSource, win, rData)
			win.linkNpcFields()
		elseif winSource.type.is("vehicle") then
			initializeVehicle(nodeSource, win, rData)
			win.linkVehicleFields()
		end
	end
end

-- Toggle the list expansion
function toggleDisplay()
	setExpanded(not bExpanded)
end

-- set the list expansion state
function setExpanded(bState)
	bExpanded = bState
	applyFilter()
	window.groupcount.setExpanded(bExpanded)
end

-- return all the nodes by passing the call up to the combatant group windowlist
function getCombatantNodeCTs()
	return window.windowlist.getCombatantNodeCTs()
end

--
-- DROP FUNCTION OVERRIDES
--

function onDrop(x, y, draginfo)
	return super.onDrop(x, y, draginfo)
end

function onGroupDrop(x, y, draginfo)
	local rCustomData = draginfo.getCustomData() or {}
	rCustomData.bGroupDrop = true
	draginfo.setCustomData(rCustomData)
	return super.onDrop(x, y, draginfo)
end

function onWindowAdded(source, child)
	DB.setValue(child, "tokenvis", "number", 1)
end

function onWindowUpdate(source, listchanged)
	if listchanged then
		applyFilter()
	end
end

function addNpc(source, win, draginfo, vData)
	super.addNpc(source, wi5n, draginfo, vData)
end

-- 
-- Pending results
--

function onPendingResultsUpdated()
	applyFilter()
end


function update()
	local windowlist = getWindows()
	for _,win in pairs(windowlist) do
		win.update()
	end
end
