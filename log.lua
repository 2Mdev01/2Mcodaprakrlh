-- Ultimate Security MOD MENU - COMPLETO E ORGANIZADO
-- APENAS para pentest autorizado

local UltimateMenu = {}
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")

-- Configurações
UltimateMenu.OpenKey = Enum.KeyCode.F5
UltimateMenu.IsOpen = false
UltimateMenu.CurrentTab = "Dashboard"

-- Sistema de logs organizado
UltimateMenu.Logs = {
    All = {},
    RemoteEvents = {},
    Character = {},
    Network = {},
    Inputs = {},
    Triggers = {},
    System = {},
    Errors = {}
}

UltimateMenu.Stats = {
    Total = 0,
    RemoteEvents = 0,
    Character = 0,
    Network = 0,
    Inputs = 0,
    Triggers = 0,
    System = 0,
    Errors = 0
}

UltimateMenu.TriggersList = {}
UltimateMenu.MonitoredRemotes = {}

-- Função de logging avançada
function UltimateMenu:AddLog(category, message, data)
    local logEntry = {
        ID = #self.Logs.All + 1,
        Time = os.date("%H:%M:%S"),
        Category = category,
        Message = message,
        Data = data or {},
        Timestamp = tick()
    }
    
    -- Adicionar aos logs
    table.insert(self.Logs.All, logEntry)
    table.insert(self.Logs[category], logEntry)
    
    -- Atualizar estatísticas
    self.Stats.Total = self.Stats.Total + 1
    self.Stats[category] = (self.Stats[category] or 0) + 1
    
    -- Print no console
    print("[" .. logEntry.Time .. "][" .. category .. "] " .. message)
    
    -- Verificar triggers
    self:CheckTriggers(category, logEntry)
    
    -- Atualizar UI
    if self.IsOpen then
        self:UpdateCurrentTab()
    end
end

-- Sistema de Triggers
function UltimateMenu:AddTrigger(name, condition, action)
    self.TriggersList[name] = {
        Condition = condition,
        Action = action,
        LastTrigger = 0
    }
    self:AddLog("System", "🔔 Trigger adicionado: " .. name)
end

function UltimateMenu:CheckTriggers(category, logEntry)
    for triggerName, trigger in pairs(self.TriggersList) do
        local now = tick()
        if now - trigger.LastTrigger > 1 then -- Cooldown de 1 segundo
            local shouldTrigger = true
            
            if trigger.Condition then
                local success, result = pcall(trigger.Condition, category, logEntry)
                shouldTrigger = success and result
            end
            
            if shouldTrigger then
                trigger.LastTrigger = now
                pcall(trigger.Action, logEntry)
                self:AddLog("Triggers", "🚨 TRIGGER: " .. triggerName, logEntry.Data)
            end
        end
    end
end

-- Monitoramento AVANÇADO de RemoteEvents
function UltimateMenu:MonitorRemoteEvents()
    self:AddLog("System", "Iniciando monitoramento de RemoteEvents...")
    
    local function instrumentRemote(remote)
        if UltimateMenu.MonitoredRemotes[remote] then return end
        
        local remoteType = remote.ClassName
        local remotePath = UltimateMenu:GetObjectPath(remote)
        
        if remote:IsA("RemoteEvent") then
            local originalFire = remote.FireServer
            remote.FireServer = function(self, ...)
                local args = {...}
                local success, result = pcall(originalFire, self, unpack(args))
                
                UltimateMenu:AddLog("RemoteEvents", 
                    "📡 " .. remote.Name .. " (FireServer)", {
                    Path = remotePath,
                    ArgsCount = #args,
                    Success = success,
                    Arguments = UltimateMenu:SanitizeArgs(args)
                })
                
                return result
            end
            
        elseif remote:IsA("RemoteFunction") then
            local originalInvoke = remote.InvokeServer
            remote.InvokeServer = function(self, ...)
                local args = {...}
                local success, result = pcall(originalInvoke, self, unpack(args))
                
                UltimateMenu:AddLog("RemoteEvents", 
                    "🔧 " .. remote.Name .. " (InvokeServer)", {
                    Path = remotePath,
                    ArgsCount = #args,
                    Success = success,
                    Result = tostring(result)
                })
                
                return result
            end
        end
        
        UltimateMenu.MonitoredRemotes[remote] = true
        UltimateMenu:AddLog("System", "✅ Monitorando: " .. remotePath)
    end

    -- Instrumentar de forma segura
    local function safeScanFolder(folder)
        local success, descendants = pcall(function()
            return folder:GetDescendants()
        end)
        
        if success then
            for _, child in ipairs(descendants) do
                if child:IsA("RemoteEvent") or child:IsA("RemoteFunction") then
                    pcall(instrumentRemote, child)
                end
            end
        end
    end

    -- Scan em pastas seguras
    local safeFolders = {ReplicatedStorage}
    for _, folder in ipairs(safeFolders) do
        safeScanFolder(folder)
    end

    -- Monitorar novos remotes
    pcall(function()
        ReplicatedStorage.DescendantAdded:Connect(function(descendant)
            if descendant:IsA("RemoteEvent") or descendant:IsA("RemoteFunction") then
                task.wait(0.5)
                pcall(instrumentRemote, descendant)
            end
        end)
    end)
