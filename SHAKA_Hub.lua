-- ════════════════════════════════════════════════════════════
-- SHAKA HUB ULTIMATE - Mod Menu Completo e Profissional
-- Versão 7.0 - Design Glassmorphism Moderno
-- ════════════════════════════════════════════════════════════

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")
local Camera = workspace.CurrentCamera
local HttpService = game:GetService("HttpService")

-- ════════════════════════════════════════════════════════════
-- CONFIGURAÇÕES GLOBAIS
-- ════════════════════════════════════════════════════════════
local CONFIG = {
    VERSION = "7.0 Ultimate",
    THEME_HUE = 0.75, -- Azul/Ciano por padrão
    RAINBOW_SPEED = 0.003,
    ANIMATION_SPEED = 0.25,
}

-- ════════════════════════════════════════════════════════════
-- ESTADOS PERSISTENTES
-- ════════════════════════════════════════════════════════════
local State = {
    -- Player
    FlyEnabled = false,
    FlySpeed = 50,
    SupermanFly = false,
    NoclipEnabled = false,
    InfJumpEnabled = false,
    SuperJumpEnabled = false,
    WalkSpeed = 16,
    JumpPower = 50,
    InvisibleEnabled = false,
    GodModeEnabled = false,
    InfiniteStamina = false,
    NoFallDamage = false,
    WalkOnWater = false,
    
    -- ESP
    ESPEnabled = false,
    ESPBox = true,
    ESPLine = true,
    ESPName = true,
    ESPDistance = true,
    ESPHealth = true,
    ESPTeamCheck = false,
    
    -- Visual
    Fullbright = false,
    FOV = 70,
    RemoveFog = false,
    
    -- Config
    RainbowMode = false,
    ThemeHue = 0.75,
    
    -- Keybinds
    Keybinds = {},
    
    -- Other
    SelectedPlayer = nil,
    SavedPosition = nil,
}

local Connections = {}
local ESPObjects = {}
local GUI = nil
local KeybindListening = nil

-- ════════════════════════════════════════════════════════════
-- FUNÇÕES AUXILIARES
-- ════════════════════════════════════════════════════════════
local function GetThemeColor()
    if State.RainbowMode then
        return Color3.fromHSV(CONFIG.THEME_HUE, 0.8, 1)
    else
        return Color3.fromHSV(State.ThemeHue, 0.8, 1)
    end
end

local function Tween(obj, props, time)
    if not obj or not obj.Parent then return end
    local tween = TweenService:Create(obj, TweenInfo.new(time or CONFIG.ANIMATION_SPEED, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), props)
    tween:Play()
    return tween
end

local function Notify(text, duration)
    task.spawn(function()
        if not GUI then return end
        
        local notif = Instance.new("Frame")
        notif.Size = UDim2.new(0, 350, 0, 70)
        notif.Position = UDim2.new(1, 10, 0, 80)
        notif.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
        notif.BackgroundTransparency = 0.1
        notif.BorderSizePixel = 0
        notif.ZIndex = 1000
        notif.Parent = GUI
        
        Instance.new("UICorner", notif).CornerRadius = UDim.new(0, 15)
        
        local blur = Instance.new("ImageLabel")
        blur.Size = UDim2.new(1, 0, 1, 0)
        blur.BackgroundTransparency = 1
        blur.Image = "rbxassetid://8992230677"
        blur.ImageColor3 = Color3.fromRGB(15, 15, 20)
        blur.ImageTransparency = 0.7
        blur.ScaleType = Enum.ScaleType.Slice
        blur.SliceCenter = Rect.new(99, 99, 99, 99)
        blur.Parent = notif
        
        local stroke = Instance.new("UIStroke", notif)
        stroke.Color = GetThemeColor()
        stroke.Thickness = 2
        stroke.Transparency = 0.3
        
        local gradient = Instance.new("UIGradient", notif)
        gradient.Color = ColorSequence.new{
            ColorSequenceKeypoint.new(0, Color3.fromRGB(20, 20, 30)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(10, 10, 15))
        }
        gradient.Rotation = 45
        
        local icon = Instance.new("TextLabel")
        icon.Size = UDim2.new(0, 50, 1, 0)
        icon.BackgroundTransparency = 1
        icon.Text = "✨"
        icon.TextSize = 28
        icon.Font = Enum.Font.GothamBold
        icon.TextColor3 = GetThemeColor()
        icon.Parent = notif
        
        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(1, -60, 1, 0)
        label.Position = UDim2.new(0, 55, 0, 0)
        label.BackgroundTransparency = 1
        label.Text = text
        label.TextColor3 = Color3.fromRGB(255, 255, 255)
        label.TextSize = 14
        label.Font = Enum.Font.GothamBold
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.TextWrapped = true
        label.Parent = notif
        
        Tween(notif, {Position = UDim2.new(1, -360, 0, 80)}, 0.4)
        
        task.wait(duration or 3)
        
        Tween(notif, {Position = UDim2.new(1, 10, 0, 80)}, 0.3)
        task.wait(0.3)
        if notif then notif:Destroy() end
    end)
end

-- ════════════════════════════════════════════════════════════
-- SISTEMA DE KEYBINDS
-- ════════════════════════════════════════════════════════════
local function ExecuteKeybind(key)
    for funcName, keybindKey in pairs(State.Keybinds) do
        if keybindKey == key then
            if funcName == "Fly" then
                State.FlyEnabled = not State.FlyEnabled
                ToggleFly(State.FlyEnabled)
            elseif funcName == "Noclip" then
                State.NoclipEnabled = not State.NoclipEnabled
                ToggleNoclip(State.NoclipEnabled)
            elseif funcName == "SuperJump" then
                State.SuperJumpEnabled = not State.SuperJumpEnabled
                ToggleSuperJump(State.SuperJumpEnabled)
            elseif funcName == "Invisible" then
                State.InvisibleEnabled = not State.InvisibleEnabled
                ToggleInvisible(State.InvisibleEnabled)
            elseif funcName == "GodMode" then
                State.GodModeEnabled = not State.GodModeEnabled
                ToggleGodMode(State.GodModeEnabled)
            end
        end
    end
end

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    ExecuteKeybind(input.KeyCode)
end)

-- ════════════════════════════════════════════════════════════
-- FUNÇÕES DO PLAYER (CORRIGIDAS E EXPANDIDAS)
-- ════════════════════════════════════════════════════════════

