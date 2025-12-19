-- ================================================
-- UPDATED SENSE ESP LIBRARY SOURCE
-- ================================================
local Sense = {}

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local Camera = Workspace.CurrentCamera

-- Settings
Sense.teamSettings = {
    enemy = {
        enabled = false, box = false, boxColor = {Color3.fromRGB(255, 0, 0), 1},
        boxFill = false, boxFillColor = {Color3.fromRGB(255, 0, 0), 0.5},
        healthBar = false, healthBarColor = {Color3.fromRGB(0, 255, 0), 1},
        healthText = false, name = false, nameColor = {Color3.fromRGB(255, 255, 255), 1},
        distance = false, weapon = false, tracer = false,
        tracerColor = {Color3.fromRGB(255, 0, 0), 1}, tracerOrigin = "Bottom",
        offScreenArrow = false, offScreenArrowColor = {Color3.fromRGB(255, 255, 255), 1},
        offScreenArrowSize = 15, offScreenArrowRadius = 150, offScreenArrowOutline = true,
        chams = false, chamsFillColor = {Color3.fromRGB(255, 0, 0), 0.5},
        chamsOutlineColor = {Color3.fromRGB(255, 0, 0), 0}, chamsVisibleOnly = false,
        box3d = false, box3dColor = {Color3.fromRGB(255, 0, 0), 1},
        skeleton = false, skeletonColor = {Color3.fromRGB(255, 255, 255), 1},
    },
    friendly = {
        enabled = false, box = false, boxColor = {Color3.fromRGB(0, 255, 0), 1},
        boxFill = false, boxFillColor = {Color3.fromRGB(0, 255, 0), 0.5},
        healthBar = false, healthBarColor = {Color3.fromRGB(0, 255, 0), 1},
        healthText = false, name = false, nameColor = {Color3.fromRGB(255, 255, 255), 1},
        distance = false, weapon = false, tracer = false,
        tracerColor = {Color3.fromRGB(0, 255, 0), 1}, tracerOrigin = "Bottom",
        offScreenArrow = false, offScreenArrowColor = {Color3.fromRGB(255, 255, 255), 1},
        offScreenArrowSize = 15, offScreenArrowRadius = 150, offScreenArrowOutline = true,
        chams = false, chamsFillColor = {Color3.fromRGB(0, 255, 0), 0.5},
        chamsOutlineColor = {Color3.fromRGB(0, 255, 0), 0}, chamsVisibleOnly = false,
        box3d = false, box3dColor = {Color3.fromRGB(0, 255, 0), 1},
        skeleton = false, skeletonColor = {Color3.fromRGB(255, 255, 255), 1},
    }
}

Sense.sharedSettings = {
    textSize = 13, textFont = Font.fromEnum(Enum.Font.Code),
    textOutline = true, textOutlineThickness = 1,
    limitDistance = false, maxDistance = 150,
    useTeamColor = false, boxThickness = 1,
    performanceMode = false, hideTeammates = false,
}

Sense.whitelist = {}

local espCache, drawings = {}, {}

local function IsAlive(p)
    local c = p and p.Character
    return c and c:FindFirstChild("HumanoidRootPart") and c:FindFirstChild("Humanoid") and c.Humanoid.Health > 0
end

local function IsTeammate(p)
    local lp = Players.LocalPlayer
    return p.Team == lp.Team and p ~= lp
end

local function GetSettings(p) return IsTeammate(p) and Sense.teamSettings.friendly or Sense.teamSettings.enemy end

local function WorldToViewport(pos)
    local v, o = Camera:WorldToViewportPoint(pos)
    return Vector2.new(v.X, v.Y), o, v.Z
end

local function GetBoundingBox(c)
    local hrp = c:FindFirstChild("HumanoidRootPart")
    if not hrp then return nil end
    local corners, size, cf = {}, c:GetExtentsSize(), hrp.CFrame
    local offsets = {Vector3.new(-size.X/2,-size.Y/2,-size.Z/2),Vector3.new(size.X/2,-size.Y/2,-size.Z/2),
        Vector3.new(-size.X/2,size.Y/2,-size.Z/2),Vector3.new(size.X/2,size.Y/2,-size.Z/2),
        Vector3.new(-size.X/2,-size.Y/2,size.Z/2),Vector3.new(size.X/2,-size.Y/2,size.Z/2),
        Vector3.new(-size.X/2,size.Y/2,size.Z/2),Vector3.new(size.X/2,size.Y/2,size.Z/2)}
    for _, o in ipairs(offsets) do
        local sp, os = WorldToViewport(cf * o)
        if os then table.insert(corners, sp) end
    end
    if #corners == 0 then return nil end
    local minX, minY, maxX, maxY = math.huge, math.huge, -math.huge, -math.huge
    for _, c in ipairs(corners) do
        minX, minY = math.min(minX, c.X), math.min(minY, c.Y)
        maxX, maxY = math.max(maxX, c.X), math.max(maxY, c.Y)
    end
    return {position = Vector2.new(minX, minY), size = Vector2.new(maxX - minX, maxY - minY)}