end

-- Monitoramento COMPLETO de Character
function UltimateMenu:MonitorCharacter()
    local lastPosition = nil
    local lastHealth = 100
    
    RunService.Heartbeat:Connect(function()
        local player = Players.LocalPlayer
        if not player or not player.Character then return end
        
        local character = player.Character
        local humanoid = character:FindFirstChildOfClass("Humanoid")
        local rootPart = character:FindFirstChild("HumanoidRootPart")
        
        -- Monitorar movimento
        if rootPart then
            local currentPosition = rootPart.Position
            if lastPosition then
                local distance = (currentPosition - lastPosition).Magnitude
                if distance > 5 then
                    UltimateMenu:AddLog("Character", "🎯 Movimento detectado", {
                        Distance = math.floor(distance),
                        Velocity = math.floor(rootPart.Velocity.Magnitude),
                        Position = {
                            X = math.floor(currentPosition.X),
                            Y = math.floor(currentPosition.Y),
                            Z = math.floor(currentPosition.Z)
                        }
                    })
                end
            end
            lastPosition = currentPosition
        end
        
        -- Monitorar saúde
        if humanoid then
            local currentHealth = humanoid.Health
            if math.abs(currentHealth - lastHealth) > 5 then
                UltimateMenu:AddLog("Character", "❤️ Saúde alterada", {
                    De = math.floor(lastHealth),
                    Para = math.floor(currentHealth),
                    Diferenca = math.floor(currentHealth - lastHealth)
                })
            end
            lastHealth = currentHealth
        end
    end)
end

-- Monitoramento de Inputs
function UltimateMenu:MonitorInputs()
    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if not gameProcessed then
            if input.UserInputType == Enum.UserInputType.Keyboard then
                UltimateMenu:AddLog("Inputs", "⌨️ Tecla: " .. input.KeyCode.Name, {
                    KeyCode = input.KeyCode.Value
                })
            elseif input.UserInputType == Enum.UserInputType.MouseButton1 then
                UltimateMenu:AddLog("Inputs", "🖱️ Mouse Click", {
                    Position = input.Position
                })
            end
        end
    end)
end

-- Monitoramento de Network
function UltimateMenu:MonitorNetwork()
    Players.PlayerAdded:Connect(function(player)
        UltimateMenu:AddLog("Network", "👤 " .. player.Name .. " entrou", {
            UserId = player.UserId,
            AccountAge = player.AccountAge
        })
    end)
    
    Players.PlayerRemoving:Connect(function(player)
        UltimateMenu:AddLog("Network", "👋 " .. player.Name .. " saiu", {
            UserId = player.UserId
        })
    end)
end

-- Funções utilitárias
function UltimateMenu:GetObjectPath(obj)
    local path = obj.Name
    local parent = obj.Parent
    while parent and parent ~= game do
        path = parent.Name .. "/" .. path
        parent = parent.Parent
    end
    return path
end

