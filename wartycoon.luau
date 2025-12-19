-- services
local runService = game:GetService("RunService");
local players = game:GetService("Players");
local workspace = game:GetService("Workspace");
local httpService = game:GetService("HttpService");

-- variables
local localPlayer = players.LocalPlayer;
local camera = workspace.CurrentCamera;
local viewportSize = camera.ViewportSize;
local container = Instance.new("Folder", gethui and gethui() or game:GetService("CoreGui"));

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

-- interface
local EspInterface = {
	_objectCache = {},
	_hasLoaded = false,
    _fontCache = {},
	sharedSettings = {
		textSize = 13,
		useCustomFonts = true,
        font = "Tahoma" -- Default font key
	},
	options = {
		enabled = false,
		limitDistance = false,
		maxDistance = 1000,
		teamCheck = false,
		teamColor = false,
		visibleCheck = false,
		highlightTarget = false,
	},
	box = {
		enabled = false,
		outline = false,
		fill = false,
		color = Color3.new(1, 1, 1),
		outlineColor = Color3.new(0, 0, 0),
		fillOpacity = 0.5,
	},
	healthBar = {
		enabled = false,
		outline = false,
		color = Color3.new(0, 1, 0),
		outlineColor = Color3.new(0, 0, 0),
	},
	healthText = {
		enabled = false,
		outline = false,
		color = Color3.new(1, 1, 1),
		outlineColor = Color3.new(0, 0, 0),
	},
	name = {
		enabled = false,
		outline = false,
		color = Color3.new(1, 1, 1),
		outlineColor = Color3.new(0, 0, 0),
	},
	distance = {
		enabled = false,
		outline = false,
		color = Color3.new(1, 1, 1),
		outlineColor = Color3.new(0, 0, 0),
	},
	weapon = {
		enabled = false,
		outline = false,
		color = Color3.new(1, 1, 1),
		outlineColor = Color3.new(0, 0, 0),
	},
	tracer = {
		enabled = false,
		outline = false,
		origin = "Bottom",
		color = Color3.new(1, 1, 1),
		outlineColor = Color3.new(0, 0, 0),
	},
	offscreenArrow = {
		enabled = false,
		outline = false,
		radius = 150,
		size = 15,
		color = Color3.new(1, 1, 1),
		outlineColor = Color3.new(0, 0, 0),
	}
};

-- [FONT REGISTRATION SYSTEM]
do
    local libraryDirectory = "sense_esp"
    
    if makefolder then
        pcall(function()
            if not isfolder(libraryDirectory) then makefolder(libraryDirectory) end
            if not isfolder(libraryDirectory.."/assets") then makefolder(libraryDirectory.."/assets") end
            if not isfolder(libraryDirectory.."/fonts") then makefolder(libraryDirectory.."/fonts") end
        end)
    end

    local function RegisterFont(Name, Weight, Style, Asset)
        local assetPath = libraryDirectory.."/assets/"..Asset.Id
        local fontPath = libraryDirectory.."/fonts/"..Name .. ".font"

        if not isfile(assetPath) then
            local success, content = pcall(function() return game:HttpGet(Asset.Font) end)
            if success then
                writefile(assetPath, content)
            end
        end

        local Data = {
            name = Name,
            faces = {
                {
                    Name = "Normal",
                    weight = Weight,
                    style = Style,
                    assetId = getcustomasset(assetPath),
                },
            },
        }

        writefile(fontPath, httpService:JSONEncode(Data))
        return getcustomasset(fontPath);
    end
    
    local Tahoma = RegisterFont("Tahoma", 400, "Normal", {
        Id = "Tahoma.ttf",
        Font = "https://github.com/KingVonOBlockJoyce/OctoHook-UI/raw/refs/heads/main/fs-tahoma-8px%20(3).ttf",
    })

    local Pixel = RegisterFont("Pixel", 400, "Normal", {
        Id = "Pixel.ttf",
        Font = "https://github.com/KingVonOBlockJoyce/vaderpaste.luau/raw/refs/heads/main/Pixel.ttf",
    })

    local Minecraftia = RegisterFont("Minecraftia", 400, "Normal", {
        Id = "Minecraftia.ttf",
        Font = "https://github.com/i77lhm/storage/raw/refs/heads/main/fonts/Minecraftia-Regular.ttf",
    }) 

    local Verdana = RegisterFont("Verdana", 400, "Normal", {
        Id = "Verdana.ttf",
        Font = "https://github.com/i77lhm/storage/raw/refs/heads/main/fonts/Verdana-Font.ttf",
    })

    EspInterface._fontCache["Tahoma"] = Font.new(Tahoma, Enum.FontWeight.Regular, Enum.FontStyle.Normal);
    EspInterface._fontCache["Pixel"] = Font.new(Pixel, Enum.FontWeight.Regular, Enum.FontStyle.Normal);
    EspInterface._fontCache["Minecraftia"] = Font.new(Minecraftia, Enum.FontWeight.Regular, Enum.FontStyle.Normal);
    EspInterface._fontCache["Verdana"] = Font.new(Verdana, Enum.FontWeight.Regular, Enum.FontStyle.Normal);
