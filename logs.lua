-- SHAKA LOGGER v3.0 ULTIMATE EDITION
-- Otimizado para Delta Executor
-- Sistema completo de análise e exploração

wait(1) -- Aguardar carregamento inicial

-- Tabela principal
local Logger = {
    Events = {},
    Logs = {},
    Blocked = {},
    Capture = {Remote = true, Character = false, Input = false, All = true},
    Stats = {Captured = 0, Blocked = 0, Replayed = 0, Dumped = 0},
    IsOpen = false,
    CurrentTab = "Dashboard",
    UI = {},
    HookActive = false,
    ExecutorCode = "",
    ExecutorHistory = {},
    DumpData = {},
    Filters = {RemoteEvent = true, RemoteFunction = true, BindableEvent = true}
}

-- Constantes
local VERSION = "3.0 ULTIMATE"
local MAX_EVENTS = 100
local MAX_LOGS = 100
local OPEN_KEY = Enum.KeyCode.F

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")

local CoreGui = nil
pcall(function()
    CoreGui = game:GetService("CoreGui")
end)

-- Cores modernas
local Colors = {
    BG = Color3.fromRGB(15, 15, 20),
    Card = Color3.fromRGB(25, 25, 35),
    Primary = Color3.fromRGB(99, 102, 241),
    Secondary = Color3.fromRGB(139, 92, 246),
    Success = Color3.fromRGB(34, 197, 94),
    Danger = Color3.fromRGB(239, 68, 68),
    Warning = Color3.fromRGB(251, 146, 60),
    Info = Color3.fromRGB(59, 130, 246),
    Text = Color3.fromRGB(248, 250, 252),
    TextDim = Color3.fromRGB(148, 163, 184),
    TextMuted = Color3.fromRGB(100, 116, 139),
    Border = Color3.fromRGB(51, 65, 85),
}

-- Cache
local OriginalFunctions = {}
local MonitoredRemotes = {}

-- Funções utilitárias
local function SafePrint(...)
    pcall(function()
        print("[SHAKA]", ...)
    end)
end

local function FormatArgs(args)
    if not args or type(args) ~= "table" then return "{}" end
    
    local formatted = {}
    for i = 1, math.min(5, #args) do
        local arg = args[i]
        pcall(function()
            if type(arg) == "string" then
                table.insert(formatted, '"' .. tostring(arg):sub(1, 20) .. '"')
            elseif type(arg) == "number" then
                table.insert(formatted, tostring(math.floor(arg * 100) / 100))
            elseif typeof(arg) == "Instance" then
                table.insert(formatted, arg.Name or "Instance")
            elseif typeof(arg) == "Vector3" then
                table.insert(formatted, string.format("V3(%.0f,%.0f,%.0f)", arg.X, arg.Y, arg.Z))
            else
                table.insert(formatted, tostring(arg):sub(1, 10))
            end
        end)
    end
    
    if #args > 5 then table.insert(formatted, "...") end
    return "{" .. table.concat(formatted, ", ") .. "}"
end

-- Sistema de Logs
function Logger:AddLog(category, message, level)
    local log = {
        Time = os.date("%H:%M:%S"),
        Category = category,
        Message = tostring(message),
        Level = level or "info"
    }
    
    table.insert(self.Logs, 1, log)
    while #self.Logs > MAX_LOGS do
        table.remove(self.Logs)
    end
    
    SafePrint(string.format("[%s] %s", category, message))
end

-- Sistema de Captura
function Logger:CaptureEvent(remote, eventType, args)
    if not self.Capture.Remote and not self.Capture.All then return end
    if not remote or not remote.Parent then return end
    
    local path = ""
    pcall(function()
        path = remote:GetFullName()
    end)
    
    if path == "" or self.Blocked[path] then return end
    
    local event = {
        Name = remote.Name,
        Type = eventType,
        Path = path,
        Remote = remote,
        Args = args,
        Time = os.date("%H:%M:%S"),
        IsLooping = false,
        CallCount = 1
    }
    
    -- Verificar duplicata
    local found = false
    for i, e in ipairs(self.Events) do
        if e.Path == path then
            e.CallCount = e.CallCount + 1
            e.Time = os.date("%H:%M:%S")
            found = true
            break
        end
    end
    
    if not found then
        table.insert(self.Events, 1, event)
        while #self.Events > MAX_EVENTS do
            table.remove(self.Events)
        end
    end
    
    self.Stats.Captured = #self.Events
    
    if self.IsOpen and self.CurrentTab == "Events" then
        task.spawn(function() self:RefreshContent() end)
    end
end

-- Hook System
function Logger:InstallHook()
    local success = false
    
    -- Método 1: Hookmetamethod
    if hookmetamethod and getnamecallmethod and newcclosure then
        pcall(function()
            local old
            old = hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
                local method = getnamecallmethod()
                local args = {...}
                
                if method == "FireServer" or method == "InvokeServer" then
                    if Logger.Capture.Remote or Logger.Capture.All then
                        task.spawn(function()
                            pcall(function()
                                if typeof(self) == "Instance" then
                                    local type = method == "FireServer" and "RemoteEvent" or "RemoteFunction"
                                    Logger:CaptureEvent(self, type, args)
                                end
                            end)
                        end)
                    end
                end
                
                return old(self, ...)
            end))
            success = true
        end)
    end
    
    -- Método 2: Monitor direto
    task.spawn(function()
        local function MonitorRemote(remote)
            if MonitoredRemotes[remote] then return end
            MonitoredRemotes[remote] = true
            
            pcall(function()
                if remote:IsA("RemoteEvent") then
                    local oldFire = remote.FireServer
                    remote.FireServer = function(self, ...)
                        local args = {...}
                        if Logger.Capture.Remote or Logger.Capture.All then
                            task.spawn(function()
                                Logger:CaptureEvent(self, "RemoteEvent", args)
                            end)
                        end
                        return oldFire(self, ...)
                    end
                elseif remote:IsA("RemoteFunction") then
                    local oldInvoke = remote.InvokeServer
                    remote.InvokeServer = function(self, ...)
                        local args = {...}
                        if Logger.Capture.Remote or Logger.Capture.All then
                            task.spawn(function()
                                Logger:CaptureEvent(self, "RemoteFunction", args)
                            end)
                        end
                        return oldInvoke(self, ...)
                    end
                end
            end)
        end
        
        for _, obj in ipairs(game:GetDescendants()) do
            if obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction") then
                MonitorRemote(obj)
            end
        end
        
        game.DescendantAdded:Connect(function(obj)
            if obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction") then
                wait(0.1)
                MonitorRemote(obj)
            end
        end)
    end)
    
    self.HookActive = true
    self:AddLog("System", "✅ Sistema de captura ativo!", "success")
    return true
