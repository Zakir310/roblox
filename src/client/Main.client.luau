--!strict
-- Main.client.luau — point d'entrée côté client : affiche l'interface « pixel cubique ».

local HudController = require(script.Parent:WaitForChild("Controllers"):WaitForChild("HudController")) -- @bundle:HudController

HudController.Start()
