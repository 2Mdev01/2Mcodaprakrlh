-- SHAKA LOGGER v1.3 - CORREÇÃO DE OVERFLOW
-- Sistema avançado de logging com replay e filtros
-- Tema: Preto e Roxo | Anti-Crash
-- CORRIGIDO: Stack overflow e performance

local ShakaLogger = {}

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")
local TweenService = game:GetService("TweenService")

-- Configurações
ShakaLogger.OpenKey = Enum.KeyCode.F
ShakaLogger.IsOpen = false
ShakaLogger.CurrentTab = "Settings"
ShakaLogger.IsRefreshing = false -- NOVO: Prevenir refresh recursivo

-- Controle de captura
ShakaLogger.CaptureEnabled = {
    Remote = false,
    Character = false,
    Input = false,
    Network = false
}

-- Dados
ShakaLogger.CapturedEvents = {}
ShakaLogger.BlockedEvents = {}
ShakaLogger.Logs = {
    Remote = {},
    Character = {},
    Input = {},
    Network = {},
    System = {}
}

ShakaLogger.FilterSettings = {
    Remote = true,
    Character = true,
    Input = true,
    Network = true,
    System = true
}

ShakaLogger.Stats = {
    Total = 0,
    Remote = 0,
    Character = 0,
    Input = 0,
    Network = 0,
    Captured = 0,
    Blocked = 0
}

--═══════════════════════════════════════════════════════════
-- SISTEMA DE LOG - OTIMIZADO
--═══════════════════════════════════════════════════════════

function ShakaLogger:AddLog(category, message, data)
    if not self.FilterSettings[category] then return end
    
    local log = {
        Time = os.date("%H:%M:%S"),
        Category = category,
        Message = message,
        Data = data or {},
        ID = tick()
    }
    
    if not self.Logs[category] then
        self.Logs[category] = {}
    end
    
    table.insert(self.Logs[category], 1, log)
    
    -- Limitar logs
    if #self.Logs[category] > 50 then
        table.remove(self.Logs[category])
    end
    
    self.Stats.Total = self.Stats.Total + 1
    self.Stats[category] = (self.Stats[category] or 0) + 1
    
    -- Print apenas se não for spam
    if category ~= "Input" or math.random() > 0.8 then
        print(string.format("[SHAKA] [%s] [%s] %s", log.Time, category, message))
    end
    
    -- REMOVIDO: Não atualizar UI automaticamente para evitar recursão
end

function ShakaLogger:IsEventBlocked(remotePath)
    return self.BlockedEvents[remotePath] == true
end

function ShakaLogger:BlockEvent(remotePath)
    self.BlockedEvents[remotePath] = true
    self.Stats.Blocked = self.Stats.Blocked + 1
    print("[SHAKA] 🚫 Bloqueado:", remotePath)
end

function ShakaLogger:UnblockEvent(remotePath)
    if self.BlockedEvents[remotePath] then
        self.BlockedEvents[remotePath] = nil
        self.Stats.Blocked = math.max(0, self.Stats.Blocked - 1)
        print("[SHAKA] ✅ Desbloqueado:", remotePath)
    end
end

--═══════════════════════════════════════════════════════════
-- SISTEMA DE CAPTURA - OTIMIZADO
--═══════════════════════════════════════════════════════════

function ShakaLogger:CaptureRemoteEvent(remote, eventType, args)
    if not self.CaptureEnabled.Remote then return end
    
    -- Proteção contra spam
    local remotePath = remote:GetFullName()
    
    local eventData = {
        Name = remote.Name,
        Type = eventType,
        Path = remotePath,
        Remote = remote,
        Args = args,
        Time = os.date("%H:%M:%S"),
        Timestamp = tick(),
        ID = #self.CapturedEvents + 1,
        IsBlocked = self:IsEventBlocked(remotePath),
        IsLooping = false
    }
    
    table.insert(self.CapturedEvents, 1, eventData)
    
    -- Limitar eventos capturados
    if #self.CapturedEvents > 50 then
        table.remove(self.CapturedEvents)
    end
    
    self.Stats.Captured = #self.CapturedEvents
    self.Stats.Remote = self.Stats.Remote + 1
    
    -- Log simplificado
    local argsStr = self:FormatArgs(args)
    local status = eventData.IsBlocked and "🚫" or "✅"
    
    -- Usar AddLog sem recursão
    local log = {
        Time = eventData.Time,
        Category = "Remote",
        Message = string.format("%s %s [%s] %s", status, remote.Name, eventType, argsStr),
        Data = eventData,
        ID = tick()
    }
    
    table.insert(self.Logs.Remote, 1, log)
    if #self.Logs.Remote > 50 then
        table.remove(self.Logs.Remote)
    end
    
    return eventData
end

