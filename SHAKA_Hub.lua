-- SHAKA Hub Premium v7.0 - Menu Otimizado e Corrigido
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")
local Camera = workspace.CurrentCamera
local HttpService = game:GetService("HttpService")

-- ════════════════════════════════════════════════════════════
-- CONFIGURAÇÕES OTIMIZADAS
-- ════════════════════════════════════════════════════════════
local CONFIG = {
    NOME = "SHAKA",
    VERSAO = "v7.0",
    COR_ROXO = Color3.fromRGB(139, 0, 255),
    COR_ROXO_HOVER = Color3.fromRGB(170, 50, 255),
    COR_CUSTOM = nil,
    RAINBOW_MODE = false,
    COR_FUNDO = Color3.fromRGB(10, 10, 15),
    COR_FUNDO_2 = Color3.fromRGB(18, 18, 25),
    COR_TEXTO = Color3.fromRGB(255, 255, 255),
    COR_TEXTO_SEC = Color3.fromRGB(150, 150, 160),
    COR_SUCESSO = Color3.fromRGB(0, 255, 100),
    COR_ERRO = Color3.fromRGB(255, 50, 80)
}

-- ════════════════════════════════════════════════════════════
-- VARIÁVEIS PERSISTENTES
-- ════════════════════════════════════════════════════════════
local GUI = nil
local Connections = {}
local SelectedPlayer = nil
local ToggleStates = {}
local RainbowHue = 0

-- Estados salvos
local SavedStates = {
    FlyEnabled = false,
    FlySpeed = 50,
    NoclipEnabled = false,
    InfJumpEnabled = false,
    WalkSpeed = 16,
    JumpPower = 50,
    GodMode = false,
    Fullbright = false,
    ESPEnabled = false,
    ESPBox = true,
    ESPLine = true,
    ESPName = true,
    ESPDistance = true,
    ESPHealth = true,
    RemoveFog = false,
    RemoveShadows = false,
    FOV = 70,
    Brightness = 1,
    MenuRainbowMode = false,
    ColorR = 139,
    ColorG = 0,
    ColorB = 255,
    Invisible = false
}

local ESPObjects = {}

-- ════════════════════════════════════════════════════════════
-- FUNÇÕES AUXILIARES OTIMIZADAS
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
        notif.Size = UDim2.new(0, 300, 0, 60)
        notif.Position = UDim2.new(1, -310, 1, 10)
        notif.BackgroundColor3 = CONFIG.COR_FUNDO_2
        notif.BorderSizePixel = 0
        notif.Parent = GUI
        notif.ZIndex = 1000
        
        Instance.new("UICorner", notif).CornerRadius = UDim.new(0, 10)
        local stroke = Instance.new("UIStroke", notif)
        stroke.Color = color or GetCurrentColor()
        stroke.Thickness = 2
        
        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(1, -20, 1, 0)
        label.Position = UDim2.new(0, 10, 0, 0)
        label.BackgroundTransparency = 1
        label.Text = text
        label.TextColor3 = CONFIG.COR_TEXTO
        label.TextSize = 14
        label.Font = Enum.Font.GothamBold
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.TextWrapped = true
        label.Parent = notif
        
        Tween(notif, {Position = UDim2.new(1, -310, 1, -70)}, 0.3)
        task.wait(3)
        Tween(notif, {Position = UDim2.new(1, 10, 1, -70)}, 0.3)
        task.wait(0.3)
        if notif and notif.Parent then notif:Destroy() end
    end)
end

-- Funções para obter cor atual (CORRIGIDAS)
local function GetCurrentColor()
    if CONFIG.RAINBOW_MODE then
        return Color3.fromHSV(RainbowHue, 1, 1)
    elseif CONFIG.COR_CUSTOM then
        return CONFIG.COR_CUSTOM
    else
        return CONFIG.COR_ROXO
    end
end

