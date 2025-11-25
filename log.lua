-- Purple Panel - Load Everything First
-- Carrega TUDO antes de mostrar a UI

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

print("🎯 INICIANDO CARREGAMENTO COMPLETO...")

-- ========== CONFIGURAÇÕES INICIAIS ==========
local Config = {
    Theme = {
        Primary = Color3.fromRGB(147, 51, 234),
        Secondary = Color3.fromRGB(20, 20, 20),
        Background = Color3.fromRGB(40, 35, 55),
        Surface = Color3.fromRGB(50, 45, 65),
        Success = Color3.fromRGB(72, 199, 142),
        Error = Color3.fromRGB(255, 85, 85),
        Warning = Color3.fromRGB(255, 159, 28),
        Text = Color3.fromRGB(255, 255, 255)
    }
}

-- ========== DADOS GLOBAIS ==========
local Memory = {
    Events = {},
    Blocked = {},
    KeyLogs = {},
    IsCapturing = false,
    CurrentTab = "Home"
}

-- ========== SISTEMA DE HOOK (CARREGA PRIMEIRO) ==========
print("🔧 CONFIGURANDO SISTEMA DE CAPTURA...")

local function SetupHookSystem()
    if hookmetamethod then
        local originalNamecall
        originalNamecall = hookmetamethod(game, "__namecall", function(self, ...)
            local method = getnamecallmethod()
            
            if Memory.IsCapturing and (method == "FireServer" or method == "InvokeServer") then
                local eventData = {
                    Name = self.Name,
                    Type = method,
                    Path = self:GetFullName(),
                    Time = os.date("%H:%M:%S"),
                    Remote = self,
                    Arguments = {...}
                }
                
                table.insert(Memory.Events, 1, eventData)
                if #Memory.Events > 50 then
                    table.remove(Memory.Events)
                end
            end
            
            return originalNamecall(self, ...)
        end)
        print("✅ Hook de eventos configurado!")
    else
        print("❌ Hookmetamethod não disponível")
    end
end

-- ========== SISTEMA DE KEY LOGGER ==========
print("⌨️ CONFIGURANDO KEY LOGGER...")

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if input.KeyCode == Enum.KeyCode.F then return end -- Ignora F
    
    local keyName = input.KeyCode.Name
    if keyName ~= "Unknown" then
        local logEntry = string.format("[%s] %s %s", 
            os.date("%H:%M:%S"),
            gameProcessed and "🔒" or "💜",
            keyName
        )
        
        table.insert(Memory.KeyLogs, 1, logEntry)
        if #Memory.KeyLogs > 100 then
            table.remove(Memory.KeyLogs)
        end
    end
end)

-- ========== FUNÇÕES UTILITÁRIAS ==========
print("🔨 CARREGANDO FUNÇÕES UTILITÁRIAS...")

local function CreateButton(text, color, parent, position, size)
    local button = Instance.new("TextButton")
    button.Size = size or UDim2.new(0.48, 0, 0, 35)
    button.Position = position or UDim2.new(0, 0, 0, 0)
    button.BackgroundColor3 = color
    button.Text = text
    button.TextColor3 = Config.Theme.Text
    button.Font = Enum.Font.GothamBold
    button.TextSize = 12
    button.AutoButtonColor = false
    button.BorderSizePixel = 0
    button.Parent = parent
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = button
    
    return button
end

local function ClearContainer(container)
    for _, child in ipairs(container:GetChildren()) do
        if child:IsA("Frame") or child:IsA("ScrollingFrame") or child:IsA("TextButton") then
            child:Destroy()
        end
    end
end

-- ========== CRIAR UI (CARREGA TUDO DE UMA VEZ) ==========
print("🎨 CRIANDO INTERFACE...")

-- ScreenGui Principal
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "PurplePanelComplete"
screenGui.ResetOnSpawn = false
screenGui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")

-- Frame Principal
local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 600, 0, 450)
mainFrame.Position = UDim2.new(0.5, -300, 0.5, -225)
mainFrame.BackgroundColor3 = Config.Theme.Background
mainFrame.BorderSizePixel = 0
mainFrame.Visible = false
mainFrame.Parent = screenGui

