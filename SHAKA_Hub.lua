-- SHAKA Hub Premium v7.0 - Mod Menu Redesenhado
-- Desenvolvido para Delta Executor

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")
local Camera = workspace.CurrentCamera
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- ════════════════════════════════════════════════════════════
-- CONFIGURAÇÕES E ESTADO
-- ════════════════════════════════════════════════════════════
local CONFIG = {
    VERSION = "7.0",
    MENU_KEY = Enum.KeyCode.Insert,
    THEME = {
        Primary = Color3.fromRGB(138, 43, 226),
        Secondary = Color3.fromRGB(186, 85, 211),
        Background = Color3.fromRGB(15, 15, 20),
        Surface = Color3.fromRGB(25, 25, 35),
        Accent = Color3.fromRGB(255, 100, 255),
        Success = Color3.fromRGB(46, 213, 115),
        Error = Color3.fromRGB(255, 71, 87),
        Warning = Color3.fromRGB(255, 184, 0),
        Text = Color3.fromRGB(255, 255, 255),
        TextDim = Color3.fromRGB(180, 180, 190)
    }
}

local STATE = {
    GUI = nil,
    Connections = {},
    SelectedPlayer = nil,
    RainbowHue = 0,
    RainbowEnabled = false,
    Keybinds = {},
    
    -- Estados das funções
    FlyEnabled = false,
    FlySpeed = 50,
    NoclipEnabled = false,
    InfJumpEnabled = false,
    SpeedEnabled = false,
    WalkSpeed = 16,
    JumpPower = 50,
    GodMode = false,
    InvisibleEnabled = false,
    ESPEnabled = false,
    FullbrightEnabled = false,
    
    -- Objetos do ESP
    ESPObjects = {},
    
    -- Objetos spawnados
    SpawnedObjects = {}
}

-- ════════════════════════════════════════════════════════════
-- FUNÇÕES AUXILIARES
-- ════════════════════════════════════════════════════════════
local function GetThemeColor()
    if STATE.RainbowEnabled then
        return Color3.fromHSV(STATE.RainbowHue, 0.8, 1)
    end
    return CONFIG.THEME.Primary
end

local function Tween(obj, props, duration)
    if not obj or not obj.Parent then return end
    TweenService:Create(obj, TweenInfo.new(duration or 0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), props):Play()
end

local function Notify(text, color, duration)
    task.spawn(function()
        if not STATE.GUI then return end
        
        local notif = Instance.new("Frame")
        notif.Size = UDim2.new(0, 350, 0, 70)
        notif.Position = UDim2.new(1, 10, 1, -80)
        notif.BackgroundColor3 = CONFIG.THEME.Surface
        notif.BorderSizePixel = 0
        notif.ZIndex = 10
        notif.Parent = STATE.GUI
        
        local corner = Instance.new("UICorner", notif)
        corner.CornerRadius = UDim.new(0, 12)
        
        local gradient = Instance.new("UIGradient", notif)
        gradient.Color = ColorSequence.new{
            ColorSequenceKeypoint.new(0, color or GetThemeColor()),
            ColorSequenceKeypoint.new(1, CONFIG.THEME.Surface)
        }
        gradient.Rotation = 90
        
        local stroke = Instance.new("UIStroke", notif)
        stroke.Color = color or GetThemeColor()
        stroke.Thickness = 2
        stroke.Transparency = 0.5
        
        local icon = Instance.new("TextLabel")
        icon.Size = UDim2.new(0, 50, 1, 0)
        icon.BackgroundTransparency = 1
        icon.Text = "✦"
        icon.TextColor3 = color or GetThemeColor()
        icon.TextSize = 28
        icon.Font = Enum.Font.GothamBold
        icon.Parent = notif
        
        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(1, -60, 1, 0)
        label.Position = UDim2.new(0, 55, 0, 0)
        label.BackgroundTransparency = 1
        label.Text = text
        label.TextColor3 = CONFIG.THEME.Text
        label.TextSize = 14
        label.Font = Enum.Font.Gotham
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.TextYAlignment = Enum.TextYAlignment.Center
        label.TextWrapped = true
        label.Parent = notif
        
        Tween(notif, {Position = UDim2.new(1, -360, 1, -80)}, 0.4)
        
        task.wait(duration or 3)
        
        Tween(notif, {Position = UDim2.new(1, 10, 1, -80)}, 0.3)
        task.wait(0.3)
        
        if notif and notif.Parent then
            notif:Destroy()
        end
    end)
end

-- ════════════════════════════════════════════════════════════
-- SISTEMA DE KEYBINDS
-- ════════════════════════════════════════════════════════════
local function SetKeybind(functionName, key)
    STATE.Keybinds[functionName] = key
    Notify("Keybind definida: " .. functionName .. " → " .. key.Name, CONFIG.THEME.Success, 2)
end

local function CheckKeybind(input)
    for funcName, key in pairs(STATE.Keybinds) do
        if input.KeyCode == key then
            if funcName == "ToggleFly" then
                ToggleFly(not STATE.FlyEnabled)
            elseif funcName == "ToggleNoclip" then
                ToggleNoclip(not STATE.NoclipEnabled)
            elseif funcName == "ToggleSpeed" then
                ToggleSpeed(not STATE.SpeedEnabled)
            elseif funcName == "ToggleInvisible" then
                ToggleInvisible(not STATE.InvisibleEnabled)
            end
        end
    end
end

