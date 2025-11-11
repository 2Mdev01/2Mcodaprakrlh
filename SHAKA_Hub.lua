-- ╔══════════════════════════════════════════════════════════╗
-- ║  SHAKA Hub ULTRA v2.0 - Menu Premium Profissional       ║
-- ║  Desenvolvido por 2M | Design Revolucionário            ║
-- ╚══════════════════════════════════════════════════════════╝

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")
local Camera = workspace.CurrentCamera

-- ══════════════════════════════════════════════════════════
-- CONFIGURAÇÕES VISUAIS ULTRA
-- ══════════════════════════════════════════════════════════
local CONFIG = {
    NOME = "SHAKA ULTRA",
    VERSAO = "v2.0",
    COR_PRINCIPAL = Color3.fromRGB(147, 51, 234),
    COR_SECUNDARIA = Color3.fromRGB(168, 85, 247),
    COR_FUNDO = Color3.fromRGB(5, 5, 10),
    COR_FUNDO_2 = Color3.fromRGB(10, 10, 20),
    COR_FUNDO_3 = Color3.fromRGB(15, 15, 25),
    COR_FUNDO_4 = Color3.fromRGB(20, 20, 30),
    COR_TEXTO = Color3.fromRGB(255, 255, 255),
    COR_TEXTO_SEC = Color3.fromRGB(156, 163, 175),
    COR_SUCESSO = Color3.fromRGB(34, 197, 94),
    COR_ERRO = Color3.fromRGB(239, 68, 68),
    COR_AVISO = Color3.fromRGB(234, 179, 8)
}

-- ══════════════════════════════════════════════════════════
-- VARIÁVEIS GLOBAIS
-- ══════════════════════════════════════════════════════════
local GUI = nil
local Connections = {}
local SelectedPlayer = nil
local RainbowHue = 0
local UIElements = {}
local IsMenuOpen = false

local SavedStates = {
    FlyEnabled = false,
    FlySpeed = 80,
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
    AttachPlayer = false,
    SitOnPlayer = false,
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
    ColorR = 147,
    ColorG = 51,
    ColorB = 234
}

local ESPObjects = {}

-- ══════════════════════════════════════════════════════════
-- FUNÇÕES DE COR E ANIMAÇÃO
-- ══════════════════════════════════════════════════════════
local function GetCurrentColor()
    if SavedStates.RainbowMode then
        return Color3.fromHSV(RainbowHue, 0.8, 0.95)
    elseif SavedStates.CustomColor then
        return SavedStates.CustomColor
    else
        return CONFIG.COR_PRINCIPAL
    end
end

local function UpdateAllColors()
    if not GUI or not GUI.Parent then return end
    local currentColor = GetCurrentColor()
    
    for _, element in pairs(UIElements) do
        pcall(function()
            if element and element.Parent then
                if element:GetAttribute("ColorUpdate") then
                    TweenService:Create(element, TweenInfo.new(0.3, Enum.EasingStyle.Quad), {
                        BackgroundColor3 = currentColor
                    }):Play()
                end
                if element:GetAttribute("StrokeUpdate") and element:IsA("UIStroke") then
                    TweenService:Create(element, TweenInfo.new(0.3, Enum.EasingStyle.Quad), {
                        Color = currentColor
                    }):Play()
                end
                if element:GetAttribute("TextColorUpdate") and (element:IsA("TextLabel") or element:IsA("TextButton")) then
                    TweenService:Create(element, TweenInfo.new(0.3, Enum.EasingStyle.Quad), {
                        TextColor3 = currentColor
                    }):Play()
                end
            end
        end)
    end
end

local function Tween(obj, props, time, style)
    if not obj or not obj.Parent then return end
    TweenService:Create(obj, TweenInfo.new(time or 0.3, style or Enum.EasingStyle.Quad, Enum.EasingDirection.Out), props):Play()
end

local function AnimateIn(obj, delay)
    if not obj then return end
    local originalPos = obj.Position
    obj.Position = UDim2.new(originalPos.X.Scale, originalPos.X.Offset - 30, originalPos.Y.Scale, originalPos.Y.Offset)
    obj.BackgroundTransparency = 1
    
    task.wait(delay or 0)
    
    Tween(obj, {
        Position = originalPos,
        BackgroundTransparency = obj:GetAttribute("OriginalTransparency") or 0
    }, 0.4, Enum.EasingStyle.Back)
end

-- ══════════════════════════════════════════════════════════
-- SISTEMA DE NOTIFICAÇÕES PREMIUM
-- ══════════════════════════════════════════════════════════
local NotificationQueue = {}
local NotificationActive = false

local function Notify(text, color, icon)
    table.insert(NotificationQueue, {text = text, color = color, icon = icon})
    
    if NotificationActive then return end
    
    task.spawn(function()
        while #NotificationQueue > 0 do
            NotificationActive = true
            local data = table.remove(NotificationQueue, 1)
            
            if not GUI then break end
            
            local notif = Instance.new("Frame")
            notif.Size = UDim2.new(0, 350, 0, 80)
            notif.Position = UDim2.new(1, 370, 0.9, -90)
            notif.BackgroundColor3 = CONFIG.COR_FUNDO_2
            notif.BackgroundTransparency = 0.05
            notif.BorderSizePixel = 0
            notif.Parent = GUI
            notif.ZIndex = 10000
            
            local corner = Instance.new("UICorner", notif)
            corner.CornerRadius = UDim.new(0, 12)
            
            local glow = Instance.new("UIStroke", notif)
            glow.Color = data.color or GetCurrentColor()
            glow.Thickness = 2
            glow.Transparency = 0
            glow.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
            
            local gradient = Instance.new("UIGradient", notif)
            gradient.Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
                ColorSequenceKeypoint.new(1, Color3.fromRGB(200, 200, 200))
            })
            gradient.Rotation = 90
            gradient.Transparency = NumberSequence.new({
                NumberSequenceKeypoint.new(0, 0.95),
                NumberSequenceKeypoint.new(1, 0.98)
            })
            
            local iconBg = Instance.new("Frame")
            iconBg.Size = UDim2.new(0, 55, 0, 55)
            iconBg.Position = UDim2.new(0, 12, 0.5, -27)
            iconBg.BackgroundColor3 = data.color or GetCurrentColor()
            iconBg.BackgroundTransparency = 0.1
            iconBg.BorderSizePixel = 0
            iconBg.Parent = notif
            
            Instance.new("UICorner", iconBg).CornerRadius = UDim.new(0, 12)
            
            local iconLabel = Instance.new("TextLabel")
            iconLabel.Size = UDim2.new(1, 0, 1, 0)
            iconLabel.BackgroundTransparency = 1
            iconLabel.Text = data.icon or "✓"
            iconLabel.TextColor3 = CONFIG.COR_TEXTO
            iconLabel.TextSize = 30
            iconLabel.Font = Enum.Font.GothamBold
            iconLabel.Parent = iconBg
            
            local textLabel = Instance.new("TextLabel")
            textLabel.Size = UDim2.new(1, -80, 1, -10)
            textLabel.Position = UDim2.new(0, 75, 0, 5)
            textLabel.BackgroundTransparency = 1
            textLabel.Text = data.text
            textLabel.TextColor3 = CONFIG.COR_TEXTO
            textLabel.TextSize = 14
            textLabel.Font = Enum.Font.Gotham
            textLabel.TextXAlignment = Enum.TextXAlignment.Left
            textLabel.TextYAlignment = Enum.TextYAlignment.Top
            textLabel.TextWrapped = true
            textLabel.Parent = notif
            
            local progressBar = Instance.new("Frame")
            progressBar.Size = UDim2.new(1, 0, 0, 3)
            progressBar.Position = UDim2.new(0, 0, 1, -3)
            progressBar.BackgroundColor3 = data.color or GetCurrentColor()
            progressBar.BorderSizePixel = 0
            progressBar.Parent = notif
            
            Tween(notif, {Position = UDim2.new(1, -370, 0.9, -90)}, 0.5, Enum.EasingStyle.Back)
            
            task.spawn(function()
                Tween(progressBar, {Size = UDim2.new(0, 0, 0, 3)}, 3, Enum.EasingStyle.Linear)
            end)
            
            task.wait(3.2)
            
            Tween(notif, {Position = UDim2.new(1, 30, 0.9, -90)}, 0.4, Enum.EasingStyle.Back)
            Tween(notif, {BackgroundTransparency = 1}, 0.4)
            Tween(glow, {Transparency = 1}, 0.4)
            
            task.wait(0.5)
            if notif and notif.Parent then notif:Destroy() end
        end
        NotificationActive = false
    end)
end

-- ══════════════════════════════════════════════════════════
-- FUNÇÕES DO PLAYER (MANTIDAS E MELHORADAS)
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
        
        Notify("Modo voo ativado! Use WASD + Space/Shift", CONFIG.COR_SUCESSO, "✈️")
    else
        if root then
            local gyro = root:FindFirstChild("FlyGyro")
            local velocity = root:FindFirstChild("FlyVelocity")
            if gyro then gyro:Destroy() end
            if velocity then velocity:Destroy() end
        end
        Notify("Modo voo desativado", CONFIG.COR_ERRO, "✈️")
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
        Notify("Noclip ativado - atravesse paredes!", CONFIG.COR_SUCESSO, "👻")
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
            local char = LocalPlayer.Character
            if char then
                local humanoid = char:FindFirstChildOfClass("Humanoid")
                if humanoid then
                    humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
                end
            end
        end)
        Notify("Pulo infinito ativado!", CONFIG.COR_SUCESSO, "🦘")
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
            local char = LocalPlayer.Character
            if char then
                local humanoid = char:FindFirstChildOfClass("Humanoid")
                if humanoid and humanoid.Health < humanoid.MaxHealth then
                    humanoid.Health = humanoid.MaxHealth
                end
            end
        end)
        Notify("God Mode ativado - você é imortal!", CONFIG.COR_SUCESSO, "🛡️")
    else
        Notify("God Mode desativado", CONFIG.COR_ERRO, "🛡️")
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
        Notify("Invisibilidade ativada!", CONFIG.COR_SUCESSO, "👻")
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
        Notify("Visível novamente", CONFIG.COR_ERRO, "👤")
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

