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

--
-- HELPER FUNCTIONS AND UTIL METHODS
--


--
-- DROP FUNCTION OVERRIDES
--

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