function UltimateMenu:SanitizeArgs(args)
    local sanitized = {}
    for i, arg in ipairs(args) do
        local argType = type(arg)
        if argType == "string" then
            sanitized[i] = #arg > 30 and string.sub(arg, 1, 30) .. "..." : arg
        elseif argType == "number" then
            sanitized[i] = tostring(arg)
        elseif argType == "boolean" then
            sanitized[i] = tostring(arg)
        else
            sanitized[i] = argType
        end
    end
    return sanitized
end

-- Criar Interface PROFISSIONAL com Abas
function UltimateMenu:CreateUI()
    if self.ScreenGui then
        self.ScreenGui:Destroy()
    end
    
    self.ScreenGui = Instance.new("ScreenGui")
    self.ScreenGui.Parent = game:GetService("CoreGui")
    self.ScreenGui.Name = "UltimateSecurityMenu"
    
    -- Cores do tema
    local Theme = {
        Background = Color3.fromRGB(35, 35, 45),
        Header = Color3.fromRGB(50, 50, 60),
        Tab = Color3.fromRGB(60, 60, 70),
        TabActive = Color3.fromRGB(0, 120, 215),
        Text = Color3.fromRGB(255, 255, 255),
        TextSecondary = Color3.fromRGB(180, 180, 180),
        Success = Color3.fromRGB(76, 175, 80),
        Warning = Color3.fromRGB(255, 152, 0),
        Error = Color3.fromRGB(244, 67, 54)
    }
    
    -- Frame principal
    local MainFrame = Instance.new("Frame")
    MainFrame.Size = UDim2.new(0, 800, 0, 500)
    MainFrame.Position = UDim2.new(0.5, -400, 0.5, -250)
    MainFrame.BackgroundColor3 = Theme.Background
    MainFrame.BorderSizePixel = 0
    MainFrame.Visible = false
    MainFrame.Parent = self.ScreenGui
    
    -- Header
    local Header = Instance.new("Frame")
    Header.Size = UDim2.new(1, 0, 0, 40)
    Header.BackgroundColor3 = Theme.Header
    Header.BorderSizePixel = 0
    Header.Parent = MainFrame
    
    local Title = Instance.new("TextLabel")
    Title.Size = UDim2.new(1, -100, 1, 0)
    Title.Position = UDim2.new(0, 15, 0, 0)
    Title.BackgroundTransparency = 1
    Title.Text = "🔒 ULTIMATE SECURITY MENU"
    Title.TextColor3 = Theme.Text
    Title.TextXAlignment = Enum.TextXAlignment.Left
    Title.Font = Enum.Font.GothamBold
    Title.TextSize = 16
    Title.Parent = Header
    
    local CloseBtn = Instance.new("TextButton")
    CloseBtn.Size = UDim2.new(0, 80, 0, 25)
    CloseBtn.Position = UDim2.new(1, -85, 0.5, -12)
    CloseBtn.BackgroundColor3 = Theme.Error
    CloseBtn.BorderSizePixel = 0
    CloseBtn.Text = "FECHAR [F5]"
    CloseBtn.TextColor3 = Theme.Text
    CloseBtn.Font = Enum.Font.GothamBold
    CloseBtn.TextSize = 12
    CloseBtn.Parent = Header
    
    -- Tabs
    local TabContainer = Instance.new("Frame")
    TabContainer.Size = UDim2.new(1, 0, 0, 35)
    TabContainer.Position = UDim2.new(0, 0, 0, 40)
    TabContainer.BackgroundColor3 = Theme.Tab
    TabContainer.BorderSizePixel = 0
    TabContainer.Parent = MainFrame
    
    local Tabs = {"Dashboard", "RemoteEvents", "Character", "Network", "Inputs", "Triggers", "Logs"}
    self.TabButtons = {}
    
    for i, tabName in ipairs(Tabs) do
        local TabButton = Instance.new("TextButton")
        TabButton.Size = UDim2.new(0, 114, 1, 0)
        TabButton.Position = UDim2.new(0, (i-1)*114, 0, 0)
        TabButton.BackgroundColor3 = Theme.Tab
        TabButton.BorderSizePixel = 0
        TabButton.Text = tabName
        TabButton.TextColor3 = Theme.TextSecondary
        TabButton.Font = Enum.Font.Gotham
        TabButton.TextSize = 12
        TabButton.Parent = TabContainer
        
        TabButton.MouseButton1Click:Connect(function()
            self:SwitchTab(tabName)
        end)
        
        self.TabButtons[tabName] = TabButton
    end
    
    -- Área de conteúdo
    local ContentFrame = Instance.new("Frame")
    ContentFrame.Size = UDim2.new(1, 0, 1, -75)
    ContentFrame.Position = UDim2.new(0, 0, 0, 75)
    ContentFrame.BackgroundTransparency = 1
    ContentFrame.Parent = MainFrame
    
    -- Criar frames para cada tab
    self.ContentFrames = {}
    
    for _, tabName in ipairs(Tabs) do
        local Frame = Instance.new("ScrollingFrame")
        Frame.Size = UDim2.new(1, 0, 1, 0)
        Frame.Position = UDim2.new(0, 0, 0, 0)
        Frame.BackgroundTransparency = 1
        Frame.BorderSizePixel = 0
        Frame.ScrollBarThickness = 8
        Frame.ScrollBarImageColor3 = Theme.TabActive
        Frame.Visible = false
        Frame.AutomaticCanvasSize = Enum.AutomaticSize.Y
        Frame.Parent = ContentFrame
        
        local Layout = Instance.new("UIListLayout")
        Layout.Padding = UDim.new(0, 10)
        Layout.Parent = Frame
        
        self.ContentFrames[tabName] = Frame
    end
    
    -- Configurar eventos
    CloseBtn.MouseButton1Click:Connect(function()
        self:ToggleMenu()
    end)
    
    self.MainFrame = MainFrame
    self.Theme = Theme
    
    -- Selecionar tab inicial
    self:SwitchTab("Dashboard")
