-- SHAKA Hub Premium v5.0 - Menu Otimizado e Funcional
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
    VERSAO = "v5.0",
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
-- VARIÁVEIS
-- ════════════════════════════════════════════════════════════
local GUI = nil
local Connections = {}
local SelectedPlayer = nil
local FlySpeed = 50
local WalkSpeed = 16
local JumpPower = 50
local FlyConnection = nil
local NoclipConnection = nil
local InfJumpConnection = nil

-- ════════════════════════════════════════════════════════════
-- FUNÇÕES AUXILIARES
-- ════════════════════════════════════════════════════════════
local function Log(msg)
    print("[SHAKA] " .. msg)
end

local function Tween(obj, props, time)
    TweenService:Create(obj, TweenInfo.new(time or 0.2, Enum.EasingStyle.Quad), props):Play()
end

local function Notify(text, color)
    task.spawn(function()
        if not GUI then return end
        
        local notif = Instance.new("Frame")
        notif.Size = UDim2.new(0, 250, 0, 50)
        notif.Position = UDim2.new(1, -260, 1, 10)
        notif.BackgroundColor3 = CONFIG.COR_FUNDO_2
        notif.BorderSizePixel = 0
        notif.Parent = GUI
        
        Instance.new("UICorner", notif).CornerRadius = UDim.new(0, 8)
        Instance.new("UIStroke", notif).Color = color or CONFIG.COR_ROXO
        
        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(1, -10, 1, 0)
        label.Position = UDim2.new(0, 5, 0, 0)
        label.BackgroundTransparency = 1
        label.Text = text
        label.TextColor3 = CONFIG.COR_TEXTO
        label.TextSize = 13
        label.Font = Enum.Font.GothamBold
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.Parent = notif
        
        Tween(notif, {Position = UDim2.new(1, -260, 1, -60)}, 0.3)
        task.wait(2.5)
        Tween(notif, {Position = UDim2.new(1, 10, 1, -60)}, 0.3)
        task.wait(0.3)
        notif:Destroy()
    end)
end

-- ════════════════════════════════════════════════════════════
-- FUNÇÕES DO PLAYER
-- ════════════════════════════════════════════════════════════
local function ToggleFly(state)
    if FlyConnection then
        FlyConnection:Disconnect()
        FlyConnection = nil
    end
    
    local char = LocalPlayer.Character
    if not char then return end
    
    if state then
        local root = char:FindFirstChild("HumanoidRootPart")
        if not root then return end
        
        local bv = Instance.new("BodyVelocity")
        bv.Name = "FlyVelocity"
        bv.MaxForce = Vector3.new(9e9, 9e9, 9e9)
        bv.Velocity = Vector3.new(0, 0, 0)
        bv.Parent = root
        
        FlyConnection = RunService.Heartbeat:Connect(function()
            if not char or not root or not root.Parent then
                if FlyConnection then FlyConnection:Disconnect() end
                return
            end
            
            local vel = Vector3.new(0, 0, 0)
            
            if UserInputService:IsKeyDown(Enum.KeyCode.W) then
                vel = vel + Camera.CFrame.LookVector
            end
            if UserInputService:IsKeyDown(Enum.KeyCode.S) then
                vel = vel - Camera.CFrame.LookVector
            end
            if UserInputService:IsKeyDown(Enum.KeyCode.A) then
                vel = vel - Camera.CFrame.RightVector
            end
            if UserInputService:IsKeyDown(Enum.KeyCode.D) then
                vel = vel + Camera.CFrame.RightVector
            end
            if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
                vel = vel + Vector3.new(0, 1, 0)
            end
            if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then
                vel = vel - Vector3.new(0, 1, 0)
            end
            
            bv.Velocity = vel * FlySpeed
        end)
        
        Notify("Fly ativado! [WASD/Space/Shift]", CONFIG.COR_SUCESSO)
    else
        if char:FindFirstChild("HumanoidRootPart") then
            local bv = char.HumanoidRootPart:FindFirstChild("FlyVelocity")
            if bv then bv:Destroy() end
        end
        Notify("Fly desativado", CONFIG.COR_ERRO)
    end
end

local function ToggleNoclip(state)
    if NoclipConnection then
        NoclipConnection:Disconnect()
        NoclipConnection = nil
    end
    
    if state then
        NoclipConnection = RunService.Stepped:Connect(function()
            local char = LocalPlayer.Character
            if char then
                for _, part in pairs(char:GetDescendants()) do
                    if part:IsA("BasePart") then
                        part.CanCollide = false
                    end
                end
            end
        end)
        Notify("Noclip ativado", CONFIG.COR_SUCESSO)
    else
        Notify("Noclip desativado", CONFIG.COR_ERRO)
    end
end

local function ToggleInfJump(state)
    if InfJumpConnection then
        InfJumpConnection:Disconnect()
        InfJumpConnection = nil
    end
    
    if state then
        InfJumpConnection = UserInputService.JumpRequest:Connect(function()
            local char = LocalPlayer.Character
            if char then
                local humanoid = char:FindFirstChildOfClass("Humanoid")
                if humanoid then
                    humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
                end
            end
        end)
        Notify("Pulo Infinito ativado", CONFIG.COR_SUCESSO)
    else
        Notify("Pulo Infinito desativado", CONFIG.COR_ERRO)
    end
