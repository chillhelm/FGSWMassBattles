--
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
--
local bInit = false
local nodeSrc = nil

function onInit()
	super.onInit()
	
	initialize()
end

function initialize()
	nodeSrc = window.getDatabaseNode()
	if(nodeSrc)then
		bInit=self.initializeItems()
	end
	local bReadOnly = (nodeSrc.isReadOnly() or not nodeSrc.isOwner())
	local sValue = DB.getValue(nodeSrc, getName())
	setValue(sValue)
	
	if bReadOnly then
		setComboBoxReadOnly(true)
	end
	local participationSkill = nodeSrc.getChild(getName())
	if participationSkill then
		if participationSkill.getValue()==nil then
			participationSkill.setValue("--")
		end
	end
end

function initializeItems()
	clear()
	addItems({"--"})
	local nodeSrc = window.getDatabaseNode()
	bInit=false
	if nodeSrc then
		local linknode = nodeSrc.getChild("link")
		local linktype, linktarget = linknode.getValue()
        if linktarget == "" then
            return bInit
        end
		skill_list = getCharSkillList(DB.findNode(linktarget))
		for _,skill in pairs(skill_list) do
			addItems({skill[1]})
			bInit=true
		end
	end
	return bInit;
end

function onValueChanged()
	if bInit and not isComboBoxReadOnly() and nodeSrc.isOwner() then
		DB.setValue(nodeSrc, getName(), "string", getValue())
	end
end

function update(bReadOnly)
	if(not bInit) then
		bInit = self.initializeItems()
	end
	setComboBoxReadOnly(bReadOnly)
end

function getCharSkillList(characterNode)
	retList={}
	if(characterNode)then
		local skills_node = characterNode.getChild("skills")
		if(skills_node)then
			for _,skillnode in pairs(skills_node.getChildren()) do
				table.insert(retList,{skillnode.getChild("name").getValue(),skillnode.getPath()})
			end
		end
	end
	return retList
end
