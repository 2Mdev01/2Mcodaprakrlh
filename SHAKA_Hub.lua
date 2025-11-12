-- ╔══════════════════════════════════════════════════════════╗
-- ║         SHAKA Hub ULTRA v3.0 - Design Premium           ║
-- ║              Desenvolvido por 2M | 2025                  ║
-- ╚══════════════════════════════════════════════════════════╝

-- ══════════════════════════════════════════════════════════
-- SERVIÇOS DO ROBLOX
-- ══════════════════════════════════════════════════════════
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")
local Camera = workspace.CurrentCamera

-- ══════════════════════════════════════════════════════════
-- CONFIGURAÇÕES DE COR E TEMA
-- ══════════════════════════════════════════════════════════
local CONFIG = {
    NOME = "SHAKA",
    VERSAO = "v3.0",
    -- Cores principais do tema
    COR_PRINCIPAL = Color3.fromRGB(169, 3, 252),      -- #A903FC (Roxo vibrante)
    COR_HOVER = Color3.fromRGB(189, 23, 255),         -- Roxo mais claro para hover
    COR_FUNDO = Color3.fromRGB(0, 0, 0),              -- #000000 (Preto puro)
    COR_FUNDO_2 = Color3.fromRGB(15, 15, 15),         -- Preto levemente mais claro
    COR_FUNDO_3 = Color3.fromRGB(25, 25, 25),         -- Cinza escuro
    COR_TEXTO = Color3.fromRGB(255, 255, 255),        -- Branco puro
    COR_TEXTO_SEC = Color3.fromRGB(180, 180, 180),    -- Cinza claro
    COR_SUCESSO = Color3.fromRGB(34, 197, 94),        -- Verde
    COR_ERRO = Color3.fromRGB(239, 68, 68),           -- Vermelho
    COR_AVISO = Color3.fromRGB(251, 191, 36)          -- Amarelo
}

-- ══════════════════════════════════════════════════════════
-- VARIÁVEIS GLOBAIS DO SISTEMA
-- ══════════════════════════════════════════════════════════
local GUI = nil
local Connections = {}                  -- Armazena conexões ativas
local SelectedPlayer = nil              -- Jogador selecionado para trollagem
local RainbowHue = 0                    -- Valor do hue para modo rainbow
local UIElements = {}                   -- Elementos para aplicar rainbow
local MenuScale = 1                     -- Escala do menu

-- Estados salvos das funcionalidades
local SavedStates = {
    -- Movimento
    FlyEnabled = false,
    FlySpeed = 100,
    NoclipEnabled = false,
    InfJumpEnabled = false,
    WalkSpeed = 16,
    JumpPower = 50,
    GodMode = false,
    
    -- ESP
    ESPEnabled = false,
    ESPBox = true,
    ESPName = true,
    ESPDistance = true,
    ESPHealth = true,
    ESPTracers = true,
    
    -- Visual
    Fullbright = false,
    FOV = 70,
    RainbowMode = false,
    
    -- Aimbot
    AimbotEnabled = false,
    AimbotTeamCheck = true,
    AimbotVisibleCheck = true,
    AimbotSmoothing = 5,
    AimbotFOV = 200,
    AimbotShowFOV = true,
    
    -- Menu
    MenuWidth = 700,
    MenuHeight = 450
}

local ESPObjects = {}                   -- Objetos ESP ativos
local AimbotTarget = nil                -- Alvo do aimbot
local AimbotFOVCircle = nil             -- Círculo FOV do aimbot

-- ══════════════════════════════════════════════════════════
-- FUNÇÕES AUXILIARES DE UI
-- ══════════════════════════════════════════════════════════

-- Retorna a cor atual (normal ou rainbow)
local function GetCurrentColor()
    if SavedStates.RainbowMode then
        return Color3.fromHSV(RainbowHue, 0.85, 0.99)
    else
        return CONFIG.COR_PRINCIPAL
    end
end

-- Cria animação suave usando TweenService
local function Tween(obj, props, time, style)
    if not obj or not obj.Parent then return end
    local tweenInfo = TweenInfo.new(
        time or 0.3,
        style or Enum.EasingStyle.Quart,
        Enum.EasingDirection.Out
    )
    TweenService:Create(obj, tweenInfo, props):Play()
end

-- Sistema de notificações premium
local function Notify(text, color, icon)
    task.spawn(function()
        if not GUI or not GUI.Parent then return end
        
        -- Criar frame da notificação
        local notif = Instance.new("Frame")
        notif.Size = UDim2.new(0, 340, 0, 75)
        notif.Position = UDim2.new(1, 360, 0.85, -37)
        notif.BackgroundColor3 = CONFIG.COR_FUNDO_2
        notif.BorderSizePixel = 0
        notif.Parent = GUI
        notif.ZIndex = 10000
        
        Instance.new("UICorner", notif).CornerRadius = UDim.new(0, 12)
        
        -- Borda gradiente animada
        local border = Instance.new("UIStroke")
        border.Color = color or GetCurrentColor()
        border.Thickness = 2
        border.Transparency = 0
        border.Parent = notif
        
        -- Accent bar lateral
        local accent = Instance.new("Frame")
        accent.Size = UDim2.new(0, 5, 1, 0)
        accent.BackgroundColor3 = color or GetCurrentColor()
        accent.BorderSizePixel = 0
        accent.Parent = notif
        
        Instance.new("UICorner", accent).CornerRadius = UDim.new(0, 12)
        
        -- Ícone
        local iconLabel = Instance.new("TextLabel")
        iconLabel.Size = UDim2.new(0, 45, 0, 45)
        iconLabel.Position = UDim2.new(0, 20, 0.5, -22)
        iconLabel.BackgroundTransparency = 1
        iconLabel.Text = icon or "✓"
        iconLabel.TextColor3 = color or GetCurrentColor()
        iconLabel.TextSize = 26
        iconLabel.Font = Enum.Font.GothamBold
        iconLabel.Parent = notif
        
        -- Texto
        local textLabel = Instance.new("TextLabel")
        textLabel.Size = UDim2.new(1, -80, 1, 0)
        textLabel.Position = UDim2.new(0, 70, 0, 0)
        textLabel.BackgroundTransparency = 1
        textLabel.Text = text
        textLabel.TextColor3 = CONFIG.COR_TEXTO
        textLabel.TextSize = 13
        textLabel.Font = Enum.Font.Gotham
        textLabel.TextXAlignment = Enum.TextXAlignment.Left
        textLabel.TextWrapped = true
        textLabel.Parent = notif
        
        -- Animação de entrada
        Tween(notif, {Position = UDim2.new(1, -360, 0.85, -37)}, 0.5, Enum.EasingStyle.Back)
        
        -- Animação de pulso no ícone
        task.spawn(function()
            for i = 1, 3 do
                Tween(iconLabel, {TextSize = 30}, 0.3)
                task.wait(0.3)
                Tween(iconLabel, {TextSize = 26}, 0.3)
                task.wait(0.3)
            end
        end)
        
        -- Esperar e remover
        task.wait(3.5)
        Tween(notif, {Position = UDim2.new(1, 20, 0.85, -37)}, 0.4)
        Tween(border, {Transparency = 1}, 0.4)
        task.wait(0.4)
        if notif and notif.Parent then notif:Destroy() end
    end)
end

-- ══════════════════════════════════════════════════════════
-- FUNÇÕES DE MOVIMENTO DO PLAYER
-- ══════════════════════════════════════════════════════════