-- ════════════════════════════════════════════════════════════
-- FUNÇÕES DO PLAYER
-- ════════════════════════════════════════════════════════════
function ToggleFly(enabled)
    STATE.FlyEnabled = enabled
    
    if STATE.Connections.Fly then
        STATE.Connections.Fly:Disconnect()
        STATE.Connections.Fly = nil
    end
    
    local char = LocalPlayer.Character
    if not char then return end
    
    local root = char:FindFirstChild("HumanoidRootPart")
    local humanoid = char:FindFirstChildOfClass("Humanoid")
    
    if not root or not humanoid then return end
    
    if enabled then
        -- Criar tapete voador visual
        local carpet = Instance.new("Part")
        carpet.Name = "FlyingCarpet"
        carpet.Size = Vector3.new(4, 0.3, 6)
        carpet.Color = GetThemeColor()
        carpet.Material = Enum.Material.Neon
        carpet.CanCollide = false
        carpet.Anchored = false
        carpet.CFrame = root.CFrame - Vector3.new(0, 3, 0)
        carpet.Parent = workspace
        
        local mesh = Instance.new("SpecialMesh", carpet)
        mesh.MeshType = Enum.MeshType.Brick
        
        local weld = Instance.new("Weld")
        weld.Part0 = root
        weld.Part1 = carpet
        weld.C0 = CFrame.new(0, -3, 0)
        weld.Parent = carpet
        
        -- Sistema de voo
        local bodyGyro = Instance.new("BodyGyro", root)
        bodyGyro.Name = "FlyGyro"
        bodyGyro.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
        bodyGyro.P = 9e4
        
        local bodyVelocity = Instance.new("BodyVelocity", root)
        bodyVelocity.Name = "FlyVelocity"
        bodyVelocity.MaxForce = Vector3.new(9e9, 9e9, 9e9)
        bodyVelocity.Velocity = Vector3.zero
        
        -- Animação Superman
        local flyAnim = humanoid:LoadAnimation(Instance.new("Animation"))
        
        STATE.Connections.Fly = RunService.Heartbeat:Connect(function()
            if not char or not char.Parent or not root or not root.Parent then
                ToggleFly(false)
                return
            end
            
            local moveDir = Vector3.zero
            
            if UserInputService:IsKeyDown(Enum.KeyCode.W) then
                moveDir = moveDir + (Camera.CFrame.LookVector * STATE.FlySpeed)
            end
            if UserInputService:IsKeyDown(Enum.KeyCode.S) then
                moveDir = moveDir - (Camera.CFrame.LookVector * STATE.FlySpeed)
            end
            if UserInputService:IsKeyDown(Enum.KeyCode.A) then
                moveDir = moveDir - (Camera.CFrame.RightVector * STATE.FlySpeed)
            end
            if UserInputService:IsKeyDown(Enum.KeyCode.D) then
                moveDir = moveDir + (Camera.CFrame.RightVector * STATE.FlySpeed)
            end
            if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
                moveDir = moveDir + (Vector3.yAxis * STATE.FlySpeed)
            end
            if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then
                moveDir = moveDir - (Vector3.yAxis * STATE.FlySpeed)
            end
            
            bodyVelocity.Velocity = moveDir
            bodyGyro.CFrame = Camera.CFrame
            
            -- Efeito visual
            if carpet and STATE.RainbowEnabled then
                carpet.Color = GetThemeColor()
            end
        end)
        
        Notify("Fly ativado! Use WASD + Space/Shift", CONFIG.THEME.Success)
    else
        -- Remover objetos de voo
        if root then
            if root:FindFirstChild("FlyGyro") then root.FlyGyro:Destroy() end
            if root:FindFirstChild("FlyVelocity") then root.FlyVelocity:Destroy() end
        end
        
        for _, obj in pairs(workspace:GetChildren()) do
            if obj.Name == "FlyingCarpet" then
                obj:Destroy()
            end
        end
        
        Notify("Fly desativado", CONFIG.THEME.Error)
    end
end

function ToggleNoclip(enabled)
    STATE.NoclipEnabled = enabled
    
    if STATE.Connections.Noclip then
        STATE.Connections.Noclip:Disconnect()
        STATE.Connections.Noclip = nil
    end
    
    if enabled then
        STATE.Connections.Noclip = RunService.Stepped:Connect(function()
            local char = LocalPlayer.Character
            if char then
                for _, part in pairs(char:GetDescendants()) do
                    if part:IsA("BasePart") then
                        part.CanCollide = false
                    end
                end
            end
        end)
        Notify("Noclip ativado", CONFIG.THEME.Success)
    else
        local char = LocalPlayer.Character
        if char then
            for _, part in pairs(char:GetDescendants()) do
                if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
                    part.CanCollide = true
                end
            end
        end
        Notify("Noclip desativado", CONFIG.THEME.Error)
    end
end

function ToggleSpeed(enabled)
    STATE.SpeedEnabled = enabled
    
    if STATE.Connections.Speed then
        STATE.Connections.Speed:Disconnect()
        STATE.Connections.Speed = nil
    end
    
    if enabled then
        STATE.Connections.Speed = RunService.Heartbeat:Connect(function()
            local char = LocalPlayer.Character
            if char then
                local humanoid = char:FindFirstChildOfClass("Humanoid")
                if humanoid then
                    humanoid.WalkSpeed = STATE.WalkSpeed
                end
            end
        end)
        Notify("Velocidade customizada ativada", CONFIG.THEME.Success)
    else
        local char = LocalPlayer.Character
        if char then
            local humanoid = char:FindFirstChildOfClass("Humanoid")
            if humanoid then
                humanoid.WalkSpeed = 16
            end
        end
        Notify("Velocidade resetada", CONFIG.THEME.Error)
    end
end

function ToggleInvisible(enabled)
    STATE.InvisibleEnabled = enabled
    
    local char = LocalPlayer.Character
    if not char then return end
    
    if enabled then
        for _, part in pairs(char:GetDescendants()) do
            if part:IsA("BasePart") then
                part.Transparency = 1
                if part.Name == "Head" then
                    part.Transparency = 1
                    if part:FindFirstChild("face") then
                        part.face.Transparency = 1
                    end
                end
            elseif part:IsA("Decal") or part:IsA("Texture") then
                part.Transparency = 1
            end
        end
        Notify("Invisibilidade ativada", CONFIG.THEME.Success)
    else
        for _, part in pairs(char:GetDescendants()) do
            if part:IsA("BasePart") then
                if part.Name == "Head" then
                    part.Transparency = 0
                    if part:FindFirstChild("face") then
                        part.face.Transparency = 0
                    end
                elseif part.Name ~= "HumanoidRootPart" then
                    part.Transparency = 0
                end
            elseif part:IsA("Decal") or part:IsA("Texture") then
                part.Transparency = 0
            end
        end
        Notify("Invisibilidade desativada", CONFIG.THEME.Error)
    end
end

function ToggleGodMode(enabled)
    STATE.GodMode = enabled
    
    if STATE.Connections.GodMode then
        STATE.Connections.GodMode:Disconnect()
        STATE.Connections.GodMode = nil
    end
    
    if enabled then
        STATE.Connections.GodMode = RunService.Heartbeat:Connect(function()
            local char = LocalPlayer.Character
            if char then
                local humanoid = char:FindFirstChildOfClass("Humanoid")
                if humanoid and humanoid.Health < humanoid.MaxHealth then
                    humanoid.Health = humanoid.MaxHealth
                end
            end
        end)
        Notify("God Mode ativado", CONFIG.THEME.Success)
    else
        Notify("God Mode desativado", CONFIG.THEME.Error)
    end
end