local mainCorner = Instance.new("UICorner")
mainCorner.CornerRadius = UDim.new(0, 10)
mainCorner.Parent = mainFrame

-- Header
local header = Instance.new("Frame")
header.Size = UDim2.new(1, 0, 0, 40)
header.BackgroundColor3 = Config.Theme.Primary
header.BorderSizePixel = 0
header.Parent = mainFrame

local headerCorner = Instance.new("UICorner")
headerCorner.CornerRadius = UDim.new(0, 10)
headerCorner.Parent = header

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -50, 1, 0)
title.Position = UDim2.new(0, 10, 0, 0)
title.BackgroundTransparency = 1
title.Text = "💜 Purple Panel - CARREGADO"
title.TextColor3 = Config.Theme.Text
title.Font = Enum.Font.GothamBold
title.TextSize = 16
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = header

local closeBtn = CreateButton("X", Config.Theme.Error, header, UDim2.new(1, -35, 0, 5), UDim2.new(0, 30, 0, 30))

-- Abas
local tabsFrame = Instance.new("Frame")
tabsFrame.Size = UDim2.new(1, -20, 0, 35)
tabsFrame.Position = UDim2.new(0, 10, 0, 45)
tabsFrame.BackgroundTransparency = 1
tabsFrame.Parent = mainFrame

local tabs = {"Home", "Events", "KeyLogs", "Executor", "Dump"}
local tabButtons = {}

for i, tabName in ipairs(tabs) do
    local tabBtn = CreateButton(tabName, Config.Theme.Surface, tabsFrame, 
        UDim2.new(0, (i-1)*115, 0, 0), UDim2.new(0, 110, 1, 0))
    
    tabButtons[tabName] = tabBtn
end

-- Área de Conteúdo
local contentFrame = Instance.new("Frame")
contentFrame.Size = UDim2.new(1, -20, 1, -90)
contentFrame.Position = UDim2.new(0, 10, 0, 85)
contentFrame.BackgroundColor3 = Config.Theme.Surface
contentFrame.BorderSizePixel = 0
contentFrame.Parent = mainFrame

local contentCorner = Instance.new("UICorner")
contentCorner.CornerRadius = UDim.new(0, 8)
contentCorner.Parent = contentFrame

-- ========== FUNÇÕES DAS ABAS (PRÉ-CARREGADAS) ==========
print("📁 CARREGANDO SISTEMA DE ABAS...")

local TabSystem = {}

