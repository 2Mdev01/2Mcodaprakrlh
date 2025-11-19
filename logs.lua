-- SECURITY MENU AVANÇADO v2.0
-- Sistema completo de logs, captura de eventos e replay
-- APENAS para pentest autorizado

local SecurityMenu = {}
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")

-- Configurações
SecurityMenu.OpenKey = Enum.KeyCode.F
SecurityMenu.IsOpen = false
SecurityMenu.CurrentTab = "Dashboard"
SecurityMenu.IsInitialized = false

-- Sistema de Logs Melhorado
SecurityMenu.Logs = {
    All = {},
    Remote = {},
    Character = {},
    Network = {},
    Input = {},
    System = {},
    Custom = {}
}

SecurityMenu.Stats = {
    Total = 0,
    Remote = 0,
    Character = 0,
    Network = 0,
    Input = 0,
    System = 0,
    Custom = 0
}

-- Sistema de Captura de Eventos (para replay)
SecurityMenu.CapturedEvents = {}
SecurityMenu.EventHistory = {}
SecurityMenu.MonitoredRemotes = {}
SecurityMenu.RemoteConnections = {}

-- Sistema de Filtros
SecurityMenu.Filters = {
    RemoteFilter = "",
    ShowOnlyImportant = false,
    MaxLogsPerCategory = 100
}

--═══════════════════════════════════════════════════════════
-- SISTEMA DE LOGGING AVANÇADO
--═══════════════════════════════════════════════════════════