end

-- Executor
function Logger:ExecuteCode(code)
    if not code or code == "" then
        self:AddLog("Executor", "❌ Código vazio!", "error")
        return
    end
    
    self:AddLog("Executor", "▶️ Executando...", "info")
    
    task.spawn(function()
        local success, err = pcall(function()
            local func, loadErr = loadstring(code)
            if not func then
                Logger:AddLog("Executor", "❌ Erro: " .. tostring(loadErr), "error")
                return
            end
            func()
            Logger:AddLog("Executor", "✅ Executado com sucesso!", "success")
        end)
        
        if not success then
            Logger:AddLog("Executor", "❌ Erro: " .. tostring(err), "error")
        end
    end)
end

-- Replay
function Logger:ReplayEvent(event, times)
    if not event or not event.Remote or not event.Remote.Parent then
        self:AddLog("System", "❌ Evento inválido", "error")
        return
    end
    
    times = times or 1
    
    task.spawn(function()
        for i = 1, times do
            pcall(function()
                if event.Type == "RemoteEvent" then
                    event.Remote:FireServer(unpack(event.Args))
                elseif event.Type == "RemoteFunction" then
                    event.Remote:InvokeServer(unpack(event.Args))
                end
            end)
            if i < times then wait(0.2) end
        end
        
        self.Stats.Replayed = self.Stats.Replayed + times
        self:AddLog("System", string.format("✅ Replay: %dx", times), "success")
    end)
end

-- Loop
function Logger:ToggleLoop(event)
    if not event or not event.Remote then return false end
    
    event.IsLooping = not event.IsLooping
    
    if event.IsLooping then
        self:AddLog("System", "🔁 Loop: " .. event.Name, "info")
        
        task.spawn(function()
            while event.IsLooping do
                pcall(function()
                    if not event.Remote or not event.Remote.Parent then
                        event.IsLooping = false
                        return
                    end
                    
                    if event.Type == "RemoteEvent" then
                        event.Remote:FireServer(unpack(event.Args))
                    end
                end)
                wait(0.5)
            end
        end)
    else
        self:AddLog("System", "⏹️ Loop parado", "info")
    end
    
    return event.IsLooping
end

-- Block
function Logger:ToggleBlock(path)
    if self.Blocked[path] then
        self.Blocked[path] = nil
        self.Stats.Blocked = self.Stats.Blocked - 1
        self:AddLog("System", "✅ Desbloqueado", "success")
    else
        self.Blocked[path] = true
        self.Stats.Blocked = self.Stats.Blocked + 1
        self:AddLog("System", "🚫 Bloqueado", "warning")
    end
end