end

-- Esp Object
local EspObject = {};
EspObject.__index = EspObject;

function EspObject.new(player)
	local self = setmetatable({}, EspObject);

	self.player = player;
	self.components = {};

	self.components.box = Drawing.new("Square");
	self.components.boxOutline = Drawing.new("Square");
	self.components.boxFill = Drawing.new("Square");

	self.components.healthBar = Drawing.new("Line");
	self.components.healthBarOutline = Drawing.new("Line");

	self.components.healthText = Drawing.new("Text");
	self.components.name = Drawing.new("Text");
	self.components.distance = Drawing.new("Text");
	self.components.weapon = Drawing.new("Text");

	self.components.tracer = Drawing.new("Line");
	self.components.tracerOutline = Drawing.new("Line");

	self.components.offscreenArrow = Drawing.new("Triangle");
	self.components.offscreenArrowOutline = Drawing.new("Triangle");

	return self;
end

function EspObject:Update()
	local player = self.player;
	local character = EspInterface.getCharacter(player);
	local settings = EspInterface.sharedSettings;
    local currentFont = EspInterface._fontCache[settings.font] or Font.fromEnum(Enum.Font.Arial)

	if not EspInterface.options.enabled or not character then
		return self:SetVisible(false);
	end

	local rootPart = findFirstChild(character, "HumanoidRootPart");
	local humanoid = findFirstChildOfClass(character, "Humanoid");

	if not rootPart or not humanoid then
		return self:SetVisible(false);
	end

	local worldPosition = getPivot(character).Position;
	local screenPosition, onScreen = wtvp(camera, worldPosition);
	local distance = (camera.CFrame.Position - worldPosition).Magnitude;

	if EspInterface.options.limitDistance and distance > EspInterface.options.maxDistance then
		return self:SetVisible(false);
	end

	if EspInterface.options.teamCheck and EspInterface.isFriendly(player) then
		return self:SetVisible(false);
	end

	if not onScreen then
		self:SetVisible(false);
		self:UpdateOffscreenArrow(worldPosition);
		return;
	end

	local size, position = EspInterface.getBoundingBox(character);
	if not size or not position then
		return self:SetVisible(false);
	end

	-- visibility checks
	if EspInterface.options.visibleCheck and not EspInterface.isVisible(character) then
		return self:SetVisible(false);
	end

	-- update components
	self:UpdateBox(size, position, player);
	self:UpdateHealthBar(size, position, humanoid);
	self:UpdateText(size, position, player, humanoid, distance, currentFont);
	self:UpdateTracer(position, player);
    
    -- Hide offscreen arrow when on screen
    self.components.offscreenArrow.Visible = false;
    self.components.offscreenArrowOutline.Visible = false;
end

function EspObject:UpdateBox(size, position, player)
	local boxSettings = EspInterface.box;
	local box = self.components.box;
	local boxOutline = self.components.boxOutline;
	local boxFill = self.components.boxFill;

	box.Visible = boxSettings.enabled;
	boxOutline.Visible = boxSettings.enabled and boxSettings.outline;
	boxFill.Visible = boxSettings.enabled and boxSettings.fill;

	if not boxSettings.enabled then return end

	local color = EspInterface.options.teamColor and EspInterface.getTeamColor(player) or boxSettings.color;

	box.Size = size;
	box.Position = position;
	box.Color = color;

	boxOutline.Size = size;
	boxOutline.Position = position;
	boxOutline.Color = boxSettings.outlineColor;
	boxOutline.Thickness = 3;

	boxFill.Size = size;
	boxFill.Position = position;
	boxFill.Color = color;
	boxFill.Transparency = boxSettings.fillOpacity;
	boxFill.Filled = true;
