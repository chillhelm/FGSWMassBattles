--
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
--

local bExpanded = true

function onInit()
	if super and super.onInit then
		super.onInit()
	end
	update()
end

--
-- EVENT FUNCTIONS AND HANDLERS
--

function onFilter(win)
	return bExpanded or win.getDatabaseNode() == getFirstChildNode() or win.isTargetedByActiveCombatant() or win.hasPendingResults()
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

--
-- DROP FUNCTION OVERRIDES
--

function onWindowAdded(source, child)
end

function onWindowUpdate(source, listchanged)
	if listchanged then
		applyFilter()
	end
end

function addNpc(source, win, draginfo, vData)
	super.addNpc(source, win, draginfo, vData)
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