-- Dumper
function Logger:DumpGame()
    self:AddLog("Dumper", "🔍 Iniciando dump...", "info")
    
    task.spawn(function()
        self.DumpData = {}
        local count = 0
        
        -- Dump remotes
        for _, obj in ipairs(game:GetDescendants()) do
            pcall(function()
                if obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction") then
                    if not self.DumpData.Remotes then
                        self.DumpData.Remotes = {}
                    end
                    table.insert(self.DumpData.Remotes, {
                        Name = obj.Name,
                        Type = obj.ClassName,
                        Path = obj:GetFullName()
                    })
                    count = count + 1
                end
            end)
        end
        
        self.Stats.Dumped = count
        self:AddLog("Dumper", string.format("✅ %d remotes encontrados!", count), "success")
        
        if self.IsOpen and self.CurrentTab == "Dumper" then
            self:RefreshContent()
        end
    end)
end

function Logger:ExportDump()
    if not self.DumpData or not next(self.DumpData) then
        self:AddLog("Dumper", "❌ Nenhum dado!", "error")
        return
    end
    
    local success, json = pcall(function()
        return HttpService:JSONEncode(self.DumpData)
    end)
    
    if success and setclipboard then
        setclipboard(json)
        self:AddLog("Dumper", "📋 Copiado!", "success")
    elseif success and writefile then
        writefile("shaka_dump.json", json)
        self:AddLog("Dumper", "💾 Salvo!", "success")
    else
        self:AddLog("Dumper", "❌ Erro ao exportar", "error")
    end
end

-- UI Components
function Logger:CreateButton(parent, text, color, size, position)
    local btn = Instance.new("TextButton")
    btn.Size = size
    btn.Position = position
    btn.BackgroundColor3 = color
    btn.Text = text
    btn.TextColor3 = Colors.Text
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 12
    btn.BorderSizePixel = 0
    btn.ZIndex = 10
    btn.Parent = parent
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = btn
    
    return btn
end

function Logger:CreateCard(parent, title, height)
    local card = Instance.new("Frame")
    card.Size = UDim2.new(1, 0, 0, height)
    card.BackgroundColor3 = Colors.Card
    card.BorderSizePixel = 0
    card.ZIndex = 3
    card.Parent = parent
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 12)
    corner.Parent = card
    
    if title then
        local header = Instance.new("TextLabel")
        header.Size = UDim2.new(1, -20, 0, 40)
        header.Position = UDim2.new(0, 10, 0, 5)
        header.BackgroundTransparency = 1
        header.Text = title
        header.TextColor3 = Colors.Primary
        header.TextXAlignment = Enum.TextXAlignment.Left
        header.Font = Enum.Font.GothamBold
        header.TextSize = 14
        header.ZIndex = 4
        header.Parent = card
    end
    
    return card
end

-- UI Principal
function Logger:CreateUI()
    local gui = Instance.new("ScreenGui")
    gui.Name = "ShakaLogger"
    gui.ResetOnSpawn = false
    
    if CoreGui then
        pcall(function() gui.Parent = CoreGui end)
    end
    
    if not gui.Parent then
        gui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")
    end
    
    -- Main Frame
    local main = Instance.new("Frame")
    main.Name = "Main"
    main.Size = UDim2.new(0, 900, 0, 600)
    main.Position = UDim2.new(0.5, -450, 0.5, -300)
    main.BackgroundColor3 = Colors.BG
    main.BorderSizePixel = 0
    main.Visible = false
    main.ZIndex = 1
    main.Parent = gui
    
    self.UI.Main = main
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 16)
    corner.Parent = main
    
    -- Header
    local header = Instance.new("Frame")
    header.Size = UDim2.new(1, 0, 0, 60)
    header.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
    header.BorderSizePixel = 0
    header.ZIndex = 2
    header.Parent = main
    
    local headerCorner = Instance.new("UICorner")
    headerCorner.CornerRadius = UDim.new(0, 16)
    headerCorner.Parent = header
    
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(0, 400, 1, 0)
    title.Position = UDim2.new(0, 20, 0, 0)
    title.BackgroundTransparency = 1
    title.Text = "⚡ SHAKA LOGGER v" .. VERSION
    title.TextColor3 = Colors.Text
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Font = Enum.Font.GothamBold
    title.TextSize = 20
    title.ZIndex = 3
    title.Parent = header
    
    -- Botão Fechar
    local close = self:CreateButton(header, "✖", Colors.Danger, 
        UDim2.new(0, 40, 0, 40), UDim2.new(1, -50, 0, 10))
    close.MouseButton1Click:Connect(function()
        self:Toggle()
    end)
    
    -- Tabs
    local tabBar = Instance.new("Frame")
    tabBar.Size = UDim2.new(1, -20, 0, 50)
    tabBar.Position = UDim2.new(0, 10, 0, 70)
    tabBar.BackgroundTransparency = 1
    tabBar.ZIndex = 2
    tabBar.Parent = main
    
    local tabLayout = Instance.new("UIListLayout")
    tabLayout.FillDirection = Enum.FillDirection.Horizontal
    tabLayout.Padding = UDim.new(0, 10)
    tabLayout.Parent = tabBar
    
    self.UI.TabButtons = {}
    local tabs = {"Dashboard", "Events", "Executor", "Dumper", "Logs", "Settings"}
    
    for _, tabName in ipairs(tabs) do
        local btn = self:CreateButton(tabBar, tabName, Colors.Card,
            UDim2.new(0, 130, 1, 0), UDim2.new(0, 0, 0, 0))
        
        btn.MouseButton1Click:Connect(function()
            self:SwitchTab(tabName)
        end)
        
        self.UI.TabButtons[tabName] = btn
    end
    
    -- Content Area
    local content = Instance.new("Frame")
    content.Size = UDim2.new(1, -20, 1, -140)
    content.Position = UDim2.new(0, 10, 0, 130)
    content.BackgroundTransparency = 1
    content.ZIndex = 2
    content.Parent = main
    
    self.UI.ContentFrames = {}
    
    for _, tabName in ipairs(tabs) do
        local frame = Instance.new("ScrollingFrame")
        frame.Name = tabName
        frame.Size = UDim2.new(1, 0, 1, 0)
        frame.BackgroundTransparency = 1
        frame.ScrollBarThickness = 6
        frame.ScrollBarImageColor3 = Colors.Primary
        frame.Visible = false
        frame.CanvasSize = UDim2.new(0, 0, 0, 0)
        frame.AutomaticCanvasSize = Enum.AutomaticSize.Y
        frame.ZIndex = 3
        frame.Parent = content
        
        local layout = Instance.new("UIListLayout")
        layout.Padding = UDim.new(0, 15)
        layout.Parent = frame
        
        self.UI.ContentFrames[tabName] = frame
    end
    
    self:AddLog("System", "✅ UI criada!", "success")