function ToggleInfJump(enabled)
    STATE.InfJumpEnabled = enabled
    
    if STATE.Connections.InfJump then
        STATE.Connections.InfJump:Disconnect()
        STATE.Connections.InfJump = nil
    end
    
    if enabled then
        STATE.Connections.InfJump = UserInputService.JumpRequest:Connect(function()
            local char = LocalPlayer.Character
            if char then
                local humanoid = char:FindFirstChildOfClass("Humanoid")
                if humanoid then
                    humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
                end
            end
        end)
        Notify("Pulo Infinito ativado", CONFIG.THEME.Success)
    else
        Notify("Pulo Infinito desativado", CONFIG.THEME.Error)
    end
end

-- ════════════════════════════════════════════════════════════
-- FUNÇÕES ESP (CORRIGIDAS)
-- ════════════════════════════════════════════════════════════
local function ClearESP()
    for player, esp in pairs(STATE.ESPObjects) do
        if esp.Box then pcall(function() esp.Box:Remove() end) end
        if esp.Line then pcall(function() esp.Line:Remove() end) end
        if esp.Name then pcall(function() esp.Name:Remove() end) end
        if esp.Distance then pcall(function() esp.Distance:Remove() end) end
        if esp.Health then pcall(function() esp.Health:Remove() end) end
    end
    STATE.ESPObjects = {}
end

local function CreateESP(player)
    if player == LocalPlayer then return end
    if STATE.ESPObjects[player] then return end
    
    local esp = {
        Box = Drawing.new("Square"),
        Line = Drawing.new("Line"),
        Name = Drawing.new("Text"),
        Distance = Drawing.new("Text"),
        Health = Drawing.new("Line")
    }
    
    esp.Box.Visible = false
    esp.Box.Thickness = 2
    esp.Box.Filled = false
    esp.Box.Color = GetThemeColor()
    esp.Box.Transparency = 1
    
    esp.Line.Visible = false
    esp.Line.Thickness = 2
    esp.Line.Color = GetThemeColor()
    esp.Line.Transparency = 1
    
    esp.Name.Visible = false
    esp.Name.Size = 16
    esp.Name.Center = true
    esp.Name.Outline = true
    esp.Name.Color = Color3.new(1, 1, 1)
    esp.Name.Text = player.Name
    
    esp.Distance.Visible = false
    esp.Distance.Size = 14
    esp.Distance.Center = true
    esp.Distance.Outline = true
    esp.Distance.Color = Color3.new(1, 1, 0)
    
    esp.Health.Visible = false
    esp.Health.Thickness = 4
    esp.Health.Transparency = 1
    
    STATE.ESPObjects[player] = esp
end

local function UpdateESP()
    for player, esp in pairs(STATE.ESPObjects) do
        if not player or not player.Parent then
            ClearESP()
            return
        end
        
        local char = player.Character
        local root = char and char:FindFirstChild("HumanoidRootPart")
        local head = char and char:FindFirstChild("Head")
        local humanoid = char and char:FindFirstChildOfClass("Humanoid")
        
        if root and head and humanoid and humanoid.Health > 0 then
            local rootPos, onScreen = Camera:WorldToViewportPoint(root.Position)
            
            if onScreen and rootPos.Z > 0 then
                local headPos = Camera:WorldToViewportPoint(head.Position + Vector3.new(0, 0.5, 0))
                local legPos = Camera:WorldToViewportPoint(root.Position - Vector3.new(0, 3, 0))
                
                local height = math.abs(headPos.Y - legPos.Y)
                local width = height / 2
                
                -- Box ESP
                esp.Box.Size = Vector2.new(width, height)
                esp.Box.Position = Vector2.new(rootPos.X - width/2, rootPos.Y - height/2)
                esp.Box.Color = STATE.RainbowEnabled and GetThemeColor() or CONFIG.THEME.Primary
                esp.Box.Visible = true
                
                -- Line ESP
                esp.Line.From = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
                esp.Line.To = Vector2.new(rootPos.X, rootPos.Y)
                esp.Line.Color = STATE.RainbowEnabled and GetThemeColor() or CONFIG.THEME.Primary
                esp.Line.Visible = true
                
                -- Name ESP
                esp.Name.Position = Vector2.new(rootPos.X, headPos.Y - 25)
                esp.Name.Visible = true
                
                -- Distance ESP
                if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                    local distance = (LocalPlayer.Character.HumanoidRootPart.Position - root.Position).Magnitude
                    esp.Distance.Text = string.format("[%.0f studs]", distance)
                    esp.Distance.Position = Vector2.new(rootPos.X, legPos.Y + 5)
                    esp.Distance.Visible = true
                end
                
                -- Health Bar
                local healthPercent = humanoid.Health / humanoid.MaxHealth
                local barHeight = height * healthPercent
                esp.Health.From = Vector2.new(rootPos.X - width/2 - 8, rootPos.Y + height/2)
                esp.Health.To = Vector2.new(rootPos.X - width/2 - 8, rootPos.Y + height/2 - barHeight)
                esp.Health.Color = Color3.new(1 - healthPercent, healthPercent, 0)
                esp.Health.Visible = true
            else
                esp.Box.Visible = false
                esp.Line.Visible = false
                esp.Name.Visible = false
                esp.Distance.Visible = false
                esp.Health.Visible = false
            end
        else
            esp.Box.Visible = false
            esp.Line.Visible = false
            esp.Name.Visible = false
            esp.Distance.Visible = false
            esp.Health.Visible = false
        end
    end
end

function ToggleESP(enabled)
    STATE.ESPEnabled = enabled
    
    if STATE.Connections.ESP then
        STATE.Connections.ESP:Disconnect()
        STATE.Connections.ESP = nil
    end
    
    if enabled then
        for _, player in pairs(Players:GetPlayers()) do
            CreateESP(player)
        end
        
        STATE.Connections.ESP = RunService.RenderStepped:Connect(UpdateESP)
        Notify("ESP ativado", CONFIG.THEME.Success)
    else
        ClearESP()
        Notify("ESP desativado", CONFIG.THEME.Error)
    end
end

-- ════════════════════════════════════════════════════════════
-- FUNÇÕES VISUAIS
-- ════════════════════════════════════════════════════════════
function ToggleFullbright(enabled)
    STATE.FullbrightEnabled = enabled
    
    if enabled then
        Lighting.Brightness = 3
        Lighting.ClockTime = 14
        Lighting.FogEnd = 1e10
        Lighting.GlobalShadows = false
        Lighting.OutdoorAmbient = Color3.new(1, 1, 1)
        Notify("Fullbright ativado", CONFIG.THEME.Success)
    else
        Lighting.Brightness = 1
        Lighting.FogEnd = 1e5
        Lighting.GlobalShadows = true
        Lighting.OutdoorAmbient = Color3.new(0.5, 0.5, 0.5)
        Notify("Fullbright desativado", CONFIG.THEME.Error)
    end
