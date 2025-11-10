-- SHAKA Hub Premium v9.0 - GTA RP Edition
-- Layout Lateral | Sistema Completo | Ultra Otimizado
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")
local Camera = workspace.CurrentCamera

-- ════════════════════════════════════════════════════════════
-- CONFIGURAÇÕES
-- ════════════════════════════════════════════════════════════
local CONFIG = {
    NOME = "SHAKA",
    VERSAO = "v9.0",
    COR_PRINCIPAL = Color3.fromRGB(139, 0, 255),
    COR_FUNDO = Color3.fromRGB(10, 10, 15),
    COR_FUNDO_2 = Color3.fromRGB(18, 18, 25),
    COR_FUNDO_3 = Color3.fromRGB(25, 25, 35),
    COR_TEXTO = Color3.fromRGB(255, 255, 255),
    COR_TEXTO_SEC = Color3.fromRGB(150, 150, 160),
    COR_SUCESSO = Color3.fromRGB(0, 255, 100),
    COR_ERRO = Color3.fromRGB(255, 50, 80),
    COR_AVISO = Color3.fromRGB(255, 200, 0)
}

-- ════════════════════════════════════════════════════════════
-- VARIÁVEIS GLOBAIS
-- ════════════════════════════════════════════════════════════
local GUI = nil
local Connections = {}
local SelectedPlayer = nil
local RainbowHue = 0
local UIElements = {}

local SavedStates = {
    -- Player
    FlyEnabled = false,
    FlySpeed = 50,
    NoclipEnabled = false,
    InfJumpEnabled = false,
    WalkSpeed = 16,
    JumpPower = 50,
    GodMode = false,
    InvisibleEnabled = false,
    Swim = false,
    
    -- Combat/Troll
    FollowPlayer = false,
    SpectatePlayer = false,
    OrbitPlayer = false,
    
    -- ESP
    ESPEnabled = false,
    ESPBox = true,
    ESPName = true,
    ESPDistance = true,
    ESPHealth = true,
    ESPTracers = true,
    ESPChams = false,
    ESPTeamColor = false,
    
    -- Visual
    Fullbright = false,
    RemoveFog = false,
    FOV = 70,
    
    -- Config
    RainbowMode = false,
    CustomColor = nil,
    MenuScale = 1
}

local ESPObjects = {}

-- ════════════════════════════════════════════════════════════
-- FUNÇÕES DE COR
-- ════════════════════════════════════════════════════════════
local function GetCurrentColor()
    if SavedStates.RainbowMode then
        return Color3.fromHSV(RainbowHue, 1, 1)
    elseif SavedStates.CustomColor then
        return SavedStates.CustomColor
    else
        return CONFIG.COR_PRINCIPAL
    end
end

local function UpdateAllColors()
    if not GUI then return end
    local currentColor = GetCurrentColor()
    
    for _, element in pairs(UIElements) do
        if element and element.Parent then
            pcall(function()
                if element:GetAttribute("ColorUpdate") then
                    TweenService:Create(element, TweenInfo.new(0.2), {
                        BackgroundColor3 = currentColor
                    }):Play()
                end
                if element:GetAttribute("StrokeUpdate") and element:IsA("UIStroke") then
                    TweenService:Create(element, TweenInfo.new(0.2), {
                        Color = currentColor
                    }):Play()
                end
                if element:GetAttribute("TextColorUpdate") and element:IsA("TextLabel") then
                    TweenService:Create(element, TweenInfo.new(0.2), {
                        TextColor3 = currentColor
                    }):Play()
                end
            end)
        end
    end
end

-- ════════════════════════════════════════════════════════════
-- FUNÇÕES AUXILIARES
-- ════════════════════════════════════════════════════════════
local function Log(msg)
    print("[SHAKA] " .. msg)
end

local function Tween(obj, props, time)
    if not obj or not obj.Parent then return end
    TweenService:Create(obj, TweenInfo.new(time or 0.2, Enum.EasingStyle.Quad), props):Play()
end

local function Notify(text, color)
    task.spawn(function()
        if not GUI then return end
        
        local notif = Instance.new("Frame")
        notif.Size = UDim2.new(0, 300, 0, 70)
        notif.Position = UDim2.new(1, -320, 1, 10)
        notif.BackgroundColor3 = CONFIG.COR_FUNDO_2
        notif.BackgroundTransparency = 0.05
        notif.BorderSizePixel = 0
        notif.Parent = GUI
        notif.ZIndex = 1000
        
        Instance.new("UICorner", notif).CornerRadius = UDim.new(0, 10)
        
        local glow = Instance.new("UIStroke", notif)
        glow.Color = color or GetCurrentColor()
        glow.Thickness = 2
        glow.Transparency = 0
        
        local icon = Instance.new("TextLabel")
        icon.Size = UDim2.new(0, 45, 0, 45)
        icon.Position = UDim2.new(0, 12, 0.5, -22)
        icon.BackgroundColor3 = color or GetCurrentColor()
        icon.Text = color == CONFIG.COR_SUCESSO and "✓" or (color == CONFIG.COR_ERRO and "✕" or "!")
        icon.TextColor3 = CONFIG.COR_TEXTO
        icon.TextSize = 26
        icon.Font = Enum.Font.GothamBold
        icon.BorderSizePixel = 0
        icon.Parent = notif
        Instance.new("UICorner", icon).CornerRadius = UDim.new(0, 10)
        
        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(1, -70, 1, -10)
        label.Position = UDim2.new(0, 62, 0, 5)
        label.BackgroundTransparency = 1
        label.Text = text
        label.TextColor3 = CONFIG.COR_TEXTO
        label.TextSize = 13
        label.Font = Enum.Font.Gotham
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.TextYAlignment = Enum.TextYAlignment.Top
        label.TextWrapped = true
        label.Parent = notif
        
        Tween(notif, {Position = UDim2.new(1, -320, 1, -80)}, 0.3)
        task.wait(3)
        Tween(notif, {Position = UDim2.new(1, 10, 1, -80)}, 0.3)
        task.wait(0.3)
        if notif and notif.Parent then notif:Destroy() end
    end)
end

-- ════════════════════════════════════════════════════════════
-- FUNÇÕES DO PLAYER
-- ════════════════════════════════════════════════════════════
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
        local bodyGyro = Instance.new("BodyGyro")
        bodyGyro.Name = "FlyGyro"
        bodyGyro.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
        bodyGyro.P = 9e4
        bodyGyro.Parent = root
        
        local bodyVelocity = Instance.new("BodyVelocity")
        bodyVelocity.Name = "FlyVelocity"
        bodyVelocity.MaxForce = Vector3.new(9e9, 9e9, 9e9)
        bodyVelocity.Velocity = Vector3.new(0, 0, 0)
        bodyVelocity.Parent = root
        
        Connections.Fly = RunService.Heartbeat:Connect(function()
            if not char or not char.Parent or not root or not root.Parent then
                ToggleFly(false)
                return
            end
            
            local moveVector = Vector3.new(0, 0, 0)
            
            if UserInputService:IsKeyDown(Enum.KeyCode.W) then
                moveVector = moveVector + (Camera.CFrame.LookVector * SavedStates.FlySpeed)
            end
            if UserInputService:IsKeyDown(Enum.KeyCode.S) then
                moveVector = moveVector - (Camera.CFrame.LookVector * SavedStates.FlySpeed)
            end
            if UserInputService:IsKeyDown(Enum.KeyCode.A) then
                moveVector = moveVector - (Camera.CFrame.RightVector * SavedStates.FlySpeed)
            end
            if UserInputService:IsKeyDown(Enum.KeyCode.D) then
                moveVector = moveVector + (Camera.CFrame.RightVector * SavedStates.FlySpeed)
            end
            if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
                moveVector = moveVector + (Vector3.new(0, 1, 0) * SavedStates.FlySpeed)
            end
            if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then
                moveVector = moveVector - (Vector3.new(0, 1, 0) * SavedStates.FlySpeed)
            end
            
            if bodyVelocity and bodyVelocity.Parent then
                bodyVelocity.Velocity = moveVector
            end
            if bodyGyro and bodyGyro.Parent then
                bodyGyro.CFrame = Camera.CFrame
            end
        end)
        
        Notify("✈️ Fly ativado! WASD + Space/Shift", CONFIG.COR_SUCESSO)
    else
        if root then
            local gyro = root:FindFirstChild("FlyGyro")
            local velocity = root:FindFirstChild("FlyVelocity")
            if gyro then gyro:Destroy() end
            if velocity then velocity:Destroy() end
        end
        Notify("✈️ Fly desativado", CONFIG.COR_ERRO)
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
            local char = LocalPlayer.Character
            if char then
                for _, part in pairs(char:GetDescendants()) do
                    if part:IsA("BasePart") and part.CanCollide then
                        part.CanCollide = false
                    end
                end
            end
        end)
        Notify("👻 Noclip ativado", CONFIG.COR_SUCESSO)
    else
        Notify("👻 Noclip desativado", CONFIG.COR_ERRO)
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
            local char = LocalPlayer.Character
            if char then
                local humanoid = char:FindFirstChildOfClass("Humanoid")
                if humanoid then
                    humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
                end
            end
        end)
        Notify("🦘 Pulo Infinito ativado", CONFIG.COR_SUCESSO)
    else
        Notify("🦘 Pulo Infinito desativado", CONFIG.COR_ERRO)
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
            local char = LocalPlayer.Character
            if char then
                local humanoid = char:FindFirstChildOfClass("Humanoid")
                if humanoid and humanoid.Health < humanoid.MaxHealth then
                    humanoid.Health = humanoid.MaxHealth
                end
            end
        end)
        Notify("🛡️ God Mode ativado", CONFIG.COR_SUCESSO)
    else
        Notify("🛡️ God Mode desativado", CONFIG.COR_ERRO)
    end
