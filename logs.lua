-- SHAKA LOGGER v2.0 - VERSÃO OTIMIZADA
-- Sistema de logging e replay de eventos
-- Corrigido: Performance, crashes e overflow

local ShakaLogger = {}

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

-- Configurações
local CONFIG = {
    OpenKey = Enum.KeyCode.F,
    MaxEvents = 30,      -- Reduzido de 50
    MaxLogs = 30,        -- Reduzido de 50
    RefreshCooldown = 0.5,
    LogCooldown = 1,
}

-- Estado
local State = {
    IsOpen = false,
    CurrentTab = "Settings",
    IsRefreshing = false,
    LastRefresh = 0,
    LastLog = {},
    
    -- Captura
    Capture = {
        Remote = false,
        Character = false,
        Input = false,
    },
    
    -- Dados
    Events = {},
    BlockedPaths = {},
    Logs = {},
    
    -- Stats
    Stats = {
        Captured = 0,
        Blocked = 0,
        Replayed = 0,
    }
}

-- UI References
local UI = {
    ScreenGui = nil,
    MainFrame = nil,
    TabButtons = {},
    ContentFrames = {},
}

-- Theme
local Theme = {
    BG = Color3.fromRGB(20, 20, 26),
    Card = Color3.fromRGB(30, 30, 38),
    Purple = Color3.fromRGB(148, 53, 236),
    Text = Color3.fromRGB(255, 255, 255),
    TextDim = Color3.fromRGB(180, 180, 200),
    Success = Color3.fromRGB(46, 204, 113),
    Danger = Color3.fromRGB(231, 76, 60),
    Warning = Color3.fromRGB(255, 165, 0),
}

--═══════════════════════════════════════════════════════════
-- UTILIDADES
--═══════════════════════════════════════════════════════════

local function SafeCall(fn, ...)
    local success, result = pcall(fn, ...)
    if not success then
        warn("[SHAKA] Erro:", result)
    end
    return success, result
end