function ToggleFly(state)
    State.FlyEnabled = state
    
    if Connections.Fly then
        Connections.Fly:Disconnect()
        Connections.Fly = nil
    end
    
    if Connections.FlyAnimation then
        Connections.FlyAnimation:Disconnect()
        Connections.FlyAnimation = nil
    end
    
    local char = LocalPlayer.Character
    if not char then return end
    
    local root = char:FindFirstChild("HumanoidRootPart")
    local humanoid = char:FindFirstChildOfClass("Humanoid")
    if not root or not humanoid then return end
    
    if state then
        -- Criar Superman visual
        local superman = Instance.new("Part")
        superman.Name = "SupermanEffect"
        superman.Size = Vector3.new(0.5, 0.5, 2)
        superman.CFrame = root.CFrame
        superman.Anchored = false
        superman.CanCollide = false
        superman.Transparency = 1
        superman.Parent = workspace
        
        local weld = Instance.new("WeldConstraint")
        weld.Part0 = root
        weld.Part1 = superman
        weld.Parent = superman
        
        local trail = Instance.new("Trail")
        trail.Color = ColorSequence.new(GetThemeColor())
        trail.Lifetime = 1
        trail.MinLength = 0.1
        trail.Transparency = NumberSequence.new{
            NumberSequenceKeypoint.new(0, 0.5),
            NumberSequenceKeypoint.new(1, 1)
        }
        trail.WidthScale = NumberSequence.new(0.5)
        
        local attach0 = Instance.new("Attachment", superman)
        attach0.Position = Vector3.new(0, 0, -1)
        local attach1 = Instance.new("Attachment", superman)
        attach1.Position = Vector3.new(0, 0, 1)
        
        trail.Attachment0 = attach0
        trail.Attachment1 = attach1
        trail.Parent = superman
        
        -- Sistema de voo
        local bodyVelocity = Instance.new("BodyVelocity")
        bodyVelocity.Name = "FlyVelocity"
        bodyVelocity.MaxForce = Vector3.new(9e9, 9e9, 9e9)
        bodyVelocity.Velocity = Vector3.new(0, 0, 0)
        bodyVelocity.Parent = root
        
        local bodyGyro = Instance.new("BodyGyro")
        bodyGyro.Name = "FlyGyro"
        bodyGyro.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
        bodyGyro.P = 9e4
        bodyGyro.Parent = root
        
        -- Animação Superman
        Connections.FlyAnimation = RunService.Heartbeat:Connect(function()
            if not char or not char.Parent or not root or not root.Parent then
                ToggleFly(false)
                return
            end
            
            -- Atualizar cor do trail no modo rainbow
            if State.RainbowMode then
                trail.Color = ColorSequence.new(GetThemeColor())
            end
            
            -- Pose de Superman
            for _, track in pairs(humanoid:GetPlayingAnimationTracks()) do
                track:Stop()
            end
            
            humanoid.PlatformStand = true
        end)
        
        Connections.Fly = RunService.Heartbeat:Connect(function()
            if not char or not char.Parent or not root or not root.Parent then
                ToggleFly(false)
                return
            end
            
            local moveVector = Vector3.new(0, 0, 0)
            local speed = State.FlySpeed
            
            if UserInputService:IsKeyDown(Enum.KeyCode.W) then
                moveVector = moveVector + (Camera.CFrame.LookVector * speed)
            end
            if UserInputService:IsKeyDown(Enum.KeyCode.S) then
                moveVector = moveVector - (Camera.CFrame.LookVector * speed)
            end
            if UserInputService:IsKeyDown(Enum.KeyCode.A) then
                moveVector = moveVector - (Camera.CFrame.RightVector * speed)
            end
            if UserInputService:IsKeyDown(Enum.KeyCode.D) then
                moveVector = moveVector + (Camera.CFrame.RightVector * speed)
            end
            if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
                moveVector = moveVector + (Vector3.new(0, 1, 0) * speed)
            end
            if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then
                moveVector = moveVector - (Vector3.new(0, 1, 0) * speed)
            end
            
            bodyVelocity.Velocity = moveVector
            
            if moveVector.Magnitude > 0 then
                bodyGyro.CFrame = CFrame.lookAt(root.Position, root.Position + moveVector.Unit)
            else
                bodyGyro.CFrame = Camera.CFrame
            end
        end)
        
        Notify("Fly ativado - Modo Superman!", 2)
    else
        -- Limpar
        humanoid.PlatformStand = false
        
        if root then
            local gyro = root:FindFirstChild("FlyGyro")
            local velocity = root:FindFirstChild("FlyVelocity")
            if gyro then gyro:Destroy() end
            if velocity then velocity:Destroy() end
        end
        
        for _, obj in pairs(workspace:GetChildren()) do
            if obj.Name == "SupermanEffect" then
                obj:Destroy()
            end
        end
        
        Notify("Fly desativado", 2)
    end
end

function ToggleNoclip(state)
    State.NoclipEnabled = state
    
    if Connections.Noclip then
        Connections.Noclip:Disconnect()
        Connections.Noclip = nil
    end
    
    if state then
        Connections.Noclip = RunService.Stepped:Connect(function()
            local char = LocalPlayer.Character
            if char then
                for _, part in pairs(char:GetDescendants()) do
                    if part:IsA("BasePart") then
                        part.CanCollide = false
                    end
                end
            end
        end)
        Notify("Noclip ativado", 2)
    else
        local char = LocalPlayer.Character
        if char then
            for _, part in pairs(char:GetDescendants()) do
                if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
                    part.CanCollide = true
                end
            end
        end
        Notify("Noclip desativado", 2)
    end
end

function ToggleSuperJump(state)
    State.SuperJumpEnabled = state
    
    if Connections.SuperJump then
        Connections.SuperJump:Disconnect()
        Connections.SuperJump = nil
    end
    
    if state then
        Connections.SuperJump = UserInputService.JumpRequest:Connect(function()
            local char = LocalPlayer.Character
            if char then
                local humanoid = char:FindFirstChildOfClass("Humanoid")
                local root = char:FindFirstChild("HumanoidRootPart")
                if humanoid and root then
                    root.Velocity = Vector3.new(root.Velocity.X, 150, root.Velocity.Z)
                    
                    -- Efeito visual
                    local explosion = Instance.new("Part")
                    explosion.Size = Vector3.new(1, 1, 1)
                    explosion.Position = root.Position - Vector3.new(0, 3, 0)
                    explosion.Anchored = true
                    explosion.CanCollide = false
                    explosion.Material = Enum.Material.Neon
                    explosion.Color = GetThemeColor()
                    explosion.Shape = Enum.PartType.Ball
                    explosion.Parent = workspace
                    
                    task.spawn(function()
                        for i = 1, 10 do
                            explosion.Size = explosion.Size + Vector3.new(0.5, 0.5, 0.5)
                            explosion.Transparency = i / 10
                            task.wait(0.05)
                        end
                        explosion:Destroy()
                    end)
                end
            end
        end)
        Notify("Super Jump ativado", 2)
    else
        Notify("Super Jump desativado", 2)
    end
