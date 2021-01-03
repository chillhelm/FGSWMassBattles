--
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
--

function onInit()
	if super and super.onInit then
		super.onInit()
	end
end

function onDrop(x,y,draginfo)
    window.onDrop(x,y,draginfo)
end

