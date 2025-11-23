-- SHAKA LOGGER v3.0 - Delta Executor Edition
print("[SHAKA] Iniciando...")
wait(2)

-- Verificar ambiente básico
if not game then
    print("[SHAKA] ERRO: game não encontrado")
    return
end

if not Players then
    Players = game:GetService("Players")
end

-- Tabela principal
getgenv().ShakaLogger = getgenv().ShakaLogger or {}
local Logger = getgenv().ShakaLogger

-- Inicializar propriedades
Logger.Events = Logger.Events or {}
Logger.Logs = Logger.Logs or {}
Logger.Blocked = Logger.Blocked or {}
Logger.Stats = Logger.Stats or {Captured = 0, Blocked = 0, Replayed = 0}
Logger.IsOpen = false
Logger.CurrentTab = "Dashboard"
Logger.UI = Logger.UI or {}

-- Configurações
local OPEN_KEY = Enum.KeyCode.F
local MAX_EVENTS = 50

-- Cores
local C = {
    BG = Color3.fromRGB(15, 15, 20),
    Card = Color3.fromRGB(25, 25, 35),
    Primary = Color3.fromRGB(99, 102, 241),
    Success = Color3.fromRGB(34, 197, 94),
    Danger = Color3.fromRGB(239, 68, 68),
    Warning = Color3.fromRGB(251, 146, 60),
    Text = Color3.fromRGB(248, 250, 252),
    TextDim = Color3.fromRGB(148, 163, 184),
}

-- Services seguros
local Services = {}
local function GetService(name)
    if not Services[name] then
        local s, r = pcall(function()
            return game:GetService(name)
        end)
        Services[name] = s and r or nil
    end
    return Services[name]
end

local Players = GetService("Players")
local RunService = GetService("RunService")
local UserInputService = GetService("UserInputService")
local TweenService = GetService("TweenService")

-- Funções auxiliares
local function Log(msg)
    pcall(function()
        print("[SHAKA]", msg)
        table.insert(Logger.Logs, 1, {
            Time = os.date("%H:%M:%S"),
            Message = tostring(msg)
        })
        while #Logger.Logs > 50 do
            table.remove(Logger.Logs)
        end
    end)
end