-- Sistema de voo melhorado (suporta mobile)
local function ToggleFly(state)
    SavedStates.FlyEnabled = state
    
    -- Desconectar conexão anterior se existir
    if Connections.Fly then
        Connections.Fly:Disconnect()
        Connections.Fly = nil
    end
    
    local char = LocalPlayer.Character
    if not char then return end
    local root = char:FindFirstChild("HumanoidRootPart")
    if not root then return end
    
    if state then
        -- Criar objetos de física para o voo
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
        
        -- Loop principal do voo
        Connections.Fly = RunService.Heartbeat:Connect(function()
            if not char or not char.Parent or not root or not root.Parent then
                ToggleFly(false)
                return
            end
            
            local speed = SavedStates.FlySpeed
            local move = Vector3.zero
            
            -- Controles PC (WASD + Space/Shift)
            if UserInputService:IsKeyDown(Enum.KeyCode.W) then 
                move = move + Camera.CFrame.LookVector * speed 
            end
            if UserInputService:IsKeyDown(Enum.KeyCode.S) then 
                move = move - Camera.CFrame.LookVector * speed 
            end
            if UserInputService:IsKeyDown(Enum.KeyCode.A) then 
                move = move - Camera.CFrame.RightVector * speed 
            end
            if UserInputService:IsKeyDown(Enum.KeyCode.D) then 
                move = move + Camera.CFrame.RightVector * speed 
            end
            if UserInputService:IsKeyDown(Enum.KeyCode.Space) then 
                move = move + Vector3.new(0, speed, 0) 
            end
            if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then 
                move = move - Vector3.new(0, speed, 0) 
            end
            
            -- Controles Mobile (Thumbstick + Botão de Pulo)
            local moveVector = LocalPlayer:GetMoveVector()
            if moveVector.Magnitude > 0 then
                local cameraCFrame = Camera.CFrame
                move = move + ((cameraCFrame.LookVector * moveVector.Z) + (cameraCFrame.RightVector * moveVector.X)) * speed
            end
            
            -- Detectar pulo no mobile
            local humanoid = char:FindFirstChildOfClass("Humanoid")
            if humanoid then
                if humanoid:GetState() == Enum.HumanoidStateType.Jumping then
                    move = move + Vector3.new(0, speed, 0)
                end
            end
            
            -- Aplicar movimento
            if bv and bv.Parent then bv.Velocity = move end
            if bg and bg.Parent then bg.CFrame = Camera.CFrame end
        end)
        
        Notify("Voo ativado! Use WASD/Analógico + Pular", CONFIG.COR_SUCESSO, "✈️")
    else
        -- Remover objetos de física
        if root then
            local gyro = root:FindFirstChild("FlyGyro")
            local vel = root:FindFirstChild("FlyVel")
            if gyro then gyro:Destroy() end
            if vel then vel:Destroy() end
        end
        Notify("Voo desativado", CONFIG.COR_ERRO, "✈️")
    end
end

-- Atravessar paredes
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
                    if v:IsA("BasePart") then 
                        v.CanCollide = false 
                    end
                end
            end)
        end)
        Notify("Noclip ativado", CONFIG.COR_SUCESSO, "👻")
    else
        Notify("Noclip desativado", CONFIG.COR_ERRO, "👻")
    end
end

-- Pulo infinito
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

-- God Mode (regeneração constante)
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

-- Aplicar velocidade e força de pulo continuamente
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
-- FUNÇÕES DE TROLLAGEM
-- ══════════════════════════════════════════════════════════

-- Teleportar para jogador selecionado
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

-- Arremessar jogador (Fling)
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
            
            -- Desabilitar colisões temporariamente
            for _, v in pairs(char:GetDescendants()) do
                if v:IsA("BasePart") then
                    v.CanCollide = false
                    v.Massless = true
                end
            end
            
            -- Criar força de arremesso
            local bv = Instance.new("BodyVelocity")
            bv.MaxForce = Vector3.new(9e9, 9e9, 9e9)
            bv.Parent = root
            
            -- Aplicar força repetidamente
            for i = 1, 10 do
                root.CFrame = SelectedPlayer.Character.HumanoidRootPart.CFrame
                bv.Velocity = Vector3.new(
                    math.random(-150, 150), 
                    math.random(150, 250), 
                    math.random(-150, 150)
                )
                task.wait(0.05)
            end
            
            -- Limpar e restaurar
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

-- Girar jogador
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
        
        -- Remover após 5 segundos
        task.delay(5, function()
            if spin and spin.Parent then spin:Destroy() end
        end)
        
        Notify(SelectedPlayer.Name .. " está girando!", CONFIG.COR_SUCESSO, "🌀")
    end)
end

-- Calcular distância até jogador
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
-- SISTEMA DE AIMBOT
-- ══════════════════════════════════════════════════════════

-- Encontrar jogador mais próximo do mouse dentro do FOV
local function GetClosestPlayerToMouse()
    local closestPlayer = nil
    local shortestDistance = SavedStates.AimbotFOV
    local mousePos = UserInputService:GetMouseLocation()
    
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            -- Verificar time se necessário
            if SavedStates.AimbotTeamCheck and player.Team == LocalPlayer.Team then 
                continue 
            end
            
            local char = player.Character
            local head = char:FindFirstChild("Head")
            local humanoid = char:FindFirstChildOfClass("Humanoid")
            
            if head and humanoid and humanoid.Health > 0 then
                local screenPos, onScreen = Camera:WorldToViewportPoint(head.Position)
                
                if onScreen then
                    -- Verificar visibilidade se necessário
                    if SavedStates.AimbotVisibleCheck then
                        local ray = Ray.new(
                            Camera.CFrame.Position, 
                            (head.Position - Camera.CFrame.Position).Unit * 500
                        )
                        local hit = workspace:FindPartOnRayWithIgnoreList(
                            ray, 
                            {LocalPlayer.Character, Camera}
                        )
                        if hit and not hit:IsDescendantOf(char) then 
                            continue 
                        end
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

-- Atualizar aimbot a cada frame
local function UpdateAimbot()
    if not SavedStates.AimbotEnabled then return end
    
    local target = GetClosestPlayerToMouse()
    AimbotTarget = target
    
    if target and target.Character then
        local head = target.Character:FindFirstChild("Head")
        if head then
            local targetPos = head.Position
            local smoothing = SavedStates.AimbotSmoothing / 10
            
            -- Suavizar movimento da câmera em direção ao alvo
            Camera.CFrame = Camera.CFrame:Lerp(
                CFrame.new(Camera.CFrame.Position, targetPos), 
                smoothing
            )
        end
    end
end

-- Criar círculo visual do FOV
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

-- Atualizar posição e aparência do círculo FOV
local function UpdateAimbotFOV()
    if AimbotFOVCircle then
        local mousePos = UserInputService:GetMouseLocation()
        AimbotFOVCircle.Position = mousePos
        AimbotFOVCircle.Radius = SavedStates.AimbotFOV
        AimbotFOVCircle.Visible = SavedStates.AimbotShowFOV and SavedStates.AimbotEnabled
        AimbotFOVCircle.Color = GetCurrentColor()
    end
end

-- Toggle aimbot
local function ToggleAimbot(state)
    SavedStates.AimbotEnabled = state
    
    -- Limpar conexões antigas
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
-- SISTEMA ESP (WALLHACK)
-- ══════════════════════════════════════════════════════════

-- Limpar todos os ESPs ativos
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

-- Criar ESP para um jogador
local function CreateESP(player)
    if player == LocalPlayer then return end
    if ESPObjects[player] then return end
    
    local esp = {}
    
    -- Caixa ao redor do jogador
    if SavedStates.ESPBox then
        esp.Box = Drawing.new("Square")
        esp.Box.Thickness = 2
        esp.Box.Filled = false
        esp.Box.Color = GetCurrentColor()
        esp.Box.Transparency = 1
        esp.Box.Visible = false
    end
    
    -- Linha do centro da tela até o jogador
    if SavedStates.ESPTracers then
        esp.Tracer = Drawing.new("Line")
        esp.Tracer.Thickness = 1.5
        esp.Tracer.Color = GetCurrentColor()
        esp.Tracer.Transparency = 0.8
        esp.Tracer.Visible = false
    end
    
    -- Nome do jogador
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
    
    -- Distância até o jogador
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
    
    -- Barra de vida
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