end

-- ════════════════════════════════════════════════════════════
-- FUNÇÕES PARA OUTROS JOGADORES (CORRIGIDAS)
-- ════════════════════════════════════════════════════════════
local function KillPlayer()
    if not STATE.SelectedPlayer then
        Notify("Selecione um jogador primeiro!", CONFIG.THEME.Warning)
        return
    end
    
    local targetChar = STATE.SelectedPlayer.Character
    if targetChar then
        local humanoid = targetChar:FindFirstChildOfClass("Humanoid")
        if humanoid then
            -- Tenta várias abordagens
            pcall(function()
                humanoid.Health = 0
                humanoid:TakeDamage(humanoid.MaxHealth)
            end)
            
            pcall(function()
                targetChar:BreakJoints()
            end)
            
            Notify("Tentativa de eliminar " .. STATE.SelectedPlayer.Name, CONFIG.THEME.Success)
        end
    end
end

local function FlingPlayer()
    if not STATE.SelectedPlayer then
        Notify("Selecione um jogador primeiro!", CONFIG.THEME.Warning)
        return
    end
    
    local targetChar = STATE.SelectedPlayer.Character
    if targetChar then
        local root = targetChar:FindFirstChild("HumanoidRootPart")
        if root then
            local bv = Instance.new("BodyVelocity")
            bv.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
            bv.Velocity = Vector3.new(
                math.random(-500, 500),
                1000,
                math.random(-500, 500)
            )
            bv.Parent = root
            
            task.delay(0.1, function()
                if bv and bv.Parent then
                    bv:Destroy()
                end
            end)
            
            Notify("Arremessando " .. STATE.SelectedPlayer.Name, CONFIG.THEME.Success)
        end
    end
end

local function TeleportToPlayer()
    if not STATE.SelectedPlayer then
        Notify("Selecione um jogador primeiro!", CONFIG.THEME.Warning)
        return
    end
    
    local char = LocalPlayer.Character
    local targetChar = STATE.SelectedPlayer.Character
    
    if char and targetChar then
        local root = char:FindFirstChild("HumanoidRootPart")
        local targetRoot = targetChar:FindFirstChild("HumanoidRootPart")
        
        if root and targetRoot then
            root.CFrame = targetRoot.CFrame * CFrame.new(0, 0, 3)
            Notify("Teleportado para " .. STATE.SelectedPlayer.Name, CONFIG.THEME.Success)
        end
    end
end

-- ════════════════════════════════════════════════════════════
-- SISTEMA DE SPAWN (PROPS E OBJETOS)
-- ════════════════════════════════════════════════════════════
local function SpawnProp(propType)
    local char = LocalPlayer.Character
    if not char then return end
    
    local root = char:FindFirstChild("HumanoidRootPart")
    if not root then return end
    
    local prop
    local spawnPos = root.CFrame * CFrame.new(0, 0, -5)
    
    if propType == "Platform" then
        prop = Instance.new("Part")
        prop.Size = Vector3.new(10, 1, 10)
        prop.Material = Enum.Material.Neon
        prop.Color = GetThemeColor()
        prop.Anchored = true
        prop.CFrame = spawnPos
        
    elseif propType == "Wall" then
        prop = Instance.new("Part")
        prop.Size = Vector3.new(15, 10, 1)
        prop.Material = Enum.Material.ForceField
        prop.Color = GetThemeColor()
        prop.Transparency = 0.3
        prop.Anchored = true
        prop.CFrame = spawnPos
        
    elseif propType == "Sphere" then
        prop = Instance.new("Part")
        prop.Shape = Enum.PartType.Ball
        prop.Size = Vector3.new(5, 5, 5)
        prop.Material = Enum.Material.Neon
        prop.Color = GetThemeColor()
        prop.Anchored = false
        prop.CFrame = spawnPos
        
        local light = Instance.new("PointLight", prop)
        light.Color = GetThemeColor()
        light.Brightness = 5
        light.Range = 20
        
    elseif propType == "Ramp" then
        prop = Instance.new("Part")
        prop.Size = Vector3.new(10, 1, 15)
        prop.Material = Enum.Material.SmoothPlastic
        prop.Color = GetThemeColor()
        prop.Anchored = true
        prop.CFrame = spawnPos * CFrame.Angles(math.rad(30), 0, 0)
        
        local mesh = Instance.new("SpecialMesh", prop)
        mesh.MeshType = Enum.MeshType.Wedge
    end
    
    if prop then
        prop.Parent = workspace
        prop.Name = "SHAKA_Prop"
        table.insert(STATE.SpawnedObjects, prop)
        
        Notify("Prop spawnado: " .. propType, CONFIG.THEME.Success)
        
        -- Auto-destruir depois de 30 segundos
        task.delay(30, function()
            if prop and prop.Parent then
                prop:Destroy()
            end
        end)
    end
end

local function ClearProps()
    for _, prop in pairs(STATE.SpawnedObjects) do
        if prop and prop.Parent then
            prop:Destroy()
        end
    end
    STATE.SpawnedObjects = {}
    
    for _, obj in pairs(workspace:GetChildren()) do
        if obj.Name == "SHAKA_Prop" then
            obj:Destroy()
        end
    end
    
    Notify("Todos os props foram removidos", CONFIG.THEME.Success)
end

-- ════════════════════════════════════════════════════════════
-- CRIAÇÃO DA GUI (REDESENHADA)
-- ════════════════════════════════════════════════════════════
local function CreateButton(text, callback, parent)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, -10, 0, 42)
    btn.BackgroundColor3 = CONFIG.THEME.Surface
    btn.Text = text
    btn.TextColor3 = CONFIG.THEME.Text
    btn.TextSize = 14
    btn.Font = Enum.Font.GothamBold
    btn.BorderSizePixel = 0
    btn.Parent = parent
    
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 10)
    
    local stroke = Instance.new("UIStroke", btn)
    stroke.Color = GetThemeColor()
    stroke.Thickness = 1.5
    stroke.Transparency = 0.7
    
    btn.MouseEnter:Connect(function()
        Tween(btn, {BackgroundColor3 = CONFIG.THEME.Primary}, 0.2)
        Tween(stroke, {Transparency = 0}, 0.2)
    end)
    
    btn.MouseLeave:Connect(function()
        Tween(btn, {BackgroundColor3 = CONFIG.THEME.Surface}, 0.2)
        Tween(stroke, {Transparency = 0.7}, 0.2)
    end)
    
    btn.MouseButton1Click:Connect(callback)
    
    return btn
