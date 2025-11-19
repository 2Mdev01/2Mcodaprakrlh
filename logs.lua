-- SHAKA LOGGER v1.1 FIXED
-- Sistema avançado de logging com replay e filtros
-- Tema: Preto e Roxo | UI Melhorada
-- Correções: Hook funcional, bloqueio preciso, replay verificado

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
ShakaLogger.BlockedEvents = {} -- {[remotePath] = true}
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

ShakaLogger.HookedRemotes = {}

--═══════════════════════════════════════════════════════════
-- SISTEMA DE LOG
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
    
    if #self.Logs[category] > 100 then
        table.remove(self.Logs[category])
    end
    
    self.Stats.Total = self.Stats.Total + 1
    self.Stats[category] = (self.Stats[category] or 0) + 1
    
    print(string.format("[SHAKA] [%s] [%s] %s", log.Time, category, message))
    
    if self.IsOpen and self.CurrentTab == "Logs" then
        task.spawn(function()
            pcall(function() self:RefreshCurrentTab() end)
        end)
    end
end

function ShakaLogger:IsEventBlocked(remotePath)
    return self.BlockedEvents[remotePath] == true
end

function ShakaLogger:BlockEvent(remotePath)
    self.BlockedEvents[remotePath] = true
    self.Stats.Blocked = self.Stats.Blocked + 1
    self:AddLog("System", "🚫 Evento bloqueado: " .. remotePath)
end

function ShakaLogger:UnblockEvent(remotePath)
    if self.BlockedEvents[remotePath] then
        self.BlockedEvents[remotePath] = nil
        self.Stats.Blocked = math.max(0, self.Stats.Blocked - 1)
        self:AddLog("System", "✅ Evento desbloqueado: " .. remotePath)
    end
end

--═══════════════════════════════════════════════════════════
-- SISTEMA DE CAPTURA - CORRIGIDO
--═══════════════════════════════════════════════════════════

function ShakaLogger:CaptureRemoteEvent(remote, eventType, args)
    local remotePath = remote:GetFullName()
    
    -- Capturar SEMPRE (mesmo se bloqueado, para mostrar tentativas)
    local eventData = {
        Name = remote.Name,
        Type = eventType,
        Path = remotePath,
        Remote = remote,
        Args = args,
        Time = os.date("%H:%M:%S"),
        Timestamp = tick(),
        ID = #self.CapturedEvents + 1,
        IsBlocked = self:IsEventBlocked(remotePath)
    }
    
    table.insert(self.CapturedEvents, 1, eventData)
    
    if #self.CapturedEvents > 100 then
        table.remove(self.CapturedEvents)
    end
    
    self.Stats.Captured = #self.CapturedEvents
    self.Stats.Remote = self.Stats.Remote + 1
    
    -- Log com indicação de bloqueio
    local argsStr = self:FormatArgs(args)
    local status = eventData.IsBlocked and "🚫 BLOQUEADO" or "✅ EXECUTADO"
    self:AddLog("Remote", string.format("%s 📡 %s [%s] %s", status, remote.Name, eventType, argsStr), eventData)
    
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
-- HOOK GLOBAL - CORRIGIDO
--═══════════════════════════════════════════════════════════

function ShakaLogger:HookAllRemotes()
    local oldNamecall
    oldNamecall = hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
        local method = getnamecallmethod()
        local args = {...}
        
        if typeof(self) == "Instance" then
            local remotePath = self:GetFullName()
            
            -- Capturar FireServer
            if method == "FireServer" and self:IsA("RemoteEvent") then
                task.spawn(function()
                    ShakaLogger:CaptureRemoteEvent(self, "RemoteEvent", args)
                end)
                
                -- BLOQUEAR se necessário
                if ShakaLogger:IsEventBlocked(remotePath) then
                    return -- NÃO executa o evento original
                end
            end
            
            -- Capturar InvokeServer
            if method == "InvokeServer" and self:IsA("RemoteFunction") then
                task.spawn(function()
                    ShakaLogger:CaptureRemoteEvent(self, "RemoteFunction", args)
                end)
                
                -- BLOQUEAR se necessário
                if ShakaLogger:IsEventBlocked(remotePath) then
                    return nil -- NÃO executa o evento original
                end
            end
        end
        
        return oldNamecall(self, ...)
    end))
    
    self:AddLog("System", "✅ Hook global instalado - Sistema de bloqueio ativo!")
end

--═══════════════════════════════════════════════════════════
-- MONITORAMENTO
--═══════════════════════════════════════════════════════════