function ShakaLogger:FormatArgs(args)
    if not args or #args == 0 then return "{}" end
    
    local result = "{"
    for i, arg in ipairs(args) do
        if i > 3 then -- Reduzido para 3
            result = result .. "..."
            break
        end
        
        local argStr
        local argType = type(arg)
        
        if argType == "string" then
            argStr = '"' .. tostring(arg):sub(1, 20) .. '"'
        elseif argType == "number" then
            argStr = tostring(arg)
        elseif argType == "boolean" then
            argStr = tostring(arg)
        elseif argType == "table" then
            argStr = "{...}"
        elseif typeof(arg) == "Instance" then
            argStr = arg.Name or "Instance"
        elseif typeof(arg) == "Vector3" then
            argStr = string.format("V3(%.0f,%.0f,%.0f)", arg.X, arg.Y, arg.Z)
        else
            argStr = tostring(arg):sub(1, 20)
        end
        
        result = result .. argStr
        if i < #args and i < 3 then
            result = result .. ", "
        end
    end
    return result .. "}"
end

--═══════════════════════════════════════════════════════════
-- HOOK GLOBAL - SIMPLIFICADO
--═══════════════════════════════════════════════════════════

function ShakaLogger:HookAllRemotes()
    if not hookmetamethod or not getnamecallmethod or not newcclosure then
        warn("[SHAKA] ❌ Executor não suporta hookmetamethod!")
        return false
    end
    
    local success = pcall(function()
        local oldNamecall
        oldNamecall = hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
            local method = getnamecallmethod()
            local args = {...}
            
            if typeof(self) == "Instance" then
                local isRemoteEvent = self:IsA("RemoteEvent")
                local isRemoteFunction = self:IsA("RemoteFunction")
                
                if (method == "FireServer" and isRemoteEvent) or (method == "InvokeServer" and isRemoteFunction) then
                    local remotePath = self:GetFullName()
                    
                    -- Verificar bloqueio PRIMEIRO
                    if ShakaLogger:IsEventBlocked(remotePath) then
                        return isRemoteFunction and nil or nil
                    end
                    
                    -- Capturar SEM pcall para evitar stack
                    if ShakaLogger.CaptureEnabled.Remote then
                        local eventType = isRemoteEvent and "RemoteEvent" or "RemoteFunction"
                        ShakaLogger:CaptureRemoteEvent(self, eventType, args)
                    end
                end
            end
            
            return oldNamecall(self, ...)
        end))
    end)
    
    if success then
        print("[SHAKA] ✅ Hook instalado!")
        return true
    else
        warn("[SHAKA] ❌ Falha no hook!")
        return false
    end
end

--═══════════════════════════════════════════════════════════
-- MONITORAMENTO - OTIMIZADO
--═══════════════════════════════════════════════════════════

function ShakaLogger:MonitorCharacter()
    local lastPos = nil
    local lastHealth = nil
    local lastUpdate = 0
    
    RunService.Heartbeat:Connect(function()
        if not self.CaptureEnabled.Character then return end
        
        local now = tick()
        if now - lastUpdate < 1 then return end -- 1 segundo de cooldown
        lastUpdate = now
        
        local player = Players.LocalPlayer
        if not player or not player.Character then return end
        
        local root = player.Character:FindFirstChild("HumanoidRootPart")
        local humanoid = player.Character:FindFirstChild("Humanoid")
        
        if root then
            local currentPos = root.Position
            if lastPos then
                local dist = (currentPos - lastPos).Magnitude
                if dist > 100 then
                    print(string.format("[SHAKA] 🎯 Movimento: %.0f studs", dist))
                end
            end
            lastPos = currentPos
        end
        
        if humanoid then
            local currentHealth = humanoid.Health
            if lastHealth and math.abs(currentHealth - lastHealth) > 10 then
                local change = currentHealth - lastHealth
                print(string.format("[SHAKA] ❤️ Saúde: %.0f → %.0f", lastHealth, currentHealth))
            end
            lastHealth = currentHealth
        end
    end)
    
    print("[SHAKA] ✅ Monitor Character ativo")
end

function ShakaLogger:MonitorInputs()
    local lastInput = {}
    
    UserInputService.InputBegan:Connect(function(input, processed)
        if not self.CaptureEnabled.Input or processed then return end
        
        local inputName = tostring(input.KeyCode.Name or input.UserInputType.Name)
        local now = tick()
        
        -- Cooldown de 1 segundo
        if lastInput[inputName] and (now - lastInput[inputName]) < 1 then
            return
        end
        lastInput[inputName] = now
        
        if input.UserInputType == Enum.UserInputType.Keyboard then
            print("[SHAKA] ⌨️ Tecla:", input.KeyCode.Name)
        end
    end)
    
    print("[SHAKA] ✅ Monitor Input ativo")
end

function ShakaLogger:MonitorNetwork()
    Players.PlayerAdded:Connect(function(player)
        if self.CaptureEnabled.Network then
            print("[SHAKA] 👤", player.Name, "entrou")
        end
    end)
    
    Players.PlayerRemoving:Connect(function(player)
        if self.CaptureEnabled.Network then
            print("[SHAKA] 👋", player.Name, "saiu")
        end
    end)
    
    print("[SHAKA] ✅ Monitor Network ativo")
end

--═══════════════════════════════════════════════════════════
-- REPLAY - VERIFICADO
--═══════════════════════════════════════════════════════════