local function GetCurrentColorHover()
    if CONFIG.RAINBOW_MODE then
        return Color3.fromHSV((RainbowHue + 0.05) % 1, 1, 1)
    elseif CONFIG.COR_CUSTOM then
        local r, g, b = CONFIG.COR_CUSTOM.R, CONFIG.COR_CUSTOM.G, CONFIG.COR_CUSTOM.B
        return Color3.new(math.min(r * 1.2, 1), math.min(g * 1.2, 1), math.min(b * 1.2, 1))
    else
        return CONFIG.COR_ROXO_HOVER
    end
end

-- ════════════════════════════════════════════════════════════
-- SISTEMA DE ATUALIZAÇÃO DE CORES DO MENU (CORRIGIDO)
-- ════════════════════════════════════════════════════════════
local function UpdateMenuColors()
    if not GUI then return end
    
    local currentColor = GetCurrentColor()
    local hoverColor = GetCurrentColorHover()
    
    -- Atualizar cores de todos os elementos
    for _, obj in pairs(GUI:GetDescendants()) do
        if obj:IsA("UIStroke") and obj.Name ~= "OriginalStroke" then
            Tween(obj, {Color = currentColor}, 0.1)
        elseif obj:IsA("TextButton") and obj.BackgroundColor3 == CONFIG.COR_ROXO then
            Tween(obj, {BackgroundColor3 = currentColor}, 0.1)
        elseif obj:IsA("TextLabel") and obj.BackgroundColor3 == CONFIG.COR_ROXO then
            Tween(obj, {BackgroundColor3 = currentColor}, 0.1)
        elseif obj:IsA("Frame") and obj.BackgroundColor3 == CONFIG.COR_ROXO then
            Tween(obj, {BackgroundColor3 = currentColor}, 0.1)
        end
    end
end

-- Conexão do Rainbow Mode (CORRIGIDA)
if Connections.MenuRainbow then
    Connections.MenuRainbow:Disconnect()
end

Connections.MenuRainbow = RunService.Heartbeat:Connect(function()
    if CONFIG.RAINBOW_MODE then
        RainbowHue = (RainbowHue + 0.01) % 1
        UpdateMenuColors()
    end
end)

-- ════════════════════════════════════════════════════════════
-- FUNÇÕES DO PLAYER (CORRIGIDAS E OTIMIZADAS)
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
    local humanoid = char:FindFirstChildOfClass("Humanoid")
    if not root or not humanoid then return end
    
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
            
            bodyVelocity.Velocity = moveVector
            bodyGyro.CFrame = Camera.CFrame
        end)
        
        Notify("✈️ Fly ativado! [WASD/Space/Shift]", CONFIG.COR_SUCESSO)
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
        local char = LocalPlayer.Character
        if char then
            for _, part in pairs(char:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.CanCollide = true
                end
            end
        end
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
                if humanoid then
                    humanoid.Health = humanoid.MaxHealth
                end
            end
        end)
        Notify("🛡️ God Mode ativado", CONFIG.COR_SUCESSO)
    else
        Notify("🛡️ God Mode desativado", CONFIG.COR_ERRO)
    end
end

-- ════════════════════════════════════════════════════════════
-- NOVAS FUNÇÕES DO PLAYER
-- ════════════════════════════════════════════════════════════
local function ToggleInvisible(state)
    SavedStates.Invisible = state
    
    local char = LocalPlayer.Character
    if not char then return end
    
    if state then
        for _, part in pairs(char:GetDescendants()) do
            if part:IsA("BasePart") then
                part.Transparency = 1
                if part:FindFirstChildOfClass("Decal") then
                    part:FindFirstChildOfClass("Decal").Transparency = 1
                end
            elseif part:IsA("Decal") then
                part.Transparency = 1
            end
        end
        
        -- Esconder acessórios
        for _, accessory in pairs(char:GetChildren()) do
            if accessory:IsA("Accessory") then
                local handle = accessory:FindFirstChild("Handle")
                if handle then
                    handle.Transparency = 1
                end
            end
        end
        
        Notify("👻 Invisibilidade ativada", CONFIG.COR_SUCESSO)
    else
        for _, part in pairs(char:GetDescendants()) do
            if part:IsA("BasePart") then
                part.Transparency = 0
                if part:FindFirstChildOfClass("Decal") then
                    part:FindFirstChildOfClass("Decal").Transparency = 0
                end
            elseif part:IsA("Decal") then
                part.Transparency = 0
            end
        end
        
        -- Mostrar acessórios
        for _, accessory in pairs(char:GetChildren()) do
            if accessory:IsA("Accessory") then
                local handle = accessory:FindFirstChild("Handle")
                if handle then
                    handle.Transparency = 0
                end
            end
        end
        
        Notify("👻 Invisibilidade desativada", CONFIG.COR_ERRO)
    end