function ShakaLogger:MonitorCharacter()
    local lastPos = nil
    local lastHealth = nil
    local checkInterval = 0.5
    local timeSinceLastCheck = 0
    
    RunService.Heartbeat:Connect(function(dt)
        if not self.FilterSettings.Character then return end
        
        timeSinceLastCheck = timeSinceLastCheck + dt
        if timeSinceLastCheck < checkInterval then return end
        timeSinceLastCheck = 0
        
        local player = Players.LocalPlayer
        if not player or not player.Character then return end
        
        local root = player.Character:FindFirstChild("HumanoidRootPart")
        local humanoid = player.Character:FindFirstChild("Humanoid")
        
        if root then
            local currentPos = root.Position
            if lastPos then
                local dist = (currentPos - lastPos).Magnitude
                if dist > 50 then
                    self:AddLog("Character", string.format("🎯 Movimento: %.1f studs", dist))
                end
            end
            lastPos = currentPos
        end
        
        if humanoid then
            local currentHealth = humanoid.Health
            if lastHealth and currentHealth ~= lastHealth then
                local change = currentHealth - lastHealth
                local emoji = change > 0 and "💚" or "❤️"
                self:AddLog("Character", string.format("%s Saúde: %.1f → %.1f (Δ%.1f)", 
                    emoji, lastHealth, currentHealth, change))
            end
            lastHealth = currentHealth
        end
    end)
    
    self:AddLog("System", "✅ Monitor de Character ativo")
end

function ShakaLogger:MonitorInputs()
    local lastInputTime = {}
    local inputCooldown = 0.5
    
    UserInputService.InputBegan:Connect(function(input, processed)
        if not self.FilterSettings.Input or processed then return end
        
        local inputName = tostring(input.KeyCode.Name or input.UserInputType.Name)
        local now = tick()
        
        if lastInputTime[inputName] and (now - lastInputTime[inputName]) < inputCooldown then
            return
        end
        lastInputTime[inputName] = now
        
        if input.UserInputType == Enum.UserInputType.Keyboard then
            self:AddLog("Input", "⌨️ Tecla: " .. input.KeyCode.Name)
        elseif input.UserInputType == Enum.UserInputType.MouseButton1 then
            self:AddLog("Input", "🖱️ Clique Esquerdo")
        elseif input.UserInputType == Enum.UserInputType.MouseButton2 then
            self:AddLog("Input", "🖱️ Clique Direito")
        end
    end)
    
    self:AddLog("System", "✅ Monitor de Input ativo")
end

function ShakaLogger:MonitorNetwork()
    Players.PlayerAdded:Connect(function(player)
        if not self.FilterSettings.Network then return end
        self:AddLog("Network", "👤 " .. player.Name .. " entrou no servidor")
    end)
    
    Players.PlayerRemoving:Connect(function(player)
        if not self.FilterSettings.Network then return end
        self:AddLog("Network", "👋 " .. player.Name .. " saiu do servidor")
    end)
    
    self:AddLog("System", "✅ Monitor de Network ativo")
end

--═══════════════════════════════════════════════════════════
-- SISTEMA DE REPLAY - CORRIGIDO
--═══════════════════════════════════════════════════════════

function ShakaLogger:ReplayEvent(eventData, times)
    times = times or 1
    local successCount = 0
    local errorMsg = nil
    
    -- Verificar se o remote ainda existe
    if not eventData.Remote or not eventData.Remote.Parent then
        self:AddLog("System", "❌ ERRO: Remote não existe mais no jogo!")
        return 0
    end
    
    for i = 1, times do
        local success, err = pcall(function()
            if eventData.Type == "RemoteEvent" then
                eventData.Remote:FireServer(unpack(eventData.Args))
            elseif eventData.Type == "RemoteFunction" then
                eventData.Remote:InvokeServer(unpack(eventData.Args))
            end
        end)
        
        if success then 
            successCount = successCount + 1 
        else
            errorMsg = err
        end
        
        if times > 1 then task.wait(0.05) end
    end
    
    if successCount > 0 then
        self:AddLog("System", string.format("✅ REPLAY: %s [%dx] - %d/%d sucesso", 
            eventData.Name, times, successCount, times))
    else
        self:AddLog("System", string.format("❌ REPLAY FALHOU: %s - %s", 
            eventData.Name, errorMsg or "Erro desconhecido"))
    end
    
    return successCount
end

