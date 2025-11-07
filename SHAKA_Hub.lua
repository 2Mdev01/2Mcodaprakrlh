-- SHAKA Hub Premium - Menu Avançado
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")
local Camera = workspace.CurrentCamera

-- Configurações
local SHAKA_CONFIG = {
    NOME = "SHAKA",
    VERSAO = "v3.0 Premium",
    COR_ROXO = Color3.fromRGB(128, 0, 128),
    COR_ROXO_CLARO = Color3.fromRGB(160, 50, 160),
    COR_ROXO_ESCURO = Color3.fromRGB(80, 0, 80),
    COR_PRETO = Color3.fromRGB(15, 15, 15),
    COR_PRETO_CLARO = Color3.fromRGB(30, 30, 30),
    COR_CINZA = Color3.fromRGB(50, 50, 50)
}

-- Variáveis globais
local GUI = nil
local Connections = {}
local ESP_Objects = {}
local SelectedPlayer = nil
local FlyEnabled = false
local NoclipEnabled = false
local InfJumpEnabled = false
local SpeedEnabled = false
local InvisEnabled = false
local MenuVisible = true
local Dragging = false
local DragStart = nil
local MenuPosition = UDim2.new(0.02, 0, 0.02, 0)

-- Sistema de logging
local function Log(mensagem)
    print("🟣 [SHAKA] " .. mensagem)
end

-- Função para criar elementos com estilo
local function CriarElemento(tipo, propriedades)
    local elemento = Instance.new(tipo)
    for prop, valor in pairs(propriedades) do
        elemento[prop] = valor
    end
    return elemento
end

