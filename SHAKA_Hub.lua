-- SHAKA Hub Premium v6.0 - Menu Completo e Funcional
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
    VERSAO = "v6.0",
    COR_ROXO = Color3.fromRGB(139, 0, 255),
    COR_ROXO_HOVER = Color3.fromRGB(170, 50, 255),
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
    ESP = {
        Enabled = false,
        Box = true,
        Line = true,
        Name = true,
        Distance = true,
        Health = true
    },
    RemoveFog = false,
    RemoveShadows = false,
    FOV = 70
}

local ESPObjects = {}

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
        notif.Size = UDim2.new(0, 280, 0, 55)
        notif.Position = UDim2.new(1, -290, 1, 10)
        notif.BackgroundColor3 = CONFIG.COR_FUNDO_2
        notif.BorderSizePixel = 0
        notif.Parent = GUI
        notif.ZIndex = 1000
        
        Instance.new("UICorner", notif).CornerRadius = UDim.new(0, 10)
        local stroke = Instance.new("UIStroke", notif)
        stroke.Color = color or CONFIG.COR_ROXO
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
        
        Tween(notif, {Position = UDim2.new(1, -290, 1, -65)}, 0.3)
        task.wait(3)
        Tween(notif, {Position = UDim2.new(1, 10, 1, -65)}, 0.3)
        task.wait(0.3)
        if notif then notif:Destroy() end
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

local function SetSpeed(value)
    SavedStates.WalkSpeed = value
end

local function SetJumpPower(value)
    SavedStates.JumpPower = value
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

-- Manter velocidade e pulo
task.spawn(function()
    while true do
        local char = LocalPlayer.Character
        if char then
            local humanoid = char:FindFirstChildOfClass("Humanoid")
            if humanoid then
                if SavedStates.WalkSpeed and humanoid.WalkSpeed ~= SavedStates.WalkSpeed then
                    humanoid.WalkSpeed = SavedStates.WalkSpeed
                end
                if SavedStates.JumpPower and humanoid.JumpPower ~= SavedStates.JumpPower then
                    humanoid.JumpPower = SavedStates.JumpPower
                end
            end
        end
        task.wait(0.1)
    end
end)

-- ════════════════════════════════════════════════════════════
-- FUNÇÕES DE TELEPORTE
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
            root.CFrame = targetRoot.CFrame * CFrame.new(0, 2, 4)
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
            -- Método alternativo mais confiável
            local oldPos = targetRoot.CFrame
            targetRoot.CFrame = root.CFrame * CFrame.new(0, 0, -4)
            task.wait(0.1)
            targetRoot.Anchored = false
            Notify("🔙 " .. SelectedPlayer.Name .. " trazido", CONFIG.COR_SUCESSO)
        end
    end
end

-- ════════════════════════════════════════════════════════════
-- FUNÇÕES DE COMBAT
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
            -- Método mais eficaz
            for i = 1, 10 do
                humanoid.Health = 0
                humanoid:TakeDamage(humanoid.MaxHealth)
                task.wait()
            end
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
            explosion.BlastPressure = 1000000
            explosion.Parent = workspace
            
            local humanoid = targetChar:FindFirstChildOfClass("Humanoid")
            if humanoid then
                humanoid:TakeDamage(100)
            end
            
            Notify("💥 Explosão criada!", CONFIG.COR_SUCESSO)
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
        for _, part in pairs(targetChar:GetDescendants()) do
            if part:IsA("BasePart") then
                local fire = Instance.new("Fire")
                fire.Size = 10
                fire.Heat = 15
                fire.Parent = part
            end
        end
        
        local humanoid = targetChar:FindFirstChildOfClass("Humanoid")
        if humanoid then
            task.spawn(function()
                for i = 1, 20 do
                    humanoid:TakeDamage(5)
                    task.wait(0.5)
                end
            end)
        end
        
        Notify("🔥 Jogador incendiado!", CONFIG.COR_SUCESSO)
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
            bodyVelocity.MaxForce = Vector3.new(9e9, 9e9, 9e9)
            bodyVelocity.Velocity = Vector3.new(
                math.random(-200, 200),
                math.random(100, 300),
                math.random(-200, 200)
            )
            bodyVelocity.Parent = root
            
            task.wait(0.5)
            bodyVelocity:Destroy()
            
            Notify("🌪️ " .. SelectedPlayer.Name .. " arremessado!", CONFIG.COR_SUCESSO)
        end
    end
end