end

local function SetSpeed(value)
    WalkSpeed = value
    local char = LocalPlayer.Character
    if char then
        local humanoid = char:FindFirstChildOfClass("Humanoid")
        if humanoid then
            humanoid.WalkSpeed = value
        end
    end
end

local function SetJumpPower(value)
    JumpPower = value
    local char = LocalPlayer.Character
    if char then
        local humanoid = char:FindFirstChildOfClass("Humanoid")
        if humanoid then
            humanoid.JumpPower = value
        end
    end
end

local function ToggleGodMode(state)
    local char = LocalPlayer.Character
    if char then
        local humanoid = char:FindFirstChildOfClass("Humanoid")
        if humanoid then
            if state then
                humanoid.MaxHealth = math.huge
                humanoid.Health = math.huge
                Notify("God Mode ativado", CONFIG.COR_SUCESSO)
            else
                humanoid.MaxHealth = 100
                humanoid.Health = 100
                Notify("God Mode desativado", CONFIG.COR_ERRO)
            end
        end
    end
end

local function TeleportToPlayer()
    if not SelectedPlayer then
        Notify("Selecione um jogador primeiro!", CONFIG.COR_ERRO)
        return
    end
    
    local char = LocalPlayer.Character
    local targetChar = SelectedPlayer.Character
    
    if char and targetChar then
        local root = char:FindFirstChild("HumanoidRootPart")
        local targetRoot = targetChar:FindFirstChild("HumanoidRootPart")
        
        if root and targetRoot then
            root.CFrame = targetRoot.CFrame * CFrame.new(0, 0, 3)
            Notify("Teleportado para " .. SelectedPlayer.Name, CONFIG.COR_SUCESSO)
        else
            Notify("Erro ao teleportar", CONFIG.COR_ERRO)
        end
    else
        Notify("Jogador não encontrado", CONFIG.COR_ERRO)
    end
end

local function BringPlayer()
    if not SelectedPlayer then
        Notify("Selecione um jogador primeiro!", CONFIG.COR_ERRO)
        return
    end
    
    local char = LocalPlayer.Character
    local targetChar = SelectedPlayer.Character
    
    if char and targetChar then
        local root = char:FindFirstChild("HumanoidRootPart")
        local targetRoot = targetChar:FindFirstChild("HumanoidRootPart")
        
        if root and targetRoot then
            targetRoot.CFrame = root.CFrame * CFrame.new(0, 0, -3)
            Notify(SelectedPlayer.Name .. " trazido até você", CONFIG.COR_SUCESSO)
        end
    end
end

local function KillPlayer()
    if not SelectedPlayer then
        Notify("Selecione um jogador primeiro!", CONFIG.COR_ERRO)
        return
    end
    
    local targetChar = SelectedPlayer.Character
    if targetChar then
        local humanoid = targetChar:FindFirstChildOfClass("Humanoid")
        if humanoid then
            humanoid.Health = 0
            Notify(SelectedPlayer.Name .. " eliminado", CONFIG.COR_SUCESSO)
        end
    end
end