function ShakaLogger:ReplayEvent(eventData, times)
    times = times or 1
    local successCount = 0
    
    if not eventData.Remote or not eventData.Remote.Parent then
        warn("[SHAKA] ❌ Remote não existe mais:", eventData.Name)
        return 0
    end
    
    for i = 1, times do
        local success = pcall(function()
            if eventData.Type == "RemoteEvent" then
                eventData.Remote:FireServer(unpack(eventData.Args))
            elseif eventData.Type == "RemoteFunction" then
                eventData.Remote:InvokeServer(unpack(eventData.Args))
            end
        end)
        
        if success then successCount = successCount + 1 end
        if times > 1 then task.wait(0.1) end
    end
    
    print(string.format("[SHAKA] ✅ REPLAY: %s [%dx] - %d/%d sucesso", 
        eventData.Name, times, successCount, times))
    
    return successCount
end

function ShakaLogger:ToggleLoop(eventData)
    if eventData.IsLooping then
        eventData.IsLooping = false
        print("[SHAKA] ⏹️ Loop parado:", eventData.Name)
        return false
    end
    
    if not eventData.Remote or not eventData.Remote.Parent then
        warn("[SHAKA] ❌ Remote não existe!")
        return false
    end
    
    eventData.IsLooping = true
    print("[SHAKA] 🔁 Loop iniciado:", eventData.Name)
    
    task.spawn(function()
        while eventData.IsLooping do
            if not eventData.Remote or not eventData.Remote.Parent then
                eventData.IsLooping = false
                break
            end
            
            pcall(function()
                if eventData.Type == "RemoteEvent" then
                    eventData.Remote:FireServer(unpack(eventData.Args))
                elseif eventData.Type == "RemoteFunction" then
                    eventData.Remote:InvokeServer(unpack(eventData.Args))
                end
            end)
            
            task.wait(0.5)
        end
    end)
    
    return true
end

--═══════════════════════════════════════════════════════════
-- INTERFACE - SIMPLIFICADA
--═══════════════════════════════════════════════════════════

