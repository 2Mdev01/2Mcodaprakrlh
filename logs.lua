-- SHAKA LOGGER v1.0
-- Sistema avançado de logging com replay e filtros
-- Tema: Preto e Roxo
-- APENAS para pentest autorizado

local ShakaLogger = {}

-- Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")
local TweenService = game:GetService("TweenService")

-- Configurações
ShakaLogger.OpenKey = Enum.KeyCode.F
ShakaLogger.IsOpen = false
ShakaLogger.CurrentTab = "Replay"

-- Dados
ShakaLogger.CapturedEvents = {}
ShakaLogger.BlockedEvents = {} -- Lista de eventos bloqueados
ShakaLogger.Logs = {
    Remote = {},
    Character = {},
    Input = {},
    Network = {},
    System = {}
}

-- Configurações de Filtros (ativar/desativar categorias)
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

ShakaLogger.HookedRemotes = {}

--═══════════════════════════════════════════════════════════
-- SISTEMA DE LOG COM FILTROS
--═══════════════════════════════════════════════════════════

function ShakaLogger:AddLog(category, message, data)
    -- Verificar se a categoria está ativa
    if not self.FilterSettings[category] then
        return
    end
    
    local log = {
        Time = os.date("%H:%M:%S"),
        Category = category,
        Message = message,
        Data = data or {},
        ID = tick()
    }
    
    -- Adicionar ao log da categoria
    if not self.Logs[category] then
        self.Logs[category] = {}
    end
    
    table.insert(self.Logs[category], 1, log)
    
    -- Limitar logs por categoria
    if #self.Logs[category] > 100 then
        table.remove(self.Logs[category])
    end
    
    -- Atualizar stats
    self.Stats.Total = self.Stats.Total + 1
    self.Stats[category] = (self.Stats[category] or 0) + 1
    
    print(string.format("[SHAKA] [%s] [%s] %s", log.Time, category, message))
    
    -- Atualizar UI se estiver na aba correta
    if self.IsOpen and self.CurrentTab == "Logs" then
        task.spawn(function()
            pcall(function() self:RefreshCurrentTab() end)
        end)
    end
end

function ShakaLogger:IsEventBlocked(remoteName)
    return self.BlockedEvents[remoteName] == true
end

function ShakaLogger:BlockEvent(remoteName)
    self.BlockedEvents[remoteName] = true
    self.Stats.Blocked = self.Stats.Blocked + 1
    self:AddLog("System", "🚫 Evento bloqueado: " .. remoteName)
end

function ShakaLogger:UnblockEvent(remoteName)
    self.BlockedEvents[remoteName] = nil
    self.Stats.Blocked = math.max(0, self.Stats.Blocked - 1)
    self:AddLog("System", "✅ Evento desbloqueado: " .. remoteName)
end

--═══════════════════════════════════════════════════════════
-- SISTEMA DE CAPTURA DE EVENTOS
--═══════════════════════════════════════════════════════════

function ShakaLogger:CaptureRemoteEvent(remote, eventType, args)
    local remoteName = remote.Name
    
    -- Verificar se está bloqueado
    if self:IsEventBlocked(remoteName) then
        return
    end
    
    local eventData = {
        Name = remoteName,
        Type = eventType,
        Path = remote:GetFullName(),
        Remote = remote,
        Args = args,
        Time = os.date("%H:%M:%S"),
        Timestamp = tick(),
        ID = #self.CapturedEvents + 1,
        IsBlocked = false
    }
    
    -- Adicionar à lista
    table.insert(self.CapturedEvents, 1, eventData)
    
    -- Limitar tamanho
    if #self.CapturedEvents > 100 then
        table.remove(self.CapturedEvents)
    end
    
    self.Stats.Captured = #self.CapturedEvents
    self.Stats.Remote = self.Stats.Remote + 1
    
    -- Log detalhado
    local argsStr = self:FormatArgs(args)
    self:AddLog("Remote", string.format("📡 %s [%s] %s", remoteName, eventType, argsStr), eventData)
    
    -- Atualizar UI de replay
    if self.IsOpen and self.CurrentTab == "Replay" then
        task.spawn(function()
            pcall(function() self:RefreshCurrentTab() end)
        end)
    end
    
    return eventData
end

function ShakaLogger:FormatArgs(args)
    if #args == 0 then return "{}" end
    
    local result = "{"
    for i, arg in ipairs(args) do
        if i > 5 then
            result = result .. "..."
            break
        end
        
        local argStr
        if type(arg) == "string" then
            argStr = '"' .. tostring(arg):sub(1, 30) .. '"'
        elseif type(arg) == "table" then
            argStr = "{...}"
        else
            argStr = tostring(arg):sub(1, 30)
        end
        
        result = result .. argStr
        if i < #args and i < 5 then
            result = result .. ", "
        end
    end
    return result .. "}"
end

--═══════════════════════════════════════════════════════════
-- HOOK GLOBAL DE REMOTES
--═══════════════════════════════════════════════════════════