end

local function ToggleInvisible(state)
    SavedStates.InvisibleEnabled = state
    local char = LocalPlayer.Character
    if not char then return end
    
    if state then
        for _, part in pairs(char:GetDescendants()) do
            if part:IsA("BasePart") then
                part.Transparency = 1
                if part.Name == "Head" then
                    local face = part:FindFirstChildOfClass("Decal")
                    if face then face.Transparency = 1 end
                end
            elseif part:IsA("Accessory") then
                local handle = part:FindFirstChild("Handle")
                if handle then handle.Transparency = 1 end
            end
        end
        Notify("👻 Invisível ativado", CONFIG.COR_SUCESSO)
    else
        for _, part in pairs(char:GetDescendants()) do
            if part:IsA("BasePart") then
                part.Transparency = 0
                if part.Name == "Head" then
                    local face = part:FindFirstChildOfClass("Decal")
                    if face then face.Transparency = 0 end
                end
            elseif part:IsA("Accessory") then
                local handle = part:FindFirstChild("Handle")
                if handle then handle.Transparency = 0 end
            end
        end
        Notify("👤 Visível novamente", CONFIG.COR_ERRO)
    end
end

local function ToggleSwim(state)
    SavedStates.Swim = state
    local char = LocalPlayer.Character
    if not char then return end
    
    local humanoid = char:FindFirstChildOfClass("Humanoid")
    if not humanoid then return end
    
    if state then
        humanoid:SetStateEnabled(Enum.HumanoidStateType.Swimming, false)
        Notify("🏊 Andar na água ativado", CONFIG.COR_SUCESSO)
    else
        humanoid:SetStateEnabled(Enum.HumanoidStateType.Swimming, true)
        Notify("🏊 Nadar restaurado", CONFIG.COR_ERRO)
    end
end

-- Manter velocidade e pulo
task.spawn(function()
    while true do
        pcall(function()
            local char = LocalPlayer.Character
            if char then
                local humanoid = char:FindFirstChildOfClass("Humanoid")
                if humanoid then
                    if humanoid.WalkSpeed ~= SavedStates.WalkSpeed then
                        humanoid.WalkSpeed = SavedStates.WalkSpeed
                    end
                    if humanoid.JumpPower ~= SavedStates.JumpPower then
                        humanoid.JumpPower = SavedStates.JumpPower
                    end
                end
            end
        end)
        task.wait(0.1)
    end
end)

-- ════════════════════════════════════════════════════════════
-- FUNÇÕES DE INTERAÇÃO COM JOGADORES
-- ════════════════════════════════════════════════════════════
local function TeleportToPlayer()
    if not SelectedPlayer or not SelectedPlayer.Parent then
        Notify("⚠️ Selecione um jogador válido!", CONFIG.COR_ERRO)
        return
    end
    
    local char = LocalPlayer.Character
    local targetChar = SelectedPlayer.Character
    
    if not char or not targetChar then
        Notify("❌ Personagens não encontrados", CONFIG.COR_ERRO)
        return
    end
    
    local root = char:FindFirstChild("HumanoidRootPart")
    local targetRoot = targetChar:FindFirstChild("HumanoidRootPart")
    
    if root and targetRoot then
        root.CFrame = targetRoot.CFrame * CFrame.new(0, 0, 3)
        Notify("🚀 Teleportado para " .. SelectedPlayer.Name, CONFIG.COR_SUCESSO)
    else
        Notify("❌ Erro ao teleportar", CONFIG.COR_ERRO)
    end
end

local function ToggleFollowPlayer(state)
    SavedStates.FollowPlayer = state
    
    if Connections.Follow then
        Connections.Follow:Disconnect()
        Connections.Follow = nil
    end
    
    if state then
        if not SelectedPlayer or not SelectedPlayer.Parent then
            Notify("⚠️ Selecione um jogador primeiro!", CONFIG.COR_ERRO)
            SavedStates.FollowPlayer = false
            return
        end
        
        Connections.Follow = RunService.Heartbeat:Connect(function()
            local char = LocalPlayer.Character
            local targetChar = SelectedPlayer and SelectedPlayer.Character
            
            if not char or not targetChar then return end
            
            local root = char:FindFirstChild("HumanoidRootPart")
            local targetRoot = targetChar:FindFirstChild("HumanoidRootPart")
            local humanoid = char:FindFirstChildOfClass("Humanoid")
            
            if root and targetRoot and humanoid then
                humanoid:MoveTo(targetRoot.Position)
            end
        end)
        
        Notify("🚶 Seguindo " .. SelectedPlayer.Name, CONFIG.COR_SUCESSO)
    else
        Notify("🚶 Parou de seguir", CONFIG.COR_ERRO)
    end
end

local function ToggleSpectatePlayer(state)
    SavedStates.SpectatePlayer = state
    
    if Connections.Spectate then
        Connections.Spectate:Disconnect()
        Connections.Spectate = nil
    end
    
    if state then
        if not SelectedPlayer or not SelectedPlayer.Parent then
            Notify("⚠️ Selecione um jogador primeiro!", CONFIG.COR_ERRO)
            SavedStates.SpectatePlayer = false
            return
        end
        
        Connections.Spectate = RunService.RenderStepped:Connect(function()
            local targetChar = SelectedPlayer and SelectedPlayer.Character
            if targetChar then
                local targetHum = targetChar:FindFirstChildOfClass("Humanoid")
                if targetHum then
                    Camera.CameraSubject = targetHum
                end
            end
        end)
        
        Notify("👁️ Espectar " .. SelectedPlayer.Name, CONFIG.COR_SUCESSO)
    else
        Camera.CameraSubject = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        Notify("👁️ Espectação desativada", CONFIG.COR_ERRO)
    end
end

local function ToggleOrbitPlayer(state)
    SavedStates.OrbitPlayer = state
    
    if Connections.Orbit then
        Connections.Orbit:Disconnect()
        Connections.Orbit = nil
    end
    
    if state then
        if not SelectedPlayer or not SelectedPlayer.Parent then
            Notify("⚠️ Selecione um jogador primeiro!", CONFIG.COR_ERRO)
            SavedStates.OrbitPlayer = false
            return
        end
        
        local angle = 0
        
        Connections.Orbit = RunService.Heartbeat:Connect(function()
            local char = LocalPlayer.Character
            local targetChar = SelectedPlayer and SelectedPlayer.Character
            
            if not char or not targetChar then return end
            
            local root = char:FindFirstChild("HumanoidRootPart")
            local targetRoot = targetChar:FindFirstChild("HumanoidRootPart")
            
            if root and targetRoot then
                angle = angle + 0.05
                local radius = 5
                local x = math.cos(angle) * radius
                local z = math.sin(angle) * radius
                
                root.CFrame = targetRoot.CFrame * CFrame.new(x, 0, z) * CFrame.Angles(0, angle, 0)
            end
        end)
        
        Notify("🌀 Orbitando " .. SelectedPlayer.Name, CONFIG.COR_SUCESSO)
    else
        Notify("🌀 Órbita desativada", CONFIG.COR_ERRO)
    end
end