end

local function GetDistance(c)
    local lp = Players.LocalPlayer
    if not lp.Character or not lp.Character:FindFirstChild("HumanoidRootPart") then return 0 end
    local hrp = c:FindFirstChild("HumanoidRootPart")
    return hrp and (lp.Character.HumanoidRootPart.Position - hrp.Position).Magnitude or 0
end

local function CreateDrawing(t)
    local d = Drawing.new(t)
    table.insert(drawings, d)
    return d
end

local function CreateESP(p)
    if espCache[p] then return end
    local e = {player = p, drawings = {}}
    e.drawings.box = CreateDrawing("Square")
    e.drawings.box.Thickness, e.drawings.box.Filled, e.drawings.box.Visible = Sense.sharedSettings.boxThickness, false, false
    e.drawings.boxFill = CreateDrawing("Square")
    e.drawings.boxFill.Filled, e.drawings.boxFill.Visible = true, false
    e.drawings.healthBarBg = CreateDrawing("Square")
    e.drawings.healthBarBg.Filled, e.drawings.healthBarBg.Color, e.drawings.healthBarBg.Visible = true, Color3.fromRGB(0,0,0), false
    e.drawings.healthBar = CreateDrawing("Square")
    e.drawings.healthBar.Filled, e.drawings.healthBar.Visible = true, false
    for _, n in ipairs({"name", "distance", "weapon", "healthText"}) do
        e.drawings[n] = CreateDrawing("Text")
        e.drawings[n].Center, e.drawings[n].Outline = true, Sense.sharedSettings.textOutline
        e.drawings[n].Font, e.drawings[n].Size, e.drawings[n].Visible = Sense.sharedSettings.textFont, Sense.sharedSettings.textSize, false
    end
    e.drawings.tracer = CreateDrawing("Line")
    e.drawings.tracer.Visible = false
    e.drawings.arrow = CreateDrawing("Triangle")
    e.drawings.arrow.Filled, e.drawings.arrow.Visible = true, false
    e.chams = Instance.new("Highlight")
    e.chams.Enabled, e.chams.DepthMode, e.chams.Parent = false, Enum.HighlightDepthMode.AlwaysOnTop, game.CoreGui
    espCache[p] = e
end

local function RemoveESP(p)
    local e = espCache[p]
    if not e then return end
    for _, d in pairs(e.drawings) do d:Remove() end
    if e.chams then e.chams:Destroy() end
    espCache[p] = nil
end