function ShakaLogger:HookAllRemotes()
    local oldNamecall
    oldNamecall = hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
        local method = getnamecallmethod()
        local args = {...}
        
        -- Capturar FireServer
        if method == "FireServer" and typeof(self) == "Instance" then
            if self:IsA("RemoteEvent") then
                task.spawn(function()
                    ShakaLogger:CaptureRemoteEvent(self, "RemoteEvent", args)
                end)
            end
        end
        
        -- Capturar InvokeServer
        if method == "InvokeServer" and typeof(self) == "Instance" then
            if self:IsA("RemoteFunction") then
                task.spawn(function()
                    ShakaLogger:CaptureRemoteEvent(self, "RemoteFunction", args)
                end)
            end
        end
        
        return oldNamecall(self, ...)
    end))
    
    self:AddLog("System", "✅ Hook global instalado - Capturando todos os remotes!")
end

--═══════════════════════════════════════════════════════════
-- MONITORAMENTO DE CHARACTER
--═══════════════════════════════════════════════════════════

function ShakaLogger:MonitorCharacter()
    local lastPos = nil
    local lastHealth = nil
    
    RunService.Heartbeat:Connect(function()
        if not self.FilterSettings.Character then return end
        
        local player = Players.LocalPlayer
        if not player or not player.Character then return end
        
        local root = player.Character:FindFirstChild("HumanoidRootPart")
        local humanoid = player.Character:FindFirstChild("Humanoid")
        
        -- Monitorar posição
        if root then
            local currentPos = root.Position
            if lastPos then
                local dist = (currentPos - lastPos).Magnitude
                if dist > 10 then
                    self:AddLog("Character", string.format("🎯 Movimento: %.1f studs", dist))
                end
            end
            lastPos = currentPos
        end
        
        -- Monitorar saúde
        if humanoid then
            local currentHealth = humanoid.Health
            if lastHealth and currentHealth ~= lastHealth then
                local change = currentHealth - lastHealth
                local emoji = change > 0 and "💚" or "❤️"
                self:AddLog("Character", string.format("%s Saúde: %.1f (Δ%.1f)", emoji, currentHealth, change))
            end
            lastHealth = currentHealth
        end
    end)
    
    self:AddLog("System", "✅ Monitoramento de Character ativo")
end

--═══════════════════════════════════════════════════════════
-- MONITORAMENTO DE INPUT
--═══════════════════════════════════════════════════════════

function ShakaLogger:MonitorInputs()
    UserInputService.InputBegan:Connect(function(input, processed)
        if not self.FilterSettings.Input or processed then return end
        
        if input.UserInputType == Enum.UserInputType.Keyboard then
            self:AddLog("Input", "⌨️ Tecla: " .. input.KeyCode.Name)
        elseif input.UserInputType == Enum.UserInputType.MouseButton1 then
            self:AddLog("Input", "🖱️ Clique Esquerdo")
        elseif input.UserInputType == Enum.UserInputType.MouseButton2 then
            self:AddLog("Input", "🖱️ Clique Direito")
        end
    end)
    
    self:AddLog("System", "✅ Monitoramento de Input ativo")
end

--═══════════════════════════════════════════════════════════
-- MONITORAMENTO DE NETWORK
--═══════════════════════════════════════════════════════════

function ShakaLogger:MonitorNetwork()
    Players.PlayerAdded:Connect(function(player)
        if not self.FilterSettings.Network then return end
        self:AddLog("Network", "👤 " .. player.Name .. " entrou")
    end)
    
    Players.PlayerRemoving:Connect(function(player)
        if not self.FilterSettings.Network then return end
        self:AddLog("Network", "👋 " .. player.Name .. " saiu")
    end)
    
    self:AddLog("System", "✅ Monitoramento de Network ativo")
end

--═══════════════════════════════════════════════════════════
-- SISTEMA DE REPLAY
--═══════════════════════════════════════════════════════════

function ShakaLogger:ReplayEvent(eventData, times)
    times = times or 1
    local successCount = 0
    
    for i = 1, times do
        local success = pcall(function()
            if eventData.Type == "RemoteEvent" then
                eventData.Remote:FireServer(unpack(eventData.Args))
            elseif eventData.Type == "RemoteFunction" then
                eventData.Remote:InvokeServer(unpack(eventData.Args))
            end
        end)
        
        if success then successCount = successCount + 1 end
        if times > 1 then task.wait(0.05) end
    end
    
    self:AddLog("System", string.format("🔄 REPLAY: %s [%dx] - %d sucesso(s)", 
        eventData.Name, times, successCount))
    
    return successCount
end