end

function ToggleInvisible(state)
    State.InvisibleEnabled = state
    
    local char = LocalPlayer.Character
    if not char then return end
    
    if state then
        for _, part in pairs(char:GetDescendants()) do
            if part:IsA("BasePart") then
                part.Transparency = 1
                if part.Name == "Head" then
                    local face = part:FindFirstChildOfClass("Decal")
                    if face then
                        face.Transparency = 1
                    end
                end
            elseif part:IsA("Accessory") then
                local handle = part:FindFirstChild("Handle")
                if handle then
                    handle.Transparency = 1
                end
            end
        end
        Notify("Invisibilidade ativada", 2)
    else
        for _, part in pairs(char:GetDescendants()) do
            if part:IsA("BasePart") then
                if part.Name == "Head" then
                    part.Transparency = 0
                    local face = part:FindFirstChildOfClass("Decal")
                    if face then
                        face.Transparency = 0
                    end
                elseif part.Name ~= "HumanoidRootPart" then
                    part.Transparency = 0
                end
                
                if part.Name == "HumanoidRootPart" then
                    part.Transparency = 1
                end
            elseif part:IsA("Accessory") then
                local handle = part:FindFirstChild("Handle")
                if handle then
                    handle.Transparency = 0
                end
            end
        end
        Notify("Invisibilidade desativada", 2)
    end
end

function ToggleGodMode(state)
    State.GodModeEnabled = state
    
    if Connections.GodMode then
        Connections.GodMode:Disconnect()
        Connections.GodMode = nil
    end
    
    if state then
        Connections.GodMode = RunService.Heartbeat:Connect(function()
            local char = LocalPlayer.Character
            if char then
                local humanoid = char:FindFirstChildOfClass("Humanoid")
                if humanoid and humanoid.Health < humanoid.MaxHealth then
                    humanoid.Health = humanoid.MaxHealth
                end
            end
        end)
        Notify("God Mode ativado", 2)
    else
        Notify("God Mode desativado", 2)
    end
end

function ToggleInfJump(state)
    if Connections.InfJump then
        Connections.InfJump:Disconnect()
        Connections.InfJump = nil
    end
    
    if state then
        Connections.InfJump = UserInputService.JumpRequest:Connect(function()
            local char = LocalPlayer.Character
            if char then
                local humanoid = char:FindFirstChildOfClass("Humanoid")
                if humanoid then
                    humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
                end
            end
        end)
        Notify("Pulo Infinito ativado", 2)
    else
        Notify("Pulo Infinito desativado", 2)
    end
end

-- Manter velocidade e pulo
task.spawn(function()
    while true do
        local char = LocalPlayer.Character
        if char then
            local humanoid = char:FindFirstChildOfClass("Humanoid")
            if humanoid then
                if humanoid.WalkSpeed ~= State.WalkSpeed then
                    humanoid.WalkSpeed = State.WalkSpeed
                end
                if humanoid.JumpPower ~= State.JumpPower then
                    humanoid.JumpPower = State.JumpPower
                end
            end
        end
        task.wait(0.1)
    end
end)

-- ════════════════════════════════════════════════════════════
-- SISTEMA DE ESP (COMPLETAMENTE REFEITO E BONITO)
-- ════════════════════════════════════════════════════════════
local function ClearESP()
    for _, esp in pairs(ESPObjects) do
        if esp.Box then esp.Box:Remove() end
        if esp.BoxOutline then esp.BoxOutline:Remove() end
        if esp.Line then esp.Line:Remove() end
        if esp.Name then esp.Name:Remove() end
        if esp.Distance then esp.Distance:Remove() end
        if esp.HealthBar then esp.HealthBar:Remove() end
        if esp.HealthBarBG then esp.HealthBarBG:Remove() end
    end
    ESPObjects = {}
end

local function CreateESP(player)
    if player == LocalPlayer then return end
    if ESPObjects[player] then return end
    
    local esp = { Player = player }
    
    if State.ESPBox then
        esp.BoxOutline = Drawing.new("Square")
        esp.BoxOutline.Thickness = 3
        esp.BoxOutline.Filled = false
        esp.BoxOutline.Color = Color3.new(0, 0, 0)
        esp.BoxOutline.Transparency = 0.8
        esp.BoxOutline.Visible = false
        esp.BoxOutline.ZIndex = 1
        
        esp.Box = Drawing.new("Square")
        esp.Box.Thickness = 1
        esp.Box.Filled = false
        esp.Box.Color = Color3.new(1, 1, 1)
        esp.Box.Transparency = 1
        esp.Box.Visible = false
        esp.Box.ZIndex = 2
    end
    
    if State.ESPLine then
        esp.Line = Drawing.new("Line")
        esp.Line.Thickness = 2
        esp.Line.Color = Color3.new(1, 1, 1)
        esp.Line.Transparency = 0.8
        esp.Line.Visible = false
        esp.Line.ZIndex = 1
    end
    
    if State.ESPName then
        esp.Name = Drawing.new("Text")
        esp.Name.Size = 16
        esp.Name.Center = true
        esp.Name.Outline = true
        esp.Name.OutlineColor = Color3.new(0, 0, 0)
        esp.Name.Color = Color3.new(1, 1, 1)
        esp.Name.Transparency = 1
        esp.Name.Visible = false
        esp.Name.ZIndex = 2
        esp.Name.Font = Drawing.Fonts.Plex
        esp.Name.Text = player.Name
    end
    
    if State.ESPDistance then
        esp.Distance = Drawing.new("Text")
        esp.Distance.Size = 14
        esp.Distance.Center = true
        esp.Distance.Outline = true
        esp.Distance.OutlineColor = Color3.new(0, 0, 0)
        esp.Distance.Color = Color3.new(0.8, 0.8, 0.8)
        esp.Distance.Transparency = 1
        esp.Distance.Visible = false
        esp.Distance.ZIndex = 2
        esp.Distance.Font = Drawing.Fonts.Plex
    end
    
    if State.ESPHealth then
        esp.HealthBarBG = Drawing.new("Square")
        esp.HealthBarBG.Thickness = 1
        esp.HealthBarBG.Filled = true
        esp.HealthBarBG.Color = Color3.new(0, 0, 0)
        esp.HealthBarBG.Transparency = 0.5
        esp.HealthBarBG.Visible = false
        esp.HealthBarBG.ZIndex = 1
        
        esp.HealthBar = Drawing.new("Square")
        esp.HealthBar.Thickness = 1
        esp.HealthBar.Filled = true
        esp.HealthBar.Color = Color3.new(0, 1, 0)
        esp.HealthBar.Transparency = 1
        esp.HealthBar.Visible = false
        esp.HealthBar.ZIndex = 2
    end
    
    ESPObjects[player] = esp
