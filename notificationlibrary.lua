return (function()
    -- // Services \\ --
    local TweenService = game:GetService("TweenService")
    local CoreGui = game:GetService("CoreGui")
    local UserInputService = game:GetService("UserInputService")
    local GuiService = game:GetService("GuiService")
    local TextService = game:GetService("TextService")
    local Players = game:GetService("Players")
    local RunService = game:GetService("RunService")

    -- // Internal Utilities (Replacements for external libs) \\ --
    
    -- Simple Signal Class
    local Signal = {}
    Signal.__index = Signal
    function Signal.new() return setmetatable({_bindable = Instance.new("BindableEvent")}, Signal) end
    function Signal:Connect(handler) return self._bindable.Event:Connect(handler) end
    function Signal:Fire(...) self._bindable:Fire(...) end
    function Signal:Destroy() if self._bindable then self._bindable:Destroy() end end

    -- Simple Maid Class
    local Maid = {}
    Maid.__index = Maid
    function Maid.new() return setmetatable({_tasks = {}}, Maid) end
    function Maid:AddTask(task) table.insert(self._tasks, task) end
    function Maid:Clean()
        for _, task in ipairs(self._tasks) do
            if typeof(task) == "function" then task()
            elseif typeof(task) == "RBXScriptConnection" then task:Disconnect()
            elseif typeof(task) == "Instance" then task:Destroy()
            elseif task.Destroy then task:Destroy() end
        end
        self._tasks = {}
    end

    -- // Main Logic \\ --

    local ProtectGui = protectgui or (syn and syn.protect_gui) or (function() end)
    local GetHUI = gethui or (function() return CoreGui end)

    local NotificationSystem = {}
    NotificationSystem.__index = NotificationSystem

    -- Configuration
    local NOTIFICATION_PADDING = 10
    local NOTIFICATION_GAP = 5
    local NOTIFICATION_DURATION = 5
    local NOTIFICATION_WIDTH = 300
    local MIN_HEIGHT = 80 -- Minimum height, will expand if text is long
    local NOTIFICATION_CORNER_RADIUS = 6
    
    local TWEEN_INFO = TweenInfo.new(0.4, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
    local PROGRESS_TWEEN_INFO = TweenInfo.new(NOTIFICATION_DURATION, Enum.EasingStyle.Linear)

    local function generateRandomString()
        local chars = {}
        for i = 1, math.random(8, 16) do
            chars[i] = string.char(math.random(97, 122))
        end
        return table.concat(chars)
    end

    local THEME = {
        Background = Color3.fromRGB(25, 25, 25),
        Text = Color3.fromRGB(255, 255, 255),
        SubText = Color3.fromRGB(200, 200, 200),
        Types = {
            Info = { Color = Color3.fromRGB(78, 131, 255) },
            Success = { Color = Color3.fromRGB(85, 170, 127) },
            Warning = { Color = Color3.fromRGB(245, 179, 66) },
            Error = { Color = Color3.fromRGB(235, 87, 87) }
        }
    }

    local ActiveNotifications = {}

    -- Container Setup
    local Container = Instance.new("ScreenGui")
    Container.Name = generateRandomString()
    Container.ResetOnSpawn = false
    Container.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    Container.Enabled = true
    
    -- Safely parent to secure GUI if possible
    pcall(function()
        ProtectGui(Container)
        Container.Parent = GetHUI()
    end)
    if not Container.Parent then Container.Parent = CoreGui end

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
        -- Ensure minimum scale for readability on small screens
        scale = math.max(scale, 0.8) 
        
        local width = math.min(NOTIFICATION_WIDTH * scale, screenWidth * 0.9)
        
        -- Dynamic Height Calculation
        local typeInfo = THEME.Types[self.Type]
        local iconSize = 24
        local titleHeight = 20
        local textPadding = 16 -- spacing between title and text
        local verticalPadding = 32 -- top/bottom padding combined
        
        -- Calculate Text Height
        local textAreaWidth = width - (iconSize + 50) -- Available width for text
        local textSize = 14 * scale
        
        local textBounds = TextService:GetTextSize(
            self.Text,
            textSize,
            Enum.Font.Gotham,
            Vector2.new(textAreaWidth, 10000) -- Huge Y limit to measure height
        )
        
        -- Calculate total required height
        local requiredHeight = verticalPadding + titleHeight + textBounds.Y + 10
        local height = math.max(requiredHeight, MIN_HEIGHT * scale)
        
        return width, height, textBounds.Y
    end

    function Notification:_init()
        local typeInfo = THEME.Types[self.Type]
        local width, height, textHeight = self:GetScaledSize()
        
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
        
        -- Stroke for visibility
        local stroke = Instance.new("UIStroke")
        stroke.Color = Color3.fromRGB(60,60,60)
        stroke.Thickness = 1
        stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
        stroke.Parent = self.Frame

        local scaleRatio = height / MIN_HEIGHT
        if scaleRatio > 1.5 then scaleRatio = 1.2 end -- Cap icon scaling

        self.Icon = Instance.new("TextLabel")
        self.Icon.Name = "Icon"
        self.Icon.Size = UDim2.new(0, 24, 0, 24)
        self.Icon.Position = UDim2.new(0, 12, 0, 12)
        self.Icon.BackgroundTransparency = 1
        self.Icon.Text = createIconText(self.Type)
        self.Icon.Font = Enum.Font.GothamBold
        self.Icon.TextSize = 20
        self.Icon.TextColor3 = typeInfo.Color
        self.Icon.Parent = self.Frame
        
        local iconWidth = self.Icon.Size.X.Offset
        
        self.TitleLabel = Instance.new("TextLabel")
        self.TitleLabel.Name = "Title"
        self.TitleLabel.Size = UDim2.new(1, -iconWidth - 45, 0, 20)
        self.TitleLabel.Position = UDim2.new(0, iconWidth + 25, 0, 14)
        self.TitleLabel.BackgroundTransparency = 1
        self.TitleLabel.Text = self.Title
        self.TitleLabel.Font = Enum.Font.GothamBold
        self.TitleLabel.TextSize = 15
        self.TitleLabel.TextColor3 = THEME.Text
        self.TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
        self.TitleLabel.Parent = self.Frame
        
        self.TextLabel = Instance.new("TextLabel")
        self.TextLabel.Name = "Content"
        self.TextLabel.Size = UDim2.new(1, -iconWidth - 45, 0, textHeight)
        self.TextLabel.Position = UDim2.new(0, iconWidth + 25, 0, 38) -- Below Title
        self.TextLabel.BackgroundTransparency = 1
        self.TextLabel.Text = self.Text
        self.TextLabel.Font = Enum.Font.Gotham
        self.TextLabel.TextSize = 14
        self.TextLabel.TextColor3 = THEME.SubText
        self.TextLabel.TextXAlignment = Enum.TextXAlignment.Left
        self.TextLabel.TextYAlignment = Enum.TextYAlignment.Top
        self.TextLabel.TextWrapped = true
        self.TextLabel.Parent = self.Frame
        
        self.CloseButton = Instance.new("TextButton")
        self.CloseButton.Name = "Close"
        self.CloseButton.Size = UDim2.new(0, 20, 0, 20)
        self.CloseButton.Position = UDim2.new(1, -25, 0, 12)
        self.CloseButton.BackgroundTransparency = 1
        self.CloseButton.Text = "X"
        self.CloseButton.Font = Enum.Font.Gotham
        self.CloseButton.TextSize = 14
        self.CloseButton.TextColor3 = THEME.SubText
        self.CloseButton.Parent = self.Frame
        
        self.ProgressContainer = Instance.new("Frame")
        self.ProgressContainer.Name = "ProgressContainer"
        self.ProgressContainer.Size = UDim2.new(1, 0, 0, 3)
        self.ProgressContainer.Position = UDim2.new(0, 0, 1, -3)
        self.ProgressContainer.BackgroundTransparency = 1
        self.ProgressContainer.BorderSizePixel = 0
        self.ProgressContainer.Parent = self.Frame
        
        local progressCorner = Instance.new("UICorner")
        progressCorner.CornerRadius = UDim.new(0, 4)
        progressCorner.Parent = self.ProgressContainer

        self.ProgressBar = Instance.new("Frame")
        self.ProgressBar.Name = "Bar"
        self.ProgressBar.Size = UDim2.new(1, 0, 1, 0)
        self.ProgressBar.BackgroundColor3 = typeInfo.Color
        self.ProgressBar.BorderSizePixel = 0
        self.ProgressBar.Parent = self.ProgressContainer
        
        local barCorner = Instance.new("UICorner")
        barCorner.CornerRadius = UDim.new(0, 4)
        barCorner.Parent = self.ProgressBar
        
        self._maid:AddTask(self.CloseButton.MouseButton1Click:Connect(function()
            self:Destroy()
        end))
        
        -- Hover Effect on Close Button
        self._maid:AddTask(self.CloseButton.MouseEnter:Connect(function()
            TweenService:Create(self.CloseButton, TweenInfo.new(0.2), {TextColor3 = Color3.fromRGB(255,255,255)}):Play()
        end))
        self._maid:AddTask(self.CloseButton.MouseLeave:Connect(function()
            TweenService:Create(self.CloseButton, TweenInfo.new(0.2), {TextColor3 = THEME.SubText}):Play()
        end))
        
        table.insert(ActiveNotifications, self)
        
        self:UpdatePositions()
        
        -- Intro Animation
        local targetPosition = UDim2.new(0, NOTIFICATION_PADDING, 1, -NOTIFICATION_PADDING)
        -- Start slightly to the left and invisible
        self.Frame.Position = UDim2.new(0, -width, 1, -NOTIFICATION_PADDING)
        self.Frame.BackgroundTransparency = 1
        self.TitleLabel.TextTransparency = 1
        self.TextLabel.TextTransparency = 1
        self.Icon.TextTransparency = 1
        
        -- Animate In
        TweenService:Create(self.Frame, TWEEN_INFO, {
            Position = targetPosition, 
            BackgroundTransparency = 0
        }):Play()
        TweenService:Create(self.TitleLabel, TWEEN_INFO, {TextTransparency = 0}):Play()
        TweenService:Create(self.TextLabel, TWEEN_INFO, {TextTransparency = 0}):Play()
        TweenService:Create(self.Icon, TWEEN_INFO, {TextTransparency = 0}):Play()
        
        -- Progress Bar Animation
        local progressTween = TweenService:Create(self.ProgressBar, PROGRESS_TWEEN_INFO, {Size = UDim2.new(0, 0, 1, 0)})
        progressTween:Play()
        
        self._maid:AddTask(progressTween.Completed:Connect(function()
            if self._destroyed then return end
            self:Destroy()
        end))
        
        if self.Callback then
            self.ClickableArea = Instance.new("TextButton")
            self.ClickableArea.Name = "ClickZone"
            self.ClickableArea.Size = UDim2.new(1, 0, 1, -4)
            self.ClickableArea.BackgroundTransparency = 1
            self.ClickableArea.Text = ""
            self.ClickableArea.ZIndex = 0
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
            
            local _, height = notif:GetScaledSize()
            
            local newY = -NOTIFICATION_PADDING - totalHeight
            local targetPosition = UDim2.new(0, NOTIFICATION_PADDING, 1, newY)
            
            if notif == self then
                -- Initial Position logic is handled in _init
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
        
        -- Out Animation
        local targetPosition = UDim2.new(0, -self.Frame.AbsoluteSize.X, self.Frame.Position.Y.Scale, self.Frame.Position.Y.Offset)
        
        local tween = TweenService:Create(self.Frame, TWEEN_INFO, {
            Position = targetPosition,
            BackgroundTransparency = 1
        })
        TweenService:Create(self.TitleLabel, TWEEN_INFO, {TextTransparency = 1}):Play()
        TweenService:Create(self.TextLabel, TWEEN_INFO, {TextTransparency = 1}):Play()
        TweenService:Create(self.Icon, TWEEN_INFO, {TextTransparency = 1}):Play()
        TweenService:Create(self.ProgressBar, TWEEN_INFO, {BackgroundTransparency = 1}):Play()
        
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

    return NotificationSystem.new()
end)()
