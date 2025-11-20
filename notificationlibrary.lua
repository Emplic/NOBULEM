local NotificationSystem = (function()
    local Maid = {}
    Maid.__index = Maid

    function Maid.new()
        return setmetatable({
            _tasks = {}
        }, Maid)
    end

    function Maid:AddTask(task)
        table.insert(self._tasks, task)
        return task
    end

    function Maid:Clean()
        for _, task in ipairs(self._tasks) do
            if typeof(task) == "RBXScriptConnection" then
                task:Disconnect()
            elseif typeof(task) == "Instance" then
                task:Destroy()
            elseif type(task) == "function" then
                task()
            end
        end
        self._tasks = {}
    end

    local Signal = {}
    Signal.__index = Signal

    function Signal.new()
        return setmetatable({
            _connections = {}
        }, Signal)
    end

    function Signal:Connect(callback)
        local connection = {
            Connected = true,
            _callback = callback
        }
        
        function connection:Disconnect()
            self.Connected = false
        end
        
        table.insert(self._connections, connection)
        return connection
    end

    function Signal:Fire(...)
        for _, connection in ipairs(self._connections) do
            if connection.Connected then
                connection._callback(...)
            end
        end
    end

    local Services = {}
    
    function Services:Get(...)
        local services = {}
        for _, serviceName in ipairs({...}) do
            table.insert(services, game:GetService(serviceName))
        end
        return unpack(services)
    end

    local MarketplaceService, Players = Services:Get("MarketplaceService", "Players")
    local player = Players.LocalPlayer
    local gamesinfos, gameInfo = pcall(function() return MarketplaceService:GetProductInfo(game.PlaceId) end)
    local placename = gamesinfos and gameInfo.Name or "Unknown Game"
    local mrexploit = identifyexecutor and identifyexecutor() or "Unknown"
    local TweenService, CoreGui, UserInputService, GuiService = Services:Get('TweenService', 'CoreGui', 'UserInputService', 'GuiService')
    
    local ProtectGui = protectgui or (syn and syn.protect_gui) or (function() end)
    local GetHUI = gethui or (function() return CoreGui end)
    
    local NotificationSystem = {}
    NotificationSystem.__index = NotificationSystem
    
    local NOTIFICATION_PADDING = 10
    local NOTIFICATION_GAP = 5
    local NOTIFICATION_DURATION = 5
    local NOTIFICATION_WIDTH = 300
    local NOTIFICATION_MIN_HEIGHT = 80
    local NOTIFICATION_CORNER_RADIUS = 4
    
    local TWEEN_INFO = TweenInfo.new(0.3, Enum.EasingStyle.Quint)
    local PROGRESS_TWEEN_INFO = TweenInfo.new(NOTIFICATION_DURATION, Enum.EasingStyle.Linear)
    
    local function generateRandomString()
        local chars = {}
        for i = 1, math.random(8, 16) do
            chars[i] = string.char(math.random(97, 122))
        end
        return table.concat(chars)
    end
    
    local THEME = {
        Background = Color3.fromRGB(30, 30, 30),
        Text = Color3.fromRGB(255, 255, 255),
        SubText = Color3.fromRGB(180, 180, 180),
        Types = {
            Info = { Color = Color3.fromRGB(78, 131, 255) },
            Success = { Color = Color3.fromRGB(85, 170, 127) },
            Warning = { Color = Color3.fromRGB(245, 179, 66) },
            Error = { Color = Color3.fromRGB(235, 87, 87) }
        }
    }
    
    local ActiveNotifications = {}
    
    local Container = Instance.new("ScreenGui")
    Container.Name = generateRandomString()
    Container.ResetOnSpawn = false
    Container.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    Container.Enabled = true
    ProtectGui(Container)
    Container.Parent = GetHUI()
    
    local Notification = {}
    Notification.__index = Notification
    
    local function createIconText(notifType)
        if notifType == "Info" then return "ℹ"
        elseif notifType == "Success" then return "✓"
        elseif notifType == "Warning" then return "⚠"
        elseif notifType == "Error" then return "X"
        end
        return ""
    end
    
    function Notification.new(options)
        local self = setmetatable({}, Notification)
        self.Type = options.Type or "Info"
        self.Title = options.Title or "Notification"
        self.Text = options.Text or ""
        self.Duration = options.Duration or NOTIFICATION_DURATION
        self.Callback = options.Callback
        self.Destroying = Signal.new()
        self._maid = Maid.new()
        self:_init()
        return self
    end
    
    function Notification:GetScreenSize()
        local viewport = workspace.CurrentCamera.ViewportSize
        local insets = GuiService:GetGuiInset()
        return viewport.X, viewport.Y - insets.Y
    end
    
    function Notification:GetScaledSize()
        local screenWidth, screenHeight = self:GetScreenSize()
        local scale = math.min(screenWidth / 1920, 1)
        local width = math.min(NOTIFICATION_WIDTH * scale, screenWidth * 0.9)
        local height = self.calculatedHeight or (NOTIFICATION_MIN_HEIGHT * scale)
        return width, height
    end
    
    function Notification:_init()
        local typeInfo = THEME.Types[self.Type]
        local screenWidth, screenHeight = self:GetScreenSize()
        local scale = math.min(screenWidth / 1920, 1)
        local width = math.min(NOTIFICATION_WIDTH * scale, screenWidth * 0.9)
        
        local tempTextLabel = Instance.new("TextLabel")
        tempTextLabel.Size = UDim2.new(0, width - 80, 0, 1000)
        tempTextLabel.Text = self.Text
        tempTextLabel.Font = Enum.Font.Gotham
        tempTextLabel.TextSize = 14 * scale
        tempTextLabel.TextWrapped = true
        tempTextLabel.TextYAlignment = Enum.TextYAlignment.Top
        tempTextLabel.Parent = Container
        
        local textBounds = tempTextLabel.TextBounds.Y
        tempTextLabel:Destroy()
        
        local requiredHeight = math.max(NOTIFICATION_MIN_HEIGHT * scale, 52 * scale + textBounds + 16 * scale)
        self.calculatedHeight = requiredHeight
        
        local height = requiredHeight
        
        self.Frame = Instance.new("Frame")
        self.Frame.Name = generateRandomString()
        self.Frame.Size = UDim2.new(0, width, 0, height)
        self.Frame.Position = UDim2.new(0, NOTIFICATION_PADDING, 1, NOTIFICATION_PADDING)
        self.Frame.BackgroundColor3 = THEME.Background
        self.Frame.BorderSizePixel = 0
        self.Frame.AnchorPoint = Vector2.new(0, 1)
        self.Frame.Parent = Container
        
        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, NOTIFICATION_CORNER_RADIUS)
        corner.Parent = self.Frame
        
        self.Icon = Instance.new("TextLabel")
        self.Icon.Name = generateRandomString()
        self.Icon.Size = UDim2.new(0, 24 * scale, 0, 24 * scale)
        self.Icon.Position = UDim2.new(0, 16 * scale, 0, 16 * scale)
        self.Icon.BackgroundTransparency = 1
        self.Icon.Text = createIconText(self.Type)
        self.Icon.Font = Enum.Font.GothamBold
        self.Icon.TextSize = 20 * scale
        self.Icon.TextColor3 = typeInfo.Color
        self.Icon.Parent = self.Frame
        
        local iconSize = self.Icon.Size.X.Offset
        
        self.TitleLabel = Instance.new("TextLabel")
        self.TitleLabel.Name = generateRandomString()
        self.TitleLabel.Size = UDim2.new(1, -iconSize - 50, 0, 20 * scale)
        self.TitleLabel.Position = UDim2.new(0, iconSize + 30, 0, 16 * scale)
        self.TitleLabel.BackgroundTransparency = 1
        self.TitleLabel.Text = self.Title
        self.TitleLabel.Font = Enum.Font.GothamBold
        self.TitleLabel.TextSize = 14 * scale
        self.TitleLabel.TextColor3 = THEME.Text
        self.TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
        self.TitleLabel.Parent = self.Frame
        
        self.TextLabel = Instance.new("TextLabel")
        self.TextLabel.Name = generateRandomString()
        self.TextLabel.Size = UDim2.new(1, -iconSize - 50, 0, height - 52 * scale)
        self.TextLabel.Position = UDim2.new(0, iconSize + 30, 0, 36 * scale)
        self.TextLabel.BackgroundTransparency = 1
        self.TextLabel.Text = self.Text
        self.TextLabel.Font = Enum.Font.Gotham
        self.TextLabel.TextSize = 14 * scale
        self.TextLabel.TextColor3 = THEME.SubText
        self.TextLabel.TextXAlignment = Enum.TextXAlignment.Left
        self.TextLabel.TextYAlignment = Enum.TextYAlignment.Top
        self.TextLabel.TextWrapped = true
        self.TextLabel.Parent = self.Frame
        
        self.CloseButton = Instance.new("TextButton")
        self.CloseButton.Name = generateRandomString()
        self.CloseButton.Size = UDim2.new(0, 16 * scale, 0, 16 * scale)
        self.CloseButton.Position = UDim2.new(1, -24 * scale, 0, 16 * scale)
        self.CloseButton.BackgroundTransparency = 1
        self.CloseButton.Text = "X"
        self.CloseButton.Font = Enum.Font.Gotham
        self.CloseButton.TextSize = 14 * scale
        self.CloseButton.TextColor3 = THEME.SubText
        self.CloseButton.Parent = self.Frame
        
        self.ProgressContainer = Instance.new("Frame")
        self.ProgressContainer.Name = generateRandomString()
        self.ProgressContainer.Size = UDim2.new(1, 0, 0, 4)
        self.ProgressContainer.Position = UDim2.new(0, 0, 1, -4)
        self.ProgressContainer.BackgroundTransparency = 0.9
        self.ProgressContainer.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
        self.ProgressContainer.BorderSizePixel = 0
        self.ProgressContainer.Parent = self.Frame
        
        self.ProgressBar = Instance.new("Frame")
        self.ProgressBar.Name = generateRandomString()
        self.ProgressBar.Size = UDim2.new(1, 0, 1, 0)
        self.ProgressBar.BackgroundColor3 = typeInfo.Color
        self.ProgressBar.BorderSizePixel = 0
        self.ProgressBar.Parent = self.ProgressContainer
        
        self._maid:AddTask(self.CloseButton.MouseButton1Click:Connect(function()
            self:Destroy()
        end))
        
        table.insert(ActiveNotifications, self)
        self:UpdatePositions()
        
        local targetPosition = UDim2.new(0, NOTIFICATION_PADDING, 1, -NOTIFICATION_PADDING)
        TweenService:Create(self.Frame, TWEEN_INFO, {Position = targetPosition, AnchorPoint = Vector2.new(0, 1)}):Play()
        
        local progressTween = TweenService:Create(self.ProgressBar, PROGRESS_TWEEN_INFO, {Size = UDim2.new(0, 0, 1, 0)})
        progressTween:Play()
        
        self._maid:AddTask(progressTween.Completed:Connect(function()
            if self._destroyed then return end
            self:Destroy()
        end))
        
        if self.Callback then
            self.ClickableArea = Instance.new("TextButton")
            self.ClickableArea.Name = generateRandomString()
            self.ClickableArea.Size = UDim2.new(1, 0, 1, -4)
            self.ClickableArea.Position = UDim2.new(0, 0, 0, 0)
            self.ClickableArea.BackgroundTransparency = 1
            self.ClickableArea.Text = ""
            self.ClickableArea.Parent = self.Frame
            
            self._maid:AddTask(self.ClickableArea.MouseButton1Click:Connect(function()
                self.Callback()
                self:Destroy()
            end))
        end
        
        return self
    end
    
    function Notification:UpdatePositions()
        local totalHeight = 0
        for i = #ActiveNotifications, 1, -1 do
            local notif = ActiveNotifications[i]
            if notif._destroyed then continue end
            local width, height = notif:GetScaledSize()
            local newY = -NOTIFICATION_PADDING - totalHeight
            local targetPosition = UDim2.new(0, NOTIFICATION_PADDING, 1, newY)
            if notif == self then
                notif.originalPosition = targetPosition
            else
                TweenService:Create(notif.Frame, TWEEN_INFO, {
                    Position = targetPosition,
                    AnchorPoint = Vector2.new(0, 1)
                }):Play()
            end
            totalHeight = totalHeight + height + NOTIFICATION_GAP
        end
    end
    
    function Notification:Destroy()
        if self._destroyed then return end
        self._destroyed = true
        self.Destroying:Fire()
        local targetPosition = UDim2.new(0.5, 0, 1, NOTIFICATION_PADDING)
        local tween = TweenService:Create(self.Frame, TWEEN_INFO, {
            Position = targetPosition,
            Transparency = 1
        })
        tween:Play()
        self._maid:AddTask(tween.Completed:Connect(function()
            local index = table.find(ActiveNotifications, self)
            if index then
                table.remove(ActiveNotifications, index)
            end
            if #ActiveNotifications > 0 then
                ActiveNotifications[1]:UpdatePositions()
            end
            self.Frame:Destroy()
            self._maid:Clean()
        end))
    end
    
    function NotificationSystem.new()
        local self = setmetatable({}, NotificationSystem)
        self._maid = Maid.new()
        return self
    end
    
    function NotificationSystem:Create(options)
        return Notification.new(options)
    end
    
    function NotificationSystem:Notify(title, message, notificationType, duration, callback)
        return self:Create({
            Title = title,
            Text = message,
            Type = notificationType or "Info",
            Duration = duration,
            Callback = callback
        })
    end
    
    function NotificationSystem:Info(title, message, duration, callback)
        return self:Notify(title, message, "Info", duration, callback)
    end
    
    function NotificationSystem:Success(title, message, duration, callback)
        return self:Notify(title, message, "Success", duration, callback)
    end
    
    function NotificationSystem:Warning(title, message, duration, callback)
        return self:Notify(title, message, "Warning", duration, callback)
    end
    
    function NotificationSystem:Error(title, message, duration, callback)
        return self:Notify(title, message, "Error", duration, callback)
    end
    
    function NotificationSystem:ClearAll()
        for _, notification in ipairs(ActiveNotifications) do
            notification:Destroy()
        end
    end
    
    function NotificationSystem:Destroy()
        self:ClearAll()
        self._maid:Clean()
    end
    
    return NotificationSystem.new()
end)()

return NotificationSystem