local function FormatArgs(args)
    if not args then return "{}" end
    local t = {}
    for i = 1, math.min(3, #args) do
        pcall(function()
            local arg = args[i]
            if type(arg) == "string" then
                table.insert(t, '"' .. tostring(arg):sub(1, 15) .. '"')
            elseif type(arg) == "number" then
                table.insert(t, tostring(arg))
            elseif typeof(arg) == "Instance" then
                table.insert(t, arg.Name or "?")
            else
                table.insert(t, tostring(arg):sub(1, 10))
            end
        end)
    end
    return "{" .. table.concat(t, ", ") .. "}"
end

-- Sistema de captura
function Logger:CaptureEvent(remote, eventType, args)
    pcall(function()
        if not remote or not remote.Parent then return end
        
        local path = remote:GetFullName()
        if self.Blocked[path] then return end
        
        local event = {
            Name = remote.Name,
            Type = eventType,
            Path = path,
            Remote = remote,
            Args = args or {},
            Time = os.date("%H:%M:%S"),
            IsLooping = false
        }
        
        table.insert(self.Events, 1, event)
        while #self.Events > MAX_EVENTS do
            table.remove(self.Events)
        end
        
        self.Stats.Captured = #self.Events
        
        if self.IsOpen and self.CurrentTab == "Events" then
            task.spawn(function() self:RefreshContent() end)
        end
    end)
end

-- Hook
function Logger:InstallHook()
    Log("Instalando hook...")
    
    local hooked = false
    
    -- Método 1
    if hookmetamethod and getnamecallmethod then
        pcall(function()
            local old
            old = hookmetamethod(game, "__namecall", function(self, ...)
                local method = getnamecallmethod()
                local args = {...}
                
                if method == "FireServer" or method == "InvokeServer" then
                    task.spawn(function()
                        pcall(function()
                            if typeof(self) == "Instance" then
                                Logger:CaptureEvent(self, method == "FireServer" and "RemoteEvent" or "RemoteFunction", args)
                            end
                        end)
                    end)
                end
                
                return old(self, ...)
            end)
            hooked = true
            Log("Hook instalado!")
        end)
    end
    
    -- Método 2
    task.spawn(function()
        for _, obj in ipairs(game:GetDescendants()) do
            pcall(function()
                if obj:IsA("RemoteEvent") then
                    local old = obj.FireServer
                    obj.FireServer = function(self, ...)
                        task.spawn(function()
                            Logger:CaptureEvent(self, "RemoteEvent", {...})
                        end)
                        return old(self, ...)
                    end
                elseif obj:IsA("RemoteFunction") then
                    local old = obj.InvokeServer
                    obj.InvokeServer = function(self, ...)
                        task.spawn(function()
                            Logger:CaptureEvent(self, "RemoteFunction", {...})
                        end)
                        return old(self, ...)
                    end
                end
            end)
        end
    end)
    
    return hooked
end

-- Replay
function Logger:Replay(event, times)
    times = times or 1
    task.spawn(function()
        for i = 1, times do
            pcall(function()
                if event.Type == "RemoteEvent" then
                    event.Remote:FireServer(unpack(event.Args))
                else
                    event.Remote:InvokeServer(unpack(event.Args))
                end
            end)
            if i < times then wait(0.2) end
        end
        self.Stats.Replayed = self.Stats.Replayed + times
        Log("Replay x" .. times)
    end)
end

-- Loop
function Logger:ToggleLoop(event)
    event.IsLooping = not event.IsLooping
    
    if event.IsLooping then
        Log("Loop ON: " .. event.Name)
        task.spawn(function()
            while event.IsLooping do
                pcall(function()
                    if event.Remote and event.Remote.Parent then
                        event.Remote:FireServer(unpack(event.Args))
                    else
                        event.IsLooping = false
                    end
                end)
                wait(0.5)
            end
        end)
    else
        Log("Loop OFF")
    end
    
    return event.IsLooping
end

-- Block
function Logger:ToggleBlock(path)
    if self.Blocked[path] then
        self.Blocked[path] = nil
        self.Stats.Blocked = self.Stats.Blocked - 1
        Log("Desbloqueado")
    else
        self.Blocked[path] = true
        self.Stats.Blocked = self.Stats.Blocked + 1
        Log("Bloqueado")
    end
end

-- Executor
function Logger:Execute(code)
    if not code or code == "" then
        Log("Código vazio!")
        return
    end
    
    Log("Executando...")
    task.spawn(function()
        local s, e = pcall(function()
            local f, err = loadstring(code)
            if f then
                f()
                Log("Sucesso!")
            else
                Log("Erro: " .. tostring(err))
            end
        end)
        if not s then
            Log("Erro: " .. tostring(e))
        end
    end)
end

-- UI
function Logger:CreateUI()
    Log("Criando UI...")
    
    local gui = Instance.new("ScreenGui")
    gui.Name = "ShakaLogger"
    gui.ResetOnSpawn = false
    
    -- Tentar CoreGui
    local placed = pcall(function()
        local CoreGui = GetService("CoreGui")
        if CoreGui then
            gui.Parent = CoreGui
        end
    end)
    
    -- Fallback PlayerGui
    if not placed or not gui.Parent then
        pcall(function()
            local player = Players.LocalPlayer
            if player then
                gui.Parent = player:WaitForChild("PlayerGui", 5)
            end
        end)
    end
    
    if not gui.Parent then
        Log("ERRO: Não foi possível criar UI")
        return false
    end
    
    -- Frame principal
    local main = Instance.new("Frame")
    main.Name = "Main"
    main.Size = UDim2.new(0, 800, 0, 550)
    main.Position = UDim2.new(0.5, -400, 0.5, -275)
    main.BackgroundColor3 = C.BG
    main.BorderSizePixel = 0
    main.Visible = false
    main.Parent = gui
    
    self.UI.Main = main
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 12)
    corner.Parent = main
    
    -- Header
    local header = Instance.new("Frame")
    header.Size = UDim2.new(1, 0, 0, 50)
    header.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
    header.BorderSizePixel = 0
    header.Parent = main
    
    local hcorner = Instance.new("UICorner")
    hcorner.CornerRadius = UDim.new(0, 12)
    hcorner.Parent = header
    
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, -100, 1, 0)
    title.Position = UDim2.new(0, 15, 0, 0)
    title.BackgroundTransparency = 1
    title.Text = "⚡ SHAKA LOGGER v3.0"
    title.TextColor3 = C.Text
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Font = Enum.Font.GothamBold
    title.TextSize = 18
    title.Parent = header
    
    -- Botão fechar
    local close = Instance.new("TextButton")
    close.Size = UDim2.new(0, 40, 0, 40)
    close.Position = UDim2.new(1, -45, 0, 5)
    close.BackgroundColor3 = C.Danger
    close.Text = "X"
    close.TextColor3 = C.Text
    close.Font = Enum.Font.GothamBold
    close.TextSize = 16
    close.BorderSizePixel = 0
    close.Parent = header
    
    local ccorner = Instance.new("UICorner")
    ccorner.CornerRadius = UDim.new(0, 8)
    ccorner.Parent = close
    
    close.MouseButton1Click:Connect(function()
        self:Toggle()
    end)
    
    -- Tabs
    local tabBar = Instance.new("Frame")
    tabBar.Size = UDim2.new(1, -20, 0, 40)
    tabBar.Position = UDim2.new(0, 10, 0, 55)
    tabBar.BackgroundTransparency = 1
    tabBar.Parent = main
    
    local tabLayout = Instance.new("UIListLayout")
    tabLayout.FillDirection = Enum.FillDirection.Horizontal
    tabLayout.Padding = UDim.new(0, 8)
    tabLayout.Parent = tabBar
    
    self.UI.TabButtons = {}
    local tabs = {"Dashboard", "Events", "Executor", "Logs"}
    
    for _, name in ipairs(tabs) do
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(0, 180, 1, 0)
        btn.BackgroundColor3 = C.Card
        btn.Text = name
        btn.TextColor3 = C.TextDim
        btn.Font = Enum.Font.GothamBold
        btn.TextSize = 13
        btn.BorderSizePixel = 0
        btn.Parent = tabBar
        
        local bcorner = Instance.new("UICorner")
        bcorner.CornerRadius = UDim.new(0, 8)
        bcorner.Parent = btn
        
        btn.MouseButton1Click:Connect(function()
            self:SwitchTab(name)
        end)
        
        self.UI.TabButtons[name] = btn
    end
    
    -- Content
    local content = Instance.new("Frame")
    content.Size = UDim2.new(1, -20, 1, -105)
    content.Position = UDim2.new(0, 10, 0, 100)
    content.BackgroundTransparency = 1
    content.Parent = main
    
    self.UI.ContentFrames = {}
    
    for _, name in ipairs(tabs) do
        local frame = Instance.new("ScrollingFrame")
        frame.Name = name
        frame.Size = UDim2.new(1, 0, 1, 0)
        frame.BackgroundTransparency = 1
        frame.ScrollBarThickness = 6
        frame.ScrollBarImageColor3 = C.Primary
        frame.Visible = false
        frame.CanvasSize = UDim2.new(0, 0, 0, 0)
        frame.AutomaticCanvasSize = Enum.AutomaticSize.Y
        frame.BorderSizePixel = 0
        frame.Parent = content
        
        local layout = Instance.new("UIListLayout")
        layout.Padding = UDim.new(0, 10)
        layout.Parent = frame
        
        self.UI.ContentFrames[name] = frame
    end
    
    Log("UI criada!")
    return true