-- ══════════════════════════════════════════════════════════
-- FUNÇÕES DE TROLL AVANÇADAS
-- ══════════════════════════════════════════════════════════
local function SitOnPlayer()
    if not SelectedPlayer or not SelectedPlayer.Parent then
        Notify("Selecione um jogador primeiro!", CONFIG.COR_ERRO, "⚠️")
        return
    end
    
    local char = LocalPlayer.Character
    local targetChar = SelectedPlayer.Character
    
    if not char or not targetChar then
        Notify("Personagens não encontrados", CONFIG.COR_ERRO, "❌")
        return
    end
    
    local root = char:FindFirstChild("HumanoidRootPart")
    local targetRoot = targetChar:FindFirstChild("HumanoidRootPart")
    local humanoid = char:FindFirstChildOfClass("Humanoid")
    
    if root and targetRoot and humanoid then
        SavedStates.SitOnPlayer = true
        humanoid.Sit = true
        
        if Connections.SitOn then
            Connections.SitOn:Disconnect()
        end
        
        Connections.SitOn = RunService.Heartbeat:Connect(function()
            if not SavedStates.SitOnPlayer then return end
            if not char or not targetChar or not char.Parent or not targetChar.Parent then
                SavedStates.SitOnPlayer = false
                return
            end
            
            local tRoot = targetChar:FindFirstChild("HumanoidRootPart")
            local myRoot = char:FindFirstChild("HumanoidRootPart")
            
            if tRoot and myRoot then
                myRoot.CFrame = tRoot.CFrame * CFrame.new(0, 0, 1.5) * CFrame.Angles(0, math.rad(180), 0)
            end
        end)
        
        Notify("Sentado em " .. SelectedPlayer.Name .. "! 😂", CONFIG.COR_SUCESSO, "💺")
    end
end

local function StopSitOnPlayer()
    SavedStates.SitOnPlayer = false
    if Connections.SitOn then
        Connections.SitOn:Disconnect()
        Connections.SitOn = nil
    end
    
    local char = LocalPlayer.Character
    if char then
        local humanoid = char:FindFirstChildOfClass("Humanoid")
        if humanoid then
            humanoid.Sit = false
        end
    end
    
    Notify("Parou de sentar no jogador", CONFIG.COR_ERRO, "💺")
end

local function AttachToPlayer()
    if not SelectedPlayer or not SelectedPlayer.Parent then
        Notify("Selecione um jogador primeiro!", CONFIG.COR_ERRO, "⚠️")
        return
    end
    
    local char = LocalPlayer.Character
    local targetChar = SelectedPlayer.Character
    
    if not char or not targetChar then
        Notify("Personagens não encontrados", CONFIG.COR_ERRO, "❌")
        return
    end
    
    local root = char:FindFirstChild("HumanoidRootPart")
    local targetRoot = targetChar:FindFirstChild("HumanoidRootPart")
    
    if root and targetRoot then
        SavedStates.AttachPlayer = true
        
        if Connections.Attach then
            Connections.Attach:Disconnect()
        end
        
        local offset = CFrame.new(0, 0, -3)
        
        Connections.Attach = RunService.Heartbeat:Connect(function()
            if not SavedStates.AttachPlayer then return end
            if not char or not targetChar or not char.Parent or not targetChar.Parent then
                SavedStates.AttachPlayer = false
                return
            end
            
            local tRoot = targetChar:FindFirstChild("HumanoidRootPart")
            local myRoot = char:FindFirstChild("HumanoidRootPart")
            
            if tRoot and myRoot then
                myRoot.CFrame = tRoot.CFrame * offset
            end
        end)
        
        Notify("Grudado em " .. SelectedPlayer.Name .. "!", CONFIG.COR_SUCESSO, "📎")
    end
end

local function StopAttachToPlayer()
    SavedStates.AttachPlayer = false
    if Connections.Attach then
        Connections.Attach:Disconnect()
        Connections.Attach = nil
    end
    Notify("Desconectado do jogador", CONFIG.COR_ERRO, "📎")
end

local function FlingPlayer()
    if not SelectedPlayer or not SelectedPlayer.Parent then
        Notify("Selecione um jogador válido!", CONFIG.COR_ERRO, "⚠️")
        return
    end
    
    local char = LocalPlayer.Character
    local targetChar = SelectedPlayer.Character
    
    if not char or not targetChar then
        Notify("Personagens não encontrados", CONFIG.COR_ERRO, "❌")
        return
    end
    
    local root = char:FindFirstChild("HumanoidRootPart")
    local targetRoot = targetChar:FindFirstChild("HumanoidRootPart")
    
    if not root or not targetRoot then
        Notify("Erro ao arremessar", CONFIG.COR_ERRO, "❌")
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
    
    Notify(SelectedPlayer.Name .. " foi arremessado! 🌪️", CONFIG.COR_SUCESSO, "🌪️")
end

local function SpinPlayer()
    if not SelectedPlayer or not SelectedPlayer.Parent then
        Notify("Selecione um jogador!", CONFIG.COR_ERRO, "⚠️")
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
            
            Notify(SelectedPlayer.Name .. " está girando! 🌀", CONFIG.COR_SUCESSO, "🌀")
        end
    end
end

local function TeleportToPlayer()
    if not SelectedPlayer or not SelectedPlayer.Parent then
        Notify("Selecione um jogador válido!", CONFIG.COR_ERRO, "⚠️")
        return
    end
    
    local char = LocalPlayer.Character
    local targetChar = SelectedPlayer.Character
    
    if not char or not targetChar then
        Notify("Personagens não encontrados", CONFIG.COR_ERRO, "❌")
        return
    end
    
    local root = char:FindFirstChild("HumanoidRootPart")
    local targetRoot = targetChar:FindFirstChild("HumanoidRootPart")
    
    if root and targetRoot then
        root.CFrame = targetRoot.CFrame * CFrame.new(0, 0, 3)
        Notify("Teleportado para " .. SelectedPlayer.Name, CONFIG.COR_SUCESSO, "🚀")
    else
        Notify("Erro ao teleportar", CONFIG.COR_ERRO, "❌")
    end
end

local function BringPlayer()
    if not SelectedPlayer or not SelectedPlayer.Parent then
        Notify("Selecione um jogador!", CONFIG.COR_ERRO, "⚠️")
        return
    end
    
    local char = LocalPlayer.Character
    local targetChar = SelectedPlayer.Character
    
    if not char or not targetChar then
        Notify("Personagens não encontrados", CONFIG.COR_ERRO, "❌")
        return
    end
    
    local root = char:FindFirstChild("HumanoidRootPart")
    local targetRoot = targetChar:FindFirstChild("HumanoidRootPart")
    
    if root and targetRoot then
        targetRoot.CFrame = root.CFrame * CFrame.new(0, 0, -3)
        Notify(SelectedPlayer.Name .. " trazido até você!", CONFIG.COR_SUCESSO, "🎯")
    end
end

-- ══════════════════════════════════════════════════════════
-- SISTEMA ESP (MANTIDO)
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
        Notify("ESP ativado - veja todos os jogadores!", CONFIG.COR_SUCESSO, "👁️")
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
        Notify("Fullbright ativado - visão total!", CONFIG.COR_SUCESSO, "💡")
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
    
    local distance = (LocalPlayer.Character.HumanoidRootPart.Position - player.Character.HumanoidRootPart.Position).Magnitude
    return distance
end

-- ══════════════════════════════════════════════════════════
-- BOTÃO FLUTUANTE ULTRA ESTILIZADO
-- ══════════════════════════════════════════════════════════
local function CreateFloatingButton()
    if not GUI then return end
    
    local floatingBtn = Instance.new("ImageButton")
    floatingBtn.Name = "FloatingButton"
    floatingBtn.Size = UDim2.new(0, 70, 0, 70)
    floatingBtn.Position = UDim2.new(0.5, -35, 0.5, -35)
    floatingBtn.BackgroundColor3 = CONFIG.COR_FUNDO
    floatingBtn.BackgroundTransparency = 0
    floatingBtn.BorderSizePixel = 0
    floatingBtn.Image = ""
    floatingBtn.Parent = GUI
    floatingBtn.ZIndex = 9999
    
    local corner = Instance.new("UICorner", floatingBtn)
    corner.CornerRadius = UDim.new(0, 35)
    
    local glow = Instance.new("UIStroke", floatingBtn)
    glow.Color = GetCurrentColor()
    glow.Thickness = 3
    glow.Transparency = 0
    glow.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    glow:SetAttribute("StrokeUpdate", true)
    table.insert(UIElements, glow)
    
    local gradient = Instance.new("UIGradient", floatingBtn)
    gradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, GetCurrentColor()),
        ColorSequenceKeypoint.new(1, CONFIG.COR_FUNDO)
    })
    gradient.Rotation = 45
    
    local logo = Instance.new("TextLabel")
    logo.Size = UDim2.new(1, 0, 1, 0)
    logo.BackgroundTransparency = 1
    logo.Text = "S"
    logo.TextColor3 = CONFIG.COR_TEXTO
    logo.TextSize = 40
    logo.Font = Enum.Font.GothamBold
    logo.Parent = floatingBtn
    
    -- Animação de pulso
    task.spawn(function()
        while floatingBtn and floatingBtn.Parent do
            Tween(floatingBtn, {Size = UDim2.new(0, 75, 0, 75)}, 0.8, Enum.EasingStyle.Sine)
            Tween(glow, {Thickness = 5}, 0.8, Enum.EasingStyle.Sine)
            task.wait(0.8)
            Tween(floatingBtn, {Size = UDim2.new(0, 70, 0, 70)}, 0.8, Enum.EasingStyle.Sine)
            Tween(glow, {Thickness = 3}, 0.8, Enum.EasingStyle.Sine)
            task.wait(0.8)
        end
    end)
    
    -- Sistema de arrastar melhorado
    local dragging = false
    local dragInput, dragStart, startPos
    
    floatingBtn.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = floatingBtn.Position
            
            Tween(floatingBtn, {Size = UDim2.new(0, 65, 0, 65)}, 0.1)
            
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                    Tween(floatingBtn, {Size = UDim2.new(0, 70, 0, 70)}, 0.2, Enum.EasingStyle.Back)
                end
            end)
        end
    end)
    
    floatingBtn.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)
    
    UserInputService.InputChanged:Connect(function(input)
        if dragging and dragInput and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            Tween(floatingBtn, {
                Position = UDim2.new(
                    startPos.X.Scale,
                    startPos.X.Offset + delta.X,
                    startPos.Y.Scale,
                    startPos.Y.Offset + delta.Y
                )
            }, 0.1, Enum.EasingStyle.Linear)
        end
    end)
    
    floatingBtn.MouseButton1Click:Connect(function()
        local main = GUI:FindFirstChild("MainWindow")
        if main then
            IsMenuOpen = not IsMenuOpen
            if IsMenuOpen then
                main.Visible = true
                main.Position = UDim2.new(0.5, -300, 1.5, 0)
                Tween(main, {Position = UDim2.new(0.5, -300, 0.5, -250)}, 0.5, Enum.EasingStyle.Back)
                Tween(floatingBtn, {BackgroundTransparency = 1}, 0.3)
                Tween(glow, {Transparency = 1}, 0.3)
                Tween(logo, {TextTransparency = 1}, 0.3)
                task.wait(0.3)
                floatingBtn.Visible = false
            end
        end
    end)
    
    return floatingBtn