function ShakaLogger:CreateUI()
    pcall(function()
        local existing = game:GetService("CoreGui"):FindFirstChild("ShakaLogger")
        if existing then existing:Destroy() end
    end)
    
    local gui = Instance.new("ScreenGui")
    gui.Name = "ShakaLogger"
    gui.ResetOnSpawn = false
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    
    pcall(function()
        gui.Parent = game:GetService("CoreGui")
    end)
    
    if not gui.Parent then
        gui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")
    end
    
    self.ScreenGui = gui
    
    local Theme = {
        Background = Color3.fromRGB(18, 18, 24),
        Header = Color3.fromRGB(28, 24, 38),
        Card = Color3.fromRGB(32, 28, 42),
        Tab = Color3.fromRGB(42, 38, 52),
        TabActive = Color3.fromRGB(148, 53, 236),
        Purple = Color3.fromRGB(148, 53, 236),
        PurpleLight = Color3.fromRGB(196, 95, 221),
        Text = Color3.fromRGB(255, 255, 255),
        TextSecondary = Color3.fromRGB(190, 190, 210),
        Success = Color3.fromRGB(46, 204, 113),
        Warning = Color3.fromRGB(255, 165, 0),
        Danger = Color3.fromRGB(231, 76, 60),
        Info = Color3.fromRGB(52, 152, 219),
        Accent = Color3.fromRGB(148, 53, 236)
    }
    
    self.Theme = Theme
    
    -- Main Frame
    local main = Instance.new("Frame")
    main.Name = "Main"
    main.Size = UDim2.new(0, 900, 0, 620)
    main.Position = UDim2.new(0.5, -450, 0.5, -310)
    main.BackgroundColor3 = Theme.Background
    main.BorderSizePixel = 0
    main.Visible = false
    main.Parent = gui
    
    self.MainFrame = main
    
    local border = Instance.new("UIStroke")
    border.Color = Theme.Purple
    border.Thickness = 2
    border.Transparency = 0.2
    border.Parent = main
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 14)
    corner.Parent = main
    
    -- Header
    local header = Instance.new("Frame")
    header.Size = UDim2.new(1, 0, 0, 55)
    header.BackgroundColor3 = Theme.Header
    header.BorderSizePixel = 0
    header.Parent = main
    
    local headerCorner = Instance.new("UICorner")
    headerCorner.CornerRadius = UDim.new(0, 14)
    headerCorner.Parent = header
    
    local topBar = Instance.new("Frame")
    topBar.Size = UDim2.new(1, 0, 0, 4)
    topBar.BackgroundColor3 = Theme.Purple
    topBar.BorderSizePixel = 0
    topBar.Parent = header
    
    local topBarCorner = Instance.new("UICorner")
    topBarCorner.CornerRadius = UDim.new(0, 14)
    topBarCorner.Parent = topBar
    
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, -120, 0, 24)
    title.Position = UDim2.new(0, 20, 0, 8)
    title.BackgroundTransparency = 1
    title.Text = "⚡ SHAKA LOGGER"
    title.TextColor3 = Theme.Purple
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Font = Enum.Font.GothamBold
    title.TextSize = 22
    title.Parent = header
    
    local subtitle = Instance.new("TextLabel")
    subtitle.Size = UDim2.new(1, -120, 0, 16)
    subtitle.Position = UDim2.new(0, 20, 0, 34)
    subtitle.BackgroundTransparency = 1
    subtitle.Text = "Event Capture & Replay • v1.3 Anti-Crash"
    subtitle.TextColor3 = Theme.TextSecondary
    subtitle.TextXAlignment = Enum.TextXAlignment.Left
    subtitle.Font = Enum.Font.Gotham
    subtitle.TextSize = 11
    subtitle.Parent = header
    
    local closeBtn = Instance.new("TextButton")
    closeBtn.Size = UDim2.new(0, 95, 0, 32)
    closeBtn.Position = UDim2.new(1, -105, 0.5, -16)
    closeBtn.BackgroundColor3 = Theme.Danger
    closeBtn.Text = "✖ FECHAR [F]"
    closeBtn.TextColor3 = Theme.Text
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.TextSize = 11
    closeBtn.BorderSizePixel = 0
    closeBtn.Parent = header
    
    local closeBtnCorner = Instance.new("UICorner")
    closeBtnCorner.CornerRadius = UDim.new(0, 8)
    closeBtnCorner.Parent = closeBtn
    
    closeBtn.MouseButton1Click:Connect(function()
        self:Toggle()
    end)
    
    -- Tabs
    local tabContainer = Instance.new("Frame")
    tabContainer.Size = UDim2.new(1, 0, 0, 48)
    tabContainer.Position = UDim2.new(0, 0, 0, 55)
    tabContainer.BackgroundColor3 = Theme.Tab
    tabContainer.BorderSizePixel = 0
    tabContainer.Parent = main
    
    local tabLayout = Instance.new("UIListLayout")
    tabLayout.FillDirection = Enum.FillDirection.Horizontal
    tabLayout.SortOrder = Enum.SortOrder.LayoutOrder
    tabLayout.Padding = UDim.new(0, 3)
    tabLayout.Parent = tabContainer
    
    local tabs = {
        {Name = "Settings", Icon = "⚙️"},
        {Name = "Replay", Icon = "🔄"},
        {Name = "Logs", Icon = "📝"}
    }
    
    self.TabButtons = {}
    
    for i, tab in ipairs(tabs) do
        local tabBtn = Instance.new("TextButton")
        tabBtn.Name = tab.Name
        tabBtn.Size = UDim2.new(0, 295, 1, 0)
        tabBtn.BackgroundColor3 = Theme.Tab
        tabBtn.BorderSizePixel = 0
        tabBtn.Text = tab.Icon .. " " .. tab.Name
        tabBtn.TextColor3 = Theme.TextSecondary
        tabBtn.Font = Enum.Font.GothamBold
        tabBtn.TextSize = 14
        tabBtn.Parent = tabContainer
        
        tabBtn.MouseButton1Click:Connect(function()
            self:SwitchTab(tab.Name)
        end)
        
        self.TabButtons[tab.Name] = tabBtn
    end
    
    -- Content
    local content = Instance.new("Frame")
    content.Name = "Content"
    content.Size = UDim2.new(1, -24, 1, -118)
    content.Position = UDim2.new(0, 12, 0, 106)
    content.BackgroundTransparency = 1
    content.Parent = main
    
    self.ContentArea = content
    
    self.ContentFrames = {}
    
    for _, tab in ipairs(tabs) do
        local frame = Instance.new("ScrollingFrame")
        frame.Name = tab.Name .. "Frame"
        frame.Size = UDim2.new(1, 0, 1, 0)
        frame.BackgroundTransparency = 1
        frame.BorderSizePixel = 0
        frame.ScrollBarThickness = 10
        frame.ScrollBarImageColor3 = Theme.Purple
        frame.Visible = false
        frame.CanvasSize = UDim2.new(0, 0, 0, 0)
        frame.AutomaticCanvasSize = Enum.AutomaticSize.Y
        frame.Parent = content
        
        local layout = Instance.new("UIListLayout")
        layout.Padding = UDim.new(0, 12)
        layout.SortOrder = Enum.SortOrder.LayoutOrder
        layout.Parent = frame
        
        self.ContentFrames[tab.Name] = frame
    end
    
    print("[SHAKA] ✅ UI criada!")
end

function ShakaLogger:SwitchTab(tabName)
    if self.IsRefreshing then return end
    
    self.CurrentTab = tabName
    
    for name, btn in pairs(self.TabButtons) do
        if name == tabName then
            btn.BackgroundColor3 = self.Theme.TabActive
            btn.TextColor3 = self.Theme.Text
        else
            btn.BackgroundColor3 = self.Theme.Tab
            btn.TextColor3 = self.Theme.TextSecondary
        end
    end
    
    for name, frame in pairs(self.ContentFrames) do
        frame.Visible = (name == tabName)
    end
    
    self:RefreshCurrentTab()
