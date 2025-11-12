-- ╔══════════════════════════════════════════════════════════╗
-- ║         SHAKA Hub ULTRA v3.0 - Design Minimalista       ║
-- ║              Desenvolvido por 2M | 2025                  ║
-- ╚══════════════════════════════════════════════════════════╝

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")
local Camera = workspace.CurrentCamera

-- ══════════════════════════════════════════════════════════
-- CONFIGURAÇÕES
-- ══════════════════════════════════════════════════════════
local CONFIG = {
    NOME = "SHAKA",
    VERSAO = "v3.0",
    COR_PRINCIPAL = Color3.fromRGB(139, 92, 246),
    COR_HOVER = Color3.fromRGB(167, 139, 250),
    COR_FUNDO = Color3.fromRGB(17, 24, 39),
    COR_FUNDO_2 = Color3.fromRGB(31, 41, 55),
    COR_FUNDO_3 = Color3.fromRGB(55, 65, 81),
    COR_TEXTO = Color3.fromRGB(243, 244, 246),
    COR_TEXTO_SEC = Color3.fromRGB(156, 163, 175),
    COR_SUCESSO = Color3.fromRGB(34, 197, 94),
    COR_ERRO = Color3.fromRGB(239, 68, 68),
    COR_AVISO = Color3.fromRGB(251, 191, 36)
}

-- ══════════════════════════════════════════════════════════
-- VARIÁVEIS GLOBAIS
-- ══════════════════════════════════════════════════════════
local GUI = nil
local Connections = {}
local SelectedPlayer = nil
local RainbowHue = 0
local UIElements = {}
local MenuScale = 1

local SavedStates = {
    FlyEnabled = false,
    FlySpeed = 100,
    NoclipEnabled = false,
    InfJumpEnabled = false,
    WalkSpeed = 16,
    JumpPower = 50,
    GodMode = false,
    ESPEnabled = false,
    ESPBox = true,
    ESPName = true,
    ESPDistance = true,
    ESPHealth = true,
    ESPTracers = true,
    Fullbright = false,
    FOV = 70,
    RainbowMode = false,
    MenuWidth = 550,
    MenuHeight = 420,
    AimbotEnabled = false,
    AimbotTeamCheck = true,
    AimbotVisibleCheck = true,
    AimbotSmoothing = 5,
    AimbotFOV = 200,
    AimbotShowFOV = true
}

local ESPObjects = {}
local AimbotTarget = nil

-- ══════════════════════════════════════════════════════════
-- FUNÇÕES AUXILIARES
-- ══════════════════════════════════════════════════════════
local function GetCurrentColor()
    if SavedStates.RainbowMode then
        return Color3.fromHSV(RainbowHue, 0.7, 0.96)
    else
        return CONFIG.COR_PRINCIPAL
    end
end

local function Tween(obj, props, time, style)
    if not obj or not obj.Parent then return end
    TweenService:Create(obj, TweenInfo.new(time or 0.25, style or Enum.EasingStyle.Quart, Enum.EasingDirection.Out), props):Play()
end

local function Notify(text, color, icon)
    task.spawn(function()
        if not GUI or not GUI.Parent then return end
        
        local notif = Instance.new("Frame")
        notif.Size = UDim2.new(0, 320, 0, 70)
        notif.Position = UDim2.new(1, 340, 0.85, -35)
        notif.BackgroundColor3 = CONFIG.COR_FUNDO_2
        notif.BorderSizePixel = 0
        notif.Parent = GUI
        notif.ZIndex = 10000
        
        Instance.new("UICorner", notif).CornerRadius = UDim.new(0, 10)
        
        local shadow = Instance.new("ImageLabel")
        shadow.Name = "Shadow"
        shadow.Size = UDim2.new(1, 30, 1, 30)
        shadow.Position = UDim2.new(0, -15, 0, -15)
        shadow.BackgroundTransparency = 1
        shadow.Image = "rbxasset://textures/ui/GuiImagePlaceholder.png"
        shadow.ImageColor3 = Color3.fromRGB(0, 0, 0)
        shadow.ImageTransparency = 0.7
        shadow.ScaleType = Enum.ScaleType.Slice
        shadow.SliceCenter = Rect.new(10, 10, 10, 10)
        shadow.ZIndex = notif.ZIndex - 1
        shadow.Parent = notif
        
        local accent = Instance.new("Frame")
        accent.Size = UDim2.new(0, 4, 1, 0)
        accent.BackgroundColor3 = color or GetCurrentColor()
        accent.BorderSizePixel = 0
        accent.Parent = notif
        
        Instance.new("UICorner", accent).CornerRadius = UDim.new(0, 10)
        
        local iconLabel = Instance.new("TextLabel")
        iconLabel.Size = UDim2.new(0, 40, 0, 40)
        iconLabel.Position = UDim2.new(0, 15, 0.5, -20)
        iconLabel.BackgroundTransparency = 1
        iconLabel.Text = icon or "✓"
        iconLabel.TextColor3 = color or GetCurrentColor()
        iconLabel.TextSize = 24
        iconLabel.Font = Enum.Font.GothamBold
        iconLabel.Parent = notif
        
        local textLabel = Instance.new("TextLabel")
        textLabel.Size = UDim2.new(1, -70, 1, 0)
        textLabel.Position = UDim2.new(0, 60, 0, 0)
        textLabel.BackgroundTransparency = 1
        textLabel.Text = text
        textLabel.TextColor3 = CONFIG.COR_TEXTO
        textLabel.TextSize = 13
        textLabel.Font = Enum.Font.Gotham
        textLabel.TextXAlignment = Enum.TextXAlignment.Left
        textLabel.TextWrapped = true
        textLabel.Parent = notif
        
        Tween(notif, {Position = UDim2.new(1, -340, 0.85, -35)}, 0.4, Enum.EasingStyle.Back)
        task.wait(3)
        Tween(notif, {Position = UDim2.new(1, 20, 0.85, -35)}, 0.3)
        task.wait(0.3)
        if notif and notif.Parent then notif:Destroy() end
    end)
end

-- ══════════════════════════════════════════════════════════
-- FUNÇÕES DO PLAYER
-- ══════════════════════════════════════════════════════════
local function ToggleFly(state)
    SavedStates.FlyEnabled = state
    
    if Connections.Fly then
        Connections.Fly:Disconnect()
        Connections.Fly = nil
    end
    
    local char = LocalPlayer.Character
    if not char then return end
    local root = char:FindFirstChild("HumanoidRootPart")
    if not root then return end
    
    if state then
        local bg = Instance.new("BodyGyro")
        bg.Name = "FlyGyro"
        bg.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
        bg.P = 9e4
        bg.Parent = root
        
        local bv = Instance.new("BodyVelocity")
        bv.Name = "FlyVel"
        bv.MaxForce = Vector3.new(9e9, 9e9, 9e9)
        bv.Velocity = Vector3.zero
        bv.Parent = root
        
        Connections.Fly = RunService.Heartbeat:Connect(function()
            if not char or not char.Parent or not root or not root.Parent then
                ToggleFly(false)
                return
            end
            
            local speed = SavedStates.FlySpeed
            local move = Vector3.zero
            
            if UserInputService:IsKeyDown(Enum.KeyCode.W) then move = move + Camera.CFrame.LookVector * speed end
            if UserInputService:IsKeyDown(Enum.KeyCode.S) then move = move - Camera.CFrame.LookVector * speed end
            if UserInputService:IsKeyDown(Enum.KeyCode.A) then move = move - Camera.CFrame.RightVector * speed end
            if UserInputService:IsKeyDown(Enum.KeyCode.D) then move = move + Camera.CFrame.RightVector * speed end
            if UserInputService:IsKeyDown(Enum.KeyCode.Space) then move = move + Vector3.new(0, speed, 0) end
            if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then move = move - Vector3.new(0, speed, 0) end
            
            if bv and bv.Parent then bv.Velocity = move end
            if bg and bg.Parent then bg.CFrame = Camera.CFrame end
        end)
        
        Notify("Voo ativado! Use WASD + Space/Shift", CONFIG.COR_SUCESSO, "✈️")
    else
        if root then
            local gyro = root:FindFirstChild("FlyGyro")
            local vel = root:FindFirstChild("FlyVel")
            if gyro then gyro:Destroy() end
            if vel then vel:Destroy() end
        end
        Notify("Voo desativado", CONFIG.COR_ERRO, "✈️")
    end
end

local function ToggleNoclip(state)
    SavedStates.NoclipEnabled = state
    
    if Connections.Noclip then
        Connections.Noclip:Disconnect()
        Connections.Noclip = nil
    end
    
    if state then
        Connections.Noclip = RunService.Stepped:Connect(function()
            pcall(function()
                for _, v in pairs(LocalPlayer.Character:GetDescendants()) do
                    if v:IsA("BasePart") then v.CanCollide = false end
                end
            end)
        end)
        Notify("Noclip ativado", CONFIG.COR_SUCESSO, "👻")
    else
        Notify("Noclip desativado", CONFIG.COR_ERRO, "👻")
    end