end

local function UpdateESP()
    if not State.ESPEnabled then return end
    
    for player, esp in pairs(ESPObjects) do
        if not player or not player.Parent or player == LocalPlayer then
            if esp.Box then esp.Box:Remove() end
            if esp.BoxOutline then esp.BoxOutline:Remove() end
            if esp.Line then esp.Line:Remove() end
            if esp.Name then esp.Name:Remove() end
            if esp.Distance then esp.Distance:Remove() end
            if esp.HealthBar then esp.HealthBar:Remove() end
            if esp.HealthBarBG then esp.HealthBarBG:Remove() end
            ESPObjects[player] = nil
            continue
        end
        
        local char = player.Character
        if not char then
            if esp.Box then esp.Box.Visible = false end
            if esp.BoxOutline then esp.BoxOutline.Visible = false end
            if esp.Line then esp.Line.Visible = false end
            if esp.Name then esp.Name.Visible = false end
            if esp.Distance then esp.Distance.Visible = false end
            if esp.HealthBar then esp.HealthBar.Visible = false end
            if esp.HealthBarBG then esp.HealthBarBG.Visible = false end
            continue
        end
        
        local root = char:FindFirstChild("HumanoidRootPart")
        local head = char:FindFirstChild("Head")
        local humanoid = char:FindFirstChildOfClass("Humanoid")
        
        if root and head and humanoid and humanoid.Health > 0 then
            local rootPos, onScreen = Camera:WorldToViewportPoint(root.Position)
            
            if onScreen and rootPos.Z > 0 then
                local headPos = Camera:WorldToViewportPoint(head.Position + Vector3.new(0, 0.5, 0))
                local legPos = Camera:WorldToViewportPoint(root.Position - Vector3.new(0, 3, 0))
                
                local height = math.abs(headPos.Y - legPos.Y)
                local width = height / 2
                
                local themeColor = GetThemeColor()
                
                -- Box ESP
                if esp.Box and State.ESPBox then
                    esp.BoxOutline.Size = Vector2.new(width, height)
                    esp.BoxOutline.Position = Vector2.new(rootPos.X - width/2, rootPos.Y - height/2)
                    esp.BoxOutline.Visible = true
                    
                    esp.Box.Size = Vector2.new(width, height)
                    esp.Box.Position = Vector2.new(rootPos.X - width/2, rootPos.Y - height/2)
                    esp.Box.Color = themeColor
                    esp.Box.Visible = true
                end
                
                -- Line ESP
                if esp.Line and State.ESPLine then
                    esp.Line.From = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
                    esp.Line.To = Vector2.new(rootPos.X, rootPos.Y)
                    esp.Line.Color = themeColor
                    esp.Line.Visible = true
                end
                
                -- Name ESP
                if esp.Name and State.ESPName then
                    esp.Name.Position = Vector2.new(rootPos.X, headPos.Y - 25)
                    esp.Name.Color = themeColor
                    esp.Name.Text = player.Name
                    esp.Name.Visible = true
                end
                
                -- Distance ESP
                if esp.Distance and State.ESPDistance and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                    local distance = (LocalPlayer.Character.HumanoidRootPart.Position - root.Position).Magnitude
                    esp.Distance.Position = Vector2.new(rootPos.X, legPos.Y + 10)
                    esp.Distance.Text = string.format("[%d studs]", math.floor(distance))
                    esp.Distance.Visible = true
                end
                
                -- Health Bar ESP
                if esp.HealthBar and State.ESPHealth then
                    local healthPercent = humanoid.Health / humanoid.MaxHealth
                    local barHeight = height * healthPercent
                    
                    esp.HealthBarBG.Size = Vector2.new(4, height)
                    esp.HealthBarBG.Position = Vector2.new(rootPos.X - width/2 - 8, rootPos.Y - height/2)
                    esp.HealthBarBG.Visible = true
                    
                    esp.HealthBar.Size = Vector2.new(4, barHeight)
                    esp.HealthBar.Position = Vector2.new(rootPos.X - width/2 - 8, rootPos.Y + height/2 - barHeight)
                    esp.HealthBar.Color = Color3.new(1 - healthPercent, healthPercent, 0)
                    esp.HealthBar.Visible = true
                end
            else
                if esp.Box then esp.Box.Visible = false end
                if esp.BoxOutline then esp.BoxOutline.Visible = false end
                if esp.Line then esp.Line.Visible = false end
                if esp.Name then esp.Name.Visible = false end
                if esp.Distance then esp.Distance.Visible = false end
                if esp.HealthBar then esp.HealthBar.Visible = false end
                if esp.HealthBarBG then esp.HealthBarBG.Visible = false end
            end
        else
            if esp.Box then esp.Box.Visible = false end
            if esp.BoxOutline then esp.BoxOutline.Visible = false end
            if esp.Line then esp.Line.Visible = false end
            if esp.Name then esp.Name.Visible = false end
            if esp.Distance then esp.Distance.Visible = false end
            if esp.HealthBar then esp.HealthBar.Visible = false end
            if esp.HealthBarBG then esp.HealthBarBG.Visible = false end
        end
    end
end

function ToggleESP(state)
    State.ESPEnabled = state
    
    if Connections.ESP then
        Connections.ESP:Disconnect()
        Connections.ESP = nil
    end
    
    if state then
        for _, player in pairs(Players:GetPlayers()) do
            CreateESP(player)
        end
        
        Connections.ESP = RunService.RenderStepped:Connect(UpdateESP)
        Notify("ESP ativado", 2)
    else
        ClearESP()
        Notify("ESP desativado", 2)
    end
end

Players.PlayerAdded:Connect(function(player)
    if State.ESPEnabled then
        task.wait(1)
        CreateESP(player)
    end
end)

Players.PlayerRemoving:Connect(function(player)
    if ESPObjects[player] then
        local esp = ESPObjects[player]
        if esp.Box then esp.Box:Remove() end
        if esp.BoxOutline then esp.BoxOutline:Remove() end
        if esp.Line then esp.Line:Remove() end
        if esp.Name then esp.Name:Remove() end
        if esp.Distance then esp.Distance:Remove() end
        if esp.HealthBar then esp.HealthBar:Remove() end
        if esp.HealthBarBG then esp.HealthBarBG:Remove() end
        ESPObjects[player] = nil
    end
end)

