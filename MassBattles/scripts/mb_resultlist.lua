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

function onSectionToggle()
	window.windowlist.onSectionToggle()
end

--
-- HELPER FUNCTIONS AND UTIL METHODS
--

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

--
-- DROP FUNCTION OVERRIDES
--

function onDrop(x, y, draginfo)
	return super.onDrop(x, y, draginfo)
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