end

local function CreateToggle(name, desc, state, callback, parent)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, -10, 0, 70)
    frame.BackgroundColor3 = CONFIG.THEME.Surface
    frame.BorderSizePixel = 0
    frame.Parent = parent
    
    Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 10)
    
    local stroke = Instance.new("UIStroke", frame)
    stroke.Color = GetThemeColor()
    stroke.Thickness = 1.5
    stroke.Transparency = 0.8
    
    local nameLabel = Instance.new("TextLabel")
    nameLabel.Size = UDim2.new(0.7, 0, 0, 28)
    nameLabel.Position = UDim2.new(0, 15, 0, 8)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text = name
    nameLabel.TextColor3 = CONFIG.THEME.Text
    nameLabel.TextSize = 15
    nameLabel.Font = Enum.Font.GothamBold
    nameLabel.TextXAlignment = Enum.TextXAlignment.Left
    nameLabel.Parent = frame
    
    local descLabel = Instance.new("TextLabel")
    descLabel.Size = UDim2.new(0.7, 0, 0, 22)
    descLabel.Position = UDim2.new(0, 15, 0, 40)
    descLabel.BackgroundTransparency = 1
    descLabel.Text = desc
    descLabel.TextColor3 = CONFIG.THEME.TextDim
    descLabel.TextSize = 12
    descLabel.Font = Enum.Font.Gotham
    descLabel.TextXAlignment = Enum.TextXAlignment.Left
    descLabel.Parent = frame
    
    local toggleBtn = Instance.new("TextButton")
    toggleBtn.Size = UDim2.new(0, 60, 0, 30)
    toggleBtn.Position = UDim2.new(1, -75, 0.5, -15)
    toggleBtn.BackgroundColor3 = state and GetThemeColor() or Color3.fromRGB(60, 60, 70)
    toggleBtn.Text = ""
    toggleBtn.BorderSizePixel = 0
    toggleBtn.Parent = frame
    
    Instance.new("UICorner", toggleBtn).CornerRadius = UDim.new(0, 15)
    
    local knob = Instance.new("Frame")
    knob.Size = UDim2.new(0, 24, 0, 24)
    knob.Position = state and UDim2.new(0, 33, 0, 3) or UDim2.new(0, 3, 0, 3)
    knob.BackgroundColor3 = CONFIG.THEME.Text
    knob.BorderSizePixel = 0
    knob.Parent = toggleBtn
    
    Instance.new("UICorner", knob).CornerRadius = UDim.new(0, 12)
    
    toggleBtn.MouseButton1Click:Connect(function()
        state = not state
        
        if state then
            Tween(toggleBtn, {BackgroundColor3 = GetThemeColor()}, 0.2)
            Tween(knob, {Position = UDim2.new(0, 33, 0, 3)}, 0.2)
        else
            Tween(toggleBtn, {BackgroundColor3 = Color3.fromRGB(60, 60, 70)}, 0.2)
            Tween(knob, {Position = UDim2.new(0, 3, 0, 3)}, 0.2)
        end
        
        callback(state)
    end)
    
    return frame
end