function TabSystem.ShowHome()
    ClearContainer(contentFrame)
    
    local container = Instance.new("Frame")
    container.Size = UDim2.new(1, 0, 1, 0)
    container.BackgroundTransparency = 1
    container.Parent = contentFrame
    
    -- Status
    local statusFrame = Instance.new("Frame")
    statusFrame.Size = UDim2.new(1, -20, 0, 120)
    statusFrame.Position = UDim2.new(0, 10, 0, 10)
    statusFrame.BackgroundColor3 = Config.Theme.Secondary
    statusFrame.Parent = container
    
    local statusCorner = Instance.new("UICorner")
    statusCorner.CornerRadius = UDim.new(0, 8)
    statusCorner.Parent = statusFrame
    
    local statusText = Instance.new("TextLabel")
    statusText.Size = UDim2.new(1, -20, 1, -20)
    statusText.Position = UDim2.new(0, 10, 0, 10)
    statusText.BackgroundTransparency = 1
    statusText.Text = string.format("💜 SISTEMA CARREGADO\n\n📊 Eventos: %d\n⌨️ Key Logs: %d\n🔒 Bloqueados: %d\n🎯 Captura: %s",
        #Memory.Events, #Memory.KeyLogs, #Memory.Blocked, Memory.IsCapturing and "ATIVA" : "INATIVA")
    statusText.TextColor3 = Config.Theme.Text
    statusText.Font = Enum.Font.Gotham
    statusText.TextSize = 12
    statusText.TextYAlignment = Enum.TextYAlignment.Top
    statusText.TextWrapped = true
    statusText.Parent = statusFrame
    
    -- Botões de Ação
    local startBtn = CreateButton(Memory.IsCapturing and "🔴 PARAR CAPTURA" or "🟢 INICIAR CAPTURA", 
        Memory.IsCapturing and Config.Theme.Error or Config.Theme.Success, 
        container, UDim2.new(0, 10, 0, 140), UDim2.new(0.48, 0, 0, 35))
    
    local clearBtn = CreateButton("🗑️ LIMPAR TUDO", Config.Theme.Warning, 
        container, UDim2.new(0.52, 10, 0, 140), UDim2.new(0.48, 0, 0, 35))
    
    local dumpBtn = CreateButton("💾 DUMP RÁPIDO", Config.Theme.Primary, 
        container, UDim2.new(0, 10, 0, 185), UDim2.new(1, -20, 0, 35))
    
    startBtn.MouseButton1Click:Connect(function()
        Memory.IsCapturing = not Memory.IsCapturing
        TabSystem.ShowHome()
    end)
    
    clearBtn.MouseButton1Click:Connect(function()
        Memory.Events = {}
        Memory.KeyLogs = {}
        TabSystem.ShowHome()
    end)
    
    dumpBtn.MouseButton1Click:Connect(function()
        TabSystem.ShowDump()
    end)
end

function TabSystem.ShowEvents()
    ClearContainer(contentFrame)
    
    local scroll = Instance.new("ScrollingFrame")
    scroll.Size = UDim2.new(1, 0, 1, -50)
    scroll.BackgroundTransparency = 1
    scroll.ScrollBarThickness = 5
    scroll.ScrollBarImageColor3 = Config.Theme.Primary
    scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
    scroll.Parent = contentFrame
    
    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, 8)
    layout.Parent = scroll
    
    if #Memory.Events == 0 then
        local empty = Instance.new("TextLabel")
        empty.Size = UDim2.new(1, -20, 0, 60)
        empty.Position = UDim2.new(0, 10, 0, 10)
        empty.BackgroundColor3 = Config.Theme.Secondary
        empty.Text = "Nenhum evento capturado\nInteraja com o jogo para ver eventos"
        empty.TextColor3 = Config.Theme.Text
        empty.Font = Enum.Font.Gotham
        empty.TextSize = 12
        empty.TextWrapped = true
        empty.Parent = scroll
    else
        for i, event in ipairs(Memory.Events) do
            if i > 15 then break end
            
            local eventFrame = Instance.new("Frame")
            eventFrame.Size = UDim2.new(1, -10, 0, 80)
            eventFrame.BackgroundColor3 = Config.Theme.Secondary
            eventFrame.Parent = scroll
            
            local eventCorner = Instance.new("UICorner")
            eventCorner.CornerRadius = UDim.new(0, 8)
            eventCorner.Parent = eventFrame
            
            -- Informações do evento
            local nameLabel = Instance.new("TextLabel")
            nameLabel.Size = UDim2.new(1, -100, 0, 20)
            nameLabel.Position = UDim2.new(0, 8, 0, 8)
            nameLabel.BackgroundTransparency = 1
            nameLabel.Text = "📡 " .. event.Name
            nameLabel.TextColor3 = Config.Theme.Primary
            nameLabel.Font = Enum.Font.GothamBold
            nameLabel.TextSize = 12
            nameLabel.TextXAlignment = Enum.TextXAlignment.Left
            nameLabel.Parent = eventFrame
            
            local pathLabel = Instance.new("TextLabel")
            pathLabel.Size = UDim2.new(1, -100, 0, 15)
            pathLabel.Position = UDim2.new(0, 8, 0, 30)
            pathLabel.BackgroundTransparency = 1
            pathLabel.Text = event.Path
            pathLabel.TextColor3 = Config.Theme.Text
            pathLabel.Font = Enum.Font.Gotham
            pathLabel.TextSize = 10
            pathLabel.TextXAlignment = Enum.TextXAlignment.Left
            pathLabel.TextTruncate = Enum.TextTruncate.AtEnd
            pathLabel.Parent = eventFrame
            
            local timeLabel = Instance.new("TextLabel")
            timeLabel.Size = UDim2.new(1, -100, 0, 15)
            timeLabel.Position = UDim2.new(0, 8, 0, 47)
            timeLabel.BackgroundTransparency = 1
            timeLabel.Text = "⏰ " .. event.Time
            timeLabel.TextColor3 = Config.Theme.Text
            timeLabel.Font = Enum.Font.Gotham
            timeLabel.TextSize = 10
            timeLabel.TextXAlignment = Enum.TextXAlignment.Left
            timeLabel.Parent = eventFrame
            
            -- Botões de ação
            local playBtn = CreateButton("▶️", Config.Theme.Success, eventFrame,
                UDim2.new(1, -85, 0, 8), UDim2.new(0, 35, 0, 25))
            
            local blockBtn = CreateButton("🚫", Config.Theme.Error, eventFrame,
                UDim2.new(1, -45, 0, 8), UDim2.new(0, 35, 0, 25))
            
            local copyBtn = CreateButton("📋", Config.Theme.Primary, eventFrame,
                UDim2.new(1, -85, 0, 38), UDim2.new(0, 75, 0, 25))
            
            -- Ações dos botões
            playBtn.MouseButton1Click:Connect(function()
                if event.Remote and event.Remote.Parent then
                    if event.Type == "FireServer" then
                        event.Remote:FireServer(unpack(event.Arguments))
                    else
                        event.Remote:InvokeServer(unpack(event.Arguments))
                    end
                end
            end)
            
            blockBtn.MouseButton1Click:Connect(function()
                Memory.Blocked[event.Path] = true
                blockBtn.Text = "✅"
                blockBtn.BackgroundColor3 = Config.Theme.Success
            end)
            
            copyBtn.MouseButton1Click:Connect(function()
                setclipboard(event.Path)
                copyBtn.Text = "✅"
                wait(1)
                copyBtn.Text = "📋"
            end)
        end
    end
    
    -- Botão limpar
    local clearBtn = CreateButton("🗑️ LIMPAR EVENTOS", Config.Theme.Warning, 
        contentFrame, UDim2.new(0, 10, 1, -45), UDim2.new(1, -20, 0, 35))
    
    clearBtn.MouseButton1Click:Connect(function()
        Memory.Events = {}
        TabSystem.ShowEvents()
    end)
