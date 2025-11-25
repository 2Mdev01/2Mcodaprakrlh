--[[
    ╔═══════════════════════════════════════════════════════════╗
    ║  Purple Dump Panel v5.0 - Xeno Edition                   ║
    ║  Dump REAL + Trigger 100% Funcional + Tema Roxo         ║
    ║  Hotkey: F para abrir/fechar                             ║
    ╚═══════════════════════════════════════════════════════════╝
--]]

-- Serviços
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local CoreGui = game:GetService("CoreGui")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

-- Configurações com tema ROXO/PRETO
local Config = {
    AutoHook = true,
    MaxEventLogs = 2000,
    MaxKeyLogs = 3000,
    AutoScroll = true,
    ShowTimestamps = true,
    CaptureMouseEvents = true,
    Theme = {
        Primary = Color3.fromRGB(147, 51, 234),    -- Roxo principal
        Secondary = Color3.fromRGB(20, 20, 20),    -- Preto
        Background = Color3.fromRGB(30, 30, 40),   -- Fundo escuro
        Surface = Color3.fromRGB(40, 35, 55),      -- Superfície roxa escura
        Success = Color3.fromRGB(72, 199, 142),    -- Verde
        Warning = Color3.fromRGB(255, 159, 28),    -- Laranja
        Error = Color3.fromRGB(255, 85, 85),       -- Vermelho
        Text = Color3.fromRGB(255, 255, 255),      -- Branco
        TextSecondary = Color3.fromRGB(200, 200, 210) -- Cinza claro
    }
}

-- Variáveis globais
local CapturedEvents = {}
local BlockedEvents = {}
local KeyLogs = {}
local ScriptCache = {}
local IsUIVisible = false
local IsCapturing = false
local HookedObjects = {}
local ConnectionsTable = {}
local OriginalFunctions = {}

-- Criar UI
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "PurpleDumpPanel_" .. tostring(math.random(10000,99999))
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

-- Proteção contra detecção
local success = pcall(function()
    ScreenGui.Parent = CoreGui
end)
if not success then
    ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
end

-- Frame Principal com sombra roxa
local Shadow = Instance.new("Frame")
Shadow.Name = "Shadow"
Shadow.Size = UDim2.new(0, 850, 0, 650)
Shadow.Position = UDim2.new(0.5, -425, 0.5, -325)
Shadow.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
Shadow.BackgroundTransparency = 0.8
Shadow.BorderSizePixel = 0
Shadow.Visible = false
Shadow.Parent = ScreenGui

local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 840, 0, 640)
MainFrame.Position = UDim2.new(0.5, -420, 0.5, -320)
MainFrame.BackgroundColor3 = Config.Theme.Background
MainFrame.BorderSizePixel = 0
MainFrame.Visible = false
MainFrame.ClipsDescendants = true
MainFrame.Parent = ScreenGui

-- Corner para bordas arredondadas
local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 15)
MainCorner.Parent = MainFrame

-- Barra de título moderna ROXA
local TitleBar = Instance.new("Frame")
TitleBar.Name = "TitleBar"
TitleBar.Size = UDim2.new(1, 0, 0, 45)
TitleBar.BackgroundColor3 = Config.Theme.Primary
TitleBar.BorderSizePixel = 0
TitleBar.Parent = MainFrame

local TitleCorner = Instance.new("UICorner")
TitleCorner.CornerRadius = UDim.new(0, 15)
TitleCorner.Parent = TitleBar

-- Ícone e título
local TitleIcon = Instance.new("TextLabel")
TitleIcon.Size = UDim2.new(0, 35, 0, 35)
TitleIcon.Position = UDim2.new(0, 15, 0, 5)
TitleIcon.BackgroundTransparency = 1
TitleIcon.Text = "💜"
TitleIcon.TextColor3 = Config.Theme.Text
TitleIcon.Font = Enum.Font.GothamBold
TitleIcon.TextSize = 20
TitleIcon.Parent = TitleBar

local TitleLabel = Instance.new("TextLabel")
TitleLabel.Size = UDim2.new(0, 400, 0, 35)
TitleLabel.Position = UDim2.new(0, 55, 0, 5)
TitleLabel.BackgroundTransparency = 1
TitleLabel.Text = "Purple Dump Panel v5.0"
TitleLabel.TextColor3 = Config.Theme.Text
TitleLabel.Font = Enum.Font.GothamBold
TitleLabel.TextSize = 18
TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
TitleLabel.Parent = TitleBar

-- Status de captura
local StatusLabel = Instance.new("TextLabel")
StatusLabel.Size = UDim2.new(0, 160, 0, 25)
StatusLabel.Position = UDim2.new(1, -320, 0, 10)
StatusLabel.BackgroundColor3 = Config.Theme.Surface
StatusLabel.Text = "⚫ Captura: OFF"
StatusLabel.TextColor3 = Config.Theme.TextSecondary
StatusLabel.Font = Enum.Font.GothamBold
StatusLabel.TextSize = 12
StatusLabel.Parent = TitleBar

local StatusCorner = Instance.new("UICorner")
StatusCorner.CornerRadius = UDim.new(0, 12)
StatusCorner.Parent = StatusLabel

-- Função auxiliar para criar botões estilizados
local function CreateStyledButton(text, color, parent, position, size)
    local Button = Instance.new("TextButton")
    Button.Size = size or UDim2.new(0.45, 0, 0, 40)
    Button.Position = position or UDim2.new(0, 0, 0, 0)
    Button.BackgroundColor3 = color
    Button.Text = text
    Button.TextColor3 = Config.Theme.Text
    Button.Font = Enum.Font.GothamBold
    Button.TextSize = 14
    Button.AutoButtonColor = false
    Button.Parent = parent
    
    local Corner = Instance.new("UICorner")
    Corner.CornerRadius = UDim.new(0, 8)
    Corner.Parent = Button
    
    -- Efeito hover
    Button.MouseEnter:Connect(function()
        TweenService:Create(Button, TweenInfo.new(0.2), {
            BackgroundColor3 = Color3.new(
                math.min(color.R + 0.1, 1),
                math.min(color.G + 0.1, 1),
                math.min(color.B + 0.1, 1)
            )
        }):Play()
    end)
    
    Button.MouseLeave:Connect(function()
        TweenService:Create(Button, TweenInfo.new(0.2), {BackgroundColor3 = color}):Play()
    end)
    
    return Button
end

-- Botões de controle
local MinimizeButton = CreateStyledButton("─", Config.Theme.Warning, TitleBar, UDim2.new(1, -120, 0, 5), UDim2.new(0, 35, 0, 35))
local MaximizeButton = CreateStyledButton("□", Config.Theme.Success, TitleBar, UDim2.new(1, -80, 0, 5), UDim2.new(0, 35, 0, 35))
local CloseButton = CreateStyledButton("✕", Config.Theme.Error, TitleBar, UDim2.new(1, -40, 0, 5), UDim2.new(0, 35, 0, 35))

-- Abas modernas
local TabButtons = Instance.new("Frame")
TabButtons.Name = "TabButtons"
TabButtons.Size = UDim2.new(1, -20, 0, 50)
TabButtons.Position = UDim2.new(0, 10, 0, 55)
TabButtons.BackgroundTransparency = 1
TabButtons.Parent = MainFrame

local TabLayout = Instance.new("UIListLayout")
TabLayout.FillDirection = Enum.FillDirection.Horizontal
TabLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
TabLayout.SortOrder = Enum.SortOrder.LayoutOrder
TabLayout.Padding = UDim.new(0, 10)
TabLayout.Parent = TabButtons