function ShakaLogger:ToggleLoop(eventData)
    if eventData.IsLooping then
        eventData.IsLooping = false
        self:AddLog("System", "⏹️ Loop parado: " .. eventData.Name)
        return false
    end
    
    eventData.IsLooping = true
    self:AddLog("System", "🔁 Loop iniciado: " .. eventData.Name)
    
    task.spawn(function()
        while eventData.IsLooping do
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
-- INTERFACE DO USUÁRIO (TEMA PRETO E ROXO)
--═══════════════════════════════════════════════════════════

function ShakaLogger:CreateUI()
    -- Limpar UI antiga
    pcall(function()
        if game:GetService("CoreGui"):FindFirstChild("ShakaLogger") then
            game:GetService("CoreGui"):FindFirstChild("ShakaLogger"):Destroy()
        end
    end)
    
    -- Criar ScreenGui
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
    
    -- Tema Preto e Roxo
    local Theme = {
        Background = Color3.fromRGB(15, 15, 20),
        Header = Color3.fromRGB(25, 20, 35),
        Card = Color3.fromRGB(30, 25, 40),
        Tab = Color3.fromRGB(40, 35, 50),
        TabActive = Color3.fromRGB(138, 43, 226), -- Roxo
        Purple = Color3.fromRGB(138, 43, 226),
        PurpleDark = Color3.fromRGB(100, 30, 180),
        PurpleLight = Color3.fromRGB(186, 85, 211),
        Text = Color3.fromRGB(255, 255, 255),
        TextSecondary = Color3.fromRGB(180, 180, 200),
        Success = Color3.fromRGB(76, 175, 80),
        Warning = Color3.fromRGB(255, 152, 0),
        Danger = Color3.fromRGB(244, 67, 54),
        Accent = Color3.fromRGB(138, 43, 226)
    }
    
    self.Theme = Theme
    
    -- Main Frame
    local main = Instance.new("Frame")
    main.Name = "Main"
    main.Size = UDim2.new(0, 850, 0, 600)
    main.Position = UDim2.new(0.5, -425, 0.5, -300)
    main.BackgroundColor3 = Theme.Background
    main.BorderSizePixel = 0
    main.Visible = false
    main.Parent = gui
    
    self.MainFrame = main
    
    -- Borda roxa brilhante
    local border = Instance.new("UIStroke")
    border.Color = Theme.Purple
    border.Thickness = 2
    border.Transparency = 0.3
    border.Parent = main
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 12)
    corner.Parent = main
    
    -- Header
    local header = Instance.new("Frame")
    header.Size = UDim2.new(1, 0, 0, 50)
    header.BackgroundColor3 = Theme.Header
    header.BorderSizePixel = 0
    header.Parent = main
    
    local headerCorner = Instance.new("UICorner")
    headerCorner.CornerRadius = UDim.new(0, 12)
    headerCorner.Parent = header
    
    -- Barra roxa no topo
    local topBar = Instance.new("Frame")
    topBar.Size = UDim2.new(1, 0, 0, 3)
    topBar.BackgroundColor3 = Theme.Purple
    topBar.BorderSizePixel = 0
    topBar.Parent = header
    
    local topBarCorner = Instance.new("UICorner")
    topBarCorner.CornerRadius = UDim.new(0, 12)
    topBarCorner.Parent = topBar
    
    -- Logo e Título
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, -120, 1, 0)
    title.Position = UDim2.new(0, 20, 0, 0)
    title.BackgroundTransparency = 1
    title.Text = "⚡ SHAKA LOGGER"
    title.TextColor3 = Theme.Purple
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Font = Enum.Font.GothamBold
    title.TextSize = 20
    title.Parent = header
    
    -- Efeito de brilho no título
    local titleGlow = Instance.new("UIStroke")
    titleGlow.Color = Theme.Purple
    titleGlow.Thickness = 1
    titleGlow.Transparency = 0.5
    titleGlow.Parent = title
    
    local subtitle = Instance.new("TextLabel")
    subtitle.Size = UDim2.new(1, -120, 0, 15)
    subtitle.Position = UDim2.new(0, 20, 1, -18)
    subtitle.BackgroundTransparency = 1
    subtitle.Text = "Advanced Event Capture & Replay System"
    subtitle.TextColor3 = Theme.TextSecondary
    subtitle.TextXAlignment = Enum.TextXAlignment.Left
    subtitle.Font = Enum.Font.Gotham
    subtitle.TextSize = 10
    subtitle.Parent = header
    
    -- Botão Fechar
    local closeBtn = Instance.new("TextButton")
    closeBtn.Size = UDim2.new(0, 90, 0, 30)
    closeBtn.Position = UDim2.new(1, -100, 0.5, -15)
    closeBtn.BackgroundColor3 = Theme.Danger
    closeBtn.Text = "✖ FECHAR [F]"
    closeBtn.TextColor3 = Theme.Text
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.TextSize = 11
    closeBtn.BorderSizePixel = 0
    closeBtn.Parent = header
    
    local closeBtnCorner = Instance.new("UICorner")
    closeBtnCorner.CornerRadius = UDim.new(0, 6)
    closeBtnCorner.Parent = closeBtn
    
    closeBtn.MouseButton1Click:Connect(function()
        self:Toggle()
    end)
    
    -- Tabs Container
    local tabContainer = Instance.new("Frame")
    tabContainer.Size = UDim2.new(1, 0, 0, 45)
    tabContainer.Position = UDim2.new(0, 0, 0, 50)
    tabContainer.BackgroundColor3 = Theme.Tab
    tabContainer.BorderSizePixel = 0
    tabContainer.Parent = main
    
    local tabLayout = Instance.new("UIListLayout")
    tabLayout.FillDirection = Enum.FillDirection.Horizontal
    tabLayout.SortOrder = Enum.SortOrder.LayoutOrder
    tabLayout.Padding = UDim.new(0, 2)
    tabLayout.Parent = tabContainer
    
    -- Criar Tabs
    local tabs = {
        {Name = "Replay", Icon = "🔄", Desc = "Event Replay"},
        {Name = "Logs", Icon = "📝", Desc = "All Logs"},
        {Name = "Remote", Icon = "📡", Desc = "Remote Events"},
        {Name = "Character", Icon = "🎯", Desc = "Character"},
        {Name = "Input", Icon = "⌨️", Desc = "Inputs"},
        {Name = "Network", Icon = "🌐", Desc = "Network"},
        {Name = "Settings", Icon = "⚙️", Desc = "Configurações"}
    }
    
    self.TabButtons = {}
    
    for i, tab in ipairs(tabs) do
        local tabBtn = Instance.new("TextButton")
        tabBtn.Name = tab.Name
        tabBtn.Size = UDim2.new(0, 120, 1, 0)
        tabBtn.BackgroundColor3 = Theme.Tab
        tabBtn.BorderSizePixel = 0
        tabBtn.Text = tab.Icon .. " " .. tab.Name
        tabBtn.TextColor3 = Theme.TextSecondary
        tabBtn.Font = Enum.Font.GothamBold
        tabBtn.TextSize = 11
        tabBtn.Parent = tabContainer
        
        local tabCorner = Instance.new("UICorner")
        tabCorner.CornerRadius = UDim.new(0, 0)
        tabCorner.Parent = tabBtn
        
        tabBtn.MouseButton1Click:Connect(function()
            self:SwitchTab(tab.Name)
        end)
        
        self.TabButtons[tab.Name] = tabBtn
    end
    
    -- Content Area
    local content = Instance.new("Frame")
    content.Name = "Content"
    content.Size = UDim2.new(1, -20, 1, -110)
    content.Position = UDim2.new(0, 10, 0, 100)
    content.BackgroundTransparency = 1
    content.Parent = main
    
    self.ContentArea = content
    
    -- Criar frames para cada tab
    self.ContentFrames = {}
    
    for _, tab in ipairs(tabs) do
        local frame = Instance.new("ScrollingFrame")
        frame.Name = tab.Name .. "Frame"
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
        
        self.ContentFrames[tab.Name] = frame
    end
    
    self:AddLog("System", "✅ Interface SHAKA LOGGER criada!")