end

function EspObject:UpdateHealthBar(size, position, humanoid)
	local healthBarSettings = EspInterface.healthBar;
	local healthBar = self.components.healthBar;
	local healthBarOutline = self.components.healthBarOutline;

	healthBar.Visible = healthBarSettings.enabled;
	healthBarOutline.Visible = healthBarSettings.enabled and healthBarSettings.outline;

	if not healthBarSettings.enabled then return end

	local healthFraction = humanoid.Health / humanoid.MaxHealth;
	local barHeight = size.Y * healthFraction;
	local barPosition = position + Vector2.new(-5, size.Y);

	healthBar.From = barPosition;
	healthBar.To = barPosition - Vector2.new(0, barHeight);
	healthBar.Color = healthBarSettings.color;

	healthBarOutline.From = barPosition + Vector2.new(0, 1);
	healthBarOutline.To = barPosition - Vector2.new(0, size.Y + 1);
	healthBarOutline.Color = healthBarSettings.outlineColor;
	healthBarOutline.Thickness = 3;
end

function EspObject:UpdateText(size, position, player, humanoid, distance, currentFont)
	local healthTextSettings = EspInterface.healthText;
	local nameSettings = EspInterface.name;
	local distanceSettings = EspInterface.distance;
	local weaponSettings = EspInterface.weapon;

	local healthText = self.components.healthText;
	local name = self.components.name;
	local dist = self.components.distance;
	local weapon = self.components.weapon;

    local function applyTextSettings(drawing, settings_comp, text, pos)
        drawing.Visible = settings_comp.enabled;
        if not settings_comp.enabled then return end
        
        drawing.Text = text;
        drawing.Position = pos;
        drawing.Color = EspInterface.options.teamColor and EspInterface.getTeamColor(player) or settings_comp.color;
        drawing.Outline = settings_comp.outline;
        drawing.OutlineColor = settings_comp.outlineColor;
        drawing.Size = EspInterface.sharedSettings.textSize;
        drawing.Font = currentFont;
        drawing.Center = true;
    end

	applyTextSettings(name, nameSettings, player.Name, position + Vector2.new(size.X / 2, -15));
	applyTextSettings(dist, distanceSettings, round(distance) .. "m", position + Vector2.new(size.X / 2, size.Y + 2));
	applyTextSettings(healthText, healthTextSettings, round(humanoid.Health), position + Vector2.new(-20, size.Y - (size.Y * (humanoid.Health / humanoid.MaxHealth))));
	applyTextSettings(weapon, weaponSettings, EspInterface.getWeapon(player), position + Vector2.new(size.X / 2, size.Y + (distanceSettings.enabled and 15 or 2)));
end

function EspObject:UpdateTracer(position, player)
	local tracerSettings = EspInterface.tracer;
	local tracer = self.components.tracer;
	local tracerOutline = self.components.tracerOutline;

	tracer.Visible = tracerSettings.enabled;
	tracerOutline.Visible = tracerSettings.enabled and tracerSettings.outline;

	if not tracerSettings.enabled then return end

	local origin = tracerSettings.origin == "Top" and Vector2.new(viewportSize.X / 2, 0) 
		or tracerSettings.origin == "Center" and viewportSize / 2 
		or Vector2.new(viewportSize.X / 2, viewportSize.Y);

	local color = EspInterface.options.teamColor and EspInterface.getTeamColor(player) or tracerSettings.color;

	tracer.From = origin;
	tracer.To = position + Vector2.new(tracer.To.X, tracer.To.Y); -- Needs Logic
	tracer.Color = color;
end