end

-- ══════════════════════════════════════════════════════════
-- CRIAÇÃO DA GUI PRINCIPAL ULTRA MODERNA
-- ══════════════════════════════════════════════════════════
local function CreateGUI()
    if GUI then
        GUI:Destroy()
    end
    
    UIElements = {}
    
    GUI = Instance.new("ScreenGui")
    GUI.Name = "SHAKA_ULTRA_V2"
    GUI.ResetOnSpawn = false
    GUI.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    GUI.Parent = LocalPlayer:WaitForChild("PlayerGui")
    
    -- JANELA PRINCIPAL
    local mainWindow = Instance.new("Frame")
    mainWindow.Name = "MainWindow"
    mainWindow.Size = UDim2.new(0, 600, 0, 500)
    mainWindow.Position = UDim2.new(0.5, -300, 1.5, 0)
    mainWindow.BackgroundColor3 = CONFIG.COR_FUNDO
    mainWindow.BackgroundTransparency = 0
    mainWindow.BorderSizePixel = 0
    mainWindow.Parent = GUI
    mainWindow.ClipsDescendants = true
    
    local mainCorner = Instance.new("UICorner", mainWindow)
    mainCorner.CornerRadius = UDim.new(0, 16)
    
    local mainGlow = Instance.new("UIStroke", mainWindow)
    mainGlow.Color = GetCurrentColor()
    mainGlow.Thickness = 2
    mainGlow.Transparency = 0
    mainGlow.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    mainGlow:SetAttribute("StrokeUpdate", true)
    table.insert(UIElements, mainGlow)
    
    -- Sistema de arrastar janela
    local dragging = false
    local dragInput, dragStart, startPos
    
    mainWindow.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = mainWindow.Position
            
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)
    
    mainWindow.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)
    
    UserInputService.InputChanged:Connect(function(input)
        if dragging and dragInput and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            Tween(mainWindow, {
                Position = UDim2.new(
                    startPos.X.Scale,
                    startPos.X.Offset + delta.X,
                    startPos.Y.Scale,
                    startPos.Y.Offset + delta.Y
                )
            }, 0.1, Enum.EasingStyle.Linear)
        end
    end)
    
    -- HEADER
    local header = Instance.new("Frame")
    header.Name = "Header"
    header.Size = UDim2.new(1, 0, 0, 60)
    header.BackgroundColor3 = CONFIG.COR_FUNDO_2
    header.BackgroundTransparency = 0
    header.BorderSizePixel = 0
    header.Parent = mainWindow
    
    local headerCorner = Instance.new("UICorner", header)
    headerCorner.CornerRadius = UDim.new(0, 16)
    
    local headerBottom = Instance.new("Frame")
    headerBottom.Size = UDim2.new(1, 0, 0, 16)
    headerBottom.Position = UDim2.new(0, 0, 1, -16)
    headerBottom.BackgroundColor3 = CONFIG.COR_FUNDO_2
    headerBottom.BorderSizePixel = 0
    headerBottom.Parent = header
    
    local logoContainer = Instance.new("Frame")
    logoContainer.Size = UDim2.new(0, 45, 0, 45)
    logoContainer.Position = UDim2.new(0, 12, 0.5, -22)
    logoContainer.BackgroundColor3 = GetCurrentColor()
    logoContainer.BorderSizePixel = 0
    logoContainer.Parent = header
    logoContainer:SetAttribute("ColorUpdate", true)
    table.insert(UIElements, logoContainer)
    
    Instance.new("UICorner", logoContainer).CornerRadius = UDim.new(0, 10)
    
    local logoText = Instance.new("TextLabel")
    logoText.Size = UDim2.new(1, 0, 1, 0)
    logoText.BackgroundTransparency = 1
    logoText.Text = "S"
    logoText.TextColor3 = CONFIG.COR_TEXTO
    logoText.TextSize = 28
    logoText.Font = Enum.Font.GothamBold
    logoText.Parent = logoContainer
    
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Size = UDim2.new(0, 200, 0, 24)
    titleLabel.Position = UDim2.new(0, 65, 0, 10)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = "SHAKA ULTRA"
    titleLabel.TextColor3 = CONFIG.COR_TEXTO
    titleLabel.TextSize = 20
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.Parent = header
    
    local versionLabel = Instance.new("TextLabel")
    versionLabel.Size = UDim2.new(0, 200, 0, 16)
    versionLabel.Position = UDim2.new(0, 65, 0, 32)
    versionLabel.BackgroundTransparency = 1
    versionLabel.Text = CONFIG.VERSAO .. " • Premium Edition"
    versionLabel.TextColor3 = CONFIG.COR_TEXTO_SEC
    versionLabel.TextSize = 11
    versionLabel.Font = Enum.Font.Gotham
    versionLabel.TextXAlignment = Enum.TextXAlignment.Left
    versionLabel.Parent = header
    
    local closeBtn = Instance.new("TextButton")
    closeBtn.Size = UDim2.new(0, 40, 0, 40)
    closeBtn.Position = UDim2.new(1, -50, 0.5, -20)
    closeBtn.BackgroundColor3 = CONFIG.COR_ERRO
    closeBtn.BackgroundTransparency = 0.8
    closeBtn.Text = "×"
    closeBtn.TextColor3 = CONFIG.COR_TEXTO
    closeBtn.TextSize = 28
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.BorderSizePixel = 0
    closeBtn.Parent = header
    
    Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 10)
    
    closeBtn.MouseEnter:Connect(function()
        Tween(closeBtn, {BackgroundTransparency = 0, Size = UDim2.new(0, 42, 0, 42)}, 0.2)
    end)
    
    closeBtn.MouseLeave:Connect(function()
        Tween(closeBtn, {BackgroundTransparency = 0.8, Size = UDim2.new(0, 40, 0, 40)}, 0.2)
    end)
    
    closeBtn.MouseButton1Click:Connect(function()
        IsMenuOpen = false
        Tween(mainWindow, {Position = UDim2.new(0.5, -300, 1.5, 0)}, 0.4, Enum.EasingStyle.Back)
        task.wait(0.4)
        mainWindow.Visible = false
        
        local floatingBtn = GUI:FindFirstChild("FloatingButton")
        if floatingBtn then
            floatingBtn.Visible = true
            floatingBtn.BackgroundTransparency = 0
            Tween(floatingBtn:FindFirstChildOfClass("UIStroke"), {Transparency = 0}, 0.3)
            Tween(floatingBtn:FindFirstChildOfClass("TextLabel"), {TextTransparency = 0}, 0.3)
        end
    end)
    
    -- CONTAINER PRINCIPAL
    local contentContainer = Instance.new("Frame")
    contentContainer.Size = UDim2.new(1, 0, 1, -60)
    contentContainer.Position = UDim2.new(0, 0, 0, 60)
    contentContainer.BackgroundTransparency = 1
    contentContainer.BorderSizePixel = 0
    contentContainer.Parent = mainWindow
    
    -- SIDEBAR DIREITA (TABS)
    local sidebar = Instance.new("Frame")
    sidebar.Size = UDim2.new(0, 140, 1, -10)
    sidebar.Position = UDim2.new(1, -145, 0, 5)
    sidebar.BackgroundColor3 = CONFIG.COR_FUNDO_2
    sidebar.BackgroundTransparency = 0.3
    sidebar.BorderSizePixel = 0
    sidebar.Parent = contentContainer
    
    Instance.new("UICorner", sidebar).CornerRadius = UDim.new(0, 12)
    
    local sidebarScroll = Instance.new("ScrollingFrame")
    sidebarScroll.Size = UDim2.new(1, -10, 1, -10)
    sidebarScroll.Position = UDim2.new(0, 5, 0, 5)
    sidebarScroll.BackgroundTransparency = 1
    sidebarScroll.BorderSizePixel = 0
    sidebarScroll.ScrollBarThickness = 4
    sidebarScroll.ScrollBarImageColor3 = GetCurrentColor()
    sidebarScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    sidebarScroll.Parent = sidebar
    
    local sidebarLayout = Instance.new("UIListLayout")
    sidebarLayout.Padding = UDim.new(0, 8)
    sidebarLayout.SortOrder = Enum.SortOrder.LayoutOrder
    sidebarLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    sidebarLayout.Parent = sidebarScroll
    
    sidebarLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        sidebarScroll.CanvasSize = UDim2.new(0, 0, 0, sidebarLayout.AbsoluteContentSize.Y + 10)
    end)
    
    -- ÁREA DE CONTEÚDO
    local tabContent = Instance.new("Frame")
    tabContent.Size = UDim2.new(1, -155, 1, -10)
    tabContent.Position = UDim2.new(0, 5, 0, 5)
    tabContent.BackgroundTransparency = 1
    tabContent.BorderSizePixel = 0
    tabContent.Parent = contentContainer
    
    local tabs = {
        {Name = "Player", Icon = "👤", Color = Color3.fromRGB(59, 130, 246)},
        {Name = "Combat", Icon = "⚔️", Color = Color3.fromRGB(239, 68, 68)},
        {Name = "Troll", Icon = "😈", Color = Color3.fromRGB(234, 179, 8)},
        {Name = "ESP", Icon = "👁️", Color = Color3.fromRGB(34, 197, 94)},
        {Name = "Visual", Icon = "✨", Color = Color3.fromRGB(168, 85, 247)},
        {Name = "Config", Icon = "⚙️", Color = Color3.fromRGB(107, 114, 128)}
    }
    
    local currentTab = "Player"
    local tabFrames = {}
    local tabButtons = {}
    
    -- FUNÇÕES PARA CRIAR ELEMENTOS
    local function CreateModernToggle(name, callback, parent, icon)
        local toggle = Instance.new("Frame")
        toggle.Size = UDim2.new(1, -10, 0, 50)
        toggle.BackgroundColor3 = CONFIG.COR_FUNDO_2
        toggle.BackgroundTransparency = 0.4
        toggle.BorderSizePixel = 0
        toggle.Parent = parent
        toggle:SetAttribute("OriginalTransparency", 0.4)
        
        Instance.new("UICorner", toggle).CornerRadius = UDim.new(0, 12)
        
        local glow = Instance.new("UIStroke", toggle)
        glow.Color = CONFIG.COR_FUNDO_3
        glow.Thickness = 1
        glow.Transparency = 0.6
        glow.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
        
        local iconLabel = Instance.new("TextLabel")
        iconLabel.Size = UDim2.new(0, 30, 0, 30)
        iconLabel.Position = UDim2.new(0, 12, 0.5, -15)
        iconLabel.BackgroundTransparency = 1
        iconLabel.Text = icon or "⚡"
        iconLabel.TextColor3 = CONFIG.COR_TEXTO_SEC
        iconLabel.TextSize = 20
        iconLabel.Font = Enum.Font.GothamBold
        iconLabel.Parent = toggle
        
        local nameLabel = Instance.new("TextLabel")
        nameLabel.Size = UDim2.new(0, 200, 1, 0)
        nameLabel.Position = UDim2.new(0, 48, 0, 0)
        nameLabel.BackgroundTransparency = 1
        nameLabel.Text = name
        nameLabel.TextColor3 = CONFIG.COR_TEXTO
        nameLabel.TextSize = 14
        nameLabel.Font = Enum.Font.GothamMedium
        nameLabel.TextXAlignment = Enum.TextXAlignment.Left
        nameLabel.Parent = toggle
        
        local switchBg = Instance.new("Frame")
        switchBg.Size = UDim2.new(0, 50, 0, 26)
        switchBg.Position = UDim2.new(1, -60, 0.5, -13)
        switchBg.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
        switchBg.BorderSizePixel = 0
        switchBg.Parent = toggle
        
        Instance.new("UICorner", switchBg).CornerRadius = UDim.new(0, 13)
        
        local switchKnob = Instance.new("Frame")
        switchKnob.Size = UDim2.new(0, 20, 0, 20)
        switchKnob.Position = UDim2.new(0, 3, 0, 3)
        switchKnob.BackgroundColor3 = CONFIG.COR_TEXTO
        switchKnob.BorderSizePixel = 0
        switchKnob.Parent = switchBg
        
        Instance.new("UICorner", switchKnob).CornerRadius = UDim.new(0, 10)
        
        local state = false
        
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(1, 0, 1, 0)
        btn.BackgroundTransparency = 1
        btn.Text = ""
        btn.Parent = toggle
        
        btn.MouseEnter:Connect(function()
            Tween(toggle, {BackgroundTransparency = 0.2}, 0.2)
            Tween(glow, {Thickness = 2, Transparency = 0.3}, 0.2)
        end)
        
        btn.MouseLeave:Connect(function()
            Tween(toggle, {BackgroundTransparency = 0.4}, 0.2)
            Tween(glow, {Thickness = 1, Transparency = 0.6}, 0.2)
        end)
        
        btn.MouseButton1Click:Connect(function()
            state = not state
            
            if state then
                Tween(switchBg, {BackgroundColor3 = GetCurrentColor()}, 0.3)
                Tween(switchKnob, {Position = UDim2.new(0, 27, 0, 3)}, 0.3, Enum.EasingStyle.Back)
                Tween(glow, {Color = GetCurrentColor(), Transparency = 0.2}, 0.3)
                Tween(iconLabel, {TextColor3 = GetCurrentColor()}, 0.3)
                switchBg:SetAttribute("ColorUpdate", true)
                table.insert(UIElements, switchBg)
            else
                Tween(switchBg, {BackgroundColor3 = Color3.fromRGB(30, 30, 40)}, 0.3)
                Tween(switchKnob, {Position = UDim2.new(0, 3, 0, 3)}, 0.3, Enum.EasingStyle.Back)
                Tween(glow, {Color = CONFIG.COR_FUNDO_3, Transparency = 0.6}, 0.3)
                Tween(iconLabel, {TextColor3 = CONFIG.COR_TEXTO_SEC}, 0.3)
                switchBg:SetAttribute("ColorUpdate", false)
            end
            
            callback(state)
        end)
        
        return toggle
    end
    
    local function CreateModernSlider(name, min, max, default, callback, parent, icon)
        local slider = Instance.new("Frame")
        slider.Size = UDim2.new(1, -10, 0, 65)
        slider.BackgroundColor3 = CONFIG.COR_FUNDO_2
        slider.BackgroundTransparency = 0.4
        slider.BorderSizePixel = 0
        slider.Parent = parent
        slider:SetAttribute("OriginalTransparency", 0.4)
        
        Instance.new("UICorner", slider).CornerRadius = UDim.new(0, 12)
        
        local glow = Instance.new("UIStroke", slider)
        glow.Color = CONFIG.COR_FUNDO_3
        glow.Thickness = 1
        glow.Transparency = 0.6
        
        local iconLabel = Instance.new("TextLabel")
        iconLabel.Size = UDim2.new(0, 30, 0, 30)
        iconLabel.Position = UDim2.new(0, 12, 0, 8)
        iconLabel.BackgroundTransparency = 1
        iconLabel.Text = icon or "📊"
        iconLabel.TextColor3 = CONFIG.COR_TEXTO_SEC
        iconLabel.TextSize = 18
        iconLabel.Font = Enum.Font.GothamBold
        iconLabel.Parent = slider
        
        local nameLabel = Instance.new("TextLabel")
        nameLabel.Size = UDim2.new(0, 180, 0, 20)
        nameLabel.Position = UDim2.new(0, 48, 0, 8)
        nameLabel.BackgroundTransparency = 1
        nameLabel.Text = name
        nameLabel.TextColor3 = CONFIG.COR_TEXTO
        nameLabel.TextSize = 13
        nameLabel.Font = Enum.Font.GothamMedium
        nameLabel.TextXAlignment = Enum.TextXAlignment.Left
        nameLabel.Parent = slider
        
        local valueLabel = Instance.new("TextLabel")
        valueLabel.Size = UDim2.new(0, 80, 0, 20)
        valueLabel.Position = UDim2.new(1, -90, 0, 8)
        valueLabel.BackgroundTransparency = 1
        valueLabel.Text = tostring(default)
        valueLabel.TextColor3 = GetCurrentColor()
        valueLabel.TextSize = 14
        valueLabel.Font = Enum.Font.GothamBold
        valueLabel.TextXAlignment = Enum.TextXAlignment.Right
        valueLabel.Parent = slider
        valueLabel:SetAttribute("TextColorUpdate", true)
        table.insert(UIElements, valueLabel)
        
        local trackBg = Instance.new("Frame")
        trackBg.Size = UDim2.new(1, -24, 0, 6)
        trackBg.Position = UDim2.new(0, 12, 0, 45)
        trackBg.BackgroundColor3 = CONFIG.COR_FUNDO
        trackBg.BorderSizePixel = 0
        trackBg.Parent = slider
        
        Instance.new("UICorner", trackBg).CornerRadius = UDim.new(0, 3)
        
        local trackFill = Instance.new("Frame")
        trackFill.Size = UDim2.new((default - min) / (max - min), 0, 1, 0)
        trackFill.BackgroundColor3 = GetCurrentColor()
        trackFill.BorderSizePixel = 0
        trackFill.Parent = trackBg
        trackFill:SetAttribute("ColorUpdate", true)
        table.insert(UIElements, trackFill)
        
        Instance.new("UICorner", trackFill).CornerRadius = UDim.new(0, 3)
        
        local knob = Instance.new("Frame")
        knob.Size = UDim2.new(0, 16, 0, 16)
        knob.Position = UDim2.new((default - min) / (max - min), -8, 0.5, -8)
        knob.BackgroundColor3 = CONFIG.COR_TEXTO
        knob.BorderSizePixel = 0
        knob.Parent = trackBg
        
        Instance.new("UICorner", knob).CornerRadius = UDim.new(0, 8)
        
        local knobGlow = Instance.new("UIStroke", knob)
        knobGlow.Color = GetCurrentColor()
        knobGlow.Thickness = 3
        knobGlow.Transparency = 0.5
        knobGlow:SetAttribute("StrokeUpdate", true)
        table.insert(UIElements, knobGlow)
        
        local dragging = false
        
        local function update(input)
            local pos = math.clamp((input.Position.X - trackBg.AbsolutePosition.X) / trackBg.AbsoluteSize.X, 0, 1)
            local value = math.floor(min + (max - min) * pos)
            
            Tween(trackFill, {Size = UDim2.new(pos, 0, 1, 0)}, 0.1, Enum.EasingStyle.Linear)
            Tween(knob, {Position = UDim2.new(pos, -8, 0.5, -8)}, 0.1, Enum.EasingStyle.Linear)
            valueLabel.Text = tostring(value)
            
            callback(value)
        end
        
        knob.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                dragging = true
                Tween(knob, {Size = UDim2.new(0, 20, 0, 20), Position = UDim2.new(knob.Position.X.Scale, -10, 0.5, -10)}, 0.2)
                Tween(knobGlow, {Thickness = 5, Transparency = 0.2}, 0.2)
            end
        end)
        
        UserInputService.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                dragging = false
                Tween(knob, {Size = UDim2.new(0, 16, 0, 16), Position = UDim2.new(knob.Position.X.Scale, -8, 0.5, -8)}, 0.2)
                Tween(knobGlow, {Thickness = 3, Transparency = 0.5}, 0.2)
            end
        end)
        
        UserInputService.InputChanged:Connect(function(input)
            if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
                update(input)
            end
        end)
        
        trackBg.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                update(input)
            end
        end)
        
        return slider
    end
    
    local function CreateModernButton(text, callback, parent, icon, color)
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(1, -10, 0, 45)
        btn.BackgroundColor3 = color or GetCurrentColor()
        btn.BackgroundTransparency = 0.2
        btn.Text = ""
        btn.BorderSizePixel = 0
        btn.Parent = parent
        btn:SetAttribute("OriginalTransparency", 0.2)
        
        if not color then
            btn:SetAttribute("ColorUpdate", true)
            table.insert(UIElements, btn)
        end
        
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 12)
        
        local glow = Instance.new("UIStroke", btn)
        glow.Color = color or GetCurrentColor()
        glow.Thickness = 0
        glow.Transparency = 1
        
        if not color then
            glow:SetAttribute("StrokeUpdate", true)
            table.insert(UIElements, glow)
        end
        
        local iconLabel = Instance.new("TextLabel")
        iconLabel.Size = UDim2.new(0, 30, 0, 30)
        iconLabel.Position = UDim2.new(0, 12, 0.5, -15)
        iconLabel.BackgroundTransparency = 1
        iconLabel.Text = icon or "⚡"
        iconLabel.TextColor3 = CONFIG.COR_TEXTO
        iconLabel.TextSize = 18
        iconLabel.Font = Enum.Font.GothamBold
        iconLabel.Parent = btn
        
        local textLabel = Instance.new("TextLabel")
        textLabel.Size = UDim2.new(1, -50, 1, 0)
        textLabel.Position = UDim2.new(0, 48, 0, 0)
        textLabel.BackgroundTransparency = 1
        textLabel.Text = text
        textLabel.TextColor3 = CONFIG.COR_TEXTO
        textLabel.TextSize = 14
        textLabel.Font = Enum.Font.GothamBold
        textLabel.TextXAlignment = Enum.TextXAlignment.Left
        textLabel.Parent = btn
        
        btn.MouseEnter:Connect(function()
            Tween(btn, {BackgroundTransparency = 0, Size = UDim2.new(1, -8, 0, 47)}, 0.2, Enum.EasingStyle.Back)
            Tween(glow, {Thickness = 3, Transparency = 0}, 0.2)
        end)
        
        btn.MouseLeave:Connect(function()
            Tween(btn, {BackgroundTransparency = 0.2, Size = UDim2.new(1, -10, 0, 45)}, 0.2)
            Tween(glow, {Thickness = 0, Transparency = 1}, 0.2)
        end)
        
        btn.MouseButton1Click:Connect(function()
            Tween(btn, {Size = UDim2.new(1, -12, 0, 43)}, 0.1)
            task.wait(0.1)
            Tween(btn, {Size = UDim2.new(1, -8, 0, 47)}, 0.2, Enum.EasingStyle.Back)
            callback()
        end)
        
        return btn
    end
    
    local function CreateSection(name, parent, icon)
        local section = Instance.new("Frame")
        section.Size = UDim2.new(1, -10, 0, 35)
        section.BackgroundColor3 = CONFIG.COR_FUNDO_3
        section.BackgroundTransparency = 0.5
        section.BorderSizePixel = 0
        section.Parent = parent
        section:SetAttribute("OriginalTransparency", 0.5)
        
        Instance.new("UICorner", section).CornerRadius = UDim.new(0, 10)
        
        local iconLabel = Instance.new("TextLabel")
        iconLabel.Size = UDim2.new(0, 25, 0, 25)
        iconLabel.Position = UDim2.new(0, 8, 0.5, -12)
        iconLabel.BackgroundTransparency = 1
        iconLabel.Text = icon or "📌"
        iconLabel.TextColor3 = GetCurrentColor()
        iconLabel.TextSize = 16
        iconLabel.Font = Enum.Font.GothamBold
        iconLabel.Parent = section
        iconLabel:SetAttribute("TextColorUpdate", true)
        table.insert(UIElements, iconLabel)
        
        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(1, -40, 1, 0)
        label.Position = UDim2.new(0, 38, 0, 0)
        label.BackgroundTransparency = 1
        label.Text = name
        label.TextColor3 = CONFIG.COR_TEXTO
        label.TextSize = 14
        label.Font = Enum.Font.GothamBold
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.Parent = section
        
        return section
    end
    
    -- LISTA DE JOGADORES (APENAS PARA ABA TROLL)
    local playerList = Instance.new("Frame")
    playerList.Size = UDim2.new(0, 180, 1, -10)
    playerList.Position = UDim2.new(0, 5, 0, 5)
    playerList.BackgroundColor3 = CONFIG.COR_FUNDO_2
    playerList.BackgroundTransparency = 0.3
    playerList.BorderSizePixel = 0
    playerList.Visible = false
    playerList.Parent = tabContent
    
    Instance.new("UICorner", playerList).CornerRadius = UDim.new(0, 12)
    
    local plGlow = Instance.new("UIStroke", playerList)
    plGlow.Color = GetCurrentColor()
    plGlow.Thickness = 1
    plGlow.Transparency = 0.5
    plGlow:SetAttribute("StrokeUpdate", true)
    table.insert(UIElements, plGlow)
    
    local plHeader = Instance.new("Frame")
    plHeader.Size = UDim2.new(1, 0, 0, 40)
    plHeader.BackgroundColor3 = GetCurrentColor()
    plHeader.BackgroundTransparency = 0.1
    plHeader.BorderSizePixel = 0
    plHeader.Parent = playerList
    plHeader:SetAttribute("ColorUpdate", true)
    table.insert(UIElements, plHeader)
    
    local plHeaderCorner = Instance.new("UICorner", plHeader)
    plHeaderCorner.CornerRadius = UDim.new(0, 12)
    
    local plHeaderBottom = Instance.new("Frame")
    plHeaderBottom.Size = UDim2.new(1, 0, 0, 12)
    plHeaderBottom.Position = UDim2.new(0, 0, 1, -12)
    plHeaderBottom.BackgroundColor3 = GetCurrentColor()
    plHeaderBottom.BackgroundTransparency = 0.1
    plHeaderBottom.BorderSizePixel = 0
    plHeaderBottom.Parent = plHeader
    plHeaderBottom:SetAttribute("ColorUpdate", true)
    table.insert(UIElements, plHeaderBottom)
    
    local plTitle = Instance.new("TextLabel")
    plTitle.Size = UDim2.new(1, 0, 1, 0)
    plTitle.BackgroundTransparency = 1
    plTitle.Text = "👥 JOGADORES"
    plTitle.TextColor3 = CONFIG.COR_TEXTO
    plTitle.TextSize = 13
    plTitle.Font = Enum.Font.GothamBold
    plTitle.Parent = plHeader
    
    local selectedLabel = Instance.new("TextLabel")
    selectedLabel.Size = UDim2.new(1, -10, 0, 32)
    selectedLabel.Position = UDim2.new(0, 5, 0, 45)
    selectedLabel.BackgroundColor3 = CONFIG.COR_FUNDO
    selectedLabel.BackgroundTransparency = 0.3
    selectedLabel.Text = "Nenhum selecionado"
    selectedLabel.TextColor3 = CONFIG.COR_TEXTO_SEC
    selectedLabel.TextSize = 11
    selectedLabel.Font = Enum.Font.Gotham
    selectedLabel.BorderSizePixel = 0
    selectedLabel.Parent = playerList
    
    Instance.new("UICorner", selectedLabel).CornerRadius = UDim.new(0, 8)
    
    local playerScroll = Instance.new("ScrollingFrame")
    playerScroll.Size = UDim2.new(1, -10, 1, -87)
    playerScroll.Position = UDim2.new(0, 5, 0, 82)
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
        
        local playerDistances = {}
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= LocalPlayer then
                local distance = GetPlayerDistance(player)
                table.insert(playerDistances, {Player = player, Distance = distance})
            end
        end
        
        table.sort(playerDistances, function(a, b)
            return a.Distance < b.Distance
        end)
        
        for i, data in ipairs(playerDistances) do
            local player = data.Player
            local distance = data.Distance
            
            local playerBtn = Instance.new("TextButton")
            playerBtn.Size = UDim2.new(1, -5, 0, 38)
            playerBtn.BackgroundColor3 = CONFIG.COR_FUNDO
            playerBtn.BackgroundTransparency = 0.5
            playerBtn.Text = ""
            playerBtn.BorderSizePixel = 0
            playerBtn.Parent = playerScroll
            playerBtn.LayoutOrder = i
            
            Instance.new("UICorner", playerBtn).CornerRadius = UDim.new(0, 8)
            
            local nameLabel = Instance.new("TextLabel")
            nameLabel.Size = UDim2.new(1, -40, 1, 0)
            nameLabel.Position = UDim2.new(0, 10, 0, 0)
            nameLabel.BackgroundTransparency = 1
            nameLabel.Text = player.Name
            nameLabel.TextColor3 = CONFIG.COR_TEXTO
            nameLabel.TextSize = 12
            nameLabel.Font = Enum.Font.GothamMedium
            nameLabel.TextXAlignment = Enum.TextXAlignment.Left
            nameLabel.TextTruncate = Enum.TextTruncate.AtEnd
            nameLabel.Parent = playerBtn
            
            local distLabel = Instance.new("TextLabel")
            distLabel.Size = UDim2.new(0, 35, 1, 0)
            distLabel.Position = UDim2.new(1, -40, 0, 0)
            distLabel.BackgroundTransparency = 1
            distLabel.Text = distance == math.huge and "?" or string.format("%dm", math.floor(distance))
            distLabel.TextColor3 = CONFIG.COR_TEXTO_SEC
            distLabel.TextSize = 10
            distLabel.Font = Enum.Font.Gotham
            distLabel.TextXAlignment = Enum.TextXAlignment.Right
            distLabel.Parent = playerBtn
            
            if SelectedPlayer == player then
                playerBtn.BackgroundColor3 = GetCurrentColor()
                playerBtn.BackgroundTransparency = 0.2
            end
            
            playerBtn.MouseButton1Click:Connect(function()
                SelectedPlayer = player
                selectedLabel.Text = "🎯 " .. player.Name
                selectedLabel.TextColor3 = GetCurrentColor()
                
                for _, btn in pairs(playerScroll:GetChildren()) do
                    if btn:IsA("TextButton") then
                        Tween(btn, {BackgroundColor3 = CONFIG.COR_FUNDO, BackgroundTransparency = 0.5}, 0.2)
                    end
                end
                
                Tween(playerBtn, {BackgroundColor3 = GetCurrentColor(), BackgroundTransparency = 0.2}, 0.2)
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
    
    task.spawn(function()
        while GUI do
            if playerList.Visible then
                UpdatePlayerList()
            end
            task.wait(2)
        end
    end)
    
    -- CRIAR TABS
    for i, tab in ipairs(tabs) do
        local tabBtn = Instance.new("TextButton")
        tabBtn.Size = UDim2.new(1, -10, 0, 60)
        tabBtn.BackgroundColor3 = CONFIG.COR_FUNDO_3
        tabBtn.BackgroundTransparency = 0.5
        tabBtn.Text = ""
        tabBtn.BorderSizePixel = 0
        tabBtn.Parent = sidebarScroll
        
        Instance.new("UICorner", tabBtn).CornerRadius = UDim.new(0, 12)
        
        local tabGlow = Instance.new("UIStroke", tabBtn)
        tabGlow.Color = CONFIG.COR_FUNDO_3
        tabGlow.Thickness = 1
        tabGlow.Transparency = 0.6
        
        local tabIcon = Instance.new("TextLabel")
        tabIcon.Size = UDim2.new(1, 0, 0, 28)
        tabIcon.Position = UDim2.new(0, 0, 0, 6)
        tabIcon.BackgroundTransparency = 1
        tabIcon.Text = tab.Icon
        tabIcon.TextColor3 = CONFIG.COR_TEXTO_SEC
        tabIcon.TextSize = 24
        tabIcon.Font = Enum.Font.GothamBold
        tabIcon.Parent = tabBtn
        
        local tabName = Instance.new("TextLabel")
        tabName.Size = UDim2.new(1, 0, 0, 18)
        tabName.Position = UDim2.new(0, 0, 0, 36)
        tabName.BackgroundTransparency = 1
        tabName.Text = tab.Name
        tabName.TextColor3 = CONFIG.COR_TEXTO_SEC
        tabName.TextSize = 11
        tabName.Font = Enum.Font.GothamMedium
        tabName.Parent = tabBtn
        
        tabButtons[tab.Name] = {Button = tabBtn, Glow = tabGlow, Icon = tabIcon, Name = tabName}
        
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
            tabFrame.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 10)
        end)
        
        tabFrames[tab.Name] = tabFrame
        
        tabBtn.MouseButton1Click:Connect(function()
            currentTab = tab.Name
            
            -- Mostrar lista de jogadores apenas na aba Troll
            if tab.Name == "Troll" then
                playerList.Visible = true
                for _, frame in pairs(tabFrames) do
                    frame.Size = UDim2.new(1, -195, 1, 0)
                    frame.Position = UDim2.new(0, 190, 0, 0)
                end
            else
                playerList.Visible = false
                for _, frame in pairs(tabFrames) do
                    frame.Size = UDim2.new(1, 0, 1, 0)
                    frame.Position = UDim2.new(0, 0, 0, 0)
                end
            end
            
            for name, frame in pairs(tabFrames) do
                frame.Visible = (name == tab.Name)
            end
            
            for name, elements in pairs(tabButtons) do
                if name == tab.Name then
                    Tween(elements.Button, {BackgroundTransparency = 0, BackgroundColor3 = tab.Color}, 0.3)
                    Tween(elements.Glow, {Color = tab.Color, Thickness = 2, Transparency = 0}, 0.3)
                    Tween(elements.Icon, {TextColor3 = CONFIG.COR_TEXTO}, 0.3)
                    Tween(elements.Name, {TextColor3 = CONFIG.COR_TEXTO}, 0.3)
                else
                    Tween(elements.Button, {BackgroundTransparency = 0.5, BackgroundColor3 = CONFIG.COR_FUNDO_3}, 0.3)
                    Tween(elements.Glow, {Color = CONFIG.COR_FUNDO_3, Thickness = 1, Transparency = 0.6}, 0.3)
                    Tween(elements.Icon, {TextColor3 = CONFIG.COR_TEXTO_SEC}, 0.3)
                    Tween(elements.Name, {TextColor3 = CONFIG.COR_TEXTO_SEC}, 0.3)
                end
            end
        end)
        
        if i == 1 then
            tabBtn.BackgroundTransparency = 0
            tabBtn.BackgroundColor3 = tab.Color
            tabGlow.Color = tab.Color
            tabGlow.Thickness = 2
            tabGlow.Transparency = 0
            tabIcon.TextColor3 = CONFIG.COR_TEXTO
            tabName.TextColor3 = CONFIG.COR_TEXTO
            tabFrame.Visible = true
        end
    end
    
    -- ═══════════ CONTEÚDO DAS ABAS ═══════════
    
    -- ABA PLAYER
    CreateSection("MOVIMENTO", tabFrames["Player"], "✈️")
    CreateModernToggle("Modo Voo", ToggleFly, tabFrames["Player"], "✈️")
    CreateModernSlider("Velocidade do Voo", 10, 300, SavedStates.FlySpeed, function(value)
        SavedStates.FlySpeed = value
    end, tabFrames["Player"], "⚡")
    
    CreateModernToggle("Noclip", ToggleNoclip, tabFrames["Player"], "👻")
    CreateModernToggle("Pulo Infinito", ToggleInfJump, tabFrames["Player"], "🦘")
    
    CreateSection("VELOCIDADE", tabFrames["Player"], "⚡")
    CreateModernSlider("Velocidade de Caminhada", 16, 400, SavedStates.WalkSpeed, function(value)
        SavedStates.WalkSpeed = value
    end, tabFrames["Player"], "🏃")
    
    CreateModernSlider("Força do Pulo", 50, 600, SavedStates.JumpPower, function(value)
        SavedStates.JumpPower = value
    end, tabFrames["Player"], "⬆️")
    
    CreateSection("PROTEÇÃO", tabFrames["Player"], "🛡️")
    CreateModernToggle("God Mode", ToggleGodMode, tabFrames["Player"], "🛡️")
    CreateModernToggle("Invisibilidade", ToggleInvisible, tabFrames["Player"], "👻")
    
    CreateSection("AÇÕES RÁPIDAS", tabFrames["Player"], "⚡")
    CreateModernButton("Sentar/Levantar", function()
        local char = LocalPlayer.Character
        if char then
            local humanoid = char:FindFirstChildOfClass("Humanoid")
            if humanoid then
                humanoid.Sit = not humanoid.Sit
                Notify(humanoid.Sit and "Sentado" or "Em pé", CONFIG.COR_SUCESSO, "💺")
            end
        end
    end, tabFrames["Player"], "💺")
    
    CreateModernButton("Remover Acessórios", function()
        local char = LocalPlayer.Character
        if char then
            local count = 0
            for _, item in pairs(char:GetChildren()) do
                if item:IsA("Accessory") then
                    item:Destroy()
                    count = count + 1
                end
            end
            Notify(count .. " acessórios removidos", CONFIG.COR_SUCESSO, "🎩")
        end
    end, tabFrames["Player"], "🎩")
    
    CreateModernButton("Resetar Personagem", function()
        local char = LocalPlayer.Character
        if char then
            local humanoid = char:FindFirstChildOfClass("Humanoid")
            if humanoid then
                humanoid.Health = 0
                Notify("Personagem resetado", CONFIG.COR_SUCESSO, "🔄")
            end
        end
    end, tabFrames["Player"], "🔄", CONFIG.COR_ERRO)
    
    -- ABA COMBAT
    CreateSection("AÇÕES DE COMBATE", tabFrames["Combat"], "⚔️")
    CreateModernButton("Eliminar Jogador", function()
        if not SelectedPlayer or not SelectedPlayer.Parent then
            Notify("Selecione um jogador primeiro!", CONFIG.COR_ERRO, "⚠️")
            return
        end
        local targetChar = SelectedPlayer.Character
        if targetChar then
            local humanoid = targetChar:FindFirstChildOfClass("Humanoid")
            if humanoid then
                humanoid.Health = 0
                Notify(SelectedPlayer.Name .. " eliminado", CONFIG.COR_SUCESSO, "💀")
            end
        end
    end, tabFrames["Combat"], "💀", CONFIG.COR_ERRO)
    
    CreateSection("OBSERVAÇÃO", tabFrames["Combat"], "👁️")
    CreateModernToggle("Espectatar Jogador", function(state)
        if Connections.Spectate then
            Connections.Spectate:Disconnect()
            Connections.Spectate = nil
        end
        
        if state then
            if not SelectedPlayer or not SelectedPlayer.Parent then
                Notify("Selecione um jogador primeiro!", CONFIG.COR_ERRO, "⚠️")
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
            
            Notify("Espectando " .. SelectedPlayer.Name, CONFIG.COR_SUCESSO, "👁️")
        else
            Camera.CameraSubject = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
            Notify("Espectação desativada", CONFIG.COR_ERRO, "👁️")
        end
    end, tabFrames["Combat"], "👁️")
    
    CreateModernToggle("Seguir Jogador", function(state)
        if Connections.Follow then
            Connections.Follow:Disconnect()
            Connections.Follow = nil
        end
        
        if state then
            if not SelectedPlayer or not SelectedPlayer.Parent then
                Notify("Selecione um jogador primeiro!", CONFIG.COR_ERRO, "⚠️")
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
            
            Notify("Seguindo " .. SelectedPlayer.Name, CONFIG.COR_SUCESSO, "🚶")
        else
            Notify("Parou de seguir", CONFIG.COR_ERRO, "🚶")
        end
    end, tabFrames["Combat"], "🚶")
    
    CreateModernToggle("Orbitar Jogador", function(state)
        if Connections.Orbit then
            Connections.Orbit:Disconnect()
            Connections.Orbit = nil
        end
        
        if state then
            if not SelectedPlayer or not SelectedPlayer.Parent then
                Notify("Selecione um jogador primeiro!", CONFIG.COR_ERRO, "⚠️")
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
            
            Notify("Orbitando " .. SelectedPlayer.Name, CONFIG.COR_SUCESSO, "🌀")
        else
            Notify("Órbita desativada", CONFIG.COR_ERRO, "🌀")
        end
    end, tabFrames["Combat"], "🌀")
    
    -- ABA TROLL
    CreateSection("TELEPORTE", tabFrames["Troll"], "🚀")
    CreateModernButton("Ir para Jogador", TeleportToPlayer, tabFrames["Troll"], "🚀")
    CreateModernButton("Trazer Jogador", BringPlayer, tabFrames["Troll"], "🎯")
    
    CreateModernButton("Teleportar para Spawn", function()
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
                Notify("Teleportado para spawn", CONFIG.COR_SUCESSO, "🏠")
            end
        end
    end, tabFrames["Troll"], "🏠")
    
    CreateSection("POSIÇÕES SALVAS", tabFrames["Troll"], "📌")
    CreateModernButton("Salvar Posição", function()
        local char = LocalPlayer.Character
        if char then
            local root = char:FindFirstChild("HumanoidRootPart")
            if root then
                SavedStates.SavedPosition = root.CFrame
                Notify("Posição salva com sucesso!", CONFIG.COR_SUCESSO, "✅")
            end
        end
    end, tabFrames["Troll"], "📌")
    
    CreateModernButton("Voltar para Posição", function()
        if not SavedStates.SavedPosition then
            Notify("Nenhuma posição salva!", CONFIG.COR_ERRO, "⚠️")
            return
        end
        local char = LocalPlayer.Character
        if char then
            local root = char:FindFirstChild("HumanoidRootPart")
            if root then
                root.CFrame = SavedStates.SavedPosition
                Notify("Teleportado para posição salva!", CONFIG.COR_SUCESSO, "📍")
            end
        end
    end, tabFrames["Troll"], "📍")
    
    CreateSection("TROLLAGEM AVANÇADA", tabFrames["Troll"], "😈")
    CreateModernButton("Sentar no Jogador", function()
        if SavedStates.SitOnPlayer then
            StopSitOnPlayer()
        else
            SitOnPlayer()
        end
    end, tabFrames["Troll"], "💺", CONFIG.COR_AVISO)
    
    CreateModernButton("Grudar no Jogador", function()
        if SavedStates.AttachPlayer then
            StopAttachToPlayer()
        else
            AttachToPlayer()
        end
    end, tabFrames["Troll"], "📎", CONFIG.COR_AVISO)
    
    CreateModernButton("Arremessar Jogador", FlingPlayer, tabFrames["Troll"], "🌪️", CONFIG.COR_AVISO)
    
    CreateModernButton("Girar Jogador", SpinPlayer, tabFrames["Troll"], "🌀", CONFIG.COR_AVISO)
    
    CreateModernButton("Copiar Roupa", function()
        if not SelectedPlayer or not SelectedPlayer.Parent then
            Notify("Selecione um jogador!", CONFIG.COR_ERRO, "⚠️")
            return
        end
        
        local char = LocalPlayer.Character
        local targetChar = SelectedPlayer.Character
        
        if not char or not targetChar then
            Notify("Personagens não encontrados", CONFIG.COR_ERRO, "❌")
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
        
        Notify("Roupa copiada de " .. SelectedPlayer.Name, CONFIG.COR_SUCESSO, "👔")
    end, tabFrames["Troll"], "👔")
    
    CreateModernButton("Freeze Jogador", function()
        if not SelectedPlayer or not SelectedPlayer.Parent then
            Notify("Selecione um jogador!", CONFIG.COR_ERRO, "⚠️")
            return
        end
        
        local targetChar = SelectedPlayer.Character
        if targetChar then
            local root = targetChar:FindFirstChild("HumanoidRootPart")
            if root then
                root.Anchored = true
                Notify(SelectedPlayer.Name .. " congelado!", CONFIG.COR_SUCESSO, "❄️")
                
                task.delay(5, function()
                    if root and root.Parent then
                        root.Anchored = false
                    end
                end)
            end
        end
    end, tabFrames["Troll"], "❄️", CONFIG.COR_AVISO)
    
    -- ABA ESP
    CreateSection("ESP PRINCIPAL", tabFrames["ESP"], "👁️")
    CreateModernToggle("Ativar ESP", ToggleESP, tabFrames["ESP"], "👁️")
    
    CreateSection("OPÇÕES DE ESP", tabFrames["ESP"], "⚙️")
    CreateModernToggle("Mostrar Caixas", function(state)
        SavedStates.ESPBox = state
        if SavedStates.ESPEnabled then
            ToggleESP(false)
            task.wait(0.1)
            ToggleESP(true)
        end
    end, tabFrames["ESP"], "📦")
    
    CreateModernToggle("Mostrar Linhas", function(state)
        SavedStates.ESPTracers = state
        if SavedStates.ESPEnabled then
            ToggleESP(false)
            task.wait(0.1)
            ToggleESP(true)
        end
    end, tabFrames["ESP"], "📏")
    
    CreateModernToggle("Mostrar Nomes", function(state)
        SavedStates.ESPName = state
        if SavedStates.ESPEnabled then
            ToggleESP(false)
            task.wait(0.1)
            ToggleESP(true)
        end
    end, tabFrames["ESP"], "📝")
    
    CreateModernToggle("Mostrar Distância", function(state)
        SavedStates.ESPDistance = state
        if SavedStates.ESPEnabled then
            ToggleESP(false)
            task.wait(0.1)
            ToggleESP(true)
        end
    end, tabFrames["ESP"], "📍")
    
    CreateModernToggle("Mostrar Vida", function(state)
        SavedStates.ESPHealth = state
        if SavedStates.ESPEnabled then
            ToggleESP(false)
            task.wait(0.1)
            ToggleESP(true)
        end
    end, tabFrames["ESP"], "❤️")
    
    CreateModernToggle("Usar Cor do Time", function(state)
        SavedStates.ESPTeamColor = state
        if SavedStates.ESPEnabled then
            ToggleESP(false)
            task.wait(0.1)
            ToggleESP(true)
        end
    end, tabFrames["ESP"], "🎨")
    
    -- ABA VISUAL
    CreateSection("ILUMINAÇÃO", tabFrames["Visual"], "💡")
    CreateModernToggle("Fullbright", ToggleFullbright, tabFrames["Visual"], "💡")
    
    CreateModernToggle("Remover Fog", function(state)
        SavedStates.RemoveFog = state
        Lighting.FogEnd = state and 1e10 or 1e5
        Notify(state and "Fog removido" or "Fog restaurado", state and CONFIG.COR_SUCESSO or CONFIG.COR_ERRO, "🌫️")
    end, tabFrames["Visual"], "🌫️")
    
    CreateSection("CÂMERA", tabFrames["Visual"], "🎥")
    CreateModernSlider("Campo de Visão (FOV)", 70, 120, SavedStates.FOV, function(value)
        SavedStates.FOV = value
        Camera.FieldOfView = value
    end, tabFrames["Visual"], "🔭")
    
    CreateSection("TEMPO", tabFrames["Visual"], "⏰")
    CreateModernButton("Dia Permanente", function()
        Lighting.ClockTime = 14
        if Connections.TimeFreeze then Connections.TimeFreeze:Disconnect() end
        Connections.TimeFreeze = RunService.Heartbeat:Connect(function()
            Lighting.ClockTime = 14
        end)
        Notify("Dia permanente ativado!", CONFIG.COR_SUCESSO, "☀️")
    end, tabFrames["Visual"], "☀️")
    
    CreateModernButton("Noite Permanente", function()
        Lighting.ClockTime = 0
        if Connections.TimeFreeze then Connections.TimeFreeze:Disconnect() end
        Connections.TimeFreeze = RunService.Heartbeat:Connect(function()
            Lighting.ClockTime = 0
        end)
        Notify("Noite permanente ativada!", CONFIG.COR_SUCESSO, "🌙")
    end, tabFrames["Visual"], "🌙")
    
    CreateModernButton("Liberar Tempo", function()
        if Connections.TimeFreeze then
            Connections.TimeFreeze:Disconnect()
            Connections.TimeFreeze = nil
            Notify("Tempo liberado!", CONFIG.COR_SUCESSO, "⏰")
        end
    end, tabFrames["Visual"], "🔓")
    
    -- ABA CONFIG
    CreateSection("COR DO MENU", tabFrames["Config"], "🎨")
    CreateModernToggle("Modo Rainbow", function(state)
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
            Notify("Modo Rainbow ativado!", CONFIG.COR_SUCESSO, "🌈")
        else
            SavedStates.CustomColor = Color3.fromRGB(SavedStates.ColorR, SavedStates.ColorG, SavedStates.ColorB)
            UpdateAllColors()
            Notify("Rainbow desativado", CONFIG.COR_ERRO, "🎨")
        end
    end, tabFrames["Config"], "🌈")
    
    CreateSection("COR PERSONALIZADA (RGB)", tabFrames["Config"], "🎨")
    CreateModernSlider("Vermelho (R)", 0, 255, SavedStates.ColorR, function(value)
        SavedStates.ColorR = value
        if not SavedStates.RainbowMode then
            SavedStates.CustomColor = Color3.fromRGB(SavedStates.ColorR, SavedStates.ColorG, SavedStates.ColorB)
            UpdateAllColors()
        end
    end, tabFrames["Config"], "🔴")
    
    CreateModernSlider("Verde (G)", 0, 255, SavedStates.ColorG, function(value)
        SavedStates.ColorG = value
        if not SavedStates.RainbowMode then
            SavedStates.CustomColor = Color3.fromRGB(SavedStates.ColorR, SavedStates.ColorG, SavedStates.ColorB)
            UpdateAllColors()
        end
    end, tabFrames["Config"], "🟢")
    
    CreateModernSlider("Azul (B)", 0, 255, SavedStates.ColorB, function(value)
        SavedStates.ColorB = value
        if not SavedStates.RainbowMode then
            SavedStates.CustomColor = Color3.fromRGB(SavedStates.ColorR, SavedStates.ColorG, SavedStates.ColorB)
            UpdateAllColors()
        end
    end, tabFrames["Config"], "🔵")
    
    CreateSection("INFORMAÇÕES", tabFrames["Config"], "ℹ️")
    CreateModernButton("Estatísticas do Jogo", function()
        local info = string.format([[🟣 SHAKA ULTRA %s
━━━━━━━━━━━━━━━━
📊 FPS: %d
👥 Jogadores: %d
⚡ Ping: %d ms
💾 Memória: %d MB]],
            CONFIG.VERSAO,
            math.floor(workspace:GetRealPhysicsFPS()),
            #Players:GetPlayers(),
            math.floor(LocalPlayer:GetNetworkPing() * 1000),
            math.floor(game:GetService("Stats"):GetTotalMemoryUsageMb())
        )
        Notify(info, GetCurrentColor(), "📊")
    end, tabFrames["Config"], "📊")
    
    CreateModernButton("Resetar Configurações", function()
        SavedStates = {
            FlyEnabled = false,
            FlySpeed = 80,
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
            AttachPlayer = false,
            SitOnPlayer = false,
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
            ColorR = 147,
            ColorG = 51,
            ColorB = 234
        }
        Notify("Configurações resetadas! Reabra (F)", CONFIG.COR_SUCESSO, "🔄")
    end, tabFrames["Config"], "🔄", CONFIG.COR_ERRO)
    
    CreateSection("CRÉDITOS", tabFrames["Config"], "👑")
    local creditsFrame = Instance.new("Frame")
    creditsFrame.Size = UDim2.new(1, -10, 0, 100)
    creditsFrame.BackgroundColor3 = CONFIG.COR_FUNDO_2
    creditsFrame.BackgroundTransparency = 0.3
    creditsFrame.BorderSizePixel = 0
    creditsFrame.Parent = tabFrames["Config"]
    creditsFrame:SetAttribute("OriginalTransparency", 0.3)
    
    Instance.new("UICorner", creditsFrame).CornerRadius = UDim.new(0, 12)
    
    local creditGradient = Instance.new("UIGradient", creditsFrame)
    creditGradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, GetCurrentColor()),
        ColorSequenceKeypoint.new(1, CONFIG.COR_FUNDO_2)
    })
    creditGradient.Rotation = 45
    creditGradient.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.7),
        NumberSequenceKeypoint.new(1, 0.3)
    })
    
    local creditIcon = Instance.new("TextLabel")
    creditIcon.Size = UDim2.new(0, 50, 0, 50)
    creditIcon.Position = UDim2.new(0.5, -25, 0, 10)
    creditIcon.BackgroundTransparency = 1
    creditIcon.Text = "👑"
    creditIcon.TextSize = 40
    creditIcon.Font = Enum.Font.GothamBold
    creditIcon.Parent = creditsFrame
    
    local creditTitle = Instance.new("TextLabel")
    creditTitle.Size = UDim2.new(1, 0, 0, 20)
    creditTitle.Position = UDim2.new(0, 0, 0, 65)
    creditTitle.BackgroundTransparency = 1
    creditTitle.Text = "2M"
    creditTitle.TextColor3 = CONFIG.COR_TEXTO
    creditTitle.TextSize = 18
    creditTitle.Font = Enum.Font.GothamBold
    creditTitle.Parent = creditsFrame
    
    local creditDesc = Instance.new("TextLabel")
    creditDesc.Size = UDim2.new(1, 0, 0, 14)
    creditDesc.Position = UDim2.new(0, 0, 0, 83)
    creditDesc.BackgroundTransparency = 1
    creditDesc.Text = "Desenvolvedor & Designer"
    creditDesc.TextColor3 = CONFIG.COR_TEXTO_SEC
    creditDesc.TextSize = 11
    creditDesc.Font = Enum.Font.Gotham
    creditDesc.Parent = creditsFrame
    
    -- Animação de entrada dos elementos
    task.spawn(function()
        task.wait(0.5)
        for i, child in ipairs(tabFrames["Player"]:GetChildren()) do
            if child:IsA("Frame") or child:IsA("TextButton") then
                AnimateIn(child, i * 0.05)
            end
        end
    end)
    
    CreateFloatingButton()
    
    Notify("SHAKA ULTRA carregado com sucesso!", GetCurrentColor(), "🚀")
    print("╔═══════════════════════════════════════╗")
    print("║    🟣 SHAKA ULTRA v2.0 - Carregado   ║")
    print("║    👑 Desenvolvido por 2M             ║")
    print("║    ⌨️  Pressione F para abrir/fechar  ║")
    print("╚═══════════════════════════════════════╝")