end

function TabSystem.ShowKeyLogs()
    ClearContainer(contentFrame)
    
    local scroll = Instance.new("ScrollingFrame")
    scroll.Size = UDim2.new(1, 0, 1, -50)
    scroll.BackgroundTransparency = 1
    scroll.ScrollBarThickness = 5
    scroll.ScrollBarImageColor3 = Config.Theme.Primary
    scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
    scroll.Parent = contentFrame
    
    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, 5)
    layout.Parent = scroll
    
    if #Memory.KeyLogs == 0 then
        local empty = Instance.new("TextLabel")
        empty.Size = UDim2.new(1, -20, 0, 60)
        empty.Position = UDim2.new(0, 10, 0, 10)
        empty.BackgroundColor3 = Config.Theme.Secondary
        empty.Text = "Nenhum key log\nPressione teclas para ver logs"
        empty.TextColor3 = Config.Theme.Text
        empty.Font = Enum.Font.Gotham
        empty.TextSize = 12
        empty.TextWrapped = true
        empty.Parent = scroll
    else
        for i, log in ipairs(Memory.KeyLogs) do
            if i > 20 then break end
            
            local logFrame = Instance.new("Frame")
            logFrame.Size = UDim2.new(1, -10, 0, 25)
            logFrame.BackgroundColor3 = Config.Theme.Secondary
            logFrame.Parent = scroll
            
            local logCorner = Instance.new("UICorner")
            logCorner.CornerRadius = UDim.new(0, 5)
            logCorner.Parent = logFrame
            
            local logText = Instance.new("TextLabel")
            logText.Size = UDim2.new(1, -10, 1, 0)
            logText.Position = UDim2.new(0, 5, 0, 0)
            logText.BackgroundTransparency = 1
            logText.Text = log
            logText.TextColor3 = Config.Theme.Text
            logText.Font = Enum.Font.Code
            logText.TextSize = 11
            logText.TextXAlignment = Enum.TextXAlignment.Left
            logText.Parent = logFrame
        end
    end
    
    local clearBtn = CreateButton("🗑️ LIMPAR KEY LOGS", Config.Theme.Warning, 
        contentFrame, UDim2.new(0, 10, 1, -45), UDim2.new(1, -20, 0, 35))
    
    clearBtn.MouseButton1Click:Connect(function()
        Memory.KeyLogs = {}
        TabSystem.ShowKeyLogs()
    end)