function EspObject:UpdateOffscreenArrow(worldPosition)
	local arrowSettings = EspInterface.offscreenArrow;
	local arrow = self.components.offscreenArrow;
	local arrowOutline = self.components.offscreenArrowOutline;

	arrow.Visible = arrowSettings.enabled;
	arrowOutline.Visible = arrowSettings.enabled and arrowSettings.outline;

	if not arrowSettings.enabled then return end

	local relative = pointToObjectSpace(camera.CFrame, worldPosition);
	local angle = math.atan2(-relative.Z, relative.X);
	
	local direction = Vector2.new(math.cos(angle), math.sin(angle));
	local position = (viewportSize / 2) + (direction * arrowSettings.radius);
	
	local rot = angle + math.pi / 2;
	local a = position + Vector2.new(math.cos(rot), math.sin(rot)) * arrowSettings.size;
	local b = position + Vector2.new(math.cos(rot + math.pi*0.8), math.sin(rot + math.pi*0.8)) * arrowSettings.size;
	local c = position + Vector2.new(math.cos(rot - math.pi*0.8), math.sin(rot - math.pi*0.8)) * arrowSettings.size;

	arrow.PointA = a;
	arrow.PointB = b;
	arrow.PointC = c;
	arrow.Color = arrowSettings.color;
	arrow.Filled = true;
end

function EspObject:SetVisible(bool)
	for _, component in next, self.components do
		component.Visible = bool;
	end
end

function EspObject:Destruct()
	for _, component in next, self.components do
		component:Remove();
	end
	clear(self.components);
end

-- EspInterface Logic
function EspInterface.getBoundingBox(character)
	local rootPart = findFirstChild(character, "HumanoidRootPart");
	if not rootPart then return end

	local cf = rootPart.CFrame;
	local size = Vector3.new(4, 6, 0); -- Standard character box size
	
	local corners = {
		cf * CFrame.new(-size.X/2, size.Y/2, 0),
		cf * CFrame.new(size.X/2, size.Y/2, 0),
		cf * CFrame.new(-size.X/2, -size.Y/2, 0),
		cf * CFrame.new(size.X/2, -size.Y/2, 0)
	};

	local minX, minY = math.huge, math.huge;
	local maxX, maxY = -math.huge, -math.huge;

	for _, corner in next, corners do
		local screenPos, onScreen = wtvp(camera, corner.Position);
		minX = math.min(minX, screenPos.X);
		minY = math.min(minY, screenPos.Y);
		maxX = math.max(maxX, screenPos.X);
		maxY = math.max(maxY, screenPos.Y);
	end

	return Vector2.new(maxX - minX, maxY - minY), Vector2.new(minX, minY);
end

function EspInterface.Load()
	if EspInterface._hasLoaded then return end

	local function createObject(player)
		if player == localPlayer then return end
		EspInterface._objectCache[player] = EspObject.new(player);
	end

	local function removeObject(player)
		if EspInterface._objectCache[player] then
			EspInterface._objectCache[player]:Destruct();
			EspInterface._objectCache[player] = nil;
		end
	end

	for _, player in next, players:GetPlayers() do
		createObject(player);
	end

	EspInterface.playerAdded = players.PlayerAdded:Connect(createObject);
	EspInterface.playerRemoving = players.PlayerRemoving:Connect(removeObject);
	
	EspInterface.renderConnection = runService.RenderStepped:Connect(function()
		viewportSize = camera.ViewportSize;
		for _, object in next, EspInterface._objectCache do
			object:Update();
		end
	end)

	EspInterface._hasLoaded = true;
end

function EspInterface.Unload()
	if not EspInterface._hasLoaded then return end
	
	EspInterface.playerAdded:Disconnect();
	EspInterface.playerRemoving:Disconnect();
	EspInterface.renderConnection:Disconnect();

	for _, object in next, EspInterface._objectCache do
		object:Destruct();
	end
	clear(EspInterface._objectCache);
	
	EspInterface._hasLoaded = false;
end

-- Game specific functions
function EspInterface.getWeapon(player)
	local char = EspInterface.getCharacter(player);
	if not char then return "None" end
	local tool = findFirstChildOfClass(char, "Tool");
	return tool and tool.Name or "None";
end

function EspInterface.isFriendly(player)
	return player.Team and player.Team == localPlayer.Team;
end

function EspInterface.getTeamColor(player)
	return player.Team and player.Team.TeamColor and player.Team.TeamColor.Color;
end

function EspInterface.getCharacter(player)
	return player.Character;
end

function EspInterface.isVisible(character)
	local root = findFirstChild(character, "HumanoidRootPart");
	if not root then return false end
	local parts = camera:GetPartsObscuringTarget({camera.CFrame.Position, root.Position}, {character, localPlayer.Character});
	return #parts == 0;
end

return EspInterface;