end

local function ToggleInfJump(state)
    SavedStates.InfJumpEnabled = state
    
    if Connections.InfJump then
        Connections.InfJump:Disconnect()
        Connections.InfJump = nil
    end
    
    if state then
        Connections.InfJump = UserInputService.JumpRequest:Connect(function()
            pcall(function()
                LocalPlayer.Character:FindFirstChildOfClass("Humanoid"):ChangeState(Enum.HumanoidStateType.Jumping)
            end)
        end)
        Notify("Pulo infinito ativado", CONFIG.COR_SUCESSO, "🦘")
    else
        Notify("Pulo infinito desativado", CONFIG.COR_ERRO, "🦘")
    end
end

local function ToggleGodMode(state)
    SavedStates.GodMode = state
    
    if Connections.GodMode then
        Connections.GodMode:Disconnect()
        Connections.GodMode = nil
    end
    
    if state then
        Connections.GodMode = RunService.Heartbeat:Connect(function()
            pcall(function()
                local hum = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
                if hum and hum.Health < hum.MaxHealth then
                    hum.Health = hum.MaxHealth
                end
            end)
        end)
        Notify("God Mode ativado", CONFIG.COR_SUCESSO, "🛡️")
    else
        Notify("God Mode desativado", CONFIG.COR_ERRO, "🛡️")
    end
end

task.spawn(function()
    while true do
        pcall(function()
            local hum = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
            if hum then
                hum.WalkSpeed = SavedStates.WalkSpeed
                hum.JumpPower = SavedStates.JumpPower
            end
        end)
        task.wait(0.1)
    end
end)

-- ══════════════════════════════════════════════════════════
-- FUNÇÕES DE TROLL
-- ══════════════════════════════════════════════════════════
local function TeleportToPlayer()
    if not SelectedPlayer or not SelectedPlayer.Parent then
        Notify("Selecione um jogador!", CONFIG.COR_ERRO, "⚠️")
        return
    end
    
    pcall(function()
        local myRoot = LocalPlayer.Character.HumanoidRootPart
        local targetRoot = SelectedPlayer.Character.HumanoidRootPart
        myRoot.CFrame = targetRoot.CFrame * CFrame.new(0, 0, 3)
        Notify("Teleportado para " .. SelectedPlayer.Name, CONFIG.COR_SUCESSO, "🚀")
    end)
end

local function FlingPlayer()
    if not SelectedPlayer or not SelectedPlayer.Parent then
        Notify("Selecione um jogador!", CONFIG.COR_ERRO, "⚠️")
        return
    end
    
    task.spawn(function()
        pcall(function()
            local char = LocalPlayer.Character
            local root = char.HumanoidRootPart
            local originalCF = root.CFrame
            
            -- Desabilitar colisões
            for _, v in pairs(char:GetDescendants()) do
                if v:IsA("BasePart") then
                    v.CanCollide = false
                    v.Massless = true
                end
            end
            
            -- Criar força
            local bv = Instance.new("BodyVelocity")
            bv.MaxForce = Vector3.new(9e9, 9e9, 9e9)
            bv.Parent = root
            
            -- Empurrar o jogador
            for i = 1, 10 do
                root.CFrame = SelectedPlayer.Character.HumanoidRootPart.CFrame
                bv.Velocity = Vector3.new(math.random(-150, 150), math.random(150, 250), math.random(-150, 150))
                task.wait(0.05)
            end
            
            -- Limpar
            bv:Destroy()
            root.CFrame = originalCF
            
            task.wait(0.5)
            for _, v in pairs(char:GetDescendants()) do
                if v:IsA("BasePart") then
                    v.CanCollide = true
                    v.Massless = false
                end
            end
            
            Notify(SelectedPlayer.Name .. " foi arremessado!", CONFIG.COR_SUCESSO, "🌪️")
        end)
    end)
end

local function SpinPlayer()
    if not SelectedPlayer or not SelectedPlayer.Parent then
        Notify("Selecione um jogador!", CONFIG.COR_ERRO, "⚠️")
        return
    end
    
    pcall(function()
        local root = SelectedPlayer.Character.HumanoidRootPart
        local spin = Instance.new("BodyAngularVelocity")
        spin.MaxTorque = Vector3.new(0, 9e9, 0)
        spin.AngularVelocity = Vector3.new(0, 100, 0)
        spin.Parent = root
        
        task.delay(5, function()
            if spin and spin.Parent then spin:Destroy() end
        end)
        
        Notify(SelectedPlayer.Name .. " está girando!", CONFIG.COR_SUCESSO, "🌀")
    end)
end

-- ══════════════════════════════════════════════════════════
-- SISTEMA DE AIMBOT
-- ══════════════════════════════════════════════════════════
local AimbotFOVCircle = nil

local function GetClosestPlayerToMouse()
    local closestPlayer = nil
    local shortestDistance = SavedStates.AimbotFOV
    local mousePos = UserInputService:GetMouseLocation()
    
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            if SavedStates.AimbotTeamCheck and player.Team == LocalPlayer.Team then continue end
            
            local char = player.Character
            local head = char:FindFirstChild("Head")
            local humanoid = char:FindFirstChildOfClass("Humanoid")
            
            if head and humanoid and humanoid.Health > 0 then
                local screenPos, onScreen = Camera:WorldToViewportPoint(head.Position)
                
                if onScreen then
                    if SavedStates.AimbotVisibleCheck then
                        local ray = Ray.new(Camera.CFrame.Position, (head.Position - Camera.CFrame.Position).Unit * 500)
                        local hit = workspace:FindPartOnRayWithIgnoreList(ray, {LocalPlayer.Character, Camera})
                        if hit and not hit:IsDescendantOf(char) then continue end
                    end
                    
                    local distance = (Vector2.new(screenPos.X, screenPos.Y) - mousePos).Magnitude
                    
                    if distance < shortestDistance then
                        closestPlayer = player
                        shortestDistance = distance
                    end
                end
            end
        end
    end
    
    return closestPlayer
end

local function UpdateAimbot()
    if not SavedStates.AimbotEnabled then return end
    
    local target = GetClosestPlayerToMouse()
    AimbotTarget = target
    
    if target and target.Character then
        local head = target.Character:FindFirstChild("Head")
        if head then
            local targetPos = head.Position
            local smoothing = SavedStates.AimbotSmoothing / 10
            
            Camera.CFrame = Camera.CFrame:Lerp(CFrame.new(Camera.CFrame.Position, targetPos), smoothing)
        end
    end
end

local function CreateAimbotFOVCircle()
    if AimbotFOVCircle then
        AimbotFOVCircle:Remove()
    end
    
    AimbotFOVCircle = Drawing.new("Circle")
    AimbotFOVCircle.Thickness = 2
    AimbotFOVCircle.NumSides = 64
    AimbotFOVCircle.Radius = SavedStates.AimbotFOV
    AimbotFOVCircle.Filled = false
    AimbotFOVCircle.Color = GetCurrentColor()
    AimbotFOVCircle.Transparency = 0.5
    AimbotFOVCircle.Visible = SavedStates.AimbotShowFOV
end

local function UpdateAimbotFOV()
    if AimbotFOVCircle then
        local mousePos = UserInputService:GetMouseLocation()
        AimbotFOVCircle.Position = mousePos
        AimbotFOVCircle.Radius = SavedStates.AimbotFOV
        AimbotFOVCircle.Visible = SavedStates.AimbotShowFOV and SavedStates.AimbotEnabled
        AimbotFOVCircle.Color = GetCurrentColor()
    end
end

local function ToggleAimbot(state)
    SavedStates.AimbotEnabled = state
    
    if Connections.Aimbot then
        Connections.Aimbot:Disconnect()
        Connections.Aimbot = nil
    end
    
    if Connections.AimbotFOV then
        Connections.AimbotFOV:Disconnect()
        Connections.AimbotFOV = nil
    end
    
    if state then
        CreateAimbotFOVCircle()
        
        Connections.Aimbot = RunService.RenderStepped:Connect(UpdateAimbot)
        Connections.AimbotFOV = RunService.RenderStepped:Connect(UpdateAimbotFOV)
        
        Notify("Aimbot ativado! Mire próximo ao inimigo", CONFIG.COR_SUCESSO, "🎯")
    else
        if AimbotFOVCircle then
            AimbotFOVCircle:Remove()
            AimbotFOVCircle = nil
        end
        AimbotTarget = nil
        Notify("Aimbot desativado", CONFIG.COR_ERRO, "🎯")
    end