local function FormatArgs(args)
    if not args or #args == 0 then return "{}" end
    
    local parts = {}
    for i = 1, math.min(3, #args) do
        local arg = args[i]
        local argType = typeof(arg)
        
        if argType == "string" then
            table.insert(parts, '"' .. tostring(arg):sub(1, 15) .. '"')
        elseif argType == "number" then
            table.insert(parts, tostring(arg))
        elseif argType == "Vector3" then
            table.insert(parts, string.format("V3(%.0f,%.0f,%.0f)", arg.X, arg.Y, arg.Z))
        elseif argType == "Instance" then
            table.insert(parts, arg.Name or "Instance")
        else
            table.insert(parts, tostring(arg):sub(1, 10))
        end
    end
    
    if #args > 3 then
        table.insert(parts, "...")
    end
    
    return "{" .. table.concat(parts, ", ") .. "}"
end

local function GetRemotePath(remote)
    return remote:GetFullName()
end

--═══════════════════════════════════════════════════════════
-- SISTEMA DE LOG
--═══════════════════════════════════════════════════════════

function ShakaLogger:AddLog(category, message)
    local now = tick()
    local lastTime = State.LastLog[category] or 0
    
    -- Cooldown para evitar spam
    if now - lastTime < CONFIG.LogCooldown then
        return
    end
    State.LastLog[category] = now
    
    local log = {
        Time = os.date("%H:%M:%S"),
        Category = category,
        Message = message,
        ID = now,
    }
    
    table.insert(State.Logs, 1, log)
    
    -- Limitar logs
    while #State.Logs > CONFIG.MaxLogs do
        table.remove(State.Logs)
    end
    
    print(string.format("[SHAKA] [%s] %s", category, message))
end

function ShakaLogger:IsBlocked(path)
    return State.BlockedPaths[path] == true
end

function ShakaLogger:ToggleBlock(path)
    if State.BlockedPaths[path] then
        State.BlockedPaths[path] = nil
        State.Stats.Blocked = math.max(0, State.Stats.Blocked - 1)
        self:AddLog("System", "✅ Desbloqueado: " .. path:match("[^.]+$"))
    else
        State.BlockedPaths[path] = true
        State.Stats.Blocked = State.Stats.Blocked + 1
        self:AddLog("System", "🚫 Bloqueado: " .. path:match("[^.]+$"))
    end
end

--═══════════════════════════════════════════════════════════
-- CAPTURA DE EVENTOS
--═══════════════════════════════════════════════════════════

function ShakaLogger:CaptureEvent(remote, eventType, args)
    if not State.Capture.Remote then return end
    
    local path = GetRemotePath(remote)
    
    -- Verificar se está bloqueado
    if self:IsBlocked(path) then
        return
    end
    
    local event = {
        Name = remote.Name,
        Type = eventType,
        Path = path,
        Remote = remote,
        Args = args,
        Time = os.date("%H:%M:%S"),
        Timestamp = tick(),
        IsLooping = false,
    }
    
    table.insert(State.Events, 1, event)
    
    -- Limitar eventos
    while #State.Events > CONFIG.MaxEvents do
        table.remove(State.Events)
    end
    
    State.Stats.Captured = #State.Events
    
    -- Log simplificado
    local argsStr = FormatArgs(args)
    self:AddLog("Remote", string.format("📡 %s %s", remote.Name, argsStr))
end

function ShakaLogger:HookRemotes()
    -- Verificar se o executor suporta hooks
    if not hookmetamethod then
        warn("[SHAKA] ❌ hookmetamethod não disponível!")
        self:AddLog("System", "❌ Executor não suporta hooks")
        return false
    end
    
    if not getnamecallmethod then
        warn("[SHAKA] ❌ getnamecallmethod não disponível!")
        self:AddLog("System", "❌ Executor não suporta getnamecallmethod")
        return false
    end
    
    if not newcclosure then
        warn("[SHAKA] ❌ newcclosure não disponível!")
        self:AddLog("System", "❌ Executor não suporta newcclosure")
        return false
    end
    
    local success, err = pcall(function()
        local oldNamecall
        oldNamecall = hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
            local method = getnamecallmethod()
            local args = {...}
            
            -- Verificar se é um Remote
            if typeof(self) == "Instance" then
                local isFireServer = method == "FireServer"
                local isInvokeServer = method == "InvokeServer"
                
                if isFireServer or isInvokeServer then
                    local path = self:GetFullName()
                    
                    -- Verificar bloqueio
                    if State.BlockedPaths[path] then
                        return isInvokeServer and nil or nil
                    end
                    
                    -- Capturar evento
                    if State.Capture.Remote then
                        local eventType = self:IsA("RemoteEvent") and "RemoteEvent" or "RemoteFunction"
                        
                        -- Usar pcall para evitar crash
                        pcall(function()
                            ShakaLogger:CaptureEvent(self, eventType, args)
                        end)
                    end
                end
            end
            
            return oldNamecall(self, ...)
        end))
    end)
    
    if success then
        self:AddLog("System", "✅ Hook instalado!")
        print("[SHAKA] ✅ Hook de remotes ativo")
        return true
    else
        warn("[SHAKA] ❌ Erro ao instalar hook:", err)
        self:AddLog("System", "❌ Erro no hook: " .. tostring(err))
        return false
    end
end

--═══════════════════════════════════════════════════════════
-- REPLAY DE EVENTOS
--═══════════════════════════════════════════════════════════

function ShakaLogger:ReplayEvent(event, times)
    times = times or 1
    
    if not event.Remote or not event.Remote.Parent then
        self:AddLog("System", "❌ Remote inválido: " .. event.Name)
        return 0
    end
    
    local successCount = 0
    
    task.spawn(function()
        for i = 1, times do
            local success = SafeCall(function()
                if event.Type == "RemoteEvent" then
                    event.Remote:FireServer(unpack(event.Args))
                else
                    event.Remote:InvokeServer(unpack(event.Args))
                end
            end)
            
            if success then
                successCount = successCount + 1
            end
            
            if times > 1 then
                task.wait(0.1)
            end
        end
        
        State.Stats.Replayed = State.Stats.Replayed + successCount
        self:AddLog("System", string.format("✅ Replay: %s x%d (%d sucesso)", 
            event.Name, times, successCount))
    end)
    
    return successCount
end

function ShakaLogger:ToggleLoop(event)
    if event.IsLooping then
        event.IsLooping = false
        self:AddLog("System", "⏹️ Loop parado: " .. event.Name)
        return false
    end
    
    if not event.Remote or not event.Remote.Parent then
        self:AddLog("System", "❌ Remote inválido!")
        return false
    end
    
    event.IsLooping = true
    self:AddLog("System", "🔁 Loop iniciado: " .. event.Name)
    
    task.spawn(function()
        while event.IsLooping do
            if not event.Remote or not event.Remote.Parent then
                event.IsLooping = false
                break
            end
            
            SafeCall(function()
                if event.Type == "RemoteEvent" then
                    event.Remote:FireServer(unpack(event.Args))
                else
                    event.Remote:InvokeServer(unpack(event.Args))
                end
            end)
            
            task.wait(0.5)
        end
    end)
    
    return true