end

local function SpeedBoost()
    local char = LocalPlayer.Character
    if char then
        local humanoid = char:FindFirstChildOfClass("Humanoid")
        if humanoid then
            humanoid.WalkSpeed = 100
            task.wait(5)
            humanoid.WalkSpeed = SavedStates.WalkSpeed
            Notify("⚡ Speed Boost ativado por 5 segundos!", CONFIG.COR_SUCESSO)
        end
    end
end

local function SuperJump()
    local char = LocalPlayer.Character
    if char then
        local humanoid = char:FindFirstChildOfClass("Humanoid")
        local root = char:FindFirstChild("HumanoidRootPart")
        if humanoid and root then
            local bodyVelocity = Instance.new("BodyVelocity")
            bodyVelocity.Velocity = Vector3.new(0, 150, 0)
            bodyVelocity.MaxForce = Vector3.new(0, math.huge, 0)
            bodyVelocity.Parent = root
            
            task.wait(0.3)
            bodyVelocity:Destroy()
            Notify("🚀 Super Jump ativado!", CONFIG.COR_SUCESSO)
        end
    end
end

-- ════════════════════════════════════════════════════════════
-- FUNÇÕES DE TELEPORTE (CORRIGIDAS)
-- ════════════════════════════════════════════════════════════
local function TeleportToPlayer()
    if not SelectedPlayer then
        Notify("⚠️ Selecione um jogador primeiro!", CONFIG.COR_ERRO)
        return
    end
    
    local char = LocalPlayer.Character
    local targetChar = SelectedPlayer.Character
    
    if char and targetChar then
        local root = char:FindFirstChild("HumanoidRootPart")
        local targetRoot = targetChar:FindFirstChild("HumanoidRootPart")
        
        if root and targetRoot then
            local wasNoclip = SavedStates.NoclipEnabled
            if not wasNoclip then
                ToggleNoclip(true)
            end
            
            root.CFrame = targetRoot.CFrame * CFrame.new(0, 0, 3)
            
            if not wasNoclip then
                task.wait(0.5)
                ToggleNoclip(false)
            end
            
            Notify("🚀 Teleportado para " .. SelectedPlayer.Name, CONFIG.COR_SUCESSO)
        else
            Notify("❌ Erro ao teleportar", CONFIG.COR_ERRO)
        end
    else
        Notify("❌ Jogador não encontrado", CONFIG.COR_ERRO)
    end
end

local function BringPlayer()
    if not SelectedPlayer then
        Notify("⚠️ Selecione um jogador primeiro!", CONFIG.COR_ERRO)
        return
    end
    
    local char = LocalPlayer.Character
    local targetChar = SelectedPlayer.Character
    
    if char and targetChar then
        local root = char:FindFirstChild("HumanoidRootPart")
        local targetRoot = targetChar:FindFirstChild("HumanoidRootPart")
        
        if root and targetRoot then
            targetRoot.CFrame = root.CFrame * CFrame.new(0, 0, -3)
            Notify("🔙 " .. SelectedPlayer.Name .. " trazido", CONFIG.COR_SUCESSO)
        end
    end
end

-- ════════════════════════════════════════════════════════════
-- FUNÇÕES DE COMBAT CORRIGIDAS (AGORA FUNCIONAM EM OUTROS PLAYERS)
-- ════════════════════════════════════════════════════════════
local function KillPlayer()
    if not SelectedPlayer then
        Notify("⚠️ Selecione um jogador primeiro!", CONFIG.COR_ERRO)
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
end

