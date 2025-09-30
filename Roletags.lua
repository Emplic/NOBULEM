-- RoleTags.lua
local function containsIgnoreCase(tbl, name)
    name = name:lower()
    for _, v in ipairs(tbl) do
        if v:lower() == name then
            return true
        end
    end
    return false
end

local Owners = {"LordLoaff", "Xx_ghostycloudxX", "Emplic"}
local CoOwner = {"dx7_rr"}
local MysStaff = {"notskuIl"}
local Advertisers = {}
local Helper = {}
local Giveaway1 = {"lordquicksy"}

local RankColors = {
    ["nobulem.owner"] = { primary = Color3.fromRGB(0, 0, 0), accent = Color3.fromRGB(255, 0, 0) },
    ["nobulem-owner"] = { primary = Color3.fromRGB(0, 0, 0), accent = Color3.fromRGB(255, 180, 0) },
    ["nobulem.staff"] = { primary = Color3.fromRGB(0, 0, 0), accent = Color3.fromRGB(255, 252, 132) },
    ["nobulem.advertiser"] = { primary = Color3.fromRGB(0, 0, 0), accent = Color3.fromRGB(255, 69, 0) },
    ["nobulem"] = { primary = Color3.fromRGB(0, 0, 0), accent = Color3.fromRGB(225, 225, 225) },
    ["nobulem.helper"] = { primary = Color3.fromRGB(0, 0, 0), accent = Color3.fromRGB(169, 169, 169) },
    ["nobulem.client user"] = { primary = Color3.fromRGB(0, 0, 0), accent = Color3.fromRGB(102, 0, 255) },
    ["nobulem.premium user"] = { primary = Color3.fromRGB(0, 0, 0), accent = Color3.fromRGB(16, 139, 211) }
}

local function getRank(playerName, chatWhitelist)
    if containsIgnoreCase(Owners, playerName) then
        return "nobulem.owner"
    elseif containsIgnoreCase(CoOwner, playerName) then
        return "nobulem.co-owner"
    elseif containsIgnoreCase(MysStaff, playerName) then
        return "nobulem.staff"
    elseif containsIgnoreCase(Advertisers, playerName) then
        return "nobulem.advertiser"
    elseif containsIgnoreCase(Helper, playerName) then
        return "nobulem.helper"
    elseif containsIgnoreCase(Giveaway1, playerName) then
        return "nobulem"
    elseif chatWhitelist[playerName:lower()] then
        return "nobulem.client user"
    end
end

return {
    Owners = Owners,
    CoOwner = CoOwner,
    MysStaff = MysStaff,
    Advertisers = Advertisers,
    Helper = Helper,
    Giveaway1 = Giveaway1,
    RankColors = RankColors,
    getRank = getRank
}