-- ════════════════════════════════════════════════════════════
-- FUNÇÕES VISUAIS
-- ════════════════════════════════════════════════════════════
function ToggleFullbright(state)
    State.Fullbright = state
    
    if state then
        Lighting.Brightness = 3
        Lighting.ClockTime = 14
        Lighting.FogEnd = 1e10
        Lighting.GlobalShadows = false
        Lighting.OutdoorAmbient = Color3.new(1, 1, 1)
        Lighting.Ambient = Color3.new(1, 1, 1)
        Notify("Fullbright ativado", 2)
    else
        Lighting.Brightness = 1
        Lighting.FogEnd = 1e5
        Lighting.GlobalShadows = true
        Lighting.OutdoorAmbient = Color3.new(0.5, 0.5, 0.5)
        Lighting.Ambient = Color3.new(0, 0, 0)
        Notify("Fullbright desativado", 2)
    end
end

-- ════════════════════════════════════════════════════════════
-- CRIAÇÃO DA GUI (DESIGN GLASSMORPHISM MODERNO)
-- ════════════════════════════════════════════════════════════
local function CreateModernGUI()
    if GUI then
        GUI:Destroy()
    end
    
    -- ScreenGui principal
    GUI = Instance.new("ScreenGui")
    GUI.Name = "SHAKA_HUB_ULTIMATE"
    GUI.ResetOnSpawn = false
    GUI.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    GUI.Parent = LocalPlayer:WaitForChild("PlayerGui")
    
    -- Container principal com glassmorphism
    local main = Instance.new("Frame")
    main.Name = "Main"
    main.Size = UDim2.new(0, 850, 0, 550)
    main.Position = UDim2.new(0.5, -425, 0.5, -275)
    main.BackgroundColor3 = Color3.fromRGB(10, 10, 15)
    main.BackgroundTransparency = 0.2
    main.BorderSizePixel = 0
    main.Parent = GUI
    
    Instance.new("UICorner", main).CornerRadius = UDim.new(0, 20)
    
    -- Efeito glassmorphism
    local blur = Instance.new("ImageLabel")
    blur.Size = UDim2.new(1, 0, 1, 0)
    blur.BackgroundTransparency = 1
    blur.Image = "rbxassetid://8992230677"
    blur.ImageColor3 = Color3.fromRGB(10, 10, 15)
    blur.ImageTransparency = 0.6
    blur.ScaleType = Enum.ScaleType.Slice
    blur.SliceCenter = Rect.new(99, 99, 99, 99)
    blur.Parent = main
    
    local mainStroke = Instance.new("UIStroke", main)
    mainStroke.Color = GetThemeColor()
    mainStroke.Thickness = 2
    mainStroke.Transparency = 0.3
    
    local mainGradient = Instance.new("UIGradient", main)
    mainGradient.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, Color3.fromRGB(15, 15, 25)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(5, 5, 10))
    }
    mainGradient.Rotation = 45
    
    -- Header moderno
    local header = Instance.new("Frame")
    header.Name = "Header"
    header.Size = UDim2.new(1, 0, 0, 60)
    header.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
    header.BackgroundTransparency = 0.3
    header.BorderSizePixel = 0
    header.Parent = main
    
    Instance.new("UICorner", header).CornerRadius = UDim.new(0, 20)
    
    local headerStroke = Instance.new("UIStroke", header)
    headerStroke.Color = GetThemeColor()
    headerStroke.Thickness = 1
    headerStroke.Transparency = 0.5
    
    -- Logo com gradiente
    local logo = Instance.new("TextLabel")
    logo.Size = UDim2.new(0, 250, 1, 0)
    logo.Position = UDim2.new(0, 25, 0, 0)
    logo.BackgroundTransparency = 1
    logo.Text = "✨ SHAKA HUB ULTIMATE"
    logo.TextColor3 = Color3.fromRGB(255, 255, 255)
    logo.TextSize = 24
    logo.Font = Enum.Font.GothamBold
    logo.TextXAlignment = Enum.TextXAlignment.Left
    logo.Parent = header
    
    local logoGradient = Instance.new("UIGradient", logo)
    logoGradient.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, GetThemeColor()),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 255, 255))
    }
    
    -- Badge de versão
    local version = Instance.new("Frame")
    version.Size = UDim2.new(0, 110, 0, 28)
    version.Position = UDim2.new(0, 280, 0, 16)
    version.BackgroundColor3 = GetThemeColor()
    version.BorderSizePixel = 0
    version.Parent = header
    
    Instance.new("UICorner", version).CornerRadius = UDim.new(0, 14)
    
    local versionLabel = Instance.new("TextLabel")
    versionLabel.Size = UDim2.new(1, 0, 1, 0)
    versionLabel.BackgroundTransparency = 1
    versionLabel.Text = "v" .. CONFIG.VERSION
    versionLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    versionLabel.TextSize = 13
    versionLabel.Font = Enum.Font.GothamBold
    versionLabel.Parent = version
    
    -- Botão fechar moderno
    local closeBtn = Instance.new("TextButton")
    closeBtn.Size = UDim2.new(0, 40, 0, 40)
    closeBtn.Position = UDim2.new(1, -50, 0, 10)
    closeBtn.BackgroundColor3 = Color3.fromRGB(255, 50, 80)
    closeBtn.Text = "✕"
    closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    closeBtn.TextSize = 22
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.BorderSizePixel = 0
    closeBtn.Parent = header
    
    Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 10)
    
    closeBtn.MouseEnter:Connect(function()
        Tween(closeBtn, {BackgroundColor3 = Color3.fromRGB(255, 70, 100)}, 0.2)
    end)
    
    closeBtn.MouseLeave:Connect(function()
        Tween(closeBtn, {BackgroundColor3 = Color3.fromRGB(255, 50, 80)}, 0.2)
    end)
    
    closeBtn.MouseButton1Click:Connect(function()
        Tween(main, {Size = UDim2.new(0, 0, 0, 0)}, 0.3)
        task.wait(0.3)
        GUI:Destroy()
        GUI = nil
    end)
    
    -- Sistema de arrastar
    local dragging, dragInput, dragStart, startPos
    
    header.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            startPos = main.Position
            
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)
    
    UserInputService.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement then
            dragInput = input
        end
    end)
    
    RunService.Heartbeat:Connect(function()
        if dragging and dragInput then
            local delta = dragInput.Position - dragStart
            main.Position = UDim2.new(
                startPos.X.Scale,
                startPos.X.Offset + delta.X,
                startPos.Y.Scale,
                startPos.Y.Offset + delta.Y
            )
        end
    end)
    
    -- Container de conteúdo
    local content = Instance.new("Frame")
    content.Size = UDim2.new(1, -20, 1, -80)
    content.Position = UDim2.new(0, 10, 0, 70)
    content.BackgroundTransparency = 1
    content.Parent = main
    
    -- Sistema de abas
    local tabBar = Instance.new("Frame")
    tabBar.Size = UDim2.new(1, 0, 0, 50)
    tabBar.BackgroundTransparency = 1
    tabBar.Parent = content
    
    local tabLayout = Instance.new("UIListLayout")
    tabLayout.FillDirection = Enum.FillDirection.Horizontal
    tabLayout.Padding = UDim.new(0, 10)
    tabLayout.SortOrder = Enum.SortOrder.LayoutOrder
    tabLayout.Parent = tabBar
    
    local tabContent = Instance.new("Frame")
    tabContent.Size = UDim2.new(1, 0, 1, -60)
    tabContent.Position = UDim2.new(0, 0, 0, 60)
    tabContent.BackgroundTransparency = 1
    tabContent.Parent = content
    
    local tabs = {
        {Name = "Player", Icon = "👤"},
        {Name = "ESP", Icon = "👁️"},
        {Name = "Visual", Icon = "✨"},
        {Name = "Config", Icon = "⚙️"}
    }
    
    local tabFrames = {}
    
    -- Função para criar toggle com keybind
    local function CreateToggleWithKeybind(name, desc, stateKey, callback, parent)
        local container = Instance.new("Frame")
        container.Size = UDim2.new(1, 0, 0, 75)
        container.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
        container.BackgroundTransparency = 0.3
        container.BorderSizePixel = 0
        container.Parent = parent
        
        Instance.new("UICorner", container).CornerRadius = UDim.new(0, 12)
        
        local containerStroke = Instance.new("UIStroke", container)
        containerStroke.Color = GetThemeColor()
        containerStroke.Thickness = 1
        containerStroke.Transparency = 0.7
        
        local nameLabel = Instance.new("TextLabel")
        nameLabel.Size = UDim2.new(0.5, -10, 0, 25)
        nameLabel.Position = UDim2.new(0, 15, 0, 10)
        nameLabel.BackgroundTransparency = 1
        nameLabel.Text = name
        nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
        nameLabel.TextSize = 16
        nameLabel.Font = Enum.Font.GothamBold
        nameLabel.TextXAlignment = Enum.TextXAlignment.Left
        nameLabel.Parent = container
        
        local descLabel = Instance.new("TextLabel")
        descLabel.Size = UDim2.new(0.6, -10, 0, 20)
        descLabel.Position = UDim2.new(0, 15, 0, 40)
        descLabel.BackgroundTransparency = 1
        descLabel.Text = desc
        descLabel.TextColor3 = Color3.fromRGB(150, 150, 160)
        descLabel.TextSize = 12
        descLabel.Font = Enum.Font.Gotham
        descLabel.TextXAlignment = Enum.TextXAlignment.Left
        descLabel.Parent = container
        
        -- Toggle switch
        local toggle = Instance.new("TextButton")
        toggle.Size = UDim2.new(0, 60, 0, 30)
        toggle.Position = UDim2.new(1, -145, 0.5, -15)
        toggle.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
        toggle.Text = ""
        toggle.BorderSizePixel = 0
        toggle.Parent = container
        
        Instance.new("UICorner", toggle).CornerRadius = UDim.new(0, 15)
        
        local knob = Instance.new("Frame")
        knob.Size = UDim2.new(0, 26, 0, 26)
        knob.Position = UDim2.new(0, 2, 0, 2)
        knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        knob.BorderSizePixel = 0
        knob.Parent = toggle
        
        Instance.new("UICorner", knob).CornerRadius = UDim.new(0, 13)
        
        -- Keybind button
        local keybindBtn = Instance.new("TextButton")
        keybindBtn.Size = UDim2.new(0, 70, 0, 30)
        keybindBtn.Position = UDim2.new(1, -70, 0.5, -15)
        keybindBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
        keybindBtn.Text = State.Keybinds[stateKey] and State.Keybinds[stateKey].Name:sub(9) or "None"
        keybindBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
        keybindBtn.TextSize = 12
        keybindBtn.Font = Enum.Font.GothamBold
        keybindBtn.BorderSizePixel = 0
        keybindBtn.Parent = container
        
        Instance.new("UICorner", keybindBtn).CornerRadius = UDim.new(0, 10)
        
        local keybindStroke = Instance.new("UIStroke", keybindBtn)
        keybindStroke.Color = GetThemeColor()
        keybindStroke.Thickness = 1
        keybindStroke.Transparency = 0.5
        
        -- Toggle logic
        local state = State[stateKey] or false
        
        if state then
            toggle.BackgroundColor3 = GetThemeColor()
            knob.Position = UDim2.new(0, 32, 0, 2)
        end
        
        toggle.MouseButton1Click:Connect(function()
            state = not state
            State[stateKey] = state
            
            if state then
                Tween(toggle, {BackgroundColor3 = GetThemeColor()}, 0.2)
                Tween(knob, {Position = UDim2.new(0, 32, 0, 2)}, 0.2)
            else
                Tween(toggle, {BackgroundColor3 = Color3.fromRGB(40, 40, 50)}, 0.2)
                Tween(knob, {Position = UDim2.new(0, 2, 0, 2)}, 0.2)
            end
            
            callback(state)
        end)
        
        -- Keybind logic
        keybindBtn.MouseButton1Click:Connect(function()
            keybindBtn.Text = "..."
            keybindBtn.BackgroundColor3 = GetThemeColor()
            KeybindListening = stateKey
            
            local connection
            connection = UserInputService.InputBegan:Connect(function(input, gameProcessed)
                if gameProcessed then return end
                
                if input.UserInputType == Enum.UserInputType.Keyboard then
                    State.Keybinds[stateKey] = input.KeyCode
                    keybindBtn.Text = input.KeyCode.Name
                    keybindBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
                    KeybindListening = nil
                    connection:Disconnect()
                end
            end)
        end)
        
        return container
    end
    
    -- Função para criar slider
    local function CreateSlider(name, min, max, stateKey, callback, parent)
        local container = Instance.new("Frame")
        container.Size = UDim2.new(1, 0, 0, 80)
        container.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
        container.BackgroundTransparency = 0.3
        container.BorderSizePixel = 0
        container.Parent = parent
        
        Instance.new("UICorner", container).CornerRadius = UDim.new(0, 12)
        
        local containerStroke = Instance.new("UIStroke", container)
        containerStroke.Color = GetThemeColor()
        containerStroke.Thickness = 1
        containerStroke.Transparency = 0.7
        
        local nameLabel = Instance.new("TextLabel")
        nameLabel.Size = UDim2.new(0.6, 0, 0, 25)
        nameLabel.Position = UDim2.new(0, 15, 0, 10)
        nameLabel.BackgroundTransparency = 1
        nameLabel.Text = name
        nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
        nameLabel.TextSize = 16
        nameLabel.Font = Enum.Font.GothamBold
        nameLabel.TextXAlignment = Enum.TextXAlignment.Left
        nameLabel.Parent = container
        
        local value = State[stateKey] or min
        
        local valueLabel = Instance.new("TextLabel")
        valueLabel.Size = UDim2.new(0.3, 0, 0, 25)
        valueLabel.Position = UDim2.new(0.7, 0, 0, 10)
        valueLabel.BackgroundTransparency = 1
        valueLabel.Text = tostring(value)
        valueLabel.TextColor3 = GetThemeColor()
        valueLabel.TextSize = 16
        valueLabel.Font = Enum.Font.GothamBold
        valueLabel.TextXAlignment = Enum.TextXAlignment.Right
        valueLabel.Parent = container
        
        local track = Instance.new("Frame")
        track.Size = UDim2.new(1, -30, 0, 8)
        track.Position = UDim2.new(0, 15, 0, 50)
        track.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
        track.BorderSizePixel = 0
        track.Parent = container
        
        Instance.new("UICorner", track).CornerRadius = UDim.new(0, 4)
        
        local fill = Instance.new("Frame")
        fill.Size = UDim2.new((value - min) / (max - min), 0, 1, 0)
        fill.BackgroundColor3 = GetThemeColor()
        fill.BorderSizePixel = 0
        fill.Parent = track
        
        Instance.new("UICorner", fill).CornerRadius = UDim.new(0, 4)
        
        local knob = Instance.new("Frame")
        knob.Size = UDim2.new(0, 20, 0, 20)
        knob.Position = UDim2.new((value - min) / (max - min), -10, 0.5, -10)
        knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        knob.BorderSizePixel = 0
        knob.Parent = track
        
        Instance.new("UICorner", knob).CornerRadius = UDim.new(0, 10)
        
        local knobStroke = Instance.new("UIStroke", knob)
        knobStroke.Color = GetThemeColor()
        knobStroke.Thickness = 2
        
        local dragging = false
        
        local function update(input)
            local pos = math.clamp((input.Position.X - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
            local newValue = math.floor(min + (max - min) * pos)
            
            fill.Size = UDim2.new(pos, 0, 1, 0)
            knob.Position = UDim2.new(pos, -10, 0.5, -10)
            valueLabel.Text = tostring(newValue)
            
            State[stateKey] = newValue
            callback(newValue)
        end
        
        knob.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                dragging = true
                Tween(knob, {Size = UDim2.new(0, 24, 0, 24)}, 0.1)
            end
        end)
        
        UserInputService.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                dragging = false
                Tween(knob, {Size = UDim2.new(0, 20, 0, 20)}, 0.1)
            end
        end)
        
        UserInputService.InputChanged:Connect(function(input)
            if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
                update(input)
            end
        end)
        
        track.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                update(input)
            end
        end)
        
        return container
    end
    
    -- Criar abas
    for i, tab in ipairs(tabs) do
        local tabBtn = Instance.new("TextButton")
        tabBtn.Size = UDim2.new(0, 200, 0, 45)
        tabBtn.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
        tabBtn.BackgroundTransparency = 0.4
        tabBtn.Text = tab.Icon .. "  " .. tab.Name
        tabBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        tabBtn.TextSize = 15
        tabBtn.Font = Enum.Font.GothamBold
        tabBtn.BorderSizePixel = 0
        tabBtn.Parent = tabBar
        
        Instance.new("UICorner", tabBtn).CornerRadius = UDim.new(0, 12)
        
        local tabStroke = Instance.new("UIStroke", tabBtn)
        tabStroke.Color = GetThemeColor()
        tabStroke.Thickness = 1
        tabStroke.Transparency = 0.7
        
        local tabFrame = Instance.new("ScrollingFrame")
        tabFrame.Size = UDim2.new(1, 0, 1, 0)
        tabFrame.BackgroundTransparency = 1
        tabFrame.BorderSizePixel = 0
        tabFrame.ScrollBarThickness = 6
        tabFrame.ScrollBarImageColor3 = GetThemeColor()
        tabFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
        tabFrame.Visible = false
        tabFrame.Parent = tabContent
        
        local layout = Instance.new("UIListLayout")
        layout.Padding = UDim.new(0, 10)
        layout.SortOrder = Enum.SortOrder.LayoutOrder
        layout.Parent = tabFrame
        
        layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            tabFrame.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 10)
        end)
        
        tabFrames[tab.Name] = tabFrame
        
        tabBtn.MouseEnter:Connect(function()
            Tween(tabBtn, {BackgroundTransparency = 0.2}, 0.2)
        end)
        
        tabBtn.MouseLeave:Connect(function()
            if tabFrame.Visible then
                Tween(tabBtn, {BackgroundTransparency = 0}, 0.2)
            else
                Tween(tabBtn, {BackgroundTransparency = 0.4}, 0.2)
            end
        end)
        
        tabBtn.MouseButton1Click:Connect(function()
            for name, frame in pairs(tabFrames) do
                frame.Visible = (name == tab.Name)
            end
            
            for _, btn in pairs(tabBar:GetChildren()) do
                if btn:IsA("TextButton") then
                    Tween(btn, {BackgroundTransparency = 0.4}, 0.2)
                    local stroke = btn:FindFirstChildOfClass("UIStroke")
                    if stroke then
                        Tween(stroke, {Transparency = 0.7}, 0.2)
                    end
                end
            end
            
            Tween(tabBtn, {BackgroundTransparency = 0}, 0.2)
            Tween(tabStroke, {Transparency = 0.3}, 0.2)
        end)
        
        if i == 1 then
            tabBtn.BackgroundTransparency = 0
            tabStroke.Transparency = 0.3
            tabFrame.Visible = true
        end
    end
    
    -- CONTEÚDO DAS ABAS
    
    -- ABA PLAYER
    CreateToggleWithKeybind("✈️ Fly", "Voar pelo mapa estilo Superman", "FlyEnabled", ToggleFly, tabFrames["Player"])
    CreateSlider("Velocidade do Fly", 10, 200, "FlySpeed", function(value)
        State.FlySpeed = value
    end, tabFrames["Player"])
    
    CreateToggleWithKeybind("👻 Noclip", "Atravessar paredes e objetos", "NoclipEnabled", ToggleNoclip, tabFrames["Player"])
    CreateToggleWithKeybind("🦘 Super Jump", "Pulo super poderoso com efeito visual", "SuperJumpEnabled", ToggleSuperJump, tabFrames["Player"])
    CreateToggleWithKeybind("👤 Invisível", "Ficar completamente invisível", "InvisibleEnabled", ToggleInvisible, tabFrames["Player"])
    CreateToggleWithKeybind("🛡️ God Mode", "Vida infinita", "GodModeEnabled", ToggleGodMode, tabFrames["Player"])
    
    CreateSlider("🏃 Velocidade de Movimento", 16, 500, "WalkSpeed", function(value)
        State.WalkSpeed = value
    end, tabFrames["Player"])
    
    CreateSlider("⬆️ Força do Pulo", 50, 500, "JumpPower", function(value)
        State.JumpPower = value
    end, tabFrames["Player"])
    
    -- ABA ESP
    CreateToggleWithKeybind("👁️ Ativar ESP", "Sistema completo de visão de jogadores", "ESPEnabled", ToggleESP, tabFrames["ESP"])
    
    CreateToggleWithKeybind("📦 Box ESP", "Caixas coloridas ao redor dos jogadores", "ESPBox", function(state)
        State.ESPBox = state
        if State.ESPEnabled then
            ToggleESP(false)
            task.wait(0.1)
            ToggleESP(true)
        end
    end, tabFrames["ESP"])
    
    CreateToggleWithKeybind("📏 Line ESP", "Linhas conectando você aos jogadores", "ESPLine", function(state)
        State.ESPLine = state
        if State.ESPEnabled then
            ToggleESP(false)
            task.wait(0.1)
            ToggleESP(true)
        end
    end, tabFrames["ESP"])
    
    CreateToggleWithKeybind("📝 Name ESP", "Mostrar nomes dos jogadores", "ESPName", function(state)
        State.ESPName = state
        if State.ESPEnabled then
            ToggleESP(false)
            task.wait(0.1)
            ToggleESP(true)
        end
    end, tabFrames["ESP"])
    
    CreateToggleWithKeybind("📍 Distance ESP", "Mostrar distância em studs", "ESPDistance", function(state)
        State.ESPDistance = state
        if State.ESPEnabled then
            ToggleESP(false)
            task.wait(0.1)
            ToggleESP(true)
        end
    end, tabFrames["ESP"])
    
    CreateToggleWithKeybind("❤️ Health Bar ESP", "Barra de vida colorida", "ESPHealth", function(state)
        State.ESPHealth = state
        if State.ESPEnabled then
            ToggleESP(false)
            task.wait(0.1)
            ToggleESP(true)
        end
    end, tabFrames["ESP"])
    
    -- ABA VISUAL
    CreateToggleWithKeybind("💡 Fullbright", "Iluminação máxima no mapa", "Fullbright", ToggleFullbright, tabFrames["Visual"])
    
    CreateToggleWithKeybind("🌫️ Remover Fog", "Remover neblina do jogo", "RemoveFog", function(state)
        State.RemoveFog = state
        if state then
            Lighting.FogEnd = 1e10
            Lighting.FogStart = 0
            Notify("Fog removido", 2)
        else
            Lighting.FogEnd = 1e5
            Lighting.FogStart = 0
            Notify("Fog restaurado", 2)
        end
    end, tabFrames["Visual"])
    
    CreateSlider("🔭 Campo de Visão (FOV)", 70, 120, "FOV", function(value)
        State.FOV = value
        Camera.FieldOfView = value
    end, tabFrames["Visual"])
    
    -- ABA CONFIG
    CreateToggleWithKeybind("🌈 Modo Rainbow", "Cores do menu mudam constantemente", "RainbowMode", function(state)
        State.RainbowMode = state
        
        if Connections.Rainbow then
            Connections.Rainbow:Disconnect()
            Connections.Rainbow = nil
        end
        
        if state then
            Connections.Rainbow = RunService.Heartbeat:Connect(function()
                CONFIG.THEME_HUE = (CONFIG.THEME_HUE + CONFIG.RAINBOW_SPEED) % 1
            end)
            Notify("Modo Rainbow ativado!", 2)
        else
            Notify("Modo Rainbow desativado", 2)
        end
    end, tabFrames["Config"])
    
    CreateSlider("🎨 Matiz da Cor (Hue)", 0, 100, "ThemeHue", function(value)
        if not State.RainbowMode then
            State.ThemeHue = value / 100
        end
    end, tabFrames["Config"])
    
    -- Animação de entrada
    main.Size = UDim2.new(0, 0, 0, 0)
    Tween(main, {Size = UDim2.new(0, 850, 0, 550)}, 0.5)
    
    Notify("SHAKA HUB ULTIMATE carregado!", 3)
