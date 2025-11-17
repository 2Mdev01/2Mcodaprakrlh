-- Advanced Security MOD MENU - CORRIGIDO
-- APENAS para pentest autorizado em servidores próprios

local AdvancedSecurityMenu = {}
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")

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

-- Cores do tema
local Themes = {
    Dark = {
        Background = Color3.fromRGB(30, 30, 40),
        Header = Color3.fromRGB(45, 45, 55),
        Tab = Color3.fromRGB(50, 50, 60),
        TabActive = Color3.fromRGB(0, 120, 215),
        Text = Color3.fromRGB(255, 255, 255),
        TextSecondary = Color3.fromRGB(200, 200, 200),
        Success = Color3.fromRGB(76, 175, 80),
        Warning = Color3.fromRGB(255, 152, 0),
        Error = Color3.fromRGB(244, 67, 54)
    }
}

local CurrentTheme = Themes[AdvancedSecurityMenu.Config.Theme]

-- Função de logging melhorada
function AdvancedSecurityMenu:AddLog(category, level, message, data)
    local logEntry = {
        Category = category,
        Level = level,
        Message = message,
        Data = data or {},
        Timestamp = os.time(),
        TimeFormatted = os.date("%H:%M:%S"),
        Tick = tick()
    }
    
    -- Adicionar à categoria geral
    table.insert(self.Logs.All, logEntry)
    
    -- Adicionar à categoria específica
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
    for categoryName, logTable in pairs(self.Logs) do
        if #logTable > 1000 then
            table.remove(logTable, 1)
        end
    end
    
    -- Atualizar UI se estiver aberta
    if self.IsMenuOpen and self.UpdateLogDisplay then
        self:UpdateLogDisplay(category)
    end
end

-- Sistema de instrumentação de RemoteEvents CORRIGIDO
function AdvancedSecurityMenu:InstrumentRemoteEvents()
    local function safeInstrumentRemote(remote)
        if self.MonitoredRemotes[remote] then return end
        
        local success, result = pcall(function()
            if remote:IsA("RemoteEvent") then
                local originalFire = remote.FireServer
                if originalFire then
                    remote.FireServer = function(self, ...)
                        local args = {...}
                        local fireSuccess, fireResult = pcall(originalFire, self, unpack(args))
                        
                        self:AddLog("RemoteEvents", "INFO", 
                            string.format("📡 %s fired", remote.Name), {
                            ArgsCount = #args,
                            Success = fireSuccess,
                            ArgsPreview = self:PreviewArgs(args)
                        })
                        
                        return fireResult
                    end
                end
            elseif remote:IsA("RemoteFunction") then
                local originalInvoke = remote.InvokeServer
                if originalInvoke then
                    remote.InvokeServer = function(self, ...)
                        local args = {...}
                        local invokeSuccess, invokeResult = pcall(originalInvoke, self, unpack(args))
                        
                        self:AddLog("RemoteEvents", "INFO", 
                            string.format("🔧 %s invoked", remote.Name), {
                            ArgsCount = #args,
                            Success = invokeSuccess,
                            ResultPreview = tostring(invokeResult)
                        })
                        
                        return invokeResult
                    end
                end
            end
            
            self.MonitoredRemotes[remote] = true
            return true
        end)
        
        if not success then
            self:AddLog("Errors", "ERROR", "Failed to instrument remote", {
                RemoteName = remote.Name,
                Error = result
            })
        end
    end

    -- Instrumentar existentes com proteção
    local function safeGetDescendants(parent)
        local success, descendants = pcall(function()
            return parent:GetDescendants()
        end)
        return success and descendants or {}
    end

    -- Monitorar ReplicatedStorage
    for _, remote in ipairs(safeGetDescendants(ReplicatedStorage)) do
        if remote:IsA("RemoteEvent") or remote:IsA("RemoteFunction") then
            task.spawn(safeInstrumentRemote, remote)
        end
    end

    -- Monitorar novos com proteção
    local function safeDescendantAdded(descendant)
        local success = pcall(function()
            if descendant:IsA("RemoteEvent") or descendant:IsA("RemoteFunction") then
                task.wait(0.2)
                safeInstrumentRemote(descendant)
            end
        end)
    end

    pcall(function()
        ReplicatedStorage.DescendantAdded:Connect(safeDescendantAdded)
    end)
