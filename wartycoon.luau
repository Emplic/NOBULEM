-- services
local runService = game:GetService("RunService");
local players = game:GetService("Players");
local workspace = game:GetService("Workspace");
local httpService = game:GetService("HttpService");

-- variables
local localPlayer = players.LocalPlayer;
local camera = workspace.CurrentCamera;
local viewportSize = camera.ViewportSize;
local container = Instance.new("Folder",
    gethui and gethui() or game:GetService("CoreGui"));

-- locals
local floor = math.floor;
local round = math.round;
local sin = math.sin;
local cos = math.cos;
local clear = table.clear;
local unpack = table.unpack;
local find = table.find;
local create = table.create;
local fromMatrix = CFrame.fromMatrix;

-- methods
local wtvp = camera.WorldToViewportPoint;
local isA = workspace.IsA;
local getPivot = workspace.GetPivot;
local findFirstChild = workspace.FindFirstChild;
local findFirstChildOfClass = workspace.FindFirstChildOfClass;
local getChildren = workspace.GetChildren;
local toOrientation = CFrame.identity.ToOrientation;
local pointToObjectSpace = CFrame.identity.PointToObjectSpace;
local lerpColor = Color3.new().Lerp;
local min2 = Vector2.zero.Min;
local max2 = Vector2.zero.Max;
local lerp2 = Vector2.zero.Lerp;
local min3 = Vector3.zero.Min;
local max3 = Vector3.zero.Max;

-- Custom Font System
local Fonts = {};
local registeredFonts = {};
local fontMap = {
    ["Plex"] = 2,
    ["UI"] = 0,
    ["System"] = 1,
    ["Monospace"] = 3,
    ["Pixel"] = 4,
    ["Minecraftia"] = 5,
    ["Verdana"] = 6
};

-- Function to create directories if they don't exist
local function ensureDirectory(dir)
    local success, result = pcall(function()
        if not isfolder(dir) then
            makefolder(dir)
        end
    end)
    return success
end

-- Function to register a font
local function registerFont(name, weight, style, url)
    -- Create directories
    ensureDirectory("Sense")
    ensureDirectory("Sense/assets")
    ensureDirectory("Sense/fonts")
    
    local assetName = name .. ".ttf"
    local fontFileName = name .. ".font"
    local assetPath = "Sense/assets/" .. assetName
    local fontPath = "Sense/fonts/" .. fontFileName
    
    -- Download and save font file
    local fontContent = game:HttpGet(url)
    writefile(assetPath, fontContent)
    
    -- Create custom asset
    local customAssetPath = getcustomasset(assetPath)
    
    -- Create font data
    local fontData = {
        name = name,
        faces = {
            {
                Name = "Normal",
                weight = weight or 400,
                style = style or "Normal",
                assetId = customAssetPath
            }
        }
    }
    
    -- Save font file
    writefile(fontPath, httpService:JSONEncode(fontData))
    
    -- Load font
    local customFontPath = getcustomasset(fontPath)
    local success, font = pcall(function()
        return Font.fromAssetId(customFontPath)
    end)
    
    if success and font then
        registeredFonts[name] = font
        return font
    end
    
    return nil
end

-- Register all fonts in background
task.spawn(function()
    pcall(function()
        -- Tahoma (as Plex replacement)
        registerFont("Tahoma", 400, "Normal", "https://github.com/KingVonOBlockJoyce/OctoHook-UI/raw/refs/heads/main/fs-tahoma-8px%20(3).ttf")
        
        -- Pixel font
        registerFont("Pixel", 400, "Normal", "https://github.com/KingVonOBlockJoyce/vaderpaste.luau/raw/refs/heads/main/Pixel.ttf")
        
        -- Minecraftia font
        registerFont("Minecraftia", 400, "Normal", "https://github.com/i77lhm/storage/raw/refs/heads/main/fonts/Minecraftia-Regular.ttf")
        
        -- Verdana font
        registerFont("Verdana", 400, "Normal", "https://github.com/i77lhm/storage/raw/refs/heads/main/fonts/Verdana-Font.ttf")
    end)
end)

-- Function to get font enum from font name
local function getFontEnum(fontName)
    return fontMap[fontName] or 2 -- Default to Plex
end

-- Function to check if font is available
local function isFontAvailable(fontName)
    return fontMap[fontName] ~= nil
end

