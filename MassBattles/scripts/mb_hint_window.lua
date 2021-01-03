local hint_state=1
local hints = {}

function onInit()
	update()
end

function update()
	for index,hint in pairs(hints) do
		self[hint].setVisible(false)
	end
	if self[hints[hint_state]] then
		self[hints[hint_state]].setVisible(true)
	end
end

function registerHint(index, hint)
	hints[index] = hint
end

function setHintState(index)
	hint_state=index
end