local function CreateSlider(name, min, max, default, callback, parent)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, -10, 0, 80)
    frame.BackgroundColor3 = CONFIG.THEME.Surface
    frame.BorderSizePixel = 0
    frame.Parent = parent
    
    Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 10)
    
    local stroke = Instance.new("UIStroke", frame)
    stroke.Color = GetThemeColor()
    stroke.Thickness = 1.5
    stroke.Transparency = 0.8
    
    local nameLabel = Instance.new("TextLabel")
    nameLabel.Size = UDim2.new(0.6, 0, 0, 28)
    nameLabel.Position = UDim2.new(0, 15, 0, 8)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text = name
    nameLabel.TextColor3 = CONFIG.THEME.Text
    nameLabel.TextSize = 15
    nameLabel.Font = Enum.Font.GothamBold
    nameLabel.TextXAlignment = Enum.TextXAlignment.Left
    nameLabel.Parent = frame
    
    local valueLabel = Instance.new("TextLabel")
    valueLabel.Size = UDim2.new(0.35, 0, 0, 28)
    valueLabel.Position = UDim2.new(0.65, 0, 0, 8)
    valueLabel.BackgroundTransparency = 1
    valueLabel.Text = tostring(default)
    valueLabel.TextColor3 = GetThemeColor()
    valueLabel.TextSize = 15
    valueLabel.Font = Enum.Font.GothamBold
    valueLabel.TextXAlignment = Enum.TextXAlignment.Right
    valueLabel.Parent = frame
    
    local track = Instance.new("Frame")
    track.Size = UDim2.new(1, -30, 0, 8)
    track.Position = UDim2.new(0, 15, 0, 52)
    track.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
    track.BorderSizePixel = 0
    track.Parent = frame
    
    Instance.new("UICorner", track).CornerRadius = UDim.new(0, 4)
    
    local fill = Instance.new("Frame")
    fill.Size = UDim2.new((default - min) / (max - min), 0, 1, 0)
    fill.BackgroundColor3 = GetThemeColor()
    fill.BorderSizePixel = 0
    fill.Parent = track
    
    Instance.new("UICorner", fill).CornerRadius = UDim.new(0, 4)
    
    local knob = Instance.new("Frame")
    knob.Size = UDim2.new(0, 20, 0, 20)
    knob.Position = UDim2.new((default - min) / (max - min), -10, 0.5, -10)
    knob.BackgroundColor3 = CONFIG.THEME.Text
    knob.BorderSizePixel = 0
    knob.Parent = track
    
    Instance.new("UICorner", knob).CornerRadius = UDim.new(0, 10)
    
    local knobStroke = Instance.new("UIStroke", knob)
    knobStroke.Color = GetThemeColor()
    knobStroke.Thickness = 3
    
    local dragging = false
    
    local function update(input)
        local pos = math.clamp((input.Position.X - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
        local value = math.floor(min + (max - min) * pos)
        
        fill.Size = UDim2.new(pos, 0, 1, 0)
        knob.Position = UDim2.new(pos, -10, 0.5, -10)
        valueLabel.Text = tostring(value)
        
        callback(value)
    end
    
    knob.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
        end
    end)
    
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
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
    
    return frame
end

local function CreateGUI()
    if STATE.GUI then
        STATE.GUI:Destroy()
    end
    
    local gui = Instance.new("ScreenGui")
    gui.Name = "SHAKA_Premium"
    gui.ResetOnSpawn = false
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    gui.Parent = LocalPlayer:WaitForChild("PlayerGui")
    
    STATE.GUI = gui
    
    -- Main Frame com animação de entrada
    local main = Instance.new("Frame")
    main.Size = UDim2.new(0, 800, 0, 550)
    main.Position = UDim2.new(0.5, -400, 0.5, -275)
    main.BackgroundColor3 = CONFIG.THEME.Background
    main.BorderSizePixel = 0
    main.Parent = gui
    
    Instance.new("UICorner", main).CornerRadius = UDim.new(0, 16)
    
    local mainStroke = Instance.new("UIStroke", main)
    mainStroke.Color = GetThemeColor()
    mainStroke.Thickness = 2
    mainStroke.Transparency = 0.5
    
    -- Header com gradiente
    local header = Instance.new("Frame")
    header.Size = UDim2.new(1, 0, 0, 60)
    header.BackgroundColor3 = CONFIG.THEME.Surface
    header.BorderSizePixel = 0
    header.Parent = main
    
    Instance.new("UICorner", header).CornerRadius = UDim.new(0, 16)
    
    local headerGradient = Instance.new("UIGradient", header)
    headerGradient.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, GetThemeColor()),
        ColorSequenceKeypoint.new(1, CONFIG.THEME.Surface)
    }
    headerGradient.Rotation = 90
    
    local logo = Instance.new("TextLabel")
    logo.Size = UDim2.new(0, 200, 1, 0)
    logo.Position = UDim2.new(0, 20, 0, 0)
    logo.BackgroundTransparency = 1
    logo.Text = "✦ SHAKA PREMIUM"
    logo.TextColor3 = CONFIG.THEME.Text
    logo.TextSize = 24
    logo.Font = Enum.Font.GothamBold
    logo.TextXAlignment = Enum.TextXAlignment.Left
    logo.Parent = header
    
    local version = Instance.new("TextLabel")
    version.Size = UDim2.new(0, 80, 0, 30)
    version.Position = UDim2.new(0, 230, 0, 15)
    version.BackgroundColor3 = CONFIG.THEME.Primary
    version.Text = "v" .. CONFIG.VERSION
    version.TextColor3 = CONFIG.THEME.Text
    version.TextSize = 14
    version.Font = Enum.Font.GothamBold
    version.BorderSizePixel = 0
    version.Parent = header
    
    Instance.new("UICorner", version).CornerRadius = UDim.new(0, 8)
    
    local closeBtn = Instance.new("TextButton")
    closeBtn.Size = UDim2.new(0, 40, 0, 40)
    closeBtn.Position = UDim2.new(1, -50, 0, 10)
    closeBtn.BackgroundColor3 = CONFIG.THEME.Error
    closeBtn.Text = "×"
    closeBtn.TextColor3 = CONFIG.THEME.Text
    closeBtn.TextSize = 28
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.BorderSizePixel = 0
    closeBtn.Parent = header
    
    Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 10)
    
    closeBtn.MouseButton1Click:Connect(function()
        Tween(main, {Size = UDim2.new(0, 0, 0, 0), Position = UDim2.new(0.5, 0, 0.5, 0)}, 0.3)
        task.wait(0.3)
        gui:Destroy()
        STATE.GUI = nil
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
    
    -- Lista de jogadores (sidebar)
    local playerList = Instance.new("Frame")
    playerList.Size = UDim2.new(0, 250, 1, -70)
    playerList.Position = UDim2.new(0, 10, 0, 65)
    playerList.BackgroundColor3 = CONFIG.THEME.Surface
    playerList.BorderSizePixel = 0
    playerList.Parent = main
    
    Instance.new("UICorner", playerList).CornerRadius = UDim.new(0, 12)
    
    local plTitle = Instance.new("TextLabel")
    plTitle.Size = UDim2.new(1, 0, 0, 40)
    plTitle.BackgroundColor3 = GetThemeColor()
    plTitle.Text = "JOGADORES ONLINE"
    plTitle.TextColor3 = CONFIG.THEME.Text
    plTitle.TextSize = 14
    plTitle.Font = Enum.Font.GothamBold
    plTitle.BorderSizePixel = 0
    plTitle.Parent = playerList
    
    Instance.new("UICorner", plTitle).CornerRadius = UDim.new(0, 12)
    
    local selectedLabel = Instance.new("TextLabel")
    selectedLabel.Size = UDim2.new(1, -10, 0, 35)
    selectedLabel.Position = UDim2.new(0, 5, 0, 45)
    selectedLabel.BackgroundColor3 = CONFIG.THEME.Background
    selectedLabel.Text = "Nenhum selecionado"
    selectedLabel.TextColor3 = CONFIG.THEME.TextDim
    selectedLabel.TextSize = 12
    selectedLabel.Font = Enum.Font.GothamBold
    selectedLabel.BorderSizePixel = 0
    selectedLabel.Parent = playerList
    
    Instance.new("UICorner", selectedLabel).CornerRadius = UDim.new(0, 8)
    
    local playerScroll = Instance.new("ScrollingFrame")
    playerScroll.Size = UDim2.new(1, -10, 1, -90)
    playerScroll.Position = UDim2.new(0, 5, 0, 85)
    playerScroll.BackgroundTransparency = 1
    playerScroll.BorderSizePixel = 0
    playerScroll.ScrollBarThickness = 4
    playerScroll.ScrollBarImageColor3 = GetThemeColor()
    playerScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    playerScroll.Parent = playerList
    
    local plLayout = Instance.new("UIListLayout", playerScroll)
    plLayout.Padding = UDim.new(0, 5)
    plLayout.SortOrder = Enum.SortOrder.Name
    
    plLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        playerScroll.CanvasSize = UDim2.new(0, 0, 0, plLayout.AbsoluteContentSize.Y + 5)
    end)
    
    local function UpdatePlayerList()
        playerScroll:ClearAllChildren()
        
        local plLayout = Instance.new("UIListLayout", playerScroll)
        plLayout.Padding = UDim.new(0, 5)
        plLayout.SortOrder = Enum.SortOrder.Name
        
        plLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            playerScroll.CanvasSize = UDim2.new(0, 0, 0, plLayout.AbsoluteContentSize.Y + 5)
        end)
        
        for _, player in pairs(Players:GetPlayers()) do
            if player ~= LocalPlayer then
                local btn = Instance.new("TextButton")
                btn.Size = UDim2.new(1, -5, 0, 40)
                btn.BackgroundColor3 = CONFIG.THEME.Background
                btn.Text = "  " .. player.Name
                btn.TextColor3 = CONFIG.THEME.Text
                btn.TextSize = 13
                btn.Font = Enum.Font.Gotham
                btn.TextXAlignment = Enum.TextXAlignment.Left
                btn.BorderSizePixel = 0
                btn.Parent = playerScroll
                
                Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)
                
                if STATE.SelectedPlayer == player then
                    btn.BackgroundColor3 = GetThemeColor()
                end
                
                btn.MouseButton1Click:Connect(function()
                    STATE.SelectedPlayer = player
                    selectedLabel.Text = player.Name
                    selectedLabel.TextColor3 = GetThemeColor()
                    UpdatePlayerList()
                end)
            end
        end
    end
    
    UpdatePlayerList()
    task.spawn(function()
        while STATE.GUI do
            task.wait(2)
            UpdatePlayerList()
        end
    end)
    
    -- Tabs
    local tabContainer = Instance.new("Frame")
    tabContainer.Size = UDim2.new(1, -270, 1, -70)
    tabContainer.Position = UDim2.new(0, 265, 0, 65)
    tabContainer.BackgroundTransparency = 1
    tabContainer.BorderSizePixel = 0
    tabContainer.Parent = main
    
    local tabBar = Instance.new("Frame")
    tabBar.Size = UDim2.new(1, 0, 0, 45)
    tabBar.BackgroundTransparency = 1
    tabBar.BorderSizePixel = 0
    tabBar.Parent = tabContainer
    
    local tabBarLayout = Instance.new("UIListLayout", tabBar)
    tabBarLayout.FillDirection = Enum.FillDirection.Horizontal
    tabBarLayout.Padding = UDim.new(0, 5)
    
    local tabContent = Instance.new("Frame")
    tabContent.Size = UDim2.new(1, 0, 1, -50)
    tabContent.Position = UDim2.new(0, 0, 0, 50)
    tabContent.BackgroundTransparency = 1
    tabContent.BorderSizePixel = 0
    tabContent.Parent = tabContainer
    
    local tabs = {
        {Name = "Player", Icon = "🎮"},
        {Name = "Combat", Icon = "⚔️"},
        {Name = "Teleport", Icon = "🌀"},
        {Name = "Visual", Icon = "✨"},
        {Name = "Spawn", Icon = "🎨"},
        {Name = "Settings", Icon = "⚙️"}
    }
    
    local tabFrames = {}
    
    for i, tab in ipairs(tabs) do
        local tabBtn = Instance.new("TextButton")
        tabBtn.Size = UDim2.new(0, 85, 0, 40)
        tabBtn.BackgroundColor3 = CONFIG.THEME.Surface
        tabBtn.Text = tab.Icon .. " " .. tab.Name
        tabBtn.TextColor3 = CONFIG.THEME.Text
        tabBtn.TextSize = 13
        tabBtn.Font = Enum.Font.GothamBold
        tabBtn.BorderSizePixel = 0
        tabBtn.Parent = tabBar
        
        Instance.new("UICorner", tabBtn).CornerRadius = UDim.new(0, 10)
        
        local tabFrame = Instance.new("ScrollingFrame")
        tabFrame.Size = UDim2.new(1, 0, 1, 0)
        tabFrame.BackgroundTransparency = 1
        tabFrame.BorderSizePixel = 0
        tabFrame.ScrollBarThickness = 4
        tabFrame.ScrollBarImageColor3 = GetThemeColor()
        tabFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
        tabFrame.Visible = (i == 1)
        tabFrame.Parent = tabContent
        
        local layout = Instance.new("UIListLayout", tabFrame)
        layout.Padding = UDim.new(0, 10)
        layout.SortOrder = Enum.SortOrder.LayoutOrder
        
        layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            tabFrame.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 10)
        end)
        
        tabFrames[tab.Name] = tabFrame
        
        if i == 1 then
            tabBtn.BackgroundColor3 = GetThemeColor()
        end
        
        tabBtn.MouseButton1Click:Connect(function()
            for _, frame in pairs(tabFrames) do
                frame.Visible = false
            end
            tabFrame.Visible = true
            
            for _, btn in pairs(tabBar:GetChildren()) do
                if btn:IsA("TextButton") then
                    Tween(btn, {BackgroundColor3 = CONFIG.THEME.Surface}, 0.2)
                end
            end
            Tween(tabBtn, {BackgroundColor3 = GetThemeColor()}, 0.2)
        end)
    end
    
    -- CONTEÚDO DAS ABAS
    
    -- Player Tab
    CreateToggle("Fly Mode", "Voar com tapete mágico", STATE.FlyEnabled, ToggleFly, tabFrames["Player"])
    CreateSlider("Velocidade Fly", 10, 200, STATE.FlySpeed, function(value)
        STATE.FlySpeed = value
    end, tabFrames["Player"])
    
    CreateToggle("Noclip", "Atravessar paredes", STATE.NoclipEnabled, ToggleNoclip, tabFrames["Player"])
    CreateToggle("Speed Boost", "Velocidade customizada", STATE.SpeedEnabled, ToggleSpeed, tabFrames["Player"])
    
    CreateSlider("Walk Speed", 16, 500, STATE.WalkSpeed, function(value)
        STATE.WalkSpeed = value
    end, tabFrames["Player"])
    
    CreateToggle("Infinite Jump", "Pular infinitamente", STATE.InfJumpEnabled, ToggleInfJump, tabFrames["Player"])
    CreateToggle("God Mode", "Imortalidade", STATE.GodMode, ToggleGodMode, tabFrames["Player"])
    CreateToggle("Invisible", "Ficar invisível", STATE.InvisibleEnabled, ToggleInvisible, tabFrames["Player"])
    
    CreateButton("🔄 Resetar Personagem", function()
        if LocalPlayer.Character then
            LocalPlayer.Character:BreakJoints()
        end
    end, tabFrames["Player"])
    
    -- Combat Tab
    CreateButton("💀 Eliminar Jogador", KillPlayer, tabFrames["Combat"])
    CreateButton("🌪️ Fling Player", FlingPlayer, tabFrames["Combat"])
    CreateButton("🔥 Explodir Jogador", function()
        if not STATE.SelectedPlayer then
            Notify("Selecione um jogador!", CONFIG.THEME.Warning)
            return
        end
        
        local targetChar = STATE.SelectedPlayer.Character
        if targetChar and targetChar:FindFirstChild("HumanoidRootPart") then
            local explosion = Instance.new("Explosion")
            explosion.Position = targetChar.HumanoidRootPart.Position
            explosion.BlastRadius = 30
            explosion.BlastPressure = 1000000
            explosion.Parent = workspace
            
            Notify("Explosão criada!", CONFIG.THEME.Success)
        end
    end, tabFrames["Combat"])
    
    -- Teleport Tab
    CreateButton("🚀 Teleport para Jogador", TeleportToPlayer, tabFrames["Teleport"])
    CreateButton("🏠 Voltar ao Spawn", function()
        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
            LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(0, 50, 0)
            Notify("Teleportado para spawn", CONFIG.THEME.Success)
        end
    end, tabFrames["Teleport"])
    
    -- Visual Tab
    CreateToggle("Fullbright", "Iluminação máxima", STATE.FullbrightEnabled, ToggleFullbright, tabFrames["Visual"])
    CreateToggle("ESP", "Ver jogadores através das paredes", STATE.ESPEnabled, ToggleESP, tabFrames["Visual"])
    
    CreateSlider("FOV", 70, 120, Camera.FieldOfView, function(value)
        Camera.FieldOfView = value
    end, tabFrames["Visual"])
    
    CreateButton("🌈 Modo Rainbow", function()
        STATE.RainbowEnabled = not STATE.RainbowEnabled
        
        if STATE.RainbowEnabled then
            if STATE.Connections.Rainbow then
                STATE.Connections.Rainbow:Disconnect()
            end
            
            STATE.Connections.Rainbow = RunService.Heartbeat:Connect(function()
                STATE.RainbowHue = (STATE.RainbowHue + 0.005) % 1
            end)
            
            Notify("Modo Rainbow ativado!", CONFIG.THEME.Success)
        else
            if STATE.Connections.Rainbow then
                STATE.Connections.Rainbow:Disconnect()
                STATE.Connections.Rainbow = nil
            end
            Notify("Modo Rainbow desativado", CONFIG.THEME.Error)
        end
    end, tabFrames["Visual"])
    
    -- Spawn Tab
    CreateButton("🟦 Spawn Platform", function() SpawnProp("Platform") end, tabFrames["Spawn"])
    CreateButton("🧱 Spawn Wall", function() SpawnProp("Wall") end, tabFrames["Spawn"])
    CreateButton("⚪ Spawn Sphere", function() SpawnProp("Sphere") end, tabFrames["Spawn"])
    CreateButton("📐 Spawn Ramp", function() SpawnProp("Ramp") end, tabFrames["Spawn"])
    CreateButton("🗑️ Limpar Todos Props", ClearProps, tabFrames["Spawn"])
    
    -- Settings Tab
    CreateButton("⌨️ Definir Keybind Fly [C]", function()
        SetKeybind("ToggleFly", Enum.KeyCode.C)
    end, tabFrames["Settings"])
    
    CreateButton("⌨️ Definir Keybind Noclip [V]", function()
        SetKeybind("ToggleNoclip", Enum.KeyCode.V)
    end, tabFrames["Settings"])
    
    CreateButton("⌨️ Definir Keybind Speed [X]", function()
        SetKeybind("ToggleSpeed", Enum.KeyCode.X)
    end, tabFrames["Settings"])
    
    CreateButton("⌨️ Definir Keybind Invisível [B]", function()
        SetKeybind("ToggleInvisible", Enum.KeyCode.B)
    end, tabFrames["Settings"])
    
    CreateButton("📋 Informações do Sistema", function()
        local info = string.format(
            "SHAKA Premium v%s\nFPS: %d\nJogadores: %d/%d\nPing: %d ms",
            CONFIG.VERSION,
            math.floor(workspace:GetRealPhysicsFPS()),
            #Players:GetPlayers(),
            Players.MaxPlayers,
            math.floor(LocalPlayer:GetNetworkPing() * 1000)
        )
        Notify(info, CONFIG.THEME.Primary, 5)
    end, tabFrames["Settings"])
    
    -- Animação de entrada
    main.Size = UDim2.new(0, 0, 0, 0)
    main.Position = UDim2.new(0.5, 0, 0.5, 0)
    Tween(main, {
        Size = UDim2.new(0, 800, 0, 550),
        Position = UDim2.new(0.5, -400, 0.5, -275)
    }, 0.5)
    
    Notify("SHAKA Premium v" .. CONFIG.VERSION .. " carregado!", CONFIG.THEME.Success, 3)