end

-- Preview de argumentos
function AdvancedSecurityMenu:PreviewArgs(args)
    local preview = {}
    for i, arg in ipairs(args) do
        local argType = type(arg)
        if argType == "string" then
            preview[i] = #arg > 20 and string.sub(arg, 1, 20).."..." or arg
        elseif argType == "number" then
            preview[i] = tostring(arg)
        elseif argType == "boolean" then
            preview[i] = tostring(arg)
        else
            preview[i] = argType
        end
    end
    return preview
end

-- Monitoramento de Character CORRIGIDO
function AdvancedSecurityMenu:MonitorCharacter()
    local lastPosition = nil
    local lastHealth = nil
    
    RunService.Heartbeat:Connect(function()
        local success = pcall(function()
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
                                X = math.floor(currentPosition.X * 100) / 100,
                                Y = math.floor(currentPosition.Y * 100) / 100,
                                Z = math.floor(currentPosition.Z * 100) / 100
                            },
                            Velocity = math.floor(rootPart.Velocity.Magnitude * 100) / 100
                        })
                    end
                end
                lastPosition = currentPosition
            end
            
            if humanoid then
                local currentHealth = humanoid.Health
                if lastHealth and math.abs(currentHealth - lastHealth) > 5 then
                    self:AddLog("Character", "WARNING", "❤️ Health changed", {
                        OldHealth = math.floor(lastHealth * 100) / 100,
                        NewHealth = math.floor(currentHealth * 100) / 100,
                        Difference = math.floor((currentHealth - lastHealth) * 100) / 100
                    })
                end
                lastHealth = currentHealth
            end
        end)
        
        if not success then
            -- Erro silencioso para evitar spam
        end
    end)
end

-- Monitoramento de Inputs CORRIGIDO
function AdvancedSecurityMenu:MonitorInputs()
    local success = pcall(function()
        UserInputService.InputBegan:Connect(function(input, gameProcessed)
            if not gameProcessed and input.UserInputType == Enum.UserInputType.Keyboard then
                self:AddLog("Inputs", "DEBUG", "⌨️ Key pressed", {
                    Key = input.KeyCode.Name,
                    KeyCode = input.KeyCode.Value
                })
            end
        end)
    end)
    
    if not success then
        self:AddLog("Errors", "ERROR", "Failed to monitor inputs")
    end
end

-- Monitoramento de Network CORRIGIDO
function AdvancedSecurityMenu:MonitorNetwork()
    local success = pcall(function()
        Players.PlayerAdded:Connect(function(player)
            self:AddLog("Network", "INFO", "👤 Player joined", {
                PlayerName = player.Name,
                UserId = player.UserId,
                AccountAge = player.AccountAge
            })
        end)
        
        Players.PlayerRemoving:Connect(function(player)
            self:AddLog("Network", "INFO", "👋 Player left", {
                PlayerName = player.Name,
                UserId = player.UserId
            })
        end)
    end)
    
    if not success then
        self:AddLog("Errors", "ERROR", "Failed to monitor network")
    end
end

-- Sistema de Triggers
function AdvancedSecurityMenu:AddTrigger(name, condition, action)
    self.Triggers[name] = {
        Condition = condition,
        Action = action,
        Cooldown = 0,
        LastTriggered = 0
    }
    self:AddLog("Triggers", "INFO", "✅ Trigger added: " .. name)
end