function ShakaLogger:ToggleLoop(eventData)
    if eventData.IsLooping then
        eventData.IsLooping = false
        self:AddLog("System", "⏹️ Loop parado: " .. eventData.Name)
        return false
    end
    
    -- Verificar se o remote existe
    if not eventData.Remote or not eventData.Remote.Parent then
        self:AddLog("System", "❌ ERRO: Remote não existe mais!")
        return false
    end
    
    eventData.IsLooping = true
    self:AddLog("System", "🔁 Loop iniciado: " .. eventData.Name .. " (0.5s)")
    
    task.spawn(function()
        while eventData.IsLooping do
            if not eventData.Remote or not eventData.Remote.Parent then
                eventData.IsLooping = false
                ShakaLogger:AddLog("System", "⚠️ Loop interrompido: Remote removido")
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
-- INTERFACE - MELHORADA
--═══════════════════════════════════════════════════════════

function ShakaLogger:CreateUI()
    pcall(function()
        if game:GetService("CoreGui"):FindFirstChild("ShakaLogger") then
            game:GetService("CoreGui"):FindFirstChild("ShakaLogger"):Destroy()
        end
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
    
    -- Tema melhorado
    local Theme = {
        Background = Color3.fromRGB(18, 18, 24),
        Header = Color3.fromRGB(28, 24, 38),
        Card = Color3.fromRGB(32, 28, 42),
        Tab = Color3.fromRGB(42, 38, 52),
        TabActive = Color3.fromRGB(148, 53, 236),
        Purple = Color3.fromRGB(148, 53, 236),
        PurpleDark = Color3.fromRGB(110, 35, 190),
        PurpleLight = Color3.fromRGB(196, 95, 221),
        Text = Color3.fromRGB(255, 255, 255),
        TextSecondary = Color3.fromRGB(190, 190, 210),
        Success = Color3.fromRGB(46, 204, 113),
        Warning = Color3.fromRGB(255, 165, 0),
        Danger = Color3.fromRGB(231, 76, 60),
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
    
    -- Sombra
    local shadow = Instance.new("ImageLabel")
    shadow.Name = "Shadow"
    shadow.Size = UDim2.new(1, 30, 1, 30)
    shadow.Position = UDim2.new(0, -15, 0, -15)
    shadow.BackgroundTransparency = 1
    shadow.Image = "rbxasset://textures/ui/GuiImagePlaceholder.png"
    shadow.ImageColor3 = Color3.fromRGB(0, 0, 0)
    shadow.ImageTransparency = 0.5
    shadow.ScaleType = Enum.ScaleType.Slice
    shadow.SliceCenter = Rect.new(10, 10, 10, 10)
    shadow.ZIndex = 0
    shadow.Parent = main
    
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
    
    local topBarGradient = Instance.new("UIGradient")
    topBarGradient.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, Theme.Purple),
        ColorSequenceKeypoint.new(0.5, Theme.PurpleLight),
        ColorSequenceKeypoint.new(1, Theme.Purple)
    }
    topBarGradient.Parent = topBar
    
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
    
    local titleGlow = Instance.new("UIStroke")
    titleGlow.Color = Theme.Purple
    titleGlow.Thickness = 1.5
    titleGlow.Transparency = 0.4
    titleGlow.Parent = title
    
    local subtitle = Instance.new("TextLabel")
    subtitle.Size = UDim2.new(1, -120, 0, 16)
    subtitle.Position = UDim2.new(0, 20, 0, 34)
    subtitle.BackgroundTransparency = 1
    subtitle.Text = "Advanced Event Capture & Replay • v1.1 Fixed"
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
        {Name = "Replay", Icon = "🔄", Desc = "Event Replay"},
        {Name = "Logs", Icon = "📝", Desc = "All Logs"},
        {Name = "Remote", Icon = "📡", Desc = "Remote Events"},
        {Name = "Character", Icon = "🎯", Desc = "Character"},
        {Name = "Input", Icon = "⌨️", Desc = "Inputs"},
        {Name = "Network", Icon = "🌐", Desc = "Network"},
        {Name = "Settings", Icon = "⚙️", Desc = "Config"}
    }
    
    self.TabButtons = {}
    
    for i, tab in ipairs(tabs) do
        local tabBtn = Instance.new("TextButton")
        tabBtn.Name = tab.Name
        tabBtn.Size = UDim2.new(0, 127, 1, 0)
        tabBtn.BackgroundColor3 = Theme.Tab
        tabBtn.BorderSizePixel = 0
        tabBtn.Text = tab.Icon .. " " .. tab.Name
        tabBtn.TextColor3 = Theme.TextSecondary
        tabBtn.Font = Enum.Font.GothamBold
        tabBtn.TextSize = 12
        tabBtn.Parent = tabContainer
        
        local tabCorner = Instance.new("UICorner")
        tabCorner.CornerRadius = UDim.new(0, 0)
        tabCorner.Parent = tabBtn
        
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
    
    self:AddLog("System", "✅ UI SHAKA LOGGER v1.1 criada!")
