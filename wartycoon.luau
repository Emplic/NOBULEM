-- Updated Sense ESP Library Source
local Sense = {}

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")
local Camera = Workspace.CurrentCamera

-- Settings
Sense.teamSettings = {
    enemy = {
        enabled = false,
        box = false,
        boxColor = {Color3.fromRGB(255, 0, 0), 1},
        boxFill = false,
        boxFillColor = {Color3.fromRGB(255, 0, 0), 0.5},
        healthBar = false,
        healthBarColor = {Color3.fromRGB(0, 255, 0), 1},
        healthText = false,
        name = false,
        nameColor = {Color3.fromRGB(255, 255, 255), 1},
        distance = false,
        weapon = false,
        tracer = false,
        tracerColor = {Color3.fromRGB(255, 0, 0), 1},
        tracerOrigin = "Bottom",
        offScreenArrow = false,
        offScreenArrowColor = {Color3.fromRGB(255, 255, 255), 1},
        offScreenArrowSize = 15,
        offScreenArrowRadius = 150,
        offScreenArrowOutline = true,
        chams = false,
        chamsFillColor = {Color3.fromRGB(255, 0, 0), 0.5},
        chamsOutlineColor = {Color3.fromRGB(255, 0, 0), 0},
        chamsVisibleOnly = false,
        box3d = false,
        box3dColor = {Color3.fromRGB(255, 0, 0), 1},
        skeleton = false,
        skeletonColor = {Color3.fromRGB(255, 255, 255), 1},
    },
    friendly = {
        enabled = false,
        box = false,
        boxColor = {Color3.fromRGB(0, 255, 0), 1},
        boxFill = false,
        boxFillColor = {Color3.fromRGB(0, 255, 0), 0.5},
        healthBar = false,
        healthBarColor = {Color3.fromRGB(0, 255, 0), 1},
        healthText = false,
        name = false,
        nameColor = {Color3.fromRGB(255, 255, 255), 1},
        distance = false,
        weapon = false,
        tracer = false,
        tracerColor = {Color3.fromRGB(0, 255, 0), 1},
        tracerOrigin = "Bottom",
        offScreenArrow = false,
        offScreenArrowColor = {Color3.fromRGB(255, 255, 255), 1},
        offScreenArrowSize = 15,
        offScreenArrowRadius = 150,
        offScreenArrowOutline = true,
        chams = false,
        chamsFillColor = {Color3.fromRGB(0, 255, 0), 0.5},
        chamsOutlineColor = {Color3.fromRGB(0, 255, 0), 0},
        chamsVisibleOnly = false,
        box3d = false,
        box3dColor = {Color3.fromRGB(0, 255, 0), 1},
        skeleton = false,
        skeletonColor = {Color3.fromRGB(255, 255, 255), 1},
    }
}

Sense.sharedSettings = {
    textSize = 13,
    textFont = Font.fromEnum(Enum.Font.Code),
    textOutline = true,
    textOutlineThickness = 1,
    limitDistance = false,
    maxDistance = 150,
    useTeamColor = false,
    boxThickness = 1,
    performanceMode = false,
    hideTeammates = false,
}

Sense.whitelist = {}

-- Storage
local espCache = {}
local drawings = {}

-- Utility Functions
local function IsAlive(player)
    local char = player and player.Character
    return char and char:FindFirstChild("HumanoidRootPart") and char:FindFirstChild("Humanoid") and char.Humanoid.Health > 0
end

local function GetTeam(player)
    return player and player.Team
end

local function IsTeammate(player)
    local lp = Players.LocalPlayer
    return GetTeam(player) == GetTeam(lp) and player ~= lp
end

local function IsWhitelisted(player)
    return Sense.whitelist[player.UserId] == true
end

local function GetSettings(player)
    if IsTeammate(player) then
        return Sense.teamSettings.friendly
    else
        return Sense.teamSettings.enemy
    end
end

local function WorldToViewport(pos)
    local vec, onScreen = Camera:WorldToViewportPoint(pos)
    return Vector2.new(vec.X, vec.Y), onScreen, vec.Z
end