end

function Logger:SwitchTab(name)
    self.CurrentTab = name
    
    for n, btn in pairs(self.UI.TabButtons) do
        btn.BackgroundColor3 = (n == name) and C.Primary or C.Card
        btn.TextColor3 = (n == name) and C.Text or C.TextDim
    end
    
    for n, frame in pairs(self.UI.ContentFrames) do
        frame.Visible = (n == name)
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
        elseif self.CurrentTab == "Logs" then
            self:BuildLogs(frame)
        end
    end)
end

function Logger:BuildDashboard(parent)
    local card = Instance.new("Frame")
    card.Size = UDim2.new(1, 0, 0, 120)
    card.BackgroundColor3 = C.Card
    card.BorderSizePixel = 0
    card.Parent = parent
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 10)
    corner.Parent = card
    
    local text = Instance.new("TextLabel")
    text.Size = UDim2.new(1, -20, 1, -20)
    text.Position = UDim2.new(0, 10, 0, 10)
    text.BackgroundTransparency = 1
    text.Text = string.format([[
📊 ESTATÍSTICAS

Eventos: %d
Bloqueados: %d
Replays: %d
    ]], self.Stats.Captured, self.Stats.Blocked, self.Stats.Replayed)
    text.TextColor3 = C.Text
    text.TextXAlignment = Enum.TextXAlignment.Left
    text.TextYAlignment = Enum.TextYAlignment.Top
    text.Font = Enum.Font.Gotham
    text.TextSize = 14
    text.Parent = card
    
    -- Botão limpar
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, -20, 0, 40)
    btn.Position = UDim2.new(0, 10, 0, 0)
    btn.BackgroundColor3 = C.Danger
    btn.Text = "🗑️ Limpar Eventos"
    btn.TextColor3 = C.Text
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 13
    btn.BorderSizePixel = 0
    btn.Parent = parent
    
    local bcorner = Instance.new("UICorner")
    bcorner.CornerRadius = UDim.new(0, 8)
    bcorner.Parent = btn
    
    btn.MouseButton1Click:Connect(function()
        self.Events = {}
        self.Stats.Captured = 0
        Log("Eventos limpos")
        self:RefreshContent()
    end)