-- Atualizar ESP de todos os jogadores
local function UpdateESP()
    if not SavedStates.ESPEnabled then return end
    
    for player, esp in pairs(ESPObjects) do
        -- Verificar se jogador ainda existe
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
            -- Esconder ESP se personagem não existe
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
                
                -- Atualizar caixa
                if esp.Box and SavedStates.ESPBox then
                    esp.Box.Size = Vector2.new(width, height)
                    esp.Box.Position = Vector2.new(rootPos.X - width/2, headPos.Y)
                    esp.Box.Color = GetCurrentColor()
                    esp.Box.Visible = true
                end
                
                -- Atualizar tracer
                if esp.Tracer and SavedStates.ESPTracers then
                    esp.Tracer.From = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
                    esp.Tracer.To = Vector2.new(rootPos.X, legPos.Y)
                    esp.Tracer.Color = GetCurrentColor()
                    esp.Tracer.Visible = true
                end
                
                -- Atualizar nome
                if esp.Name and SavedStates.ESPName then
                    esp.Name.Position = Vector2.new(rootPos.X, headPos.Y - 18)
                    esp.Name.Visible = true
                end
                
                -- Atualizar distância
                if esp.Distance and SavedStates.ESPDistance and LocalPlayer.Character then
                    local myRoot = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                    if myRoot then
                        local dist = (myRoot.Position - root.Position).Magnitude
                        esp.Distance.Position = Vector2.new(rootPos.X, legPos.Y + 5)
                        esp.Distance.Text = math.floor(dist) .. "m"
                        esp.Distance.Visible = true
                    end
                end
                
                -- Atualizar barra de vida
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
                -- Esconder ESP se fora da tela
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

-- Toggle ESP
local function ToggleESP(state)
    SavedStates.ESPEnabled = state
    
    if Connections.ESP then
        Connections.ESP:Disconnect()
        Connections.ESP = nil
    end
    
    if state then
        -- Criar ESP para todos os jogadores
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

-- ══════════════════════════════════════════════════════════
-- FUNÇÕES VISUAIS
-- ══════════════════════════════════════════════════════════

-- Fullbright (iluminação máxima)
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