end

-- Sistema de Abas
function UltimateMenu:SwitchTab(tabName)
    self.CurrentTab = tabName
    
    -- Esconder todas as tabs
    for name, frame in pairs(self.ContentFrames) do
        frame.Visible = false
        -- Limpar conteúdo anterior
        for _, child in ipairs(frame:GetChildren()) do
            if child:IsA("Frame") then
                child:Destroy()
            end
        end
    end
    
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
    
    -- Mostrar tab atual
    if self.ContentFrames[tabName] then
        self.ContentFrames[tabName].Visible = true
        self:UpdateTabContent(tabName)
    end
end

function UltimateMenu:UpdateCurrentTab()
    self:UpdateTabContent(self.CurrentTab)
end

function UltimateMenu:UpdateTabContent(tabName)
    local frame = self.ContentFrames[tabName]
    if not frame then return end
    
    if tabName == "Dashboard" then
        self:CreateDashboardContent(frame)
    elseif tabName == "RemoteEvents" then
        self:CreateRemoteEventsContent(frame)
    elseif tabName == "Character" then
        self:CreateCharacterContent(frame)
    elseif tabName == "Network" then
        self:CreateNetworkContent(frame)
    elseif tabName == "Inputs" then
        self:CreateInputsContent(frame)
    elseif tabName == "Triggers" then
        self:CreateTriggersContent(frame)
    elseif tabName == "Logs" then
        self:CreateLogsContent(frame)
    end
end

-- Conteúdo das Abas
function UltimateMenu:CreateDashboardContent(frame)
    -- Estatísticas
    local statsFrame = self:CreateSection(frame, "📊 ESTATÍSTICAS EM TEMPO REAL", 10)
    
    local stats = {
        {"Eventos Totais", "Total", self.Theme.Text},
        {"Remote Events", "RemoteEvents", self.Theme.Success},
        {"Character Events", "Character", self.Theme.Success},
        {"Network Events", "Network", self.Theme.Success},
        {"Input Events", "Inputs", self.Theme.Success},
        {"Triggers", "Triggers", self.Theme.Warning},
        {"Erros", "Errors", self.Theme.Error}
    }
    
    for i, stat in ipairs(stats) do
        self:CreateStatRow(statsFrame, stat[1], self.Stats[stat[2]], stat[3], i)
    end
    
    -- Controles
    local controlsFrame = self:CreateSection(frame, "🛠️ CONTROLES", 180)
    
    local clearBtn = Instance.new("TextButton")
    clearBtn.Size = UDim2.new(0, 150, 0, 30)
    clearBtn.Position = UDim2.new(0, 20, 0, 30)
    clearBtn.BackgroundColor3 = self.Theme.Warning
    clearBtn.BorderSizePixel = 0
    clearBtn.Text = "🧹 LIMPAR LOGS"
    clearBtn.TextColor3 = self.Theme.Text
    clearBtn.Font = Enum.Font.GothamBold
    clearBtn.TextSize = 12
    clearBtn.Parent = controlsFrame
    
    clearBtn.MouseButton1Click:Connect(function()
        self:ClearAllLogs()
    end)