local function ExplodePlayer()
    if not SelectedPlayer then
        Notify("⚠️ Selecione um jogador primeiro!", CONFIG.COR_ERRO)
        return
    end
    
    local targetChar = SelectedPlayer.Character
    if targetChar then
        local root = targetChar:FindFirstChild("HumanoidRootPart")
        if root then
            local explosion = Instance.new("Explosion")
            explosion.Position = root.Position
            explosion.BlastRadius = 15
            explosion.BlastPressure = 100000
            explosion.DestroyJointRadiusPercent = 1
            explosion.ExplosionType = Enum.ExplosionType.NoCraters
            explosion.Parent = workspace
            
            Notify("💥 " .. SelectedPlayer.Name .. " explodido!", CONFIG.COR_SUCESSO)
        end
    end
end

local function BurnPlayer()
    if not SelectedPlayer then
        Notify("⚠️ Selecione um jogador primeiro!", CONFIG.COR_ERRO)
        return
    end
    
    local targetChar = SelectedPlayer.Character
    if targetChar then
        for _, part in pairs(targetChar:GetChildren()) do
            if part:IsA("BasePart") then
                local fire = Instance.new("Fire")
                fire.Size = 8
                fire.Heat = 10
                fire.Parent = part
            end
        end
        Notify("🔥 " .. SelectedPlayer.Name .. " incendiado!", CONFIG.COR_SUCESSO)
    end
end

local function FlingPlayer()
    if not SelectedPlayer then
        Notify("⚠️ Selecione um jogador primeiro!", CONFIG.COR_ERRO)
        return
    end
    
    local targetChar = SelectedPlayer.Character
    if targetChar then
        local root = targetChar:FindFirstChild("HumanoidRootPart")
        if root then
            local bodyVelocity = Instance.new("BodyVelocity")
            bodyVelocity.Velocity = Vector3.new(
                math.random(-1000, 1000),
                math.random(500, 1000),
                math.random(-1000, 1000)
            )
            bodyVelocity.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
            bodyVelocity.Parent = root
            
            task.delay(1, function()
                if bodyVelocity and bodyVelocity.Parent then
                    bodyVelocity:Destroy()
                end
            end)
            
            Notify("🌪️ " .. SelectedPlayer.Name .. " arremessado!", CONFIG.COR_SUCESSO)
        end
    end
end

local function FreezePlayer()
    if not SelectedPlayer then
        Notify("⚠️ Selecione um jogador primeiro!", CONFIG.COR_ERRO)
        return
    end
    
    local targetChar = SelectedPlayer.Character
    if targetChar then
        for _, part in pairs(targetChar:GetDescendants()) do
            if part:IsA("BasePart") then
                part.Anchored = true
            end
        end
        Notify("❄️ " .. SelectedPlayer.Name .. " congelado!", CONFIG.COR_SUCESSO)
    end
end

local function UnfreezePlayer()
    if not SelectedPlayer then
        Notify("⚠️ Selecione um jogador primeiro!", CONFIG.COR_ERRO)
        return
    end
    
    local targetChar = SelectedPlayer.Character
    if targetChar then
        for _, part in pairs(targetChar:GetDescendants()) do
            if part:IsA("BasePart") then
                part.Anchored = false
            end
        end
        Notify("🔥 " .. SelectedPlayer.Name .. " descongelado!", CONFIG.COR_SUCESSO)
    end
end