end

function ShakaLogger:SwitchTab(tabName)
    self.CurrentTab = tabName
    
    -- Animar transição de tabs
    for name, btn in pairs(self.TabButtons) do
        if name == tabName then
            btn.BackgroundColor3 = self.Theme.TabActive
            btn.TextColor3 = self.Theme.Text
            
            -- Adicionar borda roxa
            local stroke = btn:FindFirstChild("UIStroke") or Instance.new("UIStroke")
            stroke.Color = self.Theme.Purple
            stroke.Thickness = 2
            stroke.Parent = btn
        else
            btn.BackgroundColor3 = self.Theme.Tab
            btn.TextColor3 = self.Theme.TextSecondary
            
            -- Remover borda
            if btn:FindFirstChild("UIStroke") then
                btn:FindFirstChild("UIStroke"):Destroy()
            end
        end
    end
    
    -- Mostrar frame correto
    for name, frame in pairs(self.ContentFrames) do
        frame.Visible = (name == tabName)
    end
    
    -- Atualizar conteúdo
    self:RefreshCurrentTab()
end

function ShakaLogger:RefreshCurrentTab()
    local frame = self.ContentFrames[self.CurrentTab]
    if not frame then return end
    
    -- Limpar conteúdo
    for _, child in ipairs(frame:GetChildren()) do
        if not child:IsA("UIListLayout") then
            child:Destroy()
        end
    end
    
    -- Criar conteúdo baseado na tab
    if self.CurrentTab == "Replay" then
        self:CreateReplayContent(frame)
    elseif self.CurrentTab == "Logs" then
        self:CreateLogsContent(frame, "All")
    elseif self.CurrentTab == "Remote" then
        self:CreateLogsContent(frame, "Remote")
    elseif self.CurrentTab == "Character" then
        self:CreateLogsContent(frame, "Character")
    elseif self.CurrentTab == "Input" then
        self:CreateLogsContent(frame, "Input")
    elseif self.CurrentTab == "Network" then
        self:CreateLogsContent(frame, "Network")
    elseif self.CurrentTab == "Settings" then
        self:CreateSettingsContent(frame)
    end
end

--═══════════════════════════════════════════════════════════
-- CONTEÚDO DAS TABS
--═══════════════════════════════════════════════════════════

function ShakaLogger:CreateReplayContent(frame)
    -- Stats
    local statsCard = self:CreateCard(frame, "📊 ESTATÍSTICAS", 120)
    
    local statsData = {
        {"Total de Eventos", self.Stats.Total, self.Theme.Purple},
        {"Eventos Capturados", self.Stats.Captured, self.Theme.Success},
        {"Eventos Bloqueados", self.Stats.Blocked, self.Theme.Danger}
    }
    
    for i, stat in ipairs(statsData) do
        self:CreateStatRow(statsCard, stat[1], stat[2], stat[3], i * 30)
    end
    
    -- Eventos capturados
    if #self.CapturedEvents == 0 then
        local emptyCard = self:CreateCard(frame, "⚠️ NENHUM EVENTO CAPTURADO", 80)
        local emptyText = Instance.new("TextLabel")
        emptyText.Size = UDim2.new(1, -20, 0, 40)
        emptyText.Position = UDim2.new(0, 10, 0, 35)
        emptyText.BackgroundTransparency = 1
        emptyText.Text = "Interaja com o jogo para capturar eventos automaticamente"
        emptyText.TextColor3 = self.Theme.TextSecondary
        emptyText.Font = Enum.Font.Gotham
        emptyText.TextSize = 12
        emptyText.TextWrapped = true
        emptyText.Parent = emptyCard
        return
    end
    
    -- Lista de eventos
    for i, event in ipairs(self.CapturedEvents) do
        if i > 15 then break end
        self:CreateEventCard(frame, event)
    end
