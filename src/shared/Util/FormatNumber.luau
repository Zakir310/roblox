--!strict
-- FormatNumber.luau — nombres abrégés façon simulateur : 9721 → « 9.7K », 157000000 → « 157M ».

local FormatNumber = {}

local SUFFIXES = { "", "K", "M", "B", "T", "Qa", "Qi", "Sx", "Sp", "Oc", "No", "Dc" }

local function trimDecimal(value: number): string
	-- Une décimale tronquée (jamais arrondie vers le haut : 9.99K reste 9.9K et non 10K).
	local truncated = math.floor(value * 10 + 1e-9) / 10
	local text = string.format("%.1f", truncated)
	return (string.gsub(text, "%.0$", ""))
end

-- 0..999 tels quels, puis une décimale sous 100 (9.7K, 15.3M) et entier au-delà (157M).
function FormatNumber.short(n: number): string
	if n ~= n or n == math.huge or n == -math.huge then
		return "0"
	end
	local sign = if n < 0 then "-" else ""
	local value = math.abs(n)
	if value < 1000 then
		return sign .. tostring(math.floor(value))
	end
	local index = 1
	while value >= 1000 and index < #SUFFIXES do
		value /= 1000
		index += 1
	end
	local digits = if value < 100 then trimDecimal(value) else tostring(math.floor(value))
	return sign .. digits .. SUFFIXES[index]
end

-- Multiplicateur : 10.5 → « 10.5 », 3 → « 3 », 1250 → « 1.2K ».
function FormatNumber.multiplier(n: number): string
	if n >= 1000 then
		return FormatNumber.short(n)
	end
	return trimDecimal(n)
end

return FormatNumber
