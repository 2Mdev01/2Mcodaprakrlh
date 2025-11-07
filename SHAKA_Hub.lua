-- SHAKA Hub Premium - Menu Completo
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

-- Configurações
local SHAKA_CONFIG = {
    NOME = "SHAKA",
    VERSAO = "v2.0 Premium",
    COR_ROXO = Color3.fromRGB(128, 0, 128),
    COR_ROXO_CLARO = Color3.fromRGB(160, 50, 160),
    COR_PRETO = Color3.fromRGB(20, 20, 20),
    COR_PRETO_CLARO = Color3.fromRGB(40, 40, 40)
}

-- Variáveis globais
local GUI = nil
local Connections = {}
local ESP_Objects = {}
local SelectedPlayer = nil
local FlyEnabled = false
local NoclipEnabled = false

-- Função para criar elementos com animação
local function CriarElemento(tipo, propriedades)
    local elemento = Instance.new(tipo)
    for prop, valor in pairs(propriedades) do
        elemento[prop] = valor
    end
    return elemento
end

-- Sistema de logging
local function Log(mensagem)
    print("🟣 [SHAKA] " .. mensagem)
end

-- Função para criar animação suave
local function AnimacaoSuave(elemento, propriedade, valorFinal, duracao)
    local tweenInfo = TweenInfo.new(duracao, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    local tween = TweenService:Create(elemento, tweenInfo, {[propriedade] = valorFinal})
    tween:Play()
    return tween
end

-- Criar GUI principal
local function CriarGUI()
    -- Remover GUI existente
    if GUI then
        GUI:Destroy()
        GUI = nil
    end

    -- Criar GUI principal
    GUI = CriarElemento("ScreenGui", {
        Name = "SHAKAHub",
        Parent = LocalPlayer:WaitForChild("PlayerGui"),
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    })

    -- Frame principal
    local MainFrame = CriarElemento("Frame", {
        Name = "MainFrame",
        Size = UDim2.new(0, 450, 0, 500),
        Position = UDim2.new(0.5, -225, 0.5, -250),
        BackgroundColor3 = SHAKA_CONFIG.COR_PRETO,
        BorderColor3 = SHAKA_CONFIG.COR_ROXO,
        BorderSizePixel = 2,
        Parent = GUI
    })

    -- Adicionar sombra
    local Shadow = CriarElemento("Frame", {
        Name = "Shadow",
        Size = UDim2.new(1, 10, 1, 10),
        Position = UDim2.new(0, -5, 0, -5),
        BackgroundColor3 = Color3.new(0, 0, 0),
        BackgroundTransparency = 0.8,
        BorderSizePixel = 0,
        Parent = MainFrame,
        ZIndex = -1
    })

    -- Header
    local Header = CriarElemento("Frame", {
        Name = "Header",
        Size = UDim2.new(1, 0, 0, 50),
        BackgroundColor3 = SHAKA_CONFIG.COR_ROXO,
        BorderSizePixel = 0,
        Parent = MainFrame
    })

    local Title = CriarElemento("TextLabel", {
        Name = "Title",
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        Text = SHAKA_CONFIG.NOME .. " HUB " .. SHAKA_CONFIG.VERSAO,
        TextColor3 = Color3.new(1, 1, 1),
        TextScaled = true,
        Font = Enum.Font.GothamBold,
        Parent = Header
    })

    -- Botão fechar
    local CloseButton = CriarElemento("TextButton", {
        Name = "CloseButton",
        Size = UDim2.new(0, 30, 0, 30),
        Position = UDim2.new(1, -35, 0, 10),
        BackgroundColor3 = Color3.new(1, 0, 0),
        TextColor3 = Color3.new(1, 1, 1),
        Text = "X",
        TextScaled = true,
        Font = Enum.Font.GothamBold,
        Parent = Header
    })

    CloseButton.MouseButton1Click:Connect(function()
        GUI:Destroy()
        GUI = nil
    end)

    -- Abas
    local TabsFrame = CriarElemento("Frame", {
        Name = "TabsFrame",
        Size = UDim2.new(1, 0, 0, 40),
        Position = UDim2.new(0, 0, 0, 50),
        BackgroundColor3 = SHAKA_CONFIG.COR_PRETO_CLARO,
        BorderSizePixel = 0,
        Parent = MainFrame
    })

    local Tabs = {"Player", "ESP", "Teleport", "Visuals"}
    local CurrentTab = "Player"
    local ContentFrames = {}

    -- Criar botões das abas
    for i, tabName in ipairs(Tabs) do
        local TabButton = CriarElemento("TextButton", {
            Name = tabName .. "Tab",
            Size = UDim2.new(1/#Tabs, 0, 1, 0),
            Position = UDim2.new((i-1)/#Tabs, 0, 0, 0),
            BackgroundColor3 = SHAKA_CONFIG.COR_PRETO_CLARO,
            TextColor3 = Color3.new(1, 1, 1),
            Text = tabName,
            TextScaled = true,
            Font = Enum.Font.Gotham,
            Parent = TabsFrame
        })

        -- Frame de conteúdo para cada aba
        local ContentFrame = CriarElemento("ScrollingFrame", {
            Name = tabName .. "Content",
            Size = UDim2.new(1, -20, 1, -100),
            Position = UDim2.new(0, 10, 0, 90),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            ScrollBarThickness = 5,
            CanvasSize = UDim2.new(0, 0, 0, 0),
            Visible = false,
            Parent = MainFrame
        })

        ContentFrames[tabName] = ContentFrame

        TabButton.MouseButton1Click:Connect(function()
            CurrentTab = tabName
            for name, frame in pairs(ContentFrames) do
                frame.Visible = (name == tabName)
            end
            -- Atualizar cores dos botões
            for _, btn in ipairs(TabsFrame:GetChildren()) do
                if btn:IsA("TextButton") then
                    btn.BackgroundColor3 = SHAKA_CONFIG.COR_PRETO_CLARO
                end
            end
            TabButton.BackgroundColor3 = SHAKA_CONFIG.COR_ROXO_CLARO
        end)

        if i == 1 then
            TabButton.BackgroundColor3 = SHAKA_CONFIG.COR_ROXO_CLARO
            ContentFrame.Visible = true
        end
    end

    -- Conteúdo da aba Player
    local PlayerContent = ContentFrames["Player"]
    
    local function CriarToggle(nome, posicao, callback)
        local ToggleFrame = CriarElemento("Frame", {
            Size = UDim2.new(1, -20, 0, 40),
            Position = UDim2.new(0, 10, 0, posicao),
            BackgroundColor3 = SHAKA_CONFIG.COR_PRETO_CLARO,
            BorderSizePixel = 0,
            Parent = PlayerContent
        })

        local ToggleLabel = CriarElemento("TextLabel", {
            Size = UDim2.new(0.7, 0, 1, 0),
            BackgroundTransparency = 1,
            Text = nome,
            TextColor3 = Color3.new(1, 1, 1),
            TextXAlignment = Enum.TextXAlignment.Left,
            TextScaled = true,
            Font = Enum.Font.Gotham,
            Parent = ToggleFrame
        })

        local ToggleButton = CriarElemento("TextButton", {
            Size = UDim2.new(0, 60, 0, 30),
            Position = UDim2.new(1, -70, 0.5, -15),
            BackgroundColor3 = Color3.fromRGB(255, 0, 0),
            Text = "OFF",
            TextColor3 = Color3.new(1, 1, 1),
            TextScaled = true,
            Font = Enum.Font.GothamBold,
            Parent = ToggleFrame
        })

        local estado = false
        
        ToggleButton.MouseButton1Click:Connect(function()
            estado = not estado
            if estado then
                ToggleButton.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
                ToggleButton.Text = "ON"
            else
                ToggleButton.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
                ToggleButton.Text = "OFF"
            end
            callback(estado)
        end)

        return {Frame = ToggleFrame, SetState = function(state)
            estado = state
            if estado then
                ToggleButton.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
                ToggleButton.Text = "ON"
            else
                ToggleButton.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
                ToggleButton.Text = "OFF"
            end
            callback(estado)
        end}
    end

    -- Funções Player
    local NoclipToggle = CriarToggle("Noclip", 10, function(estado)
        NoclipEnabled = estado
        Log("Noclip: " .. (estado and "ON" or "OFF"))
    end)

    local FlyToggle = CriarToggle("Fly", 60, function(estado)
        FlyEnabled = estado
        AtivarFly(estado)
        Log("Fly: " .. (estado and "ON" or "OFF"))
    end)

    local InfJumpToggle = CriarToggle("Pulo Infinito", 110, function(estado)
        AtivarPuloInfinito(estado)
        Log("Pulo Infinito: " .. (estado and "ON" or "OFF"))
    end)

    local SpeedToggle = CriarToggle("Super Velocidade", 160, function(estado)
        AtivarSuperVelocidade(estado)
        Log("Super Velocidade: " .. (estado and "ON" or "OFF"))
    end)

    local InvisToggle = CriarToggle("Ficar Invisível", 210, function(estado)
        FicarInvisivel(estado)
        Log("Invisibilidade: " .. (estado and "ON" or "OFF"))
    end)

    -- Conteúdo da aba ESP
    local ESPContent = ContentFrames["ESP"]
    
    local ESPToggle = CriarToggle("Ativar ESP", 10, function(estado)
        if estado then
            AtivarESP()
        else
            DesativarESP()
        end
        Log("ESP: " .. (estado and "ON" or "OFF"))
    end)

    local ESPPlayersToggle = CriarToggle("ESP Players", 60, function(estado)
        ESPConfig.Players = estado
        AtualizarESP()
        Log("ESP Players: " .. (estado and "ON" or "OFF"))
    end)

    local ESPNamesToggle = CriarToggle("Mostrar Nomes", 110, function(estado)
        ESPConfig.Nomes = estado
        AtualizarESP()
        Log("Nomes ESP: " .. (estado and "ON" or "OFF"))
    end)

    -- Conteúdo da aba Teleport
    local TeleportContent = ContentFrames["Teleport"]
    
    -- Lista de players
    local PlayersList = CriarElemento("ScrollingFrame", {
        Size = UDim2.new(1, -20, 0, 200),
        Position = UDim2.new(0, 10, 0, 10),
        BackgroundColor3 = SHAKA_CONFIG.COR_PRETO_CLARO,
        BorderSizePixel = 0,
        ScrollBarThickness = 5,
        CanvasSize = UDim2.new(0, 0, 0, 0),
        Parent = TeleportContent
    })

    local TPButton = CriarElemento("TextButton", {
        Size = UDim2.new(1, -20, 0, 40),
        Position = UDim2.new(0, 10, 0, 220),
        BackgroundColor3 = SHAKA_CONFIG.COR_ROXO,
        TextColor3 = Color3.new(1, 1, 1),
        Text = "TELEPORTAR PARA PLAYER",
        TextScaled = true,
        Font = Enum.Font.GothamBold,
        Parent = TeleportContent
    })

    local SelectedPlayerLabel = CriarElemento("TextLabel", {
        Size = UDim2.new(1, -20, 0, 30),
        Position = UDim2.new(0, 10, 0, 270),
        BackgroundTransparency = 1,
        Text = "Selecionado: Nenhum",
        TextColor3 = Color3.new(1, 1, 1),
        TextScaled = true,
        Font = Enum.Font.Gotham,
        Parent = TeleportContent
    })

    -- Atualizar lista de players
    local function AtualizarListaPlayers()
        PlayersList:ClearAllChildren()
        local posY = 0
        
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= LocalPlayer then
                local PlayerButton = CriarElemento("TextButton", {
                    Size = UDim2.new(1, -10, 0, 30),
                    Position = UDim2.new(0, 5, 0, posY),
                    BackgroundColor3 = SHAKA_CONFIG.COR_PRETO,
                    TextColor3 = Color3.new(1, 1, 1),
                    Text = player.Name,
                    TextScaled = true,
                    Font = Enum.Font.Gotham,
                    Parent = PlayersList
                })

                PlayerButton.MouseButton1Click:Connect(function()
                    SelectedPlayer = player
                    SelectedPlayerLabel.Text = "Selecionado: " .. player.Name
                    -- Destacar botão
                    for _, btn in ipairs(PlayersList:GetChildren()) do
                        if btn:IsA("TextButton") then
                            btn.BackgroundColor3 = SHAKA_CONFIG.COR_PRETO
                        end
                    end
                    PlayerButton.BackgroundColor3 = SHAKA_CONFIG.COR_ROXO_CLARO
                end)

                posY = posY + 35
            end
        end
        
        PlayersList.CanvasSize = UDim2.new(0, 0, 0, posY)
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
    local VisualsContent = ContentFrames["Visuals"]
    
    local FullbrightToggle = CriarToggle("Fullbright", 10, function(estado)
        AtivarFullbright(estado)
        Log("Fullbright: " .. (estado and "ON" or "OFF"))
    end)

    local FPSBoostToggle = CriarToggle("Otimizar FPS", 60, function(estado)
        OtimizarFPS(estado)
        Log("FPS Boost: " .. (estado and "ON" or "OFF"))
    end)

    -- Atualizar lista de players periodicamente
    table.insert(Connections, RunService.Heartbeat:Connect(function()
        AtualizarListaPlayers()
    end))

    -- Ajustar tamanho do conteúdo
    PlayerContent.CanvasSize = UDim2.new(0, 0, 0, 300)
    ESPContent.CanvasSize = UDim2.new(0, 0, 0, 200)
    TeleportContent.CanvasSize = UDim2.new(0, 0, 0, 320)
    VisualsContent.CanvasSize = UDim2.new(0, 0, 0, 150)

    return GUI
end

-- Sistema ESP
local ESPConfig = {
    Players = true,
    Nomes = true
}

local function AtivarESP()
    DesativarESP() -- Limpar ESP anterior
    
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            CriarESP(player.Character, player.Name)
        end
    end
    
    -- Conectar para novos players
    table.insert(Connections, Players.PlayerAdded:Connect(function(player)
        player.CharacterAdded:Connect(function(character)
            wait(1)
            if ESPConfig.Players then
                CriarESP(character, player.Name)
            end
        end)
    end))
    
    -- Conectar para caracteres existentes
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            player.CharacterAdded:Connect(function(character)
                wait(1)
                if ESPConfig.Players then
                    CriarESP(character, player.Name)
                end
            end)
        end
    end
end

local function CriarESP(character, nome)
    if ESP_Objects[character] then return end
    
    local highlight = Instance.new("Highlight")
    highlight.Name = "SHAKA_ESP"
    highlight.FillColor = SHAKA_CONFIG.COR_ROXO
    highlight.FillTransparency = 0.8
    highlight.OutlineColor = Color3.new(1, 1, 1)
    highlight.OutlineTransparency = 0
    highlight.Parent = character
    highlight.Adornee = character
    
    if ESPConfig.Nomes then
        local billboard = Instance.new("BillboardGui")
        billboard.Name = "SHAKA_NameTag"
        billboard.Size = UDim2.new(0, 200, 0, 50)
        billboard.StudsOffset = Vector3.new(0, 3, 0)
        billboard.AlwaysOnTop = true
        billboard.Parent = character
        
        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(1, 0, 1, 0)
        label.BackgroundTransparency = 1
        label.Text = nome
        label.TextColor3 = Color3.new(1, 1, 1)
        label.TextScaled = true
        label.Font = Enum.Font.GothamBold
        label.Parent = billboard
    end
    
    ESP_Objects[character] = {Highlight = highlight}
end

local function DesativarESP()
    for _, data in pairs(ESP_Objects) do
        if data.Highlight then
            data.Highlight:Destroy()
        end
    end
    ESP_Objects = {}
    
    -- Limpar todos os ESPs do jogo
    for _, player in ipairs(Players:GetPlayers()) do
        if player.Character then
            local esp = player.Character:FindFirstChild("SHAKA_ESP")
            if esp then esp:Destroy() end
            local nameTag = player.Character:FindFirstChild("SHAKA_NameTag")
            if nameTag then nameTag:Destroy() end
        end
    end
end

local function AtualizarESP()
    DesativarESP()
    if ESPConfig.Players then
        AtivarESP()
    end
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
    else
        -- A conexão será limpa quando desativada
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
Log("Iniciando SHAKA Hub...")
wait(1)

-- Criar GUI
CriarGUI()

-- Limpeza quando o script for destruído
LocalPlayer.CharacterAdded:Connect(function()
    wait(1)
    if not GUI then
        CriarGUI()
    end
end)

Log("SHAKA Hub carregado com sucesso! Pressione F para abrir/fechar")

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