end

function ShakaLogger:CreateLogsContent(frame, category)
    local logs = {}
    
    if category == "All" then
        -- Combinar todos os logs
        for cat, catLogs in pairs(self.Logs) do
            for _, log in ipairs(catLogs) do
                table.insert(logs, log)
            end
        end
        -- Ordenar por timestamp
        table.sort(logs, function(a, b) return (a.ID or 0) > (b.ID or 0) end)
    else
        logs = self.Logs[category] or {}
    end
    
    if #logs == 0 then
        local emptyCard = self:CreateCard(frame, "📭 SEM LOGS", 60)
        return
    end
    
    -- Mostrar logs
    for i, log in ipairs(logs) do
        if i > 30 then break end
        self:CreateLogRow(frame, log)
    end
end

function ShakaLogger:CreateSettingsContent(frame)
    local card = self:CreateCard(frame, "⚙️ CONFIGURAÇÕES DE FILTROS", 300)
    
    local yPos = 40
    
    for category, enabled in pairs(self.FilterSettings) do
        local toggleBtn = self:CreateToggleButton(card, category, enabled, yPos)
        yPos = yPos + 40
    end
    
    -- Botão de limpar logs
    local clearBtn = self:CreateButton(card, "🗑️ LIMPAR TODOS OS LOGS", self.Theme.Danger, 10, yPos, 300, 35)
    clearBtn.MouseButton1Click:Connect(function()
        for cat in pairs(self.Logs) do
            self.Logs[cat] = {}
        end
        self.Stats = {Total = 0, Remote = 0, Character = 0, Input = 0, Network = 0, Captured = 0, Blocked = 0}
        self:AddLog("System", "🗑️ Todos os logs foram limpos!")
        self:RefreshCurrentTab()
    end)
    
    yPos = yPos + 45
    
    -- Botão de limpar eventos capturados
    local clearEventsBtn = self:CreateButton(card, "🗑️ LIMPAR EVENTOS CAPTURADOS", self.Theme.Warning, 10, yPos, 300, 35)
    clearEventsBtn.MouseButton1Click:Connect(function()
        self.CapturedEvents = {}
        self.Stats.Captured = 0
        self:AddLog("System", "🗑️ Eventos capturados limpos!")
        self:RefreshCurrentTab()
    end)
    
    yPos = yPos + 45
    
    -- Botão de desbloquear todos
    local unblockBtn = self:CreateButton(card, "✅ DESBLOQUEAR TODOS OS EVENTOS", self.Theme.Success, 10, yPos, 300, 35)
    unblockBtn.MouseButton1Click:Connect(function()
        self.BlockedEvents = {}
        self.Stats.Blocked = 0
        self:AddLog("System", "✅ Todos os eventos foram desbloqueados!")
    end)
end

--═══════════════════════════════════════════════════════════
-- COMPONENTES DE UI
--═══════════════════════════════════════════════════════════

function ShakaLogger:CreateCard(parent, title, height)
    local card = Instance.new("Frame")
    card.Size = UDim2.new(1, 0, 0, height)
    card.BackgroundColor3 = self.Theme.Card
    card.BorderSizePixel = 0
    card.Parent = parent
    
    local cardCorner = Instance.new("UICorner")
    cardCorner.CornerRadius = UDim.new(0, 8)
    cardCorner.Parent = card
    
    local cardBorder = Instance.new("UIStroke")
    cardBorder.Color = self.Theme.Purple
    cardBorder.Thickness = 1
    cardBorder.Transparency = 0.7
    cardBorder.Parent = card
    
    if title then
        local titleLabel = Instance.new("TextLabel")
        titleLabel.Size = UDim2.new(1, -20, 0, 30)
        titleLabel.Position = UDim2.new(0, 10, 0, 5)
        titleLabel.BackgroundTransparency = 1
        titleLabel.Text = title
        titleLabel.TextColor3 = self.Theme.Purple
        titleLabel.TextXAlignment = Enum.TextXAlignment.Left
        titleLabel.Font = Enum.Font.GothamBold
        titleLabel.TextSize = 13
        titleLabel.Parent = card
    end
    
    return card
end

function ShakaLogger:CreateStatRow(parent, label, value, color, yPos)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, -40, 0, 25)
    row.Position = UDim2.new(0, 20, 0, yPos)
    row.BackgroundTransparency = 1
    row.Parent = parent
    
    local labelText = Instance.new("TextLabel")
    labelText.Size = UDim2.new(0.7, 0, 1, 0)
    labelText.BackgroundTransparency = 1
    labelText.Text = label
    labelText.TextColor3 = self.Theme.TextSecondary
    labelText.TextXAlignment = Enum.TextXAlignment.Left
    labelText.Font = Enum.Font.Gotham
    labelText.TextSize = 12
    labelText.Parent = row
    
    local valueText = Instance.new("TextLabel")
    valueText.Size = UDim2.new(0.3, 0, 1, 0)
    valueText.Position = UDim2.new(0.7, 0, 0, 0)
    valueText.BackgroundTransparency = 1
    valueText.Text = tostring(value)
    valueText.TextColor3 = color
    valueText.TextXAlignment = Enum.TextXAlignment.Right
    valueText.Font = Enum.Font.GothamBold
    valueText.TextSize = 16
    valueText.Parent = row