end

function Logger:SwitchTab(tabName)
    self.CurrentTab = tabName
    
    for name, btn in pairs(self.UI.TabButtons) do
        if name == tabName then
            btn.BackgroundColor3 = Colors.Primary
        else
            btn.BackgroundColor3 = Colors.Card
        end
    end
    
    for name, frame in pairs(self.UI.ContentFrames) do
        frame.Visible = (name == tabName)
    end
    
    self:RefreshContent()
end

function Logger:RefreshContent()
    pcall(function()
        local frame = self.UI.ContentFrames[self.CurrentTab]
        if not frame then return end
        
        for _, child in ipairs(frame:GetChildren()) do
            if not child:IsA("UIListLayout") then
                child:Destroy()
            end
        end
        
        if self.CurrentTab == "Dashboard" then
            self:BuildDashboard(frame)
        elseif self.CurrentTab == "Events" then
            self:BuildEvents(frame)
        elseif self.CurrentTab == "Executor" then
            self:BuildExecutor(frame)
        elseif self.CurrentTab == "Dumper" then
            self:BuildDumper(frame)
        elseif self.CurrentTab == "Logs" then
            self:BuildLogs(frame)
        elseif self.CurrentTab == "Settings" then
            self:BuildSettings(frame)
        end
    end)
end

-- Build Dashboard
function Logger:BuildDashboard(parent)
    local stats = self:CreateCard(parent, "📊 ESTATÍSTICAS", 150)
    
    local text = Instance.new("TextLabel")
    text.Size = UDim2.new(1, -20, 1, -50)
    text.Position = UDim2.new(0, 10, 0, 50)
    text.BackgroundTransparency = 1
    text.Text = string.format([[
Eventos Capturados: %d
Bloqueados: %d
Replays: %d
Dumps: %d
Status: %s
    ]], self.Stats.Captured, self.Stats.Blocked, self.Stats.Replayed,
        self.Stats.Dumped, self.HookActive and "✅ ATIVO" or "❌ INATIVO")
    text.TextColor3 = Colors.Text
    text.TextXAlignment = Enum.TextXAlignment.Left
    text.TextYAlignment = Enum.TextYAlignment.Top
    text.Font = Enum.Font.Gotham
    text.TextSize = 14
    text.ZIndex = 4
    text.Parent = stats
    
    -- Ações rápidas
    local actions = self:CreateCard(parent, "⚡ AÇÕES RÁPIDAS", 200)
    
    local btn1 = self:CreateButton(actions, "🗑️ Limpar Eventos", Colors.Danger,
        UDim2.new(1, -20, 0, 40), UDim2.new(0, 10, 0, 50))
    btn1.MouseButton1Click:Connect(function()
        self.Events = {}
        self.Stats.Captured = 0
        self:AddLog("System", "🗑️ Limpos", "success")
        self:RefreshContent()
    end)
    
    local btn2 = self:CreateButton(actions, "📦 Iniciar Dump", Colors.Warning,
        UDim2.new(1, -20, 0, 40), UDim2.new(0, 10, 0, 100))
    btn2.MouseButton1Click:Connect(function()
        self:DumpGame()
    end)
    
    local btn3 = self:CreateButton(actions, "✅ Desbloquear Tudo", Colors.Success,
        UDim2.new(1, -20, 0, 40), UDim2.new(0, 10, 0, 150))
    btn3.MouseButton1Click:Connect(function()
        self.Blocked = {}
        self.Stats.Blocked = 0
        self:AddLog("System", "✅ Desbloqueados", "success")
        self:RefreshContent()
    end)
