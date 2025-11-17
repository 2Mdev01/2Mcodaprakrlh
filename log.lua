-- Advanced Security MOD MENU - VERSAO FINAL FUNCIONAL
-- APENAS para pentest autorizado em servidores próprios

local AdvancedSecurityMenu = {}
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TextService = game:GetService("TextService")

-- Configurações
AdvancedSecurityMenu.Config = {
    Keybind = Enum.KeyCode.F5,
    Theme = "Dark",
    AutoStart = true
}

-- Dados
AdvancedSecurityMenu.Logs = {
    All = {},
    RemoteEvents = {},
    Character = {},
    Network = {},
    Inputs = {},
    Triggers = {},
    Errors = {}
}

AdvancedSecurityMenu.Statistics = {
    totalEvents = 0,
    remoteEvents = 0,
    characterEvents = 0,
    networkEvents = 0,
    inputs = 0,
    triggers = 0,
    errors = 0
}

AdvancedSecurityMenu.MonitoredRemotes = {}
AdvancedSecurityMenu.Triggers = {}
AdvancedSecurityMenu.IsMenuOpen = false
AdvancedSecurityMenu.CurrentTab = "Dashboard"
AdvancedSecurityMenu.UIData = {}

-- Cores do tema
local CurrentTheme = {
    Background = Color3.fromRGB(30, 30, 40),
    Header = Color3.fromRGB(45, 45, 55),
    Tab = Color3.fromRGB(50, 50, 60),
    TabActive = Color3.fromRGB(0, 120, 215),
    Text = Color3.fromRGB(255, 255, 255),
    TextSecondary = Color3.fromRGB(200, 200, 200),
    Success = Color3.fromRGB(76, 175, 80),
    Warning = Color3.fromRGB(255, 152, 0),
    Error = Color3.fromRGB(244, 67, 54),
    LogDebug = Color3.fromRGB(100, 100, 255),
    LogInfo = Color3.fromRGB(255, 255, 255),
    LogWarn = Color3.fromRGB(255, 152, 0),
    LogError = Color3.fromRGB(244, 67, 54)
}

-- Função de logging MELHORADA
function AdvancedSecurityMenu:AddLog(category, level, message, data)
    local logEntry = {
        Category = category,
        Level = level,
        Message = message,
        Data = data or {},
        Timestamp = os.time(),
        TimeFormatted = os.date("%H:%M:%S"),
        Tick = tick(),
        ID = #self.Logs.All + 1
    }
    
    -- Adicionar aos logs
    table.insert(self.Logs.All, logEntry)
    if self.Logs[category] then
        table.insert(self.Logs[category], logEntry)
    end
    
    -- Atualizar estatísticas
    self.Statistics.totalEvents += 1
    if category == "RemoteEvents" then self.Statistics.remoteEvents += 1
    elseif category == "Character" then self.Statistics.characterEvents += 1
    elseif category == "Network" then self.Statistics.networkEvents += 1
    elseif category == "Inputs" then self.Statistics.inputs += 1
    elseif category == "Triggers" then self.Statistics.triggers += 1
    elseif category == "Errors" then self.Statistics.errors += 1 end
    
    -- Limitar logs
    for _, logTable in pairs(self.Logs) do
        while #logTable > 200 do
            table.remove(logTable, 1)
        end
    end
    
    -- Atualizar UI se estiver aberta
    if self.IsMenuOpen then
        self:RefreshCurrentTab()
    end
    
    -- Print no console
    local levelColor = ""
    if level == "ERROR" then levelColor = "❌"
    elseif level == "WARNING" then levelColor = "⚠️"
    elseif level == "SUCCESS" then levelColor = "✅"
    else levelColor = "ℹ️" end
    
    print(string.format("%s [%s] %s: %s", levelColor, category, level, message))
end

