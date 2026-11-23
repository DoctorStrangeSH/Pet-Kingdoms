--!strict
-- Shared visual tokens for all primary Pet Kingdoms interface windows.
-- Keep semantic aliases here so each screen can retain readable intent-based names.

local Colors = {
	panel = Color3.fromRGB(31, 35, 48),
	panelSoft = Color3.fromRGB(43, 48, 64),
	panelLight = Color3.fromRGB(53, 59, 78),
	card = Color3.fromRGB(53, 59, 78),
	cardSelected = Color3.fromRGB(76, 91, 125),
	cream = Color3.fromRGB(255, 245, 222),
	text = Color3.fromRGB(255, 245, 222),
	muted = Color3.fromRGB(177, 185, 205),
	gold = Color3.fromRGB(255, 205, 112),
	mint = Color3.fromRGB(135, 225, 183),
	valid = Color3.fromRGB(135, 225, 183),
	rose = Color3.fromRGB(244, 151, 169),
	danger = Color3.fromRGB(255, 135, 135),
	invalid = Color3.fromRGB(245, 104, 105),
	track = Color3.fromRGB(76, 84, 105),
}

return table.freeze({
	Colors = table.freeze(Colors),
	Icons = table.freeze({
		Close = "×",
		Back = "←",
		Refresh = "↻",
		Pet = "✦",
		Bunny = "♧",
		Quest = "▤",
		Island = "◇",
		Build = "⌂",
		Wood = "♣",
		Stone = "◆",
		Gold = "●",
		Gems = "♦",
		Lantern = "✧",
		Flower = "✿",
		Fence = "▥",
		FavoriteOn = "★",
		FavoriteOff = "☆",
		Locked = "■",
		Unlocked = "□",
		Move = "↔",
		Rotate = "↻",
		Demolish = "⌫",
		Confirm = "✓",
		Search = "⌕",
	}),
	Typography = table.freeze({
		Display = Enum.Font.GothamBold,
		Body = Enum.Font.Gotham,
		Emphasis = Enum.Font.GothamSemibold,
		Sizes = table.freeze({
			Display = 22,
			Heading = 18,
			Body = 14,
			Caption = 12,
			Micro = 10,
			Numeric = 20,
		}),
	}),
	Motion = table.freeze({
		Fast = 0.12,
		Standard = 0.18,
		Slow = 0.24,
	}),
	Radii = table.freeze({
		Small = UDim.new(0, 8),
		Medium = UDim.new(0, 12),
		Large = UDim.new(0, 16),
	}),
})