end

function UltimateMenu:CreateRemoteEventsContent(frame)
    local section = self:CreateSection(frame, "📡 REMOTE EVENTS MONITORADOS", 10)
    
    local monitoredCount = 0
    for _ in pairs(self.MonitoredRemotes) do
        monitoredCount = monitoredCount + 1
    end
    
    self:CreateInfoRow(section, "Remotes Monitorados", tostring(monitoredCount), 1)
    self:CreateInfoRow(section, "Eventos Capturados", tostring(self.Stats.RemoteEvents), 2)
    
    -- Últimos eventos
    local eventsFrame = self:CreateSection(frame, "🔍 ÚLTIMOS EVENTOS", 80)
    self:DisplayLogsInSection(eventsFrame, self.Logs.RemoteEvents, 10)
end

function UltimateMenu:CreateCharacterContent(frame)
    local section = self:CreateSection(frame, "🎯 MONITORAMENTO DO PERSONAGEM", 10)
    self:CreateInfoRow(section, "Eventos Capturados", tostring(self.Stats.Character), 1)
    
    local eventsFrame = self:CreateSection(frame, "📝 ATIVIDADE RECENTE", 50)
    self:DisplayLogsInSection(eventsFrame, self.Logs.Character, 8)
end

function UltimateMenu:CreateNetworkContent(frame)
    local section = self:CreateSection(frame, "🌐 ATIVIDADE DE REDE", 10)
    self:CreateInfoRow(section, "Eventos Capturados", tostring(self.Stats.Network), 1)
    
    local eventsFrame = self:CreateSection(frame, "👥 PLAYERS RECENTES", 50)
    self:DisplayLogsInSection(eventsFrame, self.Logs.Network, 8)
end

function UltimateMenu:CreateInputsContent(frame)
    local section = self:CreateSection(frame, "⌨️ MONITORAMENTO DE INPUTS", 10)
    self:CreateInfoRow(section, "Inputs Capturados", tostring(self.Stats.Inputs), 1)
    
    local eventsFrame = self:CreateSection(frame, "🔑 INPUTS RECENTES", 50)
    self:DisplayLogsInSection(eventsFrame, self.Logs.Inputs, 10)
end

function UltimateMenu:CreateTriggersContent(frame)
    local section = self:CreateSection(frame, "🚨 SISTEMA DE TRIGGERS", 10)
    
    local triggerCount = 0
    for _ in pairs(self.TriggersList) do
        triggerCount = triggerCount + 1
    end
    
    self:CreateInfoRow(section, "Triggers Ativos", tostring(triggerCount), 1)
    self:CreateInfoRow(section, "Triggers Acionados", tostring(self.Stats.Triggers), 2)
    
    -- Triggers ativos
    local triggersFrame = self:CreateSection(frame, "⚡ TRIGGERS ATIVOS", 60)
    local i = 1
    for triggerName, _ in pairs(self.TriggersList) do
        self:CreateInfoRow(triggersFrame, "• " .. triggerName, "Ativo", i)
        i = i + 1
    end
    
    -- Últimos triggers acionados
    local eventsFrame = self:CreateSection(frame, "📋 TRIGGERS RECENTES", 150)
    self:DisplayLogsInSection(eventsFrame, self.Logs.Triggers, 6)
end