-- ══════════════════════════════════════════════════════════
-- CRIAÇÃO DO BOTÃO FLUTUANTE ARRASTÁVEL
-- ══════════════════════════════════════════════════════════
local function CreateFloatingButton()
    if not GUI or not GUI.Parent then return end
    
    local btn = Instance.new("TextButton")
    btn.Name = "FloatingBtn"
    btn.Size = UDim2.new(0, 55, 0, 55)
    btn.Position = UDim2.new(0.5, -27, 0.95, -65)
    btn.BackgroundColor3 = CONFIG.COR_PRINCIPAL
    btn.BorderSizePixel = 0
    btn.Text = ""
    btn.Parent = GUI
    btn.ZIndex = 9999
    
    Instance.new("UICorner", btn).CornerRadius = UDim.new(1, 0)
    
    -- Borda brilhante
    local stroke = Instance.new("UIStroke")
    stroke.Color = CONFIG.COR_TEXTO
    stroke.Thickness = 2
    stroke.Transparency = 0.7
    stroke.Parent = btn
    
    -- Logo "S"
    local icon = Instance.new("TextLabel")
    icon.Size = UDim2.new(1, 0, 1, 0)
    icon.BackgroundTransparency = 1
    icon.Text = "S"
    icon.TextColor3 = CONFIG.COR_TEXTO
    icon.TextSize = 26
    icon.Font = Enum.Font.GothamBold
    icon.Parent = btn
    
    -- Sistema de arrastar
    local dragging = false
    local dragInput, dragStart, startPos
    
    btn.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or 
           input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = btn.Position
            
            Tween(btn, {Size = UDim2.new(0, 50, 0, 50)}, 0.15)
            Tween(stroke, {Thickness = 3}, 0.15)
            
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                    Tween(btn, {Size = UDim2.new(0, 55, 0, 55)}, 0.2, Enum.EasingStyle.Back)
                    Tween(stroke, {Thickness = 2}, 0.2)
                end
            end)
        end
    end)
    
    btn.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or 
           input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)
    
    UserInputService.InputChanged:Connect(function(input)
        if dragging and dragInput and 
           (input.UserInputType == Enum.UserInputType.MouseMovement or 
            input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            btn.Position = UDim2.new(
                startPos.X.Scale, 
                startPos.X.Offset + delta.X, 
                startPos.Y.Scale, 
                startPos.Y.Offset + delta.Y
            )
        end
    end)
    
    -- Abrir/fechar menu ao clicar
    btn.MouseButton1Click:Connect(function()
        local main = GUI:FindFirstChild("MainFrame")
        if main then
            main.Visible = not main.Visible
            if main.Visible then
                main.Position = UDim2.new(0.5, -SavedStates.MenuWidth/2, 1.2, 0)
                Tween(main, {
                    Position = UDim2.new(0.5, -SavedStates.MenuWidth/2, 0.5, -SavedStates.MenuHeight/2)
                }, 0.5, Enum.EasingStyle.Back)
            end
        end
    end)
    
    -- Animação de pulso contínua
    task.spawn(function()
        while btn and btn.Parent do
            Tween(btn, {BackgroundColor3 = CONFIG.COR_HOVER}, 1.2, Enum.EasingStyle.Sine)
            Tween(stroke, {Transparency = 0.3}, 1.2, Enum.EasingStyle.Sine)
            task.wait(1.2)
            if not btn or not btn.Parent then break end
            Tween(btn, {BackgroundColor3 = CONFIG.COR_PRINCIPAL}, 1.2, Enum.EasingStyle.Sine)
            Tween(stroke, {Transparency = 0.7}, 1.2, Enum.EasingStyle.Sine)
            task.wait(1.2)
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
    GUI.Name = "SHAKA_V3_PREMIUM"
    GUI.ResetOnSpawn = false
    GUI.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    GUI.Parent = LocalPlayer:WaitForChild("PlayerGui")
    
    -- ═══════════════════════════════════════════════════════
    -- FRAME PRINCIPAL DO MENU
    -- ═══════════════════════════════════════════════════════
    local main = Instance.new("Frame")
    main.Name = "MainFrame"
    main.Size = UDim2.new(0, SavedStates.MenuWidth, 0, SavedStates.MenuHeight)
    main.Position = UDim2.new(0.5, -SavedStates.MenuWidth/2, 1.2, 0)
    main.BackgroundColor3 = CONFIG.COR_FUNDO
    main.BorderSizePixel = 0
    main.Visible = false
    main.Parent = GUI
    
    Instance.new("UICorner", main).CornerRadius = UDim.new(0, 15)
    
    -- Borda brilhante do menu
    local mainStroke = Instance.new("UIStroke")
    mainStroke.Color = CONFIG.COR_PRINCIPAL
    mainStroke.Thickness = 2
    mainStroke.Transparency = 0.5
    mainStroke.Parent = main
    
    -- ═══════════════════════════════════════════════════════
    -- HEADER COM AVATAR E INFO DO PLAYER (ÁREA DE ARRASTAR)
    -- ═══════════════════════════════════════════════════════
    local header = Instance.new("Frame")
    header.Name = "DragHeader"
    header.Size = UDim2.new(1, 0, 0, 60)
    header.BackgroundColor3 = CONFIG.COR_FUNDO_2
    header.BorderSizePixel = 0
    header.Parent = main
    
    Instance.new("UICorner", header).CornerRadius = UDim.new(0, 15)
    
    local headerBottom = Instance.new("Frame")
    headerBottom.Size = UDim2.new(1, 0, 0, 15)
    headerBottom.Position = UDim2.new(0, 0, 1, -15)
    headerBottom.BackgroundColor3 = CONFIG.COR_FUNDO_2
    headerBottom.BorderSizePixel = 0
    headerBottom.Parent = header
    
    -- SISTEMA DE ARRASTAR - APENAS NO HEADER
    local dragging = false
    local dragInput, dragStart, startPos
    
    header.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or 
           input.UserInputType == Enum.UserInputType.Touch then
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
        if input.UserInputType == Enum.UserInputType.MouseMovement or 
           input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)
    
    UserInputService.InputChanged:Connect(function(input)
        if dragging and dragInput and 
           (input.UserInputType == Enum.UserInputType.MouseMovement or 
            input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            Tween(main, {
                Position = UDim2.new(
                    startPos.X.Scale, 
                    startPos.X.Offset + delta.X, 
                    startPos.Y.Scale, 
                    startPos.Y.Offset + delta.Y
                )
            }, 0.1, Enum.EasingStyle.Linear)
        end
    end)
    
    -- Avatar do jogador
    local avatar = Instance.new("ImageLabel")
    avatar.Size = UDim2.new(0, 40, 0, 40)
    avatar.Position = UDim2.new(0, 15, 0.5, -20)
    avatar.BackgroundColor3 = CONFIG.COR_FUNDO_3
    avatar.BorderSizePixel = 0
    avatar.Image = "https://www.roblox.com/headshot-thumbnail/image?userId=" .. LocalPlayer.UserId .. "&width=150&height=150&format=png"
    avatar.Parent = header
    
    Instance.new("UICorner", avatar).CornerRadius = UDim.new(1, 0)
    
    -- Borda do avatar
    local avatarStroke = Instance.new("UIStroke")
    avatarStroke.Color = CONFIG.COR_PRINCIPAL
    avatarStroke.Thickness = 2
    avatarStroke.Parent = avatar
    
    -- Nome do jogador
    local playerName = Instance.new("TextLabel")
    playerName.Size = UDim2.new(0, 250, 0, 20)
    playerName.Position = UDim2.new(0, 65, 0, 12)
    playerName.BackgroundTransparency = 1
    playerName.Text = LocalPlayer.Name
    playerName.TextColor3 = CONFIG.COR_TEXTO
    playerName.TextSize = 16
    playerName.Font = Enum.Font.GothamBold
    playerName.TextXAlignment = Enum.TextXAlignment.Left
    playerName.Parent = header
    
    -- Título do hub
    local subtitle = Instance.new("TextLabel")
    subtitle.Size = UDim2.new(0, 250, 0, 16)
    subtitle.Position = UDim2.new(0, 65, 0, 32)
    subtitle.BackgroundTransparency = 1
    subtitle.Text = "⚡ " .. CONFIG.NOME .. " " .. CONFIG.VERSAO .. " Premium"
    subtitle.TextColor3 = CONFIG.COR_PRINCIPAL
    subtitle.TextSize = 11
    subtitle.Font = Enum.Font.Gotham
    subtitle.TextXAlignment = Enum.TextXAlignment.Left
    subtitle.Parent = header
    
    -- Botão fechar
    local closeBtn = Instance.new("TextButton")
    closeBtn.Size = UDim2.new(0, 35, 0, 35)
    closeBtn.Position = UDim2.new(1, -45, 0.5, -17)
    closeBtn.BackgroundColor3 = CONFIG.COR_ERRO
    closeBtn.Text = "×"
    closeBtn.TextColor3 = CONFIG.COR_TEXTO
    closeBtn.TextSize = 20
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.BorderSizePixel = 0
    closeBtn.Parent = header
    
    Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 10)
    
    closeBtn.MouseEnter:Connect(function() 
        Tween(closeBtn, {BackgroundColor3 = Color3.fromRGB(220, 38, 38), Size = UDim2.new(0, 37, 0, 37)}, 0.2) 
    end)
    closeBtn.MouseLeave:Connect(function() 
        Tween(closeBtn, {BackgroundColor3 = CONFIG.COR_ERRO, Size = UDim2.new(0, 35, 0, 35)}, 0.2) 
    end)
    closeBtn.MouseButton1Click:Connect(function()
        Tween(main, {Position = UDim2.new(0.5, -SavedStates.MenuWidth/2, 1.2, 0)}, 0.4)
        task.wait(0.4)
        main.Visible = false
    end)
    
    -- ═══════════════════════════════════════════════════════
    -- CONTAINER DAS TABS (ESQUERDA) - ESTILO SHARK HUB
    -- ═══════════════════════════════════════════════════════
    local tabsContainer = Instance.new("Frame")
    tabsContainer.Size = UDim2.new(0, 180, 1, -75)
    tabsContainer.Position = UDim2.new(0, 10, 0, 65)
    tabsContainer.BackgroundTransparency = 1
    tabsContainer.Parent = main
    
    local tabsList = Instance.new("UIListLayout")
    tabsList.Padding = UDim.new(0, 5)
    tabsList.Parent = tabsContainer
    
    -- ═══════════════════════════════════════════════════════
    -- CONTAINER DO CONTEÚDO (DIREITA)
    -- ═══════════════════════════════════════════════════════
    local contentContainer = Instance.new("Frame")
    contentContainer.Size = UDim2.new(1, -200, 1, -75)
    contentContainer.Position = UDim2.new(0, 195, 0, 65)
    contentContainer.BackgroundTransparency = 1
    contentContainer.Parent = main
    
    -- ═══════════════════════════════════════════════════════
    -- DEFINIÇÃO DAS TABS COM ÍCONES (LOGOS DA WEB)
    -- ═══════════════════════════════════════════════════════
    local tabs = {
        {
            Name = "Player",
            Icon = "https://cdn-icons-png.flaticon.com/512/1077/1077012.png",  -- Logo de usuário
            Emoji = "👤"
        },
        {
            Name = "Troll",
            Icon = "https://cdn-icons-png.flaticon.com/512/2584/2584606.png",  -- Logo de diabinho
            Emoji = "😈"
        },
        {
            Name = "Aimbot",
            Icon = "https://cdn-icons-png.flaticon.com/512/2583/2583780.png",  -- Logo de alvo
            Emoji = "🎯"
        },
        {
            Name = "ESP",
            Icon = "https://cdn-icons-png.flaticon.com/512/159/159604.png",  -- Logo de olho
            Emoji = "👁️"
        },
        {
            Name = "Visual",
            Icon = "https://cdn-icons-png.flaticon.com/512/2970/2970260.png",  -- Logo de estrela
            Emoji = "✨"
        },
        {
            Name = "Config",
            Icon = "https://cdn-icons-png.flaticon.com/512/3524/3524659.png",  -- Logo de engrenagem
            Emoji = "⚙️"
        }
    }
    
    local tabFrames = {}
    local currentTab = "Player"
    
    -- ═══════════════════════════════════════════════════════
    -- FUNÇÕES DE CRIAÇÃO DE ELEMENTOS UI
    -- ═══════════════════════════════════════════════════════
    
    -- Criar toggle (botão liga/desliga)
    local function CreateToggle(name, callback, parent, emoji)
        local toggle = Instance.new("Frame")
        toggle.Size = UDim2.new(1, 0, 0, 42)
        toggle.BackgroundColor3 = CONFIG.COR_FUNDO_2
        toggle.BorderSizePixel = 0
        toggle.Parent = parent
        
        Instance.new("UICorner", toggle).CornerRadius = UDim.new(0, 10)
        
        -- Efeito de borda
        local toggleStroke = Instance.new("UIStroke")
        toggleStroke.Color = CONFIG.COR_FUNDO_3
        toggleStroke.Thickness = 1
        toggleStroke.Transparency = 0.5
        toggleStroke.Parent = toggle
        
        -- Emoji/Ícone
        local iconLabel = Instance.new("TextLabel")
        iconLabel.Size = UDim2.new(0, 28, 0, 28)
        iconLabel.Position = UDim2.new(0, 12, 0.5, -14)
        iconLabel.BackgroundTransparency = 1
        iconLabel.Text = emoji or "⚡"
        iconLabel.TextColor3 = CONFIG.COR_TEXTO_SEC
        iconLabel.TextSize = 18
        iconLabel.Font = Enum.Font.GothamBold
        iconLabel.Parent = toggle
        
        -- Label do nome
        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(1, -100, 1, 0)
        label.Position = UDim2.new(0, 48, 0, 0)
        label.BackgroundTransparency = 1
        label.Text = name
        label.TextColor3 = CONFIG.COR_TEXTO
        label.TextSize = 13
        label.Font = Enum.Font.Gotham
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.Parent = toggle
        
        -- Switch (botão deslizante)
        local switch = Instance.new("Frame")
        switch.Size = UDim2.new(0, 48, 0, 24)
        switch.Position = UDim2.new(1, -58, 0.5, -12)
        switch.BackgroundColor3 = CONFIG.COR_FUNDO_3
        switch.BorderSizePixel = 0
        switch.Parent = toggle
        
        Instance.new("UICorner", switch).CornerRadius = UDim.new(1, 0)
        
        -- Knob (bolinha do switch)
        local knob = Instance.new("Frame")
        knob.Size = UDim2.new(0, 20, 0, 20)
        knob.Position = UDim2.new(0, 2, 0, 2)
        knob.BackgroundColor3 = CONFIG.COR_TEXTO
        knob.BorderSizePixel = 0
        knob.Parent = switch
        
        Instance.new("UICorner", knob).CornerRadius = UDim.new(1, 0)
        
        local state = false
        
        -- Botão invisível para capturar cliques
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(1, 0, 1, 0)
        btn.BackgroundTransparency = 1
        btn.Text = ""
        btn.Parent = toggle
        
        -- Animações de hover
        btn.MouseEnter:Connect(function() 
            Tween(toggle, {BackgroundColor3 = CONFIG.COR_FUNDO_3}, 0.2)
            Tween(toggleStroke, {Transparency = 0.2}, 0.2)
        end)
        btn.MouseLeave:Connect(function() 
            Tween(toggle, {BackgroundColor3 = CONFIG.COR_FUNDO_2}, 0.2)
            Tween(toggleStroke, {Transparency = 0.5}, 0.2)
        end)
        
        -- Lógica do clique
        btn.MouseButton1Click:Connect(function()
            state = not state
            if state then
                Tween(switch, {BackgroundColor3 = CONFIG.COR_PRINCIPAL}, 0.25)
                Tween(knob, {Position = UDim2.new(1, -22, 0, 2)}, 0.25, Enum.EasingStyle.Back)
                Tween(iconLabel, {TextColor3 = CONFIG.COR_PRINCIPAL}, 0.25)
                Tween(toggleStroke, {Color = CONFIG.COR_PRINCIPAL}, 0.25)
            else
                Tween(switch, {BackgroundColor3 = CONFIG.COR_FUNDO_3}, 0.25)
                Tween(knob, {Position = UDim2.new(0, 2, 0, 2)}, 0.25, Enum.EasingStyle.Back)
                Tween(iconLabel, {TextColor3 = CONFIG.COR_TEXTO_SEC}, 0.25)
                Tween(toggleStroke, {Color = CONFIG.COR_FUNDO_3}, 0.25)
            end
            callback(state)
        end)
        
        return toggle
    end
    
    -- Criar slider (controle deslizante)
    local function CreateSlider(name, min, max, default, callback, parent, emoji)
        local slider = Instance.new("Frame")
        slider.Size = UDim2.new(1, 0, 0, 56)
        slider.BackgroundColor3 = CONFIG.COR_FUNDO_2
        slider.BorderSizePixel = 0
        slider.Parent = parent
        
        Instance.new("UICorner", slider).CornerRadius = UDim.new(0, 10)
        
        -- Borda
        local sliderStroke = Instance.new("UIStroke")
        sliderStroke.Color = CONFIG.COR_FUNDO_3
        sliderStroke.Thickness = 1
        sliderStroke.Transparency = 0.5
        sliderStroke.Parent = slider
        
        -- Ícone
        local iconLabel = Instance.new("TextLabel")
        iconLabel.Size = UDim2.new(0, 26, 0, 26)
        iconLabel.Position = UDim2.new(0, 12, 0, 8)
        iconLabel.BackgroundTransparency = 1
        iconLabel.Text = emoji or "📊"
        iconLabel.TextColor3 = CONFIG.COR_TEXTO_SEC
        iconLabel.TextSize = 16
        iconLabel.Font = Enum.Font.GothamBold
        iconLabel.Parent = slider
        
        -- Label do nome
        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(1, -110, 0, 22)
        label.Position = UDim2.new(0, 46, 0, 8)
        label.BackgroundTransparency = 1
        label.Text = name
        label.TextColor3 = CONFIG.COR_TEXTO
        label.TextSize = 12
        label.Font = Enum.Font.Gotham
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.Parent = slider
        
        -- Label do valor
        local valueLabel = Instance.new("TextLabel")
        valueLabel.Size = UDim2.new(0, 70, 0, 22)
        valueLabel.Position = UDim2.new(1, -80, 0, 8)
        valueLabel.BackgroundTransparency = 1
        valueLabel.Text = tostring(default)
        valueLabel.TextColor3 = CONFIG.COR_PRINCIPAL
        valueLabel.TextSize = 12
        valueLabel.Font = Enum.Font.GothamBold
        valueLabel.TextXAlignment = Enum.TextXAlignment.Right
        valueLabel.Parent = slider
        
        -- Track (trilha do slider)
        local track = Instance.new("Frame")
        track.Size = UDim2.new(1, -24, 0, 5)
        track.Position = UDim2.new(0, 12, 0, 41)
        track.BackgroundColor3 = CONFIG.COR_FUNDO_3
        track.BorderSizePixel = 0
        track.Parent = slider
        
        Instance.new("UICorner", track).CornerRadius = UDim.new(1, 0)
        
        -- Fill (parte preenchida)
        local fill = Instance.new("Frame")
        fill.Size = UDim2.new((default - min) / (max - min), 0, 1, 0)
        fill.BackgroundColor3 = CONFIG.COR_PRINCIPAL
        fill.BorderSizePixel = 0
        fill.Parent = track
        
        Instance.new("UICorner", fill).CornerRadius = UDim.new(1, 0)
        
        -- Knob (bolinha do slider)
        local knob = Instance.new("Frame")
        knob.Size = UDim2.new(0, 14, 0, 14)
        knob.Position = UDim2.new((default - min) / (max - min), -7, 0.5, -7)
        knob.BackgroundColor3 = CONFIG.COR_TEXTO
        knob.BorderSizePixel = 0
        knob.Parent = track
        
        Instance.new("UICorner", knob).CornerRadius = UDim.new(1, 0)
        
        -- Borda do knob
        local knobStroke = Instance.new("UIStroke")
        knobStroke.Color = CONFIG.COR_PRINCIPAL
        knobStroke.Thickness = 2
        knobStroke.Parent = knob
        
        local dragging = false
        
        -- Função para atualizar o slider
        local function update(input)
            local pos = math.clamp((input.Position.X - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
            local value = math.floor(min + (max - min) * pos)
            
            fill.Size = UDim2.new(pos, 0, 1, 0)
            knob.Position = UDim2.new(pos, -7, 0.5, -7)
            valueLabel.Text = tostring(value)
            callback(value)
        end
        
        knob.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                dragging = true
                Tween(knob, {Size = UDim2.new(0, 18, 0, 18), Position = UDim2.new(knob.Position.X.Scale, -9, 0.5, -9)}, 0.15)
                Tween(sliderStroke, {Color = CONFIG.COR_PRINCIPAL, Transparency = 0.2}, 0.15)
            end
        end)
        
        UserInputService.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                dragging = false
                Tween(knob, {Size = UDim2.new(0, 14, 0, 14), Position = UDim2.new(knob.Position.X.Scale, -7, 0.5, -7)}, 0.15)
                Tween(sliderStroke, {Color = CONFIG.COR_FUNDO_3, Transparency = 0.5}, 0.15)
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
    
    -- Criar botão
    local function CreateButton(text, callback, parent, emoji, color)
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(1, 0, 0, 38)
        btn.BackgroundColor3 = color or CONFIG.COR_PRINCIPAL
        btn.Text = ""
        btn.BorderSizePixel = 0
        btn.Parent = parent
        
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 10)
        
        -- Borda
        local btnStroke = Instance.new("UIStroke")
        btnStroke.Color = CONFIG.COR_TEXTO
        btnStroke.Thickness = 0
        btnStroke.Transparency = 0.8
        btnStroke.Parent = btn
        
        -- Ícone
        local iconLabel = Instance.new("TextLabel")
        iconLabel.Size = UDim2.new(0, 28, 0, 28)
        iconLabel.Position = UDim2.new(0, 12, 0.5, -14)
        iconLabel.BackgroundTransparency = 1
        iconLabel.Text = emoji or "⚡"
        iconLabel.TextColor3 = CONFIG.COR_TEXTO
        iconLabel.TextSize = 18
        iconLabel.Font = Enum.Font.GothamBold
        iconLabel.Parent = btn
        
        -- Label
        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(1, -50, 1, 0)
        label.Position = UDim2.new(0, 46, 0, 0)
        label.BackgroundTransparency = 1
        label.Text = text
        label.TextColor3 = CONFIG.COR_TEXTO
        label.TextSize = 13
        label.Font = Enum.Font.GothamBold
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.Parent = btn
        
        btn.MouseEnter:Connect(function()
            local hoverColor = color or CONFIG.COR_HOVER
            Tween(btn, {BackgroundColor3 = Color3.fromRGB(
                math.min(hoverColor.R * 255 + 20, 255), 
                math.min(hoverColor.G * 255 + 20, 255), 
                math.min(hoverColor.B * 255 + 20, 255)
            )}, 0.2)
            Tween(btnStroke, {Thickness = 2}, 0.2)
        end)
        btn.MouseLeave:Connect(function()
            Tween(btn, {BackgroundColor3 = color or CONFIG.COR_PRINCIPAL}, 0.2)
            Tween(btnStroke, {Thickness = 0}, 0.2)
        end)
        
        btn.MouseButton1Click:Connect(function()
            Tween(btn, {Size = UDim2.new(1, 0, 0, 35)}, 0.1)
            Tween(iconLabel, {TextSize = 22}, 0.1)
            task.wait(0.1)
            Tween(btn, {Size = UDim2.new(1, 0, 0, 38)}, 0.15, Enum.EasingStyle.Back)
            Tween(iconLabel, {TextSize = 18}, 0.15)
            callback()
        end)
        
        return btn
    end
    
    -- Criar seção (título de divisão)
    local function CreateSection(text, parent)
        local section = Instance.new("Frame")
        section.Size = UDim2.new(1, 0, 0, 32)
        section.BackgroundTransparency = 1
        section.Parent = parent
        
        local line1 = Instance.new("Frame")
        line1.Size = UDim2.new(0.3, 0, 0, 2)
        line1.Position = UDim2.new(0, 0, 0.5, -1)
        line1.BackgroundColor3 = CONFIG.COR_PRINCIPAL
        line1.BorderSizePixel = 0
        line1.Parent = section
        
        Instance.new("UICorner", line1).CornerRadius = UDim.new(1, 0)
        
        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(0.4, 0, 1, 0)
        label.Position = UDim2.new(0.3, 0, 0, 0)
        label.BackgroundTransparency = 1
        label.Text = text
        label.TextColor3 = CONFIG.COR_PRINCIPAL
        label.TextSize = 12
        label.Font = Enum.Font.GothamBold
        label.Parent = section
        
        local line2 = Instance.new("Frame")
        line2.Size = UDim2.new(0.3, 0, 0, 2)
        line2.Position = UDim2.new(0.7, 0, 0.5, -1)
        line2.BackgroundColor3 = CONFIG.COR_PRINCIPAL
        line2.BorderSizePixel = 0
        line2.Parent = section
        
        Instance.new("UICorner", line2).CornerRadius = UDim.new(1, 0)
        
        return section
    end
    
    -- ═══════════════════════════════════════════════════════
    -- LISTA DE JOGADORES (APENAS ABA TROLL)
    -- ═══════════════════════════════════════════════════════
    local playerList = Instance.new("Frame")
    playerList.Size = UDim2.new(0, 170, 1, -75)
    playerList.Position = UDim2.new(0, 195, 0, 65)
    playerList.BackgroundColor3 = CONFIG.COR_FUNDO_2
    playerList.BorderSizePixel = 0
    playerList.Visible = false
    playerList.ZIndex = 2
    playerList.Parent = main
    
    Instance.new("UICorner", playerList).CornerRadius = UDim.new(0, 10)
    
    -- Borda
    local plStroke = Instance.new("UIStroke")
    plStroke.Color = CONFIG.COR_PRINCIPAL
    plStroke.Thickness = 1
    plStroke.Transparency = 0.5
    plStroke.Parent = playerList
    
    -- Título
    local plTitle = Instance.new("TextLabel")
    plTitle.Size = UDim2.new(1, 0, 0, 35)
    plTitle.BackgroundColor3 = CONFIG.COR_PRINCIPAL
    plTitle.Text = "👥 JOGADORES"
    plTitle.TextColor3 = CONFIG.COR_TEXTO
    plTitle.TextSize = 12
    plTitle.Font = Enum.Font.GothamBold
    plTitle.BorderSizePixel = 0
    plTitle.Parent = playerList
    
    Instance.new("UICorner", plTitle).CornerRadius = UDim.new(0, 10)
    
    local plBottom = Instance.new("Frame")
    plBottom.Size = UDim2.new(1, 0, 0, 10)
    plBottom.Position = UDim2.new(0, 0, 1, -10)
    plBottom.BackgroundColor3 = CONFIG.COR_PRINCIPAL
    plBottom.BorderSizePixel = 0
    plBottom.Parent = plTitle
    
    -- Label do jogador selecionado
    local selectedLabel = Instance.new("TextLabel")
    selectedLabel.Size = UDim2.new(1, -12, 0, 28)
    selectedLabel.Position = UDim2.new(0, 6, 0, 41)
    selectedLabel.BackgroundColor3 = CONFIG.COR_FUNDO
    selectedLabel.Text = "Nenhum selecionado"
    selectedLabel.TextColor3 = CONFIG.COR_TEXTO_SEC
    selectedLabel.TextSize = 10
    selectedLabel.Font = Enum.Font.Gotham
    selectedLabel.BorderSizePixel = 0
    selectedLabel.Parent = playerList
    
    Instance.new("UICorner", selectedLabel).CornerRadius = UDim.new(0, 8)
    
    -- Scroll com jogadores
    local playerScroll = Instance.new("ScrollingFrame")
    playerScroll.Size = UDim2.new(1, -12, 1, -80)
    playerScroll.Position = UDim2.new(0, 6, 0, 74)
    playerScroll.BackgroundTransparency = 1
    playerScroll.BorderSizePixel = 0
    playerScroll.ScrollBarThickness = 4
    playerScroll.ScrollBarImageColor3 = CONFIG.COR_PRINCIPAL
    playerScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    playerScroll.Parent = playerList
    
    -- Função para atualizar lista de jogadores
    local function UpdatePlayerList()
        for _, child in pairs(playerScroll:GetChildren()) do
            if child:IsA("TextButton") or child:IsA("UIListLayout") then child:Destroy() end
        end
        
        local layout = Instance.new("UIListLayout")
        layout.Padding = UDim.new(0, 5)
        layout.Parent = playerScroll
        
        layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            playerScroll.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 6)
        end)
        
        -- Ordenar jogadores por distância
        local players = {}
        for _, p in pairs(Players:GetPlayers()) do
            if p ~= LocalPlayer then
                table.insert(players, {Player = p, Distance = GetPlayerDistance(p)})
            end
        end
        
        table.sort(players, function(a, b) return a.Distance < b.Distance end)
        
        -- Criar botão para cada jogador
        for _, data in ipairs(players) do
            local p = data.Player
            local d = data.Distance
            
            local pBtn = Instance.new("TextButton")
            pBtn.Size = UDim2.new(1, -6, 0, 32)
            pBtn.BackgroundColor3 = CONFIG.COR_FUNDO
            pBtn.Text = ""
            pBtn.BorderSizePixel = 0
            pBtn.Parent = playerScroll
            
            Instance.new("UICorner", pBtn).CornerRadius = UDim.new(0, 8)
            
            -- Nome do jogador
            local pName = Instance.new("TextLabel")
            pName.Size = UDim2.new(1, -40, 1, 0)
            pName.Position = UDim2.new(0, 8, 0, 0)
            pName.BackgroundTransparency = 1
            pName.Text = p.Name
            pName.TextColor3 = CONFIG.COR_TEXTO
            pName.TextSize = 11
            pName.Font = Enum.Font.Gotham
            pName.TextXAlignment = Enum.TextXAlignment.Left
            pName.TextTruncate = Enum.TextTruncate.AtEnd
            pName.Parent = pBtn
            
            -- Distância
            local pDist = Instance.new("TextLabel")
            pDist.Size = UDim2.new(0, 35, 1, 0)
            pDist.Position = UDim2.new(1, -38, 0, 0)
            pDist.BackgroundTransparency = 1
            pDist.Text = d == math.huge and "?" or math.floor(d) .. "m"
            pDist.TextColor3 = CONFIG.COR_TEXTO_SEC
            pDist.TextSize = 9
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
    
    -- Atualizar lista a cada 2 segundos
    task.spawn(function()
        while GUI and GUI.Parent do
            if playerList.Visible then UpdatePlayerList() end
            task.wait(2)
        end
    end)
    
    -- ═══════════════════════════════════════════════════════
    -- CRIAR BOTÕES DAS TABS - ESTILO SHARK HUB
    -- ═══════════════════════════════════════════════════════
    for i, tab in ipairs(tabs) do
        local tabBtn = Instance.new("TextButton")
        tabBtn.Size = UDim2.new(1, 0, 0, 42)
        tabBtn.BackgroundColor3 = CONFIG.COR_FUNDO_2
        tabBtn.Text = ""
        tabBtn.BorderSizePixel = 0
        tabBtn.Parent = tabsContainer
        
        Instance.new("UICorner", tabBtn).CornerRadius = UDim.new(0, 10)
        
        -- Borda da tab
        local tabStroke = Instance.new("UIStroke")
        tabStroke.Color = CONFIG.COR_FUNDO_3
        tabStroke.Thickness = 1
        tabStroke.Transparency = 0.5
        tabStroke.Parent = tabBtn
        
        -- Container para o ícone (imagem pequena)
        local iconContainer = Instance.new("Frame")
        iconContainer.Size = UDim2.new(0, 28, 0, 28)
        iconContainer.Position = UDim2.new(0, 10, 0.5, -14)
        iconContainer.BackgroundTransparency = 1
        iconContainer.Parent = tabBtn
        
        -- Ícone (ImageLabel com fallback para emoji)
        local tabIcon = Instance.new("ImageLabel")
        tabIcon.Size = UDim2.new(1, 0, 1, 0)
        tabIcon.BackgroundTransparency = 1
        tabIcon.Image = tab.Icon
        tabIcon.ImageColor3 = CONFIG.COR_TEXTO_SEC
        tabIcon.ScaleType = Enum.ScaleType.Fit
        tabIcon.Parent = iconContainer
        
        -- Fallback: emoji se imagem não carregar
        local emojiLabel = Instance.new("TextLabel")
        emojiLabel.Size = UDim2.new(1, 0, 1, 0)
        emojiLabel.BackgroundTransparency = 1
        emojiLabel.Text = tab.Emoji
        emojiLabel.TextColor3 = CONFIG.COR_TEXTO_SEC
        emojiLabel.TextSize = 18
        emojiLabel.Font = Enum.Font.GothamBold
        emojiLabel.Visible = false
        emojiLabel.Parent = iconContainer
        
        -- Verificar se imagem carregou (usar emoji como fallback)
        task.spawn(function()
            task.wait(1)
            if tabIcon.Image == tab.Icon and tabIcon.ImageRectSize == Vector2.new(0, 0) then
                tabIcon.Visible = false
                emojiLabel.Visible = true
            end
        end)
        
        -- Nome da tab ao lado do ícone
        local tabName = Instance.new("TextLabel")
        tabName.Size = UDim2.new(1, -48, 1, 0)
        tabName.Position = UDim2.new(0, 45, 0, 0)
        tabName.BackgroundTransparency = 1
        tabName.Text = tab.Name
        tabName.TextColor3 = CONFIG.COR_TEXTO_SEC
        tabName.TextSize = 13
        tabName.Font = Enum.Font.Gotham
        tabName.TextXAlignment = Enum.TextXAlignment.Left
        tabName.Parent = tabBtn
        
        -- Frame de conteúdo da tab
        local tabFrame = Instance.new("ScrollingFrame")
        tabFrame.Size = UDim2.new(1, 0, 1, 0)
        tabFrame.BackgroundTransparency = 1
        tabFrame.BorderSizePixel = 0
        tabFrame.ScrollBarThickness = 4
        tabFrame.ScrollBarImageColor3 = CONFIG.COR_PRINCIPAL
        tabFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
        tabFrame.Visible = false
        tabFrame.Parent = contentContainer
        
        local layout = Instance.new("UIListLayout")
        layout.Padding = UDim.new(0, 8)
        layout.Parent = tabFrame
        
        layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            tabFrame.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 8)
        end)
        
        tabFrames[tab.Name] = tabFrame
        
        -- Lógica de clique na tab
        tabBtn.MouseButton1Click:Connect(function()
            currentTab = tab.Name
            
            -- Mostrar lista de jogadores apenas na aba Troll
            if tab.Name == "Troll" then
                playerList.Visible = true
                contentContainer.Size = UDim2.new(1, -380, 1, -75)
                contentContainer.Position = UDim2.new(0, 370, 0, 65)
            else
                playerList.Visible = false
                contentContainer.Size = UDim2.new(1, -200, 1, -75)
                contentContainer.Position = UDim2.new(0, 195, 0, 65)
            end
            
            -- Resetar todas as tabs
            for name, frame in pairs(tabFrames) do
                frame.Visible = (name == tab.Name)
            end
            
            for _, btn in pairs(tabsContainer:GetChildren()) do
                if btn:IsA("TextButton") then
                    Tween(btn, {BackgroundColor3 = CONFIG.COR_FUNDO_2}, 0.2)
                    local stroke = btn:FindFirstChild("UIStroke")
                    if stroke then Tween(stroke, {Color = CONFIG.COR_FUNDO_3}, 0.2) end
                    
                    -- Resetar cores dos ícones
                    for _, child in pairs(btn:GetChildren()) do
                        if child:IsA("Frame") then
                            for _, subchild in pairs(child:GetChildren()) do
                                if subchild:IsA("ImageLabel") then
                                    Tween(subchild, {ImageColor3 = CONFIG.COR_TEXTO_SEC}, 0.2)
                                elseif subchild:IsA("TextLabel") then
                                    Tween(subchild, {TextColor3 = CONFIG.COR_TEXTO_SEC}, 0.2)
                                end
                            end
                        elseif child:IsA("TextLabel") then
                            Tween(child, {TextColor3 = CONFIG.COR_TEXTO_SEC}, 0.2)
                        end
                    end
                end
            end
            
            -- Ativar tab clicada
            Tween(tabBtn, {BackgroundColor3 = CONFIG.COR_PRINCIPAL}, 0.2)
            Tween(tabStroke, {Color = CONFIG.COR_TEXTO}, 0.2)
            Tween(tabIcon, {ImageColor3 = CONFIG.COR_TEXTO}, 0.2)
            Tween(emojiLabel, {TextColor3 = CONFIG.COR_TEXTO}, 0.2)
            Tween(tabName, {TextColor3 = CONFIG.COR_TEXTO}, 0.2)
        end)
        
        -- Animações de hover
        tabBtn.MouseEnter:Connect(function()
            if currentTab ~= tab.Name then
                Tween(tabBtn, {BackgroundColor3 = CONFIG.COR_FUNDO_3}, 0.2)
            end
        end)
        
        tabBtn.MouseLeave:Connect(function()
            if currentTab ~= tab.Name then
                Tween(tabBtn, {BackgroundColor3 = CONFIG.COR_FUNDO_2}, 0.2)
            end
        end)
        
        -- Primeira tab ativa por padrão
        if i == 1 then
            tabBtn.BackgroundColor3 = CONFIG.COR_PRINCIPAL
            tabStroke.Color = CONFIG.COR_TEXTO
            tabIcon.ImageColor3 = CONFIG.COR_TEXTO
            emojiLabel.TextColor3 = CONFIG.COR_TEXTO
            tabName.TextColor3 = CONFIG.COR_TEXTO
            tabFrame.Visible = true
        end
    end
    
    task.wait(0.1)
    
    -- ═══════════════════════════════════════════════════════
    -- CONTEÚDO DAS ABAS
    -- ═══════════════════════════════════════════════════════
    
    -- ══════════ ABA PLAYER ══════════
    CreateSection("MOVIMENTO", tabFrames["Player"])
    CreateToggle("Voo", ToggleFly, tabFrames["Player"], "✈️")
    CreateSlider("Velocidade Voo", 10, 300, SavedStates.FlySpeed, function(v) 
        SavedStates.FlySpeed = v 
    end, tabFrames["Player"], "⚡")
    CreateToggle("Noclip", ToggleNoclip, tabFrames["Player"], "👻")
    CreateToggle("Pulo Infinito", ToggleInfJump, tabFrames["Player"], "🦘")
    
    CreateSection("VELOCIDADE", tabFrames["Player"])
    CreateSlider("Walk Speed", 16, 400, SavedStates.WalkSpeed, function(v) 
        SavedStates.WalkSpeed = v 
    end, tabFrames["Player"], "🏃")
    CreateSlider("Jump Power", 50, 600, SavedStates.JumpPower, function(v) 
        SavedStates.JumpPower = v 
    end, tabFrames["Player"], "⬆️")
    
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
    
    -- ══════════ ABA TROLL ══════════
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
    
    -- ══════════ ABA AIMBOT ══════════
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
    
    -- ══════════ ABA ESP ══════════
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
    
    -- ══════════ ABA VISUAL ══════════
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
    
    -- ══════════ ABA CONFIG ══════════
    CreateSection("TAMANHO DO MENU", tabFrames["Config"])
    CreateSlider("Largura", 600, 900, SavedStates.MenuWidth, function(v)
        SavedStates.MenuWidth = v
        main.Size = UDim2.new(0, v, 0, SavedStates.MenuHeight)
        main.Position = UDim2.new(0.5, -v/2, 0.5, -SavedStates.MenuHeight/2)
    end, tabFrames["Config"], "↔️")
    
    CreateSlider("Altura", 400, 600, SavedStates.MenuHeight, function(v)
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
                
                -- Atualizar elementos da UI
                pcall(function()
                    if mainStroke then mainStroke.Color = color end
                    if avatarStroke then avatarStroke.Color = color end
                    if subtitle then subtitle.TextColor3 = color end
                    if plTitle then plTitle.BackgroundColor3 = color end
                    if plStroke then plStroke.Color = color end
                end)
            end)
            Notify("Modo Rainbow ativado! 🌈", CONFIG.COR_SUCESSO, "🌈")
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
        SavedStates.MenuWidth = 700
        SavedStates.MenuHeight = 450
        main.Size = UDim2.new(0, 700, 0, 450)
        main.Position = UDim2.new(0.5, -350, 0.5, -225)
        Notify("Configurações resetadas!", CONFIG.COR_SUCESSO, "🔄")
    end, tabFrames["Config"], "🔄", CONFIG.COR_ERRO)
    
    -- Card de créditos
    local credits = Instance.new("Frame")
    credits.Size = UDim2.new(1, 0, 0, 80)
    credits.BackgroundColor3 = CONFIG.COR_FUNDO_2
    credits.BorderSizePixel = 0
    credits.Parent = tabFrames["Config"]
    
    Instance.new("UICorner", credits).CornerRadius = UDim.new(0, 10)
    
    local creditStroke = Instance.new("UIStroke")
    creditStroke.Color = CONFIG.COR_PRINCIPAL
    creditStroke.Thickness = 1
    creditStroke.Transparency = 0.5
    creditStroke.Parent = credits
    
    local creditIcon = Instance.new("TextLabel")
    creditIcon.Size = UDim2.new(0, 45, 0, 45)
    creditIcon.Position = UDim2.new(0.5, -22, 0, 8)
    creditIcon.BackgroundTransparency = 1
    creditIcon.Text = "👑"
    creditIcon.TextSize = 36
    creditIcon.Font = Enum.Font.GothamBold
    creditIcon.Parent = credits
    
    local creditText = Instance.new("TextLabel")
    creditText.Size = UDim2.new(1, 0, 0, 24)
    creditText.Position = UDim2.new(0, 0, 0, 56)
    creditText.BackgroundTransparency = 1
    creditText.Text = "Desenvolvido por 2M • 2025"
    creditText.TextColor3 = CONFIG.COR_TEXTO_SEC
    creditText.TextSize = 11
    creditText.Font = Enum.Font.Gotham
    creditText.Parent = credits
    
    -- Animação do ícone de créditos
    task.spawn(function()
        while credits and credits.Parent do
            Tween(creditIcon, {Rotation = 15}, 1, Enum.EasingStyle.Sine)
            task.wait(1)
            if not credits or not credits.Parent then break end
            Tween(creditIcon, {Rotation = -15}, 1, Enum.EasingStyle.Sine)
            task.wait(1)
            if not credits or not credits.Parent then break end
            Tween(creditIcon, {Rotation = 0}, 1, Enum.EasingStyle.Sine)
            task.wait(1)
        end
    end)
    
    -- Criar botão flutuante
    CreateFloatingButton()
    
    -- Notificação de carregamento
    Notify("SHAKA v3.0 Premium carregado com sucesso!", CONFIG.COR_SUCESSO, "🚀")
    
    -- Animação de borda do menu principal
    task.spawn(function()
        while main and main.Parent do
            Tween(mainStroke, {Transparency = 0.2}, 2, Enum.EasingStyle.Sine)
            task.wait(2)
            if not main or not main.Parent then break end
            Tween(mainStroke, {Transparency = 0.5}, 2, Enum.EasingStyle.Sine)
            task.wait(2)
        end
    end)
