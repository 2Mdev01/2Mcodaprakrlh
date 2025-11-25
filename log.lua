-- Purple Panel - COMPLETO com todas as funcionalidades
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")

-- Dados em memória
local Memory = {
    Events = {},
    Blocked = {},
    KeyLogs = {},
    LastTab = "Home"
}

-- Criar a UI
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "PurplePanelComplete"
screenGui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")

local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 600, 0, 450)
mainFrame.Position = UDim2.new(0.5, -300, 0.5, -225)
mainFrame.BackgroundColor3 = Color3.fromRGB(40, 35, 55)
mainFrame.BorderSizePixel = 0
mainFrame.Visible = false
mainFrame.Parent = screenGui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 10)
corner.Parent = mainFrame

-- Header
local header = Instance.new("Frame")
header.Size = UDim2.new(1, 0, 0, 40)
header.BackgroundColor3 = Color3.fromRGB(147, 51, 234)
header.BorderSizePixel = 0
header.Parent = mainFrame

local headerCorner = Instance.new("UICorner")
headerCorner.CornerRadius = UDim.new(0, 10)
headerCorner.Parent = header

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -50, 1, 0)
title.Position = UDim2.new(0, 10, 0, 0)
title.BackgroundTransparency = 1
title.Text = "💜 Purple Panel - COMPLETO"
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.Font = Enum.Font.GothamBold
title.TextSize = 16
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = header

local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 30, 0, 30)
closeBtn.Position = UDim2.new(1, -35, 0, 5)
closeBtn.BackgroundColor3 = Color3.fromRGB(255, 85, 85)
closeBtn.Text = "X"
closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextSize = 14
closeBtn.BorderSizePixel = 0
closeBtn.Parent = header

local btnCorner = Instance.new("UICorner")
btnCorner.CornerRadius = UDim.new(0, 6)
btnCorner.Parent = closeBtn

-- Abas
local tabsFrame = Instance.new("Frame")
tabsFrame.Size = UDim2.new(1, -20, 0, 35)
tabsFrame.Position = UDim2.new(0, 10, 0, 45)
tabsFrame.BackgroundTransparency = 1
tabsFrame.Parent = mainFrame

local tabs = {"Home", "Event Logs", "Key Logs", "Executor", "Dump"}
local currentTab = "Home"

for i, tabName in ipairs(tabs) do
    local tabBtn = Instance.new("TextButton")
    tabBtn.Size = UDim2.new(0, 110, 1, 0)
    tabBtn.Position = UDim2.new(0, (i-1)*115, 0, 0)
    tabBtn.BackgroundColor3 = tabName == "Home" and Color3.fromRGB(147, 51, 234) or Color3.fromRGB(60, 55, 75)
    tabBtn.Text = tabName
    tabBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    tabBtn.Font = Enum.Font.GothamBold
    tabBtn.TextSize = 12
    tabBtn.BorderSizePixel = 0
    tabBtn.Parent = tabsFrame
    
    local tabCorner = Instance.new("UICorner")
    tabCorner.CornerRadius = UDim.new(0, 6)
    tabCorner.Parent = tabBtn
    
    tabBtn.MouseButton1Click:Connect(function()
        currentTab = tabName
        updateTabs()
        showTabContent(tabName)
    end)
end

-- Conteúdo
local contentFrame = Instance.new("Frame")
contentFrame.Size = UDim2.new(1, -20, 1, -90)
contentFrame.Position = UDim2.new(0, 10, 0, 85)
contentFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
contentFrame.BorderSizePixel = 0
contentFrame.Parent = mainFrame

local contentCorner = Instance.new("UICorner")
contentCorner.CornerRadius = UDim.new(0, 8)
contentCorner.Parent = contentFrame

-- Funções
local function updateTabs()
    for i, child in ipairs(tabsFrame:GetChildren()) do
        if child:IsA("TextButton") then
            child.BackgroundColor3 = child.Text == currentTab and Color3.fromRGB(147, 51, 234) or Color3.fromRGB(60, 55, 75)
        end
    end
end

local function clearContent()
    for _, child in ipairs(contentFrame:GetChildren()) do
        if child:IsA("Frame") or child:IsA("ScrollingFrame") then
            child:Destroy()
        end
    end
end

local function createButton(text, color, parent, position, size)
    local btn = Instance.new("TextButton")
    btn.Size = size or UDim2.new(0.48, 0, 0, 35)
    btn.Position = position or UDim2.new(0, 0, 0, 0)
    btn.BackgroundColor3 = color
    btn.Text = text
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 12
    btn.BorderSizePixel = 0
    btn.Parent = parent
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = btn
    
    return btn