end

-- ════════════════════════════════════════════════════════════
-- INICIALIZAÇÃO
-- ════════════════════════════════════════════════════════════
print("════════════════════════════════════════")
print("  SHAKA Premium v" .. CONFIG.VERSION)
print("  Pressione INSERT para abrir o menu")
print("════════════════════════════════════════")

CreateGUI()

-- Keybind para abrir/fechar menu
UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    
    if input.KeyCode == CONFIG.MENU_KEY then
        if STATE.GUI then
            local main = STATE.GUI:FindFirstChild("Frame")
            if main then
                Tween(main, {
                    Size = UDim2.new(0, 0, 0, 0),
                    Position = UDim2.new(0.5, 0, 0.5, 0)
                }, 0.3)
                task.wait(0.3)
            end
            STATE.GUI:Destroy()
            STATE.GUI = nil
        else
            CreateGUI()
        end
    else
        CheckKeybind(input)
    end
end)

-- Reconectar funções após reset
LocalPlayer.CharacterAdded:Connect(function()
    task.wait(1)
    
    if STATE.FlyEnabled then ToggleFly(true) end
    if STATE.NoclipEnabled then ToggleNoclip(true) end
    if STATE.SpeedEnabled then ToggleSpeed(true) end
    if STATE.InfJumpEnabled then ToggleInfJump(true) end
    if STATE.GodMode then ToggleGodMode(true) end
    if STATE.InvisibleEnabled then ToggleInvisible(true) end
    if STATE.ESPEnabled then ToggleESP(true) end
    if STATE.FullbrightEnabled then ToggleFullbright(true) end
end)

-- Atualizar jogadores ESP
Players.PlayerAdded:Connect(function(player)
    if STATE.ESPEnabled then
        task.wait(1)
        CreateESP(player)
    end
end)

Players.PlayerRemoving:Connect(function(player)
    if STATE.ESPObjects[player] then
        local esp = STATE.ESPObjects[player]
        pcall(function() if esp.Box then esp.Box:Remove() end end)
        pcall(function() if esp.Line then esp.Line:Remove() end end)
        pcall(function() if esp.Name then esp.Name:Remove() end end)
        pcall(function() if esp.Distance then esp.Distance:Remove() end end)
        pcall(function() if esp.Health then esp.Health:Remove() end end)
        STATE.ESPObjects[player] = nil
    end
end)

print("✅ SHAKA Premium carregado com sucesso!")