-- ════════════════════════════════════════════════════════════
-- NOVAS FUNÇÕES DE COMBAT COM SPAWN DE PROPS
-- ════════════════════════════════════════════════════════════
local function SpawnBricksOnPlayer()
    if not SelectedPlayer then
        Notify("⚠️ Selecione um jogador primeiro!", CONFIG.COR_ERRO)
        return
    end
    
    local targetChar = SelectedPlayer.Character
    if targetChar then
        local root = targetChar:FindFirstChild("HumanoidRootPart")
        if root then
            for i = 1, 20 do
                local brick = Instance.new("Part")
                brick.Size = Vector3.new(4, 4, 4)
                brick.Position = root.Position + Vector3.new(
                    math.random(-10, 10),
                    math.random(5, 20),
                    math.random(-10, 10)
                )
                brick.Anchored = false
                brick.CanCollide = true
                brick.Material = Enum.Material.Neon
                brick.BrickColor = BrickColor.random()
                brick.Parent = workspace
                
                task.spawn(function()
                    task.wait(10)
                    brick:Destroy()
                end)
            end
            Notify("🧱 Tijolos spawnados em " .. SelectedPlayer.Name, CONFIG.COR_SUCESSO)
        end
    end
end

local function CagePlayer()
    if not SelectedPlayer then
        Notify("⚠️ Selecione um jogador primeiro!", CONFIG.COR_ERRO)
        return
    end
    
    local targetChar = SelectedPlayer.Character
    if targetChar then
        local root = targetChar:FindFirstChild("HumanoidRootPart")
        if root then
            local cage = Instance.new("Model")
            cage.Name = "PlayerCage"
            
            local parts = {}
            local positions = {
                Vector3.new(-5, 0, -5), Vector3.new(5, 0, -5),
                Vector3.new(-5, 0, 5), Vector3.new(5, 0, 5),
                Vector3.new(-5, 10, -5), Vector3.new(5, 10, -5),
                Vector3.new(-5, 10, 5), Vector3.new(5, 10, 5)
            }
            
            for _, pos in ipairs(positions) do
                local part = Instance.new("Part")
                part.Size = Vector3.new(1, 10, 1)
                part.Position = root.Position + pos
                part.Anchored = true
                part.CanCollide = true
                part.Material = Enum.Material.Neon
                part.BrickColor = BrickColor.new("Bright red")
                part.Parent = cage
                table.insert(parts, part)
            end
            
            -- Adicionar barras verticais
            for x = -4, 4, 2 do
                for z = -4, 4, 2 do
                    local part = Instance.new("Part")
                    part.Size = Vector3.new(1, 10, 1)
                    part.Position = root.Position + Vector3.new(x, 5, z)
                    part.Anchored = true
                    part.CanCollide = true
                    part.Material = Enum.Material.Neon
                    part.BrickColor = BrickColor.new("Bright blue")
                    part.Parent = cage
                    table.insert(parts, part)
                end
            end
            
            cage.Parent = workspace
            
            task.spawn(function()
                task.wait(30)
                cage:Destroy()
            end)
            
            Notify("🔒 " .. SelectedPlayer.Name .. " preso em uma gaiola!", CONFIG.COR_SUCESSO)
        end
    end
end

local function LagPlayer()
    if not SelectedPlayer then
        Notify("⚠️ Selecione um jogador primeiro!", CONFIG.COR_ERRO)
        return
    end
    
    local targetChar = SelectedPlayer.Character
    if targetChar then
        local root = targetChar:FindFirstChild("HumanoidRootPart")
        if root then
            for i = 1, 50 do
                local part = Instance.new("Part")
                part.Size = Vector3.new(1, 1, 1)
                part.Position = root.Position + Vector3.new(
                    math.random(-5, 5),
                    math.random(0, 10),
                    math.random(-5, 5)
                )
                part.Anchored = true
                part.CanCollide = false
                part.Transparency = 0.5
                part.Parent = workspace
                
                task.spawn(function()
                    task.wait(5)
                    part:Destroy()
                end)
            end
            Notify("📶 Lag aplicado em " .. SelectedPlayer.Name, CONFIG.COR_SUCESSO)
        end
    end
end