end

-- ========== ABA HOME ==========
local function showHomeTab()
    clearContent()
    
    local container = Instance.new("Frame")
    container.Size = UDim2.new(1, 0, 1, 0)
    container.BackgroundTransparency = 1
    container.Parent = contentFrame
    
    -- Status
    local statusFrame = Instance.new("Frame")
    statusFrame.Size = UDim2.new(1, -20, 0, 100)
    statusFrame.Position = UDim2.new(0, 10, 0, 10)
    statusFrame.BackgroundColor3 = Color3.fromRGB(50, 45, 65)
    statusFrame.Parent = container
    
    local statusCorner = Instance.new("UICorner")
    statusCorner.CornerRadius = UDim.new(0, 8)
    statusCorner.Parent = statusFrame
    
    local statusText = Instance.new("TextLabel")
    statusText.Size = UDim2.new(1, -20, 1, -20)
    statusText.Position = UDim2.new(0, 10, 0, 10)
    statusText.BackgroundTransparency = 1
    statusText.Text = string.format("📊 STATUS DO SISTEMA\n\n• Eventos Capturados: %d\n• Key Logs: %d\n• Eventos Bloqueados: %d\n• Hook Ativo: ✅", 
        #Memory.Events, #Memory.KeyLogs, #Memory.Blocked)
    statusText.TextColor3 = Color3.fromRGB(255, 255, 255)
    statusText.Font = Enum.Font.Gotham
    statusText.TextSize = 12
    statusText.TextYAlignment = Enum.TextYAlignment.Top
    statusText.TextWrapped = true
    statusText.Parent = statusFrame
    
    -- Botões de ação
    local startBtn = createButton("🟢 INICIAR CAPTURA", Color3.fromRGB(72, 199, 142), container,
        UDim2.new(0, 10, 0, 120), UDim2.new(0.48, 0, 0, 35))
    
    local clearBtn = createButton("🗑️ LIMPAR TUDO", Color3.fromRGB(255, 85, 85), container,
        UDim2.new(0.52, 10, 0, 120), UDim2.new(0.48, 0, 0, 35))
    
    local dumpBtn = createButton("💾 FAZER DUMP", Color3.fromRGB(147, 51, 234), container,
        UDim2.new(0, 10, 0, 165), UDim2.new(1, -20, 0, 35))
    
    startBtn.MouseButton1Click:Connect(function()
        startCapture()
        startBtn.Text = "🔴 CAPTURANDO..."
        startBtn.BackgroundColor3 = Color3.fromRGB(255, 85, 85)
    end)
    
    clearBtn.MouseButton1Click:Connect(function()
        Memory.Events = {}
        Memory.KeyLogs = {}
        showHomeTab()
    end)
    
    dumpBtn.MouseButton1Click:Connect(function()
        performDump()
    end)
end

-- ========== ABA EVENT LOGS ==========
local function showEventLogsTab()
    clearContent()
    
    local scroll = Instance.new("ScrollingFrame")
    scroll.Size = UDim2.new(1, 0, 1, 0)
    scroll.BackgroundTransparency = 1
    scroll.ScrollBarThickness = 5
    scroll.ScrollBarImageColor3 = Color3.fromRGB(147, 51, 234)
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
        empty.BackgroundColor3 = Color3.fromRGB(50, 45, 65)
        empty.Text = "Nenhum evento capturado\nInteraja com o jogo para ver eventos"
        empty.TextColor3 = Color3.fromRGB(200, 200, 200)
        empty.Font = Enum.Font.Gotham
        empty.TextSize = 12
        empty.TextWrapped = true
        empty.Parent = scroll
        
        local emptyCorner = Instance.new("UICorner")
        emptyCorner.CornerRadius = UDim.new(0, 8)
        emptyCorner.Parent = empty
    else
        for i, event in ipairs(Memory.Events) do
            if i > 15 then break end
            
            local eventFrame = Instance.new("Frame")
            eventFrame.Size = UDim2.new(1, -10, 0, 80)
            eventFrame.BackgroundColor3 = Color3.fromRGB(50, 45, 65)
            eventFrame.Parent = scroll
            
            local eventCorner = Instance.new("UICorner")
            eventCorner.CornerRadius = UDim.new(0, 8)
            eventCorner.Parent = eventFrame
            
            local nameLabel = Instance.new("TextLabel")
            nameLabel.Size = UDim2.new(1, -100, 0, 20)
            nameLabel.Position = UDim2.new(0, 8, 0, 8)
            nameLabel.BackgroundTransparency = 1
            nameLabel.Text = "📡 " .. event.name
            nameLabel.TextColor3 = Color3.fromRGB(147, 51, 234)
            nameLabel.Font = Enum.Font.GothamBold
            nameLabel.TextSize = 12
            nameLabel.TextXAlignment = Enum.TextXAlignment.Left
            nameLabel.Parent = eventFrame
            
            local pathLabel = Instance.new("TextLabel")
            pathLabel.Size = UDim2.new(1, -100, 0, 15)
            pathLabel.Position = UDim2.new(0, 8, 0, 30)
            pathLabel.BackgroundTransparency = 1
            pathLabel.Text = event.path or "Caminho"
            pathLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
            pathLabel.Font = Enum.Font.Gotham
            pathLabel.TextSize = 10
            pathLabel.TextXAlignment = Enum.TextXAlignment.Left
            pathLabel.TextTruncate = Enum.TextTruncate.AtEnd
            pathLabel.Parent = eventFrame
            
            local timeLabel = Instance.new("TextLabel")
            timeLabel.Size = UDim2.new(1, -100, 0, 15)
            timeLabel.Position = UDim2.new(0, 8, 0, 47)
            timeLabel.BackgroundTransparency = 1
            timeLabel.Text = "⏰ " .. event.time
            timeLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
            timeLabel.Font = Enum.Font.Gotham
            timeLabel.TextSize = 10
            timeLabel.TextXAlignment = Enum.TextXAlignment.Left
            timeLabel.Parent = eventFrame
            
            -- Botões
            local playBtn = createButton("▶️", Color3.fromRGB(72, 199, 142), eventFrame,
                UDim2.new(1, -85, 0, 8), UDim2.new(0, 35, 0, 25))
            
            local blockBtn = createButton("🚫", Color3.fromRGB(255, 85, 85), eventFrame,
                UDim2.new(1, -45, 0, 8), UDim2.new(0, 35, 0, 25))
            
            local copyBtn = createButton("📋", Color3.fromRGB(147, 51, 234), eventFrame,
                UDim2.new(1, -85, 0, 38), UDim2.new(0, 75, 0, 25))
            
            playBtn.MouseButton1Click:Connect(function()
                replayEvent(event)
            end)
            
            blockBtn.MouseButton1Click:Connect(function()
                Memory.Blocked[event.path] = true
                blockBtn.Text = "✅"
                blockBtn.BackgroundColor3 = Color3.fromRGB(72, 199, 142)
            end)
            
            copyBtn.MouseButton1Click:Connect(function()
                setclipboard(event.path)
                copyBtn.Text = "✅"
                wait(1)
                copyBtn.Text = "📋"
            end)
        end
    end
end

-- ========== ABA KEY LOGS ==========
local function showKeyLogsTab()
    clearContent()
    
    local scroll = Instance.new("ScrollingFrame")
    scroll.Size = UDim2.new(1, 0, 1, 0)
    scroll.BackgroundTransparency = 1
    scroll.ScrollBarThickness = 5
    scroll.ScrollBarImageColor3 = Color3.fromRGB(147, 51, 234)
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
        empty.BackgroundColor3 = Color3.fromRGB(50, 45, 65)
        empty.Text = "Nenhum key log\nPressione teclas para ver logs"
        empty.TextColor3 = Color3.fromRGB(200, 200, 200)
        empty.Font = Enum.Font.Gotham
        empty.TextSize = 12
        empty.TextWrapped = true
        empty.Parent = scroll
    else
        for i, log in ipairs(Memory.KeyLogs) do
            if i > 20 then break end
            
            local logFrame = Instance.new("Frame")
            logFrame.Size = UDim2.new(1, -10, 0, 25)
            logFrame.BackgroundColor3 = Color3.fromRGB(50, 45, 65)
            logFrame.Parent = scroll
            
            local logCorner = Instance.new("UICorner")
            logCorner.CornerRadius = UDim.new(0, 5)
            logCorner.Parent = logFrame
            
            local logText = Instance.new("TextLabel")
            logText.Size = UDim2.new(1, -10, 1, 0)
            logText.Position = UDim2.new(0, 5, 0, 0)
            logText.BackgroundTransparency = 1
            logText.Text = log
            logText.TextColor3 = Color3.fromRGB(255, 255, 255)
            logText.Font = Enum.Font.Code
            logText.TextSize = 11
            logText.TextXAlignment = Enum.TextXAlignment.Left
            logText.Parent = logFrame
        end
    end
    
    local clearBtn = createButton("🗑️ LIMPAR KEY LOGS", Color3.fromRGB(255, 85, 85), contentFrame,
        UDim2.new(0, 10, 1, -40), UDim2.new(1, -20, 0, 30))
    
    clearBtn.MouseButton1Click:Connect(function()
        Memory.KeyLogs = {}
        showKeyLogsTab()
    end)
end

-- ========== ABA EXECUTOR ==========
local function showExecutorTab()
    clearContent()
    
    local container = Instance.new("Frame")
    container.Size = UDim2.new(1, 0, 1, 0)
    container.BackgroundTransparency = 1
    container.Parent = contentFrame
    
    local codeBox = Instance.new("TextBox")
    codeBox.Size = UDim2.new(1, -20, 0, 200)
    codeBox.Position = UDim2.new(0, 10, 0, 10)
    codeBox.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
    codeBox.TextColor3 = Color3.fromRGB(255, 255, 255)
    codeBox.PlaceholderText = "-- Digite seu código Lua aqui...\nprint('Hello Purple Panel!')"
    codeBox.Text = ""
    codeBox.Font = Enum.Font.Code
    codeBox.TextSize = 11
    codeBox.TextXAlignment = Enum.TextXAlignment.Left
    codeBox.TextYAlignment = Enum.TextYAlignment.Top
    codeBox.MultiLine = true
    codeBox.ClearTextOnFocus = false
    codeBox.Parent = container
    
    local executeBtn = createButton("💜 EXECUTAR CÓDIGO", Color3.fromRGB(72, 199, 142), container,
        UDim2.new(0, 10, 0, 220), UDim2.new(0.6, -5, 0, 35))
    
    local clearBtn = createButton("🗑️ LIMPAR", Color3.fromRGB(255, 85, 85), container,
        UDim2.new(0.6, 5, 0, 220), UDim2.new(0.4, -5, 0, 35))
    
    local outputBox = Instance.new("TextBox")
    outputBox.Size = UDim2.new(1, -20, 0, 120)
    outputBox.Position = UDim2.new(0, 10, 0, 265)
    outputBox.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
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
        
        task.spawn(function()
            local success, result = pcall(loadstring(code))
            
            if success then
                outputBox.Text = "✅ Código executado com sucesso!"
                if result then
                    outputBox.Text = outputBox.Text .. "\n" .. tostring(result)
                end
            else
                outputBox.Text = "❌ Erro: " .. tostring(result)
            end
            
            wait(1)
            executeBtn.Text = "💜 EXECUTAR CÓDIGO"
        end)
    end)
    
    clearBtn.MouseButton1Click:Connect(function()
        codeBox.Text = ""
        outputBox.Text = "🗑️ Código limpo!"
    end)
end

-- ========== ABA DUMP ==========
local function showDumpTab()
    clearContent()
    
    local container = Instance.new("Frame")
    container.Size = UDim2.new(1, 0, 1, 0)
    container.BackgroundTransparency = 1
    container.Parent = contentFrame
    
    local infoText = Instance.new("TextLabel")
    infoText.Size = UDim2.new(1, -20, 0, 120)
    infoText.Position = UDim2.new(0, 10, 0, 10)
    infoText.BackgroundColor3 = Color3.fromRGB(50, 45, 65)
    infoText.Text = "💾 SISTEMA DE DUMP\n\n• Extrai scripts do jogo\n• Salva em arquivo .lua\n• Processa todos os serviços\n• Código fonte real"
    infoText.TextColor3 = Color3.fromRGB(255, 255, 255)
    infoText.Font = Enum.Font.Gotham
    infoText.TextSize = 12
    infoText.TextYAlignment = Enum.TextYAlignment.Top
    infoText.TextWrapped = true
    infoText.Parent = container
    
    local dumpBtn = createButton("🚀 INICIAR DUMP COMPLETO", Color3.fromRGB(147, 51, 234), container,
        UDim2.new(0, 10, 0, 140), UDim2.new(1, -20, 0, 35))
    
    local outputBox = Instance.new("TextBox")
    outputBox.Size = UDim2.new(1, -20, 0, 200)
    outputBox.Position = UDim2.new(0, 10, 0, 185)
    outputBox.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
    outputBox.TextColor3 = Color3.fromRGB(255, 255, 255)
    outputBox.Text = "Aguardando dump..."
    outputBox.Font = Enum.Font.Code
    outputBox.TextSize = 10
    outputBox.TextXAlignment = Enum.TextXAlignment.Left
    outputBox.TextYAlignment = Enum.TextYAlignment.Top
    outputBox.MultiLine = true
    outputBox.TextEditable = false
    outputBox.Parent = container
    
    dumpBtn.MouseButton1Click:Connect(function()
        dumpBtn.Text = "⏳ DUMPANDO..."
        performFullDump(outputBox)
    end)
end

-- ========== SISTEMA DE CAPTURA ==========
local function captureEvent(remote, method, args)
    local path = remote:GetFullName()
    
    if Memory.Blocked[path] then return end
    
    local eventData = {
        name = remote.Name,
        type = method,
        path = path,
        time = os.date("%H:%M:%S"),
        args = args or {}
    }
    
    table.insert(Memory.Events, 1, eventData)
    if #Memory.Events > 50 then table.remove(Memory.Events) end
    
    if currentTab == "Event Logs" then
        showEventLogsTab()
    end
end

local function startCapture()
    if hookmetamethod then
        local original
        original = hookmetamethod(game, "__namecall", function(self, ...)
            local method = getnamecallmethod()
            if (method == "FireServer" or method == "InvokeServer") and typeof(self) == "Instance" then
                task.spawn(captureEvent, self, method, {...})
            end
            return original(self, ...)
        end)
    end
end

local function replayEvent(event)
    if event.remote then
        if event.type == "FireServer" then
            event.remote:FireServer(unpack(event.args))
        else
            event.remote:InvokeServer(unpack(event.args))
        end
    end
end

-- ========== KEY LOGGER ==========
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    local keyName = input.KeyCode.Name
    if keyName ~= "Unknown" then
        local logEntry = string.format("[%s] %s %s", 
            os.date("%H:%M:%S"), 
            gameProcessed and "🔒" : "💜",
            keyName
        )
        table.insert(Memory.KeyLogs, 1, logEntry)
        if #Memory.KeyLogs > 100 then table.remove(Memory.KeyLogs) end
        
        if currentTab == "Key Logs" then
            showKeyLogsTab()
        end
    end
end)

-- ========== SISTEMA DE DUMP ==========
local function performFullDump(outputBox)
    outputBox.Text = "🚀 INICIANDO DUMP...\n\n"
    
    task.spawn(function()
        local scriptsFound = 0
        local dumpContent = "-- PURPLE PANEL DUMP\n-- " .. os.date() .. "\n\n"
        
        local services = {
            "Workspace", "ReplicatedStorage", "ServerScriptService", 
            "ServerStorage", "StarterGui", "StarterPlayer"
        }
        
        for _, serviceName in ipairs(services) do
            local service = game:GetService(serviceName)
            outputBox.Text = outputBox.Text .. "📂 " .. serviceName .. "\n"
            
            for _, obj in ipairs(service:GetDescendants()) do
                if obj:IsA("Script") or obj:IsA("LocalScript") or obj:IsA("ModuleScript") then
                    scriptsFound = scriptsFound + 1
                    dumpContent = dumpContent .. "\n-- " .. obj:GetFullName() .. "\n"
                    
                    local success, source = pcall(function() return obj.Source end)
                    if success and source then
                        dumpContent = dumpContent .. source .. "\n"
                    else
                        dumpContent = dumpContent .. "-- [PROTECTED SCRIPT]\n"
                    end
                end
            end
        end
        
        outputBox.Text = outputBox.Text .. string.format("\n✅ DUMP COMPLETO!\nScripts encontrados: %d", scriptsFound)
        
        if writefile then
            local filename = "purple_dump_" .. os.time() .. ".lua"
            pcall(function()
                writefile(filename, dumpContent)
                outputBox.Text = outputBox.Text .. "\n💾 Salvo como: " .. filename
            end)
        end
    end)
end

-- ========== CONTROLE DA UI ==========
function showTabContent(tabName)
    if tabName == "Home" then
        showHomeTab()
    elseif tabName == "Event Logs" then
        showEventLogsTab()
    elseif tabName == "Key Logs" then
        showKeyLogsTab()
    elseif tabName == "Executor" then
        showExecutorTab()
    elseif tabName == "Dump" then
        showDumpTab()
    end
end

local isVisible = false

local function toggleUI()
    isVisible = not isVisible
    mainFrame.Visible = isVisible
    if isVisible then
        showTabContent(currentTab)
    end
end

closeBtn.MouseButton1Click:Connect(toggleUI)

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if not gameProcessed and input.KeyCode == Enum.KeyCode.F then
        toggleUI()
    end
end)

-- ========== INICIALIZAÇÃO ==========
print("💜 PURPLE PANEL - COMPLETO")
print("✅ TODAS AS FUNCIONALIDADES CARREGADAS")
print("🔧 PRESSIONE F PARA ABRIR")

-- Iniciar captura automaticamente
startCapture()

-- Mostrar UI após 2 segundos
wait(2)
toggleUI()