end

-- Build Events
function Logger:BuildEvents(parent)
    if #self.Events == 0 then
        local empty = self:CreateCard(parent, "⚠️ SEM EVENTOS", 100)
        
        local msg = Instance.new("TextLabel")
        msg.Size = UDim2.new(1, -20, 1, -50)
        msg.Position = UDim2.new(0, 10, 0, 50)
        msg.BackgroundTransparency = 1
        msg.Text = "Interaja com o jogo para capturar eventos..."
        msg.TextColor3 = Colors.TextDim
        msg.Font = Enum.Font.Gotham
        msg.TextSize = 13
        msg.ZIndex = 4
        msg.Parent = empty
        return
    end
    
    for i, event in ipairs(self.Events) do
        if i > 15 then break end
        self:CreateEventCard(parent, event)
    end
end

function Logger:CreateEventCard(parent, event)
    local card = self:CreateCard(parent, nil, 120)
    
    local name = Instance.new("TextLabel")
    name.Size = UDim2.new(1, -250, 0, 25)
    name.Position = UDim2.new(0, 10, 0, 10)
    name.BackgroundTransparency = 1
    name.Text = "📡 " .. event.Name .. " (x" .. event.CallCount .. ")"
    name.TextColor3 = Colors.Primary
    name.TextXAlignment = Enum.TextXAlignment.Left
    name.Font = Enum.Font.GothamBold
    name.TextSize = 13
    name.ZIndex = 4
    name.Parent = card
    
    local path = Instance.new("TextLabel")
    path.Size = UDim2.new(1, -20, 0, 15)
    path.Position = UDim2.new(0, 10, 0, 35)
    path.BackgroundTransparency = 1
    path.Text = event.Path
    path.TextColor3 = Colors.TextDim
    path.TextXAlignment = Enum.TextXAlignment.Left
    path.Font = Enum.Font.Code
    path.TextSize = 10
    path.TextTruncate = Enum.TextTruncate.AtEnd
    path.ZIndex = 4
    path.Parent = card
    
    local args = Instance.new("TextLabel")
    args.Size = UDim2.new(1, -20, 0, 15)
    args.Position = UDim2.new(0, 10, 0, 52)
    args.BackgroundTransparency = 1
    args.Text = FormatArgs(event.Args)
    args.TextColor3 = Colors.Warning
    args.TextXAlignment = Enum.TextXAlignment.Left
    args.Font = Enum.Font.Code
    args.TextSize = 10
    args.TextTruncate = Enum.TextTruncate.AtEnd
    args.ZIndex = 4
    args.Parent = card
    
    -- Botões
    local btn1 = self:CreateButton(card, "▶️", Colors.Success,
        UDim2.new(0, 50, 0, 30), UDim2.new(0, 10, 0, 75))
    btn1.MouseButton1Click:Connect(function()
        self:ReplayEvent(event, 1)
    end)
    
    local btn5 = self:CreateButton(card, "⚡5x", Colors.Primary,
        UDim2.new(0, 55, 0, 30), UDim2.new(0, 65, 0, 75))
    btn5.MouseButton1Click:Connect(function()
        self:ReplayEvent(event, 5)
    end)
    
    local btnLoop = self:CreateButton(card, event.IsLooping and "⏹️" or "🔁", 
        event.IsLooping and Colors.Danger or Colors.Info,
        UDim2.new(0, 55, 0, 30), UDim2.new(0, 125, 0, 75))
    btnLoop.MouseButton1Click:Connect(function()
        local loop = self:ToggleLoop(event)
        btnLoop.Text = loop and "⏹️" or "🔁"
        btnLoop.BackgroundColor3 = loop and Colors.Danger or Colors.Info
    end)
    
    local btnBlock = self:CreateButton(card, "🚫", Colors.Danger,
        UDim2.new(0, 55, 0, 30), UDim2.new(0, 185, 0, 75))
    btnBlock.MouseButton1Click:Connect(function()
        self:ToggleBlock(event.Path)
        wait(0.1)
        self:RefreshContent()
    end)
end