end

-- ══════════════════════════════════════════════════════════
-- INICIALIZAÇÃO DO HUB
-- ══════════════════════════════════════════════════════════
CreateGUI()

-- ══════════════════════════════════════════════════════════
-- CONTROLES DE TECLADO
-- ══════════════════════════════════════════════════════════
UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    
    -- INSERT para abrir/fechar menu
    if input.KeyCode == Enum.KeyCode.Insert then
        if GUI then
            local main = GUI:FindFirstChild("MainFrame")
            if main then
                main.Visible = not main.Visible
                if main.Visible then
                    main.Position = UDim2.new(0.5, -SavedStates.MenuWidth/2, 1.2, 0)
                    Tween(main, {
                        Position = UDim2.new(0.5, -SavedStates.MenuWidth/2, 0.5, -SavedStates.MenuHeight/2)
                    }, 0.5, Enum.EasingStyle.Back)
                end
            end
        end
    end
end)

-- ══════════════════════════════════════════════════════════
-- EVENTOS DE JOGADORES
-- ══════════════════════════════════════════════════════════

-- Adicionar ESP quando jogador entra
Players.PlayerAdded:Connect(function(player)
    if SavedStates.ESPEnabled then
        task.wait(1)
        CreateESP(player)
    end
end)

-- Remover ESP quando jogador sai
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