end

function ShakaLogger:SwitchTab(tabName)
    self.CurrentTab = tabName
    
    for name, btn in pairs(self.TabButtons) do
        if name == tabName then
            btn.BackgroundColor3 = self.Theme.TabActive
            btn.TextColor3 = self.Theme.Text
            
            local stroke = btn:FindFirstChild("UIStroke") or Instance.new("UIStroke")
            stroke.Color = self.Theme.Purple
            stroke.Thickness = 2
            stroke.Transparency = 0
            stroke.Parent = btn
        else
            btn.BackgroundColor3 = self.Theme.Tab
            btn.TextColor3 = self.Theme.TextSecondary
            
            if btn:FindFirstChild("UIStroke") then
                btn:FindFirstChild("UIStroke"):Destroy()
            end
        end
    end
    
    for name, frame in pairs(self.ContentFrames) do
        frame.Visible = (name == tabName)
    end
    
    self:RefreshCurrentTab()
end

function ShakaLogger:RefreshCurrentTab()
    local frame = self.ContentFrames[self.CurrentTab]
    if not frame then return end
    
    for _, child in ipairs(frame:GetChildren()) do
        if not child:IsA("UIListLayout") then
            child:Destroy()
        end
    end
    
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
-- CONTEÚDO
--═══════════════════════════════════════════════════════════

function ShakaLogger:CreateReplayContent(frame)
    local statsCard = self:CreateCard(frame, "📊 ESTATÍSTICAS DO SISTEMA", 130)
    
    local statsData = {
        {"Total de Logs", self.Stats.Total, self.Theme.Purple},
        {"Eventos Capturados", self.Stats.Captured, self.Theme.Success},
        {"Eventos Bloqueados", self.Stats.Blocked, self.Theme.Danger}
    }
    
    for i, stat in ipairs(statsData) do
        self:CreateStatRow(statsCard, stat[1], stat[2], stat[3], 35 + (i - 1) * 32)
    end
    
    if #self.CapturedEvents == 0 then
        local emptyCard = self:CreateCard(frame, "⚠️ NENHUM EVENTO CAPTURADO", 90)
        local emptyText = Instance.new("TextLabel")
        emptyText.Size = UDim2.new(1, -30, 0, 50)
        emptyText.Position = UDim2.new(0, 15, 0, 35)
        emptyText.BackgroundTransparency = 1
        emptyText.Text = "Interaja com o jogo para capturar eventos automaticamente.\nOs eventos aparecerão aqui em tempo real."
        emptyText.TextColor3 = self.Theme.TextSecondary
        emptyText.Font = Enum.Font.Gotham
        emptyText.TextSize = 13
        emptyText.TextWrapped = true
        emptyText.TextYAlignment = Enum.TextYAlignment.Top
        emptyText.Parent = emptyCard
        return
    end
    
    for i, event in ipairs(self.CapturedEvents) do
        if i > 20 then break end
        self:CreateEventCard(frame, event)
    end
end

function ShakaLogger:CreateLogsContent(frame, category)
    local logs = {}
    
    if category == "All" then
        for cat, catLogs in pairs(self.Logs) do
            for _, log in ipairs(catLogs) do
                table.insert(logs, log)
            end
        end
        table.sort(logs, function(a, b) return (a.ID or 0) > (b.ID or 0) end)
    else
        logs = self.Logs[category] or {}
    end
    
    if #logs == 0 then
        local emptyCard = self:CreateCard(frame, "📭 SEM LOGS NESTA CATEGORIA", 70)
        return
    end
    
    for i, log in ipairs(logs) do
        if i > 40 then break end
        self:CreateLogRow(frame, log)
    end
end