end

--═══════════════════════════════════════════════════════════
-- MONITORAMENTO
--═══════════════════════════════════════════════════════════

function ShakaLogger:StartMonitors()
    -- Character Monitor
    local lastPos = nil
    local lastHealth = nil
    local lastCheck = 0
    
    RunService.Heartbeat:Connect(function()
        if not State.Capture.Character then return end
        
        local now = tick()
        if now - lastCheck < 2 then return end
        lastCheck = now
        
        SafeCall(function()
            local player = Players.LocalPlayer
            if not player or not player.Character then return end
            
            local root = player.Character:FindFirstChild("HumanoidRootPart")
            local humanoid = player.Character:FindFirstChild("Humanoid")
            
            if root then
                local pos = root.Position
                if lastPos and (pos - lastPos).Magnitude > 100 then
                    self:AddLog("Character", string.format("🎯 Movimento: %.0f studs", (pos - lastPos).Magnitude))
                end
                lastPos = pos
            end
            
            if humanoid then
                local hp = humanoid.Health
                if lastHealth and math.abs(hp - lastHealth) > 20 then
                    self:AddLog("Character", string.format("❤️ Saúde: %.0f → %.0f", lastHealth, hp))
                end
                lastHealth = hp
            end
        end)
    end)
    
    -- Input Monitor
    local lastInput = {}
    
    UserInputService.InputBegan:Connect(function(input, processed)
        if not State.Capture.Input or processed then return end
        
        local inputName = tostring(input.KeyCode.Name or input.UserInputType.Name)
        local now = tick()
        
        if lastInput[inputName] and (now - lastInput[inputName]) < 2 then
            return
        end
        lastInput[inputName] = now
        
        if input.UserInputType == Enum.UserInputType.Keyboard then
            self:AddLog("Input", "⌨️ " .. input.KeyCode.Name)
        end
    end)
    
    self:AddLog("System", "✅ Monitores ativos")
end

--═══════════════════════════════════════════════════════════
-- INTERFACE
--═══════════════════════════════════════════════════════════

function ShakaLogger:CreateUI()
    SafeCall(function()
        if game:GetService("CoreGui"):FindFirstChild("ShakaLoggerV2") then
            game:GetService("CoreGui").ShakaLoggerV2:Destroy()
        end
    end)
    
    local gui = Instance.new("ScreenGui")
    gui.Name = "ShakaLoggerV2"
    gui.ResetOnSpawn = false
    
    SafeCall(function()
        gui.Parent = game:GetService("CoreGui")
    end)
    
    if not gui.Parent then
        gui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")
    end
    
    UI.ScreenGui = gui
    
    -- Main Frame
    local main = Instance.new("Frame")
    main.Name = "Main"
    main.Size = UDim2.new(0, 800, 0, 550)
    main.Position = UDim2.new(0.5, -400, 0.5, -275)
    main.BackgroundColor3 = Theme.BG
    main.BorderSizePixel = 0
    main.Visible = false
    main.Parent = gui
    
    UI.MainFrame = main
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 12)
    corner.Parent = main
    
    local stroke = Instance.new("UIStroke")
    stroke.Color = Theme.Purple
    stroke.Thickness = 2
    stroke.Transparency = 0.3
    stroke.Parent = main
    
    -- Header
    self:CreateHeader(main)
    
    -- Tabs
    self:CreateTabs(main)
    
    -- Content
    self:CreateContent(main)
    
    self:AddLog("System", "✅ UI criada")
end