end

function ShakaLogger:RefreshCurrentTab()
    if self.IsRefreshing then return end
    self.IsRefreshing = true
    
    task.spawn(function()
        pcall(function()
            local frame = self.ContentFrames[self.CurrentTab]
            if not frame then 
                self.IsRefreshing = false
                return 
            end
            
            for _, child in ipairs(frame:GetChildren()) do
                if not child:IsA("UIListLayout") then
                    child:Destroy()
                end
            end
            
            if self.CurrentTab == "Settings" then
                self:CreateSettingsContent(frame)
            elseif self.CurrentTab == "Replay" then
                self:CreateReplayContent(frame)
            elseif self.CurrentTab == "Logs" then
                self:CreateLogsContent(frame)
            end
        end)
        
        self.IsRefreshing = false
    end)
end

--═══════════════════════════════════════════════════════════
-- CONTEÚDO - SIMPLIFICADO
--═══════════════════════════════════════════════════════════

function ShakaLogger:CreateSettingsContent(frame)
    local card = self:CreateCard(frame, "🎯 CONTROLE DE CAPTURA", 250)
    
    local info = Instance.new("TextLabel")
    info.Size = UDim2.new(1, -30, 0, 35)
    info.Position = UDim2.new(0, 15, 0, 40)
    info.BackgroundTransparency = 1
    info.Text = "⚠️ Ative apenas o que você precisa para evitar lag"
    info.TextColor3 = self.Theme.Warning
    info.Font = Enum.Font.Gotham
    info.TextSize = 12
    info.TextWrapped = true
    info.TextXAlignment = Enum.TextXAlignment.Left
    info.Parent = card
    
    local y = 80
    
    for category, enabled in pairs(self.CaptureEnabled) do
        self:CreateToggle(card, category, enabled, y)
        y = y + 42
    end
    
    -- Botões de ação
    local actionsCard = self:CreateCard(frame, "🔧 AÇÕES", 140)
    
    local clearBtn = self:CreateButton(actionsCard, "🗑️ LIMPAR EVENTOS", self.Theme.Danger, 15, 45, 320, 38)
    clearBtn.MouseButton1Click:Connect(function()
        self.CapturedEvents = {}
        self.Stats.Captured = 0
        print("[SHAKA] 🗑️ Eventos limpos!")
    end)
    
    local unblockBtn = self:CreateButton(actionsCard, "✅ DESBLOQUEAR TODOS", self.Theme.Success, 15, 93, 320, 38)
    unblockBtn.MouseButton1Click:Connect(function()
        self.BlockedEvents = {}
        self.Stats.Blocked = 0
        print("[SHAKA] ✅ Desbloqueados!")
        self:RefreshCurrentTab()
    end)
end

function ShakaLogger:CreateReplayContent(frame)
    local statusCard = self:CreateCard(frame, "📊 STATUS", 120)
    
    local statusText = Instance.new("TextLabel")
    statusText.Size = UDim2.new(1, -30, 0, 70)
    statusText.Position = UDim2.new(0, 15, 0, 45)
    statusText.BackgroundTransparency = 1
    statusText.Text = string.format(
        "Captura: %s\nEventos: %d\nBloqueados: %d",
        self.CaptureEnabled.Remote and "🟢 ATIVA" or "🔴 DESATIVA",
        self.Stats.Captured,
        self.Stats.Blocked
    )
    statusText.TextColor3 = self.Theme.Text
    statusText.Font = Enum.Font.GothamBold
    statusText.TextSize = 14
    statusText.TextXAlignment = Enum.TextXAlignment.Left
    statusText.TextYAlignment = Enum.TextYAlignment.Top
    statusText.Parent = statusCard
    
    if #self.CapturedEvents == 0 then
        local emptyCard = self:CreateCard(frame, "⚠️ NENHUM EVENTO", 90)
        
        local emptyText = Instance.new("TextLabel")
        emptyText.Size = UDim2.new(1, -30, 0, 50)
        emptyText.Position = UDim2.new(0, 15, 0, 40)
        emptyText.BackgroundTransparency = 1
        emptyText.Text = self.CaptureEnabled.Remote and 
            "Interaja com o jogo para capturar" or
            "Ative a captura em Settings"
        emptyText.TextColor3 = self.Theme.TextSecondary
        emptyText.Font = Enum.Font.Gotham
        emptyText.TextSize = 13
        emptyText.TextWrapped = true
        emptyText.Parent = emptyCard
        return
    end
    
    for i, event in ipairs(self.CapturedEvents) do
        if i > 10 then break end -- Limitar a 10
        self:CreateEventCard(frame, event)
    end
end

function ShakaLogger:CreateLogsContent(frame)
    local logs = {}
    
    for cat, catLogs in pairs(self.Logs) do
        for _, log in ipairs(catLogs) do
            table.insert(logs, log)
        end
    end
    
    table.sort(logs, function(a, b) return (a.ID or 0) > (b.ID or 0) end)
    
    if #logs == 0 then
        local emptyCard = self:CreateCard(frame, "📭 SEM LOGS", 60)
        return
    end
    
    for i, log in ipairs(logs) do
        if i > 20 then break end
        self:CreateLogRow(frame, log)
    end