-- Build Executor
function Logger:BuildExecutor(parent)
    local editor = self:CreateCard(parent, "💻 EXECUTOR LUA", 400)
    
    local codeBox = Instance.new("TextBox")
    codeBox.Size = UDim2.new(1, -20, 0, 280)
    codeBox.Position = UDim2.new(0, 10, 0, 50)
    codeBox.BackgroundColor3 = Color3.fromRGB(20, 20, 28)
    codeBox.Text = self.ExecutorCode
    codeBox.PlaceholderText = "-- Cole seu código Lua aqui\nprint('Hello!')"
    codeBox.TextColor3 = Colors.Text
    codeBox.TextXAlignment = Enum.TextXAlignment.Left
    codeBox.TextYAlignment = Enum.TextYAlignment.Top
    codeBox.Font = Enum.Font.Code
    codeBox.TextSize = 12
    codeBox.MultiLine = true
    codeBox.ClearTextOnFocus = false
    codeBox.TextWrapped = true
    codeBox.ZIndex = 4
    codeBox.Parent = editor
    
    local boxCorner = Instance.new("UICorner")
    boxCorner.CornerRadius = UDim.new(0, 8)
    boxCorner.Parent = codeBox
    
    codeBox:GetPropertyChangedSignal("Text"):Connect(function()
        self.ExecutorCode = codeBox.Text
    end)
    
    local btnExec = self:CreateButton(editor, "▶️ EXECUTAR", Colors.Success,
        UDim2.new(0, 250, 0, 45), UDim2.new(0, 10, 0, 340))
    btnExec.MouseButton1Click:Connect(function()
        self:ExecuteCode(self.ExecutorCode)
    end)
    
    local btnClear = self:CreateButton(editor, "🗑️ LIMPAR", Colors.Warning,
        UDim2.new(0, 150, 0, 45), UDim2.new(0, 270, 0, 340))
    btnClear.MouseButton1Click:Connect(function()
        self.ExecutorCode = ""
        codeBox.Text = ""
        self:AddLog("Executor", "🗑️ Limpo", "info")
    end)
    
    -- Scripts de exemplo
    local examples = self:CreateCard(parent, "📚 EXEMPLOS", 250)
    
    local exList = {
        {name = "🎯 Teleporte", code = [[local hrp = game.Players.LocalPlayer.Character.HumanoidRootPart
hrp.CFrame = CFrame.new(0, 50, 0)
print("Teleportado!")]]},
        {name = "🏃 Speed", code = [[local hum = game.Players.LocalPlayer.Character.Humanoid
hum.WalkSpeed = 100
print("Speed 100!")]]},
        {name = "🦘 Jump", code = [[local hum = game.Players.LocalPlayer.Character.Humanoid
hum.JumpPower = 150
print("Jump 150!")]]},
        {name = "✨ NoClip", code = [[local char = game.Players.LocalPlayer.Character
game:GetService("RunService").Stepped:Connect(function()
    for _, part in pairs(char:GetDescendants()) do
        if part:IsA("BasePart") then
            part.CanCollide = false
        end
    end
end)
print("NoClip ON!")]]},
    }
    
    local yPos = 50
    for _, ex in ipairs(exList) do
        local btn = self:CreateButton(examples, ex.name, Colors.Info,
            UDim2.new(1, -20, 0, 40), UDim2.new(0, 10, 0, yPos))
        btn.MouseButton1Click:Connect(function()
            self.ExecutorCode = ex.code
            self:AddLog("Executor", "📥 " .. ex.name, "success")
            self:RefreshContent()
        end)
        yPos = yPos + 50
    end
end