-- Criar a Interface do MOD MENU CORRIGIDA
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
    
    -- Frame principal
    local MainFrame = Instance.new("Frame")
    MainFrame.Size = UDim2.new(0, 600, 0, 400)
    MainFrame.Position = UDim2.new(0.5, -300, 0.5, -200)
    MainFrame.BackgroundColor3 = CurrentTheme.Background
    MainFrame.BorderSizePixel = 0
    MainFrame.Visible = false
    MainFrame.Parent = self.ScreenGui
    
    -- Header
    local Header = Instance.new("Frame")
    Header.Size = UDim2.new(1, 0, 0, 30)
    Header.BackgroundColor3 = CurrentTheme.Header
    Header.BorderSizePixel = 0
    Header.Parent = MainFrame
    
    local Title = Instance.new("TextLabel")
    Title.Size = UDim2.new(1, -100, 1, 0)
    Title.Position = UDim2.new(0, 10, 0, 0)
    Title.BackgroundTransparency = 1
    Title.Text = "🔒 Advanced Security MOD MENU"
    Title.TextColor3 = CurrentTheme.Text
    Title.TextXAlignment = Enum.TextXAlignment.Left
    Title.Font = Enum.Font.GothamBold
    Title.TextSize = 14
    Title.Parent = Header
    
    local CloseButton = Instance.new("TextButton")
    CloseButton.Size = UDim2.new(0, 80, 0, 20)
    CloseButton.Position = UDim2.new(1, -90, 0, 5)
    CloseButton.BackgroundColor3 = CurrentTheme.Error
    CloseButton.BorderSizePixel = 0
    CloseButton.Text = "Close [F5]"
    CloseButton.TextColor3 = CurrentTheme.Text
    CloseButton.Font = Enum.Font.Gotham
    CloseButton.TextSize = 12
    CloseButton.Parent = Header
    
    -- Tabs
    local TabContainer = Instance.new("Frame")
    TabContainer.Size = UDim2.new(1, 0, 0, 30)
    TabContainer.Position = UDim2.new(0, 0, 0, 30)
    TabContainer.BackgroundColor3 = CurrentTheme.Tab
    TabContainer.BorderSizePixel = 0
    TabContainer.Parent = MainFrame
    
    local Tabs = {"Dashboard", "RemoteEvents", "Character", "Network", "Inputs", "Triggers", "Logs"}
    local TabButtons = {}
    
    for i, tabName in ipairs(Tabs) do
        local TabButton = Instance.new("TextButton")
        TabButton.Size = UDim2.new(0, 85, 1, 0)
        TabButton.Position = UDim2.new(0, (i-1)*85, 0, 0)
        TabButton.BackgroundColor3 = CurrentTheme.Tab
        TabButton.BorderSizePixel = 0
        TabButton.Text = tabName
        TabButton.TextColor3 = CurrentTheme.TextSecondary
        TabButton.Font = Enum.Font.Gotham
        TabButton.TextSize = 11
        TabButton.Parent = TabContainer
        
        TabButton.MouseButton1Click:Connect(function()
            self:SwitchTab(tabName)
            for _, btn in pairs(TabButtons) do
                btn.BackgroundColor3 = CurrentTheme.Tab
                btn.TextColor3 = CurrentTheme.TextSecondary
            end
            TabButton.BackgroundColor3 = CurrentTheme.TabActive
            TabButton.TextColor3 = CurrentTheme.Text
        end)
        
        TabButtons[tabName] = TabButton
    end
    
    -- Content Area
    local ContentFrame = Instance.new("Frame")
    ContentFrame.Size = UDim2.new(1, 0, 1, -60)
    ContentFrame.Position = UDim2.new(0, 0, 0, 60)
    ContentFrame.BackgroundTransparency = 1
    ContentFrame.Parent = MainFrame
    
    -- Frames de conteúdo para cada tab
    self.ContentFrames = {}
    
    for _, tabName in ipairs(Tabs) do
        local Frame = Instance.new("ScrollingFrame")
        Frame.Size = UDim2.new(1, 0, 1, 0)
        Frame.Position = UDim2.new(0, 0, 0, 0)
        Frame.BackgroundTransparency = 1
        Frame.BorderSizePixel = 0
        Frame.ScrollBarThickness = 6
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
    self.TabButtons = TabButtons
    
    -- Criar conteúdo das tabs
    self:CreateTabContent()