local function GetBoundingBox(char)
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return nil end
    
    local corners = {}
    local size = char:GetExtentsSize()
    local cf = hrp.CFrame
    
    local offsets = {
        Vector3.new(-size.X/2, -size.Y/2, -size.Z/2),
        Vector3.new(size.X/2, -size.Y/2, -size.Z/2),
        Vector3.new(-size.X/2, size.Y/2, -size.Z/2),
        Vector3.new(size.X/2, size.Y/2, -size.Z/2),
        Vector3.new(-size.X/2, -size.Y/2, size.Z/2),
        Vector3.new(size.X/2, -size.Y/2, size.Z/2),
        Vector3.new(-size.X/2, size.Y/2, size.Z/2),
        Vector3.new(size.X/2, size.Y/2, size.Z/2),
    }
    
    for _, offset in ipairs(offsets) do
        local worldPos = cf * offset
        local screenPos, onScreen = WorldToViewport(worldPos)
        if onScreen then
            table.insert(corners, screenPos)
        end
    end
    
    if #corners == 0 then return nil end
    
    local minX, minY = math.huge, math.huge
    local maxX, maxY = -math.huge, -math.huge
    
    for _, corner in ipairs(corners) do
        minX = math.min(minX, corner.X)
        minY = math.min(minY, corner.Y)
        maxX = math.max(maxX, corner.X)
        maxY = math.max(maxY, corner.Y)
    end
    
    return {
        position = Vector2.new(minX, minY),
        size = Vector2.new(maxX - minX, maxY - minY)
    }
end

local function GetDistance(char)
    local lp = Players.LocalPlayer
    if not lp.Character or not lp.Character:FindFirstChild("HumanoidRootPart") then return 0 end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return 0 end
    return (lp.Character.HumanoidRootPart.Position - hrp.Position).Magnitude
end

local function GetWeapon(char)
    local tool = char:FindFirstChildOfClass("Tool")
    return tool and tool.Name or "None"
end

-- Drawing Functions
local function CreateDrawing(type)
    local drawing = Drawing.new(type)
    table.insert(drawings, drawing)
    return drawing
end

local function CreateESP(player)
    if espCache[player] then return end
    
    local esp = {
        player = player,
        drawings = {},
    }
    
    -- Box
    esp.drawings.box = CreateDrawing("Square")
    esp.drawings.box.Thickness = Sense.sharedSettings.boxThickness
    esp.drawings.box.Filled = false
    esp.drawings.box.Visible = false
    
    -- Box Fill
    esp.drawings.boxFill = CreateDrawing("Square")
    esp.drawings.boxFill.Filled = true
    esp.drawings.boxFill.Visible = false
    
    -- Health Bar Background
    esp.drawings.healthBarBg = CreateDrawing("Square")
    esp.drawings.healthBarBg.Filled = true
    esp.drawings.healthBarBg.Color = Color3.fromRGB(0, 0, 0)
    esp.drawings.healthBarBg.Visible = false
    
    -- Health Bar
    esp.drawings.healthBar = CreateDrawing("Square")
    esp.drawings.healthBar.Filled = true
    esp.drawings.healthBar.Visible = false
    
    -- Text elements
    esp.drawings.name = CreateDrawing("Text")
    esp.drawings.name.Center = true
    esp.drawings.name.Outline = Sense.sharedSettings.textOutline
    esp.drawings.name.Font = Sense.sharedSettings.textFont
    esp.drawings.name.Size = Sense.sharedSettings.textSize
    esp.drawings.name.Visible = false
    
    esp.drawings.distance = CreateDrawing("Text")
    esp.drawings.distance.Center = true
    esp.drawings.distance.Outline = Sense.sharedSettings.textOutline
    esp.drawings.distance.Font = Sense.sharedSettings.textFont
    esp.drawings.distance.Size = Sense.sharedSettings.textSize
    esp.drawings.distance.Visible = false
    
    esp.drawings.weapon = CreateDrawing("Text")
    esp.drawings.weapon.Center = true
    esp.drawings.weapon.Outline = Sense.sharedSettings.textOutline
    esp.drawings.weapon.Font = Sense.sharedSettings.textFont
    esp.drawings.weapon.Size = Sense.sharedSettings.textSize
    esp.drawings.weapon.Visible = false
    
    esp.drawings.healthText = CreateDrawing("Text")
    esp.drawings.healthText.Center = true
    esp.drawings.healthText.Outline = Sense.sharedSettings.textOutline
    esp.drawings.healthText.Font = Sense.sharedSettings.textFont
    esp.drawings.healthText.Size = Sense.sharedSettings.textSize
    esp.drawings.healthText.Visible = false
    
    -- Tracer
    esp.drawings.tracer = CreateDrawing("Line")
    esp.drawings.tracer.Visible = false
    
    -- Off-screen arrow
    esp.drawings.arrow = CreateDrawing("Triangle")
    esp.drawings.arrow.Filled = true
    esp.drawings.arrow.Visible = false
    
    -- Chams
    esp.chams = Instance.new("Highlight")
    esp.chams.Enabled = false
    esp.chams.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    esp.chams.Parent = game.CoreGui
    
    espCache[player] = esp
