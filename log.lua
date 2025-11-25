--[[
    ╔═══════════════════════════════════════════════════════════╗
    ║  Purple Dump Panel v6.0 - Memory Edition                 ║
    ║  Dump REAL + Trigger Shaka + Memória Persistente         ║
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

-- Sistema de Memória Persistente
local Memory = {
    Events = {},
    Blocked = {},
    KeyLogs = {},
    ScriptCache = {},
    HookedObjects = {},
    LastTab = "Dump",
    Settings = {}
}

-- Carregar memória salva
local function LoadMemory()
    if readfile and isfile and isfile("purple_memory.json") then
        local success, data = pcall(function()
            return HttpService:JSONDecode(readfile("purple_memory.json"))
        end)
        if success then
            Memory = data
            print("💾 Memória carregada!")
        end
    end
end

-- Salvar memória
local function SaveMemory()
    if writefile then
        local success = pcall(function()
            writefile("purple_memory.json", HttpService:JSONEncode(Memory))
        end)
        if success then
            print("💾 Memória salva!")
        end
    end
end

-- Carregar memória ao iniciar
LoadMemory()

-- Variáveis globais
local IsUIVisible = false
local IsCapturing = false
local ConnectionsTable = {}

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
TitleLabel.Text = "Purple Dump Panel v6.0"
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
local CurrentTab = Memory.LastTab

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
    Memory.LastTab = tabName
    SaveMemory()
    
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

-- SISTEMA DE CAPTURA DO SHAKA (MELHORADO)
local function FormatArgs(args)
    if not args then return "{}" end
    local t = {}
    for i = 1, math.min(3, #args) do
        local v = args[i]
        if type(v) == "string" then
            table.insert(t, '"' .. tostring(v):sub(1, 15) .. '"')
        elseif type(v) == "number" then
            table.insert(t, tostring(v))
        elseif typeof(v) == "Instance" then
            table.insert(t, v.Name)
        else
            table.insert(t, tostring(v):sub(1, 10))
        end
    end
    if #args > 3 then
        table.insert(t, "...")
    end
    return "{" .. table.concat(t, ", ") .. "}"
end

local function CaptureEvent(remote, eventType, args)
    if not remote or not remote.Parent then return end
    
    local path = remote:GetFullName()
    if Memory.Blocked[path] then return end
    
    local eventData = {
        Name = remote.Name,
        Type = eventType,
        Path = path,
        Remote = remote,
        Arguments = args or {},
        Timestamp = os.time(),
        TimeString = os.date("%H:%M:%S"),
        Loop = false
    }
    
    table.insert(Memory.Events, 1, eventData)
    
    -- Limitar quantidade
    while #Memory.Events > Config.MaxEventLogs do
        table.remove(Memory.Events)
    end
    
    -- Salvar periodicamente
    if #Memory.Events % 10 == 0 then
        SaveMemory()
    end
    
    -- Atualizar UI se visível
    if IsUIVisible and CurrentTab == "Event Logs" then
        UpdateEventsList()
    end
end

-- SISTEMA DE HOOK DO SHAKA (MELHORADO)
local function InstallHooks()
    print("🔧 Instalando hooks...")
    
    -- Método 1: Hook metamethod (mais eficiente)
    if hookmetamethod and getnamecallmethod then
        local success = pcall(function()
            local oldNamecall
            oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
                local method = getnamecallmethod()
                if (method == "FireServer" or method == "InvokeServer") and IsCapturing then
                    task.spawn(function()
                        if typeof(self) == "Instance" then
                            CaptureEvent(
                                self, 
                                method == "FireServer" and "RemoteEvent" or "RemoteFunction", 
                                {...}
                            )
                        end
                    end)
                end
                return oldNamecall(self, ...)
            end)
            print("✅ Hook metamethod instalado!")
        end)
        if not success then
            print("❌ Hook metamethod falhou")
        end
    end
    
    -- Método 2: Hook direto (backup)
    task.spawn(function()
        local function HookDescendants(parent)
            for _, obj in pairs(parent:GetDescendants()) do
                if obj:IsA("RemoteEvent") and not Memory.HookedObjects[obj] then
                    pcall(function()
                        Memory.HookedObjects[obj] = true
                        local oldFire = obj.FireServer
                        obj.FireServer = function(self, ...)
                            if IsCapturing then
                                task.spawn(function() 
                                    CaptureEvent(self, "RemoteEvent", {...}) 
                                end)
                            end
                            return oldFire(self, ...)
                        end
                    end)
                elseif obj:IsA("RemoteFunction") and not Memory.HookedObjects[obj] then
                    pcall(function()
                        Memory.HookedObjects[obj] = true
                        local oldInvoke = obj.InvokeServer
                        obj.InvokeServer = function(self, ...)
                            if IsCapturing then
                                task.spawn(function() 
                                    CaptureEvent(self, "RemoteFunction", {...}) 
                                end)
                            end
                            return oldInvoke(self, ...)
                        end
                    end)
                end
            end
        end
        
        -- Hookar serviços principais
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
            local connection = service.DescendantAdded:Connect(function(obj)
                if (obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction")) and not Memory.HookedObjects[obj] then
                    pcall(function()
                        if obj:IsA("RemoteEvent") then
                            Memory.HookedObjects[obj] = true
                            local oldFire = obj.FireServer
                            obj.FireServer = function(self, ...)
                                if IsCapturing then
                                    task.spawn(function() 
                                        CaptureEvent(self, "RemoteEvent", {...}) 
                                    end)
                                end
                                return oldFire(self, ...)
                            end
                        else
                            Memory.HookedObjects[obj] = true
                            local oldInvoke = obj.InvokeServer
                            obj.InvokeServer = function(self, ...)
                                if IsCapturing then
                                    task.spawn(function() 
                                        CaptureEvent(self, "RemoteFunction", {...}) 
                                    end)
                                end
                                return oldInvoke(self, ...)
                            end
                        end
                    end)
                end
            end)
            table.insert(ConnectionsTable, connection)
        end
        
        print("✅ Hook direto instalado: " .. #Memory.HookedObjects .. " objetos")
    end)
end

-- FUNÇÕES DE CONTROLE DE EVENTOS
local function ReplayEvent(event, times)
    times = times or 1
    task.spawn(function()
        for i = 1, times do
            pcall(function()
                if event.Remote and event.Remote.Parent then
                    if event.Type == "RemoteEvent" then
                        event.Remote:FireServer(unpack(event.Arguments))
                    else
                        event.Remote:InvokeServer(unpack(event.Arguments))
                    end
                end
            end)
            if i < times then
                task.wait(0.1)
            end
        end
        print("🔁 Replay executado x" .. times)
    end)
end

local function ToggleLoopEvent(event)
    event.Loop = not event.Loop
    
    if event.Loop then
        task.spawn(function()
            while event.Loop and event.Remote and event.Remote.Parent do
                pcall(function()
                    if event.Type == "RemoteEvent" then
                        event.Remote:FireServer(unpack(event.Arguments))
                    else
                        event.Remote:InvokeServer(unpack(event.Arguments))
                    end
                end)
                task.wait(0.3)
            end
            event.Loop = false
        end)
        return true
    else
        return false
    end
end

local function ToggleBlockEvent(path)
    if Memory.Blocked[path] then
        Memory.Blocked[path] = nil
        return false
    else
        Memory.Blocked[path] = true
        return true
    end
end

-- ABA EVENT LOGS COMPLETAMENTE REFEITA
local EventsScrollFrame
local EventsInfoLabel

function UpdateEventsList()
    if not EventsScrollFrame then return end
    
    -- Limpar eventos anteriores
    for _, child in pairs(EventsScrollFrame:GetChildren()) do
        if child:IsA("Frame") then
            child:Destroy()
        end
    end
    
    local blockedCount = 0
    for _ in pairs(Memory.Blocked) do
        blockedCount = blockedCount + 1
    end
    
    if EventsInfoLabel then
        EventsInfoLabel.Text = string.format("📊 Eventos: %d | 🔒 Bloqueados: %d | 💜 Hooked: %d", 
            #Memory.Events, blockedCount, #Memory.HookedObjects)
    end
    
    -- Mostrar últimos eventos
    for i = 1, math.min(20, #Memory.Events) do
        local event = Memory.Events[i]
        if not event then continue end
        
        local EventFrame = Instance.new("Frame")
        EventFrame.Size = UDim2.new(1, -10, 0, 110)
        EventFrame.BackgroundColor3 = Config.Theme.Surface
        EventFrame.BorderSizePixel = 0
        EventFrame.Parent = EventsScrollFrame
        
        local EventCorner = Instance.new("UICorner")
        EventCorner.CornerRadius = UDim.new(0, 8)
        EventCorner.Parent = EventFrame
        
        -- Tipo do evento
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
        
        -- Nome do evento
        local EventName = Instance.new("TextLabel")
        EventName.Size = UDim2.new(1, -240, 0, 25)
        EventName.Position = UDim2.new(0, 135, 0, 8)
        EventName.BackgroundTransparency = 1
        EventName.Text = event.Name
        EventName.TextColor3 = Config.Theme.Text
        EventName.Font = Enum.Font.GothamBold
        EventName.TextSize = 14
        EventName.TextXAlignment = Enum.TextXAlignment.Left
        EventName.TextTruncate = Enum.TextTruncate.AtEnd
        EventName.Parent = EventFrame
        
        -- Caminho
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
        
        -- Tempo e argumentos
        local TimeLabel = Instance.new("TextLabel")
        TimeLabel.Size = UDim2.new(0.5, -10, 0, 20)
        TimeLabel.Position = UDim2.new(0, 8, 0, 55)
        TimeLabel.BackgroundTransparency = 1
        TimeLabel.Text = "⏰ " .. event.TimeString
        TimeLabel.TextColor3 = Config.Theme.TextSecondary
        TimeLabel.Font = Enum.Font.Gotham
        TimeLabel.TextSize = 11
        TimeLabel.TextXAlignment = Enum.TextXAlignment.Left
        TimeLabel.Parent = EventFrame
        
        local ArgsLabel = Instance.new("TextLabel")
        ArgsLabel.Size = UDim2.new(0.5, -10, 0, 20)
        ArgsLabel.Position = UDim2.new(0, 8, 0, 75)
        ArgsLabel.BackgroundTransparency = 1
        ArgsLabel.Text = "📦 " .. FormatArgs(event.Arguments)
        ArgsLabel.TextColor3 = Config.Theme.TextSecondary
        ArgsLabel.Font = Enum.Font.Gotham
        ArgsLabel.TextSize = 11
        ArgsLabel.TextXAlignment = Enum.TextXAlignment.Left
        ArgsLabel.TextTruncate = Enum.TextTruncate.AtEnd
        ArgsLabel.Parent = EventFrame
        
        -- Botões de controle
        local PlayButton = CreateStyledButton("▶️", Config.Theme.Success, EventFrame,
            UDim2.new(1, -185, 0, 8), UDim2.new(0, 40, 0, 25))
        
        local MultiButton = CreateStyledButton("⚡5", Config.Theme.Primary, EventFrame,
            UDim2.new(1, -140, 0, 8), UDim2.new(0, 45, 0, 25))
        
        local LoopButton = CreateStyledButton(
            event.Loop and "⏹️" or "🔁",
            event.Loop and Config.Theme.Error or Config.Theme.Warning,
            EventFrame,
            UDim2.new(1, -90, 0, 8),
            UDim2.new(0, 45, 0, 25)
        )
        
        local BlockButton = CreateStyledButton("🚫", Config.Theme.Error, EventFrame,
            UDim2.new(1, -40, 0, 8), UDim2.new(0, 35, 0, 25))
        
        -- Botões inferiores
        local CopyButton = CreateStyledButton("📋 Copiar", Config.Theme.Warning, EventFrame,
            UDim2.new(1, -185, 0, 38), UDim2.new(0, 180, 0, 25))
        
        -- Conexões dos botões
        PlayButton.MouseButton1Click:Connect(function()
            ReplayEvent(event, 1)
        end)
        
        MultiButton.MouseButton1Click:Connect(function()
            ReplayEvent(event, 5)
        end)
        
        LoopButton.MouseButton1Click:Connect(function()
            local looping = ToggleLoopEvent(event)
            LoopButton.Text = looping and "⏹️" or "🔁"
            LoopButton.BackgroundColor3 = looping and Config.Theme.Error or Config.Theme.Warning
        end)
        
        BlockButton.MouseButton1Click:Connect(function()
            local blocked = ToggleBlockEvent(event.Path)
            if blocked then
                BlockButton.Text = "✅"
                BlockButton.BackgroundColor3 = Config.Theme.Success
            else
                BlockButton.Text = "🚫"
                BlockButton.BackgroundColor3 = Config.Theme.Error
            end
            SaveMemory()
            task.wait(1)
            UpdateEventsList()
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
                event.Name,
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
    EventsInfoLabel.Text = "📊 Eventos: " .. #Memory.Events .. " | 🔒 Bloqueados: 0 | 💜 Hooked: 0"
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
            
            -- Instalar hooks se necessário
            if #Memory.HookedObjects == 0 then
                InstallHooks()
            end
            
        else
            StartButton.Text = "💜 INICIAR CAPTURA"
            StartButton.BackgroundColor3 = Config.Theme.Success
            StatusLabel.Text = "⚫ Captura: OFF"
            StatusLabel.BackgroundColor3 = Config.Theme.Surface
        end
        UpdateEventsList()
    end)
    
    ClearButton.MouseButton1Click:Connect(function()
        Memory.Events = {}
        SaveMemory()
        UpdateEventsList()
    end)
    
    ExportButton.MouseButton1Click:Connect(function()
        local exportData = "-- Purple Dump Panel - Event Logs\n-- Total Events: " .. #Memory.Events .. "\n\n"
        for i, event in ipairs(Memory.Events) do
            exportData = exportData .. string.format(
                "-- [%d] %s (%s)\n-- Path: %s\n-- Time: %s\n-- Args: %s\n\n",
                i,
                event.Name,
                event.Type,
                event.Path,
                event.TimeString,
                FormatArgs(event.Arguments)
            )
        end
        
        setclipboard(exportData)
        ExportButton.Text = "✅ COPIADO!"
        task.wait(2)
        ExportButton.Text = "💾 EXPORTAR"
    end)
    
    UpdateEventsList()
end

-- ABA KEY LOGS (mantida similar)
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
        for i = 1, math.min(150, #Memory.KeyLogs) do
            displayText = displayText .. Memory.KeyLogs[i]
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
        
        table.insert(Memory.KeyLogs, 1, logEntry)
        
        if #Memory.KeyLogs > Config.MaxKeyLogs then
            table.remove(Memory.KeyLogs, #Memory.KeyLogs)
        end
        
        -- Salvar periodicamente
        if #Memory.KeyLogs % 20 == 0 then
            SaveMemory()
        end
        
        UpdateKeyLogsDisplay()
    end)
    
    table.insert(ConnectionsTable, inputBeganConnection)
    
    ClearButton.MouseButton1Click:Connect(function()
        Memory.KeyLogs = {}
        SaveMemory()
        LogBox.Text = "🗑️ Key Logs limpos com sucesso!\nAguardando novos inputs...\n\n"
    end)
    
    ExportButton.MouseButton1Click:Connect(function()
        local exportText = "-- Purple Key Logs\n-- Total Inputs: " .. #Memory.KeyLogs .. "\n\n"
        for i = #Memory.KeyLogs, 1, -1 do
            exportText = exportText .. Memory.KeyLogs[i]
        end
        
        setclipboard(exportText)
        ExportButton.Text = "✅ COPIADO!"
        task.wait(2)
        ExportButton.Text = "💾 EXPORTAR"
    end)
    
    UpdateKeyLogsDisplay()
end

-- ABA EXECUTOR (mantida similar)
function CreateCodeExecutorTab()
    local Container = Instance.new("Frame")
    Container.Size = UDim2.new(1, 0, 1, 0)
    Container.BackgroundTransparency = 1
    Container.Parent = TabContent
    
    local CodeBox = CreateStyledTextBox("-- Purple Executor\n-- Cole seu código Lua aqui\n\nprint('💜 Hello from Purple Panel v6.0!')", 
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

-- ABA SETTINGS (com sistema de memória)
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
            SaveMemory()
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
    InfoText.Text = [[💜 Purple Dump Panel v6.0

• Pressione F para abrir/fechar
• Sistema de memória persistente
• Trigger Shaka 100% funcional
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
        Memory.Events = {}
        Memory.Blocked = {}
        Memory.KeyLogs = {}
        Memory.ScriptCache = {}
        Memory.HookedObjects = {}
        SaveMemory()
        
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
SwitchTab(CurrentTab)

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

ShowNotification("💜 Purple Dump Panel v6.0\n✅ Carregado! Pressione F\n🔧 Memória Persistente Ativa", 5)

print("╔═════════════════════════════════════════╗")
print("║   💜 Purple Dump Panel v6.0             ║")
print("║   ✅ Carregado com sucesso!             ║")
print("║   📌 Pressione F para abrir/fechar      ║")
print("║   🔧 Sistema de memória persistente     ║")
print("║   🎯 Trigger Shaka 100% funcional       ║")
print("╚═════════════════════════════════════════╝")

-- Auto-inicialização do hook se configurado
if Config.AutoHook then
    task.spawn(function()
        task.wait(3)
        InstallHooks()
        print("💜 Auto-hook inicializado: " .. #Memory.HookedObjects .. " objetos hookados")
    end)
end

-- Salvar memória periodicamente
task.spawn(function()
    while true do
        task.wait(30) -- Salvar a cada 30 segundos
        SaveMemory()
    end
end)

-- Limpeza ao sair
game:GetService("Players").PlayerRemoving:Connect(function(player)
    if player == LocalPlayer then
        SaveMemory() -- Salvar antes de sair
        for _, connection in pairs(ConnectionsTable) do
            pcall(function() connection:Disconnect() end)
        end
        pcall(function() ScreenGui:Destroy() end)
    end
end)