end

-- Criar conteúdo das tabs CORRIGIDO
function AdvancedSecurityMenu:CreateTabContent()
    -- Dashboard
    self:CreateDashboardTab()
    
    -- Remote Events
    self:CreateRemoteEventsTab()
    
    -- Character Tab
    self:CreateCharacterTab()
    
    -- Network
    self:CreateNetworkTab()
    
    -- Inputs
    self:CreateInputsTab()
    
    -- Triggers
    self:CreateTriggersTab()
    
    -- Logs
    self:CreateLogsTab()
end

function AdvancedSecurityMenu:CreateDashboardTab()
    local frame = self.ContentFrames["Dashboard"]
    
    -- Estatísticas em tempo real
    self.StatsLabels = {}
    
    local stats = {
        {"📊 TOTAL EVENTS", "totalEvents"},
        {"📡 REMOTE EVENTS", "remoteEvents"},
        {"🎯 CHARACTER EVENTS", "characterEvents"},
        {"🌐 NETWORK EVENTS", "networkEvents"},
        {"⌨️ INPUTS", "inputs"},
        {"🚨 TRIGGERS", "triggers"},
        {"❌ ERRORS", "errors"}
    }
    
    for i, stat in ipairs(stats) do
        local statFrame = Instance.new("Frame")
        statFrame.Size = UDim2.new(1, -20, 0, 30)
        statFrame.Position = UDim2.new(0, 10, 0, 10 + (i-1)*35)
        statFrame.BackgroundColor3 = CurrentTheme.Header
        statFrame.BorderSizePixel = 0
        statFrame.Parent = frame
        
        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(0.6, 0, 1, 0)
        label.Position = UDim2.new(0, 10, 0, 0)
        label.BackgroundTransparency = 1
        label.Text = stat[1]
        label.TextColor3 = CurrentTheme.Text
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.Font = Enum.Font.Gotham
        label.TextSize = 12
        label.Parent = statFrame
        
        local value = Instance.new("TextLabel")
        value.Size = UDim2.new(0.3, 0, 1, 0)
        value.Position = UDim2.new(0.7, 0, 0, 0)
        value.BackgroundTransparency = 1
        value.Text = "0"
        value.TextColor3 = CurrentTheme.Success
        value.TextXAlignment = Enum.TextXAlignment.Right
        value.Font = Enum.Font.GothamBold
        value.TextSize = 14
        value.Parent = statFrame
        
        self.StatsLabels[stat[2]] = value
    end
    
    -- Controles
    local ControlsLabel = Instance.new("TextLabel")
    ControlsLabel.Size = UDim2.new(1, -20, 0, 20)
    ControlsLabel.Position = UDim2.new(0, 10, 0, 300)
    ControlsLabel.BackgroundTransparency = 1
    ControlsLabel.Text = "🛠️ CONTROLS"
    ControlsLabel.TextColor3 = CurrentTheme.Text
    ControlsLabel.TextXAlignment = Enum.TextXAlignment.Left
    ControlsLabel.Font = Enum.Font.GothamBold
    ControlsLabel.TextSize = 14
    ControlsLabel.Parent = frame
    
    local ClearLogsBtn = Instance.new("TextButton")
    ClearLogsBtn.Size = UDim2.new(0, 120, 0, 30)
    ClearLogsBtn.Position = UDim2.new(0, 10, 0, 330)
    ClearLogsBtn.BackgroundColor3 = CurrentTheme.Warning
    ClearLogsBtn.BorderSizePixel = 0
    ClearLogsBtn.Text = "🧹 Clear Logs"
    ClearLogsBtn.TextColor3 = CurrentTheme.Text
    ClearLogsBtn.Font = Enum.Font.Gotham
    ClearLogsBtn.TextSize = 12
    ClearLogsBtn.Parent = frame
    
    ClearLogsBtn.MouseButton1Click:Connect(function()
        self:ClearAllLogs()
    end)