-- ════════════════════════════════════════════════════════════
-- SISTEMA DE ESP
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
    
    local esp = {
        Player = player,
        Box = nil,
        Line = nil,
        Name = nil,
        Distance = nil,
        Health = nil
    }
    
    -- Box ESP
    if SavedStates.ESP.Box then
        esp.Box = Drawing.new("Square")
        esp.Box.Thickness = 2
        esp.Box.Filled = false
        esp.Box.Color = Color3.new(1, 0, 1)
        esp.Box.Visible = false
        esp.Box.ZIndex = 2
    end
    
    -- Line ESP
    if SavedStates.ESP.Line then
        esp.Line = Drawing.new("Line")
        esp.Line.Thickness = 2
        esp.Line.Color = Color3.new(1, 0, 1)
        esp.Line.Visible = false
        esp.Line.ZIndex = 2
    end
    
    -- Name ESP
    if SavedStates.ESP.Name then
        esp.Name = Drawing.new("Text")
        esp.Name.Size = 16
        esp.Name.Center = true
        esp.Name.Outline = true
        esp.Name.Color = Color3.new(1, 1, 1)
        esp.Name.Visible = false
        esp.Name.ZIndex = 2
        esp.Name.Text = player.Name
    end
    
    -- Distance ESP
    if SavedStates.ESP.Distance then
        esp.Distance = Drawing.new("Text")
        esp.Distance.Size = 14
        esp.Distance.Center = true
        esp.Distance.Outline = true
        esp.Distance.Color = Color3.new(1, 1, 0)
        esp.Distance.Visible = false
        esp.Distance.ZIndex = 2
    end
    
    -- Health ESP
    if SavedStates.ESP.Health then
        esp.Health = Drawing.new("Line")
        esp.Health.Thickness = 3
        esp.Health.Visible = false
        esp.Health.ZIndex = 2
    end
    
    ESPObjects[player] = esp
end

local function UpdateESP()
    for player, esp in pairs(ESPObjects) do
        if not player or not player.Parent or not player.Character then
            if esp.Box then esp.Box:Remove() end
            if esp.Line then esp.Line:Remove() end
            if esp.Name then esp.Name:Remove() end
            if esp.Distance then esp.Distance:Remove() end
            if esp.Health then esp.Health:Remove() end
            ESPObjects[player] = nil
            continue
        end
        
        local char = player.Character
        local root = char:FindFirstChild("HumanoidRootPart")
        local head = char:FindFirstChild("Head")
        local humanoid = char:FindFirstChildOfClass("Humanoid")
        
        if root and head and humanoid and humanoid.Health > 0 then
            local rootPos, onScreen = Camera:WorldToViewportPoint(root.Position)
            
            if onScreen then
                local headPos = Camera:WorldToViewportPoint(head.Position + Vector3.new(0, 0.5, 0))
                local legPos = Camera:WorldToViewportPoint(root.Position - Vector3.new(0, 3, 0))
                
                local height = math.abs(headPos.Y - legPos.Y)
                local width = height / 2
                
                -- Update Box
                if esp.Box and SavedStates.ESP.Box then
                    esp.Box.Size = Vector2.new(width, height)
                    esp.Box.Position = Vector2.new(rootPos.X - width/2, rootPos.Y - height/2)
                    esp.Box.Visible = true
                end
                
                -- Update Line
                if esp.Line and SavedStates.ESP.Line then
                    esp.Line.From = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
                    esp.Line.To = Vector2.new(rootPos.X, rootPos.Y)
                    esp.Line.Visible = true
                end
                
                -- Update Name
                if esp.Name and SavedStates.ESP.Name then
                    esp.Name.Position = Vector2.new(rootPos.X, headPos.Y - 20)
                    esp.Name.Text = player.Name
                    esp.Name.Visible = true
                end
                
                -- Update Distance
                if esp.Distance and SavedStates.ESP.Distance then
                    local distance = (LocalPlayer.Character.HumanoidRootPart.Position - root.Position).Magnitude
                    esp.Distance.Position = Vector2.new(rootPos.X, legPos.Y + 5)
                    esp.Distance.Text = string.format("[%d studs]", math.floor(distance))
                    esp.Distance.Visible = true
                end
                
                -- Update Health
                if esp.Health and SavedStates.ESP.Health then
                    local healthPercent = humanoid.Health / humanoid.MaxHealth
                    esp.Health.From = Vector2.new(rootPos.X - width/2 - 5, rootPos.Y - height/2)
                    esp.Health.To = Vector2.new(rootPos.X - width/2 - 5, rootPos.Y - height/2 + (height * healthPercent))
                    esp.Health.Color = Color3.new(1 - healthPercent, healthPercent, 0)
                    esp.Health.Visible = true
                end
            else
                if esp.Box then esp.Box.Visible = false end
                if esp.Line then esp.Line.Visible = false end
                if esp.Name then esp.Name.Visible = false end
                if esp.Distance then esp.Distance.Visible = false end
                if esp.Health then esp.Health.Visible = false end
            end
        else
            if esp.Box then esp.Box.Visible = false end
            if esp.Line then esp.Line.Visible = false end
            if esp.Name then esp.Name.Visible = false end
            if esp.Distance then esp.Distance.Visible = false end
            if esp.Health then esp.Health.Visible = false end
        end
    end