end

--═══════════════════════════════════════════════════════════
-- COMPONENTES
--═══════════════════════════════════════════════════════════

function ShakaLogger:CreateCard(parent, title, height)
    local card = Instance.new("Frame")
    card.Size = UDim2.new(1, 0, 0, height)
    card.BackgroundColor3 = self.Theme.Card
    card.BorderSizePixel = 0
    card.Parent = parent
    
    local cardCorner = Instance.new("UICorner")
    cardCorner.CornerRadius = UDim.new(0, 10)
    cardCorner.Parent = card
    
    local cardBorder = Instance.new("UIStroke")
    cardBorder.Color = self.Theme.Purple
    cardBorder.Thickness = 1.5
    cardBorder.Transparency = 0.6
    cardBorder.Parent = card
    
    if title then
        local titleLabel = Instance.new("TextLabel")
        titleLabel.Size = UDim2.new(1, -25, 0, 32)
        titleLabel.Position = UDim2.new(0, 15, 0, 6)
        titleLabel.BackgroundTransparency = 1
        titleLabel.Text = title
        titleLabel.TextColor3 = self.Theme.PurpleLight
        titleLabel.TextXAlignment = Enum.TextXAlignment.Left
        titleLabel.Font = Enum.Font.GothamBold
        titleLabel.TextSize = 14
        titleLabel.Parent = card
    end
    
    return card
end