-- Sistema de instrumentação MELHORADO
function AdvancedSecurityMenu:InstrumentRemoteEvents()
    self:AddLog("System", "INFO", "Starting RemoteEvents instrumentation...")
    
    local function safeInstrument(remote)
        if self.MonitoredRemotes[remote] then return true end
        
        local success, result = pcall(function()
            if not remote:IsA("RemoteEvent") and not remote:IsA("RemoteFunction") then
                return false, "Not a RemoteEvent or RemoteFunction"
            end
            
            local remoteName = remote.Name
            local remotePath = self:GetObjectPath(remote)
            
            if remote:IsA("RemoteEvent") then
                local originalFire = remote.FireServer
                if type(originalFire) ~= "function" then
                    return false, "FireServer is not a function"
                end
                
                remote.FireServer = function(self, ...)
                    local args = {...}
                    local callSuccess, callResult = pcall(originalFire, self, unpack(args))
                    
                    AdvancedSecurityMenu:AddLog("RemoteEvents", "INFO", 
                        string.format("📡 %s", remoteName), {
                        Path = remotePath,
                        ArgsCount = #args,
                        Success = callSuccess,
                        Args = AdvancedSecurityMenu:SanitizeArgs(args)
                    })
                    
                    if not callSuccess then
                        AdvancedSecurityMenu:AddLog("Errors", "ERROR", 
                            string.format("RemoteEvent failed: %s", remoteName), {
                            Error = callResult
                        })
                    end
                    
                    return callResult
                end
                
            elseif remote:IsA("RemoteFunction") then
                local originalInvoke = remote.InvokeServer
                if type(originalInvoke) ~= "function" then
                    return false, "InvokeServer is not a function"
                end
                
                remote.InvokeServer = function(self, ...)
                    local args = {...}
                    local callSuccess, callResult = pcall(originalInvoke, self, unpack(args))
                    
                    AdvancedSecurityMenu:AddLog("RemoteEvents", "INFO", 
                        string.format("🔧 %s", remoteName), {
                        Path = remotePath,
                        ArgsCount = #args,
                        Success = callSuccess,
                        Result = tostring(callResult)
                    })
                    
                    return callResult
                end
            end
            
            self.MonitoredRemotes[remote] = true
            return true, "Success"
        end)
        
        if not success then
            self:AddLog("Errors", "ERROR", 
                string.format("Instrumentation failed: %s", remote.Name), {
                Error = result,
                Path = self:GetObjectPath(remote)
            })
            return false
        end
        
        return true
    end

    -- Instrumentar com proteção máxima
    local function scanFolder(folder)
        local success, descendants = pcall(function()
            return folder:GetDescendants()
        end)
        
        if not success then return 0 end
        
        local count = 0
        for _, child in ipairs(descendants) do
            if child:IsA("RemoteEvent") or child:IsA("RemoteFunction") then
                if safeInstrument(child) then
                    count += 1
                end
            end
        end
        return count
    end

    -- Scan em pastas importantes
    local folders = {
        ReplicatedStorage,
        workspace,
        game:GetService("Lighting"),
        game:GetService("StarterPack"),
        game:GetService("StarterGui")
    }
    
    local totalInstrumented = 0
    for _, folder in ipairs(folders) do
        totalInstrumented += scanFolder(folder)
    end
    
    self:AddLog("System", "SUCCESS", 
        string.format("Instrumented %d RemoteEvents/RemoteFunctions", totalInstrumented))
    
    -- Monitorar novos remotes
    pcall(function()
        ReplicatedStorage.DescendantAdded:Connect(function(descendant)
            if descendant:IsA("RemoteEvent") or descendant:IsA("RemoteFunction") then
                task.wait(0.5)
                safeInstrument(descendant)
            end
        end)
    end)
end

-- Funções utilitárias
function AdvancedSecurityMenu:GetObjectPath(obj)
    local path = obj.Name
    local parent = obj.Parent
    while parent and parent ~= game do
        path = parent.Name .. "/" .. path
        parent = parent.Parent
    end
    return path
end