function UltimateMenu:CreateLogsContent(frame)
    local section = self:CreateSection(frame, "📝 TODOS OS LOGS", 10)
    self:CreateInfoRow(section, "Total de Logs", tostring(self.Stats.Total), 1)
    
    local logsFrame = self:CreateSection(frame, "🔍 LOGS RECENTES", 50)
    self:DisplayLogsInSection(logsFrame, self.Logs.All, 15)
end

-- Funções auxiliares para UI
function UltimateMenu:CreateSection(parent, title, yPosition)
    local section = Instance.new("Frame")
    section.Size = UDim2.new(1, -20, 0, 0)
    section.Position = UDim2.new(0, 10, 0, yPosition)
    section.BackgroundColor3 = self.Theme.Header
    section.BorderSizePixel = 0
    section.AutomaticSize = Enum.AutomaticSize.Y
    section.Parent = parent
    
    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, 5)
    layout.Parent = section
    
    if title then
        local titleLabel = Instance.new("TextLabel")
        titleLabel.Size = UDim2.new(1, -10, 0, 25)
        titleLabel.Position = UDim2.new(0, 10, 0, 5)
        titleLabel.BackgroundTransparency = 1
        titleLabel.Text = title
        titleLabel.TextColor3 = self.Theme.Text
        titleLabel.TextXAlignment = Enum.TextXAlignment.Left
        titleLabel.Font = Enum.Font.GothamBold
        titleLabel.TextSize = 14
        titleLabel.Parent = section
    end
    
    return section
end

function UltimateMenu:CreateStatRow(parent, label, value, color, index)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, -20, 0, 20)
    row.Position = UDim2.new(0, 10, 0, 30 + (index-1)*25)
    row.BackgroundTransparency = 1
    row.Parent = parent
    
    local labelText = Instance.new("TextLabel")
    labelText.Size = UDim2.new(0.7, 0, 1, 0)
    labelText.Position = UDim2.new(0, 0, 0, 0)
    labelText.BackgroundTransparency = 1
    labelText.Text = label
    labelText.TextColor3 = self.Theme.Text
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
    valueText.TextSize = 12
    valueText.Parent = row
end

function UltimateMenu:CreateInfoRow(parent, label, value, index)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, -20, 0, 20)
    row.Position = UDim2.new(0, 10, 0, 30 + (index-1)*25)
    row.BackgroundTransparency = 1
    row.Parent = parent
    
    local labelText = Instance.new("TextLabel")
    labelText.Size = UDim2.new(0.6, 0, 1, 0)
    labelText.Position = UDim2.new(0, 0, 0, 0)
    labelText.BackgroundTransparency = 1
    labelText.Text = label
    labelText.TextColor3 = self.Theme.TextSecondary
    labelText.TextXAlignment = Enum.TextXAlignment.Left
    labelText.Font = Enum.Font.Gotham
    labelText.TextSize = 11
    labelText.Parent = row
    
    local valueText = Instance.new("TextLabel")
    valueText.Size = UDim2.new(0.4, 0, 1, 0)
    valueText.Position = UDim2.new(0.6, 0, 0, 0)
    valueText.BackgroundTransparency = 1
    valueText.Text = value
    valueText.TextColor3 = self.Theme.Success
    valueText.TextXAlignment = Enum.TextXAlignment.Right
    valueText.Font = Enum.Font.GothamBold
    valueText.TextSize = 11
    valueText.Parent = row
end