end

function Logger:BuildEvents(parent)
    if #self.Events == 0 then
        local empty = Instance.new("TextLabel")
        empty.Size = UDim2.new(1, 0, 0, 80)
        empty.BackgroundColor3 = C.Card
        empty.Text = "Nenhum evento capturado\nInteraja com o jogo..."
        empty.TextColor3 = C.TextDim
        empty.Font = Enum.Font.Gotham
        empty.TextSize = 13
        empty.BorderSizePixel = 0
        empty.Parent = parent
        
        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 10)
        corner.Parent = empty
        return
    end
    
    for i, event in ipairs(self.Events) do
        if i > 10 then break end
        
        local card = Instance.new("Frame")
        card.Size = UDim2.new(1, 0, 0, 100)
        card.BackgroundColor3 = C.Card
        card.BorderSizePixel = 0
        card.Parent = parent
        
        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 10)
        corner.Parent = card
        
        local name = Instance.new("TextLabel")
        name.Size = UDim2.new(1, -200, 0, 20)
        name.Position = UDim2.new(0, 10, 0, 10)
        name.BackgroundTransparency = 1
        name.Text = "📡 " .. event.Name
        name.TextColor3 = C.Primary
        name.TextXAlignment = Enum.TextXAlignment.Left
        name.Font = Enum.Font.GothamBold
        name.TextSize = 13
        name.Parent = card
        
        local path = Instance.new("TextLabel")
        path.Size = UDim2.new(1, -200, 0, 15)
        path.Position = UDim2.new(0, 10, 0, 32)
        path.BackgroundTransparency = 1
        path.Text = event.Path
        path.TextColor3 = C.TextDim
        path.TextXAlignment = Enum.TextXAlignment.Left
        path.Font = Enum.Font.Code
        path.TextSize = 9
        path.TextTruncate = Enum.TextTruncate.AtEnd
        path.Parent = card
        
        local args = Instance.new("TextLabel")
        args.Size = UDim2.new(1, -200, 0, 15)
        args.Position = UDim2.new(0, 10, 0, 49)
        args.BackgroundTransparency = 1
        args.Text = FormatArgs(event.Args)
        args.TextColor3 = C.Warning
        args.TextXAlignment = Enum.TextXAlignment.Left
        args.Font = Enum.Font.Code
        args.TextSize = 9
        args.TextTruncate = Enum.TextTruncate.AtEnd
        args.Parent = card
        
        -- Botões
        local btn1 = Instance.new("TextButton")
        btn1.Size = UDim2.new(0, 50, 0, 25)
        btn1.Position = UDim2.new(0, 10, 0, 68)
        btn1.BackgroundColor3 = C.Success
        btn1.Text = "▶️"
        btn1.TextColor3 = C.Text
        btn1.Font = Enum.Font.GothamBold
        btn1.TextSize = 12
        btn1.BorderSizePixel = 0
        btn1.Parent = card
        
        local c1 = Instance.new("UICorner")
        c1.CornerRadius = UDim.new(0, 6)
        c1.Parent = btn1
        
        btn1.MouseButton1Click:Connect(function()
            self:Replay(event, 1)
        end)
        
        local btn2 = Instance.new("TextButton")
        btn2.Size = UDim2.new(0, 55, 0, 25)
        btn2.Position = UDim2.new(0, 65, 0, 68)
        btn2.BackgroundColor3 = C.Primary
        btn2.Text = "⚡5x"
        btn2.TextColor3 = C.Text
        btn2.Font = Enum.Font.GothamBold
        btn2.TextSize = 11
        btn2.BorderSizePixel = 0
        btn2.Parent = card
        
        local c2 = Instance.new("UICorner")
        c2.CornerRadius = UDim.new(0, 6)
        c2.Parent = btn2
        
        btn2.MouseButton1Click:Connect(function()
            self:Replay(event, 5)
        end)
        
        local btn3 = Instance.new("TextButton")
        btn3.Size = UDim2.new(0, 55, 0, 25)
        btn3.Position = UDim2.new(0, 125, 0, 68)
        btn3.BackgroundColor3 = event.IsLooping and C.Danger or C.Warning
        btn3.Text = event.IsLooping and "⏹️" or "🔁"
        btn3.TextColor3 = C.Text
        btn3.Font = Enum.Font.GothamBold
        btn3.TextSize = 11
        btn3.BorderSizePixel = 0
        btn3.Parent = card
        
        local c3 = Instance.new("UICorner")
        c3.CornerRadius = UDim.new(0, 6)
        c3.Parent = btn3
        
        btn3.MouseButton1Click:Connect(function()
            local loop = self:ToggleLoop(event)
            btn3.Text = loop and "⏹️" or "🔁"
            btn3.BackgroundColor3 = loop and C.Danger or C.Warning
        end)
        
        local btn4 = Instance.new("TextButton")
        btn4.Size = UDim2.new(0, 55, 0, 25)
        btn4.Position = UDim2.new(0, 185, 0, 68)
        btn4.BackgroundColor3 = C.Danger
        btn4.Text = "🚫"
        btn4.TextColor3 = C.Text
        btn4.Font = Enum.Font.GothamBold
        btn4.TextSize = 11
        btn4.BorderSizePixel = 0
        btn4.Parent = card
        
        local c4 = Instance.new("UICorner")
        c4.CornerRadius = UDim.new(0, 6)
        c4.Parent = btn4
        
        btn4.MouseButton1Click:Connect(function()
            self:ToggleBlock(event.Path)
            wait(0.1)
            self:RefreshContent()
        end)
    end
