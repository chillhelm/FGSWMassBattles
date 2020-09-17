--
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
--

function onInit()
	if super and super.onInit then
		super.onInit()
	end
end

function onDrop(x, y, draginfo)
	return super.onDrop(x, y, draginfo)
end

function moveEntry(node, win, draginfo)
	if not draginfo or not draginfo.getCustomData then
		return false
	end

	return false
end