function ShakaLogger:CreateSettingsContent(frame)
    local card = self:CreateCard(frame, "⚙️ CONFIGURAÇÕES DE FILTROS", 330)
    
    local yPos = 45
    
    for category, enabled in pairs(self.FilterSettings) do
        self:CreateToggleButton(card, category, enabled, yPos)
        yPos = yPos + 42
    end
    
    yPos = yPos + 10
    
    local clearBtn = self:CreateButton(card, "🗑️ LIMPAR TODOS OS LOGS", self.Theme.Danger, 15, yPos, 320, 38)
    clearBtn.MouseButton1Click:Connect(function()
        for cat in pairs(self.Logs) do
            self.Logs[cat] = {}
        end
        self.Stats = {Total = 0, Remote = 0, Character = 0, Input = 0, Network = 0, Captured = 0, Blocked = 0}
        self:AddLog("System", "🗑️ Todos os logs foram limpos!")
        self:RefreshCurrentTab()
    end)
    
    yPos = yPos + 48
    
    local clearEventsBtn = self:CreateButton(card, "🗑️ LIMPAR EVENTOS CAPTURADOS", self.Theme.Warning, 15, yPos, 320, 38)
    clearEventsBtn.MouseButton1Click:Connect(function()
        self.CapturedEvents = {}
        self.Stats.Captured = 0
        self:AddLog("System", "🗑️ Eventos capturados limpos!")
        self:RefreshCurrentTab()
    end)
    
    yPos = yPos + 48
    
    local unblockBtn = self:CreateButton(card, "✅ DESBLOQUEAR TODOS OS EVENTOS", self.Theme.Success, 15, yPos, 320, 38)
    unblockBtn.MouseButton1Click:Connect(function()
        self.BlockedEvents = {}
        self.Stats.Blocked = 0
        self:AddLog("System", "✅ Todos os eventos foram desbloqueados!")
        self:RefreshCurrentTab()
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

function ShakaLogger:CreateStatRow(parent, label, value, color, yPos)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, -50, 0, 28)
    row.Position = UDim2.new(0, 25, 0, yPos)
    row.BackgroundTransparency = 1
    row.Parent = parent
    
    local labelText = Instance.new("TextLabel")
    labelText.Size = UDim2.new(0.65, 0, 1, 0)
    labelText.BackgroundTransparency = 1
    labelText.Text = label
    labelText.TextColor3 = self.Theme.TextSecondary
    labelText.TextXAlignment = Enum.TextXAlignment.Left
    labelText.Font = Enum.Font.Gotham
    labelText.TextSize = 13
    labelText.Parent = row
    
    local valueText = Instance.new("TextLabel")
    valueText.Size = UDim2.new(0.35, 0, 1, 0)
    valueText.Position = UDim2.new(0.65, 0, 0, 0)
    valueText.BackgroundTransparency = 1
    valueText.Text = tostring(value)
    valueText.TextColor3 = color
    valueText.TextXAlignment = Enum.TextXAlignment.Right
    valueText.Font = Enum.Font.GothamBold
    valueText.TextSize = 18
    valueText.Parent = row
end