end

function Logger:BuildExecutor(parent)
    local card = Instance.new("Frame")
    card.Size = UDim2.new(1, 0, 0, 350)
    card.BackgroundColor3 = C.Card
    card.BorderSizePixel = 0
    card.Parent = parent
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 10)
    corner.Parent = card
    
    local codeBox = Instance.new("TextBox")
    codeBox.Size = UDim2.new(1, -20, 0, 250)
    codeBox.Position = UDim2.new(0, 10, 0, 10)
    codeBox.BackgroundColor3 = Color3.fromRGB(20, 20, 28)
    codeBox.Text = ""
    codeBox.PlaceholderText = "-- Cole seu código aqui\nprint('Hello!')"
    codeBox.TextColor3 = C.Text
    codeBox.TextXAlignment = Enum.TextXAlignment.Left
    codeBox.TextYAlignment = Enum.TextYAlignment.Top
    codeBox.Font = Enum.Font.Code
    codeBox.TextSize = 12
    codeBox.MultiLine = true
    codeBox.ClearTextOnFocus = false
    codeBox.BorderSizePixel = 0
    codeBox.Parent = card
    
    local boxCorner = Instance.new("UICorner")
    boxCorner.CornerRadius = UDim.new(0, 8)
    boxCorner.Parent = codeBox
    
    local btnExec = Instance.new("TextButton")
    btnExec.Size = UDim2.new(0, 300, 0, 40)
    btnExec.Position = UDim2.new(0, 10, 0, 270)
    btnExec.BackgroundColor3 = C.Success
    btnExec.Text = "▶️ EXECUTAR"
    btnExec.TextColor3 = C.Text
    btnExec.Font = Enum.Font.GothamBold
    btnExec.TextSize = 14
    btnExec.BorderSizePixel = 0
    btnExec.Parent = card
    
    local execCorner = Instance.new("UICorner")
    execCorner.CornerRadius = UDim.new(0, 8)
    execCorner.Parent = btnExec
    
    btnExec.MouseButton1Click:Connect(function()
        self:Execute(codeBox.Text)
    end)
    
    local btnClear = Instance.new("TextButton")
    btnClear.Size = UDim2.new(0, 150, 0, 40)
    btnClear.Position = UDim2.new(0, 320, 0, 270)
    btnClear.BackgroundColor3 = C.Warning
    btnClear.Text = "🗑️ LIMPAR"
    btnClear.TextColor3 = C.Text
    btnClear.Font = Enum.Font.GothamBold
    btnClear.TextSize = 13
    btnClear.BorderSizePixel = 0
    btnClear.Parent = card
    
    local clearCorner = Instance.new("UICorner")
    clearCorner.CornerRadius = UDim.new(0, 8)
    clearCorner.Parent = btnClear
    
    btnClear.MouseButton1Click:Connect(function()
        codeBox.Text = ""
        Log("Código limpo")
    end)