end

function ShakaLogger:CreateEventCard(parent, event)
    local card = Instance.new("Frame")
    card.Size = UDim2.new(1, 0, 0, 110)
    card.BackgroundColor3 = self.Theme.Card
    card.BorderSizePixel = 0
    card.Parent = parent
    
    local cardCorner = Instance.new("UICorner")
    cardCorner.CornerRadius = UDim.new(0, 8)
    cardCorner.Parent = card
    
    local cardBorder = Instance.new("UIStroke")
    cardBorder.Color = self.Theme.Purple
    cardBorder.Thickness = 1
    cardBorder.Transparency = 0.7
    cardBorder.Parent = card
    
    -- Nome do evento
    local nameLabel = Instance.new("TextLabel")
    nameLabel.Size = UDim2.new(1, -340, 0, 22)
    nameLabel.Position = UDim2.new(0, 12, 0, 8)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text = "📡 " .. event.Name .. " [" .. event.Type .. "]"
    nameLabel.TextColor3 = self.Theme.PurpleLight
    nameLabel.TextXAlignment = Enum.TextXAlignment.Left
    nameLabel.Font = Enum.Font.GothamBold
    nameLabel.TextSize = 13
    nameLabel.TextTruncate = Enum.TextTruncate.AtEnd
    nameLabel.Parent = card
    
    -- Caminho
    local pathLabel = Instance.new("TextLabel")
    pathLabel.Size = UDim2.new(1, -340, 0, 18)
    pathLabel.Position = UDim2.new(0, 12, 0, 32)
    pathLabel.BackgroundTransparency = 1
    pathLabel.Text = "📁 " .. event.Path
    pathLabel.TextColor3 = self.Theme.TextSecondary
    pathLabel.TextXAlignment = Enum.TextXAlignment.Left
    pathLabel.Font = Enum.Font.Gotham
    pathLabel.TextSize = 9
    pathLabel.TextTruncate = Enum.TextTruncate.AtEnd
    pathLabel.Parent = card
    
    -- Args
    local argsLabel = Instance.new("TextLabel")
    argsLabel.Size = UDim2.new(1, -340, 0, 18)
    argsLabel.Position = UDim2.new(0, 12, 0, 52)
    argsLabel.BackgroundTransparency = 1
    argsLabel.Text = "Args: " .. self:FormatArgs(event.Args)
    argsLabel.TextColor3 = self.Theme.Warning
    argsLabel.TextXAlignment = Enum.TextXAlignment.Left
    argsLabel.Font = Enum.Font.Code
    argsLabel.TextSize = 9
    argsLabel.TextTruncate = Enum.TextTruncate.AtEnd
    argsLabel.Parent = card
    
    -- Tempo
    local timeLabel = Instance.new("TextLabel")
    timeLabel.Size = UDim2.new(1, -340, 0, 16)
    timeLabel.Position = UDim2.new(0, 12, 0, 72)
    timeLabel.BackgroundTransparency = 1
    timeLabel.Text = "🕐 " .. event.Time
    timeLabel.TextColor3 = self.Theme.TextSecondary
    timeLabel.TextXAlignment = Enum.TextXAlignment.Left
    timeLabel.Font = Enum.Font.Gotham
    timeLabel.TextSize = 9
    timeLabel.Parent = card
    
    -- Botões
    local btnY = 8
    local btnSpacing = 34
    
    -- Replay 1x
    local btn1 = self:CreateButton(card, "▶️ x1", self.Theme.Success, -328, btnY, 70, 28)
    btn1.MouseButton1Click:Connect(function()
        self:ReplayEvent(event, 1)
    end)
    
    -- Replay 5x
    local btn5 = self:CreateButton(card, "⚡ x5", self.Theme.Purple, -328, btnY + btnSpacing, 70, 28)
    btn5.MouseButton1Click:Connect(function()
        self:ReplayEvent(event, 5)
    end)
    
    -- Replay 10x
    local btn10 = self:CreateButton(card, "🔥 x10", self.Theme.Warning, -328, btnY + btnSpacing * 2, 70, 28)
    btn10.MouseButton1Click:Connect(function()
        self:ReplayEvent(event, 10)
    end)
    
    -- Custom
    local btnCustom = self:CreateButton(card, "⚙️ x?", self.Theme.Tab, -252, btnY, 70, 28)
    btnCustom.MouseButton1Click:Connect(function()
        local times = tonumber(prompt and prompt("Quantas vezes repetir?", "1") or "1")
        if times and times > 0 then
            self:ReplayEvent(event, times)
        end
    end)
    
    -- Loop
    local btnLoop = self:CreateButton(card, event.IsLooping and "⏹️ STOP" or "🔁 LOOP", 
        event.IsLooping and self.Theme.Danger or Color3.fromRGB(138, 43, 226), 
        -252, btnY + btnSpacing, 70, 28)
    btnLoop.MouseButton1Click:Connect(function()
        local isLooping = self:ToggleLoop(event)
        btnLoop.Text = isLooping and "⏹️ STOP" or "🔁 LOOP"
        btnLoop.BackgroundColor3 = isLooping and self.Theme.Danger or Color3.fromRGB(138, 43, 226)
    end)
    
    -- Bloquear
    local btnBlock = self:CreateButton(card, "🚫 BLOC", self.Theme.Danger, -252, btnY + btnSpacing * 2, 70, 28)
    btnBlock.MouseButton1Click:Connect(function()
        self:BlockEvent(event.Name)
        self:RefreshCurrentTab()
    end)
    
    -- Info
    local btnInfo = self:CreateButton(card, "ℹ️ INFO", Color3.fromRGB(60, 60, 80), -176, btnY, 70, 28)
    btnInfo.MouseButton1Click:Connect(function()
        local info = string.format(
            "\n" .. string.rep("═", 60) .. "\n" ..
            "📋 INFORMAÇÕES DO EVENTO\n" ..
            string.rep("═", 60) .. "\n" ..
            "Nome: %s\n" ..
            "Tipo: %s\n" ..
            "Hora: %s\n" ..
            "Caminho: %s\n\n" ..
            "Argumentos (JSON):\n%s\n" ..
            string.rep("═", 60) .. "\n",
            event.Name,
            event.Type,
            event.Time,
            event.Path,
            HttpService:JSONEncode(event.Args)
        )
        print(info)
        self:AddLog("System", "ℹ️ Info do evento " .. event.Name .. " printada no console")
    end)
    
    -- Copiar Args
    local btnCopy = self:CreateButton(card, "📋 COPY", self.Theme.Accent, -176, btnY + btnSpacing, 70, 28)
    btnCopy.MouseButton1Click:Connect(function()
        local argsJson = HttpService:JSONEncode(event.Args)
        setclipboard(argsJson)
        self:AddLog("System", "📋 Args copiados: " .. event.Name)
    end)
    
    -- Status bloqueado
    if self:IsEventBlocked(event.Name) then
        local blockedLabel = Instance.new("TextLabel")
        blockedLabel.Size = UDim2.new(0, 60, 0, 20)
        blockedLabel.Position = UDim2.new(0, 12, 0, 88)
        blockedLabel.BackgroundColor3 = self.Theme.Danger
        blockedLabel.Text = "🚫 BLOCKED"
        blockedLabel.TextColor3 = self.Theme.Text
        blockedLabel.Font = Enum.Font.GothamBold
        blockedLabel.TextSize = 9
        blockedLabel.BorderSizePixel = 0
        blockedLabel.Parent = card
        
        local blockedCorner = Instance.new("UICorner")
        blockedCorner.CornerRadius = UDim.new(0, 4)
        blockedCorner.Parent = blockedLabel
    end
