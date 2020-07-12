
aMassBattleShortcutHost = {
    icon="button_ct",
    icon_down="button_ct_down",
    tooltipres="sidebar_tooltip_mb",
    class="massbattle_host",
    path="massbattle",
}

aMassBattleShortcutHost = {
    icon="button_ct",
    icon_down="button_ct_down",
    tooltipres="sidebar_tooltip_mb",
    class="massbattle_client",
    path="massbattle",
}

function onInit()
    if User.isHost() then
		DB.createNode("massbattle").setPublic(true);
        DesktopManager.registerStackShortcuts({aMassBattleShortcutHost})
    elseif User.isClient() then
        DesktopManager.registerStackShortcuts({aMassBattleShortcutClient})
    end
end