end

function Logger:BuildLogs(parent)
    if #self.Logs == 0 then
        local empty = Instance.new("TextLabel")
        empty.Size = UDim2.new(1, 0, 0, 60)
        empty.BackgroundColor3 = C.Card
        empty.Text = "Nenhum log"
        empty.TextColor3 = C.TextDim
        empty.Font = Enum.Font.Gotham
        empty.TextSize = 13
        empty.BorderSizePixel = 0
        empty.Parent = parent
        
        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 10)
        corner.Parent = empty
        return
    end
    
    for i, log in ipairs(self.Logs) do
        if i > 15 then break end
        
        local card = Instance.new("Frame")
        card.Size = UDim2.new(1, 0, 0, 35)
        card.BackgroundColor3 = C.Card
        card.BorderSizePixel = 0
        card.Parent = parent
        
        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 6)
        corner.Parent = card
        
        local time = Instance.new("TextLabel")
        time.Size = UDim2.new(0, 60, 1, 0)
        time.Position = UDim2.new(0, 10, 0, 0)
        time.BackgroundTransparency = 1
        time.Text = log.Time
        time.TextColor3 = C.TextDim
        time.Font = Enum.Font.Code
        time.TextSize = 10
        time.Parent = card
        
        local msg = Instance.new("TextLabel")
        msg.Size = UDim2.new(1, -80, 1, 0)
        msg.Position = UDim2.new(0, 75, 0, 0)
        msg.BackgroundTransparency = 1
        msg.Text = log.Message
        msg.TextColor3 = C.Text
        msg.TextXAlignment = Enum.TextXAlignment.Left
        msg.Font = Enum.Font.Gotham
        msg.TextSize = 11
        msg.TextTruncate = Enum.TextTruncate.AtEnd
        msg.Parent = card
    end