end

local function ToggleESP(state)
    SavedStates.ESP.Enabled = state
    
    if Connections.ESP then
        Connections.ESP:Disconnect()
        Connections.ESP = nil
    end
    
    if state then
        -- Criar ESP para jogadores existentes
        for _, player in pairs(Players:GetPlayers()) do
            CreateESP(player)
        end
        
        -- Atualizar ESP
        Connections.ESP = RunService.RenderStepped:Connect(UpdateESP)
        
        Notify("👁️ ESP ativado", CONFIG.COR_SUCESSO)
    else
        ClearESP()
        Notify("👁️ ESP desativado", CONFIG.COR_ERRO)
    end
end

-- Detectar novos jogadores
Players.PlayerAdded:Connect(function(player)
    if SavedStates.ESP.Enabled then
        task.wait(1)
        CreateESP(player)
    end
end)

Players.PlayerRemoving:Connect(function(player)
    if ESPObjects[player] then
        local esp = ESPObjects[player]
        if esp.Box then esp.Box:Remove() end
        if esp.Line then esp.Line:Remove() end
        if esp.Name then esp.Name:Remove() end
        if esp.Distance then esp.Distance:Remove() end
        if esp.Health then esp.Health:Remove() end
        ESPObjects[player] = nil
    end
end)

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
        Lighting.ClockTime = 14
        Lighting.FogEnd = 1e5
        Lighting.GlobalShadows = true
        Lighting.OutdoorAmbient = Color3.new(0.5, 0.5, 0.5)
        Lighting.Ambient = Color3.new(0, 0, 0)
        Notify("💡 Fullbright desativado", CONFIG.COR_ERRO)
    end
end

-- ════════════════════════════════════════════════════════════
-- CRIAÇÃO DA GUI
-- ════════════════════════════════════════════════════════════
local function CreateGUI()
    if GUI then
        GUI:Destroy()
    end
    
    -- ScreenGui Principal
    GUI = Instance.new("ScreenGui")
    GUI.Name = "SHAKA_HUB"
    GUI.ResetOnSpawn = false
    GUI.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    GUI.Parent = LocalPlayer:WaitForChild("PlayerGui")
    
    -- Container Principal (Agora maior)
    local main = Instance.new("Frame")
    main.Name = "Main"
    main.Size = UDim2.new(0, 700, 0, 500)
    main.Position = UDim2.new(0.5, -350, 0.5, -250)
    main.BackgroundColor3 = CONFIG.COR_FUNDO
    main.BorderSizePixel = 0
    main.Parent = GUI
    
    local mainCorner = Instance.new("UICorner")
    mainCorner.CornerRadius = UDim.new(0, 12)
    mainCorner.Parent = main
    
    local mainStroke = Instance.new("UIStroke")
    mainStroke.Color = CONFIG.COR_ROXO
    mainStroke.Thickness = 2
    mainStroke.Parent = main
    
    -- Header
    local header = Instance.new("Frame")
    header.Name = "Header"
    header.Size = UDim2.new(1, 0, 0, 50)
    header.BackgroundColor3 = CONFIG.COR_FUNDO_2
    header.BorderSizePixel = 0
    header.Parent = main
    
    local headerCorner = Instance.new("UICorner")
    headerCorner.CornerRadius = UDim.new(0, 12)
    headerCorner.Parent = header
    
    -- Logo
    local logo = Instance.new("TextLabel")
    logo.Size = UDim2.new(0, 120, 1, 0)
    logo.Position = UDim2.new(0, 20, 0, 0)
    logo.BackgroundTransparency = 1
    logo.Text = "🟣 SHAKA HUB"
    logo.TextColor3 = CONFIG.COR_ROXO
    logo.TextSize = 20
    logo.Font = Enum.Font.GothamBold
    logo.TextXAlignment = Enum.TextXAlignment.Left
    logo.Parent = header
    
    -- Versão
    local version = Instance.new("TextLabel")
    version.Size = UDim2.new(0, 60, 0, 22)
    version.Position = UDim2.new(0, 145, 0, 14)
    version.BackgroundColor3 = CONFIG.COR_ROXO
    version.Text = CONFIG.VERSAO
    version.TextColor3 = CONFIG.COR_TEXTO
    version.TextSize = 12
    version.Font = Enum.Font.GothamBold
    version.BorderSizePixel = 0
    version.Parent = header
    
    local versionCorner = Instance.new("UICorner")
    versionCorner.CornerRadius = UDim.new(0, 6)
    versionCorner.Parent = version
    
    -- Botão Fechar
    local closeBtn = Instance.new("TextButton")
    closeBtn.Size = UDim2.new(0, 35, 0, 35)
    closeBtn.Position = UDim2.new(1, -45, 0, 7)
    closeBtn.BackgroundColor3 = CONFIG.COR_ERRO