function ShakaLogger:CreateHeader(parent)
    local header = Instance.new("Frame")
    header.Size = UDim2.new(1, 0, 0, 50)
    header.BackgroundTransparency = 1
    header.Parent = parent
    
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(0, 300, 0, 24)
    title.Position = UDim2.new(0, 15, 0, 8)
    title.BackgroundTransparency = 1
    title.Text = "⚡ SHAKA LOGGER v2.0"
    title.TextColor3 = Theme.Purple
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Font = Enum.Font.GothamBold
    title.TextSize = 18
    title.Parent = header
    
    local subtitle = Instance.new("TextLabel")
    subtitle.Size = UDim2.new(0, 300, 0, 14)
    subtitle.Position = UDim2.new(0, 15, 0, 32)
    subtitle.BackgroundTransparency = 1
    subtitle.Text = "Otimizado • Anti-Crash"
    subtitle.TextColor3 = Theme.TextDim
    subtitle.TextXAlignment = Enum.TextXAlignment.Left
    subtitle.Font = Enum.Font.Gotham
    subtitle.TextSize = 11
    subtitle.Parent = header
    
    local closeBtn = Instance.new("TextButton")
    closeBtn.Size = UDim2.new(0, 80, 0, 30)
    closeBtn.Position = UDim2.new(1, -90, 0, 10)
    closeBtn.BackgroundColor3 = Theme.Danger
    closeBtn.Text = "✖ [F]"
    closeBtn.TextColor3 = Theme.Text
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.TextSize = 12
    closeBtn.BorderSizePixel = 0
    closeBtn.Parent = header
    
    local btnCorner = Instance.new("UICorner")
    btnCorner.CornerRadius = UDim.new(0, 6)
    btnCorner.Parent = closeBtn
    
    closeBtn.MouseButton1Click:Connect(function()
        self:Toggle()
    end)
end

function ShakaLogger:CreateTabs(parent)
    local tabBar = Instance.new("Frame")
    tabBar.Size = UDim2.new(1, -30, 0, 40)
    tabBar.Position = UDim2.new(0, 15, 0, 55)
    tabBar.BackgroundTransparency = 1
    tabBar.Parent = parent
    
    local layout = Instance.new("UIListLayout")
    layout.FillDirection = Enum.FillDirection.Horizontal
    layout.Padding = UDim.new(0, 8)
    layout.Parent = tabBar
    
    local tabs = {
        {Name = "Settings", Icon = "⚙️"},
        {Name = "Events", Icon = "📡"},
        {Name = "Logs", Icon = "📝"}
    }
    
    for _, tab in ipairs(tabs) do
        local btn = Instance.new("TextButton")
        btn.Name = tab.Name
        btn.Size = UDim2.new(0, 240, 1, 0)
        btn.BackgroundColor3 = Theme.Card
        btn.Text = tab.Icon .. " " .. tab.Name
        btn.TextColor3 = Theme.TextDim
        btn.Font = Enum.Font.GothamBold
        btn.TextSize = 13
        btn.BorderSizePixel = 0
        btn.Parent = tabBar
        
        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 8)
        corner.Parent = btn
        
        btn.MouseButton1Click:Connect(function()
            self:SwitchTab(tab.Name)
        end)
        
        UI.TabButtons[tab.Name] = btn
    end
end

function ShakaLogger:CreateContent(parent)
    local content = Instance.new("Frame")
    content.Size = UDim2.new(1, -30, 1, -110)
    content.Position = UDim2.new(0, 15, 0, 100)
    content.BackgroundTransparency = 1
    content.Parent = parent
    
    for name, _ in pairs(UI.TabButtons) do
        local frame = Instance.new("ScrollingFrame")
        frame.Name = name
        frame.Size = UDim2.new(1, 0, 1, 0)
        frame.BackgroundTransparency = 1
        frame.BorderSizePixel = 0
        frame.ScrollBarThickness = 8
        frame.ScrollBarImageColor3 = Theme.Purple
        frame.Visible = false
        frame.CanvasSize = UDim2.new(0, 0, 0, 0)
        frame.AutomaticCanvasSize = Enum.AutomaticSize.Y
        frame.Parent = content
        
        local layout = Instance.new("UIListLayout")
        layout.Padding = UDim.new(0, 10)
        layout.SortOrder = Enum.SortOrder.LayoutOrder
        layout.Parent = frame
        
        UI.ContentFrames[name] = frame
    end
end

function ShakaLogger:SwitchTab(tabName)
    if State.IsRefreshing then return end
    
    State.CurrentTab = tabName
    
    for name, btn in pairs(UI.TabButtons) do
        if name == tabName then
            btn.BackgroundColor3 = Theme.Purple
            btn.TextColor3 = Theme.Text
        else
            btn.BackgroundColor3 = Theme.Card
            btn.TextColor3 = Theme.TextDim
        end
    end
    
    for name, frame in pairs(UI.ContentFrames) do
        frame.Visible = (name == tabName)
    end
    
    self:RefreshTab()
