--[[
    ╔═══════════════════════════════════════════════════════════╗
    ║  Advanced Dump & Monitoring Panel v3.0                   ║
    ║  Funcionalidades: Dump completo, Event Spy, Key Logger   ║
    ║  Code Executor e Monitoramento em tempo real             ║
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

-- Configurações
local Config = {
    AutoHook = true,
    MaxEventLogs = 500,
    MaxKeyLogs = 1000,
    AutoScroll = true,
    ShowTimestamps = true,
    CaptureMouseEvents = true,
    Theme = {
        Primary = Color3.fromRGB(88, 101, 242),
        Secondary = Color3.fromRGB(32, 34, 37),
        Background = Color3.fromRGB(47, 49, 54),
        Surface = Color3.fromRGB(54, 57, 63),
        Success = Color3.fromRGB(67, 181, 129),
        Warning = Color3.fromRGB(250, 166, 26),
        Error = Color3.fromRGB(237, 66, 69),
        Text = Color3.fromRGB(255, 255, 255),
        TextSecondary = Color3.fromRGB(185, 187, 190)
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

-- Criar UI
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "AdvancedDumpPanelV3"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

-- Proteção contra detecção
local success = pcall(function()
    ScreenGui.Parent = CoreGui
end)
if not success then
    ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
end

-- Frame Principal com sombra
local Shadow = Instance.new("Frame")
Shadow.Name = "Shadow"
Shadow.Size = UDim2.new(0, 810, 0, 610)
Shadow.Position = UDim2.new(0.5, -405, 0.5, -305)
Shadow.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
Shadow.BackgroundTransparency = 0.7
Shadow.BorderSizePixel = 0
Shadow.Visible = false
Shadow.Parent = ScreenGui

local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 800, 0, 600)
MainFrame.Position = UDim2.new(0.5, -400, 0.5, -300)
MainFrame.BackgroundColor3 = Config.Theme.Background
MainFrame.BorderSizePixel = 0
MainFrame.Visible = false
MainFrame.ClipsDescendants = true
MainFrame.Parent = ScreenGui

-- Corner para bordas arredondadas
local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 12)
MainCorner.Parent = MainFrame

-- Barra de título moderna
local TitleBar = Instance.new("Frame")
TitleBar.Name = "TitleBar"
TitleBar.Size = UDim2.new(1, 0, 0, 40)
TitleBar.BackgroundColor3 = Config.Theme.Primary
TitleBar.BorderSizePixel = 0
TitleBar.Parent = MainFrame

local TitleCorner = Instance.new("UICorner")
TitleCorner.CornerRadius = UDim.new(0, 12)
TitleCorner.Parent = TitleBar

-- Corrigir cantos inferiores da barra de título
local TitleBottomCover = Instance.new("Frame")
TitleBottomCover.Size = UDim2.new(1, 0, 0, 12)
TitleBottomCover.Position = UDim2.new(0, 0, 1, -12)
TitleBottomCover.BackgroundColor3 = Config.Theme.Primary
TitleBottomCover.BorderSizePixel = 0
TitleBottomCover.Parent = TitleBar

-- Ícone e título
local TitleIcon = Instance.new("TextLabel")
TitleIcon.Size = UDim2.new(0, 30, 0, 30)
TitleIcon.Position = UDim2.new(0, 10, 0, 5)
TitleIcon.BackgroundTransparency = 1
TitleIcon.Text = "🔍"
TitleIcon.TextColor3 = Config.Theme.Text
TitleIcon.Font = Enum.Font.GothamBold
TitleIcon.TextSize = 18
TitleIcon.Parent = TitleBar

local TitleLabel = Instance.new("TextLabel")
TitleLabel.Size = UDim2.new(0, 400, 0, 30)
TitleLabel.Position = UDim2.new(0, 45, 0, 5)
TitleLabel.BackgroundTransparency = 1
TitleLabel.Text = "Advanced Dump Panel v3.0"
TitleLabel.TextColor3 = Config.Theme.Text
TitleLabel.Font = Enum.Font.GothamBold
TitleLabel.TextSize = 16
TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
TitleLabel.Parent = TitleBar

-- Status de captura
local StatusLabel = Instance.new("TextLabel")
StatusLabel.Size = UDim2.new(0, 150, 0, 20)
StatusLabel.Position = UDim2.new(1, -320, 0, 10)
StatusLabel.BackgroundColor3 = Config.Theme.Surface
StatusLabel.Text = "⚫ Captura: OFF"
StatusLabel.TextColor3 = Config.Theme.TextSecondary
StatusLabel.Font = Enum.Font.Gotham
StatusLabel.TextSize = 12
StatusLabel.Parent = TitleBar

local StatusCorner = Instance.new("UICorner")
StatusCorner.CornerRadius = UDim.new(0, 10)
StatusCorner.Parent = StatusLabel

-- Botões de controle
local MinimizeButton = Instance.new("TextButton")
MinimizeButton.Size = UDim2.new(0, 35, 0, 35)
MinimizeButton.Position = UDim2.new(1, -110, 0, 2.5)
MinimizeButton.BackgroundColor3 = Config.Theme.Warning
MinimizeButton.Text = "─"
MinimizeButton.TextColor3 = Config.Theme.Text
MinimizeButton.Font = Enum.Font.GothamBold
MinimizeButton.TextSize = 18
MinimizeButton.Parent = TitleBar

local MinimizeCorner = Instance.new("UICorner")
MinimizeCorner.CornerRadius = UDim.new(0, 8)
MinimizeCorner.Parent = MinimizeButton

local MaximizeButton = Instance.new("TextButton")
MaximizeButton.Size = UDim2.new(0, 35, 0, 35)
MaximizeButton.Position = UDim2.new(1, -70, 0, 2.5)
MaximizeButton.BackgroundColor3 = Config.Theme.Success
MaximizeButton.Text = "□"
MaximizeButton.TextColor3 = Config.Theme.Text
MaximizeButton.Font = Enum.Font.GothamBold
MaximizeButton.TextSize = 14
MaximizeButton.Parent = TitleBar

local MaximizeCorner = Instance.new("UICorner")
MaximizeCorner.CornerRadius = UDim.new(0, 8)
MaximizeCorner.Parent = MaximizeButton

local CloseButton = Instance.new("TextButton")
CloseButton.Size = UDim2.new(0, 35, 0, 35)
CloseButton.Position = UDim2.new(1, -30, 0, 2.5)
CloseButton.BackgroundColor3 = Config.Theme.Error
CloseButton.Text = "✕"
CloseButton.TextColor3 = Config.Theme.Text
CloseButton.Font = Enum.Font.GothamBold
CloseButton.TextSize = 16
CloseButton.Parent = TitleBar

local CloseCorner = Instance.new("UICorner")
CloseCorner.CornerRadius = UDim.new(0, 8)
CloseCorner.Parent = CloseButton

-- Abas modernas
local TabButtons = Instance.new("Frame")
TabButtons.Name = "TabButtons"
TabButtons.Size = UDim2.new(1, -20, 0, 45)
TabButtons.Position = UDim2.new(0, 10, 0, 50)
TabButtons.BackgroundTransparency = 1
TabButtons.Parent = MainFrame

local TabLayout = Instance.new("UIListLayout")
TabLayout.FillDirection = Enum.FillDirection.Horizontal
TabLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
TabLayout.SortOrder = Enum.SortOrder.LayoutOrder
TabLayout.Padding = UDim.new(0, 8)
TabLayout.Parent = TabButtons

-- Conteúdo das abas
local TabContent = Instance.new("Frame")
TabContent.Name = "TabContent"
TabContent.Size = UDim2.new(1, -20, 1, -115)
TabContent.Position = UDim2.new(0, 10, 0, 105)
TabContent.BackgroundColor3 = Config.Theme.Surface
TabContent.BorderSizePixel = 0
TabContent.Parent = MainFrame

local ContentCorner = Instance.new("UICorner")
ContentCorner.CornerRadius = UDim.new(0, 10)
ContentCorner.Parent = TabContent

-- Variável de controle da aba atual
local CurrentTab = "Dump"
local CurrentTabButton = nil

-- Função para criar botão de aba
local function CreateTabButton(name, icon, index)
    local Button = Instance.new("TextButton")
    Button.Name = name
    Button.Size = UDim2.new(0, 145, 1, 0)
    Button.BackgroundColor3 = Config.Theme.Surface
    Button.Text = ""
    Button.Font = Enum.Font.GothamBold
    Button.TextSize = 13
    Button.TextColor3 = Config.Theme.TextSecondary
    Button.AutoButtonColor = false
    Button.LayoutOrder = index
    Button.Parent = TabButtons
    
    local ButtonCorner = Instance.new("UICorner")
    ButtonCorner.CornerRadius = UDim.new(0, 8)
    ButtonCorner.Parent = Button
    
    local IconLabel = Instance.new("TextLabel")
    IconLabel.Size = UDim2.new(0, 25, 0, 25)
    IconLabel.Position = UDim2.new(0, 10, 0.5, -12.5)
    IconLabel.BackgroundTransparency = 1
    IconLabel.Text = icon
    IconLabel.Font = Enum.Font.GothamBold
    IconLabel.TextSize = 16
    IconLabel.TextColor3 = Config.Theme.TextSecondary
    IconLabel.Parent = Button
    
    local TextLabel = Instance.new("TextLabel")
    TextLabel.Size = UDim2.new(1, -45, 1, 0)
    TextLabel.Position = UDim2.new(0, 40, 0, 0)
    TextLabel.BackgroundTransparency = 1
    TextLabel.Text = name
    TextLabel.Font = Enum.Font.GothamBold
    TextLabel.TextSize = 13
    TextLabel.TextColor3 = Config.Theme.TextSecondary
    TextLabel.TextXAlignment = Enum.TextXAlignment.Left
    TextLabel.Parent = Button
    
    Button.MouseButton1Click:Connect(function()
        SwitchTab(name, Button, IconLabel, TextLabel)
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
    
    return Button, IconLabel, TextLabel
end

-- Função para trocar de aba com animação
function SwitchTab(tabName, button, icon, text)
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
    
    -- Limpar conteúdo anterior com fade
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

-- Função auxiliar para criar botões estilizados
local function CreateStyledButton(text, color, parent, position, size)
    local Button = Instance.new("TextButton")
    Button.Size = size or UDim2.new(0.45, 0, 0, 38)
    Button.Position = position or UDim2.new(0, 0, 0, 0)
    Button.BackgroundColor3 = color
    Button.Text = text
    Button.TextColor3 = Config.Theme.Text
    Button.Font = Enum.Font.GothamBold
    Button.TextSize = 13
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

-- ABA DUMP
function CreateDumpTab()
    local Container = Instance.new("Frame")
    Container.Size = UDim2.new(1, 0, 1, 0)
    Container.BackgroundTransparency = 1
    Container.Parent = TabContent
    
    local ButtonFrame = Instance.new("Frame")
    ButtonFrame.Size = UDim2.new(1, -20, 0, 45)
    ButtonFrame.Position = UDim2.new(0, 10, 0, 10)
    ButtonFrame.BackgroundTransparency = 1
    ButtonFrame.Parent = Container
    
    local DumpButton = CreateStyledButton("🚀 INICIAR DUMP COMPLETO", Config.Theme.Primary, ButtonFrame, 
        UDim2.new(0, 0, 0, 0), UDim2.new(0.48, 0, 1, 0))
    
    local ExportButton = CreateStyledButton("💾 EXPORTAR DUMP", Config.Theme.Success, ButtonFrame, 
        UDim2.new(0.52, 0, 0, 0), UDim2.new(0.48, 0, 1, 0))
    
    local ScrollFrame = Instance.new("ScrollingFrame")
    ScrollFrame.Size = UDim2.new(1, -20, 1, -75)
    ScrollFrame.Position = UDim2.new(0, 10, 0, 65)
    ScrollFrame.BackgroundColor3 = Config.Theme.Secondary
    ScrollFrame.BorderSizePixel = 0
    ScrollFrame.ScrollBarThickness = 6
    ScrollFrame.ScrollBarImageColor3 = Config.Theme.Primary
    ScrollFrame.Parent = Container
    
    local ScrollCorner = Instance.new("UICorner")
    ScrollCorner.CornerRadius = UDim.new(0, 8)
    ScrollCorner.Parent = ScrollFrame
    
    local OutputBox = CreateStyledTextBox("Aguardando dump...\n\n💡 Dica: Pressione F para abrir/fechar o painel", 
        ScrollFrame, UDim2.new(0, 5, 0, 5), UDim2.new(1, -10, 1, -10), true)
    OutputBox.TextEditable = false
    
    DumpButton.MouseButton1Click:Connect(function()
        DumpButton.Text = "⏳ PROCESSANDO..."
        DumpButton.BackgroundColor3 = Config.Theme.Warning
        
        task.spawn(function()
            PerformFullDump(OutputBox)
            task.wait(0.5)
            DumpButton.Text = "🚀 INICIAR DUMP COMPLETO"
            DumpButton.BackgroundColor3 = Config.Theme.Primary
        end)
    end)
    
    ExportButton.MouseButton1Click:Connect(function()
        local dumpData = OutputBox.Text
        setclipboard(dumpData)
        
        ExportButton.Text = "✅ COPIADO!"
        task.wait(2)
        ExportButton.Text = "💾 EXPORTAR DUMP"
    end)
end

-- Função de dump melhorada
function PerformFullDump(outputBox)
    local startTime = tick()
    outputBox.Text = "╔════════════════════════════════════════╗\n"
    outputBox.Text = outputBox.Text .. "║  INICIANDO DUMP COMPLETO DO JOGO      ║\n"
    outputBox.Text = outputBox.Text .. "╚════════════════════════════════════════╝\n\n"
    
    local stats = {
        TotalObjects = 0,
        Scripts = 0,
        RemoteEvents = 0,
        RemoteFunctions = 0,
        LocalScripts = 0,
        ModuleScripts = 0
    }
    
    local function DumpObject(obj, indent, path)
        stats.TotalObjects = stats.TotalObjects + 1
        local objPath = path .. "/" .. obj.Name
        local icon = "📦"
        
        if obj:IsA("Script") then
            icon = "📜"
            stats.Scripts = stats.Scripts + 1
        elseif obj:IsA("LocalScript") then
            icon = "🔧"
            stats.LocalScripts = stats.LocalScripts + 1
        elseif obj:IsA("ModuleScript") then
            icon = "📚"
            stats.ModuleScripts = stats.ModuleScripts + 1
        elseif obj:IsA("RemoteEvent") then
            icon = "📡"
            stats.RemoteEvents = stats.RemoteEvents + 1
        elseif obj:IsA("RemoteFunction") then
            icon = "🔌"
            stats.RemoteFunctions = stats.RemoteFunctions + 1
        end
        
        outputBox.Text = outputBox.Text .. indent .. icon .. " " .. obj.Name .. " (" .. obj.ClassName .. ")\n"
        
        -- Cache de scripts importantes
        if obj:IsA("Script") or obj:IsA("LocalScript") or obj:IsA("ModuleScript") then
            ScriptCache[objPath] = {
                Object = obj,
                Path = objPath,
                ClassName = obj.ClassName,
                Source = "Protected"
            }
        end
        
        -- Recursão com limite de profundidade
        if #indent < 40 then
            for _, child in pairs(obj:GetChildren()) do
                DumpObject(child, indent .. "  ", objPath)
            end
        end
    end
    
    -- Dump dos principais serviços
    local services = {
        "Workspace",
        "ReplicatedStorage",
        "ReplicatedFirst",
        "ServerScriptService",
        "StarterGui",
        "StarterPack",
        "StarterPlayer",
        "Lighting",
        "SoundService"
    }
    
    for _, serviceName in pairs(services) do
        local service = game:GetService(serviceName)
        outputBox.Text = outputBox.Text .. "\n┌─ " .. serviceName .. " ─┐\n"
        DumpObject(service, "  ", serviceName)
    end
    
    local endTime = tick()
    local duration = string.format("%.2f", endTime - startTime)
    
    outputBox.Text = outputBox.Text .. "\n╔════════════════════════════════════════╗\n"
    outputBox.Text = outputBox.Text .. "║         DUMP CONCLUÍDO COM SUCESSO     ║\n"
    outputBox.Text = outputBox.Text .. "╚════════════════════════════════════════╝\n\n"
    outputBox.Text = outputBox.Text .. "📊 Estatísticas:\n"
    outputBox.Text = outputBox.Text .. "   • Total de Objetos: " .. stats.TotalObjects .. "\n"
    outputBox.Text = outputBox.Text .. "   • Scripts: " .. stats.Scripts .. "\n"
    outputBox.Text = outputBox.Text .. "   • LocalScripts: " .. stats.LocalScripts .. "\n"
    outputBox.Text = outputBox.Text .. "   • ModuleScripts: " .. stats.ModuleScripts .. "\n"
    outputBox.Text = outputBox.Text .. "   • RemoteEvents: " .. stats.RemoteEvents .. "\n"
    outputBox.Text = outputBox.Text .. "   • RemoteFunctions: " .. stats.RemoteFunctions .. "\n"
    outputBox.Text = outputBox.Text .. "   • Tempo de execução: " .. duration .. "s\n"
end

-- ABA EVENT LOGS (Melhorada)
function CreateEventLogsTab()
    local Container = Instance.new("Frame")
    Container.Size = UDim2.new(1, 0, 1, 0)
    Container.BackgroundTransparency = 1
    Container.Parent = TabContent
    
    local ControlFrame = Instance.new("Frame")
    ControlFrame.Size = UDim2.new(1, -20, 0, 45)
    ControlFrame.Position = UDim2.new(0, 10, 0, 10)
    ControlFrame.BackgroundTransparency = 1
    ControlFrame.Parent = Container
    
    local StartButton = CreateStyledButton("🟢 INICIAR CAPTURA", Config.Theme.Success, ControlFrame,
        UDim2.new(0, 0, 0, 0), UDim2.new(0.31, 0, 1, 0))
    
    local ClearButton = CreateStyledButton("🗑️ LIMPAR", Config.Theme.Error, ControlFrame,
        UDim2.new(0.345, 0, 0, 0), UDim2.new(0.31, 0, 1, 0))
    
    local ExportButton = CreateStyledButton("💾 EXPORTAR", Config.Theme.Primary, ControlFrame,
        UDim2.new(0.69, 0, 0, 0), UDim2.new(0.31, 0, 1, 0))
    
    local InfoFrame = Instance.new("Frame")
    InfoFrame.Size = UDim2.new(1, -20, 0, 30)
    InfoFrame.Position = UDim2.new(0, 10, 0, 65)
    InfoFrame.BackgroundColor3 = Config.Theme.Secondary
    InfoFrame.Parent = Container
    
    local InfoCorner = Instance.new("UICorner")
    InfoCorner.CornerRadius = UDim.new(0, 8)
    InfoCorner.Parent = InfoFrame
    
    local InfoLabel = Instance.new("TextLabel")
    InfoLabel.Size = UDim2.new(1, -20, 1, 0)
    InfoLabel.Position = UDim2.new(0, 10, 0, 0)
    InfoLabel.BackgroundTransparency = 1
    InfoLabel.Text = "📊 Eventos Capturados: 0 | 🔒 Bloqueados: 0"
    InfoLabel.TextColor3 = Config.Theme.Text
    InfoLabel.Font = Enum.Font.Gotham
    InfoLabel.TextSize = 12
    InfoLabel.TextXAlignment = Enum.TextXAlignment.Left
    InfoLabel.Parent = InfoFrame
    
    local ScrollFrame = Instance.new("ScrollingFrame")
    ScrollFrame.Size = UDim2.new(1, -20, 1, -115)
    ScrollFrame.Position = UDim2.new(0, 10, 0, 105)
    ScrollFrame.BackgroundColor3 = Config.Theme.Secondary
    ScrollFrame.BorderSizePixel = 0
    ScrollFrame.ScrollBarThickness = 6
    ScrollFrame.ScrollBarImageColor3 = Config.Theme.Primary
    ScrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
    ScrollFrame.Parent = Container
    
    local ScrollCorner = Instance.new("UICorner")
    ScrollCorner.CornerRadius = UDim.new(0, 8)
    ScrollCorner.Parent = ScrollFrame
    
    local ListLayout = Instance.new("UIListLayout")
    ListLayout.SortOrder = Enum.SortOrder.LayoutOrder
    ListLayout.Padding = UDim.new(0, 8)
    ListLayout.Parent = ScrollFrame
    
    ListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        ScrollFrame.CanvasSize = UDim2.new(0, 0, 0, ListLayout.AbsoluteContentSize.Y + 10)
    end)
    
    -- Função para atualizar a lista de eventos
    local function UpdateEventsList()
        for _, child in pairs(ScrollFrame:GetChildren()) do
            if child:IsA("Frame") then
                child:Destroy()
            end
        end
        
        local blockedCount = 0
        for _ in pairs(BlockedEvents) do
            blockedCount = blockedCount + 1
        end
        
        InfoLabel.Text = string.format("📊 Eventos Capturados: %d | 🔒 Bloqueados: %d", #CapturedEvents, blockedCount)
        
        for i = #CapturedEvents, math.max(1, #CapturedEvents - 50), -1 do
            local event = CapturedEvents[i]
            if not event then continue end
            
            local EventFrame = Instance.new("Frame")
            EventFrame.Size = UDim2.new(1, -10, 0, 85)
            EventFrame.BackgroundColor3 = Config.Theme.Surface
            EventFrame.BorderSizePixel = 0
            EventFrame.Parent = ScrollFrame
            
            local EventCorner = Instance.new("UICorner")
            EventCorner.CornerRadius = UDim.new(0, 8)
            EventCorner.Parent = EventFrame
            
            local TypeBadge = Instance.new("TextLabel")
            TypeBadge.Size = UDim2.new(0, 100, 0, 22)
            TypeBadge.Position = UDim2.new(0, 8, 0, 8)
            TypeBadge.BackgroundColor3 = event.Type == "RemoteEvent" and Config.Theme.Primary or Config.Theme.Warning
            TypeBadge.Text = event.Type == "RemoteEvent" and "📡 Event" or "🔌 Function"
            TypeBadge.TextColor3 = Config.Theme.Text
            TypeBadge.Font = Enum.Font.GothamBold
            TypeBadge.TextSize = 11
            TypeBadge.Parent = EventFrame
            
            local BadgeCorner = Instance.new("UICorner")
            BadgeCorner.CornerRadius = UDim.new(0, 6)
            BadgeCorner.Parent = TypeBadge
            
            local EventName = Instance.new("TextLabel")
            EventName.Size = UDim2.new(1, -220, 0, 22)
            EventName.Position = UDim2.new(0, 115, 0, 8)
            EventName.BackgroundTransparency = 1
            EventName.Text = event.Object.Name
            EventName.TextColor3 = Config.Theme.Text
            EventName.Font = Enum.Font.GothamBold
            EventName.TextSize = 13
            EventName.TextXAlignment = Enum.TextXAlignment.Left
            EventName.TextTruncate = Enum.TextTruncate.AtEnd
            EventName.Parent = EventFrame
            
            local PathLabel = Instance.new("TextLabel")
            PathLabel.Size = UDim2.new(1, -120, 0, 18)
            PathLabel.Position = UDim2.new(0, 8, 0, 32)
            PathLabel.BackgroundTransparency = 1
            PathLabel.Text = "📂 " .. event.Object:GetFullName()
            PathLabel.TextColor3 = Config.Theme.TextSecondary
            PathLabel.Font = Enum.Font.Gotham
            PathLabel.TextSize = 10
            PathLabel.TextXAlignment = Enum.TextXAlignment.Left
            PathLabel.TextTruncate = Enum.TextTruncate.AtEnd
            PathLabel.Parent = EventFrame
            
            local ArgsLabel = Instance.new("TextLabel")
            ArgsLabel.Size = UDim2.new(0.5, -10, 0, 25)
            ArgsLabel.Position = UDim2.new(0, 8, 1, -30)
            ArgsLabel.BackgroundTransparency = 1
            ArgsLabel.Text = string.format("📦 Args: %d | ⏰ %s", #event.Arguments, os.date("%H:%M:%S", event.Timestamp))
            ArgsLabel.TextColor3 = Config.Theme.TextSecondary
            ArgsLabel.Font = Enum.Font.Gotham
            ArgsLabel.TextSize = 10
            ArgsLabel.TextXAlignment = Enum.TextXAlignment.Left
            ArgsLabel.Parent = EventFrame
            
            local BlockButton = CreateStyledButton(
                BlockedEvents[event.Object] and "🔓 Desbloquear" or "🔒 Bloquear",
                BlockedEvents[event.Object] and Config.Theme.Success or Config.Theme.Error,
                EventFrame,
                UDim2.new(1, -180, 0, 8),
                UDim2.new(0, 85, 0, 32)
            )
            
            local ReplayButton = CreateStyledButton(
                "▶️ Replay",
                Config.Theme.Primary,
                EventFrame,
                UDim2.new(1, -90, 0, 8),
                UDim2.new(0, 85, 0, 32)
            )
            
            local CopyButton = CreateStyledButton(
                "📋 Copiar",
                Config.Theme.Warning,
                EventFrame,
                UDim2.new(1, -180, 0, 45),
                UDim2.new(0, 175, 0, 32)
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
                local argsString = HttpService:JSONEncode(event.Arguments)
                local copyText = string.format("-- %s\n%s:FireServer(%s)", 
                    event.Object:GetFullName(), 
                    event.Object.Name,
                    argsString
                )
                setclipboard(copyText)
                
                CopyButton.Text = "✅ Copiado!"
                task.wait(1)
                CopyButton.Text = "📋 Copiar"
            end)
        end
    end
    
    -- Sistema de hook melhorado
    local function HookRemoteEvents()
        local function HookObject(obj)
            if (obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction")) and not HookedObjects[obj] then
                HookedObjects[obj] = true
                
                if obj:IsA("RemoteEvent") then
                    local oldNamecall
                    oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
                        local method = getnamecallmethod()
                        local args = {...}
                        
                        if self == obj and (method == "FireServer" or method == "fireServer") then
                            if IsCapturing then
                                local eventData = {
                                    Object = obj,
                                    Arguments = args,
                                    Timestamp = os.time(),
                                    Type = "RemoteEvent"
                                }
                                
                                table.insert(CapturedEvents, 1, eventData)
                                
                                -- Limitar logs
                                if #CapturedEvents > Config.MaxEventLogs then
                                    table.remove(CapturedEvents, #CapturedEvents)
                                end
                                
                                if IsUIVisible and CurrentTab == "Event Logs" then
                                    UpdateEventsList()
                                end
                            end
                            
                            if BlockedEvents[obj] then
                                return nil
                            end
                        end
                        
                        return oldNamecall(self, ...)
                    end)
                else
                    local oldNamecall
                    oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
                        local method = getnamecallmethod()
                        local args = {...}
                        
                        if self == obj and (method == "InvokeServer" or method == "invokeServer") then
                            if IsCapturing then
                                local eventData = {
                                    Object = obj,
                                    Arguments = args,
                                    Timestamp = os.time(),
                                    Type = "RemoteFunction"
                                }
                                
                                table.insert(CapturedEvents, 1, eventData)
                                
                                if #CapturedEvents > Config.MaxEventLogs then
                                    table.remove(CapturedEvents, #CapturedEvents)
                                end
                                
                                if IsUIVisible and CurrentTab == "Event Logs" then
                                    UpdateEventsList()
                                end
                            end
                            
                            if BlockedEvents[obj] then
                                return nil
                            end
                        end
                        
                        return oldNamecall(self, ...)
                    end)
                end
            end
        end
        
        for _, obj in pairs(game:GetDescendants()) do
            pcall(function()
                HookObject(obj)
            end)
        end
        
        game.DescendantAdded:Connect(function(obj)
            pcall(function()
                HookObject(obj)
            end)
        end)
    end
    
    StartButton.MouseButton1Click:Connect(function()
        IsCapturing = not IsCapturing
        
        if IsCapturing then
            StartButton.Text = "🔴 PARAR CAPTURA"
            StartButton.BackgroundColor3 = Config.Theme.Error
            StatusLabel.Text = "🟢 Captura: ON"
            StatusLabel.BackgroundColor3 = Config.Theme.Success
            
            if Config.AutoHook then
                HookRemoteEvents()
            end
        else
            StartButton.Text = "🟢 INICIAR CAPTURA"
            StartButton.BackgroundColor3 = Config.Theme.Success
            StatusLabel.Text = "⚫ Captura: OFF"
            StatusLabel.BackgroundColor3 = Config.Theme.Surface
        end
    end)
    
    ClearButton.MouseButton1Click:Connect(function()
        CapturedEvents = {}
        BlockedEvents = {}
        UpdateEventsList()
    end)
    
    ExportButton.MouseButton1Click:Connect(function()
        local exportData = "-- Exported Events Log\n\n"
        for i, event in ipairs(CapturedEvents) do
            exportData = exportData .. string.format(
                "-- [%d] %s (%s)\n-- Path: %s\n-- Args: %s\n\n",
                i,
                event.Object.Name,
                event.Type,
                event.Object:GetFullName(),
                HttpService:JSONEncode(event.Arguments)
            )
        end
        
        setclipboard(exportData)
        ExportButton.Text = "✅ COPIADO!"
        task.wait(2)
        ExportButton.Text = "💾 EXPORTAR"
    end)
    
    UpdateEventsList()
end

-- ABA KEY LOGS (Melhorada)
function CreateKeyLogsTab()
    local Container = Instance.new("Frame")
    Container.Size = UDim2.new(1, 0, 1, 0)
    Container.BackgroundTransparency = 1
    Container.Parent = TabContent
    
    local ControlFrame = Instance.new("Frame")
    ControlFrame.Size = UDim2.new(1, -20, 0, 45)
    ControlFrame.Position = UDim2.new(0, 10, 0, 10)
    ControlFrame.BackgroundTransparency = 1
    ControlFrame.Parent = Container
    
    local ClearButton = CreateStyledButton("🗑️ LIMPAR LOGS", Config.Theme.Error, ControlFrame,
        UDim2.new(0, 0, 0, 0), UDim2.new(0.48, 0, 1, 0))
    
    local ExportButton = CreateStyledButton("💾 EXPORTAR", Config.Theme.Success, ControlFrame,
        UDim2.new(0.52, 0, 0, 0), UDim2.new(0.48, 0, 1, 0))
    
    local ScrollFrame = Instance.new("ScrollingFrame")
    ScrollFrame.Size = UDim2.new(1, -20, 1, -75)
    ScrollFrame.Position = UDim2.new(0, 10, 0, 65)
    ScrollFrame.BackgroundColor3 = Config.Theme.Secondary
    ScrollFrame.BorderSizePixel = 0
    ScrollFrame.ScrollBarThickness = 6
    ScrollFrame.ScrollBarImageColor3 = Config.Theme.Primary
    ScrollFrame.Parent = Container
    
    local ScrollCorner = Instance.new("UICorner")
    ScrollCorner.CornerRadius = UDim.new(0, 8)
    ScrollCorner.Parent = ScrollFrame
    
    local LogBox = CreateStyledTextBox("⌨️ Key Logs aparecerão aqui...\nTodos os inputs serão registrados automaticamente", 
        ScrollFrame, UDim2.new(0, 5, 0, 5), UDim2.new(1, -10, 1, -10), true)
    LogBox.TextEditable = false
    
    -- Sistema de captura de input melhorado
    local inputConnection
    inputConnection = UserInputService.InputBegan:Connect(function(input, gameProcessed)
        local timestamp = os.date("%H:%M:%S")
        local inputType = input.UserInputType.Name
        local keyName = input.KeyCode.Name ~= "Unknown" and input.KeyCode.Name or "N/A"
        
        local logEntry = string.format(
            "[%s] %s | Tipo: %s | Key: %s | Processado: %s\n",
            timestamp,
            gameProcessed and "🔒" or "✅",
            inputType,
            keyName,
            tostring(gameProcessed)
        )
        
        table.insert(KeyLogs, 1, logEntry)
        
        if #KeyLogs > Config.MaxKeyLogs then
            table.remove(KeyLogs, #KeyLogs)
        end
        
        -- Atualizar display
        local displayText = ""
        for i = 1, math.min(100, #KeyLogs) do
            displayText = displayText .. KeyLogs[i]
        end
        
        LogBox.Text = displayText
        
        if Config.AutoScroll then
            ScrollFrame.CanvasPosition = Vector2.new(0, 0)
        end
    end)
    
    table.insert(ConnectionsTable, inputConnection)
    
    ClearButton.MouseButton1Click:Connect(function()
        KeyLogs = {}
        LogBox.Text = "⌨️ Key Logs limpos. Aguardando novos inputs...\n"
    end)
    
    ExportButton.MouseButton1Click:Connect(function()
        local exportText = "-- Key Logs Export\n-- Total: " .. #KeyLogs .. "\n\n" .. table.concat(KeyLogs, "")
        setclipboard(exportText)
        
        ExportButton.Text = "✅ COPIADO!"
        task.wait(2)
        ExportButton.Text = "💾 EXPORTAR"
    end)
end

-- ABA CODE EXECUTOR (Melhorada)
function CreateCodeExecutorTab()
    local Container = Instance.new("Frame")
    Container.Size = UDim2.new(1, 0, 1, 0)
    Container.BackgroundTransparency = 1
    Container.Parent = TabContent
    
    local CodeBox = CreateStyledTextBox("-- Code Executor\n-- Cole seu código Lua aqui\n\nprint('Hello from Advanced Panel!')", 
        Container, UDim2.new(0, 10, 0, 10), UDim2.new(1, -20, 0.55, -15), true)
    
    local ButtonFrame = Instance.new("Frame")
    ButtonFrame.Size = UDim2.new(1, -20, 0, 45)
    ButtonFrame.Position = UDim2.new(0, 10, 0.55, 5)
    ButtonFrame.BackgroundTransparency = 1
    ButtonFrame.Parent = Container
    
    local ExecuteButton = CreateStyledButton("▶️ EXECUTAR", Config.Theme.Success, ButtonFrame,
        UDim2.new(0, 0, 0, 0), UDim2.new(0.48, 0, 1, 0))
    
    local ClearButton = CreateStyledButton("🗑️ LIMPAR", Config.Theme.Error, ButtonFrame,
        UDim2.new(0.52, 0, 0, 0), UDim2.new(0.48, 0, 1, 0))
    
    local OutputLabel = Instance.new("TextLabel")
    OutputLabel.Size = UDim2.new(1, -20, 0, 25)
    OutputLabel.Position = UDim2.new(0, 10, 0.55, 60)
    OutputLabel.BackgroundTransparency = 1
    OutputLabel.Text = "📤 Output:"
    OutputLabel.TextColor3 = Config.Theme.Text
    OutputLabel.Font = Enum.Font.GothamBold
    OutputLabel.TextSize = 13
    OutputLabel.TextXAlignment = Enum.TextXAlignment.Left
    OutputLabel.Parent = Container
    
    local OutputBox = CreateStyledTextBox("Aguardando execução...", 
        Container, UDim2.new(0, 10, 0.55, 90), UDim2.new(1, -20, 0.45, -100), true)
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
                OutputBox.Text = string.format("✅ [%s] SUCESSO - Código executado\n", timestamp)
                if result ~= nil then
                    OutputBox.Text = OutputBox.Text .. "📦 Retorno: " .. tostring(result) .. "\n"
                end
            else
                OutputBox.Text = string.format("❌ [%s] ERRO:\n%s\n", timestamp, tostring(result))
            end
            
            task.wait(0.5)
            ExecuteButton.Text = "▶️ EXECUTAR"
            ExecuteButton.BackgroundColor3 = Config.Theme.Success
        end)
    end)
    
    ClearButton.MouseButton1Click:Connect(function()
        CodeBox.Text = ""
        OutputBox.Text = "🗑️ Código e output limpos.\n"
    end)
end

-- ABA SETTINGS (Melhorada)
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
    ScrollFrame.ScrollBarThickness = 6
    ScrollFrame.ScrollBarImageColor3 = Config.Theme.Primary
    ScrollFrame.CanvasSize = UDim2.new(0, 0, 0, 600)
    ScrollFrame.Parent = Container
    
    local yPos = 0
    
    -- Função para criar opção
    local function CreateOption(title, description, callback, isToggled)
        local OptionFrame = Instance.new("Frame")
        OptionFrame.Size = UDim2.new(1, -10, 0, 70)
        OptionFrame.Position = UDim2.new(0, 0, 0, yPos)
        OptionFrame.BackgroundColor3 = Config.Theme.Surface
        OptionFrame.BorderSizePixel = 0
        OptionFrame.Parent = ScrollFrame
        
        local OptionCorner = Instance.new("UICorner")
        OptionCorner.CornerRadius = UDim.new(0, 8)
        OptionCorner.Parent = OptionFrame
        
        local TitleLabel = Instance.new("TextLabel")
        TitleLabel.Size = UDim2.new(1, -100, 0, 20)
        TitleLabel.Position = UDim2.new(0, 15, 0, 10)
        TitleLabel.BackgroundTransparency = 1
        TitleLabel.Text = title
        TitleLabel.TextColor3 = Config.Theme.Text
        TitleLabel.Font = Enum.Font.GothamBold
        TitleLabel.TextSize = 14
        TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
        TitleLabel.Parent = OptionFrame
        
        local DescLabel = Instance.new("TextLabel")
        DescLabel.Size = UDim2.new(1, -100, 0, 35)
        DescLabel.Position = UDim2.new(0, 15, 0, 30)
        DescLabel.BackgroundTransparency = 1
        DescLabel.Text = description
        DescLabel.TextColor3 = Config.Theme.TextSecondary
        DescLabel.Font = Enum.Font.Gotham
        DescLabel.TextSize = 11
        DescLabel.TextXAlignment = Enum.TextXAlignment.Left
        DescLabel.TextYAlignment = Enum.TextYAlignment.Top
        DescLabel.TextWrapped = true
        DescLabel.Parent = OptionFrame
        
        local ToggleButton = Instance.new("TextButton")
        ToggleButton.Size = UDim2.new(0, 70, 0, 35)
        ToggleButton.Position = UDim2.new(1, -85, 0.5, -17.5)
        ToggleButton.BackgroundColor3 = isToggled and Config.Theme.Success or Config.Theme.Error
        ToggleButton.Text = isToggled and "✓ ON" or "✕ OFF"
        ToggleButton.TextColor3 = Config.Theme.Text
        ToggleButton.Font = Enum.Font.GothamBold
        ToggleButton.TextSize = 12
        ToggleButton.AutoButtonColor = false
        ToggleButton.Parent = OptionFrame
        
        local ToggleCorner = Instance.new("UICorner")
        ToggleCorner.CornerRadius = UDim.new(0, 8)
        ToggleCorner.Parent = ToggleButton
        
        ToggleButton.MouseButton1Click:Connect(function()
            isToggled = not isToggled
            ToggleButton.BackgroundColor3 = isToggled and Config.Theme.Success or Config.Theme.Error
            ToggleButton.Text = isToggled and "✓ ON" or "✕ OFF"
            callback(isToggled)
        end)
        
        yPos = yPos + 80
    end
    
    -- Opções
    CreateOption(
        "🔄 Auto Hook",
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
    
    -- Informações
    local InfoFrame = Instance.new("Frame")
    InfoFrame.Size = UDim2.new(1, -10, 0, 120)
    InfoFrame.Position = UDim2.new(0, 0, 0, yPos)
    InfoFrame.BackgroundColor3 = Config.Theme.Primary
    InfoFrame.BorderSizePixel = 0
    InfoFrame.Parent = ScrollFrame
    
    local InfoCorner = Instance.new("UICorner")
    InfoCorner.CornerRadius = UDim.new(0, 8)
    InfoCorner.Parent = InfoFrame
    
    local InfoText = Instance.new("TextLabel")
    InfoText.Size = UDim2.new(1, -20, 1, -20)
    InfoText.Position = UDim2.new(0, 10, 0, 10)
    InfoText.BackgroundTransparency = 1
    InfoText.Text = [[📖 Informações & Controles:

• Pressione F para abrir/fechar o painel
• Use as abas para navegar entre funcionalidades
• Todos os logs são salvos em memória
• Para melhor performance, limpe logs regularmente]]
    InfoText.TextColor3 = Config.Theme.Text
    InfoText.Font = Enum.Font.Gotham
    InfoText.TextSize = 12
    InfoText.TextXAlignment = Enum.TextXAlignment.Left
    InfoText.TextYAlignment = Enum.TextYAlignment.Top
    InfoText.TextWrapped = true
    InfoText.Parent = InfoFrame
    
    yPos = yPos + 130
    
    -- Botão de reset
    local ResetButton = CreateStyledButton("⚠️ RESETAR TUDO", Config.Theme.Error, ScrollFrame,
        UDim2.new(0, 0, 0, yPos), UDim2.new(1, -10, 0, 45))
    
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
            Size = UDim2.new(0, 800, 0, 600),
            Position = UDim2.new(0.5, -400, 0.5, -300)
        }):Play()
        
        TweenService:Create(Shadow, TweenInfo.new(0.3), {
            BackgroundTransparency = 0.7
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
    {name = "Dump", icon = "📁"},
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
    NotifFrame.Size = UDim2.new(0, 300, 0, 60)
    NotifFrame.Position = UDim2.new(1, -310, 1, -70)
    NotifFrame.BackgroundColor3 = Config.Theme.Success
    NotifFrame.BorderSizePixel = 0
    NotifFrame.Parent = ScreenGui
    
    local NotifCorner = Instance.new("UICorner")
    NotifCorner.CornerRadius = UDim.new(0, 10)
    NotifCorner.Parent = NotifFrame
    
    local NotifText = Instance.new("TextLabel")
    NotifText.Size = UDim2.new(1, -20, 1, -20)
    NotifText.Position = UDim2.new(0, 10, 0, 10)
    NotifText.BackgroundTransparency = 1
    NotifText.Text = text
    NotifText.TextColor3 = Config.Theme.Text
    NotifText.Font = Enum.Font.GothamBold
    NotifText.TextSize = 13
    NotifText.TextWrapped = true
    NotifText.Parent = NotifFrame
    
    TweenService:Create(NotifFrame, TweenInfo.new(0.3), {
        Position = UDim2.new(1, -310, 1, -80)
    }):Play()
    
    task.wait(duration or 3)
    
    TweenService:Create(NotifFrame, TweenInfo.new(0.3), {
        Position = UDim2.new(1, -310, 1, 0)
    }):Play()
    
    task.wait(0.3)
    NotifFrame:Destroy()
end

ShowNotification("🎮 Advanced Dump Panel v3.0\n✅ Carregado! Pressione F", 4)

print("╔═════════════════════════════════════════╗")
print("║   Advanced Dump Panel v3.0              ║")
print("║   ✅ Carregado com sucesso!             ║")
print("║   📌 Pressione F para abrir/fechar      ║")
print("║   🔧 Desenvolvido para análise avançada ║")
print("╚═════════════════════════════════════════╝")

-- Auto-inicialização do hook se configurado
if Config.AutoHook then
    task.spawn(function()
        task.wait(2)
        for _, obj in pairs(game:GetDescendants()) do
            if obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction") then
                HookedObjects[obj] = true
            end
        end
        print("🔗 Auto-hook inicializado: " .. tostring(#HookedObjects) .. " objetos")
    end)
end

-- Limpeza ao sair
game:GetService("Players").PlayerRemoving:Connect(function(player)
    if player == LocalPlayer then
        for _, connection in pairs(ConnectionsTable) do
            connection:Disconnect()
        end
        ScreenGui:Destroy()
    end
end)