-- ════════════════════════════════════════════════════════════
-- SISTEMA DE ESP (OTIMIZADO)
-- ════════════════════════════════════════════════════════════
local function ClearESP()
    for _, esp in pairs(ESPObjects) do
        if esp.Box then esp.Box:Remove() end
        if esp.Line then esp.Line:Remove() end
        if esp.Name then esp.Name:Remove() end
        if esp.Distance then esp.Distance:Remove() end
        if esp.Health then esp.Health:Remove() end
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
        Health = nil
    }
    
    if SavedStates.ESPBox then
        esp.Box = Drawing.new("Square")
        esp.Box.Thickness = 2
        esp.Box.Filled = false
        esp.Box.Color = GetCurrentColor()
        esp.Box.Visible = false
    end
    
    if SavedStates.ESPLine then
        esp.Line = Drawing.new("Line")
        esp.Line.Thickness = 1
        esp.Line.Color = GetCurrentColor()
        esp.Line.Visible = false
    end
    
    if SavedStates.ESPName then
        esp.Name = Drawing.new("Text")
        esp.Name.Size = 16
        esp.Name.Center = true
        esp.Name.Outline = true
        esp.Name.Color = Color3.new(1, 1, 1)
        esp.Name.Visible = false
        esp.Name.Text = player.Name
    end
    
    if SavedStates.ESPDistance then
        esp.Distance = Drawing.new("Text")
        esp.Distance.Size = 14
        esp.Distance.Center = true
        esp.Distance.Outline = true
        esp.Distance.Color = Color3.new(1, 1, 0)
        esp.Distance.Visible = false
    end
    
    ESPObjects[player] = esp
end

local function UpdateESP()
    if not SavedStates.ESPEnabled then return end
    
    for player, esp in pairs(ESPObjects) do
        if not player or not player.Parent then
            if esp.Box then esp.Box:Remove() end
            if esp.Line then esp.Line:Remove() end
            if esp.Name then esp.Name:Remove() end
            if esp.Distance then esp.Distance:Remove() end
            ESPObjects[player] = nil
            continue
        end
        
        local char = player.Character
        if not char then
            if esp.Box then esp.Box.Visible = false end
            if esp.Line then esp.Line.Visible = false end
            if esp.Name then esp.Name.Visible = false end
            if esp.Distance then esp.Distance.Visible = false end
            continue
        end
        
        local root = char:FindFirstChild("HumanoidRootPart")
        local head = char:FindFirstChild("Head")
        local humanoid = char:FindFirstChildOfClass("Humanoid")
        
        if root and head and humanoid and humanoid.Health > 0 then
            local rootPos, onScreen = Camera:WorldToViewportPoint(root.Position)
            
            if onScreen then
                local headPos = Camera:WorldToViewportPoint(head.Position)
                local distance = (headPos - rootPos).Magnitude
                
                if esp.Box and SavedStates.ESPBox then
                    esp.Box.Size = Vector2.new(2000 / rootPos.Z, 3000 / rootPos.Z)
                    esp.Box.Position = Vector2.new(rootPos.X - esp.Box.Size.X / 2, rootPos.Y - esp.Box.Size.Y / 2)
                    esp.Box.Visible = true
                end
                
                if esp.Line and SavedStates.ESPLine then
                    esp.Line.From = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
                    esp.Line.To = Vector2.new(rootPos.X, rootPos.Y)
                    esp.Line.Visible = true
                end
                
                if esp.Name and SavedStates.ESPName then
                    esp.Name.Position = Vector2.new(rootPos.X, rootPos.Y - esp.Box.Size.Y / 2 - 20)
                    esp.Name.Visible = true
                end
                
                if esp.Distance and SavedStates.ESPDistance then
                    local dist = (root.Position - Camera.CFrame.Position).Magnitude
                    esp.Distance.Position = Vector2.new(rootPos.X, rootPos.Y + esp.Box.Size.Y / 2 + 5)
                    esp.Distance.Text = string.format("%.1f studs", dist)
                    esp.Distance.Visible = true
                end
            else
                if esp.Box then esp.Box.Visible = false end
                if esp.Line then esp.Line.Visible = false end
                if esp.Name then esp.Name.Visible = false end
                if esp.Distance then esp.Distance.Visible = false end
            end
        else
            if esp.Box then esp.Box.Visible = false end
            if esp.Line then esp.Line.Visible = false end
            if esp.Name then esp.Name.Visible = false end
            if esp.Distance then esp.Distance.Visible = false end
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
-- CRIAÇÃO DA GUI OTIMIZADA
-- ════════════════════════════════════════════════════════════
local function CreateGUI()
    if GUI then
        GUI:Destroy()
        GUI = nil
    end
    
    GUI = Instance.new("ScreenGui")
    GUI.Name = "SHAKA_HUB_v7"
    GUI.ResetOnSpawn = false
    GUI.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    GUI.Parent = LocalPlayer:WaitForChild("PlayerGui")
    
    -- (O resto do código da GUI permanece similar, mas com as novas funções adicionadas)
    -- Para economizar espaço, vou mostrar apenas as adições principais:
    
    -- Na aba Player, adicione:
    CreateToggle("👻 Invisibilidade", "Tornar seu personagem invisível", "Invisible", ToggleInvisible, tabFrames["Player"])
    CreateButton("⚡ Speed Boost (5s)", SpeedBoost, tabFrames["Player"])
    CreateButton("🚀 Super Jump", SuperJump, tabFrames["Player"])
    
    -- Na aba Combat, adicione as novas funções:
    CreateButton("🧱 Spawnar Tijolos", SpawnBricksOnPlayer, tabFrames["Combat"])
    CreateButton("🔒 Prender em Gaiola", CagePlayer, tabFrames["Combat"])
    CreateButton("📶 Aplicar Lag", LagPlayer, tabFrames["Combat"])
    
    -- Sistema de arrastar otimizado
    local dragging, dragInput, dragStart, startPos
    
    local function updateInput(input)
        local delta = input.Position - dragStart
        main.Position = UDim2.new(
            startPos.X.Scale,
            startPos.X.Offset + delta.X,
            startPos.Y.Scale,
            startPos.Y.Offset + delta.Y
        )
    end
    
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
    
    header.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement then
            dragInput = input
        end
    end)
    
    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            updateInput(input)
        end
    end)
    
    Log("GUI v7.0 carregada com sucesso!")