end

function ShakaLogger:RefreshTab()
    local now = tick()
    if State.IsRefreshing or now - State.LastRefresh < CONFIG.RefreshCooldown then
        return
    end
    
    State.IsRefreshing = true
    State.LastRefresh = now
    
    task.spawn(function()
        SafeCall(function()
            local frame = UI.ContentFrames[State.CurrentTab]
            if not frame then return end
            
            for _, child in ipairs(frame:GetChildren()) do
                if not child:IsA("UIListLayout") then
                    child:Destroy()
                end
            end
            
            if State.CurrentTab == "Settings" then
                self:BuildSettings(frame)
            elseif State.CurrentTab == "Events" then
                self:BuildEvents(frame)
            elseif State.CurrentTab == "Logs" then
                self:BuildLogs(frame)
            end
        end)
        
        task.wait(0.1)
        State.IsRefreshing = false
    end)
end

--═══════════════════════════════════════════════════════════
-- CONTEÚDO DAS TABS
--═══════════════════════════════════════════════════════════

function ShakaLogger:BuildSettings(parent)
    -- Status
    local statusCard = self:CreateCard(parent, "📊 STATUS", 100)
    
    local statusText = Instance.new("TextLabel")
    statusText.Size = UDim2.new(1, -20, 0, 60)
    statusText.Position = UDim2.new(0, 10, 0, 35)
    statusText.BackgroundTransparency = 1
    statusText.Text = string.format(
        "Eventos: %d • Bloqueados: %d • Replays: %d",
        State.Stats.Captured,
        State.Stats.Blocked,
        State.Stats.Replayed
    )
    statusText.TextColor3 = Theme.Text
    statusText.Font = Enum.Font.GothamBold
    statusText.TextSize = 13
    statusText.TextWrapped = true
    statusText.Parent = statusCard
    
    -- Controles
    local controlCard = self:CreateCard(parent, "🎯 CAPTURA", 180)
    
    local y = 40
    for name, enabled in pairs(State.Capture) do
        self:CreateToggle(controlCard, name, enabled, y)
        y = y + 45
    end
    
    -- Ações
    local actionsCard = self:CreateCard(parent, "🔧 AÇÕES", 110)
    
    local clearBtn = self:CreateButton(actionsCard, "🗑️ Limpar Eventos", Theme.Danger, 10, 40, 350, 32)
    clearBtn.MouseButton1Click:Connect(function()
        State.Events = {}
        State.Stats.Captured = 0
        self:AddLog("System", "🗑️ Eventos limpos")
        self:RefreshTab()
    end)
    
    local unblockBtn = self:CreateButton(actionsCard, "✅ Desbloquear Todos", Theme.Success, 10, 78, 350, 32)
    unblockBtn.MouseButton1Click:Connect(function()
        State.BlockedPaths = {}
        State.Stats.Blocked = 0
        self:AddLog("System", "✅ Todos desbloqueados")
        self:RefreshTab()
    end)
end

function ShakaLogger:BuildEvents(parent)
    if #State.Events == 0 then
        local empty = self:CreateCard(parent, "⚠️ Nenhum Evento", 80)
        
        local msg = Instance.new("TextLabel")
        msg.Size = UDim2.new(1, -20, 0, 40)
        msg.Position = UDim2.new(0, 10, 0, 35)
        msg.BackgroundTransparency = 1
        msg.Text = State.Capture.Remote and "Interaja com o jogo..." or "Ative captura em Settings"
        msg.TextColor3 = Theme.TextDim
        msg.Font = Enum.Font.Gotham
        msg.TextSize = 12
        msg.Parent = empty
        return
    end
    
    for i, event in ipairs(State.Events) do
        if i > 15 then break end
        self:CreateEventCard(parent, event)
    end
end

function ShakaLogger:BuildLogs(parent)
    if #State.Logs == 0 then
        local empty = self:CreateCard(parent, "📭 Sem Logs", 60)
        return
    end
    
    for i, log in ipairs(State.Logs) do
        if i > 20 then break end
        self:CreateLogCard(parent, log)
    end
end

--═══════════════════════════════════════════════════════════
-- COMPONENTES
--═══════════════════════════════════════════════════════════