-- constants
local HEALTH_BAR_OFFSET = Vector2.new(5, 0);
local HEALTH_TEXT_OFFSET = Vector2.new(3, 0);
local HEALTH_BAR_OUTLINE_OFFSET = Vector2.new(0, 1);
local NAME_OFFSET = Vector2.new(0, 2);
local DISTANCE_OFFSET = Vector2.new(0, 2);
local VERTICES = {
    Vector3.new(-1, -1, -1),
    Vector3.new(-1, 1, -1),
    Vector3.new(-1, 1, 1),
    Vector3.new(-1, -1, 1),
    Vector3.new(1, -1, -1),
    Vector3.new(1, 1, -1),
    Vector3.new(1, 1, 1),
    Vector3.new(1, -1, 1)
};

-- skeleton mappings
local R15_LINKS = {
    {"Head", "UpperTorso"},
    {"UpperTorso", "LowerTorso"},
    {"LowerTorso", "LeftUpperLeg"},
    {"LeftUpperLeg", "LeftLowerLeg"},
    {"LeftLowerLeg", "LeftFoot"},
    {"LowerTorso", "RightUpperLeg"},
    {"RightUpperLeg", "RightLowerLeg"},
    {"RightLowerLeg", "RightFoot"},
    {"UpperTorso", "LeftUpperArm"},
    {"LeftUpperArm", "LeftLowerArm"},
    {"LeftLowerArm", "LeftHand"},
    {"UpperTorso", "RightUpperArm"},
    {"RightUpperArm", "RightLowerArm"},
    {"RightLowerArm", "RightHand"}
}

local R6_LINKS = {
    {"Head", "Torso"},
    {"Torso", "Left Arm"},
    {"Torso", "Right Arm"},
    {"Torso", "Left Leg"},
    {"Torso", "Right Leg"}
}

-- functions
local function isBodyPart(name)
    return name == "Head" or name:find("Torso") or name:find("Leg") or name:find("Arm");
end

local function getBoundingBox(parts)
    local min, max;
    for i = 1, #parts do
        local part = parts[i];
        local cframe, size = part.CFrame, part.Size;

        min = min3(min or cframe.Position, (cframe - size*0.5).Position);
        max = max3(max or cframe.Position, (cframe + size*0.5).Position);
    end

    local center = (min + max)*0.5;
    local front = Vector3.new(center.X, center.Y, max.Z);
    return CFrame.new(center, front), max - min;
end

local function getInstanceBounds(instance)
    if instance:IsA("Model") then
        return instance:GetBoundingBox();
    elseif instance:IsA("BasePart") then
        return instance.CFrame, instance.Size;
    end
    return nil, nil; 
end

local function worldToScreen(world)
    local screen, inBounds = wtvp(camera, world);
    return Vector2.new(screen.X, screen.Y), inBounds, screen.Z;
end