end

function AdvancedSecurityMenu:CreateRemoteEventsTab()
    local frame = self.ContentFrames["RemoteEvents"]
    -- Conteúdo será preenchido dinamicamente
end

function AdvancedSecurityMenu:CreateCharacterTab()
    local frame = self.ContentFrames["Character"]
    -- Conteúdo será preenchido dinamicamente
end

function AdvancedSecurityMenu:CreateNetworkTab()
    local frame = self.ContentFrames["Network"]
    -- Conteúdo será preenchido dinamicamente
end

function AdvancedSecurityMenu:CreateInputsTab()
    local frame = self.ContentFrames["Inputs"]
    -- Conteúdo será preenchido dinamicamente
end

function AdvancedSecurityMenu:CreateTriggersTab()
    local frame = self.ContentFrames["Triggers"]
    
    local Title = Instance.new("TextLabel")
    Title.Size = UDim2.new(1, -20, 0, 30)
    Title.Position = UDim2.new(0, 10, 0, 10)
    Title.BackgroundTransparency = 1
    Title.Text = "🚨 ACTIVE TRIGGERS"
    Title.TextColor3 = CurrentTheme.Text
    Title.TextXAlignment = Enum.TextXAlignment.Left
    Title.Font = Enum.Font.GothamBold
    Title.TextSize = 16
    Title.Parent = frame
end

function AdvancedSecurityMenu:CreateLogsTab()
    local frame = self.ContentFrames["Logs"]
    -- Conteúdo será preenchido dinamicamente
end

function AdvancedSecurityMenu:SwitchTab(tabName)
    self.CurrentTab = tabName
    
    for name, frame in pairs(self.ContentFrames) do
        frame.Visible = (name == tabName)
    end
    
    if self.TabButtons[tabName] then
        for _, btn in pairs(self.TabButtons) do
            btn.BackgroundColor3 = CurrentTheme.Tab
            btn.TextColor3 = CurrentTheme.TextSecondary
        end
        self.TabButtons[tabName].BackgroundColor3 = CurrentTheme.TabActive
        self.TabButtons[tabName].TextColor3 = CurrentTheme.Text
    end
    
    self:UpdateTabContent(tabName)
end

function AdvancedSecurityMenu:UpdateTabContent(tabName)
    if tabName == "Dashboard" then
        self:UpdateDashboard()
    elseif tabName == "Logs" then
        self:UpdateLogsTab()
    end
end

function AdvancedSecurityMenu:UpdateDashboard()
    if not self.StatsLabels then return end
    
    for statName, label in pairs(self.StatsLabels) do
        if self.Statistics[statName] then
            label.Text = tostring(self.Statistics[statName])
        end
    end
end