function ShakaLogger:CreateCard(parent, title, height)
    local card = Instance.new("Frame")
    card.Size = UDim2.new(1, 0, 0, height)
    card.BackgroundColor3 = Theme.Card
    card.BorderSizePixel = 0
    card.Parent = parent
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = card
    
    local stroke = Instance.new("UIStroke")
    stroke.Color = Theme.Purple
    stroke.Thickness = 1
    stroke.Transparency = 0.7
    stroke.Parent = card
    
    if title then
        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(1, -15, 0, 28)
        label.Position = UDim2.new(0, 10, 0, 5)
        label.BackgroundTransparency = 1
        label.Text = title
        label.TextColor3 = Theme.Purple
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.Font = Enum.Font.GothamBold
        label.TextSize = 13
        label.Parent = card
    end
    
    return card
end

function ShakaLogger:CreateToggle(parent, name, enabled, yPos)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, -20, 0, 35)
    frame.Position = UDim2.new(0, 10, 0, yPos)
    frame.BackgroundColor3 = Color3.fromRGB(40, 40, 48)
    frame.BorderSizePixel = 0
    frame.Parent = parent
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = frame
    
    local icons = {Remote = "📡", Character = "🎯", Input = "⌨️"}
    
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -90, 1, 0)
    label.Position = UDim2.new(0, 12, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = (icons[name] or "📊") .. " " .. name
    label.TextColor3 = Theme.Text
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Font = Enum.Font.GothamBold
    label.TextSize = 12
    label.Parent = frame
    
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 65, 0, 26)
    btn.Position = UDim2.new(1, -72, 0.5, -13)
    btn.BackgroundColor3 = enabled and Theme.Success or Theme.Danger
    btn.Text = enabled and "ON" or "OFF"
    btn.TextColor3 = Theme.Text
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 11
    btn.BorderSizePixel = 0
    btn.Parent = frame
    
    local btnCorner = Instance.new("UICorner")
    btnCorner.CornerRadius = UDim.new(0, 5)
    btnCorner.Parent = btn
    
    btn.MouseButton1Click:Connect(function()
        State.Capture[name] = not State.Capture[name]
        local isOn = State.Capture[name]
        btn.BackgroundColor3 = isOn and Theme.Success or Theme.Danger
        btn.Text = isOn and "ON" or "OFF"
        self:AddLog("System", string.format("%s: %s", name, isOn and "ON" or "OFF"))
    end)
end