end

function Logger:Toggle()
    self.IsOpen = not self.IsOpen
    
    if not self.UI.Main then return end
    
    if self.IsOpen then
        self.UI.Main.Visible = true
        self.UI.Main.Size = UDim2.new(0, 0, 0, 0)
        
        if TweenService then
            TweenService:Create(self.UI.Main, 
                TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
                {Size = UDim2.new(0, 800, 0, 550)}):Play()
        else
            self.UI.Main.Size = UDim2.new(0, 800, 0, 550)
        end
        
        wait(0.2)
        self:RefreshContent()
    else
        if TweenService then
            TweenService:Create(self.UI.Main, 
                TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.In),
                {Size = UDim2.new(0, 0, 0, 0)}):Play()
            wait(0.2)
        end
        self.UI.Main.Visible = false
    end
end

function Logger:SetupKeybind()
    if not UserInputService then return end
    
    UserInputService.InputBegan:Connect(function(input, processed)
        if not processed and input.KeyCode == OPEN_KEY then
            pcall(function()
                self:Toggle()
            end)
        end
    end)
end

function Logger:Init()
    Log("Iniciando SHAKA LOGGER...")
    
    -- Verificar features
    Log("Verificando executor...")
    
    local features = {
        hookmetamethod = hookmetamethod ~= nil,
        getnamecallmethod = getnamecallmethod ~= nil,
        loadstring = loadstring ~= nil,
        setclipboard = setclipboard ~= nil
    }
    
    for name, has in pairs(features) do
        Log((has and "✅" or "❌") .. " " .. name)
    end
    
    -- Criar UI
    wait(0.3)
    local uiOk = self:CreateUI()
    
    if not uiOk then
        Log("ERRO: Falha ao criar UI")
        return false
    end
    
    -- Setup keybind
    wait(0.2)
    self:SetupKeybind()
    Log("Keybind configurado [F]")
    
    -- Hook
    wait(0.3)
    self:InstallHook()
    
    Log("✅ SHAKA LOGGER PRONTO!")
    Log("Pressione [F] para abrir")
    
    -- Abrir automaticamente
    wait(1)
    self:Toggle()
    wait(0.2)
    self:SwitchTab("Dashboard")
    
    return true
end

-- Executar inicialização
Log("Aguardando 2 segundos...")
wait(2)

local success, err = pcall(function()
    Logger:Init()
end)

if not success then
    Log("ERRO na inicialização:")
    Log(tostring(err))
    print("[SHAKA] ERRO:", err)
end

-- Exportar globalmente
_G.ShakaLogger = Logger
shared.ShakaLogger = Logger

Log("SHAKA Logger carregado na variável global!")
print("[SHAKA] ✅ Carregado! Use _G.ShakaLogger")

return Logger