local function UpdateESP(p)
    local e = espCache[p]
    if not e then return end
    local s, c = GetSettings(p), p.Character
    for _, d in pairs(e.drawings) do d.Visible = false end
    e.chams.Enabled = false
    if not s.enabled or not IsAlive(p) or Sense.whitelist[p.UserId] or (Sense.sharedSettings.hideTeammates and IsTeammate(p)) then return end
    local dist = GetDistance(c)
    if Sense.sharedSettings.limitDistance and dist > Sense.sharedSettings.maxDistance then return end
    local hrp = c:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    local sp, os = WorldToViewport(hrp.Position)
    local b = GetBoundingBox(c)
    local col = Sense.sharedSettings.useTeamColor and p.Team and p.Team.TeamColor.Color or s.boxColor[1]
    if s.box and b then
        e.drawings.box.Position, e.drawings.box.Size = b.position, b.size
        e.drawings.box.Color, e.drawings.box.Transparency = col, s.boxColor[2]
        e.drawings.box.Thickness, e.drawings.box.Visible = Sense.sharedSettings.boxThickness, true
        if s.boxFill then
            e.drawings.boxFill.Position, e.drawings.boxFill.Size = b.position, b.size
            e.drawings.boxFill.Color, e.drawings.boxFill.Transparency = s.boxFillColor[1], 1 - s.boxFillColor[2]
            e.drawings.boxFill.Visible = true
        end
    end
    if s.healthBar and b then
        local h = c:FindFirstChild("Humanoid")
        if h then
            local hp = h.Health / h.MaxHealth
            e.drawings.healthBarBg.Position, e.drawings.healthBarBg.Size = Vector2.new(b.position.X-6,b.position.Y), Vector2.new(3,b.size.Y)
            e.drawings.healthBarBg.Transparency, e.drawings.healthBarBg.Visible = 0.5, true
            local hs = b.size.Y * hp
            e.drawings.healthBar.Position = Vector2.new(b.position.X-6, b.position.Y+(b.size.Y-hs))
            e.drawings.healthBar.Size, e.drawings.healthBar.Color = Vector2.new(3,hs), s.healthBarColor[1]
            e.drawings.healthBar.Transparency, e.drawings.healthBar.Visible = s.healthBarColor[2], true
        end
    end
    if s.name and b then
        e.drawings.name.Position, e.drawings.name.Text = Vector2.new(b.position.X+b.size.X/2,b.position.Y-16), p.Name
        e.drawings.name.Color, e.drawings.name.Transparency = s.nameColor[1], s.nameColor[2]
        e.drawings.name.Size, e.drawings.name.Font = Sense.sharedSettings.textSize, Sense.sharedSettings.textFont
        e.drawings.name.Outline, e.drawings.name.Visible = Sense.sharedSettings.textOutline, true
    end
    if s.distance and b then
        e.drawings.distance.Position = Vector2.new(b.position.X+b.size.X/2,b.position.Y+b.size.Y+2)
        e.drawings.distance.Text, e.drawings.distance.Color = string.format("%d studs",math.floor(dist)), Color3.fromRGB(255,255,255)
        e.drawings.distance.Transparency, e.drawings.distance.Size = 1, Sense.sharedSettings.textSize
        e.drawings.distance.Font, e.drawings.distance.Outline = Sense.sharedSettings.textFont, Sense.sharedSettings.textOutline
        e.drawings.distance.Visible = true
    end
    if s.weapon and b then
        local w = c:FindFirstChildOfClass("Tool")
        e.drawings.weapon.Position = Vector2.new(b.position.X+b.size.X/2,b.position.Y+b.size.Y+16)
        e.drawings.weapon.Text, e.drawings.weapon.Color = w and w.Name or "None", Color3.fromRGB(200,200,200)
        e.drawings.weapon.Transparency, e.drawings.weapon.Size = 1, Sense.sharedSettings.textSize
        e.drawings.weapon.Font, e.drawings.weapon.Outline = Sense.sharedSettings.textFont, Sense.sharedSettings.textOutline
        e.drawings.weapon.Visible = true
    end
    if s.healthText and b then
        local h = c:FindFirstChild("Humanoid")
        if h then
            e.drawings.healthText.Position = Vector2.new(b.position.X-20,b.position.Y+b.size.Y/2)
            e.drawings.healthText.Text, e.drawings.healthText.Color = string.format("%d",math.floor(h.Health)), Color3.fromRGB(255,255,255)
            e.drawings.healthText.Transparency, e.drawings.healthText.Size = 1, Sense.sharedSettings.textSize
            e.drawings.healthText.Font, e.drawings.healthText.Outline = Sense.sharedSettings.textFont, Sense.sharedSettings.textOutline
            e.drawings.healthText.Visible = true
        end
    end
    if s.tracer and os then
        local o = Camera.ViewportSize/2
        if s.tracerOrigin == "Top" then o = Vector2.new(Camera.ViewportSize.X/2,0)
        elseif s.tracerOrigin == "Bottom" then o = Vector2.new(Camera.ViewportSize.X/2,Camera.ViewportSize.Y) end
        e.drawings.tracer.From, e.drawings.tracer.To = o, sp
        e.drawings.tracer.Color, e.drawings.tracer.Transparency = s.tracerColor[1], s.tracerColor[2]
        e.drawings.tracer.Visible = true
    end
    if s.offScreenArrow and not os then
        local cen, dir = Camera.ViewportSize/2, (sp-Camera.ViewportSize/2).Unit
        local ang, ap = math.atan2(dir.Y,dir.X), cen + dir * s.offScreenArrowRadius
        ap = Vector2.new(math.clamp(ap.X,50,Camera.ViewportSize.X-50),math.clamp(ap.Y,50,Camera.ViewportSize.Y-50))
        local sz = s.offScreenArrowSize
        e.drawings.arrow.PointA = ap + Vector2.new(math.cos(ang)*sz,math.sin(ang)*sz)
        e.drawings.arrow.PointB = ap + Vector2.new(math.cos(ang+2.5)*sz,math.sin(ang+2.5)*sz)
        e.drawings.arrow.PointC = ap + Vector2.new(math.cos(ang-2.5)*sz,math.sin(ang-2.5)*sz)
        e.drawings.arrow.Color, e.drawings.arrow.Transparency = s.offScreenArrowColor[1], s.offScreenArrowColor[2]
        e.drawings.arrow.Visible = true
    end
    if s.chams then
        e.chams.Adornee, e.chams.FillColor = c, s.chamsFillColor[1]
        e.chams.FillTransparency, e.chams.OutlineColor = 1-s.chamsFillColor[2], s.chamsOutlineColor[1]
        e.chams.OutlineTransparency = 1-s.chamsOutlineColor[2]
        e.chams.DepthMode = s.chamsVisibleOnly and Enum.HighlightDepthMode.Occluded or Enum.HighlightDepthMode.AlwaysOnTop
        e.chams.Enabled = true
    end
end

function Sense.Load()
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= Players.LocalPlayer then CreateESP(p) end
    end
    Players.PlayerAdded:Connect(CreateESP)
    Players.PlayerRemoving:Connect(RemoveESP)
    RunService.RenderStepped:Connect(function()
        if Sense.sharedSettings.performanceMode and tick()%2<1 then return end
        for p, e in pairs(espCache) do
            if p and p.Parent then UpdateESP(p) else RemoveESP(p) end
        end
    end)
end

function Sense.Unload()
    for p in pairs(espCache) do RemoveESP(p) end
    for _, d in ipairs(drawings) do d:Remove() end
    espCache, drawings = {}, {}
end