-- Conteúdo das abas
local TabContent = Instance.new("Frame")
TabContent.Name = "TabContent"
TabContent.Size = UDim2.new(1, -20, 1, -125)
TabContent.Position = UDim2.new(0, 10, 0, 115)
TabContent.BackgroundColor3 = Config.Theme.Surface
TabContent.BorderSizePixel = 0
TabContent.Parent = MainFrame

local ContentCorner = Instance.new("UICorner")
ContentCorner.CornerRadius = UDim.new(0, 12)
ContentCorner.Parent = TabContent

-- Variável de controle da aba atual
local CurrentTab = "Dump"

-- Função para criar botão de aba
local function CreateTabButton(name, icon, index)
    local Button = Instance.new("TextButton")
    Button.Name = name
    Button.Size = UDim2.new(0, 150, 1, 0)
    Button.BackgroundColor3 = Config.Theme.Surface
    Button.Text = ""
    Button.Font = Enum.Font.GothamBold
    Button.TextSize = 14
    Button.TextColor3 = Config.Theme.TextSecondary
    Button.AutoButtonColor = false
    Button.LayoutOrder = index
    Button.Parent = TabButtons
    
    local ButtonCorner = Instance.new("UICorner")
    ButtonCorner.CornerRadius = UDim.new(0, 10)
    ButtonCorner.Parent = Button
    
    local IconLabel = Instance.new("TextLabel")
    IconLabel.Size = UDim2.new(0, 30, 0, 30)
    IconLabel.Position = UDim2.new(0, 12, 0.5, -15)
    IconLabel.BackgroundTransparency = 1
    IconLabel.Text = icon
    IconLabel.Font = Enum.Font.GothamBold
    IconLabel.TextSize = 18
    IconLabel.TextColor3 = Config.Theme.TextSecondary
    IconLabel.Parent = Button
    
    local TextLabel = Instance.new("TextLabel")
    TextLabel.Size = UDim2.new(1, -50, 1, 0)
    TextLabel.Position = UDim2.new(0, 45, 0, 0)
    TextLabel.BackgroundTransparency = 1
    TextLabel.Text = name
    TextLabel.Font = Enum.Font.GothamBold
    TextLabel.TextSize = 14
    TextLabel.TextColor3 = Config.Theme.TextSecondary
    TextLabel.TextXAlignment = Enum.TextXAlignment.Left
    TextLabel.Parent = Button
    
    Button.MouseButton1Click:Connect(function()
        SwitchTab(name)
    end)
    
    -- Efeito hover
    Button.MouseEnter:Connect(function()
        if CurrentTab ~= name then
            TweenService:Create(Button, TweenInfo.new(0.2), {BackgroundColor3 = Config.Theme.Background}):Play()
        end
    end)
    
    Button.MouseLeave:Connect(function()
        if CurrentTab ~= name then
            TweenService:Create(Button, TweenInfo.new(0.2), {BackgroundColor3 = Config.Theme.Surface}):Play()
        end
    end)
    
    return Button
end

-- Função para trocar de aba com animação
function SwitchTab(tabName)
    CurrentTab = tabName
    
    -- Atualizar estilos dos botões
    for _, child in pairs(TabButtons:GetChildren()) do
        if child:IsA("TextButton") then
            local isActive = child.Name == tabName
            TweenService:Create(child, TweenInfo.new(0.2), {
                BackgroundColor3 = isActive and Config.Theme.Primary or Config.Theme.Surface
            }):Play()
            
            for _, label in pairs(child:GetChildren()) do
                if label:IsA("TextLabel") then
                    TweenService:Create(label, TweenInfo.new(0.2), {
                        TextColor3 = isActive and Config.Theme.Text or Config.Theme.TextSecondary
                    }):Play()
                end
            end
        end
    end
    
    -- Limpar conteúdo anterior
    for _, child in pairs(TabContent:GetChildren()) do
        if not child:IsA("UICorner") then
            child:Destroy()
        end
    end
    
    -- Criar novo conteúdo
    if tabName == "Dump" then
        CreateDumpTab()
    elseif tabName == "Event Logs" then
        CreateEventLogsTab()
    elseif tabName == "Key Logs" then
        CreateKeyLogsTab()
    elseif tabName == "Executor" then
        CreateCodeExecutorTab()
    elseif tabName == "Settings" then
        CreateSettingsTab()
    end
end

-- Função auxiliar para criar caixas de texto estilizadas
local function CreateStyledTextBox(placeholder, parent, position, size, multiline)
    local Box = Instance.new("TextBox")
    Box.Size = size or UDim2.new(0.95, 0, 0, 400)
    Box.Position = position or UDim2.new(0.025, 0, 0, 60)
    Box.BackgroundColor3 = Config.Theme.Secondary
    Box.TextColor3 = Config.Theme.Text
    Box.PlaceholderText = placeholder
    Box.PlaceholderColor3 = Config.Theme.TextSecondary
    Box.Text = ""
    Box.Font = Enum.Font.Code
    Box.TextSize = 12
    Box.TextXAlignment = Enum.TextXAlignment.Left
    Box.TextYAlignment = Enum.TextYAlignment.Top
    Box.TextWrapped = true
    Box.ClearTextOnFocus = false
    Box.MultiLine = multiline or false
    Box.Parent = parent
    
    local Corner = Instance.new("UICorner")
    Corner.CornerRadius = UDim.new(0, 8)
    Corner.Parent = Box
    
    local Padding = Instance.new("UIPadding")
    Padding.PaddingLeft = UDim.new(0, 10)
    Padding.PaddingRight = UDim.new(0, 10)
    Padding.PaddingTop = UDim.new(0, 10)
    Padding.PaddingBottom = UDim.new(0, 10)
    Padding.Parent = Box
    
    return Box
end

-- SISTEMA DE DUMP REAL SALVANDO ARQUIVOS
local function SaveToFile(filename, content)
    if writefile then
        local success, err = pcall(function()
            writefile(filename, content)
        end)
        return success, err
    else
        return false, "writefile não disponível"
    end
end

local function GetScriptSource(script)
    local success, source = pcall(function()
        return script.Source
    end)
    
    if success and source and source ~= "" then
        return source
    else
        return "-- [PROTECTED] Unable to read source"
    end
end

local function DumpScriptsRecursive(parent, path, output, fileContent)
    for _, obj in pairs(parent:GetChildren()) do
        local currentPath = path .. "/" .. obj.Name
        
        if obj:IsA("Script") or obj:IsA("LocalScript") or obj:IsA("ModuleScript") then
            local source = GetScriptSource(obj)
            
            -- Adicionar ao output da UI
            output.Text = output.Text .. "\n" .. string.rep("=", 80) .. "\n"
            output.Text = output.Text .. "-- PATH: " .. currentPath .. "\n"
            output.Text = output.Text .. "-- CLASS: " .. obj.ClassName .. "\n"
            output.Text = output.Text .. string.rep("=", 80) .. "\n"
            output.Text = output.Text .. source .. "\n\n"
            
            -- Adicionar ao conteúdo do arquivo
            fileContent = fileContent .. "\n" .. string.rep("=", 80) .. "\n"
            fileContent = fileContent .. "-- PATH: " .. currentPath .. "\n"
            fileContent = fileContent .. "-- CLASS: " .. obj.ClassName .. "\n"
            fileContent = fileContent .. string.rep("=", 80) .. "\n"
            fileContent = fileContent .. source .. "\n\n"
            
            -- Cache do script
            ScriptCache[currentPath] = {
                Object = obj,
                Path = currentPath,
                ClassName = obj.ClassName,
                Source = source
            }
        end
        
        -- Recursão
        if #obj:GetChildren() > 0 then
            fileContent = DumpScriptsRecursive(obj, currentPath, output, fileContent)
        end
    end
    
    return fileContent