end

-- ══════════════════════════════════════════════════════════
-- RECARREGAR ESTADOS
-- ══════════════════════════════════════════════════════════
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
    
    Camera.FieldOfView = SavedStates.FOV
    
    if SavedStates.RainbowMode then
        if Connections.MenuRainbow then Connections.MenuRainbow:Disconnect() end
        Connections.MenuRainbow = RunService.Heartbeat:Connect(function()
            RainbowHue = (RainbowHue + 0.003) % 1
            UpdateAllColors()
        end)
    end
end

-- ══════════════════════════════════════════════════════════
-- INICIALIZAÇÃO
-- ══════════════════════════════════════════════════════════
task.wait(0.3)
CreateGUI()
ReloadSavedStates()

-- ══════════════════════════════════════════════════════════
-- CONTROLES
-- ══════════════════════════════════════════════════════════
UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    
    if input.KeyCode == Enum.KeyCode.F then
        if GUI then
            local mainWindow = GUI:FindFirstChild("MainWindow")
            local floatingBtn = GUI:FindFirstChild("FloatingButton")
            
            if mainWindow then
                IsMenuOpen = not IsMenuOpen
                if IsMenuOpen then
                    mainWindow.Visible = true
                    mainWindow.Position = UDim2.new(0.5, -300, 1.5, 0)
                    Tween(mainWindow, {Position = UDim2.new(0.5, -300, 0.5, -250)}, 0.5, Enum.EasingStyle.Back)
                    
                    if floatingBtn then
                        Tween(floatingBtn, {BackgroundTransparency = 1}, 0.3)
                        Tween(floatingBtn:FindFirstChildOfClass("UIStroke"), {Transparency = 1}, 0.3)
                        Tween(floatingBtn:FindFirstChildOfClass("TextLabel"), {TextTransparency = 1}, 0.3)
                        task.wait(0.3)
                        floatingBtn.Visible = false
                    end
                else
                    Tween(mainWindow, {Position = UDim2.new(0.5, -300, 1.5, 0)}, 0.4, Enum.EasingStyle.Back)
                    task.wait(0.4)
                    mainWindow.Visible = false
                    
                    if floatingBtn then
                        floatingBtn.Visible = true
                        floatingBtn.BackgroundTransparency = 0
                        Tween(floatingBtn:FindFirstChildOfClass("UIStroke"), {Transparency = 0}, 0.3)
                        Tween(floatingBtn:FindFirstChildOfClass("TextLabel"), {TextTransparency = 0}, 0.3)
                    end
                end
            end
        else
            CreateGUI()
            ReloadSavedStates()
        end
    end
end)

-- ══════════════════════════════════════════════════════════
-- EVENTOS
-- ══════════════════════════════════════════════════════════
LocalPlayer.CharacterAdded:Connect(function()
    task.wait(1)
    ReloadSavedStates()
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
        end)
        ESPObjects[player] = nil
    end
    
    if SelectedPlayer == player then
        SelectedPlayer = nil
    end
end)