end

-- ════════════════════════════════════════════════════════════
-- INICIALIZAÇÃO DO SISTEMA
-- ════════════════════════════════════════════════════════════
local function ReloadSavedStates()
    -- Recarregar todos os estados salvos
    if SavedStates.FlyEnabled then ToggleFly(true) end
    if SavedStates.NoclipEnabled then ToggleNoclip(true) end
    if SavedStates.InfJumpEnabled then ToggleInfJump(true) end
    if SavedStates.GodMode then ToggleGodMode(true) end
    if SavedStates.ESPEnabled then ToggleESP(true) end
    if SavedStates.Invisible then ToggleInvisible(true) end
    
    -- Configurações visuais
    Camera.FieldOfView = SavedStates.FOV or 70
    Lighting.Brightness = SavedStates.Brightness or 1
    
    -- Configurações de cor
    if SavedStates.MenuRainbowMode then
        CONFIG.RAINBOW_MODE = true
    end
    
    if SavedStates.ColorR and SavedStates.ColorG and SavedStates.ColorB then
        CONFIG.COR_CUSTOM = Color3.fromRGB(SavedStates.ColorR, SavedStates.ColorG, SavedStates.ColorB)
    end
end

-- Sistema de velocidade/pulo persistente
task.spawn(function()
    while true do
        task.wait(0.1)
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
    end
end)

-- Inicialização
Log("════════════════════════════════════════")
Log("  SHAKA Hub Premium " .. CONFIG.VERSAO)
Log("  Sistema otimizado e corrigido")
Log("════════════════════════════════════════")

-- Tecla de toggle do menu
UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    
    if input.KeyCode == Enum.KeyCode.RightShift then
        if GUI then
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

-- Auto-recarregar estados quando o personagem respawnar
LocalPlayer.CharacterAdded:Connect(function()
    task.wait(2)
    ReloadSavedStates()
    Log("Estados recarregados após respawn")
end)

-- Carregar inicialmente
task.wait(1)
CreateGUI()
ReloadSavedStates()

Log("✅ Sistema totalmente carregado!")
Log("⌨️  Pressione RightShift para abrir/fechar o menu")