-- Build Dumper
function Logger:BuildDumper(parent)
    local controls = self:CreateCard(parent, "📦 DUMPER", 180)
    
    local btnStart = self:CreateButton(controls, "🔍 INICIAR DUMP", Colors.Success,
        UDim2.new(1, -20, 0, 50), UDim2.new(0, 10, 0, 50))
    btnStart.MouseButton1Click:Connect(function()
        self:DumpGame()
    end)
    
    local btnExport = self:CreateButton(controls, "💾 EXPORTAR", Colors.Info,
        UDim2.new(1, -20, 0, 50), UDim2.new(0, 10, 0, 110))
    btnExport.MouseButton1Click:Connect(function()
        self:ExportDump()
    end)
    
    -- Resultados
    if self.DumpData and self.DumpData.Remotes then
        local results = self:CreateCard(parent, "📊 RESULTADOS", 300)
        
        local text = Instance.new("TextLabel")
        text.Size = UDim2.new(1, -20, 1, -50)
        text.Position = UDim2.new(0, 10, 0, 50)
        text.BackgroundTransparency = 1
        text.Text = string.format("Total de Remotes: %d\n\nDados prontos para exportar!", #self.DumpData.Remotes)
        text.TextColor3 = Colors.Text
        text.TextXAlignment = Enum.TextXAlignment.Left
        text.TextYAlignment = Enum.TextYAlignment.Top
        text.Font = Enum.Font.Gotham
        text.TextSize = 13
        text.TextWrapped = true
        text.ZIndex = 4
        text.Parent = results
    else
        local info = self:CreateCard(parent, "ℹ️ INFO", 150)
        
        local text = Instance.new("TextLabel")
        text.Size = UDim2.new(1, -20, 1, -50)
        text.Position = UDim2.new(0, 10, 0, 50)
        text.BackgroundTransparency = 1
        text.Text = "O Dumper extrai todos os RemoteEvents e RemoteFunctions do jogo.\n\nClique em INICIAR DUMP para começar!"
        text.TextColor3 = Colors.TextDim
        text.TextXAlignment = Enum.TextXAlignment.Left
        text.TextYAlignment = Enum.TextYAlignment.Top
        text.Font = Enum.Font.Gotham
        text.TextSize = 12
        text.TextWrapped = true
        text.ZIndex = 4
        text.Parent = info
    end
end

-- Build Logs
function Logger:BuildLogs(parent)
    if #self.Logs == 0 then
        local empty = self:CreateCard(parent, "📭 SEM LOGS", 100)
        
        local msg = Instance.new("TextLabel")
        msg.Size = UDim2.new(1, -20, 1, -50)
        msg.Position = UDim2.new(0, 10, 0, 50)
        msg.BackgroundTransparency = 1
        msg.Text = "Nenhum log registrado"
        msg.TextColor3 = Colors.TextDim
        msg.Font = Enum.Font.Gotham
        msg.TextSize = 13
        msg.ZIndex = 4
        msg.Parent = empty
        return
    end
    
    for i, log in ipairs(self.Logs) do
        if i > 20 then break end
        
        local card = Instance.new("Frame")
        card.Size = UDim2.new(1, 0, 0, 40)
        card.BackgroundColor3 = Colors.Card
        card.BorderSizePixel = 0
        card.ZIndex = 3
        card.Parent = parent
        
        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 8)
        corner.Parent = card
        
        local time = Instance.new("TextLabel")
        time.Size = UDim2.new(0, 60, 1, 0)
        time.Position = UDim2.new(0, 10, 0, 0)
        time.BackgroundTransparency = 1
        time.Text = log.Time
        time.TextColor3 = Colors.TextDim
        time.Font = Enum.Font.Code
        time.TextSize = 10
        time.ZIndex = 4
        time.Parent = card
        
        local category = Instance.new("TextLabel")
        category.Size = UDim2.new(0, 80, 1, 0)
        category.Position = UDim2.new(0, 75, 0, 0)
        category.BackgroundTransparency = 1
        category.Text = "[" .. log.Category .. "]"
        category.TextColor3 = Colors.Primary
        category.Font = Enum.Font.GothamBold
        category.TextSize = 10
        category.TextXAlignment = Enum.TextXAlignment.Left
        category.ZIndex = 4
        category.Parent = card
        
        local message = Instance.new("TextLabel")
        message.Size = UDim2.new(1, -170, 1, 0)
        message.Position = UDim2.new(0, 160, 0, 0)
        message.BackgroundTransparency = 1
        message.Text = log.Message
        message.TextColor3 = Colors.Text
        message.Font = Enum.Font.Gotham
        message.TextSize = 11
        message.TextXAlignment = Enum.TextXAlignment.Left
        message.TextTruncate = Enum.TextTruncate.AtEnd
        message.ZIndex = 4
        message.Parent = card
    end
end