function ShakaLogger:CreateToggle(parent, category, enabled, yPos)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, -30, 0, 38)
    frame.Position = UDim2.new(0, 15, 0, yPos)
    frame.BackgroundColor3 = self.Theme.Tab
    frame.BorderSizePixel = 0
    frame.Parent = parent
    
    local frameCorner = Instance.new("UICorner")
    frameCorner.CornerRadius = UDim.new(0, 8)
    frameCorner.Parent = frame
    
    local icons = {Remote = "📡", Character = "🎯", Input = "⌨️", Network = "🌐"}
    
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -110, 1, 0)
    label.Position = UDim2.new(0, 18, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = (icons[category] or "📊") .. " Capturar " .. category
    label.TextColor3 = self.Theme.Text
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Font = Enum.Font.GothamBold
    label.TextSize = 13
    label.Parent = frame
    
    local toggleBtn = Instance.new("TextButton")
    toggleBtn.Size = UDim2.new(0, 75, 0, 28)
    toggleBtn.Position = UDim2.new(1, -85, 0.5, -14)
    toggleBtn.BackgroundColor3 = enabled and self.Theme.Success or self.Theme.Danger
    toggleBtn.Text = enabled and "🟢 ON" or "🔴 OFF"
    toggleBtn.TextColor3 = self.Theme.Text
    toggleBtn.Font = Enum.Font.GothamBold
    toggleBtn.TextSize = 12
    toggleBtn.BorderSizePixel = 0
    toggleBtn.Parent = frame
    
    local toggleCorner = Instance.new("UICorner")
    toggleCorner.CornerRadius = UDim.new(0, 6)
    toggleCorner.Parent = toggleBtn
    
    toggleBtn.MouseButton1Click:Connect(function()
        self.CaptureEnabled[category] = not self.CaptureEnabled[category]
        local isEnabled = self.CaptureEnabled[category]
        toggleBtn.BackgroundColor3 = isEnabled and self.Theme.Success or self.Theme.Danger
        toggleBtn.Text = isEnabled and "🟢 ON" or "🔴 OFF"
        print(string.format("[SHAKA] Captura de %s %s", category, isEnabled and "ativada" or "desativada"))
    end)
end

function ShakaLogger:CreateEventCard(parent, event)
    local isBlocked = self:IsEventBlocked(event.Path)
    
    local card = Instance.new("Frame")
    card.Size = UDim2.new(1, 0, 0, 110)
    card.BackgroundColor3 = self.Theme.Card
    card.BorderSizePixel = 0
    card.Parent = parent
    
    local cardCorner = Instance.new("UICorner")
    cardCorner.CornerRadius = UDim.new(0, 10)
    cardCorner.Parent = card
    
    local cardBorder = Instance.new("UIStroke")
    cardBorder.Color = isBlocked and self.Theme.Danger or self.Theme.Purple
    cardBorder.Thickness = 2
    cardBorder.Transparency = 0.5
    cardBorder.Parent = card
    
    -- Nome
    local nameLabel = Instance.new("TextLabel")
    nameLabel.Size = UDim2.new(1, -340, 0, 24)
    nameLabel.Position = UDim2.new(0, 14, 0, 10)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text = "📡 " .. event.Name
    nameLabel.TextColor3 = self.Theme.PurpleLight
    nameLabel.TextXAlignment = Enum.TextXAlignment.Left
    nameLabel.Font = Enum.Font.GothamBold
    nameLabel.TextSize = 14
    nameLabel.TextTruncate = Enum.TextTruncate.AtEnd
    nameLabel.Parent = card
    
    -- Path
    local pathLabel = Instance.new("TextLabel")
    pathLabel.Size = UDim2.new(1, -340, 0, 18)
    pathLabel.Position = UDim2.new(0, 14, 0, 36)
    pathLabel.BackgroundTransparency = 1
    pathLabel.Text = event.Path
    pathLabel.TextColor3 = self.Theme.TextSecondary
    pathLabel.TextXAlignment = Enum.TextXAlignment.Left
    pathLabel.Font = Enum.Font.Gotham
    pathLabel.TextSize = 9
    pathLabel.TextTruncate = Enum.TextTruncate.AtEnd
    pathLabel.Parent = card
    
    -- Args
    local argsLabel = Instance.new("TextLabel")
    argsLabel.Size = UDim2.new(1, -340, 0, 18)
    argsLabel.Position = UDim2.new(0, 14, 0, 56)
    argsLabel.BackgroundTransparency = 1
    argsLabel.Text = "Args: " .. self:FormatArgs(event.Args)
    argsLabel.TextColor3 = self.Theme.Warning
    argsLabel.TextXAlignment = Enum.TextXAlignment.Left
    argsLabel.Font = Enum.Font.Code
    argsLabel.TextSize = 9
    argsLabel.TextTruncate = Enum.TextTruncate.AtEnd
    argsLabel.Parent = card
    
    -- Status
    if isBlocked then
        local blockedLabel = Instance.new("TextLabel")
        blockedLabel.Size = UDim2.new(0, 80, 0, 20)
        blockedLabel.Position = UDim2.new(0, 14, 0, 78)
        blockedLabel.BackgroundColor3 = self.Theme.Danger
        blockedLabel.Text = "🚫 BLOQUEADO"
        blockedLabel.TextColor3 = self.Theme.Text
        blockedLabel.Font = Enum.Font.GothamBold
        blockedLabel.TextSize = 9
        blockedLabel.BorderSizePixel = 0
        blockedLabel.Parent = card
        
        local blockedCorner = Instance.new("UICorner")
        blockedCorner.CornerRadius = UDim.new(0, 4)
        blockedCorner.Parent = blockedLabel
    end
    
    -- Botões
    local btnY = 10
    local btnX = -330
    
    local btn1 = self:CreateButton(card, "▶️ x1", self.Theme.Success, btnX, btnY, 70, 28)
    btn1.MouseButton1Click:Connect(function()
        self:ReplayEvent(event, 1)
    end)
    
    local btn5 = self:CreateButton(card, "⚡ x5", self.Theme.Purple, btnX, btnY + 35, 70, 28)
    btn5.MouseButton1Click:Connect(function()
        self:ReplayEvent(event, 5)
    end)
    
    local btn10 = self:CreateButton(card, "🔥 x10", self.Theme.Warning, btnX, btnY + 70, 70, 28)
    btn10.MouseButton1Click:Connect(function()
        self:ReplayEvent(event, 10)
    end)
    
    local btnLoop = self:CreateButton(card, event.IsLooping and "⏹️ STOP" or "🔁 LOOP", 
        event.IsLooping and self.Theme.Danger or self.Theme.Info, 
        btnX + 75, btnY, 70, 28)
    btnLoop.MouseButton1Click:Connect(function()
        local looping = self:ToggleLoop(event)
        btnLoop.Text = looping and "⏹️ STOP" or "🔁 LOOP"
        btnLoop.BackgroundColor3 = looping and self.Theme.Danger or self.Theme.Info
    end)
    
    local btnBlock = self:CreateButton(card, isBlocked and "✅ DESBLO" or "🚫 BLOC", 
        isBlocked and self.Theme.Success or self.Theme.Danger, 
        btnX + 75, btnY + 35, 70, 28)
    btnBlock.MouseButton1Click:Connect(function()
        if isBlocked then
            self:UnblockEvent(event.Path)
        else
            self:BlockEvent(event.Path)
        end
        task.wait(0.1)
        self:RefreshCurrentTab()
    end)
    
    local btnInfo = self:CreateButton(card, "ℹ️ INFO", Color3.fromRGB(70, 70, 90), btnX + 75, btnY + 70, 70, 28)
    btnInfo.MouseButton1Click:Connect(function()
        print("\n" .. string.rep("═", 60))
        print("📋 EVENTO:", event.Name)
        print("Tipo:", event.Type)
        print("Path:", event.Path)
        print("Args:", HttpService:JSONEncode(event.Args))
        print(string.rep("═", 60) .. "\n")
    end)
    
    local btnCopy = self:CreateButton(card, "📋 COPY", self.Theme.Accent, btnX + 150, btnY, 70, 28)
    btnCopy.MouseButton1Click:Connect(function()
        local argsJson = HttpService:JSONEncode(event.Args)
        if setclipboard then
            setclipboard(argsJson)
            print("[SHAKA] 📋 Copiado!")
        else
            print("[SHAKA] Args:", argsJson)
        end
    end)
end

function ShakaLogger:CreateLogRow(parent, log)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, 0, 0, 32)
    row.BackgroundColor3 = self.Theme.Card
    row.BorderSizePixel = 0
    row.Parent = parent
    
    local rowCorner = Instance.new("UICorner")
    rowCorner.CornerRadius = UDim.new(0, 6)
    rowCorner.Parent = row
    
    local timeLabel = Instance.new("TextLabel")
    timeLabel.Size = UDim2.new(0, 60, 1, 0)
    timeLabel.Position = UDim2.new(0, 8, 0, 0)
    timeLabel.BackgroundTransparency = 1
    timeLabel.Text = log.Time
    timeLabel.TextColor3 = self.Theme.TextSecondary
    timeLabel.TextXAlignment = Enum.TextXAlignment.Left
    timeLabel.Font = Enum.Font.Code
    timeLabel.TextSize = 10
    timeLabel.Parent = row
    
    local catLabel = Instance.new("TextLabel")
    catLabel.Size = UDim2.new(0, 80, 1, 0)
    catLabel.Position = UDim2.new(0, 73, 0, 0)
    catLabel.BackgroundTransparency = 1
    catLabel.Text = "[" .. log.Category .. "]"
    catLabel.TextColor3 = self.Theme.Purple
    catLabel.TextXAlignment = Enum.TextXAlignment.Left
    catLabel.Font = Enum.Font.GothamBold
    catLabel.TextSize = 10
    catLabel.Parent = row
    
    local msgLabel = Instance.new("TextLabel")
    msgLabel.Size = UDim2.new(1, -163, 1, 0)
    msgLabel.Position = UDim2.new(0, 158, 0, 0)
    msgLabel.BackgroundTransparency = 1
    msgLabel.Text = log.Message
    msgLabel.TextColor3 = self.Theme.Text
    msgLabel.TextXAlignment = Enum.TextXAlignment.Left
    msgLabel.Font = Enum.Font.Gotham
    msgLabel.TextSize = 10
    msgLabel.TextTruncate = Enum.TextTruncate.AtEnd
    msgLabel.Parent = row