function ShakaLogger:CreateEventCard(parent, event)
    local isBlocked = self:IsBlocked(event.Path)
    
    local card = Instance.new("Frame")
    card.Size = UDim2.new(1, 0, 0, 95)
    card.BackgroundColor3 = Theme.Card
    card.BorderSizePixel = 0
    card.Parent = parent
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = card
    
    local stroke = Instance.new("UIStroke")
    stroke.Color = isBlocked and Theme.Danger or Theme.Purple
    stroke.Thickness = 2
    stroke.Transparency = 0.5
    stroke.Parent = card
    
    -- Info
    local name = Instance.new("TextLabel")
    name.Size = UDim2.new(1, -280, 0, 22)
    name.Position = UDim2.new(0, 10, 0, 8)
    name.BackgroundTransparency = 1
    name.TextTruncate = Enum.TextTruncate.AtEnd
    name.Parent = card
    
    local path = Instance.new("TextLabel")
    path.Size = UDim2.new(1, -280, 0, 16)
    path.Position = UDim2.new(0, 10, 0, 32)
    path.BackgroundTransparency = 1
    path.Text = event.Path
    path.TextColor3 = Theme.TextDim
    path.TextXAlignment = Enum.TextXAlignment.Left
    path.Font = Enum.Font.Code
    path.TextSize = 9
    path.TextTruncate = Enum.TextTruncate.AtEnd
    path.Parent = card
    
    local args = Instance.new("TextLabel")
    args.Size = UDim2.new(1, -280, 0, 16)
    args.Position = UDim2.new(0, 10, 0, 50)
    args.BackgroundTransparency = 1
    args.Text = FormatArgs(event.Args)
    args.TextColor3 = Theme.Warning
    args.TextXAlignment = Enum.TextXAlignment.Left
    args.Font = Enum.Font.Code
    args.TextSize = 9
    args.TextTruncate = Enum.TextTruncate.AtEnd
    args.Parent = card
    
    -- Status
    if isBlocked then
        local blocked = Instance.new("TextLabel")
        blocked.Size = UDim2.new(0, 75, 0, 18)
        blocked.Position = UDim2.new(0, 10, 0, 72)
        blocked.BackgroundColor3 = Theme.Danger
        blocked.Text = "🚫 BLOQUEADO"
        blocked.TextColor3 = Theme.Text
        blocked.Font = Enum.Font.GothamBold
        blocked.TextSize = 9
        blocked.BorderSizePixel = 0
        blocked.Parent = card
        
        local blockedCorner = Instance.new("UICorner")
        blockedCorner.CornerRadius = UDim.new(0, 4)
        blockedCorner.Parent = blocked
    end
    
    -- Botões
    local btnX = -270
    
    local btn1 = self:CreateButton(card, "▶️ x1", Theme.Success, btnX, 8, 60, 26)
    btn1.MouseButton1Click:Connect(function()
        self:ReplayEvent(event, 1)
    end)
    
    local btn5 = self:CreateButton(card, "⚡ x5", Theme.Purple, btnX + 65, 8, 60, 26)
    btn5.MouseButton1Click:Connect(function()
        self:ReplayEvent(event, 5)
    end)
    
    local btn10 = self:CreateButton(card, "🔥 x10", Theme.Warning, btnX + 130, 8, 60, 26)
    btn10.MouseButton1Click:Connect(function()
        self:ReplayEvent(event, 10)
    end)
    
    local btnLoop = self:CreateButton(card, event.IsLooping and "⏹️" or "🔁", 
        event.IsLooping and Theme.Danger or Color3.fromRGB(52, 152, 219), 
        btnX, 38, 60, 26)
    btnLoop.MouseButton1Click:Connect(function()
        local looping = self:ToggleLoop(event)
        btnLoop.Text = looping and "⏹️" or "🔁"
        btnLoop.BackgroundColor3 = looping and Theme.Danger or Color3.fromRGB(52, 152, 219)
    end)
    
    local btnBlock = self:CreateButton(card, isBlocked and "✅" or "🚫", 
        isBlocked and Theme.Success or Theme.Danger, 
        btnX + 65, 38, 60, 26)
    btnBlock.MouseButton1Click:Connect(function()
        self:ToggleBlock(event.Path)
        task.wait(0.1)
        self:RefreshTab()
    end)
    
    local btnCopy = self:CreateButton(card, "📋", Theme.Purple, btnX + 130, 38, 60, 26)
    btnCopy.MouseButton1Click:Connect(function()
        local data = string.format("Name: %s\nPath: %s\nArgs: %s", 
            event.Name, event.Path, FormatArgs(event.Args))
        if setclipboard then
            setclipboard(data)
            self:AddLog("System", "📋 Copiado!")
        else
            print(data)
        end
    end)
    
    local btnDelete = self:CreateButton(card, "🗑️", Color3.fromRGB(60, 60, 70), btnX, 68, 195, 22)
    btnDelete.MouseButton1Click:Connect(function()
        for i, e in ipairs(State.Events) do
            if e == event then
                table.remove(State.Events, i)
                State.Stats.Captured = #State.Events
                self:AddLog("System", "🗑️ Evento removido")
                self:RefreshTab()
                break
            end
        end
    end)
end

function ShakaLogger:CreateLogCard(parent, log)
    local card = Instance.new("Frame")
    card.Size = UDim2.new(1, 0, 0, 30)
    card.BackgroundColor3 = Theme.Card
    card.BorderSizePixel = 0
    card.Parent = parent
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = card
    
    local time = Instance.new("TextLabel")
    time.Size = UDim2.new(0, 55, 1, 0)
    time.Position = UDim2.new(0, 8, 0, 0)
    time.BackgroundTransparency = 1
    time.Text = log.Time
    time.TextColor3 = Theme.TextDim
    time.TextXAlignment = Enum.TextXAlignment.Left
    time.Font = Enum.Font.Code
    time.TextSize = 10
    time.Parent = card
    
    local category = Instance.new("TextLabel")
    category.Size = UDim2.new(0, 70, 1, 0)
    category.Position = UDim2.new(0, 68, 0, 0)
    category.BackgroundTransparency = 1
    category.Text = "[" .. log.Category .. "]"
    category.TextColor3 = Theme.Purple
    category.TextXAlignment = Enum.TextXAlignment.Left
    category.Font = Enum.Font.GothamBold
    category.TextSize = 10
    category.Parent = card
    
    local message = Instance.new("TextLabel")
    message.Size = UDim2.new(1, -148, 1, 0)
    message.Position = UDim2.new(0, 143, 0, 0)
    message.BackgroundTransparency = 1
    message.Text = log.Message
    message.TextColor3 = Theme.Text
    message.TextXAlignment = Enum.TextXAlignment.Left
    message.Font = Enum.Font.Gotham
    message.TextSize = 10
    message.TextTruncate = Enum.TextTruncate.AtEnd
    message.Parent = card