function SecurityMenu:Log(category, message, data)
    if not self.Logs[category] then
        self.Logs[category] = {}
    end
    
    local logEntry = {
        Time = os.date("%H:%M:%S"),
        Timestamp = tick(),
        Category = category,
        Message = message,
        Data = data or {},
        ID = #self.Logs.All + 1
    }
    
    -- Adicionar aos logs
    table.insert(self.Logs.All, 1, logEntry)
    table.insert(self.Logs[category], 1, logEntry)
    
    -- Limitar tamanho dos logs
    if #self.Logs.All > 1000 then
        table.remove(self.Logs.All, #self.Logs.All)
    end
    
    if #self.Logs[category] > self.Filters.MaxLogsPerCategory then
        table.remove(self.Logs[category], #self.Logs[category])
    end
    
    -- Atualizar estatísticas
    self.Stats.Total = self.Stats.Total + 1
    self.Stats[category] = (self.Stats[category] or 0) + 1
    
    -- Print detalhado no console
    print(string.format("[%s] [%s] %s", logEntry.Time, category, message))
    
    -- Atualizar UI se estiver aberta
    if self.IsOpen and self.UpdateDisplay then
        task.spawn(function()
            self:UpdateDisplay()
        end)
    end
    
    return logEntry
end

--═══════════════════════════════════════════════════════════
-- SISTEMA DE CAPTURA DE REMOTE EVENTS (PARA REPLAY)
--═══════════════════════════════════════════════════════════

function SecurityMenu:CaptureEvent(remoteName, remoteType, args, remoteObject)
    local eventData = {
        Name = remoteName,
        Type = remoteType,
        Arguments = args,
        RemoteObject = remoteObject,
        Timestamp = tick(),
        Time = os.date("%H:%M:%S"),
        FullPath = remoteObject:GetFullName(),
        ID = #self.CapturedEvents + 1
    }
    
    table.insert(self.CapturedEvents, 1, eventData)
    table.insert(self.EventHistory, 1, eventData)
    
    -- Limitar histórico
    if #self.EventHistory > 200 then
        table.remove(self.EventHistory, #self.EventHistory)
    end
    
    return eventData
end

function SecurityMenu:ReplayEvent(eventData)
    if not eventData or not eventData.RemoteObject then
        self:Log("System", "❌ Evento inválido para replay", {})
        return false
    end
    
    local success, err = pcall(function()
        if eventData.Type == "RemoteEvent" then
            if eventData.RemoteObject and eventData.RemoteObject:IsA("RemoteEvent") then
                eventData.RemoteObject:FireServer(unpack(eventData.Arguments))
                self:Log("Custom", "🔄 REPLAY: " .. eventData.Name, {
                    Args = eventData.Arguments
                })
                return true
            end
        elseif eventData.Type == "RemoteFunction" then
            if eventData.RemoteObject and eventData.RemoteObject:IsA("RemoteFunction") then
                local result = eventData.RemoteObject:InvokeServer(unpack(eventData.Arguments))
                self:Log("Custom", "🔄 REPLAY: " .. eventData.Name .. " → " .. tostring(result), {
                    Args = eventData.Arguments,
                    Result = result
                })
                return true
            end
        end
    end)
    
    if not success then
        self:Log("System", "❌ Erro no replay: " .. tostring(err), {})
        return false
    end
    
    return true
end

function SecurityMenu:ReplayEventMultiple(eventData, times)
    times = times or 1
    local successCount = 0
    
    for i = 1, times do
        if self:ReplayEvent(eventData) then
            successCount = successCount + 1
        end
        task.wait(0.1) -- Delay entre replays
    end
    
    self:Log("Custom", string.format("🔄 Replay concluído: %d/%d sucessos", successCount, times), {})
    return successCount
end

--═══════════════════════════════════════════════════════════
-- MONITORAMENTO DE REMOTE EVENTS AVANÇADO
--═══════════════════════════════════════════════════════════

function SecurityMenu:MonitorRemoteEvents()
    self:Log("System", "🔍 Iniciando monitoramento avançado de RemoteEvents...", {})
    
    local function hookRemote(remote)
        if self.MonitoredRemotes[remote] then return end
        
        local remoteName = remote.Name
        local remotePath = remote:GetFullName()
        
        if remote:IsA("RemoteEvent") then
            -- Hook RemoteEvent.FireServer
            local oldFireServer = remote.FireServer
            
            remote.FireServer = newcclosure(function(self, ...)
                local args = {...}
                
                -- Capturar evento
                local eventData = SecurityMenu:CaptureEvent(remoteName, "RemoteEvent", args, remote)
                
                -- Log detalhado
                local argsStr = HttpService:JSONEncode(args)
                SecurityMenu:Log("Remote", "📡 " .. remoteName .. " | Args: " .. argsStr, {
                    Remote = remoteName,
                    Path = remotePath,
                    Args = args,
                    EventData = eventData
                })
                
                -- Chamar função original
                return oldFireServer(self, ...)
            end)
            
        elseif remote:IsA("RemoteFunction") then
            -- Hook RemoteFunction.InvokeServer
            local oldInvokeServer = remote.InvokeServer
            
            remote.InvokeServer = newcclosure(function(self, ...)
                local args = {...}
                
                -- Chamar função original e capturar resultado
                local result = oldInvokeServer(self, ...)
                
                -- Capturar evento
                local eventData = SecurityMenu:CaptureEvent(remoteName, "RemoteFunction", args, remote)
                eventData.Result = result
                
                -- Log detalhado
                local argsStr = HttpService:JSONEncode(args)
                local resultStr = tostring(result)
                SecurityMenu:Log("Remote", "🔧 " .. remoteName .. " | Args: " .. argsStr .. " → " .. resultStr, {
                    Remote = remoteName,
                    Path = remotePath,
                    Args = args,
                    Result = result,
                    EventData = eventData
                })
                
                return result
            end)
        end
        
        self.MonitoredRemotes[remote] = true
    end
    
    -- Monitorar todos os remotes existentes
    local function scanForRemotes(parent)
        for _, child in ipairs(parent:GetDescendants()) do
            if child:IsA("RemoteEvent") or child:IsA("RemoteFunction") then
                pcall(hookRemote, child)
            end
        end
    end
    
    -- Scan inicial
    pcall(scanForRemotes, ReplicatedStorage)
    pcall(scanForRemotes, game:GetService("Workspace"))
    
    -- Monitorar novos remotes
    local function onChildAdded(child)
        if child:IsA("RemoteEvent") or child:IsA("RemoteFunction") then
            task.wait(0.1)
            pcall(hookRemote, child)
            SecurityMenu:Log("System", "✨ Novo remote detectado: " .. child.Name, {})
        end
    end
    
    ReplicatedStorage.DescendantAdded:Connect(onChildAdded)
    game:GetService("Workspace").DescendantAdded:Connect(onChildAdded)
    
    self:Log("System", "✅ Monitoramento de RemoteEvents ativo!", {})
end

--═══════════════════════════════════════════════════════════
-- MONITORAMENTO DE CHARACTER
--═══════════════════════════════════════════════════════════

function SecurityMenu:MonitorCharacter()
    local lastPos = nil
    local lastHealth = nil
    
    RunService.Heartbeat:Connect(function()
        local player = Players.LocalPlayer
        if not player or not player.Character then return end
        
        local root = player.Character:FindFirstChild("HumanoidRootPart")
        local humanoid = player.Character:FindFirstChild("Humanoid")
        
        -- Monitorar posição
        if root then
            local currentPos = root.Position
            if lastPos then
                local dist = (currentPos - lastPos).Magnitude
                if dist > 5 then
                    self:Log("Character", string.format("🎯 Movimento: %.1f studs | Pos: %.1f, %.1f, %.1f", 
                        dist, currentPos.X, currentPos.Y, currentPos.Z), {
                        Distance = dist,
                        Position = currentPos
                    })
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
                self:Log("Character", string.format("%s Saúde: %.1f (Δ%.1f)", 
                    emoji, currentHealth, change), {
                    Health = currentHealth,
                    Change = change
                })
            end
            lastHealth = currentHealth
        end
    end)
    
    self:Log("System", "✅ Monitoramento de Character ativo!", {})
end

--═══════════════════════════════════════════════════════════
-- MONITORAMENTO DE INPUTS
--═══════════════════════════════════════════════════════════

function SecurityMenu:MonitorInputs()
    UserInputService.InputBegan:Connect(function(input, processed)
        if processed then return end
        
        if input.UserInputType == Enum.UserInputType.Keyboard then
            self:Log("Input", "⌨️ Tecla: " .. input.KeyCode.Name, {
                KeyCode = input.KeyCode,
                Processed = processed
            })
        elseif input.UserInputType == Enum.UserInputType.MouseButton1 then
            self:Log("Input", "🖱️ Clique Esquerdo", {})
        elseif input.UserInputType == Enum.UserInputType.MouseButton2 then
            self:Log("Input", "🖱️ Clique Direito", {})
        end
    end)
    
    self:Log("System", "✅ Monitoramento de Inputs ativo!", {})
end

--═══════════════════════════════════════════════════════════
-- MONITORAMENTO DE NETWORK
--═══════════════════════════════════════════════════════════

function SecurityMenu:MonitorNetwork()
    -- Monitorar jogadores
    Players.PlayerAdded:Connect(function(player)
        self:Log("Network", "👤 " .. player.Name .. " entrou no servidor", {
            Player = player.Name,
            UserId = player.UserId
        })
    end)
    
    Players.PlayerRemoving:Connect(function(player)
        self:Log("Network", "👋 " .. player.Name .. " saiu do servidor", {
            Player = player.Name,
            UserId = player.UserId
        })
    end)
    
    -- Log de jogadores atuais
    for _, player in ipairs(Players:GetPlayers()) do
        self:Log("Network", "👥 Jogador atual: " .. player.Name, {
            Player = player.Name,
            UserId = player.UserId
        })
    end
    
    self:Log("System", "✅ Monitoramento de Network ativo!", {})
end

--═══════════════════════════════════════════════════════════
-- INTERFACE DO USUÁRIO
--═══════════════════════════════════════════════════════════

function SecurityMenu:CreateUI()
    if self.ScreenGui then
        pcall(function() self.ScreenGui:Destroy() end)
    end
    
    self.ScreenGui = Instance.new("ScreenGui")
    self.ScreenGui.Parent = game:GetService("CoreGui")
    self.ScreenGui.Name = "SecurityMenuAdvanced"
    self.ScreenGui.ResetOnSpawn = false
    self.ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    
    -- Tema
    local Theme = {
        Background = Color3.fromRGB(20, 20, 25),
        Header = Color3.fromRGB(35, 35, 45),
        Tab = Color3.fromRGB(45, 45, 55),
        TabActive = Color3.fromRGB(70, 130, 255),
        Text = Color3.fromRGB(255, 255, 255),
        TextSecondary = Color3.fromRGB(160, 160, 170),
        Success = Color3.fromRGB(76, 175, 80),
        Warning = Color3.fromRGB(255, 193, 7),
        Error = Color3.fromRGB(244, 67, 54),
        Accent = Color3.fromRGB(0, 188, 212)
    }
    
    self.Theme = Theme
    
    -- Frame Principal
    local MainFrame = Instance.new("Frame")
    MainFrame.Name = "MainFrame"
    MainFrame.Size = UDim2.new(0, 800, 0, 550)
    MainFrame.Position = UDim2.new(0.5, -400, 0.5, -275)
    MainFrame.BackgroundColor3 = Theme.Background
    MainFrame.BorderSizePixel = 0
    MainFrame.Visible = false
    MainFrame.Parent = self.ScreenGui
    
    -- Sombra
    local Shadow = Instance.new("ImageLabel")
    Shadow.Name = "Shadow"
    Shadow.Size = UDim2.new(1, 30, 1, 30)
    Shadow.Position = UDim2.new(0, -15, 0, -15)
    Shadow.BackgroundTransparency = 1
    Shadow.Image = "rbxasset://textures/ui/GUI dropshadow.png"
    Shadow.ImageColor3 = Color3.fromRGB(0, 0, 0)
    Shadow.ImageTransparency = 0.5
    Shadow.ScaleType = Enum.ScaleType.Slice
    Shadow.SliceCenter = Rect.new(50, 50, 100, 100)
    Shadow.ZIndex = 0
    Shadow.Parent = MainFrame
    
    -- Header
    local Header = Instance.new("Frame")
    Header.Name = "Header"
    Header.Size = UDim2.new(1, 0, 0, 45)
    Header.BackgroundColor3 = Theme.Header
    Header.BorderSizePixel = 0
    Header.Parent = MainFrame
    
    local Title = Instance.new("TextLabel")
    Title.Name = "Title"
    Title.Size = UDim2.new(1, -120, 1, 0)
    Title.Position = UDim2.new(0, 15, 0, 0)
    Title.BackgroundTransparency = 1
    Title.Text = "🔒 SECURITY MENU v2.0 - Advanced Pentest Tool"
    Title.TextColor3 = Theme.Text
    Title.TextXAlignment = Enum.TextXAlignment.Left
    Title.Font = Enum.Font.GothamBold
    Title.TextSize = 16
    Title.Parent = Header
    
    local CloseBtn = Instance.new("TextButton")
    CloseBtn.Name = "CloseBtn"
    CloseBtn.Size = UDim2.new(0, 100, 0, 30)
    CloseBtn.Position = UDim2.new(1, -110, 0.5, -15)
    CloseBtn.BackgroundColor3 = Theme.Error
    CloseBtn.BorderSizePixel = 0
    CloseBtn.Text = "✖ FECHAR [F]"
    CloseBtn.TextColor3 = Theme.Text
    CloseBtn.Font = Enum.Font.GothamBold
    CloseBtn.TextSize = 12
    CloseBtn.Parent = Header
    
    CloseBtn.MouseButton1Click:Connect(function()
        self:ToggleMenu()
    end)
    
    -- Tabs Container
    local TabContainer = Instance.new("Frame")
    TabContainer.Name = "TabContainer"
    TabContainer.Size = UDim2.new(1, 0, 0, 40)
    TabContainer.Position = UDim2.new(0, 0, 0, 45)
    TabContainer.BackgroundColor3 = Theme.Tab
    TabContainer.BorderSizePixel = 0
    TabContainer.Parent = MainFrame
    
    local TabLayout = Instance.new("UIListLayout")
    TabLayout.FillDirection = Enum.FillDirection.Horizontal
    TabLayout.SortOrder = Enum.SortOrder.LayoutOrder
    TabLayout.Padding = UDim.new(0, 0)
    TabLayout.Parent = TabContainer
    
    -- Criar Tabs
    local Tabs = {
        {Name = "Dashboard", Icon = "📊"},
        {Name = "Remote", Icon = "📡"},
        {Name = "Replay", Icon = "🔄"},
        {Name = "Character", Icon = "🎯"},
        {Name = "Network", Icon = "🌐"},
        {Name = "Input", Icon = "⌨️"},
        {Name = "Logs", Icon = "📝"}
    }
    
    self.TabButtons = {}
    
    for i, tab in ipairs(Tabs) do
        local TabButton = Instance.new("TextButton")
        TabButton.Name = tab.Name .. "Tab"
        TabButton.Size = UDim2.new(0, 114, 1, 0)
        TabButton.BackgroundColor3 = Theme.Tab
        TabButton.BorderSizePixel = 0
        TabButton.Text = tab.Icon .. " " .. tab.Name
        TabButton.TextColor3 = Theme.TextSecondary
        TabButton.Font = Enum.Font.Gotham
        TabButton.TextSize = 11
        TabButton.Parent = TabContainer
        
        TabButton.MouseButton1Click:Connect(function()
            self:SwitchTab(tab.Name)
        end)
        
        self.TabButtons[tab.Name] = TabButton
    end
    
    -- Content Frame
    local ContentFrame = Instance.new("Frame")
    ContentFrame.Name = "ContentFrame"
    ContentFrame.Size = UDim2.new(1, 0, 1, -85)
    ContentFrame.Position = UDim2.new(0, 0, 0, 85)
    ContentFrame.BackgroundTransparency = 1
    ContentFrame.Parent = MainFrame
    
    -- Criar frames para cada tab
    self.ContentFrames = {}
    
    for _, tab in ipairs(Tabs) do
        local Frame = Instance.new("ScrollingFrame")
        Frame.Name = tab.Name .. "Content"
        Frame.Size = UDim2.new(1, -10, 1, -10)
        Frame.Position = UDim2.new(0, 5, 0, 5)
        Frame.BackgroundTransparency = 1
        Frame.BorderSizePixel = 0
        Frame.ScrollBarThickness = 8
        Frame.ScrollBarImageColor3 = Theme.TabActive
        Frame.Visible = false
        Frame.CanvasSize = UDim2.new(0, 0, 0, 0)
        Frame.AutomaticCanvasSize = Enum.AutomaticSize.Y
        Frame.Parent = ContentFrame
        
        local Layout = Instance.new("UIListLayout")
        Layout.Padding = UDim.new(0, 8)
        Layout.SortOrder = Enum.SortOrder.LayoutOrder
        Layout.Parent = Frame
        
        self.ContentFrames[tab.Name] = Frame
    end
    
    self.MainFrame = MainFrame
    
    -- Selecionar primeira tab
    self:SwitchTab("Dashboard")
    
    self:Log("System", "✅ Interface criada com sucesso!", {})
end

function SecurityMenu:SwitchTab(tabName)
    self.CurrentTab = tabName
    
    -- Atualizar botões
    for name, button in pairs(self.TabButtons) do
        if name == tabName then
            button.BackgroundColor3 = self.Theme.TabActive
            button.TextColor3 = self.Theme.Text
        else
            button.BackgroundColor3 = self.Theme.Tab
            button.TextColor3 = self.Theme.TextSecondary
        end
    end
    
    -- Mostrar frame correto
    for name, frame in pairs(self.ContentFrames) do
        frame.Visible = (name == tabName)
        
        if name == tabName then
            -- Limpar conteúdo anterior
            for _, child in ipairs(frame:GetChildren()) do
                if not child:IsA("UIListLayout") then
                    child:Destroy()
                end
            end
            
            -- Atualizar conteúdo
            self:UpdateTabContent(tabName)
        end
    end
end

function SecurityMenu:UpdateTabContent(tabName)
    local frame = self.ContentFrames[tabName]
    if not frame then return end
    
    if tabName == "Dashboard" then
        self:CreateDashboard(frame)
    elseif tabName == "Remote" then
        self:CreateRemoteTab(frame)
    elseif tabName == "Replay" then
        self:CreateReplayTab(frame)
    elseif tabName == "Character" then
        self:CreateCharacterTab(frame)
    elseif tabName == "Network" then
        self:CreateNetworkTab(frame)
    elseif tabName == "Input" then
        self:CreateInputTab(frame)
    elseif tabName == "Logs" then
        self:CreateLogsTab(frame)
    end
end

--═══════════════════════════════════════════════════════════
-- CONTEÚDO DAS TABS
--═══════════════════════════════════════════════════════════

function SecurityMenu:CreateDashboard(frame)
    -- Estatísticas
    local statsSection = self:CreateSection(frame, "📊 ESTATÍSTICAS EM TEMPO REAL")
    
    local statsData = {
        {"📝 Total de Eventos", self.Stats.Total, self.Theme.Accent},
        {"📡 Remote Events", self.Stats.Remote, self.Theme.Success},
        {"🔄 Eventos Capturados", #self.CapturedEvents, self.Theme.Warning},
        {"🎯 Character Events", self.Stats.Character, self.Theme.Success},
        {"🌐 Network Events", self.Stats.Network, self.Theme.Success},
        {"⌨️ Input Events", self.Stats.Input, self.Theme.Success}
    }
    
    for _, stat in ipairs(statsData) do
        self:CreateStatCard(statsSection, stat[1], stat[2], stat[3])
    end
    
    -- Controles
    local controlSection = self:CreateSection(frame, "🛠️ CONTROLES RÁPIDOS")
    
    local controls = {
        {"🧹 Limpar Logs", self.Theme.Warning, function()
            self:ClearLogs()
        end},
        {"🗑️ Limpar Eventos Capturados", self.Theme.Error, function()
            self.CapturedEvents = {}
            self:Log("System", "🗑️ Eventos capturados limpos!", {})
            self:UpdateDisplay()
        end},
        {"🔄 Atualizar Tela", self.Theme.Success, function()
            self:UpdateDisplay()
        end}
    }
    
    for _, control in ipairs(controls) do
        self:CreateButton(controlSection, control[1], control[2], control[3])
    end
end

function SecurityMenu:CreateRemoteTab(frame)
    local section = self:CreateSection(frame, "📡 REMOTE EVENTS CAPTURADOS (" .. self.Stats.Remote .. " eventos)")
    
    -- Filtro
    local filterFrame = self:CreateInputField(section, "🔍 Filtrar por nome:", function(text)
        self.Filters.RemoteFilter = text
        self:UpdateDisplay()
    end)
    
    -- Logs filtrados
    local logs = {}
    for _, log in ipairs(self.Logs.Remote) do
        if self.Filters.RemoteFilter == "" or 
           string.find(string.lower(log.Message), string.lower(self.Filters.RemoteFilter)) then
            table.insert(logs, log)
        end
    end
    
    self:DisplayLogs(section, logs, 20)
end

function SecurityMenu:CreateReplayTab(frame)
    local section = self:CreateSection(frame, "🔄 EVENTOS CAPTURADOS PARA REPLAY (" .. #self.CapturedEvents .. " eventos)")
    
    if #self.CapturedEvents == 0 then
        local emptyLabel = Instance.new("TextLabel")
        emptyLabel.Size = UDim2.new(1, -20, 0, 100)
        emptyLabel.BackgroundColor3 = self.Theme.Header
        emptyLabel.BorderSizePixel = 0
        emptyLabel.Text = "⚠️ Nenhum evento capturado ainda\n\nInteraja com o jogo para capturar eventos!"
        emptyLabel.TextColor3 = self.Theme.TextSecondary
        emptyLabel.TextSize = 14
        emptyLabel.Font = Enum.Font.Gotham
        emptyLabel.Parent = section
        return
    end
    
    -- Mostrar eventos capturados com botões de replay
    for i, event in ipairs(self.CapturedEvents) do
        if i > 30 then break end -- Limitar exibição
        
        local eventFrame = Instance.new("Frame")
        eventFrame.Size = UDim2.new(1, -20, 0, 80)
        eventFrame.BackgroundColor3 = self.Theme.Header
        eventFrame.BorderSizePixel = 0
        eventFrame.Parent = section
        
        -- Nome do evento
        local eventName = Instance.new("TextLabel")
        eventName.Size = UDim2.new(1, -160, 0, 25)
        eventName.Position = UDim2.new(0, 10, 0, 5)
        eventName.BackgroundTransparency = 1
        eventName.Text = "📡 " .. event.Name .. " [" .. event.Type .. "]"
        eventName.TextColor3 = self.Theme.Text
        eventName.TextXAlignment = Enum.TextXAlignment.Left
        eventName.Font = Enum.Font.GothamBold
        eventName.TextSize = 12
        eventName.Parent = eventFrame
        
        -- Caminho
        local eventPath = Instance.new("TextLabel")
        eventPath.Size = UDim2.new(1, -160, 0, 20)
        eventPath.Position = UDim2.new(0, 10, 0, 28)
        eventPath.BackgroundTransparency = 1
        eventPath.Text = "📁 " .. event.FullPath
        eventPath.TextColor3 = self.Theme.TextSecondary
        eventPath.TextXAlignment = Enum.TextXAlignment.Left
        eventPath.Font = Enum.Font.Gotham
        eventPath.TextSize = 9
        eventPath.TextTruncate = Enum.TextTruncate.AtEnd
        eventPath.Parent = eventFrame
        
        -- Argumentos
        local argsText = "Args: " .. HttpService:JSONEncode(event.Arguments)
        local eventArgs = Instance.new("TextLabel")
        eventArgs.Size = UDim2.new(1, -160, 0, 20)
        eventArgs.Position = UDim2.new(0, 10, 0, 50)
        eventArgs.BackgroundTransparency = 1
        eventArgs.Text = argsText
        eventArgs.TextColor3 = self.Theme.Accent
        eventArgs.TextXAlignment = Enum.TextXAlignment.Left
        eventArgs.Font = Enum.Font.Code
        eventArgs.TextSize = 9
        eventArgs.TextTruncate = Enum.TextTruncate.AtEnd
        eventArgs.Parent = eventFrame
        
        -- Botão Replay 1x
        local replayBtn = Instance.new("TextButton")
        replayBtn.Size = UDim2.new(0, 70, 0, 25)
        replayBtn.Position = UDim2.new(1, -145, 0, 5)
        replayBtn.BackgroundColor3 = self.Theme.Success
        replayBtn.BorderSizePixel = 0
        replayBtn.Text = "▶️ REPLAY"
        replayBtn.TextColor3 = self.Theme.Text
        replayBtn.Font = Enum.Font.GothamBold
        replayBtn.TextSize = 10
        replayBtn.Parent = eventFrame
        
        replayBtn.MouseButton1Click:Connect(function()
            self:ReplayEvent(event)
        end)
        
        -- Botão Replay 5x
        local replay5Btn = Instance.new("TextButton")
        replay5Btn.Size = UDim2.new(0, 70, 0, 25)
        replay5Btn.Position = UDim2.new(1, -145, 0, 32)
        replay5Btn.BackgroundColor3 = self.Theme.Warning
        replay5Btn.BorderSizePixel = 0
        replay5Btn.Text = "⚡ x5"
        replay5Btn.TextColor3 = self.Theme.Text
        replay5Btn.Font = Enum.Font.GothamBold
        replay5Btn.TextSize = 10
        replay5Btn.Parent = eventFrame
        
        replay5Btn.MouseButton1Click:Connect(function()
            self:ReplayEventMultiple(event, 5)
        end)
        
        -- Botão Replay 10x
        local replay10Btn = Instance.new("TextButton")
        replay10Btn.Size = UDim2.new(0, 70, 0, 25)
        replay10Btn.Position = UDim2.new(1, -145, 0, 50)
        replay10Btn.BackgroundColor3 = self.Theme.Error
        replay10Btn.BorderSizePixel = 0
        replay10Btn.Text = "🔥 x10"
        replay10Btn.TextColor3 = self.Theme.Text
        replay10Btn.Font = Enum.Font.GothamBold
        replay10Btn.TextSize = 10
        replay10Btn.Parent = eventFrame
        
        replay10Btn.MouseButton1Click:Connect(function()
            self:ReplayEventMultiple(event, 10)
        end)
        
        -- Botão Custom
        local customBtn = Instance.new("TextButton")
        customBtn.Size = UDim2.new(0, 70, 0, 25)
        customBtn.Position = UDim2.new(1, -72, 0, 5)
        customBtn.BackgroundColor3 = self.Theme.TabActive
        customBtn.BorderSizePixel = 0
        customBtn.Text = "⚙️ CUSTOM"
        customBtn.TextColor3 = self.Theme.Text
        customBtn.Font = Enum.Font.GothamBold
        customBtn.TextSize = 10
        customBtn.Parent = eventFrame
        
        customBtn.MouseButton1Click:Connect(function()
            -- Criar prompt para quantidade customizada
            local times = tonumber(prompt("Quantas vezes repetir?", "1"))
            if times and times > 0 then
                self:ReplayEventMultiple(event, times)
            end
        end)
        
        -- Botão Loop
        local loopBtn = Instance.new("TextButton")
        loopBtn.Size = UDim2.new(0, 70, 0, 25)
        loopBtn.Position = UDim2.new(1, -72, 0, 32)
        loopBtn.BackgroundColor3 = Color3.fromRGB(156, 39, 176)
        loopBtn.BorderSizePixel = 0
        loopBtn.Text = "🔁 LOOP"
        loopBtn.TextColor3 = self.Theme.Text
        loopBtn.Font = Enum.Font.GothamBold
        loopBtn.TextSize = 10
        loopBtn.Parent = eventFrame
        
        loopBtn.MouseButton1Click:Connect(function()
            -- Loop infinito (até clicar novamente)
            if not event.IsLooping then
                event.IsLooping = true
                loopBtn.Text = "⏸️ PARAR"
                loopBtn.BackgroundColor3 = self.Theme.Error
                
                task.spawn(function()
                    while event.IsLooping do
                        self:ReplayEvent(event)
                        task.wait(0.5)
                    end
                end)
            else
                event.IsLooping = false
                loopBtn.Text = "🔁 LOOP"
                loopBtn.BackgroundColor3 = Color3.fromRGB(156, 39, 176)
            end
        end)
        
        -- Botão Info
        local infoBtn = Instance.new("TextButton")
        infoBtn.Size = UDim2.new(0, 70, 0, 25)
        infoBtn.Position = UDim2.new(1, -72, 0, 50)
        infoBtn.BackgroundColor3 = self.Theme.Tab
        infoBtn.BorderSizePixel = 0
        infoBtn.Text = "ℹ️ INFO"
        infoBtn.TextColor3 = self.Theme.Text
        infoBtn.Font = Enum.Font.GothamBold
        infoBtn.TextSize = 10
        infoBtn.Parent = eventFrame
        
        infoBtn.MouseButton1Click:Connect(function()
            local info = string.format(
                "📋 INFORMAÇÕES DO EVENTO\n\n" ..
                "Nome: %s\n" ..
                "Tipo: %s\n" ..
                "Capturado: %s\n" ..
                "Caminho: %s\n\n" ..
                "Argumentos:\n%s",
                event.Name,
                event.Type,
                event.Time,
                event.FullPath,
                HttpService:JSONEncode(event.Arguments)
            )
            self:Log("Custom", info, event)
        end)
    end
end

function SecurityMenu:CreateCharacterTab(frame)
    local section = self:CreateSection(frame, "🎯 CHARACTER MONITORING (" .. self.Stats.Character .. " eventos)")
    self:DisplayLogs(section, self.Logs.Character, 25)
end

function SecurityMenu:CreateNetworkTab(frame)
    local section = self:CreateSection(frame, "🌐 NETWORK MONITORING (" .. self.Stats.Network .. " eventos)")
    self:DisplayLogs(section, self.Logs.Network, 25)
end

function SecurityMenu:CreateInputTab(frame)
    local section = self:CreateSection(frame, "⌨️ INPUT MONITORING (" .. self.Stats.Input .. " eventos)")
    self:DisplayLogs(section, self.Logs.Input, 25)
end

function SecurityMenu:CreateLogsTab(frame)
    local section = self:CreateSection(frame, "📝 TODOS OS LOGS (" .. self.Stats.Total .. " eventos)")
    self:DisplayLogs(section, self.Logs.All, 30)
end

--═══════════════════════════════════════════════════════════
-- FUNÇÕES AUXILIARES DE UI
--═══════════════════════════════════════════════════════════

function SecurityMenu:CreateSection(parent, title)
    local section = Instance.new("Frame")
    section.Size = UDim2.new(1, -10, 0, 0)
    section.BackgroundTransparency = 1
    section.BorderSizePixel = 0
    section.AutomaticSize = Enum.AutomaticSize.Y
    section.Parent = parent
    
    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, 5)
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Parent = section
    
    if title then
        local titleLabel = Instance.new("TextLabel")
        titleLabel.Size = UDim2.new(1, 0, 0, 30)
        titleLabel.BackgroundColor3 = self.Theme.Header
        titleLabel.BorderSizePixel = 0
        titleLabel.Text = "  " .. title
        titleLabel.TextColor3 = self.Theme.Text
        titleLabel.TextXAlignment = Enum.TextXAlignment.Left
        titleLabel.Font = Enum.Font.GothamBold
        titleLabel.TextSize = 13
        titleLabel.Parent = section
    end
    
    return section
end

function SecurityMenu:CreateStatCard(parent, label, value, color)
    local card = Instance.new("Frame")
    card.Size = UDim2.new(1, 0, 0, 50)
    card.BackgroundColor3 = self.Theme.Header
    card.BorderSizePixel = 0
    card.Parent = parent
    
    local labelText = Instance.new("TextLabel")
    labelText.Size = UDim2.new(1, -100, 1, 0)
    labelText.Position = UDim2.new(0, 15, 0, 0)
    labelText.BackgroundTransparency = 1
    labelText.Text = label
    labelText.TextColor3 = self.Theme.TextSecondary
    labelText.TextXAlignment = Enum.TextXAlignment.Left
    labelText.Font = Enum.Font.Gotham
    labelText.TextSize = 12
    labelText.Parent = card
    
    local valueText = Instance.new("TextLabel")
    valueText.Size = UDim2.new(0, 80, 1, 0)
    valueText.Position = UDim2.new(1, -90, 0, 0)
    valueText.BackgroundTransparency = 1
    valueText.Text = tostring(value)
    valueText.TextColor3 = color
    valueText.TextXAlignment = Enum.TextXAlignment.Right
    valueText.Font = Enum.Font.GothamBold
    valueText.TextSize = 20
    valueText.Parent = card
    
    return card
end

function SecurityMenu:CreateButton(parent, text, color, callback)
    local button = Instance.new("TextButton")
    button.Size = UDim2.new(1, 0, 0, 40)
    button.BackgroundColor3 = color
    button.BorderSizePixel = 0
    button.Text = text
    button.TextColor3 = self.Theme.Text
    button.Font = Enum.Font.GothamBold
    button.TextSize = 13
    button.Parent = parent
    
    button.MouseButton1Click:Connect(callback)
    
    return button
end

function SecurityMenu:CreateInputField(parent, placeholder, callback)
    local inputFrame = Instance.new("Frame")
    inputFrame.Size = UDim2.new(1, 0, 0, 35)
    inputFrame.BackgroundColor3 = self.Theme.Header
    inputFrame.BorderSizePixel = 0
    inputFrame.Parent = parent
    
    local inputBox = Instance.new("TextBox")
    inputBox.Size = UDim2.new(1, -20, 1, -10)
    inputBox.Position = UDim2.new(0, 10, 0, 5)
    inputBox.BackgroundColor3 = self.Theme.Tab
    inputBox.BorderSizePixel = 0
    inputBox.PlaceholderText = placeholder
    inputBox.PlaceholderColor3 = self.Theme.TextSecondary
    inputBox.Text = ""
    inputBox.TextColor3 = self.Theme.Text
    inputBox.TextXAlignment = Enum.TextXAlignment.Left
    inputBox.Font = Enum.Font.Gotham
    inputBox.TextSize = 11
    inputBox.ClearTextOnFocus = false
    inputBox.Parent = inputFrame
    
    inputBox.FocusLost:Connect(function()
        callback(inputBox.Text)
    end)
    
    return inputFrame
end

function SecurityMenu:DisplayLogs(parent, logs, maxLogs)
    if not logs or #logs == 0 then
        local emptyLabel = Instance.new("TextLabel")
        emptyLabel.Size = UDim2.new(1, 0, 0, 60)
        emptyLabel.BackgroundColor3 = self.Theme.Header
        emptyLabel.BorderSizePixel = 0
        emptyLabel.Text = "📭 Nenhum log disponível"
        emptyLabel.TextColor3 = self.Theme.TextSecondary
        emptyLabel.Font = Enum.Font.Gotham
        emptyLabel.TextSize = 12
        emptyLabel.Parent = parent
        return
    end
    
    local displayCount = math.min(#logs, maxLogs or 20)
    
    for i = 1, displayCount do
        local log = logs[i]
        if log then
            self:CreateLogRow(parent, log)
        end
    end
end

function SecurityMenu:CreateLogRow(parent, log)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, 0, 0, 30)
    row.BackgroundColor3 = self.Theme.Header
    row.BorderSizePixel = 0
    row.Parent = parent
    
    local timeLabel = Instance.new("TextLabel")
    timeLabel.Size = UDim2.new(0, 60, 1, 0)
    timeLabel.Position = UDim2.new(0, 5, 0, 0)
    timeLabel.BackgroundTransparency = 1
    timeLabel.Text = log.Time
    timeLabel.TextColor3 = self.Theme.TextSecondary
    timeLabel.TextXAlignment = Enum.TextXAlignment.Left
    timeLabel.Font = Enum.Font.Code
    timeLabel.TextSize = 9
    timeLabel.Parent = row
    
    local categoryLabel = Instance.new("TextLabel")
    categoryLabel.Size = UDim2.new(0, 70, 1, 0)
    categoryLabel.Position = UDim2.new(0, 70, 0, 0)
    categoryLabel.BackgroundTransparency = 1
    categoryLabel.Text = "[" .. log.Category .. "]"
    categoryLabel.TextColor3 = self.Theme.Accent
    categoryLabel.TextXAlignment = Enum.TextXAlignment.Left
    categoryLabel.Font = Enum.Font.GothamBold
    categoryLabel.TextSize = 9
    categoryLabel.Parent = row
    
    local msgLabel = Instance.new("TextLabel")
    msgLabel.Size = UDim2.new(1, -145, 1, 0)
    msgLabel.Position = UDim2.new(0, 145, 0, 0)
    msgLabel.BackgroundTransparency = 1
    msgLabel.Text = log.Message
    msgLabel.TextColor3 = self.Theme.Text
    msgLabel.TextXAlignment = Enum.TextXAlignment.Left
    msgLabel.Font = Enum.Font.Gotham
    msgLabel.TextSize = 10
    msgLabel.TextTruncate = Enum.TextTruncate.AtEnd
    msgLabel.Parent = row
    
    return row
end

function SecurityMenu:UpdateDisplay()
    if self.CurrentTab then
        task.spawn(function()
            self:SwitchTab(self.CurrentTab)
        end)
    end
end

function SecurityMenu:ClearLogs()
    for category, _ in pairs(self.Logs) do
        self.Logs[category] = {}
    end
    
    for stat, _ in pairs(self.Stats) do
        self.Stats[stat] = 0
    end
    
    self:Log("System", "🧹 Todos os logs foram limpos!", {})
    self:UpdateDisplay()
end

function SecurityMenu:ToggleMenu()
    self.IsOpen = not self.IsOpen
    if self.MainFrame then
        self.MainFrame.Visible = self.IsOpen
    end
    
    if self.IsOpen then
        self:UpdateDisplay()
    end
end

--═══════════════════════════════════════════════════════════
-- SISTEMA DE KEYBIND
--═══════════════════════════════════════════════════════════

function SecurityMenu:SetupKeybind()
    UserInputService.InputBegan:Connect(function(input, processed)
        if not processed and input.KeyCode == self.OpenKey then
            self:ToggleMenu()
        end
    end)
    
    self:Log("System", "⌨️ Keybind configurado! Pressione [F] para abrir/fechar", {})
end

--═══════════════════════════════════════════════════════════
-- INICIALIZAÇÃO
--═══════════════════════════════════════════════════════════

function SecurityMenu:Init()
    if self.IsInitialized then
        warn("SecurityMenu já foi inicializado!")
        return false
    end
    
    self:Log("System", "🚀 Iniciando Security Menu v2.0...", {})
    
    local success, err = pcall(function()
        -- Criar interface
        self:CreateUI()
        
        -- Configurar keybind
        self:SetupKeybind()
        
        -- Iniciar monitoramentos com delays
        task.wait(1)
        self:MonitorRemoteEvents()
        
        task.wait(0.3)
        self:MonitorCharacter()
        
        task.wait(0.3)
        self:MonitorInputs()
        
        task.wait(0.3)
        self:MonitorNetwork()
        
        self.IsInitialized = true
        self:Log("System", "✅ SECURITY MENU PRONTO! Pressione [F] para abrir", {})
        
        -- Auto-abrir pela primeira vez
        task.wait(1)
        self:ToggleMenu()
    end)
    
    if not success then
        warn("SecurityMenu: Erro na inicialização:", err)
        return false
    end
    
    return true
end

--═══════════════════════════════════════════════════════════
-- AUTO-INICIALIZAÇÃO
--═══════════════════════════════════════════════════════════

task.spawn(function()
    -- Esperar o jogo carregar completamente
    if not game:IsLoaded() then
        game.Loaded:Wait()
    end
    
    task.wait(2)
    
    print("═══════════════════════════════════════════════════")
    print("🔒 SECURITY MENU v2.0 - Advanced Pentest Tool")
    print("═══════════════════════════════════════════════════")
    
    local success = SecurityMenu:Init()
    
    if success then
        print("✅ Security Menu carregado com sucesso!")
        print("⌨️ Pressione [F] para abrir/fechar o menu")
        print("📡 Todos os Remote Events estão sendo monitorados")
        print("🔄 Sistema de Replay ativo e pronto!")
        print("═══════════════════════════════════════════════════")
    else
        print("❌ Falha ao carregar Security Menu")
        print("═══════════════════════════════════════════════════")
    end
end)

-- Tornar global
getgenv().SecurityMenu = SecurityMenu

return SecurityMenu