function UltimateMenu:DisplayLogsInSection(section, logs, maxLogs)
    local recentLogs = {}
    for i = math.max(1, #logs - maxLogs + 1), #logs do
        table.insert(recentLogs, logs[i])
    end
    
    for i, log in ipairs(recentLogs) do
        self:CreateLogRow(section, log, i)
    end
end

function UltimateMenu:CreateLogRow(parent, log, index)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, -20, 0, 30)
    row.Position = UDim2.new(0, 10, 0, 30 + (index-1)*35)
    row.BackgroundColor3 = self.Theme.Tab
    row.BorderSizePixel = 0
    row.Parent = parent
    
    local timeLabel = Instance.new("TextLabel")
    timeLabel.Size = UDim2.new(0, 50, 0, 15)
    timeLabel.Position = UDim2.new(0, 5, 0, 2)
    timeLabel.BackgroundTransparency = 1
    timeLabel.Text = log.Time
    timeLabel.TextColor3 = self.Theme.TextSecondary
    timeLabel.TextXAlignment = Enum.TextXAlignment.Left
    timeLabel.Font = Enum.Font.Gotham
    timeLabel.TextSize = 9
    timeLabel.Parent = row
    
    local catLabel = Instance.new("TextLabel")
    catLabel.Size = UDim2.new(0, 80, 0, 15)
    catLabel.Position = UDim2.new(0, 60, 0, 2)
    catLabel.BackgroundTransparency = 1
    catLabel.Text = "[" .. log.Category .. "]"
    catLabel.TextColor3 = self.Theme.TextSecondary
    catLabel.TextXAlignment = Enum.TextXAlignment.Left
    catLabel.Font = Enum.Font.Gotham
    catLabel.TextSize = 9
    catLabel.Parent = row
    
    local msgLabel = Instance.new("TextLabel")
    msgLabel.Size = UDim2.new(1, -150, 0, 20)
    msgLabel.Position = UDim2.new(0, 145, 0, 5)
    msgLabel.BackgroundTransparency = 1
    msgLabel.Text = log.Message
    msgLabel.TextColor3 = self.Theme.Text
    msgLabel.TextXAlignment = Enum.TextXAlignment.Left
    msgLabel.Font = Enum.Font.Gotham
    msgLabel.TextSize = 11
    msgLabel.TextTruncate = Enum.TextTruncate.AtEnd
    msgLabel.Parent = row
end

function UltimateMenu:ClearAllLogs()
    for category, _ in pairs(self.Logs) do
        self.Logs[category] = {}
    end
    
    for stat, _ in pairs(self.Stats) do
        self.Stats[stat] = 0
    end
    
    self:AddLog("System", "🧹 Todos os logs foram limpos")
end

function UltimateMenu:ToggleMenu()
    self.IsOpen = not self.IsOpen
    self.MainFrame.Visible = self.IsOpen
    
    if self.IsOpen then
        self:UpdateCurrentTab()
    end
end

-- Keybind
function UltimateMenu:SetupKeybind()
    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if not gameProcessed and input.KeyCode == self.OpenKey then
            self:ToggleMenu()
        end
    end)
end

-- Triggers de Exemplo
function UltimateMenu:SetupExampleTriggers()
    -- Trigger para movimento rápido
    self:AddTrigger("MovimentoRapido",
        function(category, logEntry)
            return category == "Character" 
                and logEntry.Data 
                and logEntry.Data.Distance 
                and logEntry.Data.Distance > 30
        end,
        function(logEntry)
            -- Ação customizada pode ser adicionada aqui
        end
    )
    
    -- Trigger para muitos RemoteEvents
    self:AddTrigger("SpamRemoteEvents",
        function(category, logEntry)
            if category == "RemoteEvents" then
                -- Verificar se há muitos eventos em pouco tempo
                local recentCount = 0
                local now = tick()
                for _, log in ipairs(self.Logs.RemoteEvents) do
                    if now - log.Timestamp < 2 then -- Últimos 2 segundos
                        recentCount = recentCount + 1
                    end
                end
                return recentCount > 5
            end
            return false
        end,
        function(logEntry)
            -- Ação para spam detection
        end
    )
end

-- Inicialização
function UltimateMenu:Init()
    self:AddLog("System", "🚀 Iniciando Ultimate Security Menu...")
    
    self:CreateUI()
    self:SetupKeybind()
    self:SetupExampleTriggers()
    
    -- Iniciar monitoramentos com delays
    task.wait(2)
    self:MonitorRemoteEvents()
    task.wait(1)
    self:MonitorCharacter()
    task.wait(1)
    self:MonitorInputs()
    task.wait(1)
    self:MonitorNetwork()
    
    self:AddLog("System", "✅ ULTIMATE MENU PRONTO! Pressione F5")
    
    return true
end

-- Iniciar automaticamente
task.spawn(function()
    task.wait(3)
    UltimateMenu:Init()
end)

-- Tornar global
getgenv().UltimateMenu = UltimateMenu

return UltimateMenu