end

-- ══════════════════════════════════════════════════════════
-- SISTEMA ESP
-- ══════════════════════════════════════════════════════════
local function ClearESP()
    for _, esp in pairs(ESPObjects) do
        pcall(function()
            if esp.Box then esp.Box:Remove() end
            if esp.Name then esp.Name:Remove() end
            if esp.Distance then esp.Distance:Remove() end
            if esp.Health then esp.Health:Remove() end
            if esp.HealthBG then esp.HealthBG:Remove() end
            if esp.Tracer then esp.Tracer:Remove() end
        end)
    end
    ESPObjects = {}
end

local function CreateESP(player)
    if player == LocalPlayer then return end
    if ESPObjects[player] then return end
    
    local esp = {}
    
    if SavedStates.ESPBox then
        esp.Box = Drawing.new("Square")
        esp.Box.Thickness = 2
        esp.Box.Filled = false
        esp.Box.Color = GetCurrentColor()
        esp.Box.Transparency = 1
        esp.Box.Visible = false
    end
    
    if SavedStates.ESPTracers then
        esp.Tracer = Drawing.new("Line")
        esp.Tracer.Thickness = 1.5
        esp.Tracer.Color = GetCurrentColor()
        esp.Tracer.Transparency = 0.8
        esp.Tracer.Visible = false
    end
    
    if SavedStates.ESPName then
        esp.Name = Drawing.new("Text")
        esp.Name.Size = 14
        esp.Name.Center = true
        esp.Name.Outline = true
        esp.Name.Color = Color3.new(1, 1, 1)
        esp.Name.Transparency = 1
        esp.Name.Visible = false
        esp.Name.Text = player.Name
        esp.Name.Font = 2
    end
    
    if SavedStates.ESPDistance then
        esp.Distance = Drawing.new("Text")
        esp.Distance.Size = 12
        esp.Distance.Center = true
        esp.Distance.Outline = true
        esp.Distance.Color = Color3.new(1, 1, 0)
        esp.Distance.Transparency = 1
        esp.Distance.Visible = false
        esp.Distance.Font = 2
    end
    
    if SavedStates.ESPHealth then
        esp.HealthBG = Drawing.new("Line")
        esp.HealthBG.Thickness = 4
        esp.HealthBG.Color = Color3.new(0.2, 0.2, 0.2)
        esp.HealthBG.Transparency = 0.5
        esp.HealthBG.Visible = false
        
        esp.Health = Drawing.new("Line")
        esp.Health.Thickness = 2
        esp.Health.Transparency = 1
        esp.Health.Visible = false
    end
    
    ESPObjects[player] = esp
end

local function UpdateESP()
    if not SavedStates.ESPEnabled then return end
    
    for player, esp in pairs(ESPObjects) do
        if not player or not player.Parent or player == LocalPlayer then
            pcall(function()
                if esp.Box then esp.Box:Remove() end
                if esp.Tracer then esp.Tracer:Remove() end
                if esp.Name then esp.Name:Remove() end
                if esp.Distance then esp.Distance:Remove() end
                if esp.Health then esp.Health:Remove() end
                if esp.HealthBG then esp.HealthBG:Remove() end
            end)
            ESPObjects[player] = nil
            continue
        end
        
        local char = player.Character
        if not char then
            if esp.Box then esp.Box.Visible = false end
            if esp.Tracer then esp.Tracer.Visible = false end
            if esp.Name then esp.Name.Visible = false end
            if esp.Distance then esp.Distance.Visible = false end
            if esp.Health then esp.Health.Visible = false end
            if esp.HealthBG then esp.HealthBG.Visible = false end
            continue
        end
        
        local root = char:FindFirstChild("HumanoidRootPart")
        local head = char:FindFirstChild("Head")
        local hum = char:FindFirstChildOfClass("Humanoid")
        
        if root and head and hum and hum.Health > 0 then
            local rootPos, onScreen = Camera:WorldToViewportPoint(root.Position)
            
            if onScreen and rootPos.Z > 0 then
                local headPos = Camera:WorldToViewportPoint(head.Position + Vector3.new(0, 0.5, 0))
                local legPos = Camera:WorldToViewportPoint(root.Position - Vector3.new(0, 3, 0))
                
                local height = math.abs(headPos.Y - legPos.Y)
                local width = height / 2
                
                if esp.Box and SavedStates.ESPBox then
                    esp.Box.Size = Vector2.new(width, height)
                    esp.Box.Position = Vector2.new(rootPos.X - width/2, headPos.Y)
                    esp.Box.Color = GetCurrentColor()
                    esp.Box.Visible = true
                end
                
                if esp.Tracer and SavedStates.ESPTracers then
                    esp.Tracer.From = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
                    esp.Tracer.To = Vector2.new(rootPos.X, legPos.Y)
                    esp.Tracer.Color = GetCurrentColor()
                    esp.Tracer.Visible = true
                end
                
                if esp.Name and SavedStates.ESPName then
                    esp.Name.Position = Vector2.new(rootPos.X, headPos.Y - 18)
                    esp.Name.Visible = true
                end
                
                if esp.Distance and SavedStates.ESPDistance and LocalPlayer.Character then
                    local myRoot = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                    if myRoot then
                        local dist = (myRoot.Position - root.Position).Magnitude
                        esp.Distance.Position = Vector2.new(rootPos.X, legPos.Y + 5)
                        esp.Distance.Text = math.floor(dist) .. "m"
                        esp.Distance.Visible = true
                    end
                end
                
                if esp.Health and esp.HealthBG and SavedStates.ESPHealth then
                    local healthPct = hum.Health / hum.MaxHealth
                    local barHeight = height * healthPct
                    
                    esp.HealthBG.From = Vector2.new(rootPos.X - width/2 - 6, headPos.Y)
                    esp.HealthBG.To = Vector2.new(rootPos.X - width/2 - 6, legPos.Y)
                    esp.HealthBG.Visible = true
                    
                    esp.Health.From = Vector2.new(rootPos.X - width/2 - 6, legPos.Y)
                    esp.Health.To = Vector2.new(rootPos.X - width/2 - 6, legPos.Y - barHeight)
                    esp.Health.Color = Color3.new(1 - healthPct, healthPct, 0)
                    esp.Health.Visible = true
                end
            else
                if esp.Box then esp.Box.Visible = false end
                if esp.Tracer then esp.Tracer.Visible = false end
                if esp.Name then esp.Name.Visible = false end
                if esp.Distance then esp.Distance.Visible = false end
                if esp.Health then esp.Health.Visible = false end
                if esp.HealthBG then esp.HealthBG.Visible = false end
            end
        end
    end
end

local function ToggleESP(state)
    SavedStates.ESPEnabled = state
    
    if Connections.ESP then
        Connections.ESP:Disconnect()
        Connections.ESP = nil
    end
    
    if state then
        for _, player in pairs(Players:GetPlayers()) do
            CreateESP(player)
        end
        Connections.ESP = RunService.RenderStepped:Connect(UpdateESP)
        Notify("ESP ativado", CONFIG.COR_SUCESSO, "👁️")
    else
        ClearESP()
        Notify("ESP desativado", CONFIG.COR_ERRO, "👁️")
    end
end

local function ToggleFullbright(state)
    SavedStates.Fullbright = state
    
    if state then
        Lighting.Brightness = 3
        Lighting.ClockTime = 14
        Lighting.FogEnd = 1e10
        Lighting.GlobalShadows = false
        Lighting.OutdoorAmbient = Color3.new(1, 1, 1)
        Lighting.Ambient = Color3.new(1, 1, 1)
        Notify("Fullbright ativado", CONFIG.COR_SUCESSO, "💡")
    else
        Lighting.Brightness = 1
        Lighting.FogEnd = 1e5
        Lighting.GlobalShadows = true
        Lighting.OutdoorAmbient = Color3.new(0.5, 0.5, 0.5)
        Lighting.Ambient = Color3.new(0, 0, 0)
        Notify("Fullbright desativado", CONFIG.COR_ERRO, "💡")
    end
end

local function GetPlayerDistance(player)
    if not LocalPlayer.Character or not LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        return math.huge
    end
    if not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then
        return math.huge
    end
    return (LocalPlayer.Character.HumanoidRootPart.Position - player.Character.HumanoidRootPart.Position).Magnitude
end