end

local function RemoveESP(player)
    local esp = espCache[player]
    if not esp then return end
    
    for _, drawing in pairs(esp.drawings) do
        drawing:Remove()
    end
    
    if esp.chams then
        esp.chams:Destroy()
    end
    
    espCache[player] = nil
end

local function UpdateESP(player)
    local esp = espCache[player]
    if not esp then return end
    
    local settings = GetSettings(player)
    local char = player.Character
    
    -- Reset visibility
    for _, drawing in pairs(esp.drawings) do
        drawing.Visible = false
    end
    esp.chams.Enabled = false
    
    -- Check conditions
    if not settings.enabled or not IsAlive(player) or IsWhitelisted(player) then
        return
    end
    
    if Sense.sharedSettings.hideTeammates and IsTeammate(player) then
        return
    end
    
    local distance = GetDistance(char)
    if Sense.sharedSettings.limitDistance and distance > Sense.sharedSettings.maxDistance then
        return
    end
    
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    
    local screenPos, onScreen = WorldToViewport(hrp.Position)
    local box = GetBoundingBox(char)
    
    -- Color setup
    local color = settings.boxColor[1]
    if Sense.sharedSettings.useTeamColor and player.Team then
        color = player.Team.TeamColor.Color
    end
    
    -- Update box
    if settings.box and box then
        esp.drawings.box.Position = box.position
        esp.drawings.box.Size = box.size
        esp.drawings.box.Color = color
        esp.drawings.box.Transparency = settings.boxColor[2]
        esp.drawings.box.Thickness = Sense.sharedSettings.boxThickness
        esp.drawings.box.Visible = true
        
        if settings.boxFill then
            esp.drawings.boxFill.Position = box.position
            esp.drawings.boxFill.Size = box.size
            esp.drawings.boxFill.Color = settings.boxFillColor[1]
            esp.drawings.boxFill.Transparency = 1 - settings.boxFillColor[2]
            esp.drawings.boxFill.Visible = true
        end
    end
    
    -- Update health bar
    if settings.healthBar and box then
        local humanoid = char:FindFirstChild("Humanoid")
        if humanoid then
            local healthPercent = humanoid.Health / humanoid.MaxHealth
            
            esp.drawings.healthBarBg.Position = Vector2.new(box.position.X - 6, box.position.Y)
            esp.drawings.healthBarBg.Size = Vector2.new(3, box.size.Y)
            esp.drawings.healthBarBg.Transparency = 0.5
            esp.drawings.healthBarBg.Visible = true
            
            local healthBarSize = box.size.Y * healthPercent
            esp.drawings.healthBar.Position = Vector2.new(box.position.X - 6, box.position.Y + (box.size.Y - healthBarSize))
            esp.drawings.healthBar.Size = Vector2.new(3, healthBarSize)
            esp.drawings.healthBar.Color = settings.healthBarColor[1]
            esp.drawings.healthBar.Transparency = settings.healthBarColor[2]
            esp.drawings.healthBar.Visible = true
        end
    end
    
    -- Update name
    if settings.name and box then
        esp.drawings.name.Position = Vector2.new(box.position.X + box.size.X / 2, box.position.Y - 16)
        esp.drawings.name.Text = player.Name
        esp.drawings.name.Color = settings.nameColor[1]
        esp.drawings.name.Transparency = settings.nameColor[2]
        esp.drawings.name.Size = Sense.sharedSettings.textSize
        esp.drawings.name.Font = Sense.sharedSettings.textFont
        esp.drawings.name.Outline = Sense.sharedSettings.textOutline
        esp.drawings.name.Visible = true
    end
    
    -- Update distance
    if settings.distance and box then
        esp.drawings.distance.Position = Vector2.new(box.position.X + box.size.X / 2, box.position.Y + box.size.Y + 2)
        esp.drawings.distance.Text = string.format("%d studs", math.floor(distance))
        esp.drawings.distance.Color = Color3.fromRGB(255, 255, 255)
        esp.drawings.distance.Transparency = 1
        esp.drawings.distance.Size = Sense.sharedSettings.textSize
        esp.drawings.distance.Font = Sense.sharedSettings.textFont
        esp.drawings.distance.Outline = Sense.sharedSettings.textOutline
        esp.drawings.distance.Visible = true
    end
    
    -- Update weapon
    if settings.weapon and box then
        local weapon = GetWeapon(char)
        esp.drawings.weapon.Position = Vector2.new(box.position.X + box.size.X / 2, box.position.Y + box.size.Y + 16)
        esp.drawings.weapon.Text = weapon
        esp.drawings.weapon.Color = Color3.fromRGB(200, 200, 200)
        esp.drawings.weapon.Transparency = 1
        esp.drawings.weapon.Size = Sense.sharedSettings.textSize
        esp.drawings.weapon.Font = Sense.sharedSettings.textFont
        esp.drawings.weapon.Outline = Sense.sharedSettings.textOutline
        esp.drawings.weapon.Visible = true
    end
    
    -- Update health text
    if settings.healthText and box then
        local humanoid = char:FindFirstChild("Humanoid")
        if humanoid then
            esp.drawings.healthText.Position = Vector2.new(box.position.X - 20, box.position.Y + box.size.Y / 2)
            esp.drawings.healthText.Text = string.format("%d", math.floor(humanoid.Health))
            esp.drawings.healthText.Color = Color3.fromRGB(255, 255, 255)
            esp.drawings.healthText.Transparency = 1
            esp.drawings.healthText.Size = Sense.sharedSettings.textSize
            esp.drawings.healthText.Font = Sense.sharedSettings.textFont
            esp.drawings.healthText.Outline = Sense.sharedSettings.textOutline
            esp.drawings.healthText.Visible = true
        end
    end
    
    -- Update tracer
    if settings.tracer and onScreen then
        local origin = Camera.ViewportSize / 2
        if settings.tracerOrigin == "Top" then
            origin = Vector2.new(Camera.ViewportSize.X / 2, 0)
        elseif settings.tracerOrigin == "Middle" then
            origin = Camera.ViewportSize / 2
        else
            origin = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
        end
        
        esp.drawings.tracer.From = origin
        esp.drawings.tracer.To = screenPos
        esp.drawings.tracer.Color = settings.tracerColor[1]
        esp.drawings.tracer.Transparency = settings.tracerColor[2]
        esp.drawings.tracer.Visible = true
    end
    
    -- Update off-screen arrow
    if settings.offScreenArrow and not onScreen then
        local center = Camera.ViewportSize / 2
        local direction = (screenPos - center).Unit
        local angle = math.atan2(direction.Y, direction.X)
        
        local arrowPos = center + direction * settings.offScreenArrowRadius
        arrowPos = Vector2.new(
            math.clamp(arrowPos.X, 50, Camera.ViewportSize.X - 50),
            math.clamp(arrowPos.Y, 50, Camera.ViewportSize.Y - 50)
        )
        
        local size = settings.offScreenArrowSize
        local p1 = arrowPos + Vector2.new(math.cos(angle) * size, math.sin(angle) * size)
        local p2 = arrowPos + Vector2.new(math.cos(angle + 2.5) * size, math.sin(angle + 2.5) * size)
        local p3 = arrowPos + Vector2.new(math.cos(angle - 2.5) * size, math.sin(angle - 2.5) * size)
        
        esp.drawings.arrow.PointA = p1
        esp.drawings.arrow.PointB = p2
        esp.drawings.arrow.PointC = p3
        esp.drawings.arrow.Color = settings.offScreenArrowColor[1]
        esp.drawings.arrow.Transparency = settings.offScreenArrowColor[2]
        esp.drawings.arrow.Visible = true
    end
    
    -- Update chams
    if settings.chams then
        esp.chams.Adornee = char
        esp.chams.FillColor = settings.chamsFillColor[1]
        esp.chams.FillTransparency = 1 - settings.chamsFillColor[2]
        esp.chams.OutlineColor = settings.chamsOutlineColor[1]
        esp.chams.OutlineTransparency = 1 - settings.chamsOutlineColor[2]
        esp.chams.DepthMode = settings.chamsVisibleOnly and Enum.HighlightDepthMode.Occluded or Enum.HighlightDepthMode.AlwaysOnTop
        esp.chams.Enabled = true
    end
end

-- Main Functions
function Sense.Load()
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= Players.LocalPlayer then
            CreateESP(player)
        end
    end
    
    Players.PlayerAdded:Connect(function(player)
        CreateESP(player)
    end)
    
    Players.PlayerRemoving:Connect(function(player)
        RemoveESP(player)
    end)
    
    RunService.RenderStepped:Connect(function()
        if Sense.sharedSettings.performanceMode and tick() % 2 < 1 then
            return
        end
        
        for player, esp in pairs(espCache) do
            if player and player.Parent then
                UpdateESP(player)
            else
                RemoveESP(player)
            end
        end
    end)
end

function Sense.Unload()
    for player in pairs(espCache) do
        RemoveESP(player)
    end
    
    for _, drawing in ipairs(drawings) do
        drawing:Remove()
    end
    
    espCache = {}
    drawings = {}
end

return Sense