end

function ShakaLogger:CreateLogRow(parent, log)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, 0, 0, 35)
    row.BackgroundColor3 = self.Theme.Card
    row.BorderSizePixel = 0
    row.Parent = parent
    
    local rowCorner = Instance.new("UICorner")
    rowCorner.CornerRadius = UDim.new(0, 6)
    rowCorner.Parent = row
    
    local rowBorder = Instance.new("UIStroke")
    rowBorder.Color = self.Theme.Purple
    rowBorder.Thickness = 1
    rowBorder.Transparency = 0.8
    rowBorder.Parent = row
    
    -- Hora
    local timeLabel = Instance.new("TextLabel")
    timeLabel.Size = UDim2.new(0, 65, 1, 0)
    timeLabel.Position = UDim2.new(0, 8, 0, 0)
    timeLabel.BackgroundTransparency = 1
    timeLabel.Text = log.Time
    timeLabel.TextColor3 = self.Theme.TextSecondary
    timeLabel.TextXAlignment = Enum.TextXAlignment.Left
    timeLabel.Font = Enum.Font.Code
    timeLabel.TextSize = 10
    timeLabel.Parent = row
    
    -- Categoria
    local catLabel = Instance.new("TextLabel")
    catLabel.Size = UDim2.new(0, 80, 1, 0)
    catLabel.Position = UDim2.new(0, 78, 0, 0)
    catLabel.BackgroundTransparency = 1
    catLabel.Text = "[" .. log.Category .. "]"
    catLabel.TextColor3 = self.Theme.Purple
    catLabel.TextXAlignment = Enum.TextXAlignment.Left
    catLabel.Font = Enum.Font.GothamBold
    catLabel.TextSize = 10
    catLabel.Parent = row
    
    -- Mensagem
    local msgLabel = Instance.new("TextLabel")
    msgLabel.Size = UDim2.new(1, -165, 1, 0)
    msgLabel.Position = UDim2.new(0, 163, 0, 0)
    msgLabel.BackgroundTransparency = 1
    msgLabel.Text = log.Message
    msgLabel.TextColor3 = self.Theme.Text
    msgLabel.TextXAlignment = Enum.TextXAlignment.Left
    msgLabel.Font = Enum.Font.Gotham
    msgLabel.TextSize = 10
    msgLabel.TextTruncate = Enum.TextTruncate.AtEnd
    msgLabel.Parent = row
end