-- ══════════════════════════════════════════════════════════
-- BOTÃO FLUTUANTE MINIMALISTA
-- ══════════════════════════════════════════════════════════
local function CreateFloatingButton()
    if not GUI or not GUI.Parent then return end
    
    local btn = Instance.new("TextButton")
    btn.Name = "FloatingBtn"
    btn.Size = UDim2.new(0, 50, 0, 50)
    btn.Position = UDim2.new(0.5, -25, 0.95, -60)
    btn.BackgroundColor3 = CONFIG.COR_PRINCIPAL
    btn.BorderSizePixel = 0
    btn.Text = ""
    btn.Parent = GUI
    btn.ZIndex = 9999
    
    Instance.new("UICorner", btn).CornerRadius = UDim.new(1, 0)
    
    local icon = Instance.new("TextLabel")
    icon.Size = UDim2.new(1, 0, 1, 0)
    icon.BackgroundTransparency = 1
    icon.Text = "S"
    icon.TextColor3 = CONFIG.COR_TEXTO
    icon.TextSize = 22
    icon.Font = Enum.Font.GothamBold
    icon.Parent = btn
    
    -- Arrastar
    local dragging, dragInput, dragStart, startPos
    
    btn.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = btn.Position
            
            Tween(btn, {Size = UDim2.new(0, 45, 0, 45)}, 0.15)
            
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                    Tween(btn, {Size = UDim2.new(0, 50, 0, 50)}, 0.2, Enum.EasingStyle.Back)
                end
            end)
        end
    end)
    
    btn.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)
    
    UserInputService.InputChanged:Connect(function(input)
        if dragging and dragInput and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            btn.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
    
    btn.MouseButton1Click:Connect(function()
        local main = GUI:FindFirstChild("MainFrame")
        if main then
            main.Visible = not main.Visible
            if main.Visible then
                main.Position = UDim2.new(0.5, -SavedStates.MenuWidth/2, 1.2, 0)
                Tween(main, {Position = UDim2.new(0.5, -SavedStates.MenuWidth/2, 0.5, -SavedStates.MenuHeight/2)}, 0.4, Enum.EasingStyle.Back)
            end
        end
    end)
    
    -- Animação de pulso
    task.spawn(function()
        while btn and btn.Parent do
            Tween(btn, {BackgroundColor3 = CONFIG.COR_HOVER}, 1, Enum.EasingStyle.Sine)
            task.wait(1)
            if not btn or not btn.Parent then break end
            Tween(btn, {BackgroundColor3 = CONFIG.COR_PRINCIPAL}, 1, Enum.EasingStyle.Sine)
            task.wait(1)
        end
    end)
    
    return btn
end

-- ══════════════════════════════════════════════════════════
-- CRIAÇÃO DA GUI PRINCIPAL
-- ══════════════════════════════════════════════════════════
local function CreateGUI()
    if GUI then GUI:Destroy() end
    
    UIElements = {}
    
    GUI = Instance.new("ScreenGui")
    GUI.Name = "SHAKA_V3"
    GUI.ResetOnSpawn = false
    GUI.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    GUI.Parent = LocalPlayer:WaitForChild("PlayerGui")
    
    -- FRAME PRINCIPAL
    local main = Instance.new("Frame")
    main.Name = "MainFrame"
    main.Size = UDim2.new(0, SavedStates.MenuWidth, 0, SavedStates.MenuHeight)
    main.Position = UDim2.new(0.5, -SavedStates.MenuWidth/2, 1.2, 0)
    main.BackgroundColor3 = CONFIG.COR_FUNDO
    main.BorderSizePixel = 0
    main.Visible = false
    main.Parent = GUI
    
    Instance.new("UICorner", main).CornerRadius = UDim.new(0, 12)
    
    -- Header
    local header = Instance.new("Frame")
    header.Size = UDim2.new(1, 0, 0, 45)
    header.BackgroundColor3 = CONFIG.COR_FUNDO_2
    header.BorderSizePixel = 0
    header.Parent = main
    
    Instance.new("UICorner", header).CornerRadius = UDim.new(0, 12)
    
    local headerBottom = Instance.new("Frame")
    headerBottom.Size = UDim2.new(1, 0, 0, 12)
    headerBottom.Position = UDim2.new(0, 0, 1, -12)
    headerBottom.BackgroundColor3 = CONFIG.COR_FUNDO_2
    headerBottom.BorderSizePixel = 0
    headerBottom.Parent = header
    
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(0, 200, 1, 0)
    title.Position = UDim2.new(0, 15, 0, 0)
    title.BackgroundTransparency = 1
    title.Text = "⚡ " .. CONFIG.NOME .. " " .. CONFIG.VERSAO
    title.TextColor3 = CONFIG.COR_TEXTO
    title.TextSize = 16
    title.Font = Enum.Font.GothamBold
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = header
    
    local closeBtn = Instance.new("TextButton")
    closeBtn.Size = UDim2.new(0, 30, 0, 30)
    closeBtn.Position = UDim2.new(1, -38, 0.5, -15)
    closeBtn.BackgroundColor3 = CONFIG.COR_ERRO
    closeBtn.Text = "×"
    closeBtn.TextColor3 = CONFIG.COR_TEXTO
    closeBtn.TextSize = 18
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.BorderSizePixel = 0
    closeBtn.Parent = header
    
    Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 8)
    
    closeBtn.MouseEnter:Connect(function() Tween(closeBtn, {BackgroundColor3 = Color3.fromRGB(220, 38, 38)}, 0.2) end)
    closeBtn.MouseLeave:Connect(function() Tween(closeBtn, {BackgroundColor3 = CONFIG.COR_ERRO}, 0.2) end)
    closeBtn.MouseButton1Click:Connect(function()
        Tween(main, {Position = UDim2.new(0.5, -SavedStates.MenuWidth/2, 1.2, 0)}, 0.3)
        task.wait(0.3)
        main.Visible = false
    end)
    
    -- Tabs Container (Esquerda)
    local tabsContainer = Instance.new("Frame")
    tabsContainer.Size = UDim2.new(0, 110, 1, -55)
    tabsContainer.Position = UDim2.new(0, 10, 0, 50)
    tabsContainer.BackgroundTransparency = 1
    tabsContainer.Parent = main
    
    local tabsList = Instance.new("UIListLayout")
    tabsList.Padding = UDim.new(0, 6)
    tabsList.Parent = tabsContainer
    
    -- Content Container
    local contentContainer = Instance.new("Frame")
    contentContainer.Size = UDim2.new(1, -130, 1, -55)
    contentContainer.Position = UDim2.new(0, 125, 0, 50)
    contentContainer.BackgroundTransparency = 1
    contentContainer.Parent = main
    
    local tabs = {
        {Name = "Player", Icon = "👤"},
        {Name = "Troll", Icon = "😈"},
        {Name = "Aimbot", Icon = "🎯"},
        {Name = "ESP", Icon = "👁️"},
        {Name = "Visual", Icon = "✨"},
        {Name = "Config", Icon = "⚙️"}
    }
    
    local tabFrames = {}
    local currentTab = "Player"
    
    -- Funções de criação de elementos
    local function CreateToggle(name, callback, parent, icon)
        local toggle = Instance.new("Frame")
        toggle.Size = UDim2.new(1, 0, 0, 38)
        toggle.BackgroundColor3 = CONFIG.COR_FUNDO_2
        toggle.BorderSizePixel = 0
        toggle.Parent = parent
        
        Instance.new("UICorner", toggle).CornerRadius = UDim.new(0, 8)
        
        local iconLabel = Instance.new("TextLabel")
        iconLabel.Size = UDim2.new(0, 24, 0, 24)
        iconLabel.Position = UDim2.new(0, 10, 0.5, -12)
        iconLabel.BackgroundTransparency = 1
        iconLabel.Text = icon or "⚡"
        iconLabel.TextColor3 = CONFIG.COR_TEXTO_SEC
        iconLabel.TextSize = 16
        iconLabel.Font = Enum.Font.GothamBold
        iconLabel.Parent = toggle
        
        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(1, -90, 1, 0)
        label.Position = UDim2.new(0, 40, 0, 0)
        label.BackgroundTransparency = 1
        label.Text = name
        label.TextColor3 = CONFIG.COR_TEXTO
        label.TextSize = 12
        label.Font = Enum.Font.Gotham
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.Parent = toggle
        
        local switch = Instance.new("Frame")
        switch.Size = UDim2.new(0, 42, 0, 22)
        switch.Position = UDim2.new(1, -50, 0.5, -11)
        switch.BackgroundColor3 = CONFIG.COR_FUNDO_3
        switch.BorderSizePixel = 0
        switch.Parent = toggle
        
        Instance.new("UICorner", switch).CornerRadius = UDim.new(1, 0)
        
        local knob = Instance.new("Frame")
        knob.Size = UDim2.new(0, 18, 0, 18)
        knob.Position = UDim2.new(0, 2, 0, 2)
        knob.BackgroundColor3 = CONFIG.COR_TEXTO
        knob.BorderSizePixel = 0
        knob.Parent = switch
        
        Instance.new("UICorner", knob).CornerRadius = UDim.new(1, 0)
        
        local state = false
        
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(1, 0, 1, 0)
        btn.BackgroundTransparency = 1
        btn.Text = ""
        btn.Parent = toggle
        
        btn.MouseEnter:Connect(function() Tween(toggle, {BackgroundColor3 = CONFIG.COR_FUNDO_3}, 0.2) end)
        btn.MouseLeave:Connect(function() Tween(toggle, {BackgroundColor3 = CONFIG.COR_FUNDO_2}, 0.2) end)
        
        btn.MouseButton1Click:Connect(function()
            state = not state
            if state then
                Tween(switch, {BackgroundColor3 = CONFIG.COR_PRINCIPAL}, 0.25)
                Tween(knob, {Position = UDim2.new(1, -20, 0, 2)}, 0.25, Enum.EasingStyle.Back)
                Tween(iconLabel, {TextColor3 = CONFIG.COR_PRINCIPAL}, 0.25)
            else
                Tween(switch, {BackgroundColor3 = CONFIG.COR_FUNDO_3}, 0.25)
                Tween(knob, {Position = UDim2.new(0, 2, 0, 2)}, 0.25, Enum.EasingStyle.Back)
                Tween(iconLabel, {TextColor3 = CONFIG.COR_TEXTO_SEC}, 0.25)
            end
            callback(state)
        end)
        
        return toggle
    end
    
    local function CreateSlider(name, min, max, default, callback, parent, icon)
        local slider = Instance.new("Frame")
        slider.Size = UDim2.new(1, 0, 0, 50)
        slider.BackgroundColor3 = CONFIG.COR_FUNDO_2
        slider.BorderSizePixel = 0
        slider.Parent = parent
        
        Instance.new("UICorner", slider).CornerRadius = UDim.new(0, 8)
        
        local iconLabel = Instance.new("TextLabel")
        iconLabel.Size = UDim2.new(0, 24, 0, 24)
        iconLabel.Position = UDim2.new(0, 10, 0, 6)
        iconLabel.BackgroundTransparency = 1
        iconLabel.Text = icon or "📊"
        iconLabel.TextColor3 = CONFIG.COR_TEXTO_SEC
        iconLabel.TextSize = 14
        iconLabel.Font = Enum.Font.GothamBold
        iconLabel.Parent = slider
        
        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(1, -100, 0, 20)
        label.Position = UDim2.new(0, 40, 0, 6)
        label.BackgroundTransparency = 1
        label.Text = name
        label.TextColor3 = CONFIG.COR_TEXTO
        label.TextSize = 11
        label.Font = Enum.Font.Gotham
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.Parent = slider
        
        local valueLabel = Instance.new("TextLabel")
        valueLabel.Size = UDim2.new(0, 60, 0, 20)
        valueLabel.Position = UDim2.new(1, -70, 0, 6)
        valueLabel.BackgroundTransparency = 1
        valueLabel.Text = tostring(default)
        valueLabel.TextColor3 = CONFIG.COR_PRINCIPAL
        valueLabel.TextSize = 11
        valueLabel.Font = Enum.Font.GothamBold
        valueLabel.TextXAlignment = Enum.TextXAlignment.Right
        valueLabel.Parent = slider
        
        local track = Instance.new("Frame")
        track.Size = UDim2.new(1, -20, 0, 4)
        track.Position = UDim2.new(0, 10, 0, 36)
        track.BackgroundColor3 = CONFIG.COR_FUNDO_3
        track.BorderSizePixel = 0
        track.Parent = slider
        
        Instance.new("UICorner", track).CornerRadius = UDim.new(1, 0)
        
        local fill = Instance.new("Frame")
        fill.Size = UDim2.new((default - min) / (max - min), 0, 1, 0)
        fill.BackgroundColor3 = CONFIG.COR_PRINCIPAL
        fill.BorderSizePixel = 0
        fill.Parent = track
        
        Instance.new("UICorner", fill).CornerRadius = UDim.new(1, 0)
        
        local knob = Instance.new("Frame")
        knob.Size = UDim2.new(0, 12, 0, 12)
        knob.Position = UDim2.new((default - min) / (max - min), -6, 0.5, -6)
        knob.BackgroundColor3 = CONFIG.COR_TEXTO
        knob.BorderSizePixel = 0
        knob.Parent = track
        
        Instance.new("UICorner", knob).CornerRadius = UDim.new(1, 0)
        
        local dragging = false
        
        local function update(input)
            local pos = math.clamp((input.Position.X - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
            local value = math.floor(min + (max - min) * pos)
            
            fill.Size = UDim2.new(pos, 0, 1, 0)
            knob.Position = UDim2.new(pos, -6, 0.5, -6)
            valueLabel.Text = tostring(value)
            callback(value)
        end
        
        knob.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                dragging = true
                Tween(knob, {Size = UDim2.new(0, 16, 0, 16), Position = UDim2.new(knob.Position.X.Scale, -8, 0.5, -8)}, 0.15)
            end
        end)
        
        UserInputService.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                dragging = false
                Tween(knob, {Size = UDim2.new(0, 12, 0, 12), Position = UDim2.new(knob.Position.X.Scale, -6, 0.5, -6)}, 0.15)
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
        
        return slider
    end
    
    local function CreateButton(text, callback, parent, icon, color)
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(1, 0, 0, 35)
        btn.BackgroundColor3 = color or CONFIG.COR_PRINCIPAL
        btn.Text = ""
        btn.BorderSizePixel = 0
        btn.Parent = parent
        
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)
        
        local iconLabel = Instance.new("TextLabel")
        iconLabel.Size = UDim2.new(0, 24, 0, 24)
        iconLabel.Position = UDim2.new(0, 10, 0.5, -12)
        iconLabel.BackgroundTransparency = 1
        iconLabel.Text = icon or "⚡"
        iconLabel.TextColor3 = CONFIG.COR_TEXTO
        iconLabel.TextSize = 16
        iconLabel.Font = Enum.Font.GothamBold
        iconLabel.Parent = btn
        
        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(1, -45, 1, 0)
        label.Position = UDim2.new(0, 40, 0, 0)
        label.BackgroundTransparency = 1
        label.Text = text
        label.TextColor3 = CONFIG.COR_TEXTO
        label.TextSize = 12
        label.Font = Enum.Font.GothamBold
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.Parent = btn
        
        btn.MouseEnter:Connect(function()
            Tween(btn, {BackgroundColor3 = color and Color3.fromRGB(math.min(color.R * 255 + 20, 255), math.min(color.G * 255 + 20, 255), math.min(color.B * 255 + 20, 255)) or CONFIG.COR_HOVER}, 0.2)
        end)
        btn.MouseLeave:Connect(function()
            Tween(btn, {BackgroundColor3 = color or CONFIG.COR_PRINCIPAL}, 0.2)
        end)
        
        btn.MouseButton1Click:Connect(function()
            Tween(btn, {Size = UDim2.new(1, 0, 0, 32)}, 0.1)
            task.wait(0.1)
            Tween(btn, {Size = UDim2.new(1, 0, 0, 35)}, 0.15, Enum.EasingStyle.Back)
            callback()
        end)
        
        return btn
    end
    
    local function CreateSection(text, parent)
        local section = Instance.new("TextLabel")
        section.Size = UDim2.new(1, 0, 0, 25)
        section.BackgroundTransparency = 1
        section.Text = text
        section.TextColor3 = CONFIG.COR_TEXTO_SEC
        section.TextSize = 10
        section.Font = Enum.Font.GothamBold
        section.TextXAlignment = Enum.TextXAlignment.Left
        section.Parent = parent
        
        return section
    end
    
    -- Lista de jogadores (apenas aba Troll)
    local playerList = Instance.new("Frame")
    playerList.Size = UDim2.new(0, 150, 1, -55)
    playerList.Position = UDim2.new(0, 125, 0, 50)
    playerList.BackgroundColor3 = CONFIG.COR_FUNDO_2
    playerList.BorderSizePixel = 0
    playerList.Visible = false
    playerList.Parent = main
    
    Instance.new("UICorner", playerList).CornerRadius = UDim.new(0, 8)
    
    local plTitle = Instance.new("TextLabel")
    plTitle.Size = UDim2.new(1, 0, 0, 30)
    plTitle.BackgroundColor3 = CONFIG.COR_PRINCIPAL
    plTitle.Text = "👥 JOGADORES"
    plTitle.TextColor3 = CONFIG.COR_TEXTO
    plTitle.TextSize = 11
    plTitle.Font = Enum.Font.GothamBold
    plTitle.BorderSizePixel = 0
    plTitle.Parent = playerList
    
    Instance.new("UICorner", plTitle).CornerRadius = UDim.new(0, 8)
    
    local plBottom = Instance.new("Frame")
    plBottom.Size = UDim2.new(1, 0, 0, 8)
    plBottom.Position = UDim2.new(0, 0, 1, -8)
    plBottom.BackgroundColor3 = CONFIG.COR_PRINCIPAL
    plBottom.BorderSizePixel = 0
    plBottom.Parent = plTitle
    
    local selectedLabel = Instance.new("TextLabel")
    selectedLabel.Size = UDim2.new(1, -8, 0, 24)
    selectedLabel.Position = UDim2.new(0, 4, 0, 34)
    selectedLabel.BackgroundColor3 = CONFIG.COR_FUNDO
    selectedLabel.Text = "Nenhum"
    selectedLabel.TextColor3 = CONFIG.COR_TEXTO_SEC
    selectedLabel.TextSize = 9
    selectedLabel.Font = Enum.Font.Gotham
    selectedLabel.BorderSizePixel = 0
    selectedLabel.Parent = playerList
    
    Instance.new("UICorner", selectedLabel).CornerRadius = UDim.new(0, 6)
    
    local playerScroll = Instance.new("ScrollingFrame")
    playerScroll.Size = UDim2.new(1, -8, 1, -66)
    playerScroll.Position = UDim2.new(0, 4, 0, 62)
    playerScroll.BackgroundTransparency = 1
    playerScroll.BorderSizePixel = 0
    playerScroll.ScrollBarThickness = 3
    playerScroll.ScrollBarImageColor3 = CONFIG.COR_PRINCIPAL
    playerScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    playerScroll.Parent = playerList
    
    local function UpdatePlayerList()
        for _, child in pairs(playerScroll:GetChildren()) do
            if child:IsA("TextButton") or child:IsA("UIListLayout") then child:Destroy() end
        end
        
        local layout = Instance.new("UIListLayout")
        layout.Padding = UDim.new(0, 4)
        layout.Parent = playerScroll
        
        layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            playerScroll.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 4)
        end)
        
        local players = {}
        for _, p in pairs(Players:GetPlayers()) do
            if p ~= LocalPlayer then
                table.insert(players, {Player = p, Distance = GetPlayerDistance(p)})
            end
        end
        
        table.sort(players, function(a, b) return a.Distance < b.Distance end)
        
        for _, data in ipairs(players) do
            local p = data.Player
            local d = data.Distance
            
            local pBtn = Instance.new("TextButton")
            pBtn.Size = UDim2.new(1, -4, 0, 28)
            pBtn.BackgroundColor3 = CONFIG.COR_FUNDO
            pBtn.Text = ""
            pBtn.BorderSizePixel = 0
            pBtn.Parent = playerScroll
            
            Instance.new("UICorner", pBtn).CornerRadius = UDim.new(0, 6)
            
            local pName = Instance.new("TextLabel")
            pName.Size = UDim2.new(1, -35, 1, 0)
            pName.Position = UDim2.new(0, 6, 0, 0)
            pName.BackgroundTransparency = 1
            pName.Text = p.Name
            pName.TextColor3 = CONFIG.COR_TEXTO
            pName.TextSize = 10
            pName.Font = Enum.Font.Gotham
            pName.TextXAlignment = Enum.TextXAlignment.Left
            pName.TextTruncate = Enum.TextTruncate.AtEnd
            pName.Parent = pBtn
            
            local pDist = Instance.new("TextLabel")
            pDist.Size = UDim2.new(0, 30, 1, 0)
            pDist.Position = UDim2.new(1, -32, 0, 0)
            pDist.BackgroundTransparency = 1
            pDist.Text = d == math.huge and "?" or math.floor(d) .. "m"
            pDist.TextColor3 = CONFIG.COR_TEXTO_SEC
            pDist.TextSize = 8
            pDist.Font = Enum.Font.Gotham
            pDist.TextXAlignment = Enum.TextXAlignment.Right
            pDist.Parent = pBtn
            
            if SelectedPlayer == p then
                pBtn.BackgroundColor3 = CONFIG.COR_PRINCIPAL
            end
            
            pBtn.MouseButton1Click:Connect(function()
                SelectedPlayer = p
                selectedLabel.Text = p.Name
                selectedLabel.TextColor3 = CONFIG.COR_PRINCIPAL
                
                for _, btn in pairs(playerScroll:GetChildren()) do
                    if btn:IsA("TextButton") then
                        Tween(btn, {BackgroundColor3 = CONFIG.COR_FUNDO}, 0.2)
                    end
                end
                Tween(pBtn, {BackgroundColor3 = CONFIG.COR_PRINCIPAL}, 0.2)
            end)
            
            pBtn.MouseEnter:Connect(function()
                if SelectedPlayer ~= p then
                    Tween(pBtn, {BackgroundColor3 = CONFIG.COR_FUNDO_3}, 0.15)
                end
            end)
            pBtn.MouseLeave:Connect(function()
                if SelectedPlayer ~= p then
                    Tween(pBtn, {BackgroundColor3 = CONFIG.COR_FUNDO}, 0.15)
                end
            end)
        end
    end
    
    task.spawn(function()
        while GUI and GUI.Parent do
            if playerList.Visible then UpdatePlayerList() end
            task.wait(2)
        end
    end)
    
    -- Criar tabs
    for i, tab in ipairs(tabs) do
        local tabBtn = Instance.new("TextButton")
        tabBtn.Size = UDim2.new(1, 0, 0, 45)
        tabBtn.BackgroundColor3 = CONFIG.COR_FUNDO_2
        tabBtn.Text = ""
        tabBtn.BorderSizePixel = 0
        tabBtn.Parent = tabsContainer
        
        Instance.new("UICorner", tabBtn).CornerRadius = UDim.new(0, 8)
        
        local tabIcon = Instance.new("TextLabel")
        tabIcon.Size = UDim2.new(1, 0, 0, 20)
        tabIcon.Position = UDim2.new(0, 0, 0, 6)
        tabIcon.BackgroundTransparency = 1
        tabIcon.Text = tab.Icon
        tabIcon.TextColor3 = CONFIG.COR_TEXTO_SEC
        tabIcon.TextSize = 18
        tabIcon.Font = Enum.Font.GothamBold
        tabIcon.Parent = tabBtn
        
        local tabName = Instance.new("TextLabel")
        tabName.Size = UDim2.new(1, 0, 0, 14)
        tabName.Position = UDim2.new(0, 0, 0, 26)
        tabName.BackgroundTransparency = 1
        tabName.Text = tab.Name
        tabName.TextColor3 = CONFIG.COR_TEXTO_SEC
        tabName.TextSize = 9
        tabName.Font = Enum.Font.Gotham
        tabName.Parent = tabBtn
        
        local tabFrame = Instance.new("ScrollingFrame")
        tabFrame.Size = UDim2.new(1, 0, 1, 0)
        tabFrame.BackgroundTransparency = 1
        tabFrame.BorderSizePixel = 0
        tabFrame.ScrollBarThickness = 3
        tabFrame.ScrollBarImageColor3 = CONFIG.COR_PRINCIPAL
        tabFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
        tabFrame.Visible = false
        tabFrame.Parent = contentContainer
        
        local layout = Instance.new("UIListLayout")
        layout.Padding = UDim.new(0, 6)
        layout.Parent = tabFrame
        
        layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            tabFrame.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 6)
        end)
        
        tabFrames[tab.Name] = tabFrame
        
        tabBtn.MouseButton1Click:Connect(function()
            currentTab = tab.Name
            
            -- Mostrar lista de jogadores apenas na aba Troll
            if tab.Name == "Troll" then
                playerList.Visible = true
                contentContainer.Size = UDim2.new(1, -290, 1, -55)
                contentContainer.Position = UDim2.new(0, 280, 0, 50)
            else
                playerList.Visible = false
                contentContainer.Size = UDim2.new(1, -130, 1, -55)
                contentContainer.Position = UDim2.new(0, 125, 0, 50)
            end
            
            for name, frame in pairs(tabFrames) do
                frame.Visible = (name == tab.Name)
            end
            
            for _, btn in pairs(tabsContainer:GetChildren()) do
                if btn:IsA("TextButton") then
                    Tween(btn, {BackgroundColor3 = CONFIG.COR_FUNDO_2}, 0.2)
                    local icon = btn:FindFirstChild("TextLabel")
                    local name = btn:FindFirstChild("TextLabel") and btn:FindFirstChild("TextLabel").Parent:FindFirstChild("TextLabel")
                    if icon then Tween(icon, {TextColor3 = CONFIG.COR_TEXTO_SEC}, 0.2) end
                    for _, child in pairs(btn:GetChildren()) do
                        if child:IsA("TextLabel") then
                            Tween(child, {TextColor3 = CONFIG.COR_TEXTO_SEC}, 0.2)
                        end
                    end
                end
            end
            
            Tween(tabBtn, {BackgroundColor3 = CONFIG.COR_PRINCIPAL}, 0.2)
            Tween(tabIcon, {TextColor3 = CONFIG.COR_TEXTO}, 0.2)
            Tween(tabName, {TextColor3 = CONFIG.COR_TEXTO}, 0.2)
        end)
        
        if i == 1 then
            tabBtn.BackgroundColor3 = CONFIG.COR_PRINCIPAL
            tabIcon.TextColor3 = CONFIG.COR_TEXTO
            tabName.TextColor3 = CONFIG.COR_TEXTO
            tabFrame.Visible = true
        end
    end
    
    -- ═══════════ CONTEÚDO DAS ABAS ═══════════
    
    -- ABA PLAYER
    CreateSection("MOVIMENTO", tabFrames["Player"])
    CreateToggle("Voo", ToggleFly, tabFrames["Player"], "✈️")
    CreateSlider("Velocidade Voo", 10, 300, SavedStates.FlySpeed, function(v) SavedStates.FlySpeed = v end, tabFrames["Player"], "⚡")
    CreateToggle("Noclip", ToggleNoclip, tabFrames["Player"], "👻")
    CreateToggle("Pulo Infinito", ToggleInfJump, tabFrames["Player"], "🦘")
    
    CreateSection("VELOCIDADE", tabFrames["Player"])
    CreateSlider("Walk Speed", 16, 400, SavedStates.WalkSpeed, function(v) SavedStates.WalkSpeed = v end, tabFrames["Player"], "🏃")
    CreateSlider("Jump Power", 50, 600, SavedStates.JumpPower, function(v) SavedStates.JumpPower = v end, tabFrames["Player"], "⬆️")
    
    CreateSection("PROTEÇÃO", tabFrames["Player"])
    CreateToggle("God Mode", ToggleGodMode, tabFrames["Player"], "🛡️")
    
    CreateSection("AÇÕES", tabFrames["Player"])
    CreateButton("Sentar/Levantar", function()
        pcall(function()
            local hum = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
            hum.Sit = not hum.Sit
            Notify(hum.Sit and "Sentado" or "Em pé", CONFIG.COR_SUCESSO, "💺")
        end)
    end, tabFrames["Player"], "💺")
    
    CreateButton("Remover Acessórios", function()
        pcall(function()
            local count = 0
            for _, v in pairs(LocalPlayer.Character:GetChildren()) do
                if v:IsA("Accessory") then
                    v:Destroy()
                    count = count + 1
                end
            end
            Notify(count .. " acessórios removidos", CONFIG.COR_SUCESSO, "🎩")
        end)
    end, tabFrames["Player"], "🎩")
    
    -- ABA TROLL
    CreateSection("TELEPORTE", tabFrames["Troll"])
    CreateButton("Ir para Jogador", TeleportToPlayer, tabFrames["Troll"], "🚀")
    CreateButton("Ir para Spawn", function()
        pcall(function()
            local spawn = workspace:FindFirstChildOfClass("SpawnLocation")
            if spawn then
                LocalPlayer.Character.HumanoidRootPart.CFrame = spawn.CFrame + Vector3.new(0, 5, 0)
            else
                LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(0, 50, 0)
            end
            Notify("Teleportado para spawn", CONFIG.COR_SUCESSO, "🏠")
        end)
    end, tabFrames["Troll"], "🏠")
    
    CreateSection("TROLLAGEM", tabFrames["Troll"])
    CreateButton("Arremessar Jogador", FlingPlayer, tabFrames["Troll"], "🌪️", CONFIG.COR_AVISO)
    CreateButton("Girar Jogador", SpinPlayer, tabFrames["Troll"], "🌀", CONFIG.COR_AVISO)
    
    CreateButton("Copiar Roupa", function()
        if not SelectedPlayer or not SelectedPlayer.Parent then
            Notify("Selecione um jogador!", CONFIG.COR_ERRO, "⚠️")
            return
        end
        pcall(function()
            for _, v in pairs(LocalPlayer.Character:GetChildren()) do
                if v:IsA("Accessory") or v:IsA("Shirt") or v:IsA("Pants") then v:Destroy() end
            end
            for _, v in pairs(SelectedPlayer.Character:GetChildren()) do
                if v:IsA("Accessory") or v:IsA("Shirt") or v:IsA("Pants") then
                    v:Clone().Parent = LocalPlayer.Character
                end
            end
            Notify("Roupa copiada!", CONFIG.COR_SUCESSO, "👔")
        end)
    end, tabFrames["Troll"], "👔")
    
    CreateButton("Seguir Jogador", function()
        if not SelectedPlayer or not SelectedPlayer.Parent then
            Notify("Selecione um jogador!", CONFIG.COR_ERRO, "⚠️")
            return
        end
        
        if Connections.Follow then
            Connections.Follow:Disconnect()
            Connections.Follow = nil
            Notify("Parou de seguir", CONFIG.COR_ERRO, "🚶")
        else
            Connections.Follow = RunService.Heartbeat:Connect(function()
                pcall(function()
                    local hum = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
                    local target = SelectedPlayer.Character.HumanoidRootPart
                    hum:MoveTo(target.Position)
                end)
            end)
            Notify("Seguindo " .. SelectedPlayer.Name, CONFIG.COR_SUCESSO, "🚶")
        end
    end, tabFrames["Troll"], "🚶")
    
    -- ABA AIMBOT
    CreateSection("AIMBOT PRINCIPAL", tabFrames["Aimbot"])
    CreateToggle("Ativar Aimbot", ToggleAimbot, tabFrames["Aimbot"], "🎯")
    
    CreateSection("CONFIGURAÇÕES", tabFrames["Aimbot"])
    CreateSlider("Suavização", 1, 10, SavedStates.AimbotSmoothing, function(v)
        SavedStates.AimbotSmoothing = v
    end, tabFrames["Aimbot"], "🎚️")
    
    CreateSlider("FOV (Raio)", 50, 500, SavedStates.AimbotFOV, function(v)
        SavedStates.AimbotFOV = v
        if AimbotFOVCircle then
            AimbotFOVCircle.Radius = v
        end
    end, tabFrames["Aimbot"], "⭕")
    
    CreateToggle("Mostrar FOV Circle", function(state)
        SavedStates.AimbotShowFOV = state
        if AimbotFOVCircle then
            AimbotFOVCircle.Visible = state and SavedStates.AimbotEnabled
        end
    end, tabFrames["Aimbot"], "👁️")
    
    CreateSection("FILTROS", tabFrames["Aimbot"])
    CreateToggle("Ignorar Time", function(state)
        SavedStates.AimbotTeamCheck = not state
    end, tabFrames["Aimbot"], "👥")
    
    CreateToggle("Apenas Visíveis", function(state)
        SavedStates.AimbotVisibleCheck = state
    end, tabFrames["Aimbot"], "👀")
    
    local infoLabel = Instance.new("TextLabel")
    infoLabel.Size = UDim2.new(1, 0, 0, 60)
    infoLabel.BackgroundColor3 = CONFIG.COR_FUNDO_2
    infoLabel.Text = "💡 DICA: O aimbot trava automaticamente no inimigo mais próximo do cursor dentro do FOV."
    infoLabel.TextColor3 = CONFIG.COR_TEXTO_SEC
    infoLabel.TextSize = 10
    infoLabel.Font = Enum.Font.Gotham
    infoLabel.TextWrapped = true
    infoLabel.TextXAlignment = Enum.TextXAlignment.Left
    infoLabel.TextYAlignment = Enum.TextYAlignment.Top
    infoLabel.BorderSizePixel = 0
    infoLabel.Parent = tabFrames["Aimbot"]
    
    local padding = Instance.new("UIPadding", infoLabel)
    padding.PaddingLeft = UDim.new(0, 8)
    padding.PaddingRight = UDim.new(0, 8)
    padding.PaddingTop = UDim.new(0, 8)
    padding.PaddingBottom = UDim.new(0, 8)
    
    Instance.new("UICorner", infoLabel).CornerRadius = UDim.new(0, 8)
    
    -- ABA ESP
    CreateSection("ESP PRINCIPAL", tabFrames["ESP"])
    CreateToggle("Ativar ESP", ToggleESP, tabFrames["ESP"], "👁️")
    
    CreateSection("OPÇÕES", tabFrames["ESP"])
    CreateToggle("Caixas", function(state)
        SavedStates.ESPBox = state
        if SavedStates.ESPEnabled then
            ToggleESP(false)
            task.wait(0.1)
            ToggleESP(true)
        end
    end, tabFrames["ESP"], "📦")
    
    CreateToggle("Nomes", function(state)
        SavedStates.ESPName = state
        if SavedStates.ESPEnabled then
            ToggleESP(false)
            task.wait(0.1)
            ToggleESP(true)
        end
    end, tabFrames["ESP"], "📝")
    
    CreateToggle("Distância", function(state)
        SavedStates.ESPDistance = state
        if SavedStates.ESPEnabled then
            ToggleESP(false)
            task.wait(0.1)
            ToggleESP(true)
        end
    end, tabFrames["ESP"], "📍")
    
    CreateToggle("Vida", function(state)
        SavedStates.ESPHealth = state
        if SavedStates.ESPEnabled then
            ToggleESP(false)
            task.wait(0.1)
            ToggleESP(true)
        end
    end, tabFrames["ESP"], "❤️")
    
    CreateToggle("Linhas", function(state)
        SavedStates.ESPTracers = state
        if SavedStates.ESPEnabled then
            ToggleESP(false)
            task.wait(0.1)
            ToggleESP(true)
        end
    end, tabFrames["ESP"], "📏")
    
    -- ABA VISUAL
    CreateSection("ILUMINAÇÃO", tabFrames["Visual"])
    CreateToggle("Fullbright", ToggleFullbright, tabFrames["Visual"], "💡")
    CreateToggle("Remover Fog", function(state)
        Lighting.FogEnd = state and 1e10 or 1e5
        Notify(state and "Fog removido" or "Fog restaurado", state and CONFIG.COR_SUCESSO or CONFIG.COR_ERRO, "🌫️")
    end, tabFrames["Visual"], "🌫️")
    
    CreateSection("CÂMERA", tabFrames["Visual"])
    CreateSlider("FOV", 70, 120, SavedStates.FOV, function(v)
        SavedStates.FOV = v
        Camera.FieldOfView = v
    end, tabFrames["Visual"], "🔭")
    
    CreateSection("TEMPO", tabFrames["Visual"])
    CreateButton("Dia Permanente", function()
        Lighting.ClockTime = 14
        if Connections.Time then Connections.Time:Disconnect() end
        Connections.Time = RunService.Heartbeat:Connect(function() Lighting.ClockTime = 14 end)
        Notify("Dia permanente ativado", CONFIG.COR_SUCESSO, "☀️")
    end, tabFrames["Visual"], "☀️")
    
    CreateButton("Noite Permanente", function()
        Lighting.ClockTime = 0
        if Connections.Time then Connections.Time:Disconnect() end
        Connections.Time = RunService.Heartbeat:Connect(function() Lighting.ClockTime = 0 end)
        Notify("Noite permanente ativada", CONFIG.COR_SUCESSO, "🌙")
    end, tabFrames["Visual"], "🌙")
    
    -- ABA CONFIG
    CreateSection("TAMANHO DO MENU", tabFrames["Config"])
    CreateSlider("Largura", 450, 700, SavedStates.MenuWidth, function(v)
        SavedStates.MenuWidth = v
        main.Size = UDim2.new(0, v, 0, SavedStates.MenuHeight)
        main.Position = UDim2.new(0.5, -v/2, main.Position.Y.Scale, main.Position.Y.Offset)
    end, tabFrames["Config"], "↔️")
    
    CreateSlider("Altura", 350, 550, SavedStates.MenuHeight, function(v)
        SavedStates.MenuHeight = v
        main.Size = UDim2.new(0, SavedStates.MenuWidth, 0, v)
        main.Position = UDim2.new(0.5, -SavedStates.MenuWidth/2, 0.5, -v/2)
    end, tabFrames["Config"], "↕️")
    
    CreateSection("COR DO TEMA", tabFrames["Config"])
    CreateToggle("Modo Rainbow", function(state)
        SavedStates.RainbowMode = state
        
        if Connections.Rainbow then
            Connections.Rainbow:Disconnect()
            Connections.Rainbow = nil
        end
        
        if state then
            Connections.Rainbow = RunService.Heartbeat:Connect(function()
                RainbowHue = (RainbowHue + 0.003) % 1
                local color = GetCurrentColor()
                
                for _, elem in pairs(UIElements) do
                    pcall(function()
                        if elem and elem.Parent then
                            Tween(elem, {BackgroundColor3 = color}, 0.1)
                        end
                    end)
                end
            end)
            Notify("Modo Rainbow ativado!", CONFIG.COR_SUCESSO, "🌈")
        else
            Notify("Rainbow desativado", CONFIG.COR_ERRO, "🌈")
        end
    end, tabFrames["Config"], "🌈")
    
    CreateSection("INFORMAÇÕES", tabFrames["Config"])
    CreateButton("Estatísticas", function()
        local info = string.format("📊 FPS: %d\n👥 Players: %d\n⚡ Ping: %dms",
            math.floor(workspace:GetRealPhysicsFPS()),
            #Players:GetPlayers(),
            math.floor(LocalPlayer:GetNetworkPing() * 1000)
        )
        Notify(info, CONFIG.COR_PRINCIPAL, "📊")
    end, tabFrames["Config"], "📊")
    
    CreateButton("Resetar Config", function()
        SavedStates.MenuWidth = 550
        SavedStates.MenuHeight = 420
        main.Size = UDim2.new(0, 550, 0, 420)
        main.Position = UDim2.new(0.5, -275, 0.5, -210)
        Notify("Configurações resetadas!", CONFIG.COR_SUCESSO, "🔄")
    end, tabFrames["Config"], "🔄", CONFIG.COR_ERRO)
    
    local credits = Instance.new("Frame")
    credits.Size = UDim2.new(1, 0, 0, 70)
    credits.BackgroundColor3 = CONFIG.COR_FUNDO_2
    credits.BorderSizePixel = 0
    credits.Parent = tabFrames["Config"]
    
    Instance.new("UICorner", credits).CornerRadius = UDim.new(0, 8)
    
    local creditIcon = Instance.new("TextLabel")
    creditIcon.Size = UDim2.new(0, 40, 0, 40)
    creditIcon.Position = UDim2.new(0.5, -20, 0, 6)
    creditIcon.BackgroundTransparency = 1
    creditIcon.Text = "👑"
    creditIcon.TextSize = 32
    creditIcon.Font = Enum.Font.GothamBold
    creditIcon.Parent = credits
    
    local creditText = Instance.new("TextLabel")
    creditText.Size = UDim2.new(1, 0, 0, 20)
    creditText.Position = UDim2.new(0, 0, 0, 48)
    creditText.BackgroundTransparency = 1
    creditText.Text = "Desenvolvido por 2M • 2025"
    creditText.TextColor3 = CONFIG.COR_TEXTO_SEC
    creditText.TextSize = 10
    creditText.Font = Enum.Font.Gotham
    creditText.Parent = credits
    
    CreateFloatingButton()
    
    Notify("SHAKA v3.0 carregado!", CONFIG.COR_SUCESSO, "🚀")
