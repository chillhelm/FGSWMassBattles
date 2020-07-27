--
-- Please see the readme.txt file included with this distribution for
-- attribution and copyright information.
--

local widgetScale = nil

function onInit()
	onScaleChanged()
	linkToken()
end

--
--	Token targeting
--

function onDeleted(token)
	setFrame(nil)
	clearTargeting(token)
end

function onContainerChanging(target)
	clearTargeting(target)
end

function clearTargeting(token)
	window.getCombatTrackerWindow().removeTargetingOnEntry(window.getDatabaseNode())
end

function onTokenUpdate()
	local tokenInstance = populateFromImageNode(window.tokenrefnode.getValue(), window.tokenrefid.getValue())
	if tokenInstance then
		setFrame("modstackfocus",2,2,2,2)
		tokenInstance.onDelete = onDeleted
		tokenInstance.onContainerChanging = onContainerChanging
	end
end

--
-- Token link
--

function linkToken()
	local tokenInstance = populateFromImageNode(window.tokenrefnode.getValue(), window.tokenrefid.getValue())
	if tokenInstance then
		TokenManager.linkToken(window.getDatabaseNode(), tokenInstance)
		onTokenUpdate()
	end
end

--
--
-- CT TOKEN EVENT HANDLERS
--
--

function onFactionChanged()
	TokenManager.updateFaction(window.getDatabaseNode())
	TokenManager.updateSpaceReach(window.getDatabaseNode())
end

function onDrop(x, y, draginfo)
	if draginfo.isType("token") then
		local sPrototype, tokenInstance = draginfo.getTokenData()
		setPrototype(sPrototype)
		replaceCombatantToken(tokenInstance)
		return true
	end
end

function onDragStart(draginfo)
	local nSpace = DB.getValue(window.getDatabaseNode(), "space")
	TokenManager.setDragTokenUnits(nSpace)
end

function onDragEnd(draginfo)
	TokenManager.endDragTokenWithUnits()
	local _,tokenInstance = draginfo.getTokenData()
	if tokenInstance then
		replaceCombatantToken(tokenInstance)
	end
	return true
end

function onClickDown(nButton, x, y)
	return true
end

function onClickRelease(nButton, x, y)
	if nButton == 1 then
		if Input.isControlPressed() then
			local nodeActive = CombatManager.getActiveCT()
			if nodeActive then
				local nodeTarget = window.getDatabaseNode()
				if nodeTarget then
					TargetingManager.toggleCTTarget(nodeActive, nodeTarget)
				end
			end
		else
			local tokenInstance = CombatManager.getTokenFromCT(window.getDatabaseNode())
			if tokenInstance and tokenInstance.isActivable() then
				tokenInstance.setActive(not tokenInstance.isActive())
			end
		end
	else
		local tokenInstance = CombatManager.getTokenFromCT(window.getDatabaseNode())
		if tokenInstance then
			tokenInstance.setScale(1.0)
		end
	end

	return true
end

function onDoubleClick(x, y)
	local nodeCT = window.getDatabaseNode()
	if Input.isAltPressed() then
		CombatManager.openRecord(nodeCT)
	elseif not Input.isControlPressed() then
		CombatManager.openMap(nodeCT)
	end
end

function onWheel(nNotches)
	TokenManager.onWheelCT(window.getDatabaseNode(), nNotches)
	return true
end

function onScaleChanged()
	local nScale = window.tokenscale.getValue()
	if nScale == 1 then
		if widgetScale then
			widgetScale.setVisible(false)
		end
	else
		if not widgetScale then
			widgetScale = addTextWidget("sheetlabelmini", "0")
			widgetScale.setFrame("mini_name", 3,1,3,1)
			widgetScale.setPosition("topright", -2, 2)
		end
		widgetScale.setVisible(true)
		widgetScale.setText(string.format("%.1f", nScale))
	end
end

function replaceCombatantToken(tokenInstance)
	CombatManager.replaceCombatantToken(window.getDatabaseNode(), tokenInstance)
	onTokenUpdate()
end