end

function TabSystem.ShowExecutor()
    ClearContainer(contentFrame)
    
    local container = Instance.new("Frame")
    container.Size = UDim2.new(1, 0, 1, 0)
    container.BackgroundTransparency = 1
    container.Parent = contentFrame
    
    local codeBox = Instance.new("TextBox")
    codeBox.Size = UDim2.new(1, -20, 0, 180)
    codeBox.Position = UDim2.new(0, 10, 0, 10)
    codeBox.BackgroundColor3 = Config.Theme.Secondary
    codeBox.TextColor3 = Config.Theme.Text
    codeBox.PlaceholderText = "-- Digite seu código Lua aqui...\nprint('Hello Purple Panel!')"
    codeBox.Text = ""
    codeBox.Font = Enum.Font.Code
    codeBox.TextSize = 11
    codeBox.TextXAlignment = Enum.TextXAlignment.Left
    codeBox.TextYAlignment = Enum.TextYAlignment.Top
    codeBox.MultiLine = true
    codeBox.ClearTextOnFocus = false
    codeBox.Parent = container
    
    local executeBtn = CreateButton("💜 EXECUTAR CÓDIGO", Config.Theme.Success, 
        container, UDim2.new(0, 10, 0, 200), UDim2.new(0.6, -5, 0, 35))
    
    local clearBtn = CreateButton("🗑️ LIMPAR", Config.Theme.Error, 
        container, UDim2.new(0.6, 5, 0, 200), UDim2.new(0.4, -5, 0, 35))
    
    local outputBox = Instance.new("TextBox")
    outputBox.Size = UDim2.new(1, -20, 0, 120)
    outputBox.Position = UDim2.new(0, 10, 0, 245)
    outputBox.BackgroundColor3 = Config.Theme.Secondary
    outputBox.TextColor3 = Color3.fromRGB(0, 255, 100)
    outputBox.Text = "📤 Output aparecerá aqui..."
    outputBox.Font = Enum.Font.Code
    outputBox.TextSize = 11
    outputBox.TextXAlignment = Enum.TextXAlignment.Left
    outputBox.TextYAlignment = Enum.TextYAlignment.Top
    outputBox.MultiLine = true
    outputBox.TextEditable = false
    outputBox.Parent = container
    
    executeBtn.MouseButton1Click:Connect(function()
        local code = codeBox.Text
        if code == "" then return end
        
        executeBtn.Text = "⏳ EXECUTANDO..."
        
        local success, result = pcall(function()
            local func = loadstring(code)
            if func then
                return func()
            end
        end)
        
        if success then
            outputBox.Text = "✅ Código executado com sucesso!"
            if result then
                outputBox.Text = outputBox.Text .. "\n📦 Retorno: " .. tostring(result)
            end
        else
            outputBox.Text = "❌ Erro: " .. tostring(result)
        end
        
        wait(1)
        executeBtn.Text = "💜 EXECUTAR CÓDIGO"
    end)
    
    clearBtn.MouseButton1Click:Connect(function()
        codeBox.Text = ""
        outputBox.Text = "🗑️ Código limpo!"
    end)
end

