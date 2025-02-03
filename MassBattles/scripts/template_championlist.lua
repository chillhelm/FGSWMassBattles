--
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
--

function onInit()
	if super and super.onInit then
		super.onInit()
	end
end

function initializeChampion(nodeSource, win, sBaseName, vData)
	local rData = (vData and type(vData) == "table") and vData
	local nodeCT = win.getDatabaseNode()
	local sType = win.kind.getValue()

	-- Name
	local sName = (rData and rData.name) or sBaseName
	local sActualName, nNumber = getNPCName(sName)
	win.name.setValue(sActualName)

	-- Token
	if rData and StringManager.isNotBlank(rData.token) then
		win.token.setPrototype(rData.token)
	else
		local sToken = DB.getValue(nodeSource, "token", "")
		if StringManager.isNotBlank(sToken) then
			win.token.setPrototype(sToken)
		else
			DB.setValue(nodeCT, "token", "token", CharacterManager.getTokenPrototype(nodeCT))
		end
	end

end

function addNpc(nodeSource, win, draginfo, vData)
	if not moveEntry(nodeSource, win, draginfo) then
		local sClass = draginfo.getShortcutData()
		win.link.setValue(sClass, nodeSource.getNodeName())

		initializeNpc(nodeSource, win, vData)
	end
	win.linkNpcFields()
	win.participation_skill.update()
	win.update()
end

function initializeNpc(nodeSource, win, vData)
	local sBaseName = DB.getValue(nodeSource, "name")

	win.kind.setValue("npc")

	initializeChampion(nodeSource, win, sBaseName, vData)

	if CharacterManager.isWildCard(nodeSource) then
		DB.setValue(win.getDatabaseNode(), "bennies", "number", BennyManager.getMaxNPCBennies(nodeSource))
		DB.setValue(win.getDatabaseNode(), "wildcard", "number", 1)
	else
		DB.setValue(win.getDatabaseNode(), "wildcard", "number", 0)
	end

	local sGear = DB.getValue(nodeSource, "gear", "")
	if StringManager.isNotBlank(sGear) then
		local rActor = ActorManager.resolveActor(win.getDatabaseNode())
		if rActor then
			local sGearRe = "%[[^%]]+%]"
			while sGear:find(sGearRe) do
				local nStart, nEnd = sGear:find(sGearRe)
				local sEffect = StringManager.trim(sGear:sub(nStart, nEnd))
				local sItem = StringManager.trim(sGear:sub(0, nStart-1):match("([^%.,;]+)$"))
				if StringManager.isNotBlank(sItem) then
					local rEffect = ActionEffect.createStateEffect(sItem .. " " .. sEffect)
					ActionEffect.applyEffect(rActor, rActor, rEffect)
				end
				sGear = sGear:sub(nEnd+1)
			end
		end
	end
end

function addPc(nodeSource, win, draginfo, vData)
	if not moveEntry(nodeSource, win, draginfo) then
		local tokenData = draginfo.getTokenData()
		win.link.setValue("charsheet", nodeSource.getPath())
        win.kind.setValue("pc")

		win.wildcard.setValue(1)

		-- Token
		if tokenData then
			win.token.setPrototype(tokenData)
		end

		-- Link
	end

	win.linkPcFields(nodeSource) -- this will have been skipped during onInit, as type / link were not set
	win.participation_skill.update()
	win.update()
end

function moveEntry(node, win, draginfo)
	if not draginfo or not draginfo.getCustomData then
		return false
	end

	return false
end

-- override
function getCombatantNodeCTs()
	return nil
end

function getNPCName(sFullName)
	local sName = "Untitled"
	local nNumber = 1
	if sFullName then
		sName, nNumber = string.match(sFullName,"^%s*(%S.-)%s*(%d*)%s*$")
	end
	if OptionsManager.isOption("NNPC", "off") then
		return sFullName
	end
	if StringManager.isNotBlank(sName) then
		nNumber = getNextNumber(sName)
		if nNumber == 1 then
			sFullName = sName
		else
			sFullName = sName .. " " .. nNumber
		end
	end
	if nNumber == 1 then
		nNumber = nil
	end
	return sFullName, nNumber
end

function getNextNumber(sName)
	return 1
end