end

function ShakaLogger:CreateButton(card, text, color, xPos, yPos, width, height)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, width, 0, height)
    btn.Position = UDim2.new(1, xPos, 0, yPos)
    btn.BackgroundColor3 = color
    btn.Text = text
    btn.TextColor3 = self.Theme.Text
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 10
    btn.BorderSizePixel = 0
    btn.AutoButtonColor = false
    btn.Parent = card
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 5)
    corner.Parent = btn
    
    btn.MouseEnter:Connect(function()
        btn.BackgroundColor3 = Color3.fromRGB(
            math.min(255, color.R * 255 + 20),
            math.min(255, color.G * 255 + 20),
            math.min(255, color.B * 255 + 20)
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
    self.IsOpen = not self.IsOpen
    if self.MainFrame then
        if self.IsOpen then
            self.MainFrame.Visible = true
            self.MainFrame.Size = UDim2.new(0, 0, 0, 0)
            TweenService:Create(self.MainFrame, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
                Size = UDim2.new(0, 900, 0, 620)
            }):Play()
            task.wait(0.1)
            self:RefreshCurrentTab()
        else
            TweenService:Create(self.MainFrame, TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.In), {
                Size = UDim2.new(0, 0, 0, 0)
            }):Play()
            task.wait(0.2)
            self.MainFrame.Visible = false
        end
    end
end

function ShakaLogger:SetupKeybind()
    UserInputService.InputBegan:Connect(function(input, processed)
        if not processed and input.KeyCode == self.OpenKey then
            self:Toggle()
        end
    end)
end

--═══════════════════════════════════════════════════════════
-- INICIALIZAÇÃO
--═══════════════════════════════════════════════════════════

function ShakaLogger:Init()
    print("\n" .. string.rep("═", 70))
    print("⚡ SHAKA LOGGER v1.3 - ANTI-CRASH")
    print("   Event Capture & Replay System")
    print(string.rep("═", 70))
    
    self:CreateUI()
    print("[SHAKA] ✅ UI criada")
    
    self:SetupKeybind()
    print("[SHAKA] ⌨️ Keybind [F] configurado")
    
    task.wait(0.5)
    self:HookAllRemotes()
    
    task.wait(0.3)
    self:MonitorCharacter()
    
    task.wait(0.2)
    self:MonitorInputs()
    
    task.wait(0.2)
    self:MonitorNetwork()
    
    task.wait(1)
    self:Toggle()
    self:SwitchTab("Settings")
    
    print("[SHAKA] ✅ Inicializado!")
    print("")
    print("⚙️ IMPORTANTE: Ative as capturas em Settings!")
    print("⌨️ Pressione [F] para abrir/fechar")
    print(string.rep("═", 70) .. "\n")
end

-- Auto-init
task.spawn(function()
    if not game:IsLoaded() then
        game.Loaded:Wait()
    end
    task.wait(3)
    
    ShakaLogger:Init()
end)

getgenv().ShakaLogger = ShakaLogger
_G.ShakaLogger = ShakaLogger

return ShakaLogger