-- ══════════════════════════════════════════════════════════
-- LOGS NO CONSOLE
-- ══════════════════════════════════════════════════════════
print("╔════════════════════════════════════════════════╗")
print("║     SHAKA HUB v3.0 PREMIUM - CARREGADO!       ║")
print("║                                                ║")
print("║  ⚡ Pressione INSERT para abrir o menu        ║")
print("║  🎮 Arraste pela BARRA SUPERIOR apenas        ║")
print("║  🌈 Ative Rainbow Mode nas configurações      ║")
print("║  🖼️  Tabs com ícones estilo Shark Hub         ║")
print("║                                                ║")
print("║  👑 Desenvolvido por 2M | 2025                ║")
print("╚════════════════════════════════════════════════╝")
print("")
print("✅ Funcionalidades carregadas:")
print("   • Sistema de Voo (PC + Mobile)")
print("   • Noclip e Pulo Infinito")
print("   • ESP completo com todas opções")
print("   • Aimbot com FOV Circle")
print("   • Sistema de Trollagem")
print("   • Fullbright e Controles Visuais")
print("   • Menu arrastável APENAS pela barra superior")
print("   • Tabs laterais com ícones + texto")
print("")
print("🎨 Tema: #A903FC (Roxo Premium) + #000000 (Preto)")
print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
