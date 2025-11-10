-- SHAKA Hub Premium v8.0 - Launch Edition
-- Designer Moderno | Sistema Completo | Otimizado
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
    VERSAO = "v8.0",
    COR_ROXO = Color3.fromRGB(139, 0, 255),
    COR_FUNDO = Color3.fromRGB(15, 15, 20),
    COR_FUNDO_2 = Color3.fromRGB(22, 22, 30),
    COR_FUNDO_3 = Color3.fromRGB(28, 28, 38),
    COR_TEXTO = Color3.fromRGB(255, 255, 255),
    COR_TEXTO_SEC = Color3.fromRGB(160, 160, 170),
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
    InfStaminaEnabled = false,
    
    -- ESP
    ESPEnabled = false,
    ESPBox = true,
    ESPLine = true,
    ESPName = true,
    ESPDistance = true,
    ESPHealth = true,
    ESPSkeleton = false,
    ESPTracers = true,
    
    -- Visual
    Fullbright = false,
    RemoveFog = false,
    RemoveShadows = false,
    FOV = 70,
    Brightness = 1,
    
    -- Config
    RainbowMode = false,
    CustomColor = nil,
    MenuScale = 0.85
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
        return CONFIG.COR_ROXO
    end
end

local function UpdateAllColors()
    if not GUI then return end
    local currentColor = GetCurrentColor()
    
    for _, element in pairs(UIElements) do
        if element and element.Parent then
            pcall(function()
                if element:IsA("Frame") or element:IsA("TextButton") or element:IsA("TextLabel") then
                    if element:GetAttribute("ColorUpdate") then
                        TweenService:Create(element, TweenInfo.new(0.2), {BackgroundColor3 = currentColor}):Play()
                    end
                elseif element:IsA("UIStroke") then
                    TweenService:Create(element, TweenInfo.new(0.2), {Color = currentColor}):Play()
                elseif element:IsA("TextLabel") then
                    if element:GetAttribute("TextColorUpdate") then
                        TweenService:Create(element, TweenInfo.new(0.2), {TextColor3 = currentColor}):Play()
                    end
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
        notif.Size = UDim2.new(0, 280, 0, 65)
        notif.Position = UDim2.new(1, -290, 1, 10)
        notif.BackgroundColor3 = CONFIG.COR_FUNDO_2
        notif.BorderSizePixel = 0
        notif.Parent = GUI
        notif.ZIndex = 1000
        
        Instance.new("UICorner", notif).CornerRadius = UDim.new(0, 12)
        local stroke = Instance.new("UIStroke", notif)
        stroke.Color = color or GetCurrentColor()
        stroke.Thickness = 2
        
        local icon = Instance.new("TextLabel")
        icon.Size = UDim2.new(0, 40, 0, 40)
        icon.Position = UDim2.new(0, 10, 0.5, -20)
        icon.BackgroundColor3 = color or GetCurrentColor()
        icon.Text = color == CONFIG.COR_SUCESSO and "✓" or (color == CONFIG.COR_ERRO and "✕" or "!")
        icon.TextColor3 = CONFIG.COR_TEXTO
        icon.TextSize = 24
        icon.Font = Enum.Font.GothamBold
        icon.BorderSizePixel = 0
        icon.Parent = notif
        Instance.new("UICorner", icon).CornerRadius = UDim.new(0, 8)
        
        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(1, -65, 1, -10)
        label.Position = UDim2.new(0, 55, 0, 5)
        label.BackgroundTransparency = 1
        label.Text = text
        label.TextColor3 = CONFIG.COR_TEXTO
        label.TextSize = 13
        label.Font = Enum.Font.Gotham
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.TextYAlignment = Enum.TextYAlignment.Top
        label.TextWrapped = true
        label.Parent = notif
        
        Tween(notif, {Position = UDim2.new(1, -290, 1, -75)}, 0.3)
        task.wait(3)
        Tween(notif, {Position = UDim2.new(1, 10, 1, -75)}, 0.3)
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
        Notify("👻 Você está invisível!", CONFIG.COR_SUCESSO)
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

local function SitPlayer()
    local char = LocalPlayer.Character
    if char then
        local humanoid = char:FindFirstChildOfClass("Humanoid")
        if humanoid then
            humanoid.Sit = not humanoid.Sit
            Notify(humanoid.Sit and "💺 Sentado" or "🚶 Em pé", CONFIG.COR_SUCESSO)
        end
    end
end

local function RemoveAccessories()
    local char = LocalPlayer.Character
    if char then
        for _, item in pairs(char:GetChildren()) do
            if item:IsA("Accessory") then
                item:Destroy()
            end
        end
        Notify("🎩 Acessórios removidos", CONFIG.COR_SUCESSO)
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
-- FUNÇÕES DE TELEPORTE
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

-- ════════════════════════════════════════════════════════════
-- FUNÇÕES DE TROLL
-- ════════════════════════════════════════════════════════════
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
    
    -- Remover acessórios atuais
    for _, item in pairs(char:GetChildren()) do
        if item:IsA("Accessory") or item:IsA("Shirt") or item:IsA("Pants") then
            item:Destroy()
        end
    end
    
    -- Copiar roupas
    for _, item in pairs(targetChar:GetChildren()) do
        if item:IsA("Accessory") or item:IsA("Shirt") or item:IsA("Pants") then
            local clone = item:Clone()
            clone.Parent = char
        end
    end
    
    -- Copiar cores do corpo
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

local function SpinPlayer()
    if not SelectedPlayer or not SelectedPlayer.Parent then
        Notify("⚠️ Selecione um jogador primeiro!", CONFIG.COR_ERRO)
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
end

local function BenxPlayer()
    if not SelectedPlayer or not SelectedPlayer.Parent then
        Notify("⚠️ Selecione um jogador primeiro!", CONFIG.COR_ERRO)
        return
    end
    
    local targetChar = SelectedPlayer.Character
    if targetChar then
        local humanoid = targetChar:FindFirstChildOfClass("Humanoid")
        if humanoid then
            for i = 1, 10 do
                task.spawn(function()
                    local sound = Instance.new("Sound")
                    sound.SoundId = "rbxassetid://130768805"
                    sound.Volume = 10
                    sound.Parent = targetChar.Head or targetChar.HumanoidRootPart
                    sound:Play()
                    task.wait(sound.TimeLength)
                    sound:Destroy()
                end)
            end
            
            for _, part in pairs(targetChar:GetChildren()) do
                if part:IsA("BasePart") then
                    local fire = Instance.new("Fire")
                    fire.Size = 10
                    fire.Heat = 15
                    fire.Parent = part
                end
            end
            
            Notify("😈 " .. SelectedPlayer.Name .. " foi benxado!", CONFIG.COR_SUCESSO)
        end
    end
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

local function SpamSounds()
    if not SelectedPlayer or not SelectedPlayer.Parent then
        Notify("⚠️ Selecione um jogador primeiro!", CONFIG.COR_ERRO)
        return
    end
    
    local targetChar = SelectedPlayer.Character
    if targetChar then
        local sounds = {
            "130768805", -- Oof
            "130776150", -- Drinking
            "130777688", -- Splash
            "130785805"  -- Click
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
        
        Notify("🔊 Sons spammados em " .. SelectedPlayer.Name, CONFIG.COR_SUCESSO)
    end
end

-- ════════════════════════════════════════════════════════════
-- SISTEMA DE ESP (MELHORADO)
-- ════════════════════════════════════════════════════════════
local function ClearESP()
    for _, esp in pairs(ESPObjects) do
        pcall(function()
            if esp.Box then esp.Box:Remove() end
            if esp.Line then esp.Line:Remove() end
            if esp.Name then esp.Name:Remove() end
            if esp.Distance then esp.Distance:Remove() end
            if esp.Health then esp.Health:Remove() end
            if esp.Tracer then esp.Tracer:Remove() end
            if esp.Skeleton then
                for _, line in pairs(esp.Skeleton) do
                    line:Remove()
                end
            end
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
        Line = nil,
        Name = nil,
        Distance = nil,
        Health = nil,
        Tracer = nil,
        Skeleton = {}
    }
    
    if SavedStates.ESPBox then
        esp.Box = Drawing.new("Square")
        esp.Box.Thickness = 2
        esp.Box.Filled = false
        esp.Box.Color = Color3.new(1, 0, 1)
        esp.Box.Transparency = 1
        esp.Box.Visible = false
    end
    
    if SavedStates.ESPTracers then
        esp.Tracer = Drawing.new("Line")
        esp.Tracer.Thickness = 2
        esp.Tracer.Color = Color3.new(1, 0, 1)
        esp.Tracer.Transparency = 1
        esp.Tracer.Visible = false
    end
    
    if SavedStates.ESPName then
        esp.Name = Drawing.new("Text")
        esp.Name.Size = 16
        esp.Name.Center = true
        esp.Name.Outline = true
        esp.Name.Color = Color3.new(1, 1, 1)
        esp.Name.Transparency = 1
        esp.Name.Visible = false
        esp.Name.Text = player.Name
    end
    
    if SavedStates.ESPDistance then
        esp.Distance = Drawing.new("Text")
        esp.Distance.Size = 14
        esp.Distance.Center = true
        esp.Distance.Outline = true
        esp.Distance.Color = Color3.new(1, 1, 0)
        esp.Distance.Transparency = 1
        esp.Distance.Visible = false
    end
    
    if SavedStates.ESPHealth then
        esp.Health = Drawing.new("Line")
        esp.Health.Thickness = 4
        esp.Health.Transparency = 1
        esp.Health.Visible = false
    end
    
    if SavedStates.ESPSkeleton then
        local parts = {"Head", "UpperTorso", "LowerTorso", "LeftUpperArm", "LeftLowerArm", "LeftHand", "RightUpperArm", "RightLowerArm", "RightHand", "LeftUpperLeg", "LeftLowerLeg", "LeftFoot", "RightUpperLeg", "RightLowerLeg", "RightFoot"}
        for i = 1, 10 do
            local line = Drawing.new("Line")
            line.Thickness = 2
            line.Color = Color3.new(1, 1, 1)
            line.Transparency = 1
            line.Visible = false
            table.insert(esp.Skeleton, line)
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
                if esp.Skeleton then
                    for _, line in pairs(esp.Skeleton) do
                        line:Remove()
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
            if esp.Skeleton then
                for _, line in pairs(esp.Skeleton) do
                    line.Visible = false
                end
            end
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
                    esp.Box.Position = Vector2.new(rootPos.X - width/2, rootPos.Y - height/2)
                    esp.Box.Visible = true
                end
                
                if esp.Tracer and SavedStates.ESPTracers then
                    esp.Tracer.From = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
                    esp.Tracer.To = Vector2.new(rootPos.X, rootPos.Y)
                    esp.Tracer.Visible = true
                end
                
                if esp.Name and SavedStates.ESPName then
                    esp.Name.Position = Vector2.new(rootPos.X, headPos.Y - 25)
                    esp.Name.Text = player.Name
                    esp.Name.Visible = true
                end
                
                if esp.Distance and SavedStates.ESPDistance and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                    local distance = (LocalPlayer.Character.HumanoidRootPart.Position - root.Position).Magnitude
                    esp.Distance.Position = Vector2.new(rootPos.X, legPos.Y + 5)
                    esp.Distance.Text = string.format("[%d studs]", math.floor(distance))
                    esp.Distance.Visible = true
                end
                
                if esp.Health and SavedStates.ESPHealth then
                    local healthPercent = humanoid.Health / humanoid.MaxHealth
                    local barHeight = height * healthPercent
                    
                    esp.Health.From = Vector2.new(rootPos.X - width/2 - 6, rootPos.Y + height/2)
                    esp.Health.To = Vector2.new(rootPos.X - width/2 - 6, rootPos.Y + height/2 - barHeight)
                    esp.Health.Color = Color3.new(1 - healthPercent, healthPercent, 0)
                    esp.Health.Visible = true
                end
            else
                if esp.Box then esp.Box.Visible = false end
                if esp.Tracer then esp.Tracer.Visible = false end
                if esp.Name then esp.Name.Visible = false end
                if esp.Distance then esp.Distance.Visible = false end
                if esp.Health then esp.Health.Visible = false end
            end
        else
            if esp.Box then esp.Box.Visible = false end
            if esp.Tracer then esp.Tracer.Visible = false end
            if esp.Name then esp.Name.Visible = false end
            if esp.Distance then esp.Distance.Visible = false end
            if esp.Health then esp.Health.Visible = false end
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
        Lighting.Brightness = SavedStates.Brightness
        Lighting.FogEnd = 1e5
        Lighting.GlobalShadows = true
        Lighting.OutdoorAmbient = Color3.new(0.5, 0.5, 0.5)
        Lighting.Ambient = Color3.new(0, 0, 0)
        Notify("💡 Fullbright desativado", CONFIG.COR_ERRO)
    end
end

-- ════════════════════════════════════════════════════════════
-- CRIAÇÃO DA GUI (REDESENHADA E MODERNA)
-- ════════════════════════════════════════════════════════════
local function CreateGUI()
    if GUI then
        GUI:Destroy()
    end
    
    UIElements = {}
    
    GUI = Instance.new("ScreenGui")
    GUI.Name = "SHAKA_HUB"
    GUI.ResetOnSpawn = false
    GUI.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    GUI.Parent = LocalPlayer:WaitForChild("PlayerGui")
    
    local scale = SavedStates.MenuScale or 0.85
    local baseWidth, baseHeight = 650, 450
    
    local main = Instance.new("Frame")
    main.Name = "Main"
    main.Size = UDim2.new(0, baseWidth * scale, 0, baseHeight * scale)
    main.Position = UDim2.new(0.5, -(baseWidth * scale)/2, 0.5, -(baseHeight * scale)/2)
    main.BackgroundColor3 = CONFIG.COR_FUNDO
    main.BorderSizePixel = 0
    main.Parent = GUI
    
    Instance.new("UICorner", main).CornerRadius = UDim.new(0, 16)
    
    local mainStroke = Instance.new("UIStroke", main)
    mainStroke.Color = GetCurrentColor()
    mainStroke.Thickness = 2.5
    mainStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    table.insert(UIElements, mainStroke)
    
    -- Header moderno
    local header = Instance.new("Frame")
    header.Name = "Header"
    header.Size = UDim2.new(1, 0, 0, 55)
    header.BackgroundColor3 = CONFIG.COR_FUNDO_2
    header.BorderSizePixel = 0
    header.Parent = main
    
    Instance.new("UICorner", header).CornerRadius = UDim.new(0, 16)
    
    local headerAccent = Instance.new("Frame")
    headerAccent.Size = UDim2.new(1, 0, 0, 3)
    headerAccent.Position = UDim2.new(0, 0, 1, -3)
    headerAccent.BackgroundColor3 = GetCurrentColor()
    headerAccent.BorderSizePixel = 0
    headerAccent.Parent = header
    headerAccent:SetAttribute("ColorUpdate", true)
    table.insert(UIElements, headerAccent)
    
    local logo = Instance.new("TextLabel")
    logo.Size = UDim2.new(0, 160, 1, 0)
    logo.Position = UDim2.new(0, 20, 0, 0)
    logo.BackgroundTransparency = 1
    logo.Text = "SHAKA HUB"
    logo.TextColor3 = GetCurrentColor()
    logo.TextSize = 20
    logo.Font = Enum.Font.GothamBold
    logo.TextXAlignment = Enum.TextXAlignment.Left
    logo.Parent = header
    logo:SetAttribute("TextColorUpdate", true)
    table.insert(UIElements, logo)
    
    local version = Instance.new("TextLabel")
    version.Size = UDim2.new(0, 60, 0, 24)
    version.Position = UDim2.new(0, 185, 0, 15.5)
    version.BackgroundColor3 = GetCurrentColor()
    version.Text = CONFIG.VERSAO
    version.TextColor3 = CONFIG.COR_TEXTO
    version.TextSize = 12
    version.Font = Enum.Font.GothamBold
    version.BorderSizePixel = 0
    version.Parent = header
    version:SetAttribute("ColorUpdate", true)
    table.insert(UIElements, version)
    
    Instance.new("UICorner", version).CornerRadius = UDim.new(0, 6)
    
    local closeBtn = Instance.new("TextButton")
    closeBtn.Size = UDim2.new(0, 35, 0, 35)
    closeBtn.Position = UDim2.new(1, -45, 0, 10)
    closeBtn.BackgroundColor3 = CONFIG.COR_ERRO
    closeBtn.Text = "×"
    closeBtn.TextColor3 = CONFIG.COR_TEXTO
    closeBtn.TextSize = 24
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.BorderSizePixel = 0
    closeBtn.Parent = header
    
    Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 8)
    
    closeBtn.MouseButton1Click:Connect(function()
        Tween(main, {Size = UDim2.new(0, 0, 0, 0)}, 0.25)
        task.wait(0.25)
        GUI:Destroy()
        GUI = nil
    end)
    
    closeBtn.MouseEnter:Connect(function()
        Tween(closeBtn, {BackgroundColor3 = Color3.fromRGB(255, 80, 100)}, 0.2)
    end)
    
    closeBtn.MouseLeave:Connect(function()
        Tween(closeBtn, {BackgroundColor3 = CONFIG.COR_ERRO}, 0.2)
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
    
    -- Player List (Redesenhado)
    local playerListContainer = Instance.new("Frame")
    playerListContainer.Size = UDim2.new(0, 200, 1, -65)
    playerListContainer.Position = UDim2.new(0, 10, 0, 60)
    playerListContainer.BackgroundColor3 = CONFIG.COR_FUNDO_2
    playerListContainer.BorderSizePixel = 0
    playerListContainer.Visible = false
    playerListContainer.Parent = main
    
    Instance.new("UICorner", playerListContainer).CornerRadius = UDim.new(0, 12)
    
    local playerStroke = Instance.new("UIStroke", playerListContainer)
    playerStroke.Color = CONFIG.COR_FUNDO_3
    playerStroke.Thickness = 1
    
    local playerListTitle = Instance.new("TextLabel")
    playerListTitle.Size = UDim2.new(1, 0, 0, 35)
    playerListTitle.BackgroundColor3 = GetCurrentColor()
    playerListTitle.Text = "👥 JOGADORES"
    playerListTitle.TextColor3 = CONFIG.COR_TEXTO
    playerListTitle.TextSize = 13
    playerListTitle.Font = Enum.Font.GothamBold
    playerListTitle.BorderSizePixel = 0
    playerListTitle.Parent = playerListContainer
    playerListTitle:SetAttribute("ColorUpdate", true)
    table.insert(UIElements, playerListTitle)
    
    Instance.new("UICorner", playerListTitle).CornerRadius = UDim.new(0, 12)
    
    local selectedLabel = Instance.new("TextLabel")
    selectedLabel.Size = UDim2.new(1, -10, 0, 30)
    selectedLabel.Position = UDim2.new(0, 5, 0, 40)
    selectedLabel.BackgroundColor3 = CONFIG.COR_FUNDO
    selectedLabel.Text = "Nenhum"
    selectedLabel.TextColor3 = CONFIG.COR_TEXTO_SEC
    selectedLabel.TextSize = 11
    selectedLabel.Font = Enum.Font.Gotham
    selectedLabel.BorderSizePixel = 0
    selectedLabel.Parent = playerListContainer
    
    Instance.new("UICorner", selectedLabel).CornerRadius = UDim.new(0, 8)
    
    local playerScroll = Instance.new("ScrollingFrame")
    playerScroll.Size = UDim2.new(1, -10, 1, -80)
    playerScroll.Position = UDim2.new(0, 5, 0, 75)
    playerScroll.BackgroundTransparency = 1
    playerScroll.BorderSizePixel = 0
    playerScroll.ScrollBarThickness = 4
    playerScroll.ScrollBarImageColor3 = GetCurrentColor()
    playerScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    playerScroll.Parent = playerListContainer
    
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
                playerBtn.Size = UDim2.new(1, -5, 0, 36)
                playerBtn.BackgroundColor3 = CONFIG.COR_FUNDO
                playerBtn.Text = " " .. player.Name
                playerBtn.TextColor3 = CONFIG.COR_TEXTO
                playerBtn.TextSize = 12
                playerBtn.Font = Enum.Font.Gotham
                playerBtn.TextXAlignment = Enum.TextXAlignment.Left
                playerBtn.BorderSizePixel = 0
                playerBtn.Parent = playerScroll
                
                Instance.new("UICorner", playerBtn).CornerRadius = UDim.new(0, 8)
                
                if SelectedPlayer == player then
                    playerBtn.BackgroundColor3 = GetCurrentColor()
                    playerBtn.TextColor3 = CONFIG.COR_TEXTO
                end
                
                playerBtn.MouseButton1Click:Connect(function()
                    SelectedPlayer = player
                    selectedLabel.Text = player.Name
                    selectedLabel.TextColor3 = GetCurrentColor()
                    
                    for _, btn in pairs(playerScroll:GetChildren()) do
                        if btn:IsA("TextButton") then
                            Tween(btn, {BackgroundColor3 = CONFIG.COR_FUNDO}, 0.1)
                            btn.TextColor3 = CONFIG.COR_TEXTO
                        end
                    end
                    
                    Tween(playerBtn, {BackgroundColor3 = GetCurrentColor()}, 0.1)
                end)
                
                playerBtn.MouseEnter:Connect(function()
                    if SelectedPlayer ~= player then
                        Tween(playerBtn, {BackgroundColor3 = CONFIG.COR_FUNDO_3}, 0.1)
                    end
                end)
                
                playerBtn.MouseLeave:Connect(function()
                    if SelectedPlayer ~= player then
                        Tween(playerBtn, {BackgroundColor3 = CONFIG.COR_FUNDO}, 0.1)
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
    
    -- Tab System (Novo Design)
    local tabContainer = Instance.new("Frame")
    tabContainer.Size = UDim2.new(0, baseWidth * scale - 20, 1, -65)
    tabContainer.Position = UDim2.new(0, 10, 0, 60)
    tabContainer.BackgroundTransparency = 1
    tabContainer.BorderSizePixel = 0
    tabContainer.Parent = main
    
    local tabBar = Instance.new("ScrollingFrame")
    tabBar.Size = UDim2.new(1, 0, 0, 42)
    tabBar.BackgroundTransparency = 1
    tabBar.BorderSizePixel = 0
    tabBar.ScrollBarThickness = 0
    tabBar.CanvasSize = UDim2.new(0, 0, 0, 0)
    tabBar.Parent = tabContainer
    
    local tabBarLayout = Instance.new("UIListLayout")
    tabBarLayout.FillDirection = Enum.FillDirection.Horizontal
    tabBarLayout.Padding = UDim.new(0, 5)
    tabBarLayout.SortOrder = Enum.SortOrder.LayoutOrder
    tabBarLayout.Parent = tabBar
    
    tabBarLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        tabBar.CanvasSize = UDim2.new(0, tabBarLayout.AbsoluteContentSize.X + 5, 0, 0)
    end)
    
    local tabContent = Instance.new("Frame")
    tabContent.Size = UDim2.new(1, 0, 1, -47)
    tabContent.Position = UDim2.new(0, 0, 0, 47)
    tabContent.BackgroundTransparency = 1
    tabContent.BorderSizePixel = 0
    tabContent.Parent = tabContainer
    
    local tabs = {
        {Name = "Player", Icon = "👤", ShowPlayerList = false},
        {Name = "Combat", Icon = "⚔️", ShowPlayerList = true},
        {Name = "Troll", Icon = "😈", ShowPlayerList = true},
        {Name = "Teleport", Icon = "📍", ShowPlayerList = true},
        {Name = "ESP", Icon = "👁️", ShowPlayerList = false},
        {Name = "Visual", Icon = "✨", ShowPlayerList = false},
        {Name = "Config", Icon = "⚙️", ShowPlayerList = false}
    }
    
    local currentTab = "Player"
    local tabFrames = {}
    
    -- Funções de criação de elementos
    local function CreateToggle(name, desc, savedKey, callback, parent)
        local toggle = Instance.new("Frame")
        toggle.Size = UDim2.new(1, -10, 0, 62)
        toggle.BackgroundColor3 = CONFIG.COR_FUNDO_2
        toggle.BorderSizePixel = 0
        toggle.Parent = parent
        
        Instance.new("UICorner", toggle).CornerRadius = UDim.new(0, 10)
        
        local stroke = Instance.new("UIStroke", toggle)
        stroke.Color = CONFIG.COR_FUNDO_3
        stroke.Thickness = 1
        
        local nameLabel = Instance.new("TextLabel")
        nameLabel.Size = UDim2.new(0.6, 0, 0, 24)
        nameLabel.Position = UDim2.new(0, 12, 0, 8)
        nameLabel.BackgroundTransparency = 1
        nameLabel.Text = name
        nameLabel.TextColor3 = CONFIG.COR_TEXTO
        nameLabel.TextSize = 14
        nameLabel.Font = Enum.Font.GothamBold
        nameLabel.TextXAlignment = Enum.TextXAlignment.Left
        nameLabel.Parent = toggle
        
        local descLabel = Instance.new("TextLabel")
        descLabel.Size = UDim2.new(0.6, 0, 0, 20)
        descLabel.Position = UDim2.new(0, 12, 0, 34)
        descLabel.BackgroundTransparency = 1
        descLabel.Text = desc
        descLabel.TextColor3 = CONFIG.COR_TEXTO_SEC
        descLabel.TextSize = 11
        descLabel.Font = Enum.Font.Gotham
        descLabel.TextXAlignment = Enum.TextXAlignment.Left
        descLabel.Parent = toggle
        
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(0, 50, 0, 26)
        btn.Position = UDim2.new(1, -60, 0.5, -13)
        btn.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
        btn.Text = ""
        btn.BorderSizePixel = 0
        btn.Parent = toggle
        
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 13)
        
        local knob = Instance.new("Frame")
        knob.Size = UDim2.new(0, 20, 0, 20)
        knob.Position = UDim2.new(0, 3, 0, 3)
        knob.BackgroundColor3 = CONFIG.COR_TEXTO
        knob.BorderSizePixel = 0
        knob.Parent = btn
        
        Instance.new("UICorner", knob).CornerRadius = UDim.new(0, 10)
        
        local state = SavedStates[savedKey] or false
        
        if state then
            btn.BackgroundColor3 = GetCurrentColor()
            knob.Position = UDim2.new(0, 27, 0, 3)
            btn:SetAttribute("ColorUpdate", true)
            table.insert(UIElements, btn)
        end
        
        btn.MouseButton1Click:Connect(function()
            state = not state
            SavedStates[savedKey] = state
            
            if state then
                Tween(btn, {BackgroundColor3 = GetCurrentColor()}, 0.15)
                Tween(knob, {Position = UDim2.new(0, 27, 0, 3)}, 0.15)
                btn:SetAttribute("ColorUpdate", true)
                table.insert(UIElements, btn)
            else
                Tween(btn, {BackgroundColor3 = Color3.fromRGB(45, 45, 55)}, 0.15)
                Tween(knob, {Position = UDim2.new(0, 3, 0, 3)}, 0.15)
                btn:SetAttribute("ColorUpdate", false)
            end
            
            callback(state)
        end)
        
        return toggle
    end
    
    local function CreateSlider(name, min, max, savedKey, callback, parent)
        local slider = Instance.new("Frame")
        slider.Size = UDim2.new(1, -10, 0, 70)
        slider.BackgroundColor3 = CONFIG.COR_FUNDO_2
        slider.BorderSizePixel = 0
        slider.Parent = parent
        
        Instance.new("UICorner", slider).CornerRadius = UDim.new(0, 10)
        
        local stroke = Instance.new("UIStroke", slider)
        stroke.Color = CONFIG.COR_FUNDO_3
        stroke.Thickness = 1
        
        local nameLabel = Instance.new("TextLabel")
        nameLabel.Size = UDim2.new(0.5, 0, 0, 24)
        nameLabel.Position = UDim2.new(0, 12, 0, 8)
        nameLabel.BackgroundTransparency = 1
        nameLabel.Text = name
        nameLabel.TextColor3 = CONFIG.COR_TEXTO
        nameLabel.TextSize = 14
        nameLabel.Font = Enum.Font.GothamBold
        nameLabel.TextXAlignment = Enum.TextXAlignment.Left
        nameLabel.Parent = slider
        
        local default = SavedStates[savedKey] or min
        
        local valueLabel = Instance.new("TextLabel")
        valueLabel.Size = UDim2.new(0.4, 0, 0, 24)
        valueLabel.Position = UDim2.new(0.6, 0, 0, 8)
        valueLabel.BackgroundTransparency = 1
        valueLabel.Text = tostring(default)
        valueLabel.TextColor3 = GetCurrentColor()
        valueLabel.TextSize = 14
        valueLabel.Font = Enum.Font.GothamBold
        valueLabel.TextXAlignment = Enum.TextXAlignment.Right
        valueLabel.Parent = slider
        valueLabel:SetAttribute("TextColorUpdate", true)
        table.insert(UIElements, valueLabel)
        
        local track = Instance.new("Frame")
        track.Size = UDim2.new(1, -24, 0, 6)
        track.Position = UDim2.new(0, 12, 0, 46)
        track.BackgroundColor3 = CONFIG.COR_FUNDO
        track.BorderSizePixel = 0
        track.Parent = slider
        
        Instance.new("UICorner", track).CornerRadius = UDim.new(0, 3)
        
        local fill = Instance.new("Frame")
        fill.Size = UDim2.new((default - min) / (max - min), 0, 1, 0)
        fill.BackgroundColor3 = GetCurrentColor()
        fill.BorderSizePixel = 0
        fill.Parent = track
        fill:SetAttribute("ColorUpdate", true)
        table.insert(UIElements, fill)
        
        Instance.new("UICorner", fill).CornerRadius = UDim.new(0, 3)
        
        local knob = Instance.new("Frame")
        knob.Size = UDim2.new(0, 14, 0, 14)
        knob.Position = UDim2.new((default - min) / (max - min), -7, 0.5, -7)
        knob.BackgroundColor3 = CONFIG.COR_TEXTO
        knob.BorderSizePixel = 0
        knob.Parent = track
        
        Instance.new("UICorner", knob).CornerRadius = UDim.new(0, 7)
        
        local dragging = false
        
        local function update(input)
            local pos = math.clamp((input.Position.X - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
            local value = math.floor(min + (max - min) * pos)
            
            fill.Size = UDim2.new(pos, 0, 1, 0)
            knob.Position = UDim2.new(pos, -7, 0.5, -7)
            valueLabel.Text = tostring(value)
            
            SavedStates[savedKey] = value
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
        btn.Size = UDim2.new(1, -10, 0, 42)
        btn.BackgroundColor3 = GetCurrentColor()
        btn.Text = text
        btn.TextColor3 = CONFIG.COR_TEXTO
        btn.TextSize = 13
        btn.Font = Enum.Font.GothamBold
        btn.BorderSizePixel = 0
        btn.Parent = parent
        btn:SetAttribute("ColorUpdate", true)
        table.insert(UIElements, btn)
        
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 10)
        
        btn.MouseEnter:Connect(function()
            Tween(btn, {BackgroundColor3 = Color3.fromRGB(
                math.min(GetCurrentColor().R * 255 * 1.2, 255)/255,
                math.min(GetCurrentColor().G * 255 * 1.2, 255)/255,
                math.min(GetCurrentColor().B * 255 * 1.2, 255)/255
            )}, 0.15)
        end)
        
        btn.MouseLeave:Connect(function()
            Tween(btn, {BackgroundColor3 = GetCurrentColor()}, 0.15)
        end)
        
        btn.MouseButton1Click:Connect(callback)
        
        return btn
    end
    
    -- Criar abas
    for i, tab in ipairs(tabs) do
        local tabBtn = Instance.new("TextButton")
        tabBtn.Size = UDim2.new(0, 90, 0, 38)
        tabBtn.BackgroundColor3 = CONFIG.COR_FUNDO_2
        tabBtn.Text = tab.Icon .. " " .. tab.Name
        tabBtn.TextColor3 = CONFIG.COR_TEXTO
        tabBtn.TextSize = 12
        tabBtn.Font = Enum.Font.GothamBold
        tabBtn.BorderSizePixel = 0
        tabBtn.Parent = tabBar
        
        Instance.new("UICorner", tabBtn).CornerRadius = UDim.new(0, 10)
        
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
            
            if tab.ShowPlayerList then
                playerListContainer.Visible = true
                tabContainer.Size = UDim2.new(0, (baseWidth * scale) - 220, 1, -65)
                tabContainer.Position = UDim2.new(0, 220, 0, 60)
            else
                playerListContainer.Visible = false
                tabContainer.Size = UDim2.new(0, (baseWidth * scale) - 20, 1, -65)
                tabContainer.Position = UDim2.new(0, 10, 0, 60)
            end
            
            for name, frame in pairs(tabFrames) do
                frame.Visible = (name == tab.Name)
            end
            
            for _, btn in pairs(tabBar:GetChildren()) do
                if btn:IsA("TextButton") then
                    Tween(btn, {BackgroundColor3 = CONFIG.COR_FUNDO_2}, 0.15)
                end
            end
            
            Tween(tabBtn, {BackgroundColor3 = GetCurrentColor()}, 0.15)
        end)
        
        if i == 1 then
            tabBtn.BackgroundColor3 = GetCurrentColor()
            tabBtn:SetAttribute("ColorUpdate", true)
            table.insert(UIElements, tabBtn)
            tabFrame.Visible = true
        end
    end
    
    -- ═══════════════ ABA PLAYER ═══════════════
    CreateToggle("✈️ Fly", "Voar com WASD/Space/Shift", "FlyEnabled", ToggleFly, tabFrames["Player"])
    CreateSlider("🚀 Velocidade Fly", 10, 300, "FlySpeed", function(value)
        SavedStates.FlySpeed = value
    end, tabFrames["Player"])
    
    CreateToggle("👻 Noclip", "Atravessar paredes", "NoclipEnabled", ToggleNoclip, tabFrames["Player"])
    CreateToggle("🦘 Pulo Infinito", "Pular infinitamente", "InfJumpEnabled", ToggleInfJump, tabFrames["Player"])
    
    CreateSlider("🏃 Velocidade", 16, 350, "WalkSpeed", function(value)
        SavedStates.WalkSpeed = value
    end, tabFrames["Player"])
    
    CreateSlider("⬆️ Força do Pulo", 50, 600, "JumpPower", function(value)
        SavedStates.JumpPower = value
    end, tabFrames["Player"])
    
    CreateToggle("🛡️ God Mode", "Vida infinita", "GodMode", ToggleGodMode, tabFrames["Player"])
    CreateToggle("👁️ Invisível", "Ficar invisível", "InvisibleEnabled", ToggleInvisible, tabFrames["Player"])
    
    CreateButton("💺 Sentar/Levantar", SitPlayer, tabFrames["Player"])
    CreateButton("🎩 Remover Acessórios", RemoveAccessories, tabFrames["Player"])
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
    
    -- ═══════════════ ABA COMBAT ═══════════════
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
    
    CreateButton("🌪️ Arremessar (Fling)", FlingPlayer, tabFrames["Combat"])
    
    -- ═══════════════ ABA TROLL ═══════════════
    CreateButton("👔 Copiar Roupa", CopyOutfit, tabFrames["Troll"])
    CreateButton("🌀 Girar Jogador", SpinPlayer, tabFrames["Troll"])
    CreateButton("😈 Benx Player", BenxPlayer, tabFrames["Troll"])
    CreateButton("🔊 Spam Sons", SpamSounds, tabFrames["Troll"])
    
    -- ═══════════════ ABA TELEPORT ═══════════════
    CreateButton("🚀 Teleportar para Jogador", TeleportToPlayer, tabFrames["Teleport"])
    
    CreateButton("🏠 Voltar ao Spawn", function()
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
                Notify("🏠 Teleportado para spawn", CONFIG.COR_SUCESSO)
            end
        end
    end, tabFrames["Teleport"])
    
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
    
    -- ═══════════════ ABA ESP ═══════════════
    local espTitle = Instance.new("TextLabel")
    espTitle.Size = UDim2.new(1, -10, 0, 35)
    espTitle.BackgroundColor3 = GetCurrentColor()
    espTitle.Text = "👁️ CONFIGURAÇÕES ESP"
    espTitle.TextColor3 = CONFIG.COR_TEXTO
    espTitle.TextSize = 14
    espTitle.Font = Enum.Font.GothamBold
    espTitle.BorderSizePixel = 0
    espTitle.Parent = tabFrames["ESP"]
    espTitle:SetAttribute("ColorUpdate", true)
    table.insert(UIElements, espTitle)
    Instance.new("UICorner", espTitle).CornerRadius = UDim.new(0, 10)
    
    CreateToggle("👁️ Ativar ESP", "Liga/desliga o ESP", "ESPEnabled", ToggleESP, tabFrames["ESP"])
    
    CreateToggle("📦 Box ESP", "Caixas ao redor dos jogadores", "ESPBox", function(state)
        SavedStates.ESPBox = state
        if SavedStates.ESPEnabled then
            ToggleESP(false)
            task.wait(0.1)
            ToggleESP(true)
        end
    end, tabFrames["ESP"])
    
    CreateToggle("📏 Tracers ESP", "Linhas conectando você aos jogadores", "ESPTracers", function(state)
        SavedStates.ESPTracers = state
        if SavedStates.ESPEnabled then
            ToggleESP(false)
            task.wait(0.1)
            ToggleESP(true)
        end
    end, tabFrames["ESP"])
    
    CreateToggle("📝 Name ESP", "Mostrar nomes", "ESPName", function(state)
        SavedStates.ESPName = state
        if SavedStates.ESPEnabled then
            ToggleESP(false)
            task.wait(0.1)
            ToggleESP(true)
        end
    end, tabFrames["ESP"])
    
    CreateToggle("📍 Distance ESP", "Mostrar distância", "ESPDistance", function(state)
        SavedStates.ESPDistance = state
        if SavedStates.ESPEnabled then
            ToggleESP(false)
            task.wait(0.1)
            ToggleESP(true)
        end
    end, tabFrames["ESP"])
    
    CreateToggle("❤️ Health ESP", "Barra de vida", "ESPHealth", function(state)
        SavedStates.ESPHealth = state
        if SavedStates.ESPEnabled then
            ToggleESP(false)
            task.wait(0.1)
            ToggleESP(true)
        end
    end, tabFrames["ESP"])
    
    -- ═══════════════ ABA VISUAL ═══════════════
    CreateToggle("💡 Fullbright", "Iluminação máxima", "Fullbright", ToggleFullbright, tabFrames["Visual"])
    
    CreateToggle("🌫️ Remover Fog", "Remover neblina", "RemoveFog", function(state)
        SavedStates.RemoveFog = state
        Lighting.FogEnd = state and 1e10 or 1e5
        Notify(state and "🌫️ Fog removido" or "🌫️ Fog restaurado", state and CONFIG.COR_SUCESSO or CONFIG.COR_ERRO)
    end, tabFrames["Visual"])
    
    CreateToggle("🌑 Remover Sombras", "Desativar sombras", "RemoveShadows", function(state)
        SavedStates.RemoveShadows = state
        Lighting.GlobalShadows = not state
        Notify(state and "🌑 Sombras removidas" or "🌑 Sombras restauradas", state and CONFIG.COR_SUCESSO or CONFIG.COR_ERRO)
    end, tabFrames["Visual"])
    
    CreateSlider("☀️ Brilho", 0, 10, "Brightness", function(value)
        SavedStates.Brightness = value
        Lighting.Brightness = value
    end, tabFrames["Visual"])
    
    CreateSlider("🔭 FOV", 70, 120, "FOV", function(value)
        SavedStates.FOV = value
        Camera.FieldOfView = value
    end, tabFrames["Visual"])
    
    CreateButton("⏰ Dia Permanente", function()
        Lighting.ClockTime = 14
        if Connections.TimeFreeze then Connections.TimeFreeze:Disconnect() end
        Connections.TimeFreeze = RunService.Heartbeat:Connect(function()
            Lighting.ClockTime = 14
        end)
        Notify("⏰ Dia permanente ativado", CONFIG.COR_SUCESSO)
    end, tabFrames["Visual"])
    
    CreateButton("🌙 Noite Permanente", function()
        Lighting.ClockTime = 0
        if Connections.TimeFreeze then Connections.TimeFreeze:Disconnect() end
        Connections.TimeFreeze = RunService.Heartbeat:Connect(function()
            Lighting.ClockTime = 0
        end)
        Notify("🌙 Noite permanente ativada", CONFIG.COR_SUCESSO)
    end, tabFrames["Visual"])
    
    -- ═══════════════ ABA CONFIG ═══════════════
    local colorTitle = Instance.new("TextLabel")
    colorTitle.Size = UDim2.new(1, -10, 0, 35)
    colorTitle.BackgroundColor3 = GetCurrentColor()
    colorTitle.Text = "🎨 CORES DO MENU"
    colorTitle.TextColor3 = CONFIG.COR_TEXTO
    colorTitle.TextSize = 14
    colorTitle.Font = Enum.Font.GothamBold
    colorTitle.BorderSizePixel = 0
    colorTitle.Parent = tabFrames["Config"]
    colorTitle:SetAttribute("ColorUpdate", true)
    table.insert(UIElements, colorTitle)
    Instance.new("UICorner", colorTitle).CornerRadius = UDim.new(0, 10)
    
    CreateToggle("🌈 Modo Rainbow", "Cores animadas", "RainbowMode", function(state)
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
            Notify("🌈 Modo Rainbow desativado", CONFIG.COR_ERRO)
        end
    end, tabFrames["Config"])
    
    local presetColors = {
        {Name = "🟣 Roxo", Color = Color3.fromRGB(139, 0, 255)},
        {Name = "🔴 Vermelho", Color = Color3.fromRGB(255, 50, 80)},
        {Name = "🔵 Azul", Color = Color3.fromRGB(50, 150, 255)},
        {Name = "🟢 Verde", Color = Color3.fromRGB(0, 255, 100)},
        {Name = "🟡 Amarelo", Color = Color3.fromRGB(255, 220, 0)},
        {Name = "💗 Rosa", Color = Color3.fromRGB(255, 100, 200)},
        {Name = "🔵 Ciano", Color = Color3.fromRGB(0, 255, 255)},
        {Name = "🟠 Laranja", Color = Color3.fromRGB(255, 140, 0)}
    }
    
    for _, preset in ipairs(presetColors) do
        CreateButton(preset.Name, function()
            if SavedStates.RainbowMode then
                Notify("⚠️ Desative o Rainbow primeiro!", CONFIG.COR_ERRO)
                return
            end
            SavedStates.CustomColor = preset.Color
            UpdateAllColors()
            Notify("🎨 Cor alterada!", CONFIG.COR_SUCESSO)
        end, tabFrames["Config"])
    end
    
    local sizeTitle = Instance.new("TextLabel")
    sizeTitle.Size = UDim2.new(1, -10, 0, 35)
    sizeTitle.BackgroundColor3 = GetCurrentColor()
    sizeTitle.Text = "📐 TAMANHO DO MENU"
    sizeTitle.TextColor3 = CONFIG.COR_TEXTO
    sizeTitle.TextSize = 14
    sizeTitle.Font = Enum.Font.GothamBold
    sizeTitle.BorderSizePixel = 0
    sizeTitle.Parent = tabFrames["Config"]
    sizeTitle:SetAttribute("ColorUpdate", true)
    table.insert(UIElements, sizeTitle)
    Instance.new("UICorner", sizeTitle).CornerRadius = UDim.new(0, 10)
    
    CreateSlider("📏 Escala", 60, 120, "MenuScale", function(value)
        SavedStates.MenuScale = value / 100
        Notify("📏 Reabra o menu (F) para aplicar", CONFIG.COR_AVISO)
    end, tabFrames["Config"])
    
    local infoTitle = Instance.new("TextLabel")
    infoTitle.Size = UDim2.new(1, -10, 0, 35)
    infoTitle.BackgroundColor3 = GetCurrentColor()
    infoTitle.Text = "ℹ️ INFORMAÇÕES"
    infoTitle.TextColor3 = CONFIG.COR_TEXTO
    infoTitle.TextSize = 14
    infoTitle.Font = Enum.Font.GothamBold
    infoTitle.BorderSizePixel = 0
    infoTitle.Parent = tabFrames["Config"]
    infoTitle:SetAttribute("ColorUpdate", true)
    table.insert(UIElements, infoTitle)
    Instance.new("UICorner", infoTitle).CornerRadius = UDim.new(0, 10)
    
    CreateButton("📊 Estatísticas do Jogo", function()
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
    
    CreateButton("⚡ Otimizar FPS", function()
        settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
        for _, obj in ipairs(workspace:GetDescendants()) do
            if obj:IsA("ParticleEmitter") or obj:IsA("Trail") or obj:IsA("Smoke") or obj:IsA("Fire") or obj:IsA("Sparkles") then
                obj.Enabled = false
            end
        end
        Notify("⚡ FPS otimizado!", CONFIG.COR_SUCESSO)
    end, tabFrames["Config"])
    
    CreateButton("🔄 Resetar Configurações", function()
        SavedStates = {
            FlyEnabled = false,
            FlySpeed = 50,
            NoclipEnabled = false,
            InfJumpEnabled = false,
            WalkSpeed = 16,
            JumpPower = 50,
            GodMode = false,
            InvisibleEnabled = false,
            ESPEnabled = false,
            ESPBox = true,
            ESPLine = true,
            ESPName = true,
            ESPDistance = true,
            ESPHealth = true,
            ESPSkeleton = false,
            ESPTracers = true,
            Fullbright = false,
            RemoveFog = false,
            RemoveShadows = false,
            FOV = 70,
            Brightness = 1,
            RainbowMode = false,
            CustomColor = nil,
            MenuScale = 0.85
        }
        Notify("🔄 Configurações resetadas!\nReabra o menu (F)", CONFIG.COR_SUCESSO)
    end, tabFrames["Config"])
    
    -- Animação de entrada
    main.Size = UDim2.new(0, 0, 0, 0)
    Tween(main, {Size = UDim2.new(0, baseWidth * scale, 0, baseHeight * scale)}, 0.4)
    
    Log("Menu carregado com sucesso!")
    Notify("🟣 SHAKA Hub " .. CONFIG.VERSAO .. " carregado!\nPressione F para fechar/abrir", GetCurrentColor())
end

-- ════════════════════════════════════════════════════════════
-- RECARREGAR ESTADOS SALVOS
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
    if SavedStates.RemoveShadows then Lighting.GlobalShadows = false end
    if SavedStates.InvisibleEnabled then ToggleInvisible(true) end
    
    Camera.FieldOfView = SavedStates.FOV
    Lighting.Brightness = SavedStates.Brightness
    
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
Log("  🟣 SHAKA Hub Premium " .. CONFIG.VERSAO)
Log("  🚀 Launch Edition")
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
                Tween(main, {Size = UDim2.new(0, 0, 0, 0)}, 0.25)
                task.wait(0.25)
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
        end)
        ESPObjects[player] = nil
    end
    
    if SelectedPlayer == player then
        SelectedPlayer = nil
    end
end)

Log("✅ Sistema carregado!")
Log("⌨️  Pressione F para abrir/fechar")
Log("🎨 Design moderno e otimizado")
Log("👔 Nova função: Copiar Roupa")
Log("😈 Nova aba: Troll")
Log("👁️ ESP configurável individualmente")
Log("📐 Tamanho do menu ajustável")
Log("════════════════════════════════════════")