end

-- ════════════════════════════════════════════════════════════
-- INICIALIZAÇÃO
-- ════════════════════════════════════════════════════════════
print("════════════════════════════════════════")
print("  SHAKA HUB ULTIMATE " .. CONFIG.VERSION)
print("  Design Glassmorphism Moderno")
print("════════════════════════════════════════")

task.wait(0.5)

CreateModernGUI()

-- Sistema de rainbow
task.spawn(function()
    while true do
        if State.RainbowMode and GUI then
            -- Atualizar todas as cores do menu
            for _, obj in pairs(GUI:GetDescendants()) do
                if obj:IsA("UIStroke") and obj.Parent.Name ~= "Main" then
                    obj.Color = GetThemeColor()
                elseif obj.Name == "version" or obj:FindFirstChild("version") then
                    obj.BackgroundColor3 = GetThemeColor()
                end
            end
        end
        task.wait(0.03)
    end
end)

-- Toggle do menu com INSERT
UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    
    if input.KeyCode == Enum.KeyCode.Insert then
        if GUI then
            local main = GUI:FindFirstChild("Main")
            if main then
                Tween(main, {Size = UDim2.new(0, 0, 0, 0)}, 0.3)
                task.wait(0.3)
            end
            GUI:Destroy()
            GUI = nil
        else
            CreateModernGUI()
        end
    end
end)

-- Reconectar ao resetar
LocalPlayer.CharacterAdded:Connect(function()
    task.wait(1)
    if State.FlyEnabled then ToggleFly(true) end
    if State.NoclipEnabled then ToggleNoclip(true) end
    if State.SuperJumpEnabled then ToggleSuperJump(true) end
    if State.InvisibleEnabled then ToggleInvisible(true) end
    if State.GodModeEnabled then ToggleGodMode(true) end
    if State.ESPEnabled then ToggleESP(true) end
    if State.Fullbright then ToggleFullbright(true) end
end)

print("✅ Sistema carregado com sucesso!")
print("⌨️  Pressione INSERT para abrir/fechar")
print("🎮 Configure keybinds para funções rápidas")
print("════════════════════════════════════════")