function ShakaLogger:CreateEventCard(parent, event)
    local isBlocked = self:IsEventBlocked(event.Path)
    
    local card = Instance.new("Frame")
    card.Size = UDim2.new(1, 0, 0, 120)
    card.BackgroundColor3 = self.Theme.Card
    card.BorderSizePixel = 0
    card.Parent = parent
    
    local cardCorner = Instance.new("UICorner")
    cardCorner.CornerRadius = UDim.new(0, 10)
    cardCorner.Parent = card
    
    local cardBorder = Instance.new("UIStroke")
    cardBorder.Color = isBlocked and self.Theme.Danger or self.Theme.Purple
    cardBorder.Thickness = isBlocked and 2 or 1.5
    cardBorder.Transparency = isBlocked and 0.3 or 0.6
    cardBorder.Parent = card
    
    -- Status badge
    if isBlocked then
        local blockedBadge = Instance.new("Frame")
        blockedBadge.Size = UDim2.new(0, 90, 0, 24)
        blockedBadge.Position = UDim2.new(0, 14, 0, 10)
        blockedBadge.BackgroundColor3 = self.Theme.Danger
        blockedBadge.BorderSizePixel = 0
        blockedBadge.ZIndex = 2
        blockedBadge.Parent = card
        
        local badgeCorner = Instance.new("UICorner")
        badgeCorner.CornerRadius = UDim.new(0, 6)
        badgeCorner.Parent = blockedBadge
        
        local badgeText = Instance.new("TextLabel")
        badgeText.Size = UDim2.new(1, 0, 1, 0)
        badgeText.BackgroundTransparency = 1
        badgeText.Text = "🚫 BLOQUEADO"
        badgeText.TextColor3 = self.Theme.Text
        badgeText.Font = Enum.Font.GothamBold
        badgeText.TextSize = 10
        badgeText.Parent = blockedBadge
    end
    
    local nameLabel = Instance.new("TextLabel")
    nameLabel.Size = UDim2.new(1, -360, 0, 24)
    nameLabel.Position = UDim2.new(0, isBlocked and 110 or 14, 0, 10)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text = "📡 " .. event.Name .. " [" .. event.Type .. "]"
    nameLabel.TextColor3 = self.Theme.PurpleLight
    nameLabel.TextXAlignment = Enum.TextXAlignment.Left
    nameLabel.Font = Enum.Font.GothamBold
    nameLabel.TextSize = 14
    nameLabel.TextTruncate = Enum.TextTruncate.AtEnd
    nameLabel.Parent = card
    
    local pathLabel = Instance.new("TextLabel")
    pathLabel.Size = UDim2.new(1, -360, 0, 20)
    pathLabel.Position = UDim2.new(0, 14, 0, 36)
    pathLabel.BackgroundTransparency = 1
    pathLabel.Text = "📁 " .. event.Path
    pathLabel.TextColor3 = self.Theme.TextSecondary
    pathLabel.TextXAlignment = Enum.TextXAlignment.Left
    pathLabel.Font = Enum.Font.Gotham
    pathLabel.TextSize = 10
    pathLabel.TextTruncate = Enum.TextTruncate.AtEnd
    pathLabel.Parent = card
    
    local argsLabel = Instance.new("TextLabel")
    argsLabel.Size = UDim2.new(1, -360, 0, 20)
    argsLabel.Position = UDim2.new(0, 14, 0, 58)
    argsLabel.BackgroundTransparency = 1
    argsLabel.Text = "Args: " .. self:FormatArgs(event.Args)
    argsLabel.TextColor3 = self.Theme.Warning
    argsLabel.TextXAlignment = Enum.TextXAlignment.Left
    argsLabel.Font = Enum.Font.Code
    argsLabel.TextSize = 10
    argsLabel.TextTruncate = Enum.TextTruncate.AtEnd
    argsLabel.Parent = card
    
    local timeLabel = Instance.new("TextLabel")
    timeLabel.Size = UDim2.new(1, -360, 0, 18)
    timeLabel.Position = UDim2.new(0, 14, 0, 80)
    timeLabel.BackgroundTransparency = 1
    timeLabel.Text = "🕐 " .. event.Time
    timeLabel.TextColor3 = self.Theme.TextSecondary
    timeLabel.TextXAlignment = Enum.TextXAlignment.Left
    timeLabel.Font = Enum.Font.Gotham
    timeLabel.TextSize = 10
    timeLabel.Parent = card
    
    -- Botões
    local btnY = 10
    local btnSpacing = 37
    
    local btn1 = self:CreateButton(card, "▶️ x1", self.Theme.Success, -345, btnY, 75, 30)
    btn1.MouseButton1Click:Connect(function()
        self:ReplayEvent(event, 1)
    end)
    
    local btn5 = self:CreateButton(card, "⚡ x5", self.Theme.Purple, -345, btnY + btnSpacing, 75, 30)
    btn5.MouseButton1Click:Connect(function()
        self:ReplayEvent(event, 5)
    end)
    
    local btn10 = self:CreateButton(card, "🔥 x10", self.Theme.Warning, -345, btnY + btnSpacing * 2, 75, 30)
    btn10.MouseButton1Click:Connect(function()
        self:ReplayEvent(event, 10)
    end)
    
    local btnCustom = self:CreateButton(card, "⚙️ x?", self.Theme.Tab, -265, btnY, 75, 30)
    btnCustom.MouseButton1Click:Connect(function()
        -- Simular input (Roblox não tem prompt nativo em client)
        self:AddLog("System", "💡 Use console: _G.ShakaLogger:ReplayEvent(evento, vezes)")
    end)
    
    local btnLoop = self:CreateButton(card, event.IsLooping and "⏹️ STOP" or "🔁 LOOP", 
        event.IsLooping and self.Theme.Danger or Color3.fromRGB(138, 43, 226), 
        -265, btnY + btnSpacing, 75, 30)
    btnLoop.MouseButton1Click:Connect(function()
        local looping = self:ToggleLoop(event)
        btnLoop.Text = looping and "⏹️ STOP" or "🔁 LOOP"
        btnLoop.BackgroundColor3 = looping and self.Theme.Danger or Color3.fromRGB(138, 43, 226)
    end)
    
    local btnBlock = self:CreateButton(card, isBlocked and "✅ DESBLO" or "🚫 BLOC", 
        isBlocked and self.Theme.Success or self.Theme.Danger, 
        -265, btnY + btnSpacing * 2, 75, 30)
    btnBlock.MouseButton1Click:Connect(function()
        if isBlocked then
            self:UnblockEvent(event.Path)
        else
            self:BlockEvent(event.Path)
        end
        self:RefreshCurrentTab()
    end)
    
    local btnInfo = self:CreateButton(card, "ℹ️ INFO", Color3.fromRGB(70, 70, 90), -185, btnY, 75, 30)
    btnInfo.MouseButton1Click:Connect(function()
        local info = string.format(
            "\n" .. string.rep("═", 70) .. "\n" ..
            "📋 INFORMAÇÕES DO EVENTO\n" ..
            string.rep("═", 70) .. "\n" ..
            "Nome: %s\n" ..
            "Tipo: %s\n" ..
            "Hora: %s\n" ..
            "Caminho: %s\n" ..
            "Bloqueado: %s\n\n" ..
            "Argumentos (JSON):\n%s\n" ..
            string.rep("═", 70) .. "\n",
            event.Name,
            event.Type,
            event.Time,
            event.Path,
            isBlocked and "SIM" or "NÃO",
            HttpService:JSONEncode(event.Args)
        )
        print(info)
        self:AddLog("System", "ℹ️ Info do evento " .. event.Name .. " printada no console")
    end)
    
    local btnCopy = self:CreateButton(card, "📋 COPY", self.Theme.Accent, -185, btnY + btnSpacing, 75, 30)
    btnCopy.MouseButton1Click:Connect(function()
        local argsJson = HttpService:JSONEncode(event.Args)
        if setclipboard then
            setclipboard(argsJson)
            self:AddLog("System", "📋 Args copiados: " .. event.Name)
        else
            print("ARGS:", argsJson)
            self:AddLog("System", "📋 Args printados no console (clipboard não disponível)")
        end
    end)