end

function ShakaLogger:CreateButton(parent, text, color, xPos, yPos, width, height)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, width, 0, height)
    btn.Position = UDim2.new(1, xPos, 0, yPos)
    btn.BackgroundColor3 = color
    btn.Text = text
    btn.TextColor3 = Theme.Text
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 10
    btn.BorderSizePixel = 0
    btn.AutoButtonColor = false
    btn.Parent = parent
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 5)
    corner.Parent = btn
    
    btn.MouseEnter:Connect(function()
        btn.BackgroundColor3 = Color3.fromRGB(
            math.min(255, color.R * 255 + 25),
            math.min(255, color.G * 255 + 25),
            math.min(255, color.B * 255 + 25)
        )
    end)
    
    btn.MouseLeave:Connect(function()
        btn.BackgroundColor3 = color
    end)
    
    return btn
end

--═══════════════════════════════════════════════════════════
-- CONTROLES
--═══════════════════════════════════════════════════════════

function ShakaLogger:Toggle()
    State.IsOpen = not State.IsOpen
    
    if not UI.MainFrame then return end
    
    if State.IsOpen then
        UI.MainFrame.Visible = true
        UI.MainFrame.Size = UDim2.new(0, 0, 0, 0)
        TweenService:Create(UI.MainFrame, TweenInfo.new(0.3, Enum.EasingStyle.Back), {
            Size = UDim2.new(0, 800, 0, 550)
        }):Play()
        task.wait(0.15)
        self:RefreshTab()
    else
        TweenService:Create(UI.MainFrame, TweenInfo.new(0.2, Enum.EasingStyle.Back), {
            Size = UDim2.new(0, 0, 0, 0)
        }):Play()
        task.wait(0.2)
        UI.MainFrame.Visible = false
    end
end

function ShakaLogger:SetupKeybind()
    UserInputService.InputBegan:Connect(function(input, processed)
        if not processed and input.KeyCode == CONFIG.OpenKey then
            self:Toggle()
        end
    end)
end

--═══════════════════════════════════════════════════════════
-- INICIALIZAÇÃO
--═══════════════════════════════════════════════════════════

function ShakaLogger:Init()
    print("\n" .. string.rep("═", 60))
    print("⚡ SHAKA LOGGER v2.0 - OTIMIZADO")
    print("   Anti-Crash • Performance Melhorada")
    print(string.rep("═", 60))
    
    -- UI
    SafeCall(function()
        self:CreateUI()
    end)
    
    -- Keybind
    SafeCall(function()
        self:SetupKeybind()
    end)
    
    -- Hook
    task.wait(0.5)
    SafeCall(function()
        self:HookRemotes()
    end)
    
    -- Monitors
    task.wait(0.3)
    SafeCall(function()
        self:StartMonitors()
    end)
    
    -- Abrir UI
    task.wait(1)
    self:Toggle()
    self:SwitchTab("Settings")
    
    print("\n✅ SHAKA LOGGER PRONTO!")
    print("⌨️ Pressione [F] para abrir/fechar")
    print("⚠️ Ative as capturas em Settings\n")
    print(string.rep("═", 60) .. "\n")
end

--═══════════════════════════════════════════════════════════
-- AUTO-INIT
--═══════════════════════════════════════════════════════════

task.spawn(function()
    if not game:IsLoaded() then
        game.Loaded:Wait()
    end
    task.wait(2)
    
    ShakaLogger:Init()
end)

-- Global
getgenv().ShakaLogger = ShakaLogger
_G.ShakaLogger = ShakaLogger

return ShakaLogger = "📡 " .. event.Name
    name.TextColor3 = Theme.Purple
    name.TextXAlignment = Enum.TextXAlignment.Left
    name.Font = Enum.Font.GothamBold
    name.TextSize = 13
    name.Text