function AdvancedSecurityMenu:UpdateLogsTab()
    local frame = self.ContentFrames["Logs"]
    if not frame then return end
    
    -- Limpar logs antigos
    for _, child in ipairs(frame:GetChildren()) do
        if child:IsA("Frame") then
            child:Destroy()
        end
    end
    
    -- Mostrar últimos 20 logs
    local recentLogs = {}
    for i = math.max(1, #self.Logs.All - 19), #self.Logs.All do
        table.insert(recentLogs, self.Logs.All[i])
    end
    
    for i, log in ipairs(recentLogs) do
        local logFrame = Instance.new("Frame")
        logFrame.Size = UDim2.new(1, -20, 0, 40)
        logFrame.Position = UDim2.new(0, 10, 0, 10 + (i-1)*45)
        logFrame.BackgroundColor3 = CurrentTheme.Header
        logFrame.BorderSizePixel = 0
        logFrame.Parent = frame
        
        local timeLabel = Instance.new("TextLabel")
        timeLabel.Size = UDim2.new(0, 60, 0, 15)
        timeLabel.Position = UDim2.new(0, 5, 0, 3)
        timeLabel.BackgroundTransparency = 1
        timeLabel.Text = log.TimeFormatted
        timeLabel.TextColor3 = CurrentTheme.TextSecondary
        timeLabel.TextXAlignment = Enum.TextXAlignment.Left
        timeLabel.Font = Enum.Font.Gotham
        timeLabel.TextSize = 10
        timeLabel.Parent = logFrame
        
        local categoryLabel = Instance.new("TextLabel")
        categoryLabel.Size = UDim2.new(0, 100, 0, 15)
        categoryLabel.Position = UDim2.new(0, 70, 0, 3)
        categoryLabel.BackgroundTransparency = 1
        categoryLabel.Text = "[" .. log.Category .. "]"
        categoryLabel.TextColor3 = CurrentTheme.TextSecondary
        categoryLabel.TextXAlignment = Enum.TextXAlignment.Left
        categoryLabel.Font = Enum.Font.Gotham
        categoryLabel.TextSize = 10
        categoryLabel.Parent = logFrame
        
        local messageLabel = Instance.new("TextLabel")
        messageLabel.Size = UDim2.new(1, -10, 0, 20)
        messageLabel.Position = UDim2.new(0, 5, 0, 20)
        messageLabel.BackgroundTransparency = 1
        messageLabel.Text = log.Message
        messageLabel.TextColor3 = CurrentTheme.Text
        messageLabel.TextXAlignment = Enum.TextXAlignment.Left
        messageLabel.Font = Enum.Font.Gotham
        messageLabel.TextSize = 12
        messageLabel.TextTruncate = Enum.TextTruncate.AtEnd
        messageLabel.Parent = logFrame
    end
end

function AdvancedSecurityMenu:UpdateLogDisplay(category)
    if self.IsMenuOpen then
        self:UpdateDashboard()
        if self.CurrentTab == "Logs" or self.CurrentTab == category then
            self:UpdateTabContent(self.CurrentTab)
        end
    end
end

function AdvancedSecurityMenu:ClearAllLogs()
    for categoryName, logTable in pairs(self.Logs) do
        self.Logs[categoryName] = {}
    end
    
    for statName, _ in pairs(self.Statistics) do
        self.Statistics[statName] = 0
    end
    
    self:AddLog("System", "INFO", "All logs cleared")
    self:UpdateTabContent(self.CurrentTab)
end

-- Controle do menu
function AdvancedSecurityMenu:ToggleMenu()
    self.IsMenuOpen = not self.IsMenuOpen
    self.MainFrame.Visible = self.IsMenuOpen
    
    if self.IsMenuOpen then
        self:UpdateTabContent(self.CurrentTab)
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

-- Inicialização CORRIGIDA
function AdvancedSecurityMenu:Init()
    local success, err = pcall(function()
        self:CreateMenu()
        self:SetupKeybind()
        
        -- Iniciar monitoramentos
        self:InstrumentRemoteEvents()
        self:MonitorCharacter()
        self:MonitorInputs()
        self:MonitorNetwork()
        
        -- Triggers padrão
        self:AddTrigger("Fast Movement", 
            function(data)
                return data.Category == "Character" and data.Data.Distance and data.Data.Distance > 50
            end,
            function(data)
                self:AddLog("Triggers", "WARNING", "🚨 FAST MOVEMENT DETECTED!", data.Data)
            end
        )
        
        self:AddLog("System", "SUCCESS", "🎮 MOD MENU Loaded! Press F5 to open")
        return true
    end)
    
    if not success then
        warn("MOD MENU Initialization Error: " .. tostring(err))
        return false
    end
    
    return true
end

-- Iniciar automaticamente
if AdvancedSecurityMenu.Config.AutoStart then
    task.spawn(function()
        task.wait(2) -- Esperar o jogo carregar
        AdvancedSecurityMenu:Init()
    end)
end

-- Tornar global
getgenv().ASM = AdvancedSecurityMenu

return AdvancedSecurityMenu