end

function ShakaLogger:CreateLogRow(parent, log)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, 0, 0, 38)
    row.BackgroundColor3 = self.Theme.Card
    row.BorderSizePixel = 0
    row.Parent = parent
    
    local rowCorner = Instance.new("UICorner")
    rowCorner.CornerRadius = UDim.new(0, 8)
    rowCorner.Parent = row
    
    local rowBorder = Instance.new("UIStroke")
    rowBorder.Color = self.Theme.Purple
    rowBorder.Thickness = 1
    rowBorder.Transparency = 0.8
    rowBorder.Parent = row
    
    local timeLabel = Instance.new("TextLabel")
    timeLabel.Size = UDim2.new(0, 70, 1, 0)
    timeLabel.Position = UDim2.new(0, 10, 0, 0)
    timeLabel.BackgroundTransparency = 1
    timeLabel.Text = log.Time
    timeLabel.TextColor3 = self.Theme.TextSecondary
    timeLabel.TextXAlignment = Enum.TextXAlignment.Left
    timeLabel.Font = Enum.Font.Code
    timeLabel.TextSize = 11
    timeLabel.Parent = row
    
    local catLabel = Instance.new("TextLabel")
    catLabel.Size = UDim2.new(0, 90, 1, 0)
    catLabel.Position = UDim2.new(0, 85, 0, 0)
    catLabel.BackgroundTransparency = 1
    catLabel.Text = "[" .. log.Category .. "]"
    catLabel.TextColor3 = self.Theme.Purple
    catLabel.TextXAlignment = Enum.TextXAlignment.Left
    catLabel.Font = Enum.Font.GothamBold
    catLabel.TextSize = 11
    catLabel.Parent = row
    
    local msgLabel = Instance.new("TextLabel")
    msgLabel.Size = UDim2.new(1, -185, 1, 0)
    msgLabel.Position = UDim2.new(0, 180, 0, 0)
    msgLabel.BackgroundTransparency = 1
    msgLabel.Text = log.Message
    msgLabel.TextColor3 = self.Theme.Text
    msgLabel.TextXAlignment = Enum.TextXAlignment.Left
    msgLabel.Font = Enum.Font.Gotham
    msgLabel.TextSize = 11
    msgLabel.TextTruncate = Enum.TextTruncate.AtEnd
    msgLabel.Parent = row
end