function AdvancedSecurityMenu:SanitizeArgs(args)
    local sanitized = {}
    for i, arg in ipairs(args) do
        local argType = type(arg)
        if argType == "string" then
            sanitized[i] = #arg > 50 and string.sub(arg, 1, 50) .. "..." : arg
        elseif argType == "number" then
            sanitized[i] = tostring(arg)
        elseif argType == "boolean" then
            sanitized[i] = tostring(arg)
        elseif argType == "table" then
            sanitized[i] = "table:" .. tostring(#arg)
        else
            sanitized[i] = argType
        end
    end
    return sanitized
end

-- Monitoramento de Character
function AdvancedSecurityMenu:MonitorCharacter()
    local lastPosition = nil
    local lastHealth = nil
    
    RunService.Heartbeat:Connect(function()
        local success, result = pcall(function()
            local player = Players.LocalPlayer
            if not player or not player.Character then return end
            
            local character = player.Character
            local humanoid = character:FindFirstChildOfClass("Humanoid")
            local rootPart = character:FindFirstChild("HumanoidRootPart")
            
            if rootPart then
                local currentPosition = rootPart.Position
                if lastPosition then
                    local distance = (currentPosition - lastPosition).Magnitude
                    if distance > 2 then
                        self:AddLog("Character", "INFO", "🎯 Character moved", {
                            Distance = math.floor(distance * 100) / 100,
                            Position = {
                                X = math.floor(currentPosition.X),
                                Y = math.floor(currentPosition.Y), 
                                Z = math.floor(currentPosition.Z)
                            },
                            Velocity = math.floor(rootPart.Velocity.Magnitude * 100) / 100
                        })
                    end
                end
                lastPosition = currentPosition
            end
            
            if humanoid then
                local currentHealth = humanoid.Health
                if lastHealth and math.abs(currentHealth - lastHealth) > 2 then
                    self:AddLog("Character", "INFO", "❤️ Health changed", {
                        From = math.floor(lastHealth),
                        To = math.floor(currentHealth),
                        Difference = math.floor(currentHealth - lastHealth)
                    })
                end
                lastHealth = currentHealth
            end
        end)
        
        if not success then
            -- Erro silencioso
        end
    end)
end

-- Monitoramento de Inputs
function AdvancedSecurityMenu:MonitorInputs()
    local success, result = pcall(function()
        UserInputService.InputBegan:Connect(function(input, gameProcessed)
            if not gameProcessed and input.UserInputType == Enum.UserInputType.Keyboard then
                self:AddLog("Inputs", "DEBUG", "⌨️ " .. input.KeyCode.Name, {
                    KeyCode = input.KeyCode.Value,
                    UserInputType = input.UserInputType.Name
                })
            end
        end)
    end)
    
    if not success then
        self:AddLog("Errors", "ERROR", "Failed to monitor inputs", {Error = result})
    end
end

-- Monitoramento de Network
function AdvancedSecurityMenu:MonitorNetwork()
    local success, result = pcall(function()
        Players.PlayerAdded:Connect(function(player)
            self:AddLog("Network", "INFO", "👤 " .. player.Name .. " joined", {
                UserId = player.UserId,
                AccountAge = player.AccountAge,
                Membership = player.MembershipType.Name
            })
        end)
        
        Players.PlayerRemoving:Connect(function(player)
            self:AddLog("Network", "INFO", "👋 " .. player.Name .. " left", {
                UserId = player.UserId
            })
        end)
    end)
    
    if not success then
        self:AddLog("Errors", "ERROR", "Failed to monitor network", {Error = result})
    end
end

-- Criar Interface COMPLETA
function AdvancedSecurityMenu:CreateMenu()
    if self.ScreenGui then 
        pcall(function() self.ScreenGui:Destroy() end) 
    end
    
    self.ScreenGui = Instance.new("ScreenGui")
    if gethui then
        self.ScreenGui.Parent = gethui()
    else
        self.ScreenGui.Parent = game:GetService("CoreGui")
    end
    self.ScreenGui.Name = "AdvancedSecurityMenu"
    
    -- Frame principal
    local MainFrame = Instance.new("Frame")
    MainFrame.Size = UDim2.new(0, 700, 0, 500)
    MainFrame.Position = UDim2.new(0.5, -350, 0.5, -250)
    MainFrame.BackgroundColor3 = CurrentTheme.Background
    MainFrame.BorderSizePixel = 0
    MainFrame.Visible = false
    MainFrame.Parent = self.ScreenGui
    
    -- Header
    local Header = Instance.new("Frame")
    Header.Size = UDim2.new(1, 0, 0, 40)
    Header.BackgroundColor3 = CurrentTheme.Header
    Header.BorderSizePixel = 0
    Header.Parent = MainFrame
    
    local Title = Instance.new("TextLabel")
    Title.Size = UDim2.new(1, -100, 1, 0)
    Title.Position = UDim2.new(0, 15, 0, 0)
    Title.BackgroundTransparency = 1
    Title.Text = "🔒 ADVANCED SECURITY MOD MENU"
    Title.TextColor3 = CurrentTheme.Text
    Title.TextXAlignment = Enum.TextXAlignment.Left
    Title.Font = Enum.Font.GothamBold
    Title.TextSize = 16
    Title.Parent = Header
    
    local CloseButton = Instance.new("TextButton")
    CloseButton.Size = UDim2.new(0, 80, 0, 25)
    CloseButton.Position = UDim2.new(1, -85, 0.5, -12.5)
    CloseButton.BackgroundColor3 = CurrentTheme.Error
    CloseButton.BorderSizePixel = 0
    CloseButton.Text = "CLOSE [F5]"
    CloseButton.TextColor3 = CurrentTheme.Text
    Title.Font = Enum.Font.GothamBold
    CloseButton.TextSize = 12
    CloseButton.Parent = Header
    
    -- Tabs
    local TabContainer = Instance.new("Frame")
    TabContainer.Size = UDim2.new(1, 0, 0, 35)
    TabContainer.Position = UDim2.new(0, 0, 0, 40)
    TabContainer.BackgroundColor3 = CurrentTheme.Tab
    TabContainer.BorderSizePixel = 0
    TabContainer.Parent = MainFrame
    
    local Tabs = {"Dashboard", "RemoteEvents", "Character", "Network", "Inputs", "Triggers", "Logs"}
    self.TabButtons = {}
    
    for i, tabName in ipairs(Tabs) do
        local TabButton = Instance.new("TextButton")
        TabButton.Size = UDim2.new(0, 100, 1, 0)
        TabButton.Position = UDim2.new(0, (i-1)*100, 0, 0)
        TabButton.BackgroundColor3 = CurrentTheme.Tab
        TabButton.BorderSizePixel = 0
        TabButton.Text = tabName
        TabButton.TextColor3 = CurrentTheme.TextSecondary
        TabButton.Font = Enum.Font.Gotham
        TabButton.TextSize = 12
        TabButton.Parent = TabContainer
        
        TabButton.MouseButton1Click:Connect(function()
            self:SwitchTab(tabName)
        end)
        
        self.TabButtons[tabName] = TabButton
    end
    
    -- Content Area
    local ContentFrame = Instance.new("Frame")
    ContentFrame.Size = UDim2.new(1, 0, 1, -75)
    ContentFrame.Position = UDim2.new(0, 0, 0, 75)
    ContentFrame.BackgroundTransparency = 1
    ContentFrame.Parent = MainFrame
    
    -- Criar frames de conteúdo
    self.ContentFrames = {}
    
    for _, tabName in ipairs(Tabs) do
        local Frame = Instance.new("ScrollingFrame")
        Frame.Size = UDim2.new(1, 0, 1, 0)
        Frame.Position = UDim2.new(0, 0, 0, 0)
        Frame.BackgroundTransparency = 1
        Frame.BorderSizePixel = 0
        Frame.ScrollBarThickness = 8
        Frame.ScrollBarImageColor3 = CurrentTheme.TabActive
        Frame.Visible = false
        Frame.AutomaticCanvasSize = Enum.AutomaticSize.Y
        Frame.Parent = ContentFrame
        
        local UIListLayout = Instance.new("UIListLayout")
        UIListLayout.Padding = UDim.new(0, 5)
        UIListLayout.Parent = Frame
        
        self.ContentFrames[tabName] = Frame
    end
    
    -- Configurar eventos
    CloseButton.MouseButton1Click:Connect(function()
        self:ToggleMenu()
    end)
    
    self.MainFrame = MainFrame
    
    -- Selecionar tab inicial
    self:SwitchTab("Dashboard")
end

-- Sistema de tabs FUNCIONAL
function AdvancedSecurityMenu:SwitchTab(tabName)
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
            button.BackgroundColor3 = CurrentTheme.TabActive
            button.TextColor3 = CurrentTheme.Text
        else
            button.BackgroundColor3 = CurrentTheme.Tab
            button.TextColor3 = CurrentTheme.TextSecondary
        end
    end
    
    -- Mostrar tab atual
    if self.ContentFrames[tabName] then
        self.ContentFrames[tabName].Visible = true
        self:RefreshTabContent(tabName)
    end
end

function AdvancedSecurityMenu:RefreshCurrentTab()
    self:RefreshTabContent(self.CurrentTab)
end

function AdvancedSecurityMenu:RefreshTabContent(tabName)
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

-- Conteúdo das tabs
function AdvancedSecurityMenu:CreateDashboardContent(frame)
    -- Estatísticas
    local statsFrame = self:CreateSection(frame, "📊 REAL-TIME STATISTICS", 10)
    
    local stats = {
        {"Total Events", "totalEvents", CurrentTheme.Text},
        {"Remote Events", "remoteEvents", CurrentTheme.LogInfo},
        {"Character Events", "characterEvents", CurrentTheme.LogInfo},
        {"Network Events", "networkEvents", CurrentTheme.LogInfo},
        {"Input Events", "inputs", CurrentTheme.LogInfo},
        {"Triggers Activated", "triggers", CurrentTheme.Warning},
        {"Errors", "errors", CurrentTheme.Error}
    }
    
    for i, stat in ipairs(stats) do
        self:CreateStatRow(statsFrame, stat[1], self.Statistics[stat[2]], stat[3], i)
    end
    
    -- Controles
    local controlsFrame = self:CreateSection(frame, "🛠️ CONTROLS", 200)
    
    local clearBtn = Instance.new("TextButton")
    clearBtn.Size = UDim2.new(0, 150, 0, 30)
    clearBtn.Position = UDim2.new(0, 10, 0, 30)
    clearBtn.BackgroundColor3 = CurrentTheme.Warning
    clearBtn.BorderSizePixel = 0
    clearBtn.Text = "🧹 CLEAR ALL LOGS"
    clearBtn.TextColor3 = CurrentTheme.Text
    clearBtn.Font = Enum.Font.GothamBold
    clearBtn.TextSize = 12
    clearBtn.Parent = controlsFrame
    
    clearBtn.MouseButton1Click:Connect(function()
        self:ClearAllLogs()
    end)
end

function AdvancedSecurityMenu:CreateRemoteEventsContent(frame)
    local section = self:CreateSection(frame, "📡 REMOTE EVENTS MONITOR", 10)
    
    local monitoredCount = 0
    for _ in pairs(self.MonitoredRemotes) do
        monitoredCount += 1
    end
    
    self:CreateInfoRow(section, "Monitored Remotes", tostring(monitoredCount), 1)
    self:CreateInfoRow(section, "Total Events", tostring(self.Statistics.remoteEvents), 2)
    
    -- Mostrar últimos eventos
    local recentFrame = self:CreateSection(frame, "🔍 RECENT EVENTS", 80)
    
    local recentLogs = {}
    for i = math.max(1, #self.Logs.RemoteEvents - 9), #self.Logs.RemoteEvents do
        table.insert(recentLogs, self.Logs.RemoteEvents[i])
    end
    
    for i, log in ipairs(recentLogs) do
        self:CreateLogRow(recentFrame, log, i)
    end
end

function AdvancedSecurityMenu:CreateCharacterContent(frame)
    local section = self:CreateSection(frame, "🎯 CHARACTER MONITOR", 10)
    self:CreateInfoRow(section, "Total Events", tostring(self.Statistics.characterEvents), 1)
    
    local recentFrame = self:CreateSection(frame, "📝 RECENT ACTIVITY", 50)
    local recentLogs = {}
    for i = math.max(1, #self.Logs.Character - 4), #self.Logs.Character do
        table.insert(recentLogs, self.Logs.Character[i])
    end
    
    for i, log in ipairs(recentLogs) do
        self:CreateLogRow(recentFrame, log, i)
    end
end

function AdvancedSecurityMenu:CreateNetworkContent(frame)
    local section = self:CreateSection(frame, "🌐 NETWORK MONITOR", 10)
    self:CreateInfoRow(section, "Total Events", tostring(self.Statistics.networkEvents), 1)
    
    local recentFrame = self:CreateSection(frame, "👥 RECENT PLAYERS", 50)
    local recentLogs = {}
    for i = math.max(1, #self.Logs.Network - 4), #self.Logs.Network do
        table.insert(recentLogs, self.Logs.Network[i])
    end
    
    for i, log in ipairs(recentLogs) do
        self:CreateLogRow(recentFrame, log, i)
    end
end

function AdvancedSecurityMenu:CreateInputsContent(frame)
    local section = self:CreateSection(frame, "⌨️ INPUTS MONITOR", 10)
    self:CreateInfoRow(section, "Total Inputs", tostring(self.Statistics.inputs), 1)
    
    local recentFrame = self:CreateSection(frame, "🔑 RECENT INPUTS", 50)
    local recentLogs = {}
    for i = math.max(1, #self.Logs.Inputs - 9), #self.Logs.Inputs do
        table.insert(recentLogs, self.Logs.Inputs[i])
    end
    
    for i, log in ipairs(recentLogs) do
        self:CreateLogRow(recentFrame, log, i)
    end
end

function AdvancedSecurityMenu:CreateTriggersContent(frame)
    local section = self:CreateSection(frame, "🚨 TRIGGERS SYSTEM", 10)
    self:CreateInfoRow(section, "Triggers Activated", tostring(self.Statistics.triggers), 1)
    self:CreateInfoRow(section, "Total Triggers", tostring(#self.Triggers), 2)
    
    local recentFrame = self:CreateSection(frame, "⚡ RECENT TRIGGERS", 50)
    local recentLogs = {}
    for i = math.max(1, #self.Logs.Triggers - 4), #self.Logs.Triggers do
        table.insert(recentLogs, self.Logs.Triggers[i])
    end
    
    for i, log in ipairs(recentLogs) do
        self:CreateLogRow(recentFrame, log, i)
    end
end

function AdvancedSecurityMenu:CreateLogsContent(frame)
    local section = self:CreateSection(frame, "📝 ALL LOGS", 10)
    self:CreateInfoRow(section, "Total Logs", tostring(self.Statistics.totalEvents), 1)
    
    local logsFrame = self:CreateSection(frame, "🔍 RECENT LOGS", 50)
    
    local recentLogs = {}
    for i = math.max(1, #self.Logs.All - 19), #self.Logs.All do
        table.insert(recentLogs, self.Logs.All[i])
    end
    
    for i, log in ipairs(recentLogs) do
        self:CreateDetailedLogRow(logsFrame, log, i)
    end
end

-- Funções auxiliares para UI
function AdvancedSecurityMenu:CreateSection(parent, title, yPosition)
    local section = Instance.new("Frame")
    section.Size = UDim2.new(1, -20, 0, 0)
    section.Position = UDim2.new(0, 10, 0, yPosition)
    section.BackgroundColor3 = CurrentTheme.Header
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
        titleLabel.TextColor3 = CurrentTheme.Text
        titleLabel.TextXAlignment = Enum.TextXAlignment.Left
        titleLabel.Font = Enum.Font.GothamBold
        titleLabel.TextSize = 14
        titleLabel.Parent = section
    end
    
    return section
end

function AdvancedSecurityMenu:CreateStatRow(parent, label, value, color, index)
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
    labelText.TextColor3 = CurrentTheme.Text
    labelText.TextXAlignment = Enum.TextXAlignment.Left
    labelText.Font = Enum.Font.Gotham
    labelText.TextSize = 12
    labelText.Parent = row
    
    local valueText = Instance.new("TextLabel")
    valueText.Size = UDim2.new(0.4, 0, 1, 0)
    valueText.Position = UDim2.new(0.6, 0, 0, 0)
    valueText.BackgroundTransparency = 1
    valueText.Text = tostring(value)
    valueText.TextColor3 = color
    valueText.TextXAlignment = Enum.TextXAlignment.Right
    valueText.Font = Enum.Font.GothamBold
    valueText.TextSize = 12
    valueText.Parent = row
end

function AdvancedSecurityMenu:CreateInfoRow(parent, label, value, index)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, -20, 0, 20)
    row.Position = UDim2.new(0, 10, 0, 30 + (index-1)*25)
    row.BackgroundTransparency = 1
    row.Parent = parent
    
    local labelText = Instance.new("TextLabel")
    labelText.Size = UDim2.new(0.5, 0, 1, 0)
    labelText.Position = UDim2.new(0, 0, 0, 0)
    labelText.BackgroundTransparency = 1
    labelText.Text = label
    labelText.TextColor3 = CurrentTheme.TextSecondary
    labelText.TextXAlignment = Enum.TextXAlignment.Left
    labelText.Font = Enum.Font.Gotham
    labelText.TextSize = 11
    labelText.Parent = row
    
    local valueText = Instance.new("TextLabel")
    valueText.Size = UDim2.new(0.5, 0, 1, 0)
    valueText.Position = UDim2.new(0.5, 0, 0, 0)
    valueText.BackgroundTransparency = 1
    valueText.Text = value
    valueText.TextColor3 = CurrentTheme.Success
    valueText.TextXAlignment = Enum.TextXAlignment.Right
    valueText.Font = Enum.Font.GothamBold
    valueText.TextSize = 11
    valueText.Parent = row
end

function AdvancedSecurityMenu:CreateLogRow(parent, log, index)
    if not log then return end
    
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, -20, 0, 30)
    row.Position = UDim2.new(0, 10, 0, 30 + (index-1)*35)
    row.BackgroundColor3 = CurrentTheme.Tab
    row.BorderSizePixel = 0
    row.Parent = parent
    
    local timeLabel = Instance.new("TextLabel")
    timeLabel.Size = UDim2.new(0, 60, 0, 15)
    timeLabel.Position = UDim2.new(0, 5, 0, 2)
    timeLabel.BackgroundTransparency = 1
    timeLabel.Text = log.TimeFormatted
    timeLabel.TextColor3 = CurrentTheme.TextSecondary
    timeLabel.TextXAlignment = Enum.TextXAlignment.Left
    timeLabel.Font = Enum.Font.Gotham
    timeLabel.TextSize = 9
    timeLabel.Parent = row
    
    local messageLabel = Instance.new("TextLabel")
    messageLabel.Size = UDim2.new(1, -70, 0, 20)
    messageLabel.Position = UDim2.new(0, 65, 0, 5)
    messageLabel.BackgroundTransparency = 1
    messageLabel.Text = log.Message
    messageLabel.TextColor3 = CurrentTheme.Text
    messageLabel.TextXAlignment = Enum.TextXAlignment.Left
    messageLabel.Font = Enum.Font.Gotham
    messageLabel.TextSize = 11
    messageLabel.TextTruncate = Enum.TextTruncate.AtEnd
    messageLabel.Parent = row
end

function AdvancedSecurityMenu:CreateDetailedLogRow(parent, log, index)
    if not log then return end
    
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, -20, 0, 40)
    row.Position = UDim2.new(0, 10, 0, 30 + (index-1)*45)
    row.BackgroundColor3 = CurrentTheme.Tab
    row.BorderSizePixel = 0
    row.Parent = parent
    
    local timeLabel = Instance.new("TextLabel")
    timeLabel.Size = UDim2.new(0, 50, 0, 15)
    timeLabel.Position = UDim2.new(0, 5, 0, 2)
    timeLabel.BackgroundTransparency = 1
    timeLabel.Text = log.TimeFormatted
    timeLabel.TextColor3 = CurrentTheme.TextSecondary
    timeLabel.TextXAlignment = Enum.TextXAlignment.Left
    timeLabel.Font = Enum.Font.Gotham
    timeLabel.TextSize = 9
    timeLabel.Parent = row
    
    local categoryLabel = Instance.new("TextLabel")
    categoryLabel.Size = UDim2.new(0, 80, 0, 15)
    categoryLabel.Position = UDim2.new(0, 60, 0, 2)
    categoryLabel.BackgroundTransparency = 1
    categoryLabel.Text = "[" .. log.Category .. "]"
    categoryLabel.TextColor3 = CurrentTheme.TextSecondary
    categoryLabel.TextXAlignment = Enum.TextXAlignment.Left
    categoryLabel.Font = Enum.Font.Gotham
    categoryLabel.TextSize = 9
    categoryLabel.Parent = row
    
    local levelLabel = Instance.new("TextLabel")
    levelLabel.Size = UDim2.new(0, 60, 0, 15)
    levelLabel.Position = UDim2.new(0, 145, 0, 2)
    levelLabel.BackgroundTransparency = 1
    levelLabel.Text = log.Level
    levelLabel.TextColor3 = CurrentTheme.TextSecondary
    levelLabel.TextXAlignment = Enum.TextXAlignment.Left
    levelLabel.Font = Enum.Font.Gotham
    levelLabel.TextSize = 9
    levelLabel.Parent = row
    
    local messageLabel = Instance.new("TextLabel")
    messageLabel.Size = UDim2.new(1, -10, 0, 20)
    messageLabel.Position = UDim2.new(0, 5, 0, 18)
    messageLabel.BackgroundTransparency = 1
    messageLabel.Text = log.Message
    messageLabel.TextColor3 = CurrentTheme.Text
    messageLabel.TextXAlignment = Enum.TextXAlignment.Left
    messageLabel.Font = Enum.Font.Gotham
    messageLabel.TextSize = 11
    messageLabel.TextTruncate = Enum.TextTruncate.AtEnd
    messageLabel.Parent = row
end

function AdvancedSecurityMenu:ClearAllLogs()
    for category, _ in pairs(self.Logs) do
        self.Logs[category] = {}
    end
    
    for stat, _ in pairs(self.Statistics) do
        self.Statistics[stat] = 0
    end
    
    self:AddLog("System", "INFO", "All logs cleared")
    self:RefreshCurrentTab()
end

function AdvancedSecurityMenu:ToggleMenu()
    self.IsMenuOpen = not self.IsMenuOpen
    self.MainFrame.Visible = self.IsMenuOpen
    
    if self.IsMenuOpen then
        self:RefreshCurrentTab()
    end
end

-- Keybind
function AdvancedSecurityMenu:SetupKeybind()
    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if not gameProcessed and input.KeyCode == self.Config.Keybind then
            self:ToggleMenu()
        end
    end)
end

-- Sistema de Triggers
function AdvancedSecurityMenu:AddTrigger(name, condition, action)
    self.Triggers[name] = {
        Condition = condition,
        Action = action
    }
    self:AddLog("Triggers", "INFO", "Trigger added: " .. name)
end

-- Inicialização
function AdvancedSecurityMenu:Init()
    self:AddLog("System", "INFO", "Initializing Advanced Security MOD MENU...")
    
    self:CreateMenu()
    self:SetupKeybind()
    
    -- Iniciar monitoramentos
    self:InstrumentRemoteEvents()
    self:MonitorCharacter()
    self:MonitorInputs()
    self:MonitorNetwork()
    
    -- Triggers de exemplo
    self:AddTrigger("FastMovement", 
        function(data)
            return data.Category == "Character" and data.Data and data.Data.Distance and data.Data.Distance > 30
        end,
        function(data)
            self:AddLog("Triggers", "WARNING", "🚨 FAST MOVEMENT DETECTED!", data.Data)
        end
    )
    
    self:AddLog("System", "SUCCESS", "🎮 MOD MENU READY! Press F5 to open")
    
    return true
end

-- Iniciar automaticamente
if AdvancedSecurityMenu.Config.AutoStart then
    task.spawn(function()
        task.wait(2)
        local success = AdvancedSecurityMenu:Init()
        if not success then
            warn("AdvancedSecurityMenu: Failed to initialize")
        end
    end)
end

-- Tornar global
getgenv().ASM = AdvancedSecurityMenu

return AdvancedSecurityMenu