end

-- ══════════════════════════════════════════════════════════
-- INICIALIZAÇÃO
-- ══════════════════════════════════════════════════════════
CreateGUI()

-- ══════════════════════════════════════════════════════════
-- CONTROLES
-- ══════════════════════════════════════════════════════════
UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    
    if input.KeyCode == Enum.KeyCode.Insert then
        if GUI then
            local main = GUI:FindFirstChild("MainFrame")
            if main then
                main.Visible = not main.Visible
                if main.Visible then
                    main.Position = UDim2.new(0.5, -SavedStates.MenuWidth/2, 1.2, 0)
                    Tween(main, {Position = UDim2.new(0.5, -SavedStates.MenuWidth/2, 0.5, -SavedStates.MenuHeight/2)}, 0.4, Enum.EasingStyle.Back)
                end
            end
        end
    end
end)

-- ══════════════════════════════════════════════════════════
-- EVENTOS
-- ══════════════════════════════════════════════════════════
Players.PlayerAdded:Connect(function(player)
    if SavedStates.ESPEnabled then
        task.wait(1)
        CreateESP(player)
    end
end)

Players.PlayerRemoving:Connect(function(player)
    if ESPObjects[player] then
        local esp = ESPObjects[player]
        pcall(function()
            if esp.Box then esp.Box:Remove() end
            if esp.Tracer then esp.Tracer:Remove() end
            if esp.Name then esp.Name:Remove() end
            if esp.Distance then esp.Distance:Remove() end
            if esp.Health then esp.Health:Remove() end
            if esp.HealthBG then esp.HealthBG:Remove() end
        end)
        ESPObjects[player] = nil
    end
    if SelectedPlayer == player then SelectedPlayer = nil end
end)

print("╔════════════════════════════════════╗")
print("║  SHAKA HUB v3.0 - Carregado!      ║")
print("║  Pressione INSERT para abrir       ║")
print("║  Desenvolvido por 2M               ║")
print("╚════════════════════════════════════╝")