local function DanceOnPlayer()
    if not SelectedPlayer or not SelectedPlayer.Parent then
        Notify("⚠️ Selecione um jogador primeiro!", CONFIG.COR_ERRO)
        return
    end
    
    local char = LocalPlayer.Character
    local targetChar = SelectedPlayer.Character
    
    if not char or not targetChar then
        Notify("❌ Personagens não encontrados", CONFIG.COR_ERRO)
        return
    end
    
    local root = char:FindFirstChild("HumanoidRootPart")
    local targetRoot = targetChar:FindFirstChild("HumanoidRootPart")
    local humanoid = char:FindFirstChildOfClass("Humanoid")
    
    if root and targetRoot and humanoid then
        root.CFrame = targetRoot.CFrame * CFrame.new(0, 0, -2)
        
        -- Animação de dança
        local animator = humanoid:FindFirstChildOfClass("Animator")
        if animator then
            -- IDs de animação de dança do Roblox
            local danceIds = {
                "rbxassetid://507770239",
                "rbxassetid://507770453",
                "rbxassetid://507770677",
                "rbxassetid://507770897"
            }
            
            local randomDance = danceIds[math.random(1, #danceIds)]
            local danceAnim = Instance.new("Animation")
            danceAnim.AnimationId = randomDance
            
            local track = animator:LoadAnimation(danceAnim)
            track:Play()
            
            task.delay(5, function()
                track:Stop()
            end)
        end
        
        Notify("💃 Dançando em " .. SelectedPlayer.Name, CONFIG.COR_SUCESSO)
    end
end

local function TwerkOnPlayer()
    if not SelectedPlayer or not SelectedPlayer.Parent then
        Notify("⚠️ Selecione um jogador primeiro!", CONFIG.COR_ERRO)
        return
    end
    
    local char = LocalPlayer.Character
    local targetChar = SelectedPlayer.Character
    
    if not char or not targetChar then return end
    
    local root = char:FindFirstChild("HumanoidRootPart")
    local targetRoot = targetChar:FindFirstChild("HumanoidRootPart")
    
    if root and targetRoot then
        root.CFrame = targetRoot.CFrame * CFrame.new(0, 0, -1.5)
        
        -- Animação de rebolar
        for i = 1, 20 do
            task.spawn(function()
                wait(i * 0.1)
                if root and root.Parent then
                    root.CFrame = root.CFrame * CFrame.Angles(0, 0, math.rad(10))
                    wait(0.05)
                    root.CFrame = root.CFrame * CFrame.Angles(0, 0, math.rad(-10))
                end
            end)
        end
        
        Notify("🍑 Rebolando em " .. SelectedPlayer.Name, CONFIG.COR_SUCESSO)
    end
end

local function CopyOutfit()
    if not SelectedPlayer or not SelectedPlayer.Parent then
        Notify("⚠️ Selecione um jogador primeiro!", CONFIG.COR_ERRO)
        return
    end
    
    local char = LocalPlayer.Character
    local targetChar = SelectedPlayer.Character
    
    if not char or not targetChar then
        Notify("❌ Personagens não encontrados", CONFIG.COR_ERRO)
        return
    end
    
    for _, item in pairs(char:GetChildren()) do
        if item:IsA("Accessory") or item:IsA("Shirt") or item:IsA("Pants") then
            item:Destroy()
        end
    end
    
    for _, item in pairs(targetChar:GetChildren()) do
        if item:IsA("Accessory") or item:IsA("Shirt") or item:IsA("Pants") then
            local clone = item:Clone()
            clone.Parent = char
        end
    end
    
    for _, part in pairs(char:GetChildren()) do
        if part:IsA("BasePart") then
            local targetPart = targetChar:FindFirstChild(part.Name)
            if targetPart and targetPart:IsA("BasePart") then
                part.BrickColor = targetPart.BrickColor
                part.Color = targetPart.Color
            end
        end
    end
    
    Notify("👔 Roupa copiada de " .. SelectedPlayer.Name, CONFIG.COR_SUCESSO)
end

local function FlingPlayer()
    if not SelectedPlayer or not SelectedPlayer.Parent then
        Notify("⚠️ Selecione um jogador válido!", CONFIG.COR_ERRO)
        return
    end
    
    local char = LocalPlayer.Character
    local targetChar = SelectedPlayer.Character
    
    if not char or not targetChar then
        Notify("❌ Personagens não encontrados", CONFIG.COR_ERRO)
        return
    end
    
    local root = char:FindFirstChild("HumanoidRootPart")
    local targetRoot = targetChar:FindFirstChild("HumanoidRootPart")
    
    if not root or not targetRoot then
        Notify("❌ Erro ao arremessar", CONFIG.COR_ERRO)
        return
    end
    
    local originalPos = root.CFrame
    
    for _, part in pairs(char:GetDescendants()) do
        if part:IsA("BasePart") then
            part.CanCollide = false
            part.Massless = true
        end
    end
    
    local bodyVelocity = Instance.new("BodyVelocity")
    bodyVelocity.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
    bodyVelocity.Velocity = Vector3.new(0, 0, 0)
    bodyVelocity.Parent = root
    
    for i = 1, 5 do
        root.CFrame = targetRoot.CFrame
        bodyVelocity.Velocity = Vector3.new(
            math.random(-100, 100),
            math.random(100, 200),
            math.random(-100, 100)
        )
        task.wait(0.1)
    end
    
    bodyVelocity:Destroy()
    root.CFrame = originalPos
    
    task.wait(0.5)
    for _, part in pairs(char:GetDescendants()) do
        if part:IsA("BasePart") then
            part.CanCollide = true
            part.Massless = false
        end
    end
    
    Notify("🌪️ " .. SelectedPlayer.Name .. " arremessado!", CONFIG.COR_SUCESSO)
end

-- ════════════════════════════════════════════════════════════
-- SISTEMA DE ESP (OTIMIZADO E BONITO)
-- ════════════════════════════════════════════════════════════
local function ClearESP()
    for _, esp in pairs(ESPObjects) do
        pcall(function()
            if esp.Box then esp.Box:Remove() end
            if esp.Name then esp.Name:Remove() end
            if esp.Distance then esp.Distance:Remove() end
            if esp.Health then esp.Health:Remove() end
            if esp.HealthBG then esp.HealthBG:Remove() end
            if esp.Tracer then esp.Tracer:Remove() end
            if esp.Chams then esp.Chams:Destroy() end
        end)
    end
    ESPObjects = {}
end

local function CreateESP(player)
    if player == LocalPlayer then return end
    if ESPObjects[player] then return end
    
    local esp = {
        Player = player,
        Box = nil,
        Name = nil,
        Distance = nil,
        Health = nil,
        HealthBG = nil,
        Tracer = nil,
        Chams = nil
    }
    
    if SavedStates.ESPBox then
        esp.Box = Drawing.new("Square")
        esp.Box.Thickness = 2
        esp.Box.Filled = false
        esp.Box.Color = SavedStates.ESPTeamColor and player.TeamColor.Color or GetCurrentColor()
        esp.Box.Transparency = 1
        esp.Box.Visible = false
    end
    
    if SavedStates.ESPTracers then
        esp.Tracer = Drawing.new("Line")
        esp.Tracer.Thickness = 1.5
        esp.Tracer.Color = SavedStates.ESPTeamColor and player.TeamColor.Color or GetCurrentColor()
        esp.Tracer.Transparency = 0.8
        esp.Tracer.Visible = false
    end
    
    if SavedStates.ESPName then
        esp.Name = Drawing.new("Text")
        esp.Name.Size = 15
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
        esp.Distance.Size = 13
        esp.Distance.Center = true
        esp.Distance.Outline = true
        esp.Distance.Color = Color3.new(1, 1, 0)
        esp.Distance.Transparency = 1
        esp.Distance.Visible = false
        esp.Distance.Font = 2
    end
    
    if SavedStates.ESPHealth then
        esp.HealthBG = Drawing.new("Line")
        esp.HealthBG.Thickness = 5
        esp.HealthBG.Color = Color3.new(0.2, 0.2, 0.2)
        esp.HealthBG.Transparency = 0.5
        esp.HealthBG.Visible = false
        
        esp.Health = Drawing.new("Line")
        esp.Health.Thickness = 3
        esp.Health.Transparency = 1
        esp.Health.Visible = false
    end
    
    if SavedStates.ESPChams then
        local char = player.Character
        if char then
            for _, part in pairs(char:GetChildren()) do
                if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
                    local highlight = Instance.new("BoxHandleAdornment")
                    highlight.Size = part.Size
                    highlight.Adornee = part
                    highlight.Color3 = SavedStates.ESPTeamColor and player.TeamColor.Color or GetCurrentColor()
                    highlight.Transparency = 0.7
                    highlight.ZIndex = 1
                    highlight.AlwaysOnTop = true
                    highlight.Parent = part
                    
                    if not esp.Chams then
                        esp.Chams = {}
                    end
                    table.insert(esp.Chams, highlight)
                end
            end
        end
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
                if esp.Chams then
                    for _, cham in pairs(esp.Chams) do
                        cham:Destroy()
                    end
                end
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
        
        local root = char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso")
        local head = char:FindFirstChild("Head")
        local humanoid = char:FindFirstChildOfClass("Humanoid")
        
        if root and head and humanoid and humanoid.Health > 0 then
            local rootPos, onScreen = Camera:WorldToViewportPoint(root.Position)
            
            if onScreen and rootPos.Z > 0 then
                local headPos = Camera:WorldToViewportPoint(head.Position + Vector3.new(0, 0.5, 0))
                local legPos = Camera:WorldToViewportPoint(root.Position - Vector3.new(0, 3, 0))
                
                local height = math.abs(headPos.Y - legPos.Y)
                local width = height / 2
                
                if esp.Box and SavedStates.ESPBox then
                    esp.Box.Size = Vector2.new(width, height)
                    esp.Box.Position = Vector2.new(rootPos.X - width/2, headPos.Y)
                    esp.Box.Color = SavedStates.ESPTeamColor and player.TeamColor.Color or GetCurrentColor()
                    esp.Box.Visible = true
                end
                
                if esp.Tracer and SavedStates.ESPTracers then
                    esp.Tracer.From = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
                    esp.Tracer.To = Vector2.new(rootPos.X, legPos.Y)
                    esp.Tracer.Color = SavedStates.ESPTeamColor and player.TeamColor.Color or GetCurrentColor()
                    esp.Tracer.Visible = true
                end
                
                if esp.Name and SavedStates.ESPName then
                    esp.Name.Position = Vector2.new(rootPos.X, headPos.Y - 20)
                    esp.Name.Text = player.Name
                    esp.Name.Visible = true
                end
                
                if esp.Distance and SavedStates.ESPDistance and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                    local distance = (LocalPlayer.Character.HumanoidRootPart.Position - root.Position).Magnitude
                    esp.Distance.Position = Vector2.new(rootPos.X, legPos.Y + 5)
                    esp.Distance.Text = string.format("%d studs", math.floor(distance))
                    esp.Distance.Visible = true
                end
                
                if esp.Health and esp.HealthBG and SavedStates.ESPHealth then
                    local healthPercent = humanoid.Health / humanoid.MaxHealth
                    local barHeight = height * healthPercent
                    
                    esp.HealthBG.From = Vector2.new(rootPos.X - width/2 - 6, headPos.Y)
                    esp.HealthBG.To = Vector2.new(rootPos.X - width/2 - 6, legPos.Y)
                    esp.HealthBG.Visible = true
                    
                    esp.Health.From = Vector2.new(rootPos.X - width/2 - 6, legPos.Y)
                    esp.Health.To = Vector2.new(rootPos.X - width/2 - 6, legPos.Y - barHeight)
                    esp.Health.Color = Color3.new(1 - healthPercent, healthPercent, 0)
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
        Notify("👁️ ESP ativado", CONFIG.COR_SUCESSO)
    else
        ClearESP()
        Notify("👁️ ESP desativado", CONFIG.COR_ERRO)
    end
end

-- ════════════════════════════════════════════════════════════
-- FUNÇÕES VISUAIS
-- ════════════════════════════════════════════════════════════
local function ToggleFullbright(state)
    SavedStates.Fullbright = state
    
    if state then
        Lighting.Brightness = 3
        Lighting.ClockTime = 14
        Lighting.FogEnd = 1e10
        Lighting.GlobalShadows = false
        Lighting.OutdoorAmbient = Color3.new(1, 1, 1)
        Lighting.Ambient = Color3.new(1, 1, 1)
        Notify("💡 Fullbright ativado", CONFIG.COR_SUCESSO)
    else
        Lighting.Brightness = 1
        Lighting.FogEnd = 1e5
        Lighting.GlobalShadows = true
        Lighting.OutdoorAmbient = Color3.new(0.5, 0.5, 0.5)
        Lighting.Ambient = Color3.new(0, 0, 0)
        Notify("💡 Fullbright desativado", CONFIG.COR_ERRO)
    end
end

-- ════════════════════════════════════════════════════════════
-- CRIAÇÃO DA GUI (ESTILO GTA RP)
-- ════════════════════════════════════════════════════════════
local function CreateGUI()
    if GUI then
        GUI:Destroy()
    end
    
    UIElements = {}
    
    GUI = Instance.new("ScreenGui")
    GUI.Name = "SHAKA_HUB_RP"
    GUI.ResetOnSpawn = false
    GUI.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    GUI.Parent = LocalPlayer:WaitForChild("PlayerGui")
    
    local scale = SavedStates.MenuScale or 1
    local baseWidth, baseHeight = 420, 580
    
    local main = Instance.new("Frame")
    main.Name = "Main"
    main.Size = UDim2.new(0, baseWidth * scale, 0, baseHeight * scale)
    main.Position = UDim2.new(1, -((baseWidth * scale) + 20), 0.5, -(baseHeight * scale)/2)
    main.BackgroundColor3 = CONFIG.COR_FUNDO
    main.BackgroundTransparency = 0.05
    main.BorderSizePixel = 0
    main.Parent = GUI
    
    Instance.new("UICorner", main).CornerRadius = UDim.new(0, 14)
    
    local mainGlow = Instance.new("UIStroke", main)
    mainGlow.Color = GetCurrentColor()
    mainGlow.Thickness = 2
    mainGlow.Transparency = 0.3
    mainGlow.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    mainGlow:SetAttribute("StrokeUpdate", true)
    table.insert(UIElements, mainGlow)
    
    -- Header GTA Style
    local header = Instance.new("Frame")
    header.Name = "Header"
    header.Size = UDim2.new(1, 0, 0, 60)
    header.BackgroundColor3 = CONFIG.COR_FUNDO_2
    header.BackgroundTransparency = 0.1
    header.BorderSizePixel = 0
    header.Parent = main
    
    Instance.new("UICorner", header).CornerRadius = UDim.new(0, 14)
    
    local headerLine = Instance.new("Frame")
    headerLine.Size = UDim2.new(1, 0, 0, 2)
    headerLine.Position = UDim2.new(0, 0, 1, -2)
    headerLine.BackgroundColor3 = GetCurrentColor()
    headerLine.BorderSizePixel = 0
    headerLine.Parent = header
    headerLine:SetAttribute("ColorUpdate", true)
    table.insert(UIElements, headerLine)
    
    local logo = Instance.new("TextLabel")
    logo.Size = UDim2.new(0, 200, 0, 30)
    logo.Position = UDim2.new(0, 20, 0, 10)
    logo.BackgroundTransparency = 1
    logo.Text = "SHAKA"
    logo.TextColor3 = GetCurrentColor()
    logo.TextSize = 28
    logo.Font = Enum.Font.GothamBold
    logo.TextXAlignment = Enum.TextXAlignment.Left
    logo.Parent = header
    logo:SetAttribute("TextColorUpdate", true)
    table.insert(UIElements, logo)
    
    local subtitle = Instance.new("TextLabel")
    subtitle.Size = UDim2.new(0, 200, 0, 20)
    subtitle.Position = UDim2.new(0, 20, 0, 35)
    subtitle.BackgroundTransparency = 1
    subtitle.Text = "GTA RP EDITION • " .. CONFIG.VERSAO
    subtitle.TextColor3 = CONFIG.COR_TEXTO_SEC
    subtitle.TextSize = 11
    subtitle.Font = Enum.Font.Gotham
    subtitle.TextXAlignment = Enum.TextXAlignment.Left
    subtitle.Parent = header
    
    local closeBtn = Instance.new("TextButton")
    closeBtn.Size = UDim2.new(0, 40, 0, 40)
    closeBtn.Position = UDim2.new(1, -50, 0, 10)
    closeBtn.BackgroundColor3 = CONFIG.COR_ERRO
    closeBtn.BackgroundTransparency = 0.2
    closeBtn.Text = "×"
    closeBtn.TextColor3 = CONFIG.COR_TEXTO
    closeBtn.TextSize = 28
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.BorderSizePixel = 0
    closeBtn.Parent = header
    
    Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 10)
    
    closeBtn.MouseButton1Click:Connect(function()
        Tween(main, {Position = UDim2.new(1, 50, 0.5, -(baseHeight * scale)/2)}, 0.3)
        task.wait(0.3)
        GUI:Destroy()
        GUI = nil
    end)
    
    closeBtn.MouseEnter:Connect(function()
        Tween(closeBtn, {BackgroundTransparency = 0}, 0.15)
    end)
    
    closeBtn.MouseLeave:Connect(function()
        Tween(closeBtn, {BackgroundTransparency = 0.2}, 0.15)
    end)
    
    -- Content Area
    local content = Instance.new("Frame")
    content.Size = UDim2.new(1, -20, 1, -80)
    content.Position = UDim2.new(0, 10, 0, 70)
    content.BackgroundTransparency = 1
    content.BorderSizePixel = 0
    content.Parent = main
    
    -- Sidebar (Tabs verticais - GTA Style)
    local sidebar = Instance.new("Frame")
    sidebar.Size = UDim2.new(0, 110, 1, 0)
    sidebar.BackgroundTransparency = 1
    sidebar.BorderSizePixel = 0
    sidebar.Parent = content
    
    local sidebarScroll = Instance.new("ScrollingFrame")
    sidebarScroll.Size = UDim2.new(1, 0, 1, 0)
    sidebarScroll.BackgroundTransparency = 1
    sidebarScroll.BorderSizePixel = 0
    sidebarScroll.ScrollBarThickness = 0
    sidebarScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    sidebarScroll.Parent = sidebar
    
    local sidebarLayout = Instance.new("UIListLayout")
    sidebarLayout.Padding = UDim.new(0, 8)
    sidebarLayout.SortOrder = Enum.SortOrder.LayoutOrder
    sidebarLayout.Parent = sidebarScroll
    
    sidebarLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        sidebarScroll.CanvasSize = UDim2.new(0, 0, 0, sidebarLayout.AbsoluteContentSize.Y + 10)
    end)
    
    -- Tab Content Area
    local tabContent = Instance.new("Frame")
    tabContent.Size = UDim2.new(1, -120, 1, 0)
    tabContent.Position = UDim2.new(0, 120, 0, 0)
    tabContent.BackgroundTransparency = 1
    tabContent.BorderSizePixel = 0
    tabContent.Parent = content
    
    local tabs = {
        {Name = "Player", Icon = "👤", Color = Color3.fromRGB(100, 150, 255)},
        {Name = "Combat", Icon = "⚔️", Color = Color3.fromRGB(255, 100, 100)},
        {Name = "Troll", Icon = "😈", Color = Color3.fromRGB(255, 150, 50)},
        {Name = "Teleport", Icon = "📍", Color = Color3.fromRGB(100, 255, 150)},
        {Name = "ESP", Icon = "👁️", Color = Color3.fromRGB(255, 200, 50)},
        {Name = "Visual", Icon = "✨", Color = Color3.fromRGB(200, 100, 255)},
        {Name = "Config", Icon = "⚙️", Color = Color3.fromRGB(150, 150, 150)}
    }
    
    local currentTab = "Player"
    local tabFrames = {}
    
    -- Função para criar elementos
    local function CreateToggle(name, callback, parent)
        local toggle = Instance.new("Frame")
        toggle.Size = UDim2.new(1, -10, 0, 45)
        toggle.BackgroundColor3 = CONFIG.COR_FUNDO_2
        toggle.BackgroundTransparency = 0.3
        toggle.BorderSizePixel = 0
        toggle.Parent = parent
        
        Instance.new("UICorner", toggle).CornerRadius = UDim.new(0, 8)
        
        local glow = Instance.new("UIStroke", toggle)
        glow.Color = CONFIG.COR_FUNDO_3
        glow.Thickness = 1
        glow.Transparency = 0.5
        
        local nameLabel = Instance.new("TextLabel")
        nameLabel.Size = UDim2.new(0.7, 0, 1, 0)
        nameLabel.Position = UDim2.new(0, 12, 0, 0)
        nameLabel.BackgroundTransparency = 1
        nameLabel.Text = name
        nameLabel.TextColor3 = CONFIG.COR_TEXTO
        nameLabel.TextSize = 13
        nameLabel.Font = Enum.Font.Gotham
        nameLabel.TextXAlignment = Enum.TextXAlignment.Left
        nameLabel.Parent = toggle
        
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(0, 45, 0, 24)
        btn.Position = UDim2.new(1, -55, 0.5, -12)
        btn.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
        btn.Text = ""
        btn.BorderSizePixel = 0
        btn.Parent = toggle
        
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 12)
        
        local knob = Instance.new("Frame")
        knob.Size = UDim2.new(0, 18, 0, 18)
        knob.Position = UDim2.new(0, 3, 0, 3)
        knob.BackgroundColor3 = CONFIG.COR_TEXTO
        knob.BorderSizePixel = 0
        knob.Parent = btn
        
        Instance.new("UICorner", knob).CornerRadius = UDim.new(0, 9)
        
        local state = false
        
        btn.MouseButton1Click:Connect(function()
            state = not state
            
            if state then
                Tween(btn, {BackgroundColor3 = GetCurrentColor()}, 0.2)
                Tween(knob, {Position = UDim2.new(0, 24, 0, 3)}, 0.2)
                Tween(glow, {Color = GetCurrentColor(), Transparency = 0}, 0.2)
                btn:SetAttribute("ColorUpdate", true)
                table.insert(UIElements, btn)
            else
                Tween(btn, {BackgroundColor3 = Color3.fromRGB(40, 40, 50)}, 0.2)
                Tween(knob, {Position = UDim2.new(0, 3, 0, 3)}, 0.2)
                Tween(glow, {Color = CONFIG.COR_FUNDO_3, Transparency = 0.5}, 0.2)
                btn:SetAttribute("ColorUpdate", false)
            end
            
            callback(state)
        end)
        
        return toggle
    end
    
    local function CreateSlider(name, min, max, default, callback, parent)
        local slider = Instance.new("Frame")
        slider.Size = UDim2.new(1, -10, 0, 55)
        slider.BackgroundColor3 = CONFIG.COR_FUNDO_2
        slider.BackgroundTransparency = 0.3
        slider.BorderSizePixel = 0
        slider.Parent = parent
        
        Instance.new("UICorner", slider).CornerRadius = UDim.new(0, 8)
        
        local glow = Instance.new("UIStroke", slider)
        glow.Color = CONFIG.COR_FUNDO_3
        glow.Thickness = 1
        glow.Transparency = 0.5
        
        local nameLabel = Instance.new("TextLabel")
        nameLabel.Size = UDim2.new(0.6, 0, 0, 22)
        nameLabel.Position = UDim2.new(0, 12, 0, 5)
        nameLabel.BackgroundTransparency = 1
        nameLabel.Text = name
        nameLabel.TextColor3 = CONFIG.COR_TEXTO
        nameLabel.TextSize = 13
        nameLabel.Font = Enum.Font.Gotham
        nameLabel.TextXAlignment = Enum.TextXAlignment.Left
        nameLabel.Parent = slider
        
        local valueLabel = Instance.new("TextLabel")
        valueLabel.Size = UDim2.new(0.3, 0, 0, 22)
        valueLabel.Position = UDim2.new(0.7, 0, 0, 5)
        valueLabel.BackgroundTransparency = 1
        valueLabel.Text = tostring(default)
        valueLabel.TextColor3 = GetCurrentColor()
        valueLabel.TextSize = 13
        valueLabel.Font = Enum.Font.GothamBold
        valueLabel.TextXAlignment = Enum.TextXAlignment.Right
        valueLabel.Parent = slider
        valueLabel:SetAttribute("TextColorUpdate", true)
        table.insert(UIElements, valueLabel)
        
        local track = Instance.new("Frame")
        track.Size = UDim2.new(1, -24, 0, 5)
        track.Position = UDim2.new(0, 12, 0, 38)
        track.BackgroundColor3 = CONFIG.COR_FUNDO
        track.BorderSizePixel = 0
        track.Parent = slider
        
        Instance.new("UICorner", track).CornerRadius = UDim.new(0, 2.5)
        
        local fill = Instance.new("Frame")
        fill.Size = UDim2.new((default - min) / (max - min), 0, 1, 0)
        fill.BackgroundColor3 = GetCurrentColor()
        fill.BorderSizePixel = 0
        fill.Parent = track
        fill:SetAttribute("ColorUpdate", true)
        table.insert(UIElements, fill)
        
        Instance.new("UICorner", fill).CornerRadius = UDim.new(0, 2.5)
        
        local knob = Instance.new("Frame")
        knob.Size = UDim2.new(0, 13, 0, 13)
        knob.Position = UDim2.new((default - min) / (max - min), -6.5, 0.5, -6.5)
        knob.BackgroundColor3 = CONFIG.COR_TEXTO
        knob.BorderSizePixel = 0
        knob.Parent = track
        
        Instance.new("UICorner", knob).CornerRadius = UDim.new(0, 6.5)
        
        local dragging = false
        
        local function update(input)
            local pos = math.clamp((input.Position.X - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
            local value = math.floor(min + (max - min) * pos)
            
            fill.Size = UDim2.new(pos, 0, 1, 0)
            knob.Position = UDim2.new(pos, -6.5, 0.5, -6.5)
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
        
        return slider
    end
    
    local function CreateButton(text, callback, parent)
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(1, -10, 0, 40)
        btn.BackgroundColor3 = GetCurrentColor()
        btn.BackgroundTransparency = 0.2
        btn.Text = text
        btn.TextColor3 = CONFIG.COR_TEXTO
        btn.TextSize = 13
        btn.Font = Enum.Font.GothamBold
        btn.BorderSizePixel = 0
        btn.Parent = parent
        btn:SetAttribute("ColorUpdate", true)
        table.insert(UIElements, btn)
        
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)
        
        local glow = Instance.new("UIStroke", btn)
        glow.Color = GetCurrentColor()
        glow.Thickness = 0
        glow.Transparency = 1
        glow:SetAttribute("StrokeUpdate", true)
        table.insert(UIElements, glow)
        
        btn.MouseEnter:Connect(function()
            Tween(btn, {BackgroundTransparency = 0}, 0.15)
            Tween(glow, {Thickness = 2, Transparency = 0}, 0.15)
        end)
        
        btn.MouseLeave:Connect(function()
            Tween(btn, {BackgroundTransparency = 0.2}, 0.15)
            Tween(glow, {Thickness = 0, Transparency = 1}, 0.15)
        end)
        
        btn.MouseButton1Click:Connect(callback)
        
        return btn
    end
    
    local function CreateSection(name, parent)
        local section = Instance.new("TextLabel")
        section.Size = UDim2.new(1, -10, 0, 30)
        section.BackgroundColor3 = CONFIG.COR_FUNDO_3
        section.BackgroundTransparency = 0.5
        section.Text = "  " .. name
        section.TextColor3 = GetCurrentColor()
        section.TextSize = 14
        section.Font = Enum.Font.GothamBold
        section.TextXAlignment = Enum.TextXAlignment.Left
        section.BorderSizePixel = 0
        section.Parent = parent
        section:SetAttribute("TextColorUpdate", true)
        table.insert(UIElements, section)
        
        Instance.new("UICorner", section).CornerRadius = UDim.new(0, 8)
        
        return section
    end
    
    -- Player List (GTA Style)
    local playerList = Instance.new("Frame")
    playerList.Size = UDim2.new(0, 180, 1, -70)
    playerList.Position = UDim2.new(0, 10, 0, 70)
    playerList.BackgroundColor3 = CONFIG.COR_FUNDO_2
    playerList.BackgroundTransparency = 0.05
    playerList.BorderSizePixel = 0
    playerList.Visible = false
    playerList.Parent = GUI
    
    Instance.new("UICorner", playerList).CornerRadius = UDim.new(0, 12)
    
    local plGlow = Instance.new("UIStroke", playerList)
    plGlow.Color = GetCurrentColor()
    plGlow.Thickness = 2
    plGlow.Transparency = 0.3
    plGlow:SetAttribute("StrokeUpdate", true)
    table.insert(UIElements, plGlow)
    
    local plTitle = Instance.new("TextLabel")
    plTitle.Size = UDim2.new(1, 0, 0, 35)
    plTitle.BackgroundColor3 = GetCurrentColor()
    plTitle.BackgroundTransparency = 0.2
    plTitle.Text = "👥 JOGADORES"
    plTitle.TextColor3 = CONFIG.COR_TEXTO
    plTitle.TextSize = 13
    plTitle.Font = Enum.Font.GothamBold
    plTitle.BorderSizePixel = 0
    plTitle.Parent = playerList
    plTitle:SetAttribute("ColorUpdate", true)
    table.insert(UIElements, plTitle)
    
    Instance.new("UICorner", plTitle).CornerRadius = UDim.new(0, 12)
    
    local selectedLabel = Instance.new("TextLabel")
    selectedLabel.Size = UDim2.new(1, -10, 0, 28)
    selectedLabel.Position = UDim2.new(0, 5, 0, 40)
    selectedLabel.BackgroundColor3 = CONFIG.COR_FUNDO
    selectedLabel.BackgroundTransparency = 0.3
    selectedLabel.Text = "Nenhum selecionado"
    selectedLabel.TextColor3 = CONFIG.COR_TEXTO_SEC
    selectedLabel.TextSize = 11
    selectedLabel.Font = Enum.Font.Gotham
    selectedLabel.BorderSizePixel = 0
    selectedLabel.Parent = playerList
    
    Instance.new("UICorner", selectedLabel).CornerRadius = UDim.new(0, 7)
    
    local playerScroll = Instance.new("ScrollingFrame")
    playerScroll.Size = UDim2.new(1, -10, 1, -80)
    playerScroll.Position = UDim2.new(0, 5, 0, 73)
    playerScroll.BackgroundTransparency = 1
    playerScroll.BorderSizePixel = 0
    playerScroll.ScrollBarThickness = 3
    playerScroll.ScrollBarImageColor3 = GetCurrentColor()
    playerScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    playerScroll.Parent = playerList
    
    local function UpdatePlayerList()
        for _, child in pairs(playerScroll:GetChildren()) do
            if child:IsA("TextButton") or child:IsA("UIListLayout") then
                child:Destroy()
            end
        end
        
        local playerLayout = Instance.new("UIListLayout")
        playerLayout.Padding = UDim.new(0, 5)
        playerLayout.SortOrder = Enum.SortOrder.LayoutOrder
        playerLayout.Parent = playerScroll
        
        playerLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            playerScroll.CanvasSize = UDim2.new(0, 0, 0, playerLayout.AbsoluteContentSize.Y + 5)
        end)
        
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= LocalPlayer then
                local playerBtn = Instance.new("TextButton")
                playerBtn.Size = UDim2.new(1, -5, 0, 35)
                playerBtn.BackgroundColor3 = CONFIG.COR_FUNDO
                playerBtn.BackgroundTransparency = 0.5
                playerBtn.Text = " " .. player.Name
                playerBtn.TextColor3 = CONFIG.COR_TEXTO
                playerBtn.TextSize = 12
                playerBtn.Font = Enum.Font.Gotham
                playerBtn.TextXAlignment = Enum.TextXAlignment.Left
                playerBtn.BorderSizePixel = 0
                playerBtn.Parent = playerScroll
                
                Instance.new("UICorner", playerBtn).CornerRadius = UDim.new(0, 7)
                
                if SelectedPlayer == player then
                    playerBtn.BackgroundColor3 = GetCurrentColor()
                    playerBtn.BackgroundTransparency = 0.2
                    playerBtn.TextColor3 = CONFIG.COR_TEXTO
                end
                
                playerBtn.MouseButton1Click:Connect(function()
                    SelectedPlayer = player
                    selectedLabel.Text = player.Name
                    selectedLabel.TextColor3 = GetCurrentColor()
                    
                    for _, btn in pairs(playerScroll:GetChildren()) do
                        if btn:IsA("TextButton") then
                            Tween(btn, {BackgroundColor3 = CONFIG.COR_FUNDO, BackgroundTransparency = 0.5}, 0.15)
                            btn.TextColor3 = CONFIG.COR_TEXTO
                        end
                    end
                    
                    Tween(playerBtn, {BackgroundColor3 = GetCurrentColor(), BackgroundTransparency = 0.2}, 0.15)
                end)
                
                playerBtn.MouseEnter:Connect(function()
                    if SelectedPlayer ~= player then
                        Tween(playerBtn, {BackgroundTransparency = 0.3}, 0.15)
                    end
                end)
                
                playerBtn.MouseLeave:Connect(function()
                    if SelectedPlayer ~= player then
                        Tween(playerBtn, {BackgroundTransparency = 0.5}, 0.15)
                    end
                end)
            end
        end
    end
    
    UpdatePlayerList()
    
    task.spawn(function()
        while GUI do
            UpdatePlayerList()
            task.wait(3)
        end
    end)
    
    -- Criar Tabs
    for i, tab in ipairs(tabs) do
        -- Tab Button (Vertical GTA Style)
        local tabBtn = Instance.new("TextButton")
        tabBtn.Size = UDim2.new(1, 0, 0, 55)
        tabBtn.BackgroundColor3 = CONFIG.COR_FUNDO_2
        tabBtn.BackgroundTransparency = 0.3
        tabBtn.Text = ""
        tabBtn.BorderSizePixel = 0
        tabBtn.Parent = sidebarScroll
        
        Instance.new("UICorner", tabBtn).CornerRadius = UDim.new(0, 10)
        
        local tabGlow = Instance.new("UIStroke", tabBtn)
        tabGlow.Color = CONFIG.COR_FUNDO_3
        tabGlow.Thickness = 1
        tabGlow.Transparency = 0.5
        
        local tabIcon = Instance.new("TextLabel")
        tabIcon.Size = UDim2.new(1, 0, 0, 28)
        tabIcon.Position = UDim2.new(0, 0, 0, 5)
        tabIcon.BackgroundTransparency = 1
        tabIcon.Text = tab.Icon
        tabIcon.TextColor3 = CONFIG.COR_TEXTO
        tabIcon.TextSize = 24
        tabIcon.Font = Enum.Font.GothamBold
        tabIcon.Parent = tabBtn
        
        local tabName = Instance.new("TextLabel")
        tabName.Size = UDim2.new(1, 0, 0, 18)
        tabName.Position = UDim2.new(0, 0, 0, 32)
        tabName.BackgroundTransparency = 1
        tabName.Text = tab.Name
        tabName.TextColor3 = CONFIG.COR_TEXTO_SEC
        tabName.TextSize = 10
        tabName.Font = Enum.Font.Gotham
        tabName.Parent = tabBtn
        
        -- Tab Frame
        local tabFrame = Instance.new("ScrollingFrame")
        tabFrame.Size = UDim2.new(1, 0, 1, 0)
        tabFrame.BackgroundTransparency = 1
        tabFrame.BorderSizePixel = 0
        tabFrame.ScrollBarThickness = 4
        tabFrame.ScrollBarImageColor3 = GetCurrentColor()
        tabFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
        tabFrame.Visible = false
        tabFrame.Parent = tabContent
        
        local layout = Instance.new("UIListLayout")
        layout.Padding = UDim.new(0, 8)
        layout.SortOrder = Enum.SortOrder.LayoutOrder
        layout.Parent = tabFrame
        
        layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            tabFrame.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 8)
        end)
        
        tabFrames[tab.Name] = tabFrame
        
        tabBtn.MouseButton1Click:Connect(function()
            currentTab = tab.Name
            
            -- Mostrar/esconder player list
            if tab.Name == "Combat" or tab.Name == "Troll" or tab.Name == "Teleport" then
                playerList.Visible = true
                playerList.Position = UDim2.new(0, 10, 0, 70)
            else
                playerList.Visible = false
            end
            
            -- Atualizar tabs
            for name, frame in pairs(tabFrames) do
                frame.Visible = (name == tab.Name)
            end
            
            -- Atualizar visual dos botões
            for _, btn in pairs(sidebarScroll:GetChildren()) do
                if btn:IsA("TextButton") then
                    local glow = btn:FindFirstChildOfClass("UIStroke")
                    Tween(btn, {BackgroundTransparency = 0.3}, 0.15)
                    if glow then
                        Tween(glow, {Color = CONFIG.COR_FUNDO_3, Transparency = 0.5}, 0.15)
                    end
                    for _, label in pairs(btn:GetChildren()) do
                        if label:IsA("TextLabel") and label.Text ~= tab.Icon then
                            label.TextColor3 = CONFIG.COR_TEXTO_SEC
                        end
                    end
                end
            end
            
            Tween(tabBtn, {BackgroundTransparency = 0}, 0.15)
            Tween(tabGlow, {Color = GetCurrentColor(), Transparency = 0}, 0.15)
            tabName.TextColor3 = GetCurrentColor()
        end)
        
        if i == 1 then
            tabBtn.BackgroundTransparency = 0
            tabGlow.Color = GetCurrentColor()
            tabGlow.Transparency = 0
            tabName.TextColor3 = GetCurrentColor()
            tabFrame.Visible = true
        end
    end
    
    -- ═══════════════ CONTEÚDO DAS ABAS ═══════════════
    
    -- ABA PLAYER
    CreateSection("✈️ MOVIMENTO", tabFrames["Player"])
    CreateToggle("✈️ Fly (WASD + Space/Shift)", ToggleFly, tabFrames["Player"])
    CreateSlider("Velocidade Fly", 10, 300, SavedStates.FlySpeed, function(value)
        SavedStates.FlySpeed = value
    end, tabFrames["Player"])
    
    CreateToggle("👻 Noclip", ToggleNoclip, tabFrames["Player"])
    CreateToggle("🦘 Pulo Infinito", ToggleInfJump, tabFrames["Player"])
    CreateToggle("🏊 Andar na Água", ToggleSwim, tabFrames["Player"])
    
    CreateSection("⚡ VELOCIDADE", tabFrames["Player"])
    CreateSlider("🏃 WalkSpeed", 16, 400, SavedStates.WalkSpeed, function(value)
        SavedStates.WalkSpeed = value
    end, tabFrames["Player"])
    
    CreateSlider("⬆️ JumpPower", 50, 600, SavedStates.JumpPower, function(value)
        SavedStates.JumpPower = value
    end, tabFrames["Player"])
    
    CreateSection("🛡️ PROTEÇÃO", tabFrames["Player"])
    CreateToggle("🛡️ God Mode", ToggleGodMode, tabFrames["Player"])
    CreateToggle("👻 Invisível", ToggleInvisible, tabFrames["Player"])
    
    CreateSection("🎨 APARÊNCIA", tabFrames["Player"])
    CreateButton("💺 Sentar/Levantar", function()
        local char = LocalPlayer.Character
        if char then
            local humanoid = char:FindFirstChildOfClass("Humanoid")
            if humanoid then
                humanoid.Sit = not humanoid.Sit
                Notify(humanoid.Sit and "💺 Sentado" or "🚶 Em pé", CONFIG.COR_SUCESSO)
            end
        end
    end, tabFrames["Player"])
    
    CreateButton("🎩 Remover Acessórios", function()
        local char = LocalPlayer.Character
        if char then
            for _, item in pairs(char:GetChildren()) do
                if item:IsA("Accessory") then
                    item:Destroy()
                end
            end
            Notify("🎩 Acessórios removidos", CONFIG.COR_SUCESSO)
        end
    end, tabFrames["Player"])
    
    CreateButton("🔄 Resetar Personagem", function()
        local char = LocalPlayer.Character
        if char then
            local humanoid = char:FindFirstChildOfClass("Humanoid")
            if humanoid then
                humanoid.Health = 0
                Notify("🔄 Personagem resetado", CONFIG.COR_SUCESSO)
            end
        end
    end, tabFrames["Player"])
    
    -- ABA COMBAT
    CreateSection("💀 AÇÕES DE COMBATE", tabFrames["Combat"])
    CreateButton("💀 Eliminar Jogador", function()
        if not SelectedPlayer or not SelectedPlayer.Parent then
            Notify("⚠️ Selecione um jogador!", CONFIG.COR_ERRO)
            return
        end
        local targetChar = SelectedPlayer.Character
        if targetChar then
            local humanoid = targetChar:FindFirstChildOfClass("Humanoid")
            if humanoid then
                humanoid.Health = 0
                Notify("💀 " .. SelectedPlayer.Name .. " eliminado", CONFIG.COR_SUCESSO)
            end
        end
    end, tabFrames["Combat"])
    
    CreateButton("🌪️ Fling (Arremessar)", FlingPlayer, tabFrames["Combat"])
    
    CreateSection("👁️ OBSERVAÇÃO", tabFrames["Combat"])
    CreateToggle("👁️ Espectatar Jogador", ToggleSpectatePlayer, tabFrames["Combat"])
    CreateToggle("🚶 Seguir Jogador", ToggleFollowPlayer, tabFrames["Combat"])
    CreateToggle("🌀 Orbitar Jogador", ToggleOrbitPlayer, tabFrames["Combat"])
    
    -- ABA TROLL
    CreateSection("😈 TROLLAGEM AVANÇADA", tabFrames["Troll"])
    CreateButton("👔 Copiar Roupa", CopyOutfit, tabFrames["Troll"])
    CreateButton("💃 Dançar no Jogador", DanceOnPlayer, tabFrames["Troll"])
    CreateButton("🍑 Rebolar no Jogador", TwerkOnPlayer, tabFrames["Troll"])
    
    CreateSection("🎪 EFEITOS", tabFrames["Troll"])
    CreateButton("🌀 Girar Jogador", function()
        if not SelectedPlayer or not SelectedPlayer.Parent then
            Notify("⚠️ Selecione um jogador!", CONFIG.COR_ERRO)
            return
        end
        
        local targetChar = SelectedPlayer.Character
        if targetChar then
            local root = targetChar:FindFirstChild("HumanoidRootPart")
            if root then
                local spin = Instance.new("BodyAngularVelocity")
                spin.MaxTorque = Vector3.new(0, math.huge, 0)
                spin.AngularVelocity = Vector3.new(0, 100, 0)
                spin.Parent = root
                
                task.delay(5, function()
                    if spin and spin.Parent then
                        spin:Destroy()
                    end
                end)
                
                Notify("🌀 " .. SelectedPlayer.Name .. " girando!", CONFIG.COR_SUCESSO)
            end
        end
    end, tabFrames["Troll"])
    
    CreateButton("🔊 Spam Sons", function()
        if not SelectedPlayer or not SelectedPlayer.Parent then
            Notify("⚠️ Selecione um jogador!", CONFIG.COR_ERRO)
            return
        end
        
        local targetChar = SelectedPlayer.Character
        if targetChar then
            local sounds = {
                "130768805", "130776150", "130777688", "130785805"
            }
            
            for i = 1, 20 do
                task.spawn(function()
                    local sound = Instance.new("Sound")
                    sound.SoundId = "rbxassetid://" .. sounds[math.random(1, #sounds)]
                    sound.Volume = 5
                    sound.Parent = targetChar.HumanoidRootPart or targetChar.Head
                    sound:Play()
                    task.wait(sound.TimeLength)
                    sound:Destroy()
                end)
            end
            
            Notify("🔊 Sons spammados!", CONFIG.COR_SUCESSO)
        end
    end, tabFrames["Troll"])
    
    CreateButton("🔥 Benx Player", function()
        if not SelectedPlayer or not SelectedPlayer.Parent then
            Notify("⚠️ Selecione um jogador!", CONFIG.COR_ERRO)
            return
        end
        
        local targetChar = SelectedPlayer.Character
        if targetChar then
            for _, part in pairs(targetChar:GetChildren()) do
                if part:IsA("BasePart") then
                    local fire = Instance.new("Fire")
                    fire.Size = 10
                    fire.Heat = 15
                    fire.Parent = part
                end
            end
            
            Notify("🔥 " .. SelectedPlayer.Name .. " em chamas!", CONFIG.COR_SUCESSO)
        end
    end, tabFrames["Troll"])
    
    -- ABA TELEPORT
    CreateSection("🚀 TELEPORTE", tabFrames["Teleport"])
    CreateButton("🚀 Teleportar para Jogador", TeleportToPlayer, tabFrames["Teleport"])
    
    CreateButton("🏠 Spawn", function()
        local char = LocalPlayer.Character
        if char then
            local root = char:FindFirstChild("HumanoidRootPart")
            if root then
                local spawn = workspace:FindFirstChildOfClass("SpawnLocation")
                if spawn then
                    root.CFrame = spawn.CFrame + Vector3.new(0, 5, 0)
                else
                    root.CFrame = CFrame.new(0, 50, 0)
                end
                Notify("🏠 Spawn!", CONFIG.COR_SUCESSO)
            end
        end
    end, tabFrames["Teleport"])
    
    CreateSection("📌 POSIÇÕES SALVAS", tabFrames["Teleport"])
    CreateButton("📌 Salvar Posição", function()
        local char = LocalPlayer.Character
        if char then
            local root = char:FindFirstChild("HumanoidRootPart")
            if root then
                SavedStates.SavedPosition = root.CFrame
                Notify("✅ Posição salva!", CONFIG.COR_SUCESSO)
            end
        end
    end, tabFrames["Teleport"])
    
    CreateButton("📍 Voltar à Posição", function()
        if not SavedStates.SavedPosition then
            Notify("⚠️ Nenhuma posição salva!", CONFIG.COR_ERRO)
            return
        end
        local char = LocalPlayer.Character
        if char then
            local root = char:FindFirstChild("HumanoidRootPart")
            if root then
                root.CFrame = SavedStates.SavedPosition
                Notify("📍 Teleportado!", CONFIG.COR_SUCESSO)
            end
        end
    end, tabFrames["Teleport"])
    
    -- ABA ESP
    CreateSection("👁️ ESP GERAL", tabFrames["ESP"])
    CreateToggle("👁️ Ativar ESP", ToggleESP, tabFrames["ESP"])
    
    CreateSection("📦 OPÇÕES DE ESP", tabFrames["ESP"])
    CreateToggle("📦 Box ESP", function(state)
        SavedStates.ESPBox = state
        if SavedStates.ESPEnabled then
            ToggleESP(false)
            task.wait(0.1)
            ToggleESP(true)
        end
    end, tabFrames["ESP"])
    
    CreateToggle("📏 Tracers", function(state)
        SavedStates.ESPTracers = state
        if SavedStates.ESPEnabled then
            ToggleESP(false)
            task.wait(0.1)
            ToggleESP(true)
        end
    end, tabFrames["ESP"])
    
    CreateToggle("📝 Nome", function(state)
        SavedStates.ESPName = state
        if SavedStates.ESPEnabled then
            ToggleESP(false)
            task.wait(0.1)
            ToggleESP(true)
        end
    end, tabFrames["ESP"])
    
    CreateToggle("📍 Distância", function(state)
        SavedStates.ESPDistance = state
        if SavedStates.ESPEnabled then
            ToggleESP(false)
            task.wait(0.1)
            ToggleESP(true)
        end
    end, tabFrames["ESP"])
    
    CreateToggle("❤️ Barra de Vida", function(state)
        SavedStates.ESPHealth = state
        if SavedStates.ESPEnabled then
            ToggleESP(false)
            task.wait(0.1)
            ToggleESP(true)
        end
    end, tabFrames["ESP"])
    
    CreateToggle("✨ Chams (Highlight)", function(state)
        SavedStates.ESPChams = state
        if SavedStates.ESPEnabled then
            ToggleESP(false)
            task.wait(0.1)
            ToggleESP(true)
        end
    end, tabFrames["ESP"])
    
    CreateToggle("🎨 Cor do Time", function(state)
        SavedStates.ESPTeamColor = state
        if SavedStates.ESPEnabled then
            ToggleESP(false)
            task.wait(0.1)
            ToggleESP(true)
        end
    end, tabFrames["ESP"])
    
    -- ABA VISUAL
    CreateSection("💡 ILUMINAÇÃO", tabFrames["Visual"])
    CreateToggle("💡 Fullbright", ToggleFullbright, tabFrames["Visual"])
    
    CreateToggle("🌫️ Remover Fog", function(state)
        SavedStates.RemoveFog = state
        Lighting.FogEnd = state and 1e10 or 1e5
        Notify(state and "🌫️ Fog removido" or "🌫️ Fog restaurado", state and CONFIG.COR_SUCESSO or CONFIG.COR_ERRO)
    end, tabFrames["Visual"])
    
    CreateSlider("🔭 FOV", 70, 120, SavedStates.FOV, function(value)
        SavedStates.FOV = value
        Camera.FieldOfView = value
    end, tabFrames["Visual"])
    
    CreateSection("⏰ TEMPO", tabFrames["Visual"])
    CreateButton("☀️ Dia Permanente", function()
        Lighting.ClockTime = 14
        if Connections.TimeFreeze then Connections.TimeFreeze:Disconnect() end
        Connections.TimeFreeze = RunService.Heartbeat:Connect(function()
            Lighting.ClockTime = 14
        end)
        Notify("☀️ Dia permanente!", CONFIG.COR_SUCESSO)
    end, tabFrames["Visual"])
    
    CreateButton("🌙 Noite Permanente", function()
        Lighting.ClockTime = 0
        if Connections.TimeFreeze then Connections.TimeFreeze:Disconnect() end
        Connections.TimeFreeze = RunService.Heartbeat:Connect(function()
            Lighting.ClockTime = 0
        end)
        Notify("🌙 Noite permanente!", CONFIG.COR_SUCESSO)
    end, tabFrames["Visual"])
    
    CreateSection("⚡ PERFORMANCE", tabFrames["Visual"])
    CreateButton("⚡ Otimizar FPS", function()
        settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
        for _, obj in ipairs(workspace:GetDescendants()) do
            if obj:IsA("ParticleEmitter") or obj:IsA("Trail") or obj:IsA("Smoke") or obj:IsA("Fire") or obj:IsA("Sparkles") then
                obj.Enabled = false
            end
        end
        Notify("⚡ FPS otimizado!", CONFIG.COR_SUCESSO)
    end, tabFrames["Visual"])
    
    -- ABA CONFIG
    CreateSection("🎨 PERSONALIZAÇÃO", tabFrames["Config"])
    CreateToggle("🌈 Modo Rainbow", function(state)
        SavedStates.RainbowMode = state
        
        if Connections.MenuRainbow then
            Connections.MenuRainbow:Disconnect()
            Connections.MenuRainbow = nil
        end
        
        if state then
            Connections.MenuRainbow = RunService.Heartbeat:Connect(function()
                RainbowHue = (RainbowHue + 0.003) % 1
                UpdateAllColors()
            end)
            Notify("🌈 Modo Rainbow ativado!", CONFIG.COR_SUCESSO)
        else
            SavedStates.CustomColor = nil
            UpdateAllColors()
            Notify("🌈 Modo desativado", CONFIG.COR_ERRO)
        end
    end, tabFrames["Config"])
    
    CreateSection("🎨 CORES PREDEFINIDAS", tabFrames["Config"])
    local presetColors = {
        {Name = "🟣 Roxo", Color = Color3.fromRGB(139, 0, 255)},
        {Name = "🔴 Vermelho", Color = Color3.fromRGB(255, 50, 80)},
        {Name = "🔵 Azul", Color = Color3.fromRGB(50, 150, 255)},
        {Name = "🟢 Verde", Color = Color3.fromRGB(0, 255, 100)},
        {Name = "🟡 Amarelo", Color = Color3.fromRGB(255, 220, 0)},
        {Name = "💗 Rosa", Color = Color3.fromRGB(255, 100, 200)},
    }
    
    for _, preset in ipairs(presetColors) do
        CreateButton(preset.Name, function()
            if SavedStates.RainbowMode then
                Notify("⚠️ Desative o Rainbow!", CONFIG.COR_ERRO)
                return
            end
            SavedStates.CustomColor = preset.Color
            UpdateAllColors()
            Notify("🎨 Cor alterada!", CONFIG.COR_SUCESSO)
        end, tabFrames["Config"])
    end
    
    CreateSection("ℹ️ INFORMAÇÕES", tabFrames["Config"])
    CreateButton("📊 Estatísticas", function()
        local info = string.format([[🟣 SHAKA Hub %s
━━━━━━━━━━━━━━━━━
📊 FPS: %d
👥 Jogadores: %d
⚡ Ping: %d ms
🎮 Jogo: %s]],
            CONFIG.VERSAO,
            math.floor(workspace:GetRealPhysicsFPS()),
            #Players:GetPlayers(),
            math.floor(LocalPlayer:GetNetworkPing() * 1000),
            game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId).Name or "Unknown"
        )
        Notify(info, GetCurrentColor())
    end, tabFrames["Config"])
    
    CreateButton("🔄 Resetar Config", function()
        SavedStates = {
            FlyEnabled = false,
            FlySpeed = 50,
            NoclipEnabled = false,
            InfJumpEnabled = false,
            WalkSpeed = 16,
            JumpPower = 50,
            GodMode = false,
            InvisibleEnabled = false,
            Swim = false,
            FollowPlayer = false,
            SpectatePlayer = false,
            OrbitPlayer = false,
            ESPEnabled = false,
            ESPBox = true,
            ESPName = true,
            ESPDistance = true,
            ESPHealth = true,
            ESPTracers = true,
            ESPChams = false,
            ESPTeamColor = false,
            Fullbright = false,
            RemoveFog = false,
            FOV = 70,
            RainbowMode = false,
            CustomColor = nil,
            MenuScale = 1
        }
        Notify("🔄 Configurações resetadas!\nReabra (F)", CONFIG.COR_SUCESSO)
    end, tabFrames["Config"])
    
    -- Animação de entrada (GTA Style - slide from right)
    main.Position = UDim2.new(1, 50, 0.5, -(baseHeight * scale)/2)
    Tween(main, {Position = UDim2.new(1, -((baseWidth * scale) + 20), 0.5, -(baseHeight * scale)/2)}, 0.4)
    
    Log("Menu GTA RP carregado!")
    Notify("🟣 SHAKA Hub " .. CONFIG.VERSAO .. " carregado!\nPressione F para fechar/abrir", GetCurrentColor())
end

-- ════════════════════════════════════════════════════════════
-- RECARREGAR ESTADOS
-- ════════════════════════════════════════════════════════════
local function ReloadSavedStates()
    task.wait(0.5)
    
    if SavedStates.FlyEnabled then ToggleFly(true) end
    if SavedStates.NoclipEnabled then ToggleNoclip(true) end
    if SavedStates.InfJumpEnabled then ToggleInfJump(true) end
    if SavedStates.GodMode then ToggleGodMode(true) end
    if SavedStates.ESPEnabled then ToggleESP(true) end
    if SavedStates.Fullbright then ToggleFullbright(true) end
    if SavedStates.RemoveFog then Lighting.FogEnd = 1e10 end
    if SavedStates.InvisibleEnabled then ToggleInvisible(true) end
    if SavedStates.Swim then ToggleSwim(true) end
    
    Camera.FieldOfView = SavedStates.FOV
    
    if SavedStates.RainbowMode then
        if Connections.MenuRainbow then Connections.MenuRainbow:Disconnect() end
        Connections.MenuRainbow = RunService.Heartbeat:Connect(function()
            RainbowHue = (RainbowHue + 0.003) % 1
            UpdateAllColors()
        end)
    end
end

-- ════════════════════════════════════════════════════════════
-- INICIALIZAÇÃO
-- ════════════════════════════════════════════════════════════
Log("════════════════════════════════════════")
Log("  🟣 SHAKA Hub GTA RP " .. CONFIG.VERSAO)
Log("  🎮 Edition Premium")
Log("════════════════════════════════════════")

task.wait(0.3)

CreateGUI()
ReloadSavedStates()

-- ════════════════════════════════════════════════════════════
-- CONTROLES
-- ════════════════════════════════════════════════════════════
UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    
    if input.KeyCode == Enum.KeyCode.F then
        if GUI then
            local main = GUI:FindFirstChild("Main")
            if main then
                Tween(main, {Position = UDim2.new(1, 50, 0.5, -290)}, 0.3)
                task.wait(0.3)
            end
            GUI:Destroy()
            GUI = nil
            Log("Menu fechado")
        else
            CreateGUI()
            ReloadSavedStates()
            Log("Menu aberto")
        end
    end
end)

-- ════════════════════════════════════════════════════════════
-- EVENTOS
-- ════════════════════════════════════════════════════════════
LocalPlayer.CharacterAdded:Connect(function()
    task.wait(1)
    ReloadSavedStates()
    Log("Personagem resetado - estados recarregados")
end)

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
            if esp.Chams then
                for _, cham in pairs(esp.Chams) do
                    cham:Destroy()
                end
            end
        end)
        ESPObjects[player] = nil
    end
    
    if SelectedPlayer == player then
        SelectedPlayer = nil
    end
end)

Log("✅ SHAKA Hub carregado com sucesso!")
Log("⌨️  Pressione F para abrir/fechar")
Log("🎨 Layout GTA RP implementado")
Log("😈 Novas funções: Dançar, Rebolar, Orbitar")
Log("👁️ ESP otimizado com Chams")
Log("🚶 Sistema de Follow e Spectate")
Log("🏊 Andar na água e muito mais!")
Log("════════════════════════════════════════")