function ShakaLogger:CreateToggleButton(parent, category, enabled, yPos)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, -20, 0, 35)
    frame.Position = UDim2.new(0, 10, 0, yPos)
    frame.BackgroundColor3 = self.Theme.Tab
    frame.BorderSizePixel = 0
    frame.Parent = parent
    
    local frameCorner = Instance.new("UICorner")
    frameCorner.CornerRadius = UDim.new(0, 6)
    frameCorner.Parent = frame
    
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -100, 1, 0)
    label.Position = UDim2.new(0, 15, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = "📊 " .. category .. " Logs"
    label.TextColor3 = self.Theme.Text
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Font = Enum.Font.Gotham
    label.TextSize = 12
    label.Parent = frame
    
    local toggleBtn = Instance.new("TextButton")
    toggleBtn.Size = UDim2.new(0, 70, 0, 25)
    toggleBtn.Position = UDim2.new(1, -80, 0.5, -12)
    toggleBtn.BackgroundColor3 = enabled and self.Theme.Success or self.Theme.Danger
    toggleBtn.Text = enabled and "✓ ON" or "✗ OFF"
    toggleBtn.TextColor3 = self.Theme.Text
    toggleBtn.Font = Enum.Font.GothamBold
    toggleBtn.TextSize = 11
    toggleBtn.BorderSizePixel = 0
    toggleBtn.Parent = frame
    
    local toggleCorner = Instance.new("UICorner")
    toggleCorner.CornerRadius = UDim.new(0, 4)
    toggleCorner.Parent = toggleBtn
    
    toggleBtn.MouseButton1Click:Connect(function()
        self.FilterSettings[category] = not self.FilterSettings[category]
        local isEnabled = self.FilterSettings[category]
        toggleBtn.BackgroundColor3 = isEnabled and self.Theme.Success or self.Theme.Danger
        toggleBtn.Text = isEnabled and "✓ ON" or "✗ OFF"
        self:AddLog("System", string.format("%s logs %s", category, isEnabled and "ativados" or "desativados"))
    end)
    
    return frame
end

function ShakaLogger:CreateButton(parent, text, color, xPos, yPos, width, height)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, width, 0, height)
    btn.Position = UDim2.new(1, xPos, 0, yPos)
    btn.BackgroundColor3 = color
    btn.Text = text
    btn.TextColor3 = self.Theme.Text
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 10
    btn.BorderSizePixel = 0
    btn.Parent = parent
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 4)
    corner.Parent = btn
    
    -- Efeito hover
    btn.MouseEnter:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(
            math.min(255, color.R * 255 + 20),
            math.min(255, color.G * 255 + 20),
            math.min(255, color.B * 255 + 20)
        )}):Play()
    end)
    
    btn.MouseLeave:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.2), {BackgroundColor3 = color}):Play()
    end)
    
    return btn
end

--═══════════════════════════════════════════════════════════
-- CONTROLES
--═══════════════════════════════════════════════════════════

function ShakaLogger:Toggle()
    self.IsOpen = not self.IsOpen
    if self.MainFrame then
        -- Animação suave
        if self.IsOpen then
            self.MainFrame.Visible = true
            self.MainFrame.Size = UDim2.new(0, 0, 0, 0)
            TweenService:Create(self.MainFrame, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
                Size = UDim2.new(0, 850, 0, 600)
            }):Play()
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
    print("⚡ SHAKA LOGGER v1.0")
    print("   Advanced Event Capture & Replay System")
    print("   Tema: Preto e Roxo")
    print(string.rep("═", 70))
    
    -- Criar UI
    self:CreateUI()
    self:AddLog("System", "✅ SHAKA LOGGER UI criada com sucesso!")
    
    -- Configurar keybind
    self:SetupKeybind()
    self:AddLog("System", "⌨️ Keybind [F] configurado - Pressione F para abrir/fechar")
    
    -- Hook global
    task.wait(0.5)
    self:HookAllRemotes()
    
    -- Iniciar monitoramentos
    task.wait(0.3)
    self:MonitorCharacter()
    
    task.wait(0.2)
    self:MonitorInputs()
    
    task.wait(0.2)
    self:MonitorNetwork()
    
    -- Auto-abrir
    task.wait(1)
    self:Toggle()
    self:SwitchTab("Replay")
    
    print("✅ SHAKA LOGGER inicializado com sucesso!")
    print("⌨️ Pressione [F] para abrir/fechar o menu")
    print("🎯 Interaja com o jogo para capturar eventos")
    print("🚫 Use o botão BLOC para bloquear eventos spam")
    print("⚙️ Configure filtros na aba Settings")
    print(string.rep("═", 70) .. "\n")
end

-- Auto-inicialização
task.spawn(function()
    if not game:IsLoaded() then
        game.Loaded:Wait()
    end
    task.wait(3)
    
    ShakaLogger:Init()
end)

-- Global
getgenv().ShakaLogger = ShakaLogger
_G.ShakaLogger = ShakaLogger

-- Comandos úteis
print("\n📋 COMANDOS ÚTEIS:")
print("   _G.ShakaLogger:Toggle() - Abrir/Fechar menu")
print("   _G.ShakaLogger:BlockEvent('NomeDoEvento') - Bloquear evento")
print("   _G.ShakaLogger:UnblockEvent('NomeDoEvento') - Desbloquear evento")
print("")

return ShakaLogger