local function ToggleFullbright(state)
    if state then
        Lighting.Brightness = 2
        Lighting.ClockTime = 14
        Lighting.FogEnd = 1e10
        Lighting.GlobalShadows = false
        Lighting.OutdoorAmbient = Color3.new(1, 1, 1)
        Notify("Fullbright ativado", CONFIG.COR_SUCESSO)
    else
        Lighting.Brightness = 1
        Lighting.ClockTime = 14
        Lighting.FogEnd = 1e5
        Lighting.GlobalShadows = true
        Lighting.OutdoorAmbient = Color3.new(0.5, 0.5, 0.5)
        Notify("Fullbright desativado", CONFIG.COR_ERRO)
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
    
    -- Container Principal
    local main = Instance.new("Frame")
    main.Name = "Main"
    main.Size = UDim2.new(0, 550, 0, 400)
    main.Position = UDim2.new(0.5, -275, 0.5, -200)
    main.BackgroundColor3 = CONFIG.COR_FUNDO
    main.BorderSizePixel = 0
    main.Parent = GUI
    
    local mainCorner = Instance.new("UICorner")
    mainCorner.CornerRadius = UDim.new(0, 10)
    mainCorner.Parent = main
    
    local mainStroke = Instance.new("UIStroke")
    mainStroke.Color = CONFIG.COR_ROXO
    mainStroke.Thickness = 2
    mainStroke.Parent = main
    
    -- Header
    local header = Instance.new("Frame")
    header.Name = "Header"
    header.Size = UDim2.new(1, 0, 0, 45)
    header.BackgroundColor3 = CONFIG.COR_FUNDO_2
    header.BorderSizePixel = 0
    header.Parent = main
    
    local headerCorner = Instance.new("UICorner")
    headerCorner.CornerRadius = UDim.new(0, 10)
    headerCorner.Parent = header
    
    -- Logo
    local logo = Instance.new("TextLabel")
    logo.Size = UDim2.new(0, 100, 1, 0)
    logo.Position = UDim2.new(0, 15, 0, 0)
    logo.BackgroundTransparency = 1
    logo.Text = "🟣 SHAKA"
    logo.TextColor3 = CONFIG.COR_ROXO
    logo.TextSize = 18
    logo.Font = Enum.Font.GothamBold
    logo.TextXAlignment = Enum.TextXAlignment.Left
    logo.Parent = header
    
    -- Versão
    local version = Instance.new("TextLabel")
    version.Size = UDim2.new(0, 60, 0, 20)
    version.Position = UDim2.new(0, 120, 0, 12)
    version.BackgroundColor3 = CONFIG.COR_ROXO
    version.Text = CONFIG.VERSAO
    version.TextColor3 = CONFIG.COR_TEXTO
    version.TextSize = 11
    version.Font = Enum.Font.GothamBold
    version.BorderSizePixel = 0
    version.Parent = header
    
    local versionCorner = Instance.new("UICorner")
    versionCorner.CornerRadius = UDim.new(0, 5)
    versionCorner.Parent = version
    
    -- Botão Fechar
    local closeBtn = Instance.new("TextButton")
    closeBtn.Size = UDim2.new(0, 30, 0, 30)
    closeBtn.Position = UDim2.new(1, -40, 0, 7)
    closeBtn.BackgroundColor3 = CONFIG.COR_ERRO
    closeBtn.Text = "×"
    closeBtn.TextColor3 = CONFIG.COR_TEXTO
    closeBtn.TextSize = 20
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.BorderSizePixel = 0
    closeBtn.Parent = header
    
    local closeBtnCorner = Instance.new("UICorner")
    closeBtnCorner.CornerRadius = UDim.new(0, 6)
    closeBtnCorner.Parent = closeBtn
    
    closeBtn.MouseButton1Click:Connect(function()
        Tween(main, {Size = UDim2.new(0, 0, 0, 0)}, 0.2)
        task.wait(0.2)
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
    
    -- Abas
    local tabBar = Instance.new("Frame")
    tabBar.Size = UDim2.new(0, 130, 1, -45)
    tabBar.Position = UDim2.new(0, 0, 0, 45)
    tabBar.BackgroundColor3 = CONFIG.COR_FUNDO_2
    tabBar.BorderSizePixel = 0
    tabBar.Parent = main
    
    -- Conteúdo
    local content = Instance.new("Frame")
    content.Size = UDim2.new(1, -130, 1, -45)
    content.Position = UDim2.new(0, 130, 0, 45)
    content.BackgroundTransparency = 1
    content.BorderSizePixel = 0
    content.Parent = main
    
    local tabs = {
        {Name = "Player", Icon = "👤"},
        {Name = "Combat", Icon = "⚔️"},
        {Name = "Teleport", Icon = "📍"},
        {Name = "Visuals", Icon = "✨"}
    }
    
    local currentTab = "Player"
    local tabFrames = {}
    
    -- Função para criar toggle
    local function CreateToggle(name, desc, callback, parent)
        local toggle = Instance.new("Frame")
        toggle.Size = UDim2.new(1, -20, 0, 60)
        toggle.BackgroundColor3 = CONFIG.COR_FUNDO_2
        toggle.BorderSizePixel = 0
        toggle.Parent = parent
        
        local toggleCorner = Instance.new("UICorner")
        toggleCorner.CornerRadius = UDim.new(0, 8)
        toggleCorner.Parent = toggle
        
        local nameLabel = Instance.new("TextLabel")
        nameLabel.Size = UDim2.new(0.65, 0, 0, 25)
        nameLabel.Position = UDim2.new(0, 12, 0, 8)
        nameLabel.BackgroundTransparency = 1
        nameLabel.Text = name
        nameLabel.TextColor3 = CONFIG.COR_TEXTO
        nameLabel.TextSize = 14
        nameLabel.Font = Enum.Font.GothamBold
        nameLabel.TextXAlignment = Enum.TextXAlignment.Left
        nameLabel.Parent = toggle
        
        local descLabel = Instance.new("TextLabel")
        descLabel.Size = UDim2.new(0.65, 0, 0, 20)
        descLabel.Position = UDim2.new(0, 12, 0, 32)
        descLabel.BackgroundTransparency = 1
        descLabel.Text = desc
        descLabel.TextColor3 = CONFIG.COR_TEXTO_SEC
        descLabel.TextSize = 11
        descLabel.Font = Enum.Font.Gotham
        descLabel.TextXAlignment = Enum.TextXAlignment.Left
        descLabel.Parent = toggle
        
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(0, 50, 0, 24)
        btn.Position = UDim2.new(1, -60, 0.5, -12)
        btn.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
        btn.Text = ""
        btn.BorderSizePixel = 0
        btn.Parent = toggle
        
        local btnCorner = Instance.new("UICorner")
        btnCorner.CornerRadius = UDim.new(0, 12)
        btnCorner.Parent = btn
        
        local knob = Instance.new("Frame")
        knob.Size = UDim2.new(0, 20, 0, 20)
        knob.Position = UDim2.new(0, 2, 0, 2)
        knob.BackgroundColor3 = CONFIG.COR_TEXTO
        knob.BorderSizePixel = 0
        knob.Parent = btn
        
        local knobCorner = Instance.new("UICorner")
        knobCorner.CornerRadius = UDim.new(0, 10)
        knobCorner.Parent = knob
        
        local state = false
        
        btn.MouseButton1Click:Connect(function()
            state = not state
            
            if state then
                Tween(btn, {BackgroundColor3 = CONFIG.COR_ROXO}, 0.15)
                Tween(knob, {Position = UDim2.new(0, 28, 0, 2)}, 0.15)
            else
                Tween(btn, {BackgroundColor3 = Color3.fromRGB(50, 50, 60)}, 0.15)
                Tween(knob, {Position = UDim2.new(0, 2, 0, 2)}, 0.15)
            end
            
            callback(state)
        end)
        
        return toggle
    end
    
    -- Função para criar slider
    local function CreateSlider(name, min, max, default, callback, parent)
        local slider = Instance.new("Frame")
        slider.Size = UDim2.new(1, -20, 0, 70)
        slider.BackgroundColor3 = CONFIG.COR_FUNDO_2
        slider.BorderSizePixel = 0
        slider.Parent = parent
        
        local sliderCorner = Instance.new("UICorner")
        sliderCorner.CornerRadius = UDim.new(0, 8)
        sliderCorner.Parent = slider
        
        local nameLabel = Instance.new("TextLabel")
        nameLabel.Size = UDim2.new(0.6, 0, 0, 25)
        nameLabel.Position = UDim2.new(0, 12, 0, 8)
        nameLabel.BackgroundTransparency = 1
        nameLabel.Text = name
        nameLabel.TextColor3 = CONFIG.COR_TEXTO
        nameLabel.TextSize = 14
        nameLabel.Font = Enum.Font.GothamBold
        nameLabel.TextXAlignment = Enum.TextXAlignment.Left
        nameLabel.Parent = slider
        
        local valueLabel = Instance.new("TextLabel")
        valueLabel.Size = UDim2.new(0.3, 0, 0, 25)
        valueLabel.Position = UDim2.new(0.7, 0, 0, 8)
        valueLabel.BackgroundTransparency = 1
        valueLabel.Text = tostring(default)
        valueLabel.TextColor3 = CONFIG.COR_ROXO
        valueLabel.TextSize = 14
        valueLabel.Font = Enum.Font.GothamBold
        valueLabel.TextXAlignment = Enum.TextXAlignment.Right
        valueLabel.Parent = slider
        
        local track = Instance.new("Frame")
        track.Size = UDim2.new(1, -24, 0, 6)
        track.Position = UDim2.new(0, 12, 0, 45)
        track.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
        track.BorderSizePixel = 0
        track.Parent = slider
        
        local trackCorner = Instance.new("UICorner")
        trackCorner.CornerRadius = UDim.new(0, 3)
        trackCorner.Parent = track
        
        local fill = Instance.new("Frame")
        fill.Size = UDim2.new((default - min) / (max - min), 0, 1, 0)
        fill.BackgroundColor3 = CONFIG.COR_ROXO
        fill.BorderSizePixel = 0
        fill.Parent = track
        
        local fillCorner = Instance.new("UICorner")
        fillCorner.CornerRadius = UDim.new(0, 3)
        fillCorner.Parent = fill
        
        local knob = Instance.new("Frame")
        knob.Size = UDim2.new(0, 14, 0, 14)
        knob.Position = UDim2.new((default - min) / (max - min), -7, 0.5, -7)
        knob.BackgroundColor3 = CONFIG.COR_TEXTO
        knob.BorderSizePixel = 0
        knob.Parent = track
        
        local knobCorner = Instance.new("UICorner")
        knobCorner.CornerRadius = UDim.new(0, 7)
        knobCorner.Parent = knob
        
        local dragging = false
        
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
    
    -- Função para criar botão
    local function CreateButton(text, callback, parent)
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(1, -20, 0, 40)
        btn.BackgroundColor3 = CONFIG.COR_ROXO
        btn.Text = text
        btn.TextColor3 = CONFIG.COR_TEXTO
        btn.TextSize = 14
        btn.Font = Enum.Font.GothamBold
        btn.BorderSizePixel = 0
        btn.Parent = parent
        
        local btnCorner = Instance.new("UICorner")
        btnCorner.CornerRadius = UDim.new(0, 8)
        btnCorner.Parent = btn
        
        btn.MouseEnter:Connect(function()
            Tween(btn, {BackgroundColor3 = CONFIG.COR_ROXO_HOVER}, 0.15)
        end)
        
        btn.MouseLeave:Connect(function()
            Tween(btn, {BackgroundColor3 = CONFIG.COR_ROXO}, 0.15)
        end)
        
        btn.MouseButton1Click:Connect(callback)
        
        return btn
    end
    
    -- Criar abas
    for i, tab in ipairs(tabs) do
        local tabBtn = Instance.new("TextButton")
        tabBtn.Size = UDim2.new(1, -10, 0, 50)
        tabBtn.Position = UDim2.new(0, 5, 0, (i - 1) * 55 + 5)
        tabBtn.BackgroundColor3 = CONFIG.COR_FUNDO
        tabBtn.Text = tab.Icon .. "\n" .. tab.Name
        tabBtn.TextColor3 = CONFIG.COR_TEXTO
        tabBtn.TextSize = 13
        tabBtn.Font = Enum.Font.GothamBold
        tabBtn.BorderSizePixel = 0
        tabBtn.Parent = tabBar
        
        local tabCorner = Instance.new("UICorner")
        tabCorner.CornerRadius = UDim.new(0, 8)
        tabCorner.Parent = tabBtn
        
        -- Frame de conteúdo
        local tabContent = Instance.new("ScrollingFrame")
        tabContent.Size = UDim2.new(1, -20, 1, -20)
        tabContent.Position = UDim2.new(0, 10, 0, 10)
        tabContent.BackgroundTransparency = 1
        tabContent.BorderSizePixel = 0
        tabContent.ScrollBarThickness = 4
        tabContent.ScrollBarImageColor3 = CONFIG.COR_ROXO
        tabContent.CanvasSize = UDim2.new(0, 0, 0, 0)
        tabContent.Visible = false
        tabContent.Parent = content
        
        local layout = Instance.new("UIListLayout")
        layout.Padding = UDim.new(0, 10)
        layout.SortOrder = Enum.SortOrder.LayoutOrder
        layout.Parent = tabContent
        
        layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            tabContent.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 10)
        end)
        
        tabFrames[tab.Name] = tabContent
        
        tabBtn.MouseButton1Click:Connect(function()
            currentTab = tab.Name
            
            for name, frame in pairs(tabFrames) do
                frame.Visible = (name == tab.Name)
            end
            
            for _, btn in pairs(tabBar:GetChildren()) do
                if btn:IsA("TextButton") then
                    Tween(btn, {BackgroundColor3 = CONFIG.COR_FUNDO}, 0.15)
                end
            end
            
            Tween(tabBtn, {BackgroundColor3 = CONFIG.COR_ROXO}, 0.15)
        end)
        
        if i == 1 then
            tabBtn.BackgroundColor3 = CONFIG.COR_ROXO
            tabContent.Visible = true
        end
    end
    
    -- ════════════════════════════════════════════════════════════
    -- ABA PLAYER
    -- ════════════════════════════════════════════════════════════
    CreateToggle("Fly", "Voar pelo mapa [WASD]", function(state)
        ToggleFly(state)
    end, tabFrames["Player"])
    
    CreateSlider("Velocidade Fly", 10, 150, 50, function(value)
        FlySpeed = value
    end, tabFrames["Player"])
    
    CreateToggle("Noclip", "Atravessar paredes", function(state)
        ToggleNoclip(state)
    end, tabFrames["Player"])
    
    CreateToggle("Pulo Infinito", "Pular infinitamente", function(state)
        ToggleInfJump(state)
    end, tabFrames["Player"])
    
    CreateSlider("Velocidade", 16, 200, 16, function(value)
        SetSpeed(value)
    end, tabFrames["Player"])
    
    CreateSlider("Força do Pulo", 50, 300, 50, function(value)
        SetJumpPower(value)
    end, tabFrames["Player"])
    
    CreateToggle("God Mode", "Invencibilidade", function(state)
        ToggleGodMode(state)
    end, tabFrames["Player"])
    
    CreateButton("🔄 Resetar Personagem", function()
        local char = LocalPlayer.Character
        if char then
            local humanoid = char:FindFirstChildOfClass("Humanoid")
            if humanoid then
                humanoid.Health = 0
                Notify("Personagem resetado", CONFIG.COR_SUCESSO)
            end
        end
    end, tabFrames["Player"])
    
    -- ════════════════════════════════════════════════════════════
    -- ABA COMBAT
    -- ════════════════════════════════════════════════════════════
    local playerListFrame = Instance.new("Frame")
    playerListFrame.Size = UDim2.new(1, -20, 0, 220)
    playerListFrame.BackgroundColor3 = CONFIG.COR_FUNDO_2
    playerListFrame.BorderSizePixel = 0
    playerListFrame.Parent = tabFrames["Combat"]
    
    local playerListCorner = Instance.new("UICorner")
    playerListCorner.CornerRadius = UDim.new(0, 8)
    playerListCorner.Parent = playerListFrame
    
    local playerListTitle = Instance.new("TextLabel")
    playerListTitle.Size = UDim2.new(1, 0, 0, 30)
    playerListTitle.BackgroundTransparency = 1
    playerListTitle.Text = "🎯 Selecione um Jogador"
    playerListTitle.TextColor3 = CONFIG.COR_TEXTO
    playerListTitle.TextSize = 14
    playerListTitle.Font = Enum.Font.GothamBold
    playerListTitle.Parent = playerListFrame
    
    local playerScroll = Instance.new("ScrollingFrame")
    playerScroll.Size = UDim2.new(1, -10, 1, -40)
    playerScroll.Position = UDim2.new(0, 5, 0, 35)
    playerScroll.BackgroundTransparency = 1
    playerScroll.BorderSizePixel = 0
    playerScroll.ScrollBarThickness = 4
    playerScroll.ScrollBarImageColor3 = CONFIG.COR_ROXO
    playerScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    playerScroll.Parent = playerListFrame
    
    local playerLayout = Instance.new("UIListLayout")
    playerLayout.Padding = UDim.new(0, 5)
    playerLayout.SortOrder = Enum.SortOrder.LayoutOrder
    playerLayout.Parent = playerScroll
    
    playerLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        playerScroll.CanvasSize = UDim2.new(0, 0, 0, playerLayout.AbsoluteContentSize.Y + 5)
    end)
    
    local selectedLabel = Instance.new("TextLabel")
    selectedLabel.Size = UDim2.new(1, -20, 0, 35)
    selectedLabel.BackgroundColor3 = CONFIG.COR_FUNDO_2
    selectedLabel.Text = "👤 Nenhum jogador selecionado"
    selectedLabel.TextColor3 = CONFIG.COR_ROXO
    selectedLabel.TextSize = 13
    selectedLabel.Font = Enum.Font.GothamBold
    selectedLabel.BorderSizePixel = 0
    selectedLabel.Parent = tabFrames["Combat"]
    
    local selectedCorner = Instance.new("UICorner")
    selectedCorner.CornerRadius = UDim.new(0, 8)
    selectedCorner.Parent = selectedLabel
    
    local function UpdatePlayerList()
        playerScroll:ClearAllChildren()
        
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
                playerBtn.Text = "  👤 " .. player.Name
                playerBtn.TextColor3 = CONFIG.COR_TEXTO
                playerBtn.TextSize = 12
                playerBtn.Font = Enum.Font.Gotham
                playerBtn.TextXAlignment = Enum.TextXAlignment.Left
                playerBtn.BorderSizePixel = 0
                playerBtn.Parent = playerScroll
                
                local btnCorner = Instance.new("UICorner")
                btnCorner.CornerRadius = UDim.new(0, 6)
                btnCorner.Parent = playerBtn
                
                playerBtn.MouseButton1Click:Connect(function()
                    SelectedPlayer = player
                    selectedLabel.Text = "👤 Selecionado: " .. player.Name
                    
                    for _, btn in pairs(playerScroll:GetChildren()) do
                        if btn:IsA("TextButton") then
                            Tween(btn, {BackgroundColor3 = CONFIG.COR_FUNDO}, 0.1)
                        end
                    end
                    
                    Tween(playerBtn, {BackgroundColor3 = CONFIG.COR_ROXO}, 0.1)
                end)
                
                playerBtn.MouseEnter:Connect(function()
                    if SelectedPlayer ~= player then
                        Tween(playerBtn, {BackgroundColor3 = CONFIG.COR_FUNDO_2}, 0.1)
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
    
    CreateButton("🔫 Eliminar Jogador", function()
        KillPlayer()
    end, tabFrames["Combat"])
    
    CreateButton("💥 Explodir Jogador", function()
        if not SelectedPlayer then
            Notify("Selecione um jogador primeiro!", CONFIG.COR_ERRO)
            return
        end
        
        local targetChar = SelectedPlayer.Character
        if targetChar then
            local root = targetChar:FindFirstChild("HumanoidRootPart")
            if root then
                local explosion = Instance.new("Explosion")
                explosion.Position = root.Position
                explosion.BlastRadius = 10
                explosion.BlastPressure = 500000
                explosion.Parent = workspace
                Notify("Explosão criada!", CONFIG.COR_SUCESSO)
            end
        end
    end, tabFrames["Combat"])
    
    CreateButton("🔥 Incendiar Jogador", function()
        if not SelectedPlayer then
            Notify("Selecione um jogador primeiro!", CONFIG.COR_ERRO)
            return
        end
        
        local targetChar = SelectedPlayer.Character
        if targetChar then
            local root = targetChar:FindFirstChild("HumanoidRootPart")
            if root then
                local fire = Instance.new("Fire")
                fire.Size = 10
                fire.Heat = 10
                fire.Parent = root
                Notify("Jogador incendiado!", CONFIG.COR_SUCESSO)
            end
        end
    end, tabFrames["Combat"])
    
    -- ════════════════════════════════════════════════════════════
    -- ABA TELEPORT
    -- ════════════════════════════════════════════════════════════
    local tpListFrame = Instance.new("Frame")
    tpListFrame.Size = UDim2.new(1, -20, 0, 220)
    tpListFrame.BackgroundColor3 = CONFIG.COR_FUNDO_2
    tpListFrame.BorderSizePixel = 0
    tpListFrame.Parent = tabFrames["Teleport"]
    
    local tpListCorner = Instance.new("UICorner")
    tpListCorner.CornerRadius = UDim.new(0, 8)
    tpListCorner.Parent = tpListFrame
    
    local tpListTitle = Instance.new("TextLabel")
    tpListTitle.Size = UDim2.new(1, 0, 0, 30)
    tpListTitle.BackgroundTransparency = 1
    tpListTitle.Text = "📍 Lista de Jogadores"
    tpListTitle.TextColor3 = CONFIG.COR_TEXTO
    tpListTitle.TextSize = 14
    tpListTitle.Font = Enum.Font.GothamBold
    tpListTitle.Parent = tpListFrame
    
    local tpScroll = Instance.new("ScrollingFrame")
    tpScroll.Size = UDim2.new(1, -10, 1, -40)
    tpScroll.Position = UDim2.new(0, 5, 0, 35)
    tpScroll.BackgroundTransparency = 1
    tpScroll.BorderSizePixel = 0
    tpScroll.ScrollBarThickness = 4
    tpScroll.ScrollBarImageColor3 = CONFIG.COR_ROXO
    tpScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    tpScroll.Parent = tpListFrame
    
    local tpLayout = Instance.new("UIListLayout")
    tpLayout.Padding = UDim.new(0, 5)
    tpLayout.SortOrder = Enum.SortOrder.LayoutOrder
    tpLayout.Parent = tpScroll
    
    tpLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        tpScroll.CanvasSize = UDim2.new(0, 0, 0, tpLayout.AbsoluteContentSize.Y + 5)
    end)
    
    local tpSelectedLabel = Instance.new("TextLabel")
    tpSelectedLabel.Size = UDim2.new(1, -20, 0, 35)
    tpSelectedLabel.BackgroundColor3 = CONFIG.COR_FUNDO_2
    tpSelectedLabel.Text = "📌 Nenhum jogador selecionado"
    tpSelectedLabel.TextColor3 = CONFIG.COR_ROXO
    tpSelectedLabel.TextSize = 13
    tpSelectedLabel.Font = Enum.Font.GothamBold
    tpSelectedLabel.BorderSizePixel = 0
    tpSelectedLabel.Parent = tabFrames["Teleport"]
    
    local tpSelectedCorner = Instance.new("UICorner")
    tpSelectedCorner.CornerRadius = UDim.new(0, 8)
    tpSelectedCorner.Parent = tpSelectedLabel
    
    local function UpdateTPList()
        tpScroll:ClearAllChildren()
        
        local tpLayout = Instance.new("UIListLayout")
        tpLayout.Padding = UDim.new(0, 5)
        tpLayout.SortOrder = Enum.SortOrder.LayoutOrder
        tpLayout.Parent = tpScroll
        
        tpLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            tpScroll.CanvasSize = UDim2.new(0, 0, 0, tpLayout.AbsoluteContentSize.Y + 5)
        end)
        
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= LocalPlayer then
                local playerBtn = Instance.new("TextButton")
                playerBtn.Size = UDim2.new(1, -5, 0, 35)
                playerBtn.BackgroundColor3 = CONFIG.COR_FUNDO
                playerBtn.Text = "  📍 " .. player.Name
                playerBtn.TextColor3 = CONFIG.COR_TEXTO
                playerBtn.TextSize = 12
                playerBtn.Font = Enum.Font.Gotham
                playerBtn.TextXAlignment = Enum.TextXAlignment.Left
                playerBtn.BorderSizePixel = 0
                playerBtn.Parent = tpScroll
                
                local btnCorner = Instance.new("UICorner")
                btnCorner.CornerRadius = UDim.new(0, 6)
                btnCorner.Parent = playerBtn
                
                playerBtn.MouseButton1Click:Connect(function()
                    SelectedPlayer = player
                    tpSelectedLabel.Text = "📌 Selecionado: " .. player.Name
                    
                    for _, btn in pairs(tpScroll:GetChildren()) do
                        if btn:IsA("TextButton") then
                            Tween(btn, {BackgroundColor3 = CONFIG.COR_FUNDO}, 0.1)
                        end
                    end
                    
                    Tween(playerBtn, {BackgroundColor3 = CONFIG.COR_ROXO}, 0.1)
                end)
                
                playerBtn.MouseEnter:Connect(function()
                    if SelectedPlayer ~= player then
                        Tween(playerBtn, {BackgroundColor3 = CONFIG.COR_FUNDO_2}, 0.1)
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
    
    UpdateTPList()
    
    task.spawn(function()
        while GUI do
            UpdateTPList()
            task.wait(3)
        end
    end)
    
    CreateButton("🚀 Teleportar para Jogador", function()
        TeleportToPlayer()
    end, tabFrames["Teleport"])
    
    CreateButton("🔙 Trazer Jogador", function()
        BringPlayer()
    end, tabFrames["Teleport"])
    
    CreateButton("🏠 Voltar ao Spawn", function()
        local char = LocalPlayer.Character
        if char then
            local root = char:FindFirstChild("HumanoidRootPart")
            if root then
                local spawn = workspace:FindFirstChildOfClass("SpawnLocation")
                if spawn then
                    root.CFrame = spawn.CFrame + Vector3.new(0, 5, 0)
                    Notify("Teleportado para spawn", CONFIG.COR_SUCESSO)
                else
                    root.CFrame = CFrame.new(0, 50, 0)
                    Notify("Teleportado para origem", CONFIG.COR_SUCESSO)
                end
            end
        end
    end, tabFrames["Teleport"])
    
    -- ════════════════════════════════════════════════════════════
    -- ABA VISUALS
    -- ════════════════════════════════════════════════════════════
    CreateToggle("Fullbright", "Iluminação total", function(state)
        ToggleFullbright(state)
    end, tabFrames["Visuals"])
    
    CreateToggle("Remover Fog", "Remover neblina", function(state)
        if state then
            Lighting.FogEnd = 1e10
            Lighting.FogStart = 0
            Notify("Fog removido", CONFIG.COR_SUCESSO)
        else
            Lighting.FogEnd = 1e5
            Lighting.FogStart = 0
            Notify("Fog restaurado", CONFIG.COR_ERRO)
        end
    end, tabFrames["Visuals"])
    
    CreateSlider("Brilho", 0, 5, 1, function(value)
        Lighting.Brightness = value
    end, tabFrames["Visuals"])
    
    CreateSlider("FOV", 70, 120, 70, function(value)
        Camera.FieldOfView = value
    end, tabFrames["Visuals"])
    
    CreateToggle("Remover Sombras", "Desativar sombras", function(state)
        Lighting.GlobalShadows = not state
        if state then
            Notify("Sombras removidas", CONFIG.COR_SUCESSO)
        else
            Notify("Sombras restauradas", CONFIG.COR_ERRO)
        end
    end, tabFrames["Visuals"])
    
    CreateToggle("Otimizar FPS", "Melhorar performance", function(state)
        if state then
            settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
            
            for _, obj in ipairs(workspace:GetDescendants()) do
                if obj:IsA("ParticleEmitter") or obj:IsA("Trail") or obj:IsA("Smoke") or obj:IsA("Fire") or obj:IsA("Sparkles") then
                    obj.Enabled = false
                end
            end
            
            Notify("FPS otimizado", CONFIG.COR_SUCESSO)
        else
            settings().Rendering.QualityLevel = Enum.QualityLevel.Automatic
            
            for _, obj in ipairs(workspace:GetDescendants()) do
                if obj:IsA("ParticleEmitter") or obj:IsA("Trail") or obj:IsA("Smoke") or obj:IsA("Fire") or obj:IsA("Sparkles") then
                    obj.Enabled = true
                end
            end
            
            Notify("FPS normal", CONFIG.COR_ERRO)
        end
    end, tabFrames["Visuals"])
    
    CreateButton("🎨 Céu Colorido", function()
        local sky = Lighting:FindFirstChildOfClass("Sky") or Instance.new("Sky", Lighting)
        sky.SkyboxBk = "rbxassetid://48020371"
        sky.SkyboxDn = "rbxassetid://48020144"
        sky.SkyboxFt = "rbxassetid://48020359"
        sky.SkyboxLf = "rbxassetid://48020320"
        sky.SkyboxRt = "rbxassetid://48020315"
        sky.SkyboxUp = "rbxassetid://48020383"
        Notify("Céu alterado!", CONFIG.COR_SUCESSO)
    end, tabFrames["Visuals"])
    
    -- Animação de entrada
    main.Size = UDim2.new(0, 0, 0, 0)
    Tween(main, {Size = UDim2.new(0, 550, 0, 400)}, 0.3)
    
    Log("Menu carregado com sucesso!")
    Notify("🟣 SHAKA Hub " .. CONFIG.VERSAO .. " carregado!", CONFIG.COR_ROXO)
end

-- ════════════════════════════════════════════════════════════
-- INICIALIZAÇÃO
-- ════════════════════════════════════════════════════════════
Log("════════════════════════════════════════")
Log("  SHAKA Hub Premium " .. CONFIG.VERSAO)
Log("  Inicializando sistema...")
Log("════════════════════════════════════════")

task.wait(0.5)

CreateGUI()

-- Manter velocidade e pulo
task.spawn(function()
    while true do
        local char = LocalPlayer.Character
        if char then
            local humanoid = char:FindFirstChildOfClass("Humanoid")
            if humanoid then
                if humanoid.WalkSpeed ~= WalkSpeed then
                    humanoid.WalkSpeed = WalkSpeed
                end
                if humanoid.JumpPower ~= JumpPower then
                    humanoid.JumpPower = JumpPower
                end
            end
        end
        task.wait(0.1)
    end
end)

-- Toggle com tecla F
UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    
    if input.KeyCode == Enum.KeyCode.F then
        if GUI then
            local main = GUI:FindFirstChild("Main")
            if main then
                Tween(main, {Size = UDim2.new(0, 0, 0, 0)}, 0.2)
                task.wait(0.2)
            end
            GUI:Destroy()
            GUI = nil
            Log("Menu fechado")
        else
            CreateGUI()
            Log("Menu aberto")
        end
    end
end)

Log("✅ Sistema carregado!")
Log("⌨️  Pressione F para abrir/fechar o menu")
Log("════════════════════════════════════════")
