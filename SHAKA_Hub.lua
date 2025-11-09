-- SHAKA Hub Premium v4.0 - Menu Profissional Melhorado
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")
local Camera = workspace.CurrentCamera

-- ═══════════════════════════════════════════════════════════
-- CONFIGURAÇÕES
-- ═══════════════════════════════════════════════════════════
local SHAKA_CONFIG = {
    NOME = "SHAKA",
    VERSAO = "v4.0 Premium",
    COR_PRIMARIA = Color3.fromRGB(147, 51, 234),
    COR_SECUNDARIA = Color3.fromRGB(109, 40, 217),
    COR_HOVER = Color3.fromRGB(168, 85, 247),
    COR_FUNDO = Color3.fromRGB(17, 17, 27),
    COR_FUNDO_SECUNDARIO = Color3.fromRGB(23, 23, 37),
    COR_TEXTO = Color3.fromRGB(255, 255, 255),
    COR_TEXTO_SEC = Color3.fromRGB(156, 163, 175),
    COR_SUCESSO = Color3.fromRGB(34, 197, 94),
    COR_ERRO = Color3.fromRGB(239, 68, 68)
}

-- ═══════════════════════════════════════════════════════════
-- VARIÁVEIS GLOBAIS
-- ═══════════════════════════════════════════════════════════
local GUI = nil
local Connections = {}
local ESP_Objects = {}
local SelectedPlayer = nil
local SelectedPlayerForAction = nil
local FlyEnabled = false
local NoclipEnabled = false
local InfJumpEnabled = false
local SpeedEnabled = false
local InvisEnabled = false
local GodmodeEnabled = false
local MenuVisible = true
local Dragging = false
local DragStart = nil
local MenuPosition = UDim2.new(0.5, -350, 0.5, -250)
local CurrentSpeed = 16
local CurrentJumpPower = 50

-- ═══════════════════════════════════════════════════════════
-- FUNÇÕES AUXILIARES
-- ═══════════════════════════════════════════════════════════
local function Log(mensagem)
    print("🟣 [SHAKA] " .. mensagem)
end

local function CriarElemento(tipo, propriedades)
    local elemento = Instance.new(tipo)
    for prop, valor in pairs(propriedades) do
        elemento[prop] = valor
    end
    return elemento
end