function TabSystem.ShowDump()
    ClearContainer(contentFrame)
    
    local container = Instance.new("Frame")
    container.Size = UDim2.new(1, 0, 1, 0)
    container.BackgroundTransparency = 1
    container.Parent = contentFrame
    
    local infoText = Instance.new("TextLabel")
    infoText.Size = UDim2.new(1, -20, 0, 100)
    infoText.Position = UDim2.new(0, 10, 0, 10)
    infoText.BackgroundColor3 = Config.Theme.Secondary
    infoText.Text = "💾 SISTEMA DE DUMP\n\n• Extrai scripts do jogo\n• Salva em arquivo .lua\n• Processa serviços principais\n• Código fonte real"
    infoText.TextColor3 = Config.Theme.Text
    infoText.Font = Enum.Font.Gotham
    infoText.TextSize = 12
    infoText.TextYAlignment = Enum.TextYAlignment.Top
    infoText.TextWrapped = true
    infoText.Parent = container
    
    local dumpBtn = CreateButton("🚀 INICIAR DUMP COMPLETO", Config.Theme.Primary, 
        container, UDim2.new(0, 10, 0, 120), UDim2.new(1, -20, 0, 35))
    
    local outputBox = Instance.new("TextBox")
    outputBox.Size = UDim2.new(1, -20, 0, 200)
    outputBox.Position = UDim2.new(0, 10, 0, 165)
    outputBox.BackgroundColor3 = Config.Theme.Secondary
    outputBox.TextColor3 = Config.Theme.Text
    outputBox.Text = "Clique em INICIAR DUMP para começar..."
    outputBox.Font = Enum.Font.Code
    outputBox.TextSize = 10
    outputBox.TextXAlignment = Enum.TextXAlignment.Left
    outputBox.TextYAlignment = Enum.TextYAlignment.Top
    outputBox.MultiLine = true
    outputBox.TextEditable = false
    outputBox.Parent = container
    
    dumpBtn.MouseButton1Click:Connect(function()
        dumpBtn.Text = "⏳ DUMPANDO..."
        outputBox.Text = "🚀 INICIANDO DUMP COMPLETO...\n\n"
        
        local scripts = 0
        for _, serviceName in ipairs({"Workspace", "ReplicatedStorage", "ServerScriptService"}) do
            local service = game:GetService(serviceName)
            outputBox.Text = outputBox.Text .. "📂 " .. serviceName .. "\n"
            
            for _, obj in ipairs(service:GetDescendants()) do
                if obj:IsA("Script") or obj:IsA("LocalScript") or obj:IsA("ModuleScript") then
                    scripts = scripts + 1
                end
            end
        end
        
        outputBox.Text = outputBox.Text .. string.format("\n✅ DUMP COMPLETO!\n📊 Scripts encontrados: %d", scripts)
        
        if writefile then
            pcall(function()
                writefile("purple_dump.txt", "Dump completo - " .. scripts .. " scripts")
                outputBox.Text = outputBox.Text .. "\n💾 Arquivo salvo: purple_dump.txt"
            end)
        end
        
        dumpBtn.Text = "🚀 INICIAR DUMP"
    end)
end

-- ========== SISTEMA DE CONTROLE ==========
print("🎮 CONFIGURANDO CONTROLES...")

local function SwitchTab(tabName)
    Memory.CurrentTab = tabName
    
    -- Atualizar botões das abas
    for name, btn in pairs(tabButtons) do
        btn.BackgroundColor3 = name == tabName and Config.Theme.Primary or Config.Theme.Surface
    end
    
    -- Mostrar conteúdo da aba
    if tabName == "Home" then
        TabSystem.ShowHome()
    elseif tabName == "Events" then
        TabSystem.ShowEvents()
    elseif tabName == "KeyLogs" then
        TabSystem.ShowKeyLogs()
    elseif tabName == "Executor" then
        TabSystem.ShowExecutor()
    elseif tabName == "Dump" then
        TabSystem.ShowDump()
    end
end

-- Configurar eventos das abas
for tabName, btn in pairs(tabButtons) do
    btn.MouseButton1Click:Connect(function()
        SwitchTab(tabName)
    end)
end

-- ========== CONTROLE DA UI ==========
local isUIVisible = false

local function ToggleUI()
    isUIVisible = not isUIVisible
    mainFrame.Visible = isUIVisible
    
    if isUIVisible then
        SwitchTab(Memory.CurrentTab)
    end
end

closeBtn.MouseButton1Click:Connect(ToggleUI)

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if not gameProcessed and input.KeyCode == Enum.KeyCode.F then
        ToggleUI()
    end
end)

-- ========== INICIALIZAÇÃO FINAL ==========
print("🚀 INICIANDO SISTEMAS...")

-- Configurar hook
SetupHookSystem()

-- Ativar captura por padrão
Memory.IsCapturing = true

print("✅ TODOS OS SISTEMAS CARREGADOS!")
print("💜 PURPLE PANEL - PRONTO PARA USO!")
print("🔧 PRESSIONE F PARA ABRIR O MENU")

-- Mostrar UI após 2 segundos
wait(2)
ToggleUI()

print("🎉 UI INICIADA COM SUCESSO!")