-- Build Settings
function Logger:BuildSettings(parent)
    local capture = self:CreateCard(parent, "🎯 CAPTURA", 200)
    
    local yPos = 50
    local toggles = {
        {name = "Remote", label = "📡 Remote Events"},
        {name = "Character", label = "🎯 Character"},
        {name = "Input", label = "⌨️ Input"},
        {name = "All", label = "🌐 Capturar Tudo"}
    }
    
    for _, toggle in ipairs(toggles) do
        local frame = Instance.new("Frame")
        frame.Size = UDim2.new(1, -20, 0, 35)
        frame.Position = UDim2.new(0, 10, 0, yPos)
        frame.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
        frame.BorderSizePixel = 0
        frame.ZIndex = 4
        frame.Parent = capture
        
        local frameCorner = Instance.new("UICorner")
        frameCorner.CornerRadius = UDim.new(0, 6)
        frameCorner.Parent = frame
        
        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(1, -90, 1, 0)
        label.Position = UDim2.new(0, 10, 0, 0)
        label.BackgroundTransparency = 1
        label.Text = toggle.label
        label.TextColor3 = Colors.Text
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.Font = Enum.Font.GothamBold
        label.TextSize = 12
        label.ZIndex = 5
        label.Parent = frame
        
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(0, 60, 0, 26)
        btn.Position = UDim2.new(1, -70, 0.5, -13)
        btn.BackgroundColor3 = self.Capture[toggle.name] and Colors.Success or Colors.Danger
        btn.Text = self.Capture[toggle.name] and "ON" or "OFF"
        btn.TextColor3 = Colors.Text
        btn.Font = Enum.Font.GothamBold
        btn.TextSize = 11
        btn.BorderSizePixel = 0
        btn.ZIndex = 5
        btn.Parent = frame
        
        local btnCorner = Instance.new("UICorner")
        btnCorner.CornerRadius = UDim.new(0, 5)
        btnCorner.Parent = btn
        
        btn.MouseButton1Click:Connect(function()
            self.Capture[toggle.name] = not self.Capture[toggle.name]
            btn.BackgroundColor3 = self.Capture[toggle.name] and Colors.Success or Colors.Danger
            btn.Text = self.Capture[toggle.name] and "ON" or "OFF"
            self:AddLog("System", toggle.name .. ": " .. btn.Text, "info")
        end)
        
        yPos = yPos + 40
    end
    
    -- Info
    local info = self:CreateCard(parent, "ℹ️ INFORMAÇÕES", 150)
    
    local infoText = Instance.new("TextLabel")
    infoText.Size = UDim2.new(1, -20, 1, -50)
    infoText.Position = UDim2.new(0, 10, 0, 50)
    infoText.BackgroundTransparency = 1
    infoText.Text = string.format([[
SHAKA LOGGER v%s

Status: %s
Executor: %s
Remotes: %d

Pressione [F] para abrir/fechar
    ]], VERSION,
        self.HookActive and "✅ ATIVO" or "❌ INATIVO",
        loadstring and "✅ OK" or "❌ N/A",
        #self.Events)
    infoText.TextColor3 = Colors.Text
    infoText.TextXAlignment = Enum.TextXAlignment.Left
    infoText.TextYAlignment = Enum.TextYAlignment.Top
    infoText.Font = Enum.Font.Code
    infoText.TextSize = 11
    infoText.ZIndex = 4
    infoText.Parent = info
end

-- Toggle UI
function Logger:Toggle()
    self.IsOpen = not self.IsOpen
    
    if not self.UI.Main then return end
    
    if self.IsOpen then
        self.UI.Main.Visible = true
        self.UI.Main.Size = UDim2.new(0, 0, 0, 0)
        
        TweenService:Create(self.UI.Main, 
            TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
            {Size = UDim2.new(0, 900, 0, 600)}):Play()
        
        wait(0.2)
        self:RefreshContent()
    else
        TweenService:Create(self.UI.Main, 
            TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.In),
            {Size = UDim2.new(0, 0, 0, 0)}):Play()
        
        wait(0.2)
        self.UI.Main.Visible = false
    end
end

-- Keybind
function Logger:SetupKeybind()
    UserInputService.InputBegan:Connect(function(input, processed)
        if not processed and input.KeyCode == OPEN_KEY then
            pcall(function()
                self:Toggle()
            end)
        end
    end)
end

-- Inicialização
function Logger:Init()
    SafePrint("\n" .. string.rep("=", 60))
    SafePrint("⚡ SHAKA LOGGER v" .. VERSION)
    SafePrint("   Sistema Ultra Completo")
    SafePrint(string.rep("=", 60))
    
    SafePrint("\n🔍 Verificando executor...")
    
    local features = {
        "hookmetamethod", "getnamecallmethod", "newcclosure",
        "setclipboard", "loadstring", "writefile"
    }
    
    for _, feat in ipairs(features) do
        local has = false
        pcall(function()
            has = _G[feat] ~= nil or getfenv()[feat] ~= nil
        end)
        SafePrint((has and "✅" or "❌") .. " " .. feat)
    end
    
    SafePrint("\n🎨 Criando UI...")
    wait(0.3)
    
    local success = pcall(function()
        self:CreateUI()
    end)
    
    if not success then
        SafePrint("❌ Erro ao criar UI")
        return
    end
    
    SafePrint("⌨️ Configurando controles...")
    wait(0.2)
    pcall(function()
        self:SetupKeybind()
    end)
    
    SafePrint("🔗 Instalando hooks...")
    wait(0.3)
    pcall(function()
        self:InstallHook()
    end)
    
    SafePrint("\n✅ SHAKA LOGGER PRONTO!")
    SafePrint("⌨️ Pressione [F] para abrir")
    SafePrint(string.rep("=", 60) .. "\n")
    
    -- Abrir automaticamente
    wait(1)
    pcall(function()
        self:Toggle()
        wait(0.2)
        self:SwitchTab("Dashboard")
    end)
end

-- Iniciar
wait(1)
SafePrint("🚀 Iniciando SHAKA LOGGER...")

local success, err = pcall(function()
    Logger:Init()
end)

if not success then
    SafePrint("❌ ERRO: " .. tostring(err))
end

-- Exportar
pcall(function()
    getgenv().ShakaLogger = Logger
    _G.ShakaLogger = Logger
    shared.ShakaLogger = Logger
end)

SafePrint("✅ SHAKA LOGGER Carregado!")

return Logger