local function AnimacaoSuave(elemento, propriedades, duracao)
    local tweenInfo = TweenInfo.new(duracao or 0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    local tween = TweenService:Create(elemento, tweenInfo, propriedades)
    tween:Play()
    return tween
end

local function CriarSombra(parent)
    local sombra = CriarElemento("ImageLabel", {
        Name = "Shadow",
        Size = UDim2.new(1, 30, 1, 30),
        Position = UDim2.new(0, -15, 0, -15),
        BackgroundTransparency = 1,
        Image = "rbxasset://textures/ui/GuiImagePlaceholder.png",
        ImageColor3 = Color3.new(0, 0, 0),
        ImageTransparency = 0.7,
        ZIndex = -1,
        Parent = parent
    })
    return sombra
end

local function CriarNotificacao(texto, tipo)
    local cor = tipo == "sucesso" and SHAKA_CONFIG.COR_SUCESSO or 
                tipo == "erro" and SHAKA_CONFIG.COR_ERRO or 
                SHAKA_CONFIG.COR_PRIMARIA
    
    local notif = CriarElemento("Frame", {
        Size = UDim2.new(0, 300, 0, 60),
        Position = UDim2.new(1, -320, 1, -80),
        BackgroundColor3 = SHAKA_CONFIG.COR_FUNDO_SECUNDARIO,
        BorderSizePixel = 0,
        Parent = GUI
    })
    
    local barra = CriarElemento("Frame", {
        Size = UDim2.new(0, 4, 1, 0),
        BackgroundColor3 = cor,
        BorderSizePixel = 0,
        Parent = notif
    })
    
    local label = CriarElemento("TextLabel", {
        Size = UDim2.new(1, -20, 1, 0),
        Position = UDim2.new(0, 15, 0, 0),
        BackgroundTransparency = 1,
        Text = texto,
        TextColor3 = SHAKA_CONFIG.COR_TEXTO,
        TextSize = 14,
        Font = Enum.Font.Gotham,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextWrapped = true,
        Parent = notif
    })
    
    AnimacaoSuave(notif, {Position = UDim2.new(1, -320, 1, -80)}, 0.5)
    
    task.wait(3)
    AnimacaoSuave(notif, {Position = UDim2.new(1, 20, 1, -80)}, 0.5)
    task.wait(0.5)
    notif:Destroy()
end

-- ═══════════════════════════════════════════════════════════
-- CRIAÇÃO DA GUI MODERNA
-- ═══════════════════════════════════════════════════════════
local function CriarGUI()
    if GUI then
        GUI:Destroy()
        GUI = nil
    end

    -- GUI Principal
    GUI = CriarElemento("ScreenGui", {
        Name = "SHAKAHub",
        Parent = LocalPlayer:WaitForChild("PlayerGui"),
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        ResetOnSpawn = false
    })

    -- Container Principal com bordas arredondadas
    local MainContainer = CriarElemento("Frame", {
        Name = "MainContainer",
        Size = UDim2.new(0, 700, 0, 500),
        Position = MenuPosition,
        BackgroundColor3 = SHAKA_CONFIG.COR_FUNDO,
        BorderSizePixel = 0,
        ClipsDescendants = true,
        Parent = GUI
    })
    
    local cornerMain = CriarElemento("UICorner", {
        CornerRadius = UDim.new(0, 12),
        Parent = MainContainer
    })

    -- Borda gradiente
    local bordaGradiente = CriarElemento("UIStroke", {
        Color = SHAKA_CONFIG.COR_PRIMARIA,
        Thickness = 2,
        Transparency = 0.5,
        Parent = MainContainer
    })

    -- Header Premium
    local Header = CriarElemento("Frame", {
        Name = "Header",
        Size = UDim2.new(1, 0, 0, 60),
        BackgroundColor3 = SHAKA_CONFIG.COR_FUNDO_SECUNDARIO,
        BorderSizePixel = 0,
        Parent = MainContainer
    })
    
    local cornerHeader = CriarElemento("UICorner", {
        CornerRadius = UDim.new(0, 12),
        Parent = Header
    })

    -- Logo com ícone
    local LogoContainer = CriarElemento("Frame", {
        Size = UDim2.new(0, 180, 0, 40),
        Position = UDim2.new(0, 20, 0, 10),
        BackgroundTransparency = 1,
        Parent = Header
    })
    
    local LogoIcon = CriarElemento("TextLabel", {
        Size = UDim2.new(0, 40, 0, 40),
        BackgroundTransparency = 1,
        Text = "🟣",
        TextSize = 28,
        Font = Enum.Font.GothamBold,
        Parent = LogoContainer
    })
    
    local LogoText = CriarElemento("TextLabel", {
        Size = UDim2.new(0, 120, 0, 40),
        Position = UDim2.new(0, 45, 0, 0),
        BackgroundTransparency = 1,
        Text = "SHAKA",
        TextColor3 = SHAKA_CONFIG.COR_TEXTO,
        TextSize = 22,
        Font = Enum.Font.GothamBold,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = LogoContainer
    })

    -- Badge de versão
    local VersionBadge = CriarElemento("Frame", {
        Size = UDim2.new(0, 100, 0, 25),
        Position = UDim2.new(0, 210, 0, 17),
        BackgroundColor3 = SHAKA_CONFIG.COR_PRIMARIA,
        BorderSizePixel = 0,
        Parent = Header
    })
    
    local cornerVersion = CriarElemento("UICorner", {
        CornerRadius = UDim.new(0, 6),
        Parent = VersionBadge
    })
    
    local VersionLabel = CriarElemento("TextLabel", {
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        Text = SHAKA_CONFIG.VERSAO,
        TextColor3 = SHAKA_CONFIG.COR_TEXTO,
        TextSize = 12,
        Font = Enum.Font.GothamBold,
        Parent = VersionBadge
    })

    -- Botões do Header (Minimizar e Fechar)
    local function CriarBotaoHeader(texto, cor, posX)
        local btn = CriarElemento("TextButton", {
            Size = UDim2.new(0, 35, 0, 35),
            Position = UDim2.new(1, posX, 0, 12),
            BackgroundColor3 = cor,
            Text = texto,
            TextColor3 = SHAKA_CONFIG.COR_TEXTO,
            TextSize = 18,
            Font = Enum.Font.GothamBold,
            BorderSizePixel = 0,
            Parent = Header
        })
        
        local corner = CriarElemento("UICorner", {
            CornerRadius = UDim.new(0, 8),
            Parent = btn
        })
        
        btn.MouseEnter:Connect(function()
            AnimacaoSuave(btn, {BackgroundColor3 = Color3.fromRGB(
                math.min(cor.R * 255 * 1.2, 255),
                math.min(cor.G * 255 * 1.2, 255),
                math.min(cor.B * 255 * 1.2, 255)
            )}, 0.2)
        end)
        
        btn.MouseLeave:Connect(function()
            AnimacaoSuave(btn, {BackgroundColor3 = cor}, 0.2)
        end)
        
        return btn
    end

    local MinimizeButton = CriarBotaoHeader("─", SHAKA_CONFIG.COR_SECUNDARIA, -90)
    local CloseButton = CriarBotaoHeader("×", SHAKA_CONFIG.COR_ERRO, -50)

    -- Container do Conteúdo
    local ContentContainer = CriarElemento("Frame", {
        Name = "ContentContainer",
        Size = UDim2.new(1, 0, 1, -60),
        Position = UDim2.new(0, 0, 0, 60),
        BackgroundColor3 = SHAKA_CONFIG.COR_FUNDO,
        BorderSizePixel = 0,
        Parent = MainContainer
    })

    -- Menu Lateral (Abas)
    local SideMenu = CriarElemento("Frame", {
        Name = "SideMenu",
        Size = UDim2.new(0, 160, 1, 0),
        BackgroundColor3 = SHAKA_CONFIG.COR_FUNDO_SECUNDARIO,
        BorderSizePixel = 0,
        Parent = ContentContainer
    })

    -- Área de Conteúdo
    local TabContent = CriarElemento("Frame", {
        Name = "TabContent",
        Size = UDim2.new(1, -160, 1, 0),
        Position = UDim2.new(0, 160, 0, 0),
        BackgroundColor3 = SHAKA_CONFIG.COR_FUNDO,
        BorderSizePixel = 0,
        Parent = ContentContainer
    })

    -- ═══════════════════════════════════════════════════════════
    -- SISTEMA DE ABAS
    -- ═══════════════════════════════════════════════════════════
    local Tabs = {
        {Nome = "Player", Icon = "👤", Desc = "Controle seu personagem"},
        {Nome = "Combat", Icon = "⚔️", Desc = "Funções de combate"},
        {Nome = "ESP", Icon = "👁️", Desc = "Visualização de jogadores"},
        {Nome = "Teleport", Icon = "📍", Desc = "Teletransporte"},
        {Nome = "Visuals", Icon = "✨", Desc = "Efeitos visuais"},
        {Nome = "Settings", Icon = "⚙️", Desc = "Configurações"}
    }

    local CurrentTab = "Player"
    local TabFrames = {}
    local TabButtons = {}

    -- Criar botões de abas
    for i, tab in ipairs(Tabs) do
        local TabButton = CriarElemento("TextButton", {
            Name = tab.Nome .. "Tab",
            Size = UDim2.new(1, -20, 0, 55),
            Position = UDim2.new(0, 10, 0, (i-1) * 60 + 10),
            BackgroundColor3 = SHAKA_CONFIG.COR_FUNDO,
            BorderSizePixel = 0,
            Text = "",
            Parent = SideMenu
        })
        
        local cornerTab = CriarElemento("UICorner", {
            CornerRadius = UDim.new(0, 8),
            Parent = TabButton
        })
        
        local IconLabel = CriarElemento("TextLabel", {
            Size = UDim2.new(0, 30, 0, 30),
            Position = UDim2.new(0, 10, 0, 12),
            BackgroundTransparency = 1,
            Text = tab.Icon,
            TextSize = 20,
            Font = Enum.Font.GothamBold,
            Parent = TabButton
        })
        
        local NameLabel = CriarElemento("TextLabel", {
            Size = UDim2.new(1, -50, 0, 20),
            Position = UDim2.new(0, 45, 0, 10),
            BackgroundTransparency = 1,
            Text = tab.Nome,
            TextColor3 = SHAKA_CONFIG.COR_TEXTO,
            TextSize = 14,
            Font = Enum.Font.GothamBold,
            TextXAlignment = Enum.TextXAlignment.Left,
            Parent = TabButton
        })
        
        -- Frame de conteúdo para cada aba
        local ContentFrame = CriarElemento("ScrollingFrame", {
            Name = tab.Nome .. "Content",
            Size = UDim2.new(1, -20, 1, -20),
            Position = UDim2.new(0, 10, 0, 10),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            ScrollBarThickness = 4,
            ScrollBarImageColor3 = SHAKA_CONFIG.COR_PRIMARIA,
            CanvasSize = UDim2.new(0, 0, 0, 0),
            Visible = false,
            Parent = TabContent
        })
        
        local layout = CriarElemento("UIListLayout", {
            Padding = UDim.new(0, 10),
            SortOrder = Enum.SortOrder.LayoutOrder,
            Parent = ContentFrame
        })

        TabFrames[tab.Nome] = ContentFrame
        TabButtons[tab.Nome] = TabButton

        -- Eventos de clique
        TabButton.MouseButton1Click:Connect(function()
            CurrentTab = tab.Nome
            for nome, frame in pairs(TabFrames) do
                frame.Visible = (nome == tab.Nome)
            end
            for nome, btn in pairs(TabButtons) do
                if nome == tab.Nome then
                    AnimacaoSuave(btn, {BackgroundColor3 = SHAKA_CONFIG.COR_PRIMARIA}, 0.2)
                else
                    AnimacaoSuave(btn, {BackgroundColor3 = SHAKA_CONFIG.COR_FUNDO}, 0.2)
                end
            end
        end)
        
        -- Hover effects
        TabButton.MouseEnter:Connect(function()
            if CurrentTab ~= tab.Nome then
                AnimacaoSuave(TabButton, {BackgroundColor3 = SHAKA_CONFIG.COR_FUNDO_SECUNDARIO}, 0.2)
            end
        end)
        
        TabButton.MouseLeave:Connect(function()
            if CurrentTab ~= tab.Nome then
                AnimacaoSuave(TabButton, {BackgroundColor3 = SHAKA_CONFIG.COR_FUNDO}, 0.2)
            end
        end)

        if i == 1 then
            TabButton.BackgroundColor3 = SHAKA_CONFIG.COR_PRIMARIA
            ContentFrame.Visible = true
        end
    end

    -- ═══════════════════════════════════════════════════════════
    -- COMPONENTES DA UI
    -- ═══════════════════════════════════════════════════════════
    
    -- Função para criar Toggle moderno
    local function CriarToggle(nome, descricao, callback, valorPadrao, parent)
        local Container = CriarElemento("Frame", {
            Size = UDim2.new(1, 0, 0, 70),
            BackgroundColor3 = SHAKA_CONFIG.COR_FUNDO_SECUNDARIO,
            BorderSizePixel = 0,
            Parent = parent or TabFrames[CurrentTab]
        })
        
        local corner = CriarElemento("UICorner", {
            CornerRadius = UDim.new(0, 10),
            Parent = Container
        })
        
        local NameLabel = CriarElemento("TextLabel", {
            Size = UDim2.new(0.7, 0, 0, 25),
            Position = UDim2.new(0, 15, 0, 10),
            BackgroundTransparency = 1,
            Text = nome,
            TextColor3 = SHAKA_CONFIG.COR_TEXTO,
            TextSize = 16,
            Font = Enum.Font.GothamBold,
            TextXAlignment = Enum.TextXAlignment.Left,
            Parent = Container
        })
        
        local DescLabel = CriarElemento("TextLabel", {
            Size = UDim2.new(0.7, 0, 0, 20),
            Position = UDim2.new(0, 15, 0, 35),
            BackgroundTransparency = 1,
            Text = descricao,
            TextColor3 = SHAKA_CONFIG.COR_TEXTO_SEC,
            TextSize = 12,
            Font = Enum.Font.Gotham,
            TextXAlignment = Enum.TextXAlignment.Left,
            Parent = Container
        })
        
        local ToggleButton = CriarElemento("TextButton", {
            Size = UDim2.new(0, 60, 0, 30),
            Position = UDim2.new(1, -75, 0.5, -15),
            BackgroundColor3 = valorPadrao and SHAKA_CONFIG.COR_SUCESSO or Color3.fromRGB(60, 60, 70),
            Text = "",
            BorderSizePixel = 0,
            Parent = Container
        })
        
        local cornerToggle = CriarElemento("UICorner", {
            CornerRadius = UDim.new(0, 15),
            Parent = ToggleButton
        })
        
        local Knob = CriarElemento("Frame", {
            Size = UDim2.new(0, 24, 0, 24),
            Position = valorPadrao and UDim2.new(0, 33, 0, 3) or UDim2.new(0, 3, 0, 3),
            BackgroundColor3 = SHAKA_CONFIG.COR_TEXTO,
            BorderSizePixel = 0,
            Parent = ToggleButton
        })
        
        local cornerKnob = CriarElemento("UICorner", {
            CornerRadius = UDim.new(0, 12),
            Parent = Knob
        })
        
        local estado = valorPadrao or false
        
        local function AtualizarToggle()
            if estado then
                AnimacaoSuave(ToggleButton, {BackgroundColor3 = SHAKA_CONFIG.COR_SUCESSO}, 0.3)
                AnimacaoSuave(Knob, {Position = UDim2.new(0, 33, 0, 3)}, 0.3)
            else
                AnimacaoSuave(ToggleButton, {BackgroundColor3 = Color3.fromRGB(60, 60, 70)}, 0.3)
                AnimacaoSuave(Knob, {Position = UDim2.new(0, 3, 0, 3)}, 0.3)
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
            GetState = function() return estado end,
            Container = Container
        }
    end
    
    -- Função para criar Slider moderno
    local function CriarSlider(nome, min, max, valorPadrao, callback, parent)
        local Container = CriarElemento("Frame", {
            Size = UDim2.new(1, 0, 0, 80),
            BackgroundColor3 = SHAKA_CONFIG.COR_FUNDO_SECUNDARIO,
            BorderSizePixel = 0,
            Parent = parent or TabFrames[CurrentTab]
        })
        
        local corner = CriarElemento("UICorner", {
            CornerRadius = UDim.new(0, 10),
            Parent = Container
        })
        
        local NameLabel = CriarElemento("TextLabel", {
            Size = UDim2.new(0.6, 0, 0, 25),
            Position = UDim2.new(0, 15, 0, 10),
            BackgroundTransparency = 1,
            Text = nome,
            TextColor3 = SHAKA_CONFIG.COR_TEXTO,
            TextSize = 16,
            Font = Enum.Font.GothamBold,
            TextXAlignment = Enum.TextXAlignment.Left,
            Parent = Container
        })
        
        local ValueLabel = CriarElemento("TextLabel", {
            Size = UDim2.new(0.3, 0, 0, 25),
            Position = UDim2.new(0.7, 0, 0, 10),
            BackgroundTransparency = 1,
            Text = tostring(valorPadrao),
            TextColor3 = SHAKA_CONFIG.COR_PRIMARIA,
            TextSize = 16,
            Font = Enum.Font.GothamBold,
            TextXAlignment = Enum.TextXAlignment.Right,
            Parent = Container
        })
        
        local SliderFrame = CriarElemento("Frame", {
            Size = UDim2.new(1, -30, 0, 8),
            Position = UDim2.new(0, 15, 0, 50),
            BackgroundColor3 = Color3.fromRGB(40, 40, 50),
            BorderSizePixel = 0,
            Parent = Container
        })
        
        local cornerSlider = CriarElemento("UICorner", {
            CornerRadius = UDim.new(0, 4),
            Parent = SliderFrame
        })
        
        local SliderFill = CriarElemento("Frame", {
            Size = UDim2.new((valorPadrao - min) / (max - min), 0, 1, 0),
            BackgroundColor3 = SHAKA_CONFIG.COR_PRIMARIA,
            BorderSizePixel = 0,
            Parent = SliderFrame
        })
        
        local cornerFill = CriarElemento("UICorner", {
            CornerRadius = UDim.new(0, 4),
            Parent = SliderFill
        })
        
        local SliderKnob = CriarElemento("Frame", {
            Size = UDim2.new(0, 18, 0, 18),
            Position = UDim2.new((valorPadrao - min) / (max - min), -9, 0.5, -9),
            BackgroundColor3 = SHAKA_CONFIG.COR_TEXTO,
            BorderSizePixel = 0,
            Parent = SliderFrame
        })
        
        local cornerKnob = CriarElemento("UICorner", {
            CornerRadius = UDim.new(0, 9),
            Parent = SliderKnob
        })
        
        local dragging = false
        
        local function AtualizarSlider(input)
            local pos = math.clamp((input.Position.X - SliderFrame.AbsolutePosition.X) / SliderFrame.AbsoluteSize.X, 0, 1)
            local valor = math.floor(min + (max - min) * pos)
            
            SliderFill.Size = UDim2.new(pos, 0, 1, 0)
            SliderKnob.Position = UDim2.new(pos, -9, 0.5, -9)
            ValueLabel.Text = tostring(valor)
            
            callback(valor)
        end
        
        SliderKnob.InputBegan:Connect(function(input)
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
                AtualizarSlider(input)
            end
        end)
        
        SliderFrame.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                AtualizarSlider(input)
            end
        end)
        
        return Container
    end
    
    -- Função para criar Botão moderno
    local function CriarBotao(texto, callback, parent)
        local Button = CriarElemento("TextButton", {
            Size = UDim2.new(1, 0, 0, 45),
            BackgroundColor3 = SHAKA_CONFIG.COR_PRIMARIA,
            Text = texto,
            TextColor3 = SHAKA_CONFIG.COR_TEXTO,
            TextSize = 15,
            Font = Enum.Font.GothamBold,
            BorderSizePixel = 0,
            Parent = parent or TabFrames[CurrentTab]
        })
        
        local corner = CriarElemento("UICorner", {
            CornerRadius = UDim.new(0, 10),
            Parent = Button
        })
        
        Button.MouseEnter:Connect(function()
            AnimacaoSuave(Button, {BackgroundColor3 = SHAKA_CONFIG.COR_HOVER}, 0.2)
        end)
        
        Button.MouseLeave:Connect(function()
            AnimacaoSuave(Button, {BackgroundColor3 = SHAKA_CONFIG.COR_PRIMARIA}, 0.2)
        end)
        
        Button.MouseButton1Click:Connect(callback)
        
        return Button
    end

    -- ═══════════════════════════════════════════════════════════
    -- ABA PLAYER
    -- ═══════════════════════════════════════════════════════════
    CriarToggle("Noclip", "Atravessar paredes e objetos", function(estado)
        NoclipEnabled = estado
        CriarNotificacao("Noclip " .. (estado and "ativado" or "desativado"), "sucesso")
    end, false, TabFrames["Player"])
    
    CriarToggle("Fly", "Voar livremente pelo mapa", function(estado)
        FlyEnabled = estado
        AtivarFly(estado)
        CriarNotificacao("Fly " .. (estado and "ativado" or "desativado"), "sucesso")
    end, false, TabFrames["Player"])
    
    CriarToggle("Pulo Infinito", "Pular sem limite de altura", function(estado)
        InfJumpEnabled = estado
        AtivarPuloInfinito(estado)
        CriarNotificacao("Pulo Infinito " .. (estado and "ativado" or "desativado"), "sucesso")
    end, false, TabFrames["Player"])
    
    CriarSlider("Velocidade", 16, 200, 16, function(valor)
        CurrentSpeed = valor
        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
            LocalPlayer.Character.Humanoid.WalkSpeed = valor
        end
    end, TabFrames["Player"])
    
    CriarSlider("Força do Pulo", 50, 300, 50, function(valor)
        CurrentJumpPower = valor
        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
            LocalPlayer.Character.Humanoid.JumpPower = valor
        end
    end, TabFrames["Player"])
    
    CriarToggle("Invisibilidade", "Ficar invisível para outros", function(estado)
        InvisEnabled = estado
        FicarInvisivel(estado)
        CriarNotificacao("Invisibilidade " .. (estado and "ativada" or "desativada"), "sucesso")
    end, false, TabFrames["Player"])
    
    CriarToggle("God Mode", "Invencibilidade", function(estado)
        GodmodeEnabled = estado
        AtivarGodMode(estado)
        CriarNotificacao("God Mode " .. (estado and "ativado" or "desativado"), "sucesso")
    end, false, TabFrames["Player"])
    
    CriarBotao("🔄 Resetar Personagem", function()
        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
            LocalPlayer.Character.Humanoid.Health = 0
            CriarNotificacao("Personagem resetado", "sucesso")
        end
    end, TabFrames["Player"])

    -- ═══════════════════════════════════════════════════════════
    -- ABA COMBAT
    -- ═══════════════════════════════════════════════════════════
    -- Selecionador de Player para Combat
    local CombatPlayerFrame = CriarElemento("Frame", {
        Size = UDim2.new(1, 0, 0, 300),
        BackgroundColor3 = SHAKA_CONFIG.COR_FUNDO_SECUNDARIO,
        BorderSizePixel = 0,
        Parent = TabFrames["Combat"]
    })
    
    local cornerCombat = CriarElemento("UICorner", {
        CornerRadius = UDim.new(0, 10),
        Parent = CombatPlayerFrame
    })
    
    local CombatLabel = CriarElemento("TextLabel", {
        Size = UDim2.new(1, 0, 0, 35),
        BackgroundTransparency = 1,
        Text = "🎯 Selecione um Jogador",
        TextColor3 = SHAKA_CONFIG.COR_TEXTO,
        TextSize = 16,
        Font = Enum.Font.GothamBold,
        Parent = CombatPlayerFrame
    })
    
    local CombatPlayerList = CriarElemento("ScrollingFrame", {
        Size = UDim2.new(1, -20, 1, -45),
        Position = UDim2.new(0, 10, 0, 40),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ScrollBarThickness = 4,
        ScrollBarImageColor3 = SHAKA_CONFIG.COR_PRIMARIA,
        CanvasSize = UDim2.new(0, 0, 0, 0),
        Parent = CombatPlayerFrame
    })
    
    local combatLayout = CriarElemento("UIListLayout", {
        Padding = UDim.new(0, 5),
        SortOrder = Enum.SortOrder.LayoutOrder,
        Parent = CombatPlayerList
    })
    
    local SelectedCombatLabel = CriarElemento("TextLabel", {
        Size = UDim2.new(1, 0, 0, 30),
        BackgroundColor3 = SHAKA_CONFIG.COR_FUNDO_SECUNDARIO,
        Text = "👤 Selecionado: Nenhum",
        TextColor3 = SHAKA_CONFIG.COR_PRIMARIA,
        TextSize = 14,
        Font = Enum.Font.GothamBold,
        BorderSizePixel = 0,
        Parent = TabFrames["Combat"]
    })
    
    local cornerSelected = CriarElemento("UICorner", {
        CornerRadius = UDim.new(0, 10),
        Parent = SelectedCombatLabel
    })
    
    -- Função para atualizar lista de players para combat
    local function AtualizarCombatPlayers()
        CombatPlayerList:ClearAllChildren()
        
        local combatLayout = CriarElemento("UIListLayout", {
            Padding = UDim.new(0, 5),
            SortOrder = Enum.SortOrder.LayoutOrder,
            Parent = CombatPlayerList
        })
        
        local posY = 0
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= LocalPlayer then
                local PlayerBtn = CriarElemento("TextButton", {
                    Size = UDim2.new(1, 0, 0, 40),
                    BackgroundColor3 = SHAKA_CONFIG.COR_FUNDO,
                    Text = "",
                    BorderSizePixel = 0,
                    Parent = CombatPlayerList
                })
                
                local corner = CriarElemento("UICorner", {
                    CornerRadius = UDim.new(0, 8),
                    Parent = PlayerBtn
                })
                
                local PlayerIcon = CriarElemento("TextLabel", {
                    Size = UDim2.new(0, 30, 0, 30),
                    Position = UDim2.new(0, 5, 0, 5),
                    BackgroundTransparency = 1,
                    Text = "👤",
                    TextSize = 18,
                    Parent = PlayerBtn
                })
                
                local PlayerName = CriarElemento("TextLabel", {
                    Size = UDim2.new(1, -40, 1, 0),
                    Position = UDim2.new(0, 40, 0, 0),
                    BackgroundTransparency = 1,
                    Text = player.Name,
                    TextColor3 = SHAKA_CONFIG.COR_TEXTO,
                    TextSize = 14,
                    Font = Enum.Font.Gotham,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    Parent = PlayerBtn
                })
                
                PlayerBtn.MouseButton1Click:Connect(function()
                    SelectedPlayerForAction = player
                    SelectedCombatLabel.Text = "👤 Selecionado: " .. player.Name
                    
                    for _, btn in ipairs(CombatPlayerList:GetChildren()) do
                        if btn:IsA("TextButton") then
                            AnimacaoSuave(btn, {BackgroundColor3 = SHAKA_CONFIG.COR_FUNDO}, 0.2)
                        end
                    end
                    AnimacaoSuave(PlayerBtn, {BackgroundColor3 = SHAKA_CONFIG.COR_PRIMARIA}, 0.2)
                end)
                
                PlayerBtn.MouseEnter:Connect(function()
                    if SelectedPlayerForAction ~= player then
                        AnimacaoSuave(PlayerBtn, {BackgroundColor3 = SHAKA_CONFIG.COR_FUNDO_SECUNDARIO}, 0.2)
                    end
                end)
                
                PlayerBtn.MouseLeave:Connect(function()
                    if SelectedPlayerForAction ~= player then
                        AnimacaoSuave(PlayerBtn, {BackgroundColor3 = SHAKA_CONFIG.COR_FUNDO}, 0.2)
                    end
                end)
                
                posY = posY + 45
            end
        end
        
        CombatPlayerList.CanvasSize = UDim2.new(0, 0, 0, posY)
    end
    
    -- Botões de ação para combat
    CriarBotao("⚔️ Atacar Player", function()
        if SelectedPlayerForAction and SelectedPlayerForAction.Character then
            -- Implementar lógica de ataque
            CriarNotificacao("Atacando " .. SelectedPlayerForAction.Name, "sucesso")
        else
            CriarNotificacao("Selecione um jogador primeiro!", "erro")
        end
    end, TabFrames["Combat"])
    
    CriarBotao("🔫 Kill Player", function()
        if SelectedPlayerForAction and SelectedPlayerForAction.Character and SelectedPlayerForAction.Character:FindFirstChild("Humanoid") then
            SelectedPlayerForAction.Character.Humanoid.Health = 0
            CriarNotificacao("Player eliminado", "sucesso")
        else
            CriarNotificacao("Selecione um jogador primeiro!", "erro")
        end
    end, TabFrames["Combat"])
    
    CriarBotao("💥 Explodir Player", function()
        if SelectedPlayerForAction and SelectedPlayerForAction.Character and SelectedPlayerForAction.Character:FindFirstChild("HumanoidRootPart") then
            local explosion = Instance.new("Explosion")
            explosion.Position = SelectedPlayerForAction.Character.HumanoidRootPart.Position
            explosion.BlastRadius = 10
            explosion.Parent = workspace
            CriarNotificacao("Explosão criada!", "sucesso")
        else
            CriarNotificacao("Selecione um jogador primeiro!", "erro")
        end
    end, TabFrames["Combat"])
    
    CriarToggle("Auto Kill", "Eliminar automaticamente", function(estado)
        -- Implementar lógica de auto kill
        CriarNotificacao("Auto Kill " .. (estado and "ativado" or "desativado"), "sucesso")
    end, false, TabFrames["Combat"])

    -- ═══════════════════════════════════════════════════════════
    -- ABA ESP
    -- ═══════════════════════════════════════════════════════════
    CriarToggle("ESP Ativado", "Visualizar todos os jogadores", function(estado)
        if estado then
            AtivarESP()
        else
            DesativarESP()
        end
        CriarNotificacao("ESP " .. (estado and "ativado" or "desativado"), "sucesso")
    end, false, TabFrames["ESP"])
    
    CriarToggle("Mostrar Caixas", "Caixa ao redor dos players", function(estado)
        ESPConfig.Box = estado
        AtualizarESP()
    end, true, TabFrames["ESP"])
    
    CriarToggle("Mostrar Linhas", "Linha até os players", function(estado)
        ESPConfig.Tracer = estado
        AtualizarESP()
    end, true, TabFrames["ESP"])
    
    CriarToggle("Mostrar Nomes", "Exibir nomes dos players", function(estado)
        ESPConfig.Names = estado
        AtualizarESP()
    end, true, TabFrames["ESP"])
    
    CriarToggle("Mostrar Distância", "Exibir distância em metros", function(estado)
        ESPConfig.Distance = estado
        AtualizarESP()
    end, true, TabFrames["ESP"])
    
    CriarToggle("Mostrar Vida", "Exibir barra de vida", function(estado)
        ESPConfig.Health = estado
        AtualizarESP()
    end, true, TabFrames["ESP"])
    
    CriarToggle("Mostrar Skeleton", "Exibir esqueleto do player", function(estado)
        ESPConfig.Skeleton = estado
        AtualizarESP()
    end, false, TabFrames["ESP"])
    
    CriarSlider("Transparência ESP", 0, 100, 80, function(valor)
        ESPConfig.Transparency = valor / 100
        AtualizarESP()
    end, TabFrames["ESP"])

    -- ═══════════════════════════════════════════════════════════
    -- ABA TELEPORT
    -- ═══════════════════════════════════════════════════════════
    local TPPlayerFrame = CriarElemento("Frame", {
        Size = UDim2.new(1, 0, 0, 280),
        BackgroundColor3 = SHAKA_CONFIG.COR_FUNDO_SECUNDARIO,
        BorderSizePixel = 0,
        Parent = TabFrames["Teleport"]
    })
    
    local cornerTP = CriarElemento("UICorner", {
        CornerRadius = UDim.new(0, 10),
        Parent = TPPlayerFrame
    })
    
    local TPLabel = CriarElemento("TextLabel", {
        Size = UDim2.new(1, 0, 0, 35),
        BackgroundTransparency = 1,
        Text = "📍 Lista de Jogadores",
        TextColor3 = SHAKA_CONFIG.COR_TEXTO,
        TextSize = 16,
        Font = Enum.Font.GothamBold,
        Parent = TPPlayerFrame
    })
    
    local TPPlayerList = CriarElemento("ScrollingFrame", {
        Size = UDim2.new(1, -20, 1, -45),
        Position = UDim2.new(0, 10, 0, 40),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ScrollBarThickness = 4,
        ScrollBarImageColor3 = SHAKA_CONFIG.COR_PRIMARIA,
        CanvasSize = UDim2.new(0, 0, 0, 0),
        Parent = TPPlayerFrame
    })
    
    local tpLayout = CriarElemento("UIListLayout", {
        Padding = UDim.new(0, 5),
        SortOrder = Enum.SortOrder.LayoutOrder,
        Parent = TPPlayerList
    })
    
    local SelectedTPLabel = CriarElemento("TextLabel", {
        Size = UDim2.new(1, 0, 0, 30),
        BackgroundColor3 = SHAKA_CONFIG.COR_FUNDO_SECUNDARIO,
        Text = "📌 Selecionado: Nenhum",
        TextColor3 = SHAKA_CONFIG.COR_PRIMARIA,
        TextSize = 14,
        Font = Enum.Font.GothamBold,
        BorderSizePixel = 0,
        Parent = TabFrames["Teleport"]
    })
    
    local cornerTPSelected = CriarElemento("UICorner", {
        CornerRadius = UDim.new(0, 10),
        Parent = SelectedTPLabel
    })
    
    -- Função para atualizar lista de players para TP
    local function AtualizarTPPlayers()
        TPPlayerList:ClearAllChildren()
        
        local tpLayout = CriarElemento("UIListLayout", {
            Padding = UDim.new(0, 5),
            SortOrder = Enum.SortOrder.LayoutOrder,
            Parent = TPPlayerList
        })
        
        local posY = 0
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= LocalPlayer then
                local PlayerBtn = CriarElemento("TextButton", {
                    Size = UDim2.new(1, 0, 0, 40),
                    BackgroundColor3 = SHAKA_CONFIG.COR_FUNDO,
                    Text = "",
                    BorderSizePixel = 0,
                    Parent = TPPlayerList
                })
                
                local corner = CriarElemento("UICorner", {
                    CornerRadius = UDim.new(0, 8),
                    Parent = PlayerBtn
                })
                
                local PlayerIcon = CriarElemento("TextLabel", {
                    Size = UDim2.new(0, 30, 0, 30),
                    Position = UDim2.new(0, 5, 0, 5),
                    BackgroundTransparency = 1,
                    Text = "📍",
                    TextSize = 18,
                    Parent = PlayerBtn
                })
                
                local PlayerName = CriarElemento("TextLabel", {
                    Size = UDim2.new(1, -40, 1, 0),
                    Position = UDim2.new(0, 40, 0, 0),
                    BackgroundTransparency = 1,
                    Text = player.Name,
                    TextColor3 = SHAKA_CONFIG.COR_TEXTO,
                    TextSize = 14,
                    Font = Enum.Font.Gotham,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    Parent = PlayerBtn
                })
                
                PlayerBtn.MouseButton1Click:Connect(function()
                    SelectedPlayer = player
                    SelectedTPLabel.Text = "📌 Selecionado: " .. player.Name
                    
                    for _, btn in ipairs(TPPlayerList:GetChildren()) do
                        if btn:IsA("TextButton") then
                            AnimacaoSuave(btn, {BackgroundColor3 = SHAKA_CONFIG.COR_FUNDO}, 0.2)
                        end
                    end
                    AnimacaoSuave(PlayerBtn, {BackgroundColor3 = SHAKA_CONFIG.COR_PRIMARIA}, 0.2)
                end)
                
                PlayerBtn.MouseEnter:Connect(function()
                    if SelectedPlayer ~= player then
                        AnimacaoSuave(PlayerBtn, {BackgroundColor3 = SHAKA_CONFIG.COR_FUNDO_SECUNDARIO}, 0.2)
                    end
                end)
                
                PlayerBtn.MouseLeave:Connect(function()
                    if SelectedPlayer ~= player then
                        AnimacaoSuave(PlayerBtn, {BackgroundColor3 = SHAKA_CONFIG.COR_FUNDO}, 0.2)
                    end
                end)
                
                posY = posY + 45
            end
        end
        
        TPPlayerList.CanvasSize = UDim2.new(0, 0, 0, posY)
    end
    
    CriarBotao("🚀 Teleportar para Player", function()
        if SelectedPlayer and SelectedPlayer.Character and SelectedPlayer.Character:FindFirstChild("HumanoidRootPart") and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
            LocalPlayer.Character.HumanoidRootPart.CFrame = SelectedPlayer.Character.HumanoidRootPart.CFrame
            CriarNotificacao("Teleportado para " .. SelectedPlayer.Name, "sucesso")
        else
            CriarNotificacao("Selecione um jogador válido!", "erro")
        end
    end, TabFrames["Teleport"])
    
    CriarBotao("🔙 Trazer Player até Você", function()
        if SelectedPlayer and SelectedPlayer.Character and SelectedPlayer.Character:FindFirstChild("HumanoidRootPart") and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
            SelectedPlayer.Character.HumanoidRootPart.CFrame = LocalPlayer.Character.HumanoidRootPart.CFrame
            CriarNotificacao(SelectedPlayer.Name .. " foi trazido até você", "sucesso")
        else
            CriarNotificacao("Selecione um jogador válido!", "erro")
        end
    end, TabFrames["Teleport"])
    
    CriarToggle("Teleport em Loop", "TP contínuo para o player", function(estado)
        if estado and SelectedPlayer then
            local connection = RunService.Heartbeat:Connect(function()
                if SelectedPlayer and SelectedPlayer.Character and SelectedPlayer.Character:FindFirstChild("HumanoidRootPart") and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                    LocalPlayer.Character.HumanoidRootPart.CFrame = SelectedPlayer.Character.HumanoidRootPart.CFrame
                end
            end)
            table.insert(Connections, connection)
            CriarNotificacao("Loop TP ativado", "sucesso")
        else
            CriarNotificacao("Loop TP desativado", "sucesso")
        end
    end, false, TabFrames["Teleport"])
    
    CriarBotao("🏠 Voltar ao Spawn", function()
        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
            local spawn = workspace:FindFirstChild("SpawnLocation") or workspace:FindFirstChildOfClass("SpawnLocation")
            if spawn then
                LocalPlayer.Character.HumanoidRootPart.CFrame = spawn.CFrame + Vector3.new(0, 5, 0)
                CriarNotificacao("Teleportado para o spawn", "sucesso")
            else
                CriarNotificacao("Spawn não encontrado", "erro")
            end
        end
    end, TabFrames["Teleport"])

    -- ═══════════════════════════════════════════════════════════
    -- ABA VISUALS
    -- ═══════════════════════════════════════════════════════════
    CriarToggle("Fullbright", "Iluminação completa", function(estado)
        AtivarFullbright(estado)
        CriarNotificacao("Fullbright " .. (estado and "ativado" or "desativado"), "sucesso")
    end, false, TabFrames["Visuals"])
    
    CriarToggle("Remover Fog", "Remover neblina", function(estado)
        if estado then
            Lighting.FogEnd = 100000
            Lighting.FogStart = 0
        else
            Lighting.FogEnd = 100000
            Lighting.FogStart = 0
        end
        CriarNotificacao("Fog " .. (estado and "removido" or "restaurado"), "sucesso")
    end, false, TabFrames["Visuals"])
    
    CriarToggle("Otimizar FPS", "Melhorar performance", function(estado)
        OtimizarFPS(estado)
        CriarNotificacao("Otimização de FPS " .. (estado and "ativada" or "desativada"), "sucesso")
    end, false, TabFrames["Visuals"])
    
    CriarToggle("Remover Texturas", "Performance extra", function(estado)
        if estado then
            for _, obj in ipairs(workspace:GetDescendants()) do
                if obj:IsA("Decal") or obj:IsA("Texture") then
                    obj.Transparency = 1
                end
            end
        else
            for _, obj in ipairs(workspace:GetDescendants()) do
                if obj:IsA("Decal") or obj:IsA("Texture") then
                    obj.Transparency = 0
                end
            end
        end
        CriarNotificacao("Texturas " .. (estado and "removidas" or "restauradas"), "sucesso")
    end, false, TabFrames["Visuals"])
    
    CriarSlider("Brilho", 0, 5, 1, function(valor)
        Lighting.Brightness = valor
    end, TabFrames["Visuals"])
    
    CriarSlider("FOV da Câmera", 70, 120, 70, function(valor)
        Camera.FieldOfView = valor
    end, TabFrames["Visuals"])
    
    CriarToggle("Remover Sombras", "Desativar sombras", function(estado)
        Lighting.GlobalShadows = not estado
        CriarNotificacao("Sombras " .. (estado and "removidas" or "restauradas"), "sucesso")
    end, false, TabFrames["Visuals"])

    -- ═══════════════════════════════════════════════════════════
    -- ABA SETTINGS
    -- ═══════════════════════════════════════════════════════════
    local InfoFrame = CriarElemento("Frame", {
        Size = UDim2.new(1, 0, 0, 150),
        BackgroundColor3 = SHAKA_CONFIG.COR_FUNDO_SECUNDARIO,
        BorderSizePixel = 0,
        Parent = TabFrames["Settings"]
    })
    
    local cornerInfo = CriarElemento("UICorner", {
        CornerRadius = UDim.new(0, 10),
        Parent = InfoFrame
    })
    
    local InfoLabel = CriarElemento("TextLabel", {
        Size = UDim2.new(1, -20, 1, -20),
        Position = UDim2.new(0, 10, 0, 10),
        BackgroundTransparency = 1,
        Text = "🟣 SHAKA Hub Premium v4.0\n\n✨ Menu profissional melhorado\n👨‍💻 Desenvolvido com dedicação\n🎯 Mais de 30 funções disponíveis\n\n⌨️ Pressione F para abrir/fechar",
        TextColor3 = SHAKA_CONFIG.COR_TEXTO,
        TextSize = 14,
        Font = Enum.Font.Gotham,
        TextWrapped = true,
        TextYAlignment = Enum.TextYAlignment.Top,
        Parent = InfoFrame
    })
    
    CriarBotao("🔄 Recarregar Menu", function()
        CriarGUI()
        CriarNotificacao("Menu recarregado com sucesso!", "sucesso")
    end, TabFrames["Settings"])
    
    CriarBotao("🗑️ Destruir Menu", function()
        if GUI then
            GUI:Destroy()
            GUI = nil
            for _, connection in ipairs(Connections) do
                connection:Disconnect()
            end
            Connections = {}
            CriarNotificacao("Menu destruído", "erro")
        end
    end, TabFrames["Settings"])
    
    CriarBotao("📋 Copiar Info do Jogo", function()
        local info = "Game: " .. game.Name .. "\nJobId: " .. game.JobId .. "\nPlayers: " .. #Players:GetPlayers()
        setclipboard(info)
        CriarNotificacao("Informações copiadas!", "sucesso")
    end, TabFrames["Settings"])

    -- ═══════════════════════════════════════════════════════════
    -- SISTEMA DE ARRASTAR
    -- ═══════════════════════════════════════════════════════════
    local function IniciarArraste(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            Dragging = true
            DragStart = input.Position
            local startPos = MainContainer.Position
            
            local connection = RunService.Heartbeat:Connect(function()
                if Dragging then
                    local delta = UserInputService:GetMouseLocation() - DragStart
                    MainContainer.Position = UDim2.new(
                        startPos.X.Scale,
                        startPos.X.Offset + delta.X,
                        startPos.Y.Scale,
                        startPos.Y.Offset + delta.Y
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

    -- ═══════════════════════════════════════════════════════════
    -- EVENTOS DOS BOTÕES DO HEADER
    -- ═══════════════════════════════════════════════════════════
    MinimizeButton.MouseButton1Click:Connect(function()
        MenuVisible = not MenuVisible
        if MenuVisible then
            AnimacaoSuave(MainContainer, {Size = UDim2.new(0, 700, 0, 500)}, 0.3)
            AnimacaoSuave(ContentContainer, {Size = UDim2.new(1, 0, 1, -60)}, 0.3)
        else
            AnimacaoSuave(MainContainer, {Size = UDim2.new(0, 320, 0, 60)}, 0.3)
            AnimacaoSuave(ContentContainer, {Size = UDim2.new(1, 0, 0, 0)}, 0.3)
        end
    end)

    CloseButton.MouseButton1Click:Connect(function()
        AnimacaoSuave(MainContainer, {Size = UDim2.new(0, 0, 0, 0)}, 0.3)
        task.wait(0.3)
        GUI:Destroy()
        GUI = nil
    end)

    -- Atualizar listas de players
    task.spawn(function()
        while GUI do
            AtualizarTPPlayers()
            AtualizarCombatPlayers()
            task.wait(2)
        end
    end)

    -- Ajustar canvas size
    for _, frame in pairs(TabFrames) do
        local layout = frame:FindFirstChildOfClass("UIListLayout")
        if layout then
            layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
                frame.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 10)
            end)
        end
    end

    return GUI
end

-- ═══════════════════════════════════════════════════════════
-- FUNÇÕES DO PLAYER
-- ═══════════════════════════════════════════════════════════
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
                
                local direction = Vector3.new()
                
                if UserInputService:IsKeyDown(Enum.KeyCode.W) then
                    direction = direction + Camera.CFrame.LookVector
                end
                if UserInputService:IsKeyDown(Enum.KeyCode.S) then
                    direction = direction - Camera.CFrame.LookVector
                end
                if UserInputService:IsKeyDown(Enum.KeyCode.A) then
                    direction = direction - Camera.CFrame.RightVector
                end
                if UserInputService:IsKeyDown(Enum.KeyCode.D) then
                    direction = direction + Camera.CFrame.RightVector
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

local function FicarInvisivel(estado)
    if LocalPlayer.Character then
        for _, part in ipairs(LocalPlayer.Character:GetDescendants()) do
            if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
                part.Transparency = estado and 1 or 0
                if part:FindFirstChild("face") then
                    part.face.Transparency = estado and 1 or 0
                end
            end
        end
    end
end

local function AtivarGodMode(estado)
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
        if estado then
            LocalPlayer.Character.Humanoid.MaxHealth = math.huge
            LocalPlayer.Character.Humanoid.Health = math.huge
        else
            LocalPlayer.Character.Humanoid.MaxHealth = 100
            LocalPlayer.Character.Humanoid.Health = 100
        end
    end
end

local function AtivarFullbright(estado)
    if estado then
        Lighting.Brightness = 2
        Lighting.ClockTime = 14
        Lighting.FogEnd = 100000
        Lighting.GlobalShadows = false
        Lighting.OutdoorAmbient = Color3.new(1, 1, 1)
    else
        Lighting.Brightness = 1
        Lighting.ClockTime = 14
        Lighting.FogEnd = 100000
        Lighting.GlobalShadows = true
        Lighting.OutdoorAmbient = Color3.new(0.5, 0.5, 0.5)
    end
end

local function OtimizarFPS(estado)
    if estado then
        settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
        for _, effect in ipairs(workspace:GetDescendants()) do
            if effect:IsA("ParticleEmitter") or effect:IsA("Fire") or effect:IsA("Smoke") or effect:IsA("Sparkles") then
                effect.Enabled = false
            end
        end
    else
        settings().Rendering.QualityLevel = Enum.QualityLevel.Automatic
        for _, effect in ipairs(workspace:GetDescendants()) do
            if effect:IsA("ParticleEmitter") or effect:IsA("Fire") or effect:IsA("Smoke") or effect:IsA("Sparkles") then
                effect.Enabled = true
            end
        end
    end
end

-- ═══════════════════════════════════════════════════════════
-- SISTEMA ESP AVANÇADO
-- ═══════════════════════════════════════════════════════════
local ESPConfig = {
    Box = true,
    Tracer = true,
    Names = true,
    Distance = true,
    Health = true,
    Skeleton = false,
    Transparency = 0.8
}

local function CriarESP(character, nome)
    if ESP_Objects[character] then return end
    
    local espFolder = Instance.new("Folder")
    espFolder.Name = "SHAKA_ESP"
    espFolder.Parent = character
    
    -- Highlight (Box)
    if ESPConfig.Box then
        local highlight = Instance.new("Highlight")
        highlight.Name = "Box"
        highlight.FillColor = SHAKA_CONFIG.COR_PRIMARIA
        highlight.FillTransparency = ESPConfig.Transparency
        highlight.OutlineColor = SHAKA_CONFIG.COR_TEXTO
        highlight.OutlineTransparency = 0
        highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        highlight.Parent = espFolder
        highlight.Adornee = character
    end
    
    -- Tracer (Linha)
    if ESPConfig.Tracer then
        local beam = Instance.new("Beam")
        beam.Name = "Tracer"
        beam.Color = ColorSequence.new(SHAKA_CONFIG.COR_PRIMARIA)
        beam.Width0 = 0.1
        beam.Width1 = 0.1
        beam.FaceCamera = true
        
        local attachment0 = Instance.new("Attachment")
        attachment0.Parent = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") or workspace.Terrain
        
        local attachment1 = Instance.new("Attachment")
        attachment1.Parent = character:FindFirstChild("HumanoidRootPart") or character:FindFirstChildWhichIsA("BasePart")
        
        beam.Attachment0 = attachment0
        beam.Attachment1 = attachment1
        beam.Parent = espFolder
    end
    
    -- Billboard (Nome, Distância, Vida)
    if ESPConfig.Names or ESPConfig.Distance or ESPConfig.Health then
        local billboard = Instance.new("BillboardGui")
        billboard.Name = "NameTag"
        billboard.Size = UDim2.new(0, 200, 0, 100)
        billboard.StudsOffset = Vector3.new(0, 3, 0)
        billboard.AlwaysOnTop = true
        billboard.Parent = espFolder
        
        if character:FindFirstChild("HumanoidRootPart") then
            billboard.Adornee = character.HumanoidRootPart
        end
        
        -- Container
        local container = Instance.new("Frame")
        container.Size = UDim2.new(1, 0, 1, 0)
        container.BackgroundTransparency = 1
        container.Parent = billboard
        
        local layout = Instance.new("UIListLayout")
        layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
        layout.VerticalAlignment = Enum.VerticalAlignment.Top
        layout.Padding = UDim.new(0, 2)
        layout.Parent = container
        
        -- Nome
        if ESPConfig.Names then
            local nameLabel = Instance.new("TextLabel")
            nameLabel.Size = UDim2.new(1, 0, 0, 20)
            nameLabel.BackgroundTransparency = 1
            nameLabel.Text = nome
            nameLabel.TextColor3 = SHAKA_CONFIG.COR_TEXTO
            nameLabel.TextStrokeTransparency = 0.5
            nameLabel.TextSize = 14
            nameLabel.Font = Enum.Font.GothamBold
            nameLabel.Parent = container
        end
        
        -- Distância
        if ESPConfig.Distance then
            local distanceLabel = Instance.new("TextLabel")
            distanceLabel.Name = "Distance"
            distanceLabel.Size = UDim2.new(1, 0, 0, 18)
            distanceLabel.BackgroundTransparency = 1
            distanceLabel.Text = "0m"
            distanceLabel.TextColor3 = SHAKA_CONFIG.COR_PRIMARIA
            distanceLabel.TextStrokeTransparency = 0.5
            distanceLabel.TextSize = 12
            distanceLabel.Font = Enum.Font.Gotham
            distanceLabel.Parent = container
            
            -- Atualizar distância
            local connection = RunService.Heartbeat:Connect(function()
                if character and character:FindFirstChild("HumanoidRootPart") and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                    local distance = (character.HumanoidRootPart.Position - LocalPlayer.Character.HumanoidRootPart.Position).Magnitude
                    distanceLabel.Text = math.floor(distance) .. "m"
                else
                    connection:Disconnect()
                end
            end)
            table.insert(Connections, connection)
        end
        
        -- Barra de Vida
        if ESPConfig.Health then
            local healthContainer = Instance.new("Frame")
            healthContainer.Name = "HealthBar"
            healthContainer.Size = UDim2.new(0.8, 0, 0, 5)
            healthContainer.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
            healthContainer.BorderSizePixel = 0
            healthContainer.Parent = container
            
            local healthBar = Instance.new("Frame")
            healthBar.Size = UDim2.new(1, 0, 1, 0)
            healthBar.BackgroundColor3 = SHAKA_CONFIG.COR_SUCESSO
            healthBar.BorderSizePixel = 0
            healthBar.Parent = healthContainer
            
            local corner1 = Instance.new("UICorner")
            corner1.CornerRadius = UDim.new(0, 2)
            corner1.Parent = healthContainer
            
            local corner2 = Instance.new("UICorner")
            corner2.CornerRadius = UDim.new(0, 2)
            corner2.Parent = healthBar
            
            -- Atualizar vida
            local connection = RunService.Heartbeat:Connect(function()
                if character and character:FindFirstChild("Humanoid") then
                    local humanoid = character.Humanoid
                    local healthPercent = humanoid.Health / humanoid.MaxHealth
                    healthBar.Size = UDim2.new(healthPercent, 0, 1, 0)
                    
                    -- Cor baseada na vida
                    if healthPercent > 0.5 then
                        healthBar.BackgroundColor3 = SHAKA_CONFIG.COR_SUCESSO
                    elseif healthPercent > 0.25 then
                        healthBar.BackgroundColor3 = Color3.fromRGB(255, 200, 0)
                    else
                        healthBar.BackgroundColor3 = SHAKA_CONFIG.COR_ERRO
                    end
                else
                    connection:Disconnect()
                end
            end)
            table.insert(Connections, connection)
        end
    end
    
    -- Skeleton (Esqueleto)
    if ESPConfig.Skeleton then
        local skeletonFolder = Instance.new("Folder")
        skeletonFolder.Name = "Skeleton"
        skeletonFolder.Parent = espFolder
        
        local limbs = {
            {"Head", "UpperTorso"},
            {"UpperTorso", "LowerTorso"},
            {"UpperTorso", "LeftUpperArm"},
            {"LeftUpperArm", "LeftLowerArm"},
            {"LeftLowerArm", "LeftHand"},
            {"UpperTorso", "RightUpperArm"},
            {"RightUpperArm", "RightLowerArm"},
            {"RightLowerArm", "RightHand"},
            {"LowerTorso", "LeftUpperLeg"},
            {"LeftUpperLeg", "LeftLowerLeg"},
            {"LeftLowerLeg", "LeftFoot"},
            {"LowerTorso", "RightUpperLeg"},
            {"RightUpperLeg", "RightLowerLeg"},
            {"RightLowerLeg", "RightFoot"}
        }
        
        for _, limbPair in ipairs(limbs) do
            local part1 = character:FindFirstChild(limbPair[1])
            local part2 = character:FindFirstChild(limbPair[2])
            
            if part1 and part2 then
                local beam = Instance.new("Beam")
                beam.Color = ColorSequence.new(SHAKA_CONFIG.COR_PRIMARIA)
                beam.Width0 = 0.1
                beam.Width1 = 0.1
                beam.FaceCamera = true
                
                local attachment0 = Instance.new("Attachment")
                attachment0.Parent = part1
                
                local attachment1 = Instance.new("Attachment")
                attachment1.Parent = part2
                
                beam.Attachment0 = attachment0
                beam.Attachment1 = attachment1
                beam.Parent = skeletonFolder
            end
        end
    end
    
    ESP_Objects[character] = espFolder
end

local function AtivarESP()
    DesativarESP()
    
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            CriarESP(player.Character, player.Name)
        end
    end
    
    local connection1 = Players.PlayerAdded:Connect(function(player)
        player.CharacterAdded:Connect(function(character)
            task.wait(1)
            CriarESP(character, player.Name)
        end)
    end)
    
    local connection2 = Players.PlayerRemoving:Connect(function(player)
        if player.Character and ESP_Objects[player.Character] then
            ESP_Objects[player.Character]:Destroy()
            ESP_Objects[player.Character] = nil
        end
    end)
    
    table.insert(Connections, connection1)
    table.insert(Connections, connection2)
end

local function DesativarESP()
    for character, espFolder in pairs(ESP_Objects) do
        if espFolder then
            espFolder:Destroy()
        end
    end
    ESP_Objects = {}
end

local function AtualizarESP()
    DesativarESP()
    task.wait(0.1)
    AtivarESP()
end

-- ═══════════════════════════════════════════════════════════
-- SISTEMA NOCLIP
-- ═══════════════════════════════════════════════════════════
table.insert(Connections, RunService.Stepped:Connect(function()
    if NoclipEnabled and LocalPlayer.Character then
        for _, part in ipairs(LocalPlayer.Character:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanCollide = false
            end
        end
    end
end))

-- ═══════════════════════════════════════════════════════════
-- SISTEMA DE VELOCIDADE E PULO AUTOMÁTICO
-- ═══════════════════════════════════════════════════════════
table.insert(Connections, RunService.Heartbeat:Connect(function()
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
        if SpeedEnabled then
            LocalPlayer.Character.Humanoid.WalkSpeed = CurrentSpeed
        end
        if LocalPlayer.Character.Humanoid.JumpPower ~= CurrentJumpPower then
            LocalPlayer.Character.Humanoid.JumpPower = CurrentJumpPower
        end
    end
end))

-- ═══════════════════════════════════════════════════════════
-- INICIALIZAÇÃO
-- ═══════════════════════════════════════════════════════════
Log("═══════════════════════════════════════")
Log("    SHAKA Hub Premium v4.0")
Log("    Carregando sistema...")
Log("═══════════════════════════════════════")

task.wait(1)

-- Criar GUI
CriarGUI()

Log("✅ Menu carregado com sucesso!")
Log("⌨️  Pressione F para abrir/fechar")
Log("═══════════════════════════════════════")

-- Notificação de boas-vindas
task.spawn(function()
    task.wait(0.5)
    if GUI then
        CriarNotificacao("🟣 SHAKA Hub v4.0 carregado!", "sucesso")
    end
end)

-- ═══════════════════════════════════════════════════════════
-- TOGGLE COM TECLA F
-- ═══════════════════════════════════════════════════════════
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    
    if input.KeyCode == Enum.KeyCode.F then
        if GUI then
            AnimacaoSuave(GUI.MainContainer, {Size = UDim2.new(0, 0, 0, 0)}, 0.3)
            task.wait(0.3)
            GUI:Destroy()
            GUI = nil
            Log("Menu fechado")
        else
            CriarGUI()
            Log("Menu aberto")
            task.wait(0.2)
            CriarNotificacao("Menu reaberto!", "sucesso")
        end
    end
end)

-- ═══════════════════════════════════════════════════════════
-- LIMPEZA AO SAIR
-- ═══════════════════════════════════════════════════════════
game:GetService("Players").PlayerRemoving:Connect(function(player)
    if player == LocalPlayer then
        for _, connection in ipairs(Connections) do
            connection:Disconnect()
        end
        DesativarESP()
        if GUI then
            GUI:Destroy()
        end
    end
end)