-- Animação suave
local function AnimacaoSuave(elemento, propriedades, duracao)
    local tweenInfo = TweenInfo.new(duracao, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    local tween = TweenService:Create(elemento, tweenInfo, propriedades)
    tween:Play()
    return tween
end

-- Criar GUI moderna
local function CriarGUI()
    if GUI then
        GUI:Destroy()
        GUI = nil
    end

    -- GUI Principal
    GUI = CriarElemento("ScreenGui", {
        Name = "SHAKAHub",
        Parent = LocalPlayer:WaitForChild("PlayerGui"),
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    })

    -- Container Principal
    local MainContainer = CriarElemento("Frame", {
        Name = "MainContainer",
        Size = UDim2.new(0, 600, 0, 400),
        Position = MenuPosition,
        BackgroundColor3 = SHAKA_CONFIG.COR_PRETO,
        BorderColor3 = SHAKA_CONFIG.COR_ROXO,
        BorderSizePixel = 2,
        ClipsDescendants = true,
        Parent = GUI
    })

    -- Header arrastável
    local Header = CriarElemento("Frame", {
        Name = "Header",
        Size = UDim2.new(1, 0, 0, 35),
        BackgroundColor3 = SHAKA_CONFIG.COR_ROXO_ESCURO,
        BorderSizePixel = 0,
        Parent = MainContainer
    })

    local Logo = CriarElemento("TextLabel", {
        Name = "Logo",
        Size = UDim2.new(0, 120, 1, 0),
        BackgroundTransparency = 1,
        Text = "🟣 SHAKA",
        TextColor3 = Color3.new(1, 1, 1),
        TextScaled = true,
        Font = Enum.Font.GothamBold,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = Header
    })

    local Version = CriarElemento("TextLabel", {
        Name = "Version",
        Size = UDim2.new(0, 80, 1, 0),
        Position = UDim2.new(1, -80, 0, 0),
        BackgroundTransparency = 1,
        Text = SHAKA_CONFIG.VERSAO,
        TextColor3 = Color3.new(0.8, 0.8, 0.8),
        TextScaled = true,
        Font = Enum.Font.Gotham,
        Parent = Header
    })

    local MinimizeButton = CriarElemento("TextButton", {
        Name = "MinimizeButton",
        Size = UDim2.new(0, 30, 0, 30),
        Position = UDim2.new(1, -70, 0, 2),
        BackgroundColor3 = SHAKA_CONFIG.COR_ROXO_CLARO,
        TextColor3 = Color3.new(1, 1, 1),
        Text = "_",
        TextScaled = true,
        Font = Enum.Font.GothamBold,
        Parent = Header
    })

    local CloseButton = CriarElemento("TextButton", {
        Name = "CloseButton",
        Size = UDim2.new(0, 30, 0, 30),
        Position = UDim2.new(1, -35, 0, 2),
        BackgroundColor3 = Color3.fromRGB(200, 0, 0),
        TextColor3 = Color3.new(1, 1, 1),
        Text = "×",
        TextScaled = true,
        Font = Enum.Font.GothamBold,
        Parent = Header
    })

    -- Container do conteúdo
    local ContentContainer = CriarElemento("Frame", {
        Name = "ContentContainer",
        Size = UDim2.new(1, 0, 1, -35),
        Position = UDim2.new(0, 0, 0, 35),
        BackgroundColor3 = SHAKA_CONFIG.COR_PRETO,
        BorderSizePixel = 0,
        Parent = MainContainer
    })

    -- Abas laterais
    local SideTabs = CriarElemento("Frame", {
        Name = "SideTabs",
        Size = UDim2.new(0, 120, 1, 0),
        BackgroundColor3 = SHAKA_CONFIG.COR_PRETO_CLARO,
        BorderSizePixel = 0,
        Parent = ContentContainer
    })

    -- Conteúdo das abas
    local TabContent = CriarElemento("Frame", {
        Name = "TabContent",
        Size = UDim2.new(1, -120, 1, 0),
        Position = UDim2.new(0, 120, 0, 0),
        BackgroundColor3 = SHAKA_CONFIG.COR_PRETO,
        BorderSizePixel = 0,
        Parent = ContentContainer
    })

    -- Lista de abas
    local Tabs = {
        {Nome = "Player", Icon = "👤"},
        {Nome = "ESP", Icon = "🎯"},
        {Nome = "Teleport", Icon = "📍"},
        {Nome = "Visuals", Icon = "✨"},
        {Nome = "Settings", Icon = "⚙️"}
    }

    local CurrentTab = "Player"
    local TabFrames = {}

    -- Criar botões das abas laterais
    for i, tab in ipairs(Tabs) do
        local TabButton = CriarElemento("TextButton", {
            Name = tab.Nome .. "Tab",
            Size = UDim2.new(1, -10, 0, 50),
            Position = UDim2.new(0, 5, 0, (i-1) * 55 + 5),
            BackgroundColor3 = SHAKA_CONFIG.COR_PRETO_CLARO,
            BorderColor3 = SHAKA_CONFIG.COR_ROXO,
            BorderSizePixel = 1,
            Text = tab.Icon .. "\n" .. tab.Nome,
            TextColor3 = Color3.new(1, 1, 1),
            TextScaled = true,
            Font = Enum.Font.Gotham,
            Parent = SideTabs
        })

        -- Frame de conteúdo para cada aba
        local ContentFrame = CriarElemento("ScrollingFrame", {
            Name = tab.Nome .. "Content",
            Size = UDim2.new(1, -20, 1, -20),
            Position = UDim2.new(0, 10, 0, 10),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            ScrollBarThickness = 5,
            CanvasSize = UDim2.new(0, 0, 0, 0),
            Visible = false,
            Parent = TabContent
        })

        TabFrames[tab.Nome] = ContentFrame

        TabButton.MouseButton1Click:Connect(function()
            CurrentTab = tab.Nome
            for nome, frame in pairs(TabFrames) do
                frame.Visible = (nome == tab.Nome)
            end
            -- Atualizar cores dos botões
            for _, btn in ipairs(SideTabs:GetChildren()) do
                if btn:IsA("TextButton") then
                    AnimacaoSuave(btn, {BackgroundColor3 = SHAKA_CONFIG.COR_PRETO_CLARO}, 0.2)
                end
            end
            AnimacaoSuave(TabButton, {BackgroundColor3 = SHAKA_CONFIG.COR_ROXO}, 0.2)
        end)

        if i == 1 then
            TabButton.BackgroundColor3 = SHAKA_CONFIG.COR_ROXO
            ContentFrame.Visible = true
        end
    end

    -- Função para criar toggles modernos
    local function CriarToggle(nome, descricao, posicaoY, callback, valorPadrao)
        local ToggleContainer = CriarElemento("Frame", {
            Size = UDim2.new(1, -20, 0, 60),
            Position = UDim2.new(0, 10, 0, posicaoY),
            BackgroundColor3 = SHAKA_CONFIG.COR_PRETO_CLARO,
            BorderColor3 = SHAKA_CONFIG.COR_CINZA,
            BorderSizePixel = 1,
            Parent = TabFrames[CurrentTab]
        })

        local ToggleInfo = CriarElemento("Frame", {
            Size = UDim2.new(0.7, 0, 1, 0),
            BackgroundTransparency = 1,
            Parent = ToggleContainer
        })

        local ToggleName = CriarElemento("TextLabel", {
            Size = UDim2.new(1, 0, 0, 30),
            BackgroundTransparency = 1,
            Text = nome,
            TextColor3 = Color3.new(1, 1, 1),
            TextXAlignment = Enum.TextXAlignment.Left,
            TextScaled = true,
            Font = Enum.Font.GothamBold,
            Parent = ToggleInfo
        })

        local ToggleDesc = CriarElemento("TextLabel", {
            Size = UDim2.new(1, 0, 0, 25),
            Position = UDim2.new(0, 0, 0, 30),
            BackgroundTransparency = 1,
            Text = descricao,
            TextColor3 = Color3.new(0.8, 0.8, 0.8),
            TextXAlignment = Enum.TextXAlignment.Left,
            TextScaled = false,
            TextSize = 12,
            Font = Enum.Font.Gotham,
            Parent = ToggleInfo
        })

        local ToggleButton = CriarElemento("TextButton", {
            Size = UDim2.new(0, 50, 0, 25),
            Position = UDim2.new(1, -60, 0.5, -12),
            BackgroundColor3 = valorPadrao and SHAKA_CONFIG.COR_ROXO or SHAKA_CONFIG.COR_CINZA,
            Text = "",
            Parent = ToggleContainer
        })

        local ToggleKnob = CriarElemento("Frame", {
            Size = UDim2.new(0, 21, 0, 21),
            Position = UDim2.new(0, valorPadrao and 25 or 2, 0, 2),
            BackgroundColor3 = Color3.new(1, 1, 1),
            BorderSizePixel = 0,
            Parent = ToggleButton
        })

        local estado = valorPadrao or false

        local function AtualizarToggle()
            if estado then
                AnimacaoSuave(ToggleButton, {BackgroundColor3 = SHAKA_CONFIG.COR_ROXO}, 0.2)
                AnimacaoSuave(ToggleKnob, {Position = UDim2.new(0, 25, 0, 2)}, 0.2)
            else
                AnimacaoSuave(ToggleButton, {BackgroundColor3 = SHAKA_CONFIG.COR_CINZA}, 0.2)
                AnimacaoSuave(ToggleKnob, {Position = UDim2.new(0, 2, 0, 2)}, 0.2)
            end
            callback(estado)
        end

        ToggleButton.MouseButton1Click:Connect(function()
            estado = not estado
            AtualizarToggle()
        end)

        return {
            SetState = function(novoEstado)
                estado = novoEstado
                AtualizarToggle()
            end,
            GetState = function() return estado end
        }
    end

    -- Conteúdo da aba Player
    local PlayerToggles = {}
    PlayerToggles.Noclip = CriarToggle("Noclip", "Atravessar paredes", 10, function(estado)
        NoclipEnabled = estado
        Log("Noclip: " .. (estado and "ON" or "OFF"))
    end, false)

    PlayerToggles.Fly = CriarToggle("Fly", "Voar pelo mapa", 80, function(estado)
        FlyEnabled = estado
        AtivarFly(estado)
        Log("Fly: " .. (estado and "ON" or "OFF"))
    end, false)

    PlayerToggles.InfJump = CriarToggle("Pulo Infinito", "Pular sem limites", 150, function(estado)
        InfJumpEnabled = estado
        AtivarPuloInfinito(estado)
        Log("Pulo Infinito: " .. (estado and "ON" or "OFF"))
    end, false)

    PlayerToggles.Speed = CriarToggle("Super Velocidade", "Aumentar velocidade", 220, function(estado)
        SpeedEnabled = estado
        AtivarSuperVelocidade(estado)
        Log("Super Velocidade: " .. (estado and "ON" or "OFF"))
    end, false)

    PlayerToggles.Invis = CriarToggle("Invisibilidade", "Ficar invisível", 290, function(estado)
        InvisEnabled = estado
        FicarInvisivel(estado)
        Log("Invisibilidade: " .. (estado and "ON" or "OFF"))
    end, false)

    -- Conteúdo da aba ESP
    local ESPToggles = {}
    ESPToggles.ESP = CriarToggle("ESP Ativado", "Visualizar jogadores", 10, function(estado)
        if estado then
            AtivarESP()
        else
            DesativarESP()
        end
        Log("ESP: " .. (estado and "ON" or "OFF"))
    end, false)

    ESPToggles.Box = CriarToggle("ESP Box", "Caixa ao redor dos players", 80, function(estado)
        ESPConfig.Box = estado
        AtualizarESP()
        Log("ESP Box: " .. (estado and "ON" or "OFF"))
    end, true)

    ESPToggles.Tracer = CriarToggle("ESP Tracer", "Linha até os players", 150, function(estado)
        ESPConfig.Tracer = estado
        AtualizarESP()
        Log("ESP Tracer: " .. (estado and "ON" or "OFF"))
    end, true)

    ESPToggles.Names = CriarToggle("Mostrar Nomes", "Exibir nomes dos players", 220, function(estado)
        ESPConfig.Names = estado
        AtualizarESP()
        Log("Nomes ESP: " .. (estado and "ON" or "OFF"))
    end, true)

    ESPToggles.Distance = CriarToggle("Mostrar Distância", "Exibir distância", 290, function(estado)
        ESPConfig.Distance = estado
        AtualizarESP()
        Log("Distância ESP: " .. (estado and "ON" or "OFF"))
    end, true)

    -- Conteúdo da aba Teleport
    local PlayersListFrame = CriarElemento("ScrollingFrame", {
        Size = UDim2.new(1, -20, 0, 250),
        Position = UDim2.new(0, 10, 0, 10),
        BackgroundColor3 = SHAKA_CONFIG.COR_PRETO_CLARO,
        BorderSizePixel = 1,
        ScrollBarThickness = 5,
        CanvasSize = UDim2.new(0, 0, 0, 0),
        Parent = TabFrames["Teleport"]
    })

    local SelectedPlayerLabel = CriarElemento("TextLabel", {
        Size = UDim2.new(1, -20, 0, 30),
        Position = UDim2.new(0, 10, 0, 270),
        BackgroundTransparency = 1,
        Text = "Selecionado: Nenhum",
        TextColor3 = Color3.new(1, 1, 1),
        TextScaled = true,
        Font = Enum.Font.Gotham,
        Parent = TabFrames["Teleport"]
    })

    local TPButton = CriarElemento("TextButton", {
        Size = UDim2.new(1, -20, 0, 40),
        Position = UDim2.new(0, 10, 0, 310),
        BackgroundColor3 = SHAKA_CONFIG.COR_ROXO,
        TextColor3 = Color3.new(1, 1, 1),
        Text = "TELEPORTAR PARA PLAYER",
        TextScaled = true,
        Font = Enum.Font.GothamBold,
        Parent = TabFrames["Teleport"]
    })

    -- Função para atualizar lista de players
    local function AtualizarListaPlayers()
        PlayersListFrame:ClearAllChildren()
        local posY = 0
        
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= LocalPlayer then
                local PlayerButton = CriarElemento("TextButton", {
                    Size = UDim2.new(1, -10, 0, 40),
                    Position = UDim2.new(0, 5, 0, posY),
                    BackgroundColor3 = SHAKA_CONFIG.COR_PRETO,
                    BorderColor3 = SHAKA_CONFIG.COR_CINZA,
                    Text = "👤 " .. player.Name,
                    TextColor3 = Color3.new(1, 1, 1),
                    TextScaled = true,
                    Font = Enum.Font.Gotham,
                    Parent = PlayersListFrame
                })

                PlayerButton.MouseButton1Click:Connect(function()
                    SelectedPlayer = player
                    SelectedPlayerLabel.Text = "Selecionado: " .. player.Name
                    -- Destacar botão
                    for _, btn in ipairs(PlayersListFrame:GetChildren()) do
                        if btn:IsA("TextButton") then
                            AnimacaoSuave(btn, {BackgroundColor3 = SHAKA_CONFIG.COR_PRETO}, 0.2)
                        end
                    end
                    AnimacaoSuave(PlayerButton, {BackgroundColor3 = SHAKA_CONFIG.COR_ROXO}, 0.2)
                end)

                posY = posY + 45
            end
        end
        
        PlayersListFrame.CanvasSize = UDim2.new(0, 0, 0, posY)
    end

    TPButton.MouseButton1Click:Connect(function()
        if SelectedPlayer and SelectedPlayer.Character and SelectedPlayer.Character:FindFirstChild("HumanoidRootPart") then
            LocalPlayer.Character:SetPrimaryPartCFrame(SelectedPlayer.Character.HumanoidRootPart.CFrame)
            Log("Teleportado para: " .. SelectedPlayer.Name)
        else
            Log("Erro: Player não encontrado")
        end
    end)

    -- Conteúdo da aba Visuals
    local VisualsToggles = {}
    VisualsToggles.Fullbright = CriarToggle("Fullbright", "Iluminação total", 10, function(estado)
        AtivarFullbright(estado)
        Log("Fullbright: " .. (estado and "ON" or "OFF"))
    end, false)

    VisualsToggles.FPSBoost = CriarToggle("Otimizar FPS", "Melhorar performance", 80, function(estado)
        OtimizarFPS(estado)
        Log("FPS Boost: " .. (estado and "ON" or "OFF"))
    end, false)

    -- Sistema de arrastar
    local function IniciarArraste(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            Dragging = true
            DragStart = input.Position
            local startingPosition = MainContainer.Position
            local connection = RunService.Heartbeat:Connect(function()
                if Dragging then
                    local delta = input.Position - DragStart
                    MainContainer.Position = UDim2.new(
                        startingPosition.X.Scale,
                        startingPosition.X.Offset + delta.X,
                        startingPosition.Y.Scale,
                        startingPosition.Y.Offset + delta.Y
                    )
                else
                    connection:Disconnect()
                end
            end)
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    Dragging = false
                    MenuPosition = MainContainer.Position
                end
            end)
        end
    end

    Header.InputBegan:Connect(IniciarArraste)

    -- Botões do header
    MinimizeButton.MouseButton1Click:Connect(function()
        MenuVisible = not MenuVisible
        if MenuVisible then
            AnimacaoSuave(MainContainer, {Size = UDim2.new(0, 600, 0, 400)}, 0.3)
        else
            AnimacaoSuave(MainContainer, {Size = UDim2.new(0, 120, 0, 35)}, 0.3)
        end
    end)

    CloseButton.MouseButton1Click:Connect(function()
        GUI:Destroy()
        GUI = nil
    end)

    -- Atualizar lista de players periodicamente
    table.insert(Connections, RunService.Heartbeat:Connect(function()
        AtualizarListaPlayers()
    end))

    -- Ajustar tamanho do conteúdo
    for _, frame in pairs(TabFrames) do
        frame.CanvasSize = UDim2.new(0, 0, 0, 400)
    end

    return GUI
end

-- Sistema ESP Avançado
local ESPConfig = {
    Box = true,
    Tracer = true,
    Names = true,
    Distance = true
}

local function AtivarESP()
    DesativarESP()
    
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            CriarESP(player.Character, player.Name)
        end
    end
    
    table.insert(Connections, Players.PlayerAdded:Connect(function(player)
        player.CharacterAdded:Connect(function(character)
            wait(1)
            CriarESP(character, player.Name)
        end)
    end))
end

local function CriarESP(character, nome)
    if ESP_Objects[character] then return end
    
    local espFolder = Instance.new("Folder")
    espFolder.Name = "SHAKA_ESP"
    espFolder.Parent = character
    
    -- ESP Box
    if ESPConfig.Box then
        local highlight = Instance.new("Highlight")
        highlight.Name = "Box"
        highlight.FillColor = SHAKA_CONFIG.COR_ROXO
        highlight.FillTransparency = 0.8
        highlight.OutlineColor = Color3.new(1, 1, 1)
        highlight.OutlineTransparency = 0
        highlight.Parent = espFolder
        highlight.Adornee = character
    end
    
    -- ESP Tracer
    if ESPConfig.Tracer then
        local tracer = Instance.new("LineHandleAdornment")
        tracer.Name = "Tracer"
        tracer.Color3 = SHAKA_CONFIG.COR_ROXO
        tracer.Thickness = 2
        tracer.ZIndex = 10
        tracer.Parent = espFolder
        
        table.insert(Connections, RunService.Heartbeat:Connect(function()
            if character and character:FindFirstChild("HumanoidRootPart") and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                tracer.Adornee = character.HumanoidRootPart
                tracer.Length = (character.HumanoidRootPart.Position - LocalPlayer.Character.HumanoidRootPart.Position).Magnitude
                tracer.CFrame = CFrame.new(character.HumanoidRootPart.Position, LocalPlayer.Character.HumanoidRootPart.Position)
            end
        end))
    end
    
    -- Nome e Distância
    if ESPConfig.Names then
        local billboard = Instance.new("BillboardGui")
        billboard.Name = "NameTag"
        billboard.Size = UDim2.new(0, 200, 0, 50)
        billboard.StudsOffset = Vector3.new(0, 3, 0)
        billboard.AlwaysOnTop = true
        billboard.Parent = espFolder
        
        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(1, 0, 1, 0)
        label.BackgroundTransparency = 1
        label.Text = nome .. (ESPConfig.Distance and "" or "")
        label.TextColor3 = Color3.new(1, 1, 1)
        label.TextScaled = true
        label.Font = Enum.Font.GothamBold
        label.Parent = billboard
        
        -- Atualizar distância
        if ESPConfig.Distance then
            table.insert(Connections, RunService.Heartbeat:Connect(function()
                if character and character:FindFirstChild("HumanoidRootPart") and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                    local distancia = math.floor((character.HumanoidRootPart.Position - LocalPlayer.Character.HumanoidRootPart.Position).Magnitude)
                    label.Text = nome .. " [" .. distancia .. "m]"
                end
            end))
        end
    end
    
    ESP_Objects[character] = espFolder
end

local function DesativarESP()
    for _, espFolder in pairs(ESP_Objects) do
        espFolder:Destroy()
    end
    ESP_Objects = {}
    
    for _, player in ipairs(Players:GetPlayers()) do
        if player.Character then
            local esp = player.Character:FindFirstChild("SHAKA_ESP")
            if esp then esp:Destroy() end
        end
    end
end

local function AtualizarESP()
    DesativarESP()
    AtivarESP()
end

-- Funções do Player
local function AtivarFly(estado)
    if estado then
        local bodyVelocity = Instance.new("BodyVelocity")
        bodyVelocity.Name = "SHAKA_Fly"
        bodyVelocity.Velocity = Vector3.new(0, 0, 0)
        bodyVelocity.MaxForce = Vector3.new(0, 0, 0)
        
        local connection = RunService.Heartbeat:Connect(function()
            if FlyEnabled and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                local root = LocalPlayer.Character.HumanoidRootPart
                bodyVelocity.Parent = root
                bodyVelocity.MaxForce = Vector3.new(40000, 40000, 40000)
                
                local camera = workspace.CurrentCamera
                local direction = Vector3.new()
                
                if UserInputService:IsKeyDown(Enum.KeyCode.W) then
                    direction = direction + camera.CFrame.LookVector
                end
                if UserInputService:IsKeyDown(Enum.KeyCode.S) then
                    direction = direction - camera.CFrame.LookVector
                end
                if UserInputService:IsKeyDown(Enum.KeyCode.A) then
                    direction = direction - camera.CFrame.RightVector
                end
                if UserInputService:IsKeyDown(Enum.KeyCode.D) then
                    direction = direction + camera.CFrame.RightVector
                end
                if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
                    direction = direction + Vector3.new(0, 1, 0)
                end
                if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then
                    direction = direction - Vector3.new(0, 1, 0)
                end
                
                bodyVelocity.Velocity = direction * 50
            else
                bodyVelocity:Destroy()
                connection:Disconnect()
            end
        end)
        
        table.insert(Connections, connection)
    else
        if LocalPlayer.Character then
            local fly = LocalPlayer.Character:FindFirstChild("SHAKA_Fly")
            if fly then fly:Destroy() end
        end
    end
end

local function AtivarPuloInfinito(estado)
    if estado then
        local connection = UserInputService.JumpRequest:Connect(function()
            if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
                LocalPlayer.Character.Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
            end
        end)
        table.insert(Connections, connection)
    end
end

local function AtivarSuperVelocidade(estado)
    if estado then
        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
            LocalPlayer.Character.Humanoid.WalkSpeed = 50
        end
    else
        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
            LocalPlayer.Character.Humanoid.WalkSpeed = 16
        end
    end
end

local function FicarInvisivel(estado)
    if estado then
        if LocalPlayer.Character then
            for _, part in ipairs(LocalPlayer.Character:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.Transparency = 1
                end
            end
        end
    else
        if LocalPlayer.Character then
            for _, part in ipairs(LocalPlayer.Character:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.Transparency = 0
                end
            end
        end
    end
end

local function AtivarFullbright(estado)
    if estado then
        Lighting.Brightness = 2
        Lighting.ClockTime = 14
        Lighting.FogEnd = 100000
        Lighting.GlobalShadows = false
    else
        Lighting.Brightness = 1
        Lighting.ClockTime = 14
        Lighting.FogEnd = 100000
        Lighting.GlobalShadows = true
    end
end

local function OtimizarFPS(estado)
    if estado then
        settings().Rendering.QualityLevel = 1
        for _, effect in ipairs(workspace:GetDescendants()) do
            if effect:IsA("ParticleEmitter") or effect:IsA("Fire") or effect:IsA("Smoke") then
                effect.Enabled = false
            end
        end
    else
        settings().Rendering.QualityLevel = 10
        for _, effect in ipairs(workspace:GetDescendants()) do
            if effect:IsA("ParticleEmitter") or effect:IsA("Fire") or effect:IsA("Smoke") then
                effect.Enabled = true
            end
        end
    end
end

-- Sistema Noclip
table.insert(Connections, RunService.Stepped:Connect(function()
    if NoclipEnabled and LocalPlayer.Character then
        for _, part in ipairs(LocalPlayer.Character:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanCollide = false
            end
        end
    end
end))

-- Inicialização
Log("Iniciando SHAKA Hub Premium...")
wait(2)

-- Criar GUI
CriarGUI()

-- Toggle com F
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    
    if input.KeyCode == Enum.KeyCode.F then
        if GUI then
            GUI:Destroy()
            GUI = nil
            Log("Menu fechado")
        else
            CriarGUI()
            Log("Menu aberto")
        end
    end
end)

Log("SHAKA Hub Premium carregado! Pressione F para abrir/fechar")