end

-- ABA DUMP MELHORADA
function CreateDumpTab()
    local Container = Instance.new("Frame")
    Container.Size = UDim2.new(1, 0, 1, 0)
    Container.BackgroundTransparency = 1
    Container.Parent = TabContent
    
    local ButtonFrame = Instance.new("Frame")
    ButtonFrame.Size = UDim2.new(1, -20, 0, 50)
    ButtonFrame.Position = UDim2.new(0, 10, 0, 10)
    ButtonFrame.BackgroundTransparency = 1
    ButtonFrame.Parent = Container
    
    local DumpButton = CreateStyledButton("💜 DUMP REAL + SALVAR", Config.Theme.Primary, ButtonFrame, 
        UDim2.new(0, 0, 0, 0), UDim2.new(0.48, 0, 1, 0))
    
    local ExportButton = CreateStyledButton("💾 EXPORTAR", Config.Theme.Success, ButtonFrame, 
        UDim2.new(0.52, 0, 0, 0), UDim2.new(0.48, 0, 1, 0))
    
    local ProgressFrame = Instance.new("Frame")
    ProgressFrame.Size = UDim2.new(1, -20, 0, 25)
    ProgressFrame.Position = UDim2.new(0, 10, 0, 70)
    ProgressFrame.BackgroundColor3 = Config.Theme.Secondary
    ProgressFrame.BorderSizePixel = 0
    ProgressFrame.Visible = false
    ProgressFrame.Parent = Container
    
    local ProgressCorner = Instance.new("UICorner")
    ProgressCorner.CornerRadius = UDim.new(0, 8)
    ProgressCorner.Parent = ProgressFrame
    
    local ProgressBar = Instance.new("Frame")
    ProgressBar.Size = UDim2.new(0, 0, 1, 0)
    ProgressBar.BackgroundColor3 = Config.Theme.Primary
    ProgressBar.BorderSizePixel = 0
    ProgressBar.Parent = ProgressFrame
    
    local ProgressCorner2 = Instance.new("UICorner")
    ProgressCorner2.CornerRadius = UDim.new(0, 8)
    ProgressCorner2.Parent = ProgressBar
    
    local ProgressLabel = Instance.new("TextLabel")
    ProgressLabel.Size = UDim2.new(1, 0, 1, 0)
    ProgressLabel.BackgroundTransparency = 1
    ProgressLabel.Text = "Processando..."
    ProgressLabel.TextColor3 = Config.Theme.Text
    ProgressLabel.Font = Enum.Font.GothamBold
    ProgressLabel.TextSize = 12
    ProgressLabel.Parent = ProgressFrame
    
    local ScrollFrame = Instance.new("ScrollingFrame")
    ScrollFrame.Size = UDim2.new(1, -20, 1, -115)
    ScrollFrame.Position = UDim2.new(0, 10, 0, 105)
    ScrollFrame.BackgroundColor3 = Config.Theme.Secondary
    ScrollFrame.BorderSizePixel = 0
    ScrollFrame.ScrollBarThickness = 8
    ScrollFrame.ScrollBarImageColor3 = Config.Theme.Primary
    ScrollFrame.Parent = Container
    
    local ScrollCorner = Instance.new("UICorner")
    ScrollCorner.CornerRadius = UDim.new(0, 8)
    ScrollCorner.Parent = ScrollFrame
    
    local OutputBox = Instance.new("TextLabel")
    OutputBox.Size = UDim2.new(1, -20, 1, -20)
    OutputBox.Position = UDim2.new(0, 10, 0, 10)
    OutputBox.BackgroundTransparency = 1
    OutputBox.Text = "💜 PURPLE DUMP PANEL v5.0\n\n"..
        "DUMP REAL + SALVAMENTO EM ARQUIVO\n\n"..
        "Este dump irá:\n"..
        "• Extrair código fonte REAL dos scripts\n"..
        "• Salvar em arquivo no seu PC\n"..
        "• Processar todos os serviços do jogo\n"..
        "• Manter cache para análise rápida\n\n"..
        "Clique em 'DUMP REAL + SALVAR' para começar."
    OutputBox.TextColor3 = Config.Theme.Text
    OutputBox.Font = Enum.Font.Code
    OutputBox.TextSize = 12
    OutputBox.TextXAlignment = Enum.TextXAlignment.Left
    OutputBox.TextYAlignment = Enum.TextYAlignment.Top
    OutputBox.TextWrapped = true
    OutputBox.Parent = ScrollFrame
    
    local function UpdateProgress(current, total, text)
        local percent = current / total
        ProgressBar.Size = UDim2.new(percent, 0, 1, 0)
        ProgressLabel.Text = text .. string.format(" (%d/%d - %.1f%%)", current, total, percent * 100)
    end
    
    DumpButton.MouseButton1Click:Connect(function()
        DumpButton.Text = "⏳ PROCESSANDO..."
        DumpButton.BackgroundColor3 = Config.Theme.Warning
        ProgressFrame.Visible = true
        
        task.spawn(function()
            local startTime = tick()
            OutputBox.Text = "🚀 INICIANDO DUMP REAL...\n⏰ Isso pode levar alguns minutos...\n\n"
            
            ScriptCache = {}
            local totalScripts = 0
            local processedScripts = 0
            
            -- Contar scripts primeiro
            local function CountScripts(parent)
                for _, obj in pairs(parent:GetChildren()) do
                    if obj:IsA("Script") or obj:IsA("LocalScript") or obj:IsA("ModuleScript") then
                        totalScripts = totalScripts + 1
                    end
                    CountScripts(obj)
                end
            end
            
            local servicesToDump = {
                game:GetService("Workspace"),
                game:GetService("ReplicatedStorage"),
                game:GetService("ReplicatedFirst"),
                game:GetService("ServerScriptService"),
                game:GetService("ServerStorage"),
                game:GetService("StarterGui"),
                game:GetService("StarterPack"),
                game:GetService("StarterPlayer"),
                game:GetService("Lighting"),
                game:GetService("SoundService"),
                game:GetService("Players")
            }
            
            for _, service in pairs(servicesToDump) do
                CountScripts(service)
            end
            
            OutputBox.Text = OutputBox.Text .. string.format("📊 Total de scripts encontrados: %d\n\n", totalScripts)
            
            -- Fazer o dump real
            local fileContent = "-- PURPLE DUMP PANEL v5.0 - DUMP COMPLETO\n-- Data: " .. os.date("%d/%m/%Y %H:%M:%S") .. "\n\n"
            
            for _, service in pairs(servicesToDump) do
                local serviceName = service.Name
                OutputBox.Text = OutputBox.Text .. string.format("\n📂 PROCESSANDO: %s\n", serviceName)
                fileContent = fileContent .. string.format("\n=== %s ===\n", serviceName)
                
                fileContent = DumpScriptsRecursive(service, serviceName, OutputBox, fileContent)
                
                -- Atualizar progresso
                processedScripts = processedScripts + math.floor(totalScripts / #servicesToDump)
                UpdateProgress(processedScripts, totalScripts, "Processando " .. serviceName)
                task.wait(0.1)
            end
            
            -- SALVAR EM ARQUIVO
            local filename = "purple_dump_" .. os.time() .. ".lua"
            local success, err = SaveToFile(filename, fileContent)
            
            local endTime = tick()
            local duration = string.format("%.2f", endTime - startTime)
            
            if success then
                OutputBox.Text = OutputBox.Text .. string.format("\n\n✅ DUMP SALVO COM SUCESSO!\n")
                OutputBox.Text = OutputBox.Text .. string.format("📁 Arquivo: %s\n", filename)
            else
                OutputBox.Text = OutputBox.Text .. string.format("\n\n⚠️ DUMP CONCLUÍDO MAS NÃO SALVO\n")
                OutputBox.Text = OutputBox.Text .. string.format("❌ Erro: %s\n", err)
            end
            
            OutputBox.Text = OutputBox.Text .. string.format("📊 Scripts processados: %d\n", totalScripts)
            OutputBox.Text = OutputBox.Text .. string.format("⏰ Tempo total: %s segundos\n", duration)
            OutputBox.Text = OutputBox.Text .. string.format("💾 Tamanho: %d KB\n", #fileContent / 1024)
            
            ProgressFrame.Visible = false
            DumpButton.Text = "💜 DUMP REAL + SALVAR"
            DumpButton.BackgroundColor3 = Config.Theme.Primary
        end)
    end)
    
    ExportButton.MouseButton1Click:Connect(function()
        local dumpData = OutputBox.Text
        setclipboard(dumpData)
        OutputBox.Text = OutputBox.Text .. "\n✅ Dump copiado para clipboard!"
        
        ExportButton.Text = "✅ COPIADO!"
        task.wait(2)
        ExportButton.Text = "💾 EXPORTAR"
    end)
end

-- SISTEMA DE TRIGGER 100% FUNCIONAL
local function HookRemoteEvent(event)
    if HookedObjects[event] then return end
    HookedObjects[event] = true
    
    if event:IsA("RemoteEvent") then
        local oldFireServer = event.FireServer
        OriginalFunctions[event] = oldFireServer
        
        event.FireServer = function(self, ...)
            local args = {...}
            local callingScript = getcallingscript()
            
            if IsCapturing then
                local eventData = {
                    Object = event,
                    Arguments = args,
                    Timestamp = os.time(),
                    Type = "RemoteEvent",
                    Caller = callingScript or "Unknown",
                    Path = event:GetFullName()
                }
                
                table.insert(CapturedEvents, 1, eventData)
                
                if #CapturedEvents > Config.MaxEventLogs then
                    table.remove(CapturedEvents, #CapturedEvents)
                end
                
                -- Atualizar UI se visível
                if IsUIVisible and CurrentTab == "Event Logs" then
                    UpdateEventsList()
                end
            end
            
            if not BlockedEvents[event] then
                return oldFireServer(self, ...)
            end
        end
    elseif event:IsA("RemoteFunction") then
        local oldInvokeServer = event.InvokeServer
        OriginalFunctions[event] = oldInvokeServer
        
        event.InvokeServer = function(self, ...)
            local args = {...}
            local callingScript = getcallingscript()
            
            if IsCapturing then
                local eventData = {
                    Object = event,
                    Arguments = args,
                    Timestamp = os.time(),
                    Type = "RemoteFunction",
                    Caller = callingScript or "Unknown",
                    Path = event:GetFullName()
                }
                
                table.insert(CapturedEvents, 1, eventData)
                
                if #CapturedEvents > Config.MaxEventLogs then
                    table.remove(CapturedEvents, #CapturedEvents)
                end
                
                if IsUIVisible and CurrentTab == "Event Logs" then
                    UpdateEventsList()
                end
            end
            
            if not BlockedEvents[event] then
                return oldInvokeServer(self, ...)
            end
        end
    end
end

local function HookExistingRemotes()
    local function HookDescendants(parent)
        for _, obj in pairs(parent:GetDescendants()) do
            if (obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction")) and not HookedObjects[obj] then
                pcall(function()
                    HookRemoteEvent(obj)
                end)
            end
        end
    end
    
    -- Hookar em todos os serviços importantes
    local services = {
        game:GetService("Workspace"),
        game:GetService("ReplicatedStorage"),
        game:GetService("ReplicatedFirst"),
        game:GetService("ServerScriptService"),
        game:GetService("ServerStorage"),
        game:GetService("StarterGui"),
        game:GetService("StarterPack"),
        game:GetService("StarterPlayer"),
        game:GetService("Players")
    }
    
    for _, service in pairs(services) do
        pcall(function()
            HookDescendants(service)
        end)
    end
    
    -- Hookar novos objetos
    for _, service in pairs(services) do
        local connection
        connection = service.DescendantAdded:Connect(function(obj)
            if (obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction")) and not HookedObjects[obj] then
                pcall(function()
                    HookRemoteEvent(obj)
                end)
            end
        end)
        table.insert(ConnectionsTable, connection)
    end
end

-- ABA EVENT LOGS COMPLETAMENTE REFEITA
local EventsScrollFrame
local EventsInfoLabel

function UpdateEventsList()
    if not EventsScrollFrame then return end
    
    for _, child in pairs(EventsScrollFrame:GetChildren()) do
        if child:IsA("Frame") then
            child:Destroy()
        end
    end
    
    local blockedCount = 0
    for _ in pairs(BlockedEvents) do
        blockedCount = blockedCount + 1
    end
    
    if EventsInfoLabel then
        EventsInfoLabel.Text = string.format("📊 Eventos: %d | 🔒 Bloqueados: %d | 💜 Hooked: %d", #CapturedEvents, blockedCount, #HookedObjects)
    end
    
    for i = math.min(100, #CapturedEvents), 1, -1 do
        local event = CapturedEvents[i]
        if not event then continue end
        
        local EventFrame = Instance.new("Frame")
        EventFrame.Size = UDim2.new(1, -10, 0, 110)
        EventFrame.BackgroundColor3 = Config.Theme.Surface
        EventFrame.BorderSizePixel = 0
        EventFrame.Parent = EventsScrollFrame
        
        local EventCorner = Instance.new("UICorner")
        EventCorner.CornerRadius = UDim.new(0, 8)
        EventCorner.Parent = EventFrame
        
        local TypeBadge = Instance.new("TextLabel")
        TypeBadge.Size = UDim2.new(0, 120, 0, 25)
        TypeBadge.Position = UDim2.new(0, 8, 0, 8)
        TypeBadge.BackgroundColor3 = event.Type == "RemoteEvent" and Config.Theme.Primary or Config.Theme.Warning
        TypeBadge.Text = event.Type == "RemoteEvent" and "📡 RemoteEvent" or "🔌 RemoteFunction"
        TypeBadge.TextColor3 = Config.Theme.Text
        TypeBadge.Font = Enum.Font.GothamBold
        TypeBadge.TextSize = 12
        TypeBadge.Parent = EventFrame
        
        local BadgeCorner = Instance.new("UICorner")
        BadgeCorner.CornerRadius = UDim.new(0, 6)
        BadgeCorner.Parent = TypeBadge
        
        local EventName = Instance.new("TextLabel")
        EventName.Size = UDim2.new(1, -240, 0, 25)
        EventName.Position = UDim2.new(0, 135, 0, 8)
        EventName.BackgroundTransparency = 1
        EventName.Text = event.Object.Name
        EventName.TextColor3 = Config.Theme.Text
        EventName.Font = Enum.Font.GothamBold
        EventName.TextSize = 14
        EventName.TextXAlignment = Enum.TextXAlignment.Left
        EventName.TextTruncate = Enum.TextTruncate.AtEnd
        EventName.Parent = EventFrame
        
        local PathLabel = Instance.new("TextLabel")
        PathLabel.Size = UDim2.new(1, -120, 0, 20)
        PathLabel.Position = UDim2.new(0, 8, 0, 35)
        PathLabel.BackgroundTransparency = 1
        PathLabel.Text = "📂 " .. event.Path
        PathLabel.TextColor3 = Config.Theme.TextSecondary
        PathLabel.Font = Enum.Font.Gotham
        PathLabel.TextSize = 11
        PathLabel.TextXAlignment = Enum.TextXAlignment.Left
        PathLabel.TextTruncate = Enum.TextTruncate.AtEnd
        PathLabel.Parent = EventFrame
        
        local TimeLabel = Instance.new("TextLabel")
        TimeLabel.Size = UDim2.new(0.5, -10, 0, 20)
        TimeLabel.Position = UDim2.new(0, 8, 0, 55)
        TimeLabel.BackgroundTransparency = 1
        TimeLabel.Text = "⏰ " .. os.date("%H:%M:%S", event.Timestamp)
        TimeLabel.TextColor3 = Config.Theme.TextSecondary
        TimeLabel.Font = Enum.Font.Gotham
        TimeLabel.TextSize = 11
        TimeLabel.TextXAlignment = Enum.TextXAlignment.Left
        TimeLabel.Parent = EventFrame
        
        local ArgsLabel = Instance.new("TextLabel")
        ArgsLabel.Size = UDim2.new(0.5, -10, 0, 20)
        ArgsLabel.Position = UDim2.new(0, 8, 0, 75)
        ArgsLabel.BackgroundTransparency = 1
        ArgsLabel.Text = string.format("📦 Args: %d", #event.Arguments)
        ArgsLabel.TextColor3 = Config.Theme.TextSecondary
        ArgsLabel.Font = Enum.Font.Gotham
        ArgsLabel.TextSize = 11
        ArgsLabel.TextXAlignment = Enum.TextXAlignment.Left
        ArgsLabel.Parent = EventFrame
        
        local BlockButton = CreateStyledButton(
            BlockedEvents[event.Object] and "🔓 Desbloquear" or "🔒 Bloquear",
            BlockedEvents[event.Object] and Config.Theme.Success or Config.Theme.Error,
            EventFrame,
            UDim2.new(1, -185, 0, 8),
            UDim2.new(0, 90, 0, 35)
        )
        
        local ReplayButton = CreateStyledButton(
            "▶️ Replay",
            Config.Theme.Primary,
            EventFrame,
            UDim2.new(1, -90, 0, 8),
            UDim2.new(0, 85, 0, 35)
        )
        
        local CopyButton = CreateStyledButton(
            "📋 Copiar",
            Config.Theme.Warning,
            EventFrame,
            UDim2.new(1, -185, 0, 48),
            UDim2.new(0, 180, 0, 35)
        )
        
        BlockButton.MouseButton1Click:Connect(function()
            BlockedEvents[event.Object] = not BlockedEvents[event.Object]
            UpdateEventsList()
        end)
        
        ReplayButton.MouseButton1Click:Connect(function()
            pcall(function()
                if event.Type == "RemoteEvent" then
                    event.Object:FireServer(unpack(event.Arguments))
                else
                    event.Object:InvokeServer(unpack(event.Arguments))
                end
            end)
            
            ReplayButton.Text = "✅ Enviado"
            task.wait(1)
            ReplayButton.Text = "▶️ Replay"
        end)
        
        CopyButton.MouseButton1Click:Connect(function()
            local argsString = ""
            for i, arg in ipairs(event.Arguments) do
                if type(arg) == "string" then
                    argsString = argsString .. '"' .. tostring(arg) .. '"'
                else
                    argsString = argsString .. tostring(arg)
                end
                if i < #event.Arguments then
                    argsString = argsString .. ", "
                end
            end
            
            local copyText = string.format("-- %s\n%s:%s(%s)", 
                event.Path, 
                event.Object.Name,
                event.Type == "RemoteEvent" and "FireServer" or "InvokeServer",
                argsString
            )
            setclipboard(copyText)
            
            CopyButton.Text = "✅ Copiado!"
            task.wait(1)
            CopyButton.Text = "📋 Copiar"
        end)
    end
end

function CreateEventLogsTab()
    local Container = Instance.new("Frame")
    Container.Size = UDim2.new(1, 0, 1, 0)
    Container.BackgroundTransparency = 1
    Container.Parent = TabContent
    
    local ControlFrame = Instance.new("Frame")
    ControlFrame.Size = UDim2.new(1, -20, 0, 50)
    ControlFrame.Position = UDim2.new(0, 10, 0, 10)
    ControlFrame.BackgroundTransparency = 1
    ControlFrame.Parent = Container
    
    local StartButton = CreateStyledButton("💜 INICIAR CAPTURA", Config.Theme.Success, ControlFrame,
        UDim2.new(0, 0, 0, 0), UDim2.new(0.32, 0, 1, 0))
    
    local ClearButton = CreateStyledButton("🗑️ LIMPAR", Config.Theme.Error, ControlFrame,
        UDim2.new(0.34, 0, 0, 0), UDim2.new(0.32, 0, 1, 0))
    
    local ExportButton = CreateStyledButton("💾 EXPORTAR", Config.Theme.Primary, ControlFrame,
        UDim2.new(0.68, 0, 0, 0), UDim2.new(0.32, 0, 1, 0))
    
    local InfoFrame = Instance.new("Frame")
    InfoFrame.Size = UDim2.new(1, -20, 0, 35)
    InfoFrame.Position = UDim2.new(0, 10, 0, 70)
    InfoFrame.BackgroundColor3 = Config.Theme.Secondary
    InfoFrame.Parent = Container
    
    local InfoCorner = Instance.new("UICorner")
    InfoCorner.CornerRadius = UDim.new(0, 8)
    InfoCorner.Parent = InfoFrame
    
    EventsInfoLabel = Instance.new("TextLabel")
    EventsInfoLabel.Size = UDim2.new(1, -20, 1, 0)
    EventsInfoLabel.Position = UDim2.new(0, 10, 0, 0)
    EventsInfoLabel.BackgroundTransparency = 1
    EventsInfoLabel.Text = "📊 Eventos: 0 | 🔒 Bloqueados: 0 | 💜 Hooked: 0"
    EventsInfoLabel.TextColor3 = Config.Theme.Text
    EventsInfoLabel.Font = Enum.Font.GothamBold
    EventsInfoLabel.TextSize = 13
    EventsInfoLabel.TextXAlignment = Enum.TextXAlignment.Left
    EventsInfoLabel.Parent = InfoFrame
    
    EventsScrollFrame = Instance.new("ScrollingFrame")
    EventsScrollFrame.Size = UDim2.new(1, -20, 1, -125)
    EventsScrollFrame.Position = UDim2.new(0, 10, 0, 115)
    EventsScrollFrame.BackgroundColor3 = Config.Theme.Secondary
    EventsScrollFrame.BorderSizePixel = 0
    EventsScrollFrame.ScrollBarThickness = 8
    EventsScrollFrame.ScrollBarImageColor3 = Config.Theme.Primary
    EventsScrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
    EventsScrollFrame.Parent = Container
    
    local ScrollCorner = Instance.new("UICorner")
    ScrollCorner.CornerRadius = UDim.new(0, 8)
    ScrollCorner.Parent = EventsScrollFrame
    
    local ListLayout = Instance.new("UIListLayout")
    ListLayout.SortOrder = Enum.SortOrder.LayoutOrder
    ListLayout.Padding = UDim.new(0, 10)
    ListLayout.Parent = EventsScrollFrame
    
    ListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        EventsScrollFrame.CanvasSize = UDim2.new(0, 0, 0, ListLayout.AbsoluteContentSize.Y + 10)
    end)
    
    StartButton.MouseButton1Click:Connect(function()
        IsCapturing = not IsCapturing
        
        if IsCapturing then
            StartButton.Text = "🔴 PARAR CAPTURA"
            StartButton.BackgroundColor3 = Config.Theme.Error
            StatusLabel.Text = "💜 Captura: ON"
            StatusLabel.BackgroundColor3 = Config.Theme.Success
            
            -- Hookar eventos existentes
            HookExistingRemotes()
            
        else
            StartButton.Text = "💜 INICIAR CAPTURA"
            StartButton.BackgroundColor3 = Config.Theme.Success
            StatusLabel.Text = "⚫ Captura: OFF"
            StatusLabel.BackgroundColor3 = Config.Theme.Surface
        end
        UpdateEventsList()
    end)
    
    ClearButton.MouseButton1Click:Connect(function()
        CapturedEvents = {}
        BlockedEvents = {}
        UpdateEventsList()
    end)
    
    ExportButton.MouseButton1Click:Connect(function()
        local exportData = "-- Purple Dump Panel - Event Logs\n-- Total Events: " .. #CapturedEvents .. "\n\n"
        for i, event in ipairs(CapturedEvents) do
            exportData = exportData .. string.format(
                "-- [%d] %s (%s)\n-- Path: %s\n-- Time: %s\n-- Args Count: %d\n\n",
                i,
                event.Object.Name,
                event.Type,
                event.Path,
                os.date("%H:%M:%S", event.Timestamp),
                #event.Arguments
            )
        end
        
        setclipboard(exportData)
        ExportButton.Text = "✅ COPIADO!"
        task.wait(2)
        ExportButton.Text = "💾 EXPORTAR"
    end)
    
    UpdateEventsList()
end

-- ABA KEY LOGS
function CreateKeyLogsTab()
    local Container = Instance.new("Frame")
    Container.Size = UDim2.new(1, 0, 1, 0)
    Container.BackgroundTransparency = 1
    Container.Parent = TabContent
    
    local ControlFrame = Instance.new("Frame")
    ControlFrame.Size = UDim2.new(1, -20, 0, 50)
    ControlFrame.Position = UDim2.new(0, 10, 0, 10)
    ControlFrame.BackgroundTransparency = 1
    ControlFrame.Parent = Container
    
    local ClearButton = CreateStyledButton("🗑️ LIMPAR LOGS", Config.Theme.Error, ControlFrame,
        UDim2.new(0, 0, 0, 0), UDim2.new(0.48, 0, 1, 0))
    
    local ExportButton = CreateStyledButton("💾 EXPORTAR", Config.Theme.Success, ControlFrame,
        UDim2.new(0.52, 0, 0, 0), UDim2.new(0.48, 0, 1, 0))
    
    local InfoLabel = Instance.new("TextLabel")
    InfoLabel.Size = UDim2.new(1, -20, 0, 30)
    InfoLabel.Position = UDim2.new(0, 10, 0, 70)
    InfoLabel.BackgroundTransparency = 1
    InfoLabel.Text = "⌨️ Key Logger Ativo - Todos os inputs estão sendo registrados"
    InfoLabel.TextColor3 = Config.Theme.Text
    InfoLabel.Font = Enum.Font.GothamBold
    InfoLabel.TextSize = 13
    InfoLabel.TextXAlignment = Enum.TextXAlignment.Left
    InfoLabel.Parent = Container
    
    local ScrollFrame = Instance.new("ScrollingFrame")
    ScrollFrame.Size = UDim2.new(1, -20, 1, -120)
    ScrollFrame.Position = UDim2.new(0, 10, 0, 105)
    ScrollFrame.BackgroundColor3 = Config.Theme.Secondary
    ScrollFrame.BorderSizePixel = 0
    ScrollFrame.ScrollBarThickness = 8
    ScrollFrame.ScrollBarImageColor3 = Config.Theme.Primary
    ScrollFrame.Parent = Container
    
    local ScrollCorner = Instance.new("UICorner")
    ScrollCorner.CornerRadius = UDim.new(0, 8)
    ScrollCorner.Parent = ScrollFrame
    
    local LogBox = Instance.new("TextLabel")
    LogBox.Size = UDim2.new(1, -20, 1, -20)
    LogBox.Position = UDim2.new(0, 10, 0, 10)
    LogBox.BackgroundTransparency = 1
    LogBox.Text = "💜 Purple Key Logger Iniciado...\nAguardando inputs...\n\n"
    LogBox.TextColor3 = Config.Theme.Text
    LogBox.Font = Enum.Font.Code
    LogBox.TextSize = 12
    LogBox.TextXAlignment = Enum.TextXAlignment.Left
    LogBox.TextYAlignment = Enum.TextYAlignment.Top
    LogBox.TextWrapped = true
    LogBox.Parent = ScrollFrame
    
    -- Sistema de captura de input
    local function UpdateKeyLogsDisplay()
        local displayText = "💜 KEY LOGS - Últimos 150 inputs:\n\n"
        for i = 1, math.min(150, #KeyLogs) do
            displayText = displayText .. KeyLogs[i]
        end
        LogBox.Text = displayText
        
        if Config.AutoScroll then
            ScrollFrame.CanvasPosition = Vector2.new(0, LogBox.TextBounds.Y)
        end
    end

    local inputBeganConnection
    inputBeganConnection = UserInputService.InputBegan:Connect(function(input, gameProcessed)
        local timestamp = os.date("%H:%M:%S")
        local inputType = input.UserInputType.Name
        local keyName = "Unknown"
        
        if input.KeyCode ~= Enum.KeyCode.Unknown then
            keyName = input.KeyCode.Name
        elseif input.UserInputType == Enum.UserInputType.MouseButton1 then
            keyName = "MouseButton1"
        elseif input.UserInputType == Enum.UserInputType.MouseButton2 then
            keyName = "MouseButton2"
        elseif input.UserInputType == Enum.UserInputType.MouseButton3 then
            keyName = "MouseButton3"
        end
        
        local logEntry = string.format(
            "[%s] %s | %s | %s | Game: %s\n",
            timestamp,
            gameProcessed and "🔒" or "💜",
            inputType,
            keyName,
            tostring(gameProcessed)
        )
        
        table.insert(KeyLogs, 1, logEntry)
        
        if #KeyLogs > Config.MaxKeyLogs then
            table.remove(KeyLogs, #KeyLogs)
        end
        
        UpdateKeyLogsDisplay()
    end)
    
    table.insert(ConnectionsTable, inputBeganConnection)
    
    ClearButton.MouseButton1Click:Connect(function()
        KeyLogs = {}
        LogBox.Text = "🗑️ Key Logs limpos com sucesso!\nAguardando novos inputs...\n\n"
    end)
    
    ExportButton.MouseButton1Click:Connect(function()
        local exportText = "-- Purple Key Logs\n-- Total Inputs: " .. #KeyLogs .. "\n\n"
        for i = #KeyLogs, 1, -1 do
            exportText = exportText .. KeyLogs[i]
        end
        
        setclipboard(exportText)
        ExportButton.Text = "✅ COPIADO!"
        task.wait(2)
        ExportButton.Text = "💾 EXPORTAR"
    end)
end

-- ABA EXECUTOR
function CreateCodeExecutorTab()
    local Container = Instance.new("Frame")
    Container.Size = UDim2.new(1, 0, 1, 0)
    Container.BackgroundTransparency = 1
    Container.Parent = TabContent
    
    local CodeBox = CreateStyledTextBox("-- Purple Executor\n-- Cole seu código Lua aqui\n\nprint('💜 Hello from Purple Panel v5.0!')", 
        Container, UDim2.new(0, 10, 0, 10), UDim2.new(1, -20, 0.55, -15), true)
    
    local ButtonFrame = Instance.new("Frame")
    ButtonFrame.Size = UDim2.new(1, -20, 0, 50)
    ButtonFrame.Position = UDim2.new(0, 10, 0.55, 5)
    ButtonFrame.BackgroundTransparency = 1
    ButtonFrame.Parent = Container
    
    local ExecuteButton = CreateStyledButton("💜 EXECUTAR", Config.Theme.Success, ButtonFrame,
        UDim2.new(0, 0, 0, 0), UDim2.new(0.48, 0, 1, 0))
    
    local ClearButton = CreateStyledButton("🗑️ LIMPAR", Config.Theme.Error, ButtonFrame,
        UDim2.new(0.52, 0, 0, 0), UDim2.new(0.48, 0, 1, 0))
    
    local OutputLabel = Instance.new("TextLabel")
    OutputLabel.Size = UDim2.new(1, -20, 0, 30)
    OutputLabel.Position = UDim2.new(0, 10, 0.55, 65)
    OutputLabel.BackgroundTransparency = 1
    OutputLabel.Text = "📤 Output:"
    OutputLabel.TextColor3 = Config.Theme.Text
    OutputLabel.Font = Enum.Font.GothamBold
    OutputLabel.TextSize = 14
    OutputLabel.TextXAlignment = Enum.TextXAlignment.Left
    OutputLabel.Parent = Container
    
    local OutputBox = CreateStyledTextBox("Aguardando execução...", 
        Container, UDim2.new(0, 10, 0.55, 100), UDim2.new(1, -20, 0.45, -110), true)
    OutputBox.TextEditable = false
    OutputBox.TextColor3 = Color3.fromRGB(0, 255, 100)
    
    ExecuteButton.MouseButton1Click:Connect(function()
        local code = CodeBox.Text
        
        if code == "" or code == nil then
            OutputBox.Text = "❌ [ERRO] Nenhum código para executar!\n"
            return
        end
        
        ExecuteButton.Text = "⏳ EXECUTANDO..."
        ExecuteButton.BackgroundColor3 = Config.Theme.Warning
        
        task.spawn(function()
            local success, result = pcall(function()
                local func, err = loadstring(code)
                if func then
                    return func()
                else
                    error(err)
                end
            end)
            
            local timestamp = os.date("%H:%M:%S")
            
            if success then
                OutputBox.Text = string.format("💜 [%s] SUCESSO - Código executado\n", timestamp)
                if result ~= nil then
                    OutputBox.Text = OutputBox.Text .. "📦 Retorno: " .. tostring(result) .. "\n"
                end
            else
                OutputBox.Text = string.format("❌ [%s] ERRO:\n%s\n", timestamp, tostring(result))
            end
            
            task.wait(0.5)
            ExecuteButton.Text = "💜 EXECUTAR"
            ExecuteButton.BackgroundColor3 = Config.Theme.Success
        end)
    end)
    
    ClearButton.MouseButton1Click:Connect(function()
        CodeBox.Text = ""
        OutputBox.Text = "🗑️ Código e output limpos.\n"
    end)
end

-- ABA SETTINGS
function CreateSettingsTab()
    local Container = Instance.new("Frame")
    Container.Size = UDim2.new(1, 0, 1, 0)
    Container.BackgroundTransparency = 1
    Container.Parent = TabContent
    
    local ScrollFrame = Instance.new("ScrollingFrame")
    ScrollFrame.Size = UDim2.new(1, -20, 1, -10)
    ScrollFrame.Position = UDim2.new(0, 10, 0, 10)
    ScrollFrame.BackgroundTransparency = 1
    ScrollFrame.BorderSizePixel = 0
    ScrollFrame.ScrollBarThickness = 8
    ScrollFrame.ScrollBarImageColor3 = Config.Theme.Primary
    ScrollFrame.CanvasSize = UDim2.new(0, 0, 0, 600)
    ScrollFrame.Parent = Container
    
    local yPos = 0
    
    local function CreateOption(title, description, callback, isToggled)
        local OptionFrame = Instance.new("Frame")
        OptionFrame.Size = UDim2.new(1, -10, 0, 80)
        OptionFrame.Position = UDim2.new(0, 0, 0, yPos)
        OptionFrame.BackgroundColor3 = Config.Theme.Surface
        OptionFrame.BorderSizePixel = 0
        OptionFrame.Parent = ScrollFrame
        
        local OptionCorner = Instance.new("UICorner")
        OptionCorner.CornerRadius = UDim.new(0, 10)
        OptionCorner.Parent = OptionFrame
        
        local TitleLabel = Instance.new("TextLabel")
        TitleLabel.Size = UDim2.new(1, -100, 0, 25)
        TitleLabel.Position = UDim2.new(0, 15, 0, 10)
        TitleLabel.BackgroundTransparency = 1
        TitleLabel.Text = title
        TitleLabel.TextColor3 = Config.Theme.Text
        TitleLabel.Font = Enum.Font.GothamBold
        TitleLabel.TextSize = 15
        TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
        TitleLabel.Parent = OptionFrame
        
        local DescLabel = Instance.new("TextLabel")
        DescLabel.Size = UDim2.new(1, -100, 0, 40)
        DescLabel.Position = UDim2.new(0, 15, 0, 35)
        DescLabel.BackgroundTransparency = 1
        DescLabel.Text = description
        DescLabel.TextColor3 = Config.Theme.TextSecondary
        DescLabel.Font = Enum.Font.Gotham
        DescLabel.TextSize = 12
        DescLabel.TextXAlignment = Enum.TextXAlignment.Left
        DescLabel.TextYAlignment = Enum.TextYAlignment.Top
        DescLabel.TextWrapped = true
        DescLabel.Parent = OptionFrame
        
        local ToggleButton = Instance.new("TextButton")
        ToggleButton.Size = UDim2.new(0, 80, 0, 40)
        ToggleButton.Position = UDim2.new(1, -90, 0.5, -20)
        ToggleButton.BackgroundColor3 = isToggled and Config.Theme.Success or Config.Theme.Error
        ToggleButton.Text = isToggled and "💜 ON" or "✕ OFF"
        ToggleButton.TextColor3 = Config.Theme.Text
        ToggleButton.Font = Enum.Font.GothamBold
        ToggleButton.TextSize = 13
        ToggleButton.AutoButtonColor = false
        ToggleButton.Parent = OptionFrame
        
        local ToggleCorner = Instance.new("UICorner")
        ToggleCorner.CornerRadius = UDim.new(0, 8)
        ToggleCorner.Parent = ToggleButton
        
        ToggleButton.MouseButton1Click:Connect(function()
            isToggled = not isToggled
            ToggleButton.BackgroundColor3 = isToggled and Config.Theme.Success or Config.Theme.Error
            ToggleButton.Text = isToggled and "💜 ON" or "✕ OFF"
            callback(isToggled)
        end)
        
        yPos = yPos + 90
    end
    
    CreateOption(
        "💜 Auto Hook",
        "Hookar automaticamente novos RemoteEvents/Functions",
        function(value) Config.AutoHook = value end,
        Config.AutoHook
    )
    
    CreateOption(
        "⏰ Mostrar Timestamps",
        "Exibir hora em logs de eventos",
        function(value) Config.ShowTimestamps = value end,
        Config.ShowTimestamps
    )
    
    CreateOption(
        "📜 Auto Scroll",
        "Rolar automaticamente para novos logs",
        function(value) Config.AutoScroll = value end,
        Config.AutoScroll
    )
    
    CreateOption(
        "🖱️ Capturar Mouse",
        "Registrar eventos de mouse nos key logs",
        function(value) Config.CaptureMouseEvents = value end,
        Config.CaptureMouseEvents
    )
    
    local InfoFrame = Instance.new("Frame")
    InfoFrame.Size = UDim2.new(1, -10, 0, 140)
    InfoFrame.Position = UDim2.new(0, 0, 0, yPos)
    InfoFrame.BackgroundColor3 = Config.Theme.Primary
    InfoFrame.Parent = ScrollFrame
    
    local InfoCorner = Instance.new("UICorner")
    InfoCorner.CornerRadius = UDim.new(0, 10)
    InfoCorner.Parent = InfoFrame
    
    local InfoText = Instance.new("TextLabel")
    InfoText.Size = UDim2.new(1, -20, 1, -20)
    InfoText.Position = UDim2.new(0, 10, 0, 10)
    InfoText.BackgroundTransparency = 1
    InfoText.Text = [[💜 Purple Dump Panel v5.0

• Pressione F para abrir/fechar
• Dump REAL salva arquivos no PC
• Trigger 100% funcional
• Tema roxo/preto premium
• Compatível com Xeno Executor]]
    InfoText.TextColor3 = Config.Theme.Text
    InfoText.Font = Enum.Font.GothamBold
    InfoText.TextSize = 13
    InfoText.TextXAlignment = Enum.TextXAlignment.Left
    InfoText.TextYAlignment = Enum.TextYAlignment.Top
    InfoText.TextWrapped = true
    InfoText.Parent = InfoFrame
    
    yPos = yPos + 150
    
    local ResetButton = CreateStyledButton("⚠️ RESETAR TUDO", Config.Theme.Error, ScrollFrame,
        UDim2.new(0, 0, 0, yPos), UDim2.new(1, -10, 0, 50))
    
    ResetButton.MouseButton1Click:Connect(function()
        CapturedEvents = {}
        BlockedEvents = {}
        KeyLogs = {}
        ScriptCache = {}
        HookedObjects = {}
        
        ResetButton.Text = "✅ RESETADO!"
        task.wait(2)
        ResetButton.Text = "⚠️ RESETAR TUDO"
    end)
end

-- Função para alternar visibilidade com animação
local function ToggleUI()
    IsUIVisible = not IsUIVisible
    
    if IsUIVisible then
        MainFrame.Visible = true
        Shadow.Visible = true
        
        MainFrame.Size = UDim2.new(0, 0, 0, 0)
        MainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
        
        TweenService:Create(MainFrame, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
            Size = UDim2.new(0, 840, 0, 640),
            Position = UDim2.new(0.5, -420, 0.5, -320)
        }):Play()
        
        TweenService:Create(Shadow, TweenInfo.new(0.3), {
            BackgroundTransparency = 0.8
        }):Play()
        
        SwitchTab(CurrentTab)
    else
        TweenService:Create(MainFrame, TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.In), {
            Size = UDim2.new(0, 0, 0, 0),
            Position = UDim2.new(0.5, 0, 0.5, 0)
        }):Play()
        
        TweenService:Create(Shadow, TweenInfo.new(0.2), {
            BackgroundTransparency = 1
        }):Play()
        
        task.wait(0.2)
        MainFrame.Visible = false
        Shadow.Visible = false
    end
end

-- Hotkey F
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    
    if input.KeyCode == Enum.KeyCode.F then
        ToggleUI()
    end
end)

-- Botões de controle
CloseButton.MouseButton1Click:Connect(ToggleUI)
MinimizeButton.MouseButton1Click:Connect(ToggleUI)

-- Criar abas
local tabs = {
    {name = "Dump", icon = "💜"},
    {name = "Event Logs", icon = "📡"},
    {name = "Key Logs", icon = "⌨️"},
    {name = "Executor", icon = "⚡"},
    {name = "Settings", icon = "⚙️"}
}

for i, tab in ipairs(tabs) do
    CreateTabButton(tab.name, tab.icon, i)
end

-- Inicializar
SwitchTab("Dump")

-- Notificação de inicialização
local function ShowNotification(text, duration)
    local NotifFrame = Instance.new("Frame")
    NotifFrame.Size = UDim2.new(0, 350, 0, 70)
    NotifFrame.Position = UDim2.new(1, -360, 1, -80)
    NotifFrame.BackgroundColor3 = Config.Theme.Primary
    NotifFrame.BorderSizePixel = 0
    NotifFrame.Parent = ScreenGui
    
    local NotifCorner = Instance.new("UICorner")
    NotifCorner.CornerRadius = UDim.new(0, 12)
    NotifCorner.Parent = NotifFrame
    
    local NotifText = Instance.new("TextLabel")
    NotifText.Size = UDim2.new(1, -20, 1, -20)
    NotifText.Position = UDim2.new(0, 10, 0, 10)
    NotifText.BackgroundTransparency = 1
    NotifText.Text = text
    NotifText.TextColor3 = Config.Theme.Text
    NotifText.Font = Enum.Font.GothamBold
    NotifText.TextSize = 14
    NotifText.TextWrapped = true
    NotifText.Parent = NotifFrame
    
    TweenService:Create(NotifFrame, TweenInfo.new(0.3), {
        Position = UDim2.new(1, -360, 1, -90)
    }):Play()
    
    task.wait(duration or 4)
    
    TweenService:Create(NotifFrame, TweenInfo.new(0.3), {
        Position = UDim2.new(1, -360, 1, 0)
    }):Play()
    
    task.wait(0.3)
    NotifFrame:Destroy()
end

ShowNotification("💜 Purple Dump Panel v5.0\n✅ Carregado! Pressione F\n🔧 Dump REAL + Trigger 100%", 5)

print("╔═════════════════════════════════════════╗")
print("║   💜 Purple Dump Panel v5.0             ║")
print("║   ✅ Carregado com sucesso!             ║")
print("║   📌 Pressione F para abrir/fechar      ║")
print("║   🔧 Dump REAL + Trigger 100%           ║")
print("║   🎨 Tema roxo/preto premium            ║")
print("╚═════════════════════════════════════════╝")

-- Auto-inicialização do hook se configurado
if Config.AutoHook then
    task.spawn(function()
        task.wait(3)
        HookExistingRemotes()
        print("💜 Auto-hook inicializado: " .. tostring(#HookedObjects) .. " objetos hookados")
    end)
end

-- Limpeza ao sair
game:GetService("Players").PlayerRemoving:Connect(function(player)
    if player == LocalPlayer then
        for _, connection in pairs(ConnectionsTable) do
            pcall(function() connection:Disconnect() end)
        end
        pcall(function() ScreenGui:Destroy() end)
    end
end)