local function calculateCorners(cframe, size)
    local corners = create(#VERTICES);
    for i = 1, #VERTICES do
        corners[i] = worldToScreen((cframe + size*0.5*VERTICES[i]).Position);
    end

    local min = min2(viewportSize, unpack(corners));
    local max = max2(Vector2.zero, unpack(corners));
    return {
        corners = corners,
        topLeft = Vector2.new(floor(min.X), floor(min.Y)),
        topRight = Vector2.new(floor(max.X), floor(min.Y)),
        bottomLeft = Vector2.new(floor(min.X), floor(max.Y)),
        bottomRight = Vector2.new(floor(max.X), floor(max.Y))
    };
end

local function rotateVector(vector, radians)
    local x, y = vector.X, vector.Y;
    local c, s = cos(radians), sin(radians);
    return Vector2.new(x*c - y*s, x*s + y*c);
end

local function parseColor(self, color, isOutline)
    if color == "Team Color" or (self.interface.sharedSettings.useTeamColor and not isOutline) then
        return self.interface.getTeamColor(self.player) or Color3.new(1,1,1);
    end
    return color;
end

-- esp object
local EspObject = {};
EspObject.__index = EspObject;

function EspObject.new(player, interface)
    local self = setmetatable({}, EspObject);
    self.player = assert(player, "Missing argument #1 (Player expected)");
    self.interface = assert(interface, "Missing argument #2 (table expected)");
    self:Construct();
    return self;
end

function EspObject:_create(class, properties)
    local drawing = Drawing.new(class);
    for property, value in next, properties do
        pcall(function() drawing[property] = value; end);
    end
    self.bin[#self.bin + 1] = drawing;
    return drawing;
end

function EspObject:Construct()
    self.charCache = {};
    self.childCount = 0;
    self.bin = {};
    self.skeletonLines = {};
    
    -- Pre-create skeleton lines
    for i = 1, 16 do 
        self.skeletonLines[i] = self:_create("Line", { Thickness = 1, Visible = false });
    end

    self.drawings = {
        box3d = {
            {
                self:_create("Line", { Thickness = 1, Visible = false }),
                self:_create("Line", { Thickness = 1, Visible = false }),
                self:_create("Line", { Thickness = 1, Visible = false })
            },
            {
                self:_create("Line", { Thickness = 1, Visible = false }),
                self:_create("Line", { Thickness = 1, Visible = false }),
                self:_create("Line", { Thickness = 1, Visible = false })
            },
            {
                self:_create("Line", { Thickness = 1, Visible = false }),
                self:_create("Line", { Thickness = 1, Visible = false }),
                self:_create("Line", { Thickness = 1, Visible = false })
            },
            {
                self:_create("Line", { Thickness = 1, Visible = false }),
                self:_create("Line", { Thickness = 1, Visible = false }),
                self:_create("Line", { Thickness = 1, Visible = false })
            }
        },
        visible = {
            tracerOutline = self:_create("Line", { Thickness = 3, Visible = false }),
            tracer = self:_create("Line", { Thickness = 1, Visible = false }),
            boxFill = self:_create("Square", { Filled = true, Visible = false }),
            boxOutline = self:_create("Square", { Thickness = 3, Visible = false }),
            box = self:_create("Square", { Thickness = 1, Visible = false }),
            healthBarOutline = self:_create("Line", { Thickness = 3, Visible = false }),
            healthBar = self:_create("Line", { Thickness = 1, Visible = false }),
            healthText = self:_create("Text", { Center = true, Visible = false }),
            name = self:_create("Text", { Text = self.player.DisplayName, Center = true, Visible = false }),
            distance = self:_create("Text", { Center = true, Visible = false }),
            weapon = self:_create("Text", { Center = true, Visible = false }),
        },
        hidden = {
            arrowOutline = self:_create("Triangle", { Thickness = 3, Visible = false }),
            arrow = self:_create("Triangle", { Filled = true, Visible = false })
        }
    };

    self.renderConnection = runService.Heartbeat:Connect(function(deltaTime)
        self:Update(deltaTime);
        self:Render(deltaTime);
    end);
end

function EspObject:Destruct()
    self.renderConnection:Disconnect();

    for i = 1, #self.bin do
        self.bin[i]:Remove();
    end

    clear(self);
end

function EspObject:Update()
    local interface = self.interface;

    self.options = interface.teamSettings[interface.isFriendly(self.player) and "friendly" or "enemy"];
    self.character = interface.getCharacter(self.player);
    self.health, self.maxHealth = interface.getHealth(self.player);
    self.weapon = interface.getWeapon(self.player);
    
    -- Check whitelist
    local isWhitelisted = false;
    for _, userId in ipairs(interface.whitelist) do
        if userId == self.player.UserId then
            isWhitelisted = true;
            break;
        end
    end
    
    -- Check priority
    self.isPrioritized = interface.prioritizedPlayer and interface.prioritizedPlayer == self.player;
    
    self.enabled = self.options.enabled and self.character and not isWhitelisted;

    local head = self.enabled and findFirstChild(self.character, "Head");
    if not head then
        self.charCache = {};
        self.onScreen = false;
        return;
    end

    local _, onScreen, depth = worldToScreen(head.Position);
    self.onScreen = onScreen;
    self.distance = depth;

    if interface.sharedSettings.limitDistance and depth > interface.sharedSettings.maxDistance then
        self.onScreen = false;
    end

    if self.onScreen then
        local cache = self.charCache;
        local children = getChildren(self.character);
        if not cache[1] or self.childCount ~= #children then
            clear(cache);

            for i = 1, #children do
                local part = children[i];
                if isA(part, "BasePart") and isBodyPart(part.Name) then
                    cache[#cache + 1] = part;
                end
            end

            self.childCount = #children;
        end

        self.corners = calculateCorners(getBoundingBox(cache));
    elseif self.options.offScreenArrow then
        local cframe = camera.CFrame;
        local flat = fromMatrix(cframe.Position, cframe.RightVector, Vector3.yAxis);
        local objectSpace = pointToObjectSpace(flat, head.Position);
        self.direction = Vector2.new(objectSpace.X, objectSpace.Z).Unit;
    end
end

function EspObject:Render()
    local onScreen = self.onScreen or false;
    local enabled = self.enabled or false;
    local visible = self.drawings.visible;
    local hidden = self.drawings.hidden;
    local box3d = self.drawings.box3d;
    local interface = self.interface;
    local options = self.options;
    local corners = self.corners;
    
    -- Get font value from shared settings
    local fontValue = interface.sharedSettings.textFont;
    local fontEnum = getFontEnum(fontValue);

    -- Apply priority colors if this player is prioritized
    local function getPriorityColor(defaultColor, priorityColor)
        return self.isPrioritized and (priorityColor or defaultColor) or defaultColor;
    end

    -- SKELETON LOGIC
    local skeletonEnabled = enabled and onScreen and options.skeleton;
    if skeletonEnabled and self.character then
        local links = (findFirstChild(self.character, "UpperTorso")) and R15_LINKS or R6_LINKS;
        local index = 1;
        for _, link in ipairs(links) do
            local p1 = findFirstChild(self.character, link[1]);
            local p2 = findFirstChild(self.character, link[2]);
            if p1 and p2 then
                local v1, vis1 = worldToScreen(p1.Position);
                local v2, vis2 = worldToScreen(p2.Position);
                
                if vis1 or vis2 then
                    local line = self.skeletonLines[index];
                    if line then
                        line.Visible = true;
                        line.From = v1;
                        line.To = v2;
                        line.Color = getPriorityColor(
                            parseColor(self, options.skeletonColor[1]), 
                            interface.prioritySkeletonColor and interface.prioritySkeletonColor[1]
                        );
                        line.Transparency = options.skeletonColor[2];
                        index = index + 1;
                    end
                end
            end
        end
        -- Hide unused lines
        for i = index, #self.skeletonLines do
            self.skeletonLines[i].Visible = false;
        end
    else
        for i = 1, #self.skeletonLines do
            self.skeletonLines[i].Visible = false;
        end
    end

    visible.box.Visible = enabled and onScreen and options.box;
    visible.boxOutline.Visible = visible.box.Visible and options.boxOutline;
    if visible.box.Visible then
        local box = visible.box;
        box.Position = corners.topLeft;
        box.Size = corners.bottomRight - corners.topLeft;
        box.Color = getPriorityColor(
            parseColor(self, options.boxColor[1]),
            interface.priorityBoxColor and interface.priorityBoxColor[1]
        );
        box.Transparency = options.boxColor[2];

        local boxOutline = visible.boxOutline;
        boxOutline.Position = box.Position;
        boxOutline.Size = box.Size;
        boxOutline.Color = parseColor(self, options.boxOutlineColor[1], true);
        boxOutline.Transparency = options.boxOutlineColor[2];
    end

    visible.boxFill.Visible = enabled and onScreen and options.boxFill;
    if visible.boxFill.Visible then
        local boxFill = visible.boxFill;
        boxFill.Position = corners.topLeft;
        boxFill.Size = corners.bottomRight - corners.topLeft;
        boxFill.Color = getPriorityColor(
            parseColor(self, options.boxFillColor[1]),
            interface.priorityBoxFillColor and interface.priorityBoxFillColor[1]
        );
        boxFill.Transparency = options.boxFillColor[2];
    end

    visible.healthBar.Visible = enabled and onScreen and options.healthBar;
    visible.healthBarOutline.Visible = visible.healthBar.Visible and options.healthBarOutline;
    if visible.healthBar.Visible then
        local barFrom = corners.topLeft - HEALTH_BAR_OFFSET;
        local barTo = corners.bottomLeft - HEALTH_BAR_OFFSET;

        local healthBar = visible.healthBar;
        healthBar.To = barTo;
        healthBar.From = lerp2(barTo, barFrom, self.health/self.maxHealth);
        
        if self.isPrioritized and interface.priorityHealthBarColor then
            healthBar.Color = interface.priorityHealthBarColor[1];
        else
            healthBar.Color = lerpColor(options.dyingColor, options.healthyColor, self.health/self.maxHealth);
        end

        local healthBarOutline = visible.healthBarOutline;
        healthBarOutline.To = barTo + HEALTH_BAR_OUTLINE_OFFSET;
        healthBarOutline.From = barFrom - HEALTH_BAR_OUTLINE_OFFSET;
        healthBarOutline.Color = parseColor(self, options.healthBarOutlineColor[1], true);
        healthBarOutline.Transparency = options.healthBarOutlineColor[2];
    end

    visible.healthText.Visible = enabled and onScreen and options.healthText;
    if visible.healthText.Visible then
        local barFrom = corners.topLeft - HEALTH_BAR_OFFSET;
        local barTo = corners.bottomLeft - HEALTH_BAR_OFFSET;

        local healthText = visible.healthText;
        healthText.Text = round(self.health) .. "hp";
        healthText.Size = interface.sharedSettings.textSize;
        healthText.Font = fontEnum;
        healthText.Color = getPriorityColor(
            parseColor(self, options.healthTextColor[1]),
            interface.priorityTextColor and interface.priorityTextColor[1]
        );
        healthText.Transparency = options.healthTextColor[2];
        healthText.Outline = options.healthTextOutline;
        healthText.OutlineColor = parseColor(self, options.healthTextOutlineColor, true);
        healthText.Position = lerp2(barTo, barFrom, self.health/self.maxHealth) - healthText.TextBounds*0.5 - HEALTH_TEXT_OFFSET;
    end

    visible.name.Visible = enabled and onScreen and options.name;
    if visible.name.Visible then
        local name = visible.name;
        name.Size = interface.sharedSettings.textSize;
        name.Font = fontEnum;
        name.Color = getPriorityColor(
            parseColor(self, options.nameColor[1]),
            interface.priorityTextColor and interface.priorityTextColor[1]
        );
        name.Transparency = options.nameColor[2];
        name.Outline = options.nameOutline;
        name.OutlineColor = parseColor(self, options.nameOutlineColor, true);
        name.Position = (corners.topLeft + corners.topRight)*0.5 - Vector2.yAxis*name.TextBounds.Y - NAME_OFFSET;
    end

    visible.distance.Visible = enabled and onScreen and self.distance and options.distance;
    if visible.distance.Visible then
        local distance = visible.distance;
        distance.Text = round(self.distance) .. " studs";
        distance.Size = interface.sharedSettings.textSize;
        distance.Font = fontEnum;
        distance.Color = getPriorityColor(
            parseColor(self, options.distanceColor[1]),
            interface.priorityTextColor and interface.priorityTextColor[1]
        );
        distance.Transparency = options.distanceColor[2];
        distance.Outline = options.distanceOutline;
        distance.OutlineColor = parseColor(self, options.distanceOutlineColor, true);
        distance.Position = (corners.bottomLeft + corners.bottomRight)*0.5 + DISTANCE_OFFSET;
    end

    visible.weapon.Visible = enabled and onScreen and options.weapon;
    if visible.weapon.Visible then
        local weapon = visible.weapon;
        weapon.Text = self.weapon;
        weapon.Size = interface.sharedSettings.textSize;
        weapon.Font = fontEnum;
        weapon.Color = getPriorityColor(
            parseColor(self, options.weaponColor[1]),
            interface.priorityTextColor and interface.priorityTextColor[1]
        );
        weapon.Transparency = options.weaponColor[2];
        weapon.Outline = options.weaponOutline;
        weapon.OutlineColor = parseColor(self, options.weaponOutlineColor, true);
        weapon.Position =
            (corners.bottomLeft + corners.bottomRight)*0.5 +
            (visible.distance.Visible and DISTANCE_OFFSET + Vector2.yAxis*visible.distance.TextBounds.Y or Vector2.zero);
    end

    visible.tracer.Visible = enabled and onScreen and options.tracer;
    visible.tracerOutline.Visible = visible.tracer.Visible and options.tracerOutline;
    if visible.tracer.Visible then
        local tracer = visible.tracer;
        tracer.Color = getPriorityColor(
            parseColor(self, options.tracerColor[1]),
            interface.priorityTracerColor and interface.priorityTracerColor[1]
        );
        tracer.Transparency = options.tracerColor[2];
        tracer.To = (corners.bottomLeft + corners.bottomRight)*0.5;
        tracer.From =
            options.tracerOrigin == "Middle" and viewportSize*0.5 or
            options.tracerOrigin == "Top" and viewportSize*Vector2.new(0.5, 0) or
            options.tracerOrigin == "Bottom" and viewportSize*Vector2.new(0.5, 1);

        local tracerOutline = visible.tracerOutline;
        tracerOutline.Color = parseColor(self, options.tracerOutlineColor[1], true);
        tracerOutline.Transparency = options.tracerOutlineColor[2];
        tracerOutline.To = tracer.To;
        tracerOutline.From = tracer.From;
    end

    hidden.arrow.Visible = enabled and (not onScreen) and options.offScreenArrow;
    hidden.arrowOutline.Visible = hidden.arrow.Visible and options.offScreenArrowOutline;
    if hidden.arrow.Visible and self.direction then
        local arrow = hidden.arrow;
        arrow.PointA = min2(max2(viewportSize*0.5 + self.direction*options.offScreenArrowRadius, Vector2.one*25), viewportSize - Vector2.one*25);
        arrow.PointB = arrow.PointA - rotateVector(self.direction, 0.45)*options.offScreenArrowSize;
        arrow.PointC = arrow.PointA - rotateVector(self.direction, -0.45)*options.offScreenArrowSize;
        arrow.Color = getPriorityColor(
            parseColor(self, options.offScreenArrowColor[1]),
            interface.priorityArrowColor and interface.priorityArrowColor[1]
        );
        arrow.Transparency = options.offScreenArrowColor[2];

        local arrowOutline = hidden.arrowOutline;
        arrowOutline.PointA = arrow.PointA;
        arrowOutline.PointB = arrow.PointB;
        arrowOutline.PointC = arrow.PointC;
        arrowOutline.Color = parseColor(self, options.offScreenArrowOutlineColor[1], true);
        arrowOutline.Transparency = options.offScreenArrowOutlineColor[2];
    end

    local box3dEnabled = enabled and onScreen and options.box3d;
    for i = 1, #box3d do
        local face = box3d[i];
        for i2 = 1, #face do
            local line = face[i2];
            line.Visible = box3dEnabled;
            line.Color = getPriorityColor(
                parseColor(self, options.box3dColor[1]),
                interface.priorityBox3dColor and interface.priorityBox3dColor[1]
            );
            line.Transparency = options.box3dColor[2];
        end

        if box3dEnabled then
            local line1 = face[1];
            line1.From = corners.corners[i];
            line1.To = corners.corners[i == 4 and 1 or i+1];

            local line2 = face[2];
            line2.From = corners.corners[i == 4 and 1 or i+1];
            line2.To = corners.corners[i == 4 and 5 or i+5];

            local line3 = face[3];
            line3.From = corners.corners[i == 4 and 5 or i+5];
            line3.To = corners.corners[i == 4 and 8 or i+4];
        end
    end
end

-- cham object
local ChamObject = {};
ChamObject.__index = ChamObject;

function ChamObject.new(player, interface)
    local self = setmetatable({}, ChamObject);
    self.player = assert(player, "Missing argument #1 (Player expected)");
    self.interface = assert(interface, "Missing argument #2 (table expected)");
    self:Construct();
    return self;
end

function ChamObject:Construct()
    self.highlight = Instance.new("Highlight", container);
    self.updateConnection = runService.Heartbeat:Connect(function()
        self:Update();
    end);
end

function ChamObject:Destruct()
    self.updateConnection:Disconnect();
    self.highlight:Destroy();

    clear(self);
end

function ChamObject:Update()
    local highlight = self.highlight;
    local interface = self.interface;
    local character = interface.getCharacter(self.player);
    local options = interface.teamSettings[interface.isFriendly(self.player) and "friendly" or "enemy"];
    
    -- Check whitelist
    local isWhitelisted = false;
    for _, userId in ipairs(interface.whitelist) do
        if userId == self.player.UserId then
            isWhitelisted = true;
            break;
        end
    end
    
    -- Check priority
    local isPrioritized = interface.prioritizedPlayer and interface.prioritizedPlayer == self.player;
    
    local enabled = options.enabled and character and not isWhitelisted;

    highlight.Enabled = enabled and options.chams;
    if highlight.Enabled then
        highlight.Adornee = character;
        
        if isPrioritized and interface.priorityChamsFillColor then
            -- Use priority colors for prioritized players
            highlight.FillColor = interface.priorityChamsFillColor[1];
            highlight.FillTransparency = interface.priorityChamsFillColor[2];
            highlight.OutlineColor = interface.priorityChamsOutlineColor and interface.priorityChamsOutlineColor[1] or Color3.fromRGB(255, 215, 0);
            highlight.OutlineTransparency = interface.priorityChamsOutlineColor and interface.priorityChamsOutlineColor[2] or 0;
        else
            highlight.FillColor = parseColor(self, options.chamsFillColor[1]);
            highlight.FillTransparency = options.chamsFillColor[2];
            highlight.OutlineColor = parseColor(self, options.chamsOutlineColor[1], true);
            highlight.OutlineTransparency = options.chamsOutlineColor[2];
        end
        
        highlight.DepthMode = options.chamsVisibleOnly and "Occluded" or "AlwaysOnTop";
    end
end

-- interface
local EspInterface = {
    _hasLoaded = false,
    _objectCache = {},
    whitelist = {},
    prioritizedPlayer = nil,
    -- Priority colors
    priorityTextColor = { Color3.new(1, 1, 0), 1 },
    priorityBoxColor = { Color3.new(1, 1, 0), 1 },
    priorityBoxFillColor = { Color3.new(1, 1, 0, 0.3), 0.5 },
    priorityBox3dColor = { Color3.new(1, 1, 0), 1 },
    priorityTracerColor = { Color3.new(1, 1, 0), 1 },
    priorityArrowColor = { Color3.new(1, 1, 0), 1 },
    prioritySkeletonColor = { Color3.new(1, 1, 0), 1 },
    priorityHealthBarColor = { Color3.new(1, 1, 0), 1 },
    priorityChamsFillColor = { Color3.new(1, 1, 0), 0.5 },
    priorityChamsOutlineColor = { Color3.new(1, 215/255, 0), 0 },
    
    sharedSettings = {
        textSize = 13,
        textFont = "Plex",
        limitDistance = false,
        maxDistance = 150,
        useTeamColor = false
    },
    teamSettings = {
        enemy = {
            enabled = false,
            box = false,
            boxColor = { Color3.new(1,0,0), 1 },
            boxOutline = true,
            boxOutlineColor = { Color3.new(), 1 },
            boxFill = false,
            boxFillColor = { Color3.new(1,0,0), 0.5 },
            healthBar = false,
            healthyColor = Color3.new(0,1,0),
            dyingColor = Color3.new(1,0,0),
            healthBarOutline = true,
            healthBarOutlineColor = { Color3.new(), 0.5 },
            healthText = false,
            healthTextColor = { Color3.new(1,1,1), 1 },
            healthTextOutline = true,
            healthTextOutlineColor = Color3.new(),
            box3d = false,
            box3dColor = { Color3.new(1,0,0), 1 },
            name = false,
            nameColor = { Color3.new(1,1,1), 1 },
            nameOutline = true,
            nameOutlineColor = Color3.new(),
            weapon = false,
            weaponColor = { Color3.new(1,1,1), 1 },
            weaponOutline = true,
            weaponOutlineColor = Color3.new(),
            distance = false,
            distanceColor = { Color3.new(1,1,1), 1 },
            distanceOutline = true,
            distanceOutlineColor = Color3.new(),
            tracer = false,
            tracerOrigin = "Bottom",
            tracerColor = { Color3.new(1,0,0), 1 },
            tracerOutline = true,
            tracerOutlineColor = { Color3.new(), 1 },
            offScreenArrow = false,
            offScreenArrowColor = { Color3.new(1,1,1), 1 },
            offScreenArrowSize = 15,
            offScreenArrowRadius = 150,
            offScreenArrowOutline = true,
            offScreenArrowOutlineColor = { Color3.new(), 1 },
            skeleton = false,
            skeletonColor = { Color3.new(1,1,1), 1 },
            chams = false,
            chamsVisibleOnly = false,
            chamsFillColor = { Color3.new(0.2, 0.2, 0.2), 0.5 },
            chamsOutlineColor = { Color3.new(1,0,0), 0 },
        },
        friendly = {
            enabled = false,
            box = false,
            boxColor = { Color3.new(0,1,0), 1 },
            boxOutline = true,
            boxOutlineColor = { Color3.new(), 1 },
            boxFill = false,
            boxFillColor = { Color3.new(0,1,0), 0.5 },
            healthBar = false,
            healthyColor = Color3.new(0,1,0),
            dyingColor = Color3.new(1,0,0),
            healthBarOutline = true,
            healthBarOutlineColor = { Color3.new(), 0.5 },
            healthText = false,
            healthTextColor = { Color3.new(1,1,1), 1 },
            healthTextOutline = true,
            healthTextOutlineColor = Color3.new(),
            box3d = false,
            box3dColor = { Color3.new(0,1,0), 1 },
            name = false,
            nameColor = { Color3.new(1,1,1), 1 },
            nameOutline = true,
            nameOutlineColor = Color3.new(),
            weapon = false,
            weaponColor = { Color3.new(1,1,1), 1 },
            weaponOutline = true,
            weaponOutlineColor = Color3.new(),
            distance = false,
            distanceColor = { Color3.new(1,1,1), 1 },
            distanceOutline = true,
            distanceOutlineColor = Color3.new(),
            tracer = false,
            tracerOrigin = "Bottom",
            tracerColor = { Color3.new(0,1,0), 1 },
            tracerOutline = true,
            tracerOutlineColor = { Color3.new(), 1 },
            offScreenArrow = false,
            offScreenArrowColor = { Color3.new(1,1,1), 1 },
            offScreenArrowSize = 15,
            offScreenArrowRadius = 150,
            offScreenArrowOutline = true,
            offScreenArrowOutlineColor = { Color3.new(), 1 },
            skeleton = false,
            skeletonColor = { Color3.new(1,1,1), 1 },
            chams = false,
            chamsVisibleOnly = false,
            chamsFillColor = { Color3.new(0.2, 0.2, 0.2), 0.5 },
            chamsOutlineColor = { Color3.new(0,1,0), 0 }
        }
    }
};

function EspInterface.AddInstance(instance, options)
    local cache = EspInterface._objectCache;
    if cache[instance] then
        warn("Instance handler already exists.");
    else
        cache[instance] = { Instance.new(instance, options, EspInterface) };
    end
    return cache[instance][1];
end

function EspInterface.SetPrioritizedPlayer(player)
    EspInterface.prioritizedPlayer = player;
end

function EspInterface.ClearPriority()
    EspInterface.prioritizedPlayer = nil;
end

function EspInterface.AddToWhitelist(userId)
    for _, id in ipairs(EspInterface.whitelist) do
        if id == userId then
            return false;
        end
    end
    table.insert(EspInterface.whitelist, userId);
    return true;
end

function EspInterface.RemoveFromWhitelist(userId)
    for i, id in ipairs(EspInterface.whitelist) do
        if id == userId then
            table.remove(EspInterface.whitelist, i);
            return true;
        end
    end
    return false;
end

function EspInterface.Load()
    assert(not EspInterface._hasLoaded, "Esp has already been loaded.");

    local function createObject(player)
        EspInterface._objectCache[player] = {
            EspObject.new(player, EspInterface),
            ChamObject.new(player, EspInterface)
        };
    end

    local function removeObject(player)
        local object = EspInterface._objectCache[player];
        if object then
            for i = 1, #object do
                object[i]:Destruct();
            end
            EspInterface._objectCache[player] = nil;
        end
    end

    local plrs = players:GetPlayers();
    for i = 1, #plrs do
        if plrs[i] ~= localPlayer then
            createObject(plrs[i]);
        end
    end

    EspInterface.playerAdded = players.PlayerAdded:Connect(function(player)
        if player ~= localPlayer then
            createObject(player);
        end
    end);
    
    EspInterface.playerRemoving = players.PlayerRemoving:Connect(removeObject);
    EspInterface._hasLoaded = true;
end

function EspInterface.Unload()
    assert(EspInterface._hasLoaded, "Esp has not been loaded yet.");

    for index, object in next, EspInterface._objectCache do
        for i = 1, #object do
            object[i]:Destruct();
        end
        EspInterface._objectCache[index] = nil;
    end

    EspInterface.playerAdded:Disconnect();
    EspInterface.playerRemoving:Disconnect();
    EspInterface._hasLoaded = false;
    EspInterface.prioritizedPlayer = nil;
    EspInterface.whitelist = {};
end

-- game specific functions
function EspInterface.getWeapon(player)
    local character = player and EspInterface.getCharacter(player);
    if character then
        local tool = findFirstChildOfClass(character, "Tool");
        if tool then
            return tool.Name;
        end
    end
    return "None";
end

function EspInterface.isFriendly(player)
    return player.Team and localPlayer.Team and player.Team == localPlayer.Team;
end

function EspInterface.getTeamColor(player)
    return player.Team and player.Team.TeamColor and player.Team.TeamColor.Color;
end

function EspInterface.getCharacter(player)
    return player.Character;
end

function EspInterface.getHealth(player)
    local character = player and EspInterface.getCharacter(player);
    local humanoid = character and findFirstChildOfClass(character, "Humanoid");
    if humanoid then
        return humanoid.Health, humanoid.MaxHealth;
    end
    return 100, 100;
end

return EspInterface;