function ShakaLogger:CreateToggleButton(parent, category, enabled, yPos)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, -30, 0, 38)
    frame.Position = UDim2.new(0, 15, 0, yPos)
    frame.BackgroundColor3 = self.Theme.Tab
    frame.BorderSizePixel = 0
    frame.Parent = parent
    
    local frameCorner = Instance.new("UICorner")
    frameCorner.CornerRadius = UDim.new(0, 8)
    frameCorner.Parent = frame
    
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -110, 1, 0)
    label.Position = UDim2.new(0, 18, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = "📊 " .. category .. " Logs"
    label.TextColor3 = self.Theme.Text
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Font = Enum.Font.GothamBold
    label.TextSize = 13
    label.Parent = frame
    
    local toggleBtn = Instance.new("TextButton")
    toggleBtn.Size = UDim2.new(0, 75, 0, 28)
    toggleBtn.Position = UDim2.new(1, -85, 0.5, -14)
    toggleBtn.BackgroundColor3 = enabled and self.Theme.Success or self.Theme.Danger
    toggleBtn.Text = enabled and "✓ ON" or "✗ OFF"
    toggleBtn.TextColor3 = self.Theme.Text
    toggleBtn.Font = Enum.Font.GothamBold
    toggleBtn.TextSize = 12
    toggleBtn.BorderSizePixel = 0
    toggleBtn.Parent = frame
    
    local toggleCorner = Instance.new("UICorner")
    toggleCorner.CornerRadius = UDim.new(0, 6)
    toggleCorner.Parent = toggleBtn
    
    toggleBtn.MouseButton1Click:Connect(function()
        self.FilterSettings[category] = not self.FilterSettings[category]
        local isEnabled = self.FilterSettings[category]
        toggleBtn.BackgroundColor3 = isEnabled and self.Theme.Success or self.Theme.Danger
        toggleBtn.Text = isEnabled and "✓ ON" or "✗ OFF"
        self:AddLog("System", string.format("%s logs %s", category, isEnabled and "ativados ✅" or "desativados ❌"))
    end)
    
    return frame
end

function ShakaLogger:CreateButton(card, text, color, xPos, yPos, width, height)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, width, 0, height)
    btn.Position = UDim2.new(1, xPos, 0, yPos)
    btn.BackgroundColor3 = color
    btn.Text = text
    btn.TextColor3 = self.Theme.Text
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 11
    btn.BorderSizePixel = 0
    btn.AutoButtonColor = false
    btn.Parent = card
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = btn
    
    btn.MouseEnter:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.15), {
            BackgroundColor3 = Color3.fromRGB(
                math.min(255, color.R * 255 + 25),
                math.min(255, color.G * 255 + 25),
                math.min(255, color.B * 255 + 25)
            )
        }):Play()
    end)
    
    btn.MouseLeave:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.15), {BackgroundColor3 = color}):Play()
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
            TweenService:Create(self.MainFrame, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
                Size = UDim2.new(0, 900, 0, 620)
            }):Play()
            task.wait(0.1)
            self:RefreshCurrentTab()
        else
            TweenService:Create(self.MainFrame, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.In), {
                Size = UDim2.new(0, 0, 0, 0)
            }):Play()
            task.wait(0.25)
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
    print("\n" .. string.rep("═", 80))
    print("⚡ SHAKA LOGGER v1.1 FIXED")
    print("   Advanced Event Capture & Replay System")
    print("   Tema: Preto e Roxo | UI Melhorada")
    print(string.rep("═", 80))
    
    self:CreateUI()
    self:AddLog("System", "✅ SHAKA LOGGER UI v1.1 criada com sucesso!")
    
    self:SetupKeybind()
    self:AddLog("System", "⌨️ Keybind [F] configurado - Pressione F para abrir/fechar")
    
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
    self:SwitchTab("Replay")
    
    print("✅ SHAKA LOGGER v1.1 inicializado com sucesso!")
    print("⌨️ Pressione [F] para abrir/fechar o menu")
    print("🎯 Interaja com o jogo para capturar eventos")
    print("🚫 Bloqueio agora funciona CORRETAMENTE por caminho completo")
    print("🔄 Replay verifica se remote existe antes de executar")
    print(string.rep("═", 80) .. "\n")
end

task.spawn(function()
    if not game:IsLoaded() then
        game.Loaded:Wait()
    end
    task.wait(3)
    
    ShakaLogger:Init()
end)

getgenv().ShakaLogger = ShakaLogger
_G.ShakaLogger = ShakaLogger

print("\n📋 COMANDOS ÚTEIS:")
print("   _G.ShakaLogger:Toggle() - Abrir/Fechar")
print("   _G.ShakaLogger:BlockEvent('caminho.completo.Remote') - Bloquear")
print("   _G.ShakaLogger:UnblockEvent('caminho.completo.Remote') - Desbloquear")
print("")

return ShakaLogger
