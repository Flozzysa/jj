Config                            = {}
Config.DrawDistance               = 10
Config.MarkerColor                = {r = 120, g = 120, b = 240}
Config.EnablePlayerManagement     = false -- enables the actual car dealer job. You'll need esx_addonaccount, esx_billing and esx_society

Config.Locale = GetConvar('esx:locale', 'es')
Config.Locale = GetConvar('esx:locale', 'es')
Config.UseVIPCredits = true -- toggle to use VIP credits for vehicle purchases
Config.LicenseEnable = false -- require people to own drivers license when buying vehicles? Only applies if EnablePlayerManagement is disabled. Requires esx_license

-- looks like this: 'LLL NNN'
-- The maximum plate length is 8 chars (including spaces & symbols), don't go past it!
Config.PlateLetters  = 3
Config.PlateNumbers  = 3
Config.PlateUseSpace = true

Config.OxInventory = ESX.GetConfig().OxInventory

Config.Blip = {
	show = true,
	Sprite = 326,
	Display = 4,
	Scale = 0.8
}

Config.Zones = {

	ShopEntering = {
		Pos   = vector3(-38.63, -1109.39, 26.44),
		Size  = {x = 1.5, y = 1.5, z = 1.0},
		Type  = 1
	},

	ShopInside = {
		Pos     = vector3(-33.2,-1100.98,34.06),
		Size    = {x = 1.5, y = 1.5, z = 1.0},
		Heading = 133.2806,
		Type    = -1
	},

	ShopOutside = {
		Pos     = vector3(-761.2583, -230.5953, 37.2838),
		Size    = {x = 1.5, y = 1.5, z = 1.0},
		Heading = 209.9033,
		Type    = -1
	}

}