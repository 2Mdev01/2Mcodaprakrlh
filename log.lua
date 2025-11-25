-- Purple Panel - Xeno Edition
-- Versão Ultra Simples e Testada

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

print("🎯 Iniciando Purple Panel...")

-- Criar UI básica
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "XenoPurplePanel"
screenGui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")

local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 500, 0, 400)
mainFrame.Position = UDim2.new(0.5, -250, 0.5, -200)
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

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -50, 1, 0)
title.Position = UDim2.new(0, 10, 0, 0)
title.BackgroundTransparency = 1
title.Text = "💜 Purple Panel - XENO"
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

-- Abas simples
local tabs = {"Logger", "Executor", "Dump"}
local currentTab = "Logger"

for i, tabName in ipairs(tabs) do
    local tabBtn = Instance.new("TextButton")
    tabBtn.Size = UDim2.new(0, 100, 0, 30)
    tabBtn.Position = UDim2.new(0, 10 + (i-1)*110, 0, 45)
    tabBtn.BackgroundColor3 = tabName == "Logger" and Color3.fromRGB(147, 51, 234) or Color3.fromRGB(60, 55, 75)
    tabBtn.Text = tabName
    tabBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    tabBtn.Font = Enum.Font.GothamBold
    tabBtn.TextSize = 12
    tabBtn.BorderSizePixel = 0
    tabBtn.Parent = mainFrame
    
    tabBtn.MouseButton1Click:Connect(function()
        currentTab = tabName
        -- Atualizar cores das abas
        for j, child in ipairs(mainFrame:GetChildren()) do
            if child:IsA("TextButton") and child ~= closeBtn then
                child.BackgroundColor3 = child.Text == tabName and Color3.fromRGB(147, 51, 234) or Color3.fromRGB(60, 55, 75)
            end
        end
        updateContent()
    end)
end

-- Área de conteúdo
local contentFrame = Instance.new("Frame")
contentFrame.Size = UDim2.new(1, -20, 1, -90)
contentFrame.Position = UDim2.new(0, 10, 0, 85)
contentFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
contentFrame.BorderSizePixel = 0
contentFrame.Parent = mainFrame

-- Dados
local events = {}
local isCapturing = false

-- Função para atualizar conteúdo
function updateContent()
    -- Limpar conteúdo anterior
    for _, child in ipairs(contentFrame:GetChildren()) do
        child:Destroy()
    end
    
    if currentTab == "Logger" then
        showLoggerTab()
    elseif currentTab == "Executor" then
        showExecutorTab()
    elseif currentTab == "Dump" then
        showDumpTab()
    end
end

-- ABA LOGGER
function showLoggerTab()
    local scroll = Instance.new("ScrollingFrame")
    scroll.Size = UDim2.new(1, 0, 1, -50)
    scroll.BackgroundTransparency = 1
    scroll.ScrollBarThickness = 5
    scroll.ScrollBarImageColor3 = Color3.fromRGB(147, 51, 234)
    scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
    scroll.Parent = contentFrame
    
    if #events == 0 then
        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(1, -20, 0, 60)
        label.Position = UDim2.new(0, 10, 0, 10)
        label.BackgroundColor3 = Color3.fromRGB(50, 45, 65)
        label.Text = "Nenhum evento capturado\nInteraja com o jogo"
        label.TextColor3 = Color3.fromRGB(200, 200, 200)
        label.Font = Enum.Font.Gotham
        label.TextSize = 12
        label.TextWrapped = true
        label.Parent = scroll
    else
        for i, event in ipairs(events) do
            if i > 10 then break end
            
            local frame = Instance.new("Frame")
            frame.Size = UDim2.new(1, -10, 0, 60)
            frame.BackgroundColor3 = Color3.fromRGB(50, 45, 65)
            frame.Parent = scroll
            
            local name = Instance.new("TextLabel")
            name.Size = UDim2.new(1, -80, 0, 20)
            name.Position = UDim2.new(0, 8, 0, 8)
            name.BackgroundTransparency = 1
            name.Text = "📡 " .. event.name
            name.TextColor3 = Color3.fromRGB(147, 51, 234)
            name.Font = Enum.Font.GothamBold
            name.TextSize = 12
            name.TextXAlignment = Enum.TextXAlignment.Left
            name.Parent = frame
            
            local path = Instance.new("TextLabel")
            path.Size = UDim2.new(1, -80, 0, 15)
            path.Position = UDim2.new(0, 8, 0, 30)
            path.BackgroundTransparency = 1
            path.Text = event.path
            path.TextColor3 = Color3.fromRGB(200, 200, 200)
            path.Font = Enum.Font.Gotham
            path.TextSize = 10
            path.TextXAlignment = Enum.TextXAlignment.Left
            path.TextTruncate = Enum.TextTruncate.AtEnd
            path.Parent = frame
            
            local time = Instance.new("TextLabel")
            time.Size = UDim2.new(1, -80, 0, 15)
            time.Position = UDim2.new(0, 8, 0, 45)
            time.BackgroundTransparency = 1
            time.Text = "⏰ " .. event.time
            time.TextColor3 = Color3.fromRGB(200, 200, 200)
            time.Font = Enum.Font.Gotham
            time.TextSize = 10
            time.TextXAlignment = Enum.TextXAlignment.Left
            time.Parent = frame
            
            local copyBtn = Instance.new("TextButton")
            copyBtn.Size = UDim2.new(0, 60, 0, 25)
            copyBtn.Position = UDim2.new(1, -65, 0, 8)
            copyBtn.BackgroundColor3 = Color3.fromRGB(147, 51, 234)
            copyBtn.Text = "📋"
            copyBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
            copyBtn.Font = Enum.Font.GothamBold
            copyBtn.TextSize = 12
            copyBtn.BorderSizePixel = 0
            copyBtn.Parent = frame
            
            copyBtn.MouseButton1Click:Connect(function()
                setclipboard(event.path)
                copyBtn.Text = "✅"
                wait(1)
                copyBtn.Text = "📋"
            end)
        end
    end
    
    -- Botões de controle
    local startBtn = Instance.new("TextButton")
    startBtn.Size = UDim2.new(0, 120, 0, 35)
    startBtn.Position = UDim2.new(0, 10, 1, -45)
    startBtn.BackgroundColor3 = isCapturing and Color3.fromRGB(255, 85, 85) or Color3.fromRGB(72, 199, 142)
    startBtn.Text = isCapturing and "🔴 PARAR" or "🟢 INICIAR"
    startBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    startBtn.Font = Enum.Font.GothamBold
    startBtn.TextSize = 12
    startBtn.BorderSizePixel = 0
    startBtn.Parent = contentFrame
    
    local clearBtn = Instance.new("TextButton")
    clearBtn.Size = UDim2.new(0, 120, 0, 35)
    clearBtn.Position = UDim2.new(1, -130, 1, -45)
    clearBtn.BackgroundColor3 = Color3.fromRGB(255, 159, 28)
    clearBtn.Text = "🗑️ LIMPAR"
    clearBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    clearBtn.Font = Enum.Font.GothamBold
    clearBtn.TextSize = 12
    clearBtn.BorderSizePixel = 0
    clearBtn.Parent = contentFrame
    
    startBtn.MouseButton1Click:Connect(function()
        isCapturing = not isCapturing
        startBtn.Text = isCapturing and "🔴 PARAR" or "🟢 INICIAR"
        startBtn.BackgroundColor3 = isCapturing and Color3.fromRGB(255, 85, 85) or Color3.fromRGB(72, 199, 142)
    end)
    
    clearBtn.MouseButton1Click:Connect(function()
        events = {}
        updateContent()
    end)
end

-- ABA EXECUTOR
function showExecutorTab()
    local codeBox = Instance.new("TextBox")
    codeBox.Size = UDim2.new(1, -20, 0, 150)
    codeBox.Position = UDim2.new(0, 10, 0, 10)
    codeBox.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
    codeBox.TextColor3 = Color3.fromRGB(255, 255, 255)
    codeBox.PlaceholderText = "print('Hello Xeno!')\n-- Digite seu código aqui"
    codeBox.Text = ""
    codeBox.Font = Enum.Font.Code
    codeBox.TextSize = 11
    codeBox.TextXAlignment = Enum.TextXAlignment.Left
    codeBox.TextYAlignment = Enum.TextYAlignment.Top
    codeBox.MultiLine = true
    codeBox.ClearTextOnFocus = false
    codeBox.Parent = contentFrame
    
    local executeBtn = Instance.new("TextButton")
    executeBtn.Size = UDim2.new(0, 150, 0, 35)
    executeBtn.Position = UDim2.new(0, 10, 0, 170)
    executeBtn.BackgroundColor3 = Color3.fromRGB(72, 199, 142)
    executeBtn.Text = "💜 EXECUTAR"
    executeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    executeBtn.Font = Enum.Font.GothamBold
    executeBtn.TextSize = 12
    executeBtn.BorderSizePixel = 0
    executeBtn.Parent = contentFrame
    
    local outputBox = Instance.new("TextBox")
    outputBox.Size = UDim2.new(1, -20, 0, 120)
    outputBox.Position = UDim2.new(0, 10, 0, 215)
    outputBox.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
    outputBox.TextColor3 = Color3.fromRGB(0, 255, 100)
    outputBox.Text = "Output aparecerá aqui..."
    outputBox.Font = Enum.Font.Code
    outputBox.TextSize = 11
    outputBox.TextXAlignment = Enum.TextXAlignment.Left
    outputBox.TextYAlignment = Enum.TextYAlignment.Top
    outputBox.MultiLine = true
    outputBox.TextEditable = false
    outputBox.Parent = contentFrame
    
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
            outputBox.Text = "✅ Código executado!"
            if result then
                outputBox.Text = outputBox.Text .. "\n" .. tostring(result)
            end
        else
            outputBox.Text = "❌ Erro: " .. tostring(result)
        end
        
        wait(1)
        executeBtn.Text = "💜 EXECUTAR"
    end)
end

-- ABA DUMP
function showDumpTab()
    local info = Instance.new("TextLabel")
    info.Size = UDim2.new(1, -20, 0, 80)
    info.Position = UDim2.new(0, 10, 0, 10)
    info.BackgroundColor3 = Color3.fromRGB(50, 45, 65)
    info.Text = "💾 SISTEMA DE DUMP\n\nExtrai scripts do jogo\nSalva em arquivo .lua"
    info.TextColor3 = Color3.fromRGB(255, 255, 255)
    info.Font = Enum.Font.Gotham
    info.TextSize = 12
    info.TextYAlignment = Enum.TextYAlignment.Top
    info.TextWrapped = true
    info.Parent = contentFrame
    
    local dumpBtn = Instance.new("TextButton")
    dumpBtn.Size = UDim2.new(1, -20, 0, 35)
    dumpBtn.Position = UDim2.new(0, 10, 0, 100)
    dumpBtn.BackgroundColor3 = Color3.fromRGB(147, 51, 234)
    dumpBtn.Text = "🚀 INICIAR DUMP"
    dumpBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    dumpBtn.Font = Enum.Font.GothamBold
    dumpBtn.TextSize = 12
    dumpBtn.BorderSizePixel = 0
    dumpBtn.Parent = contentFrame
    
    local output = Instance.new("TextBox")
    output.Size = UDim2.new(1, -20, 0, 150)
    output.Position = UDim2.new(0, 10, 0, 145)
    output.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
    output.TextColor3 = Color3.fromRGB(255, 255, 255)
    output.Text = "Clique em INICIAR DUMP..."
    output.Font = Enum.Font.Code
    output.TextSize = 10
    output.TextXAlignment = Enum.TextXAlignment.Left
    output.TextYAlignment = Enum.TextYAlignment.Top
    output.MultiLine = true
    output.TextEditable = false
    output.Parent = contentFrame
    
    dumpBtn.MouseButton1Click:Connect(function()
        dumpBtn.Text = "⏳ DUMPANDO..."
        output.Text = "🚀 Iniciando dump...\n"
        
        local scripts = 0
        for _, serviceName in ipairs({"Workspace", "ReplicatedStorage"}) do
            local service = game:GetService(serviceName)
            output.Text = output.Text .. "📂 " .. serviceName .. "\n"
            
            for _, obj in ipairs(service:GetDescendants()) do
                if obj:IsA("Script") then
                    scripts = scripts + 1
                end
            end
        end
        
        output.Text = output.Text .. "\n✅ Dump completo!\nScripts: " .. scripts
        
        if writefile then
            pcall(function()
                writefile("purple_dump.txt", "Dump completo - " .. scripts .. " scripts")
                output.Text = output.Text .. "\n💾 Arquivo salvo!"
            end)
        end
        
        dumpBtn.Text = "🚀 INICIAR DUMP"
    end)
end

-- SISTEMA DE CAPTURA SIMPLES
local function simpleHook()
    if hookmetamethod then
        local old
        old = hookmetamethod(game, "__namecall", function(self, ...)
            local method = getnamecallmethod()
            if isCapturing and (method == "FireServer" or method == "InvokeServer") then
                local event = {
                    name = self.Name,
                    path = self:GetFullName(),
                    time = os.date("%H:%M:%S")
                }
                table.insert(events, 1, event)
                if #events > 20 then table.remove(events) end
                
                if currentTab == "Logger" then
                    updateContent()
                end
            end
            return old(self, ...)
        end)
    end
end

-- KEY LOGGER SIMPLES
UserInputService.InputBegan:Connect(function(input)
    if input.KeyCode == Enum.KeyCode.F then
        return -- Ignorar F para não interferir
    end
end)

-- CONTROLE DA UI
local isVisible = false

local function toggleUI()
    isVisible = not isVisible
    mainFrame.Visible = isVisible
    if isVisible then
        updateContent()
    end
end

closeBtn.MouseButton1Click:Connect(toggleUI)

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if not gameProcessed and input.KeyCode == Enum.KeyCode.F then
        toggleUI()
    end
end)

-- INICIAR
print("💜 PURPLE PANEL - XENO EDITION")
print("✅ CARREGADO COM SUCESSO!")
print("🔧 PRESSIONE F PARA ABRIR")

-- Iniciar sistemas
simpleHook()

-- Mostrar UI após 1 segundo
wait(1)
toggleUI()
