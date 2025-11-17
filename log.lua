-- Advanced Security MOD MENU - VERSAO CORRIGIDA
-- APENAS para pentest autorizado em servidores próprios

local AdvancedSecurityMenu = {}
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

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
local CurrentTheme = {
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

-- Função de logging
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
        if #logTable > 1000 then
            table.remove(logTable, 1)
        end
    end
    
    print(string.format("[%s] %s: %s", category, level, message))
end

-- Sistema de instrumentação SEGURO
function AdvancedSecurityMenu:InstrumentRemoteEvents()
    local function safeInstrument(remote)
        if self.MonitoredRemotes[remote] then return end
        
        local success = pcall(function()
            if remote:IsA("RemoteEvent") then
                local original = remote.FireServer
                remote.FireServer = function(self, ...)
                    local args = {...}
                    local callSuccess, result = pcall(original, self, unpack(args))
                    
                    self:AddLog("RemoteEvents", "INFO", 
                        string.format("📡 %s fired", remote.Name), {
                        ArgsCount = #args,
                        Success = callSuccess
                    })
                    
                    return result
                end
            elseif remote:IsA("RemoteFunction") then
                local original = remote.InvokeServer
                remote.InvokeServer = function(self, ...)
                    local args = {...}
                    local callSuccess, result = pcall(original, self, unpack(args))
                    
                    self:AddLog("RemoteEvents", "INFO", 
                        string.format("🔧 %s invoked", remote.Name), {
                        ArgsCount = #args,
                        Success = callSuccess
                    })
                    
                    return result
                end
            end
            
            self.MonitoredRemotes[remote] = true
        end)
        
        if not success then
            self:AddLog("Errors", "ERROR", "Failed to instrument: " .. remote.Name)
        end
    end

    -- Instrumentar existentes
    for _, remote in ipairs(ReplicatedStorage:GetDescendants()) do
        if remote:IsA("RemoteEvent") or remote:IsA("RemoteFunction") then
            task.spawn(safeInstrument, remote)
        end
    end

    -- Monitorar novos
    ReplicatedStorage.DescendantAdded:Connect(function(descendant)
        if descendant:IsA("RemoteEvent") or descendant:IsA("RemoteFunction") then
            task.wait(0.1)
            task.spawn(safeInstrument, descendant)
        end
    end)
end

-- Monitoramento de Character
function AdvancedSecurityMenu:MonitorCharacter()
    local lastPosition = nil
    
    RunService.Heartbeat:Connect(function()
        local player = Players.LocalPlayer
        if not player or not player.Character then return end
        
        local rootPart = player.Character:FindFirstChild("HumanoidRootPart")
        if rootPart then
            local currentPosition = rootPart.Position
            if lastPosition then
                local distance = (currentPosition - lastPosition).Magnitude
                if distance > 2 then
                    self:AddLog("Character", "INFO", "🎯 Moved " .. math.floor(distance) .. " studs")
                end
            end
            lastPosition = currentPosition
        end
    end)
end

-- Monitoramento de Inputs
function AdvancedSecurityMenu:MonitorInputs()
    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if not gameProcessed and input.UserInputType == Enum.UserInputType.Keyboard then
            self:AddLog("Inputs", "DEBUG", "⌨️ " .. input.KeyCode.Name)
        end
    end)
end

-- Monitoramento de Network
function AdvancedSecurityMenu:MonitorNetwork()
    Players.PlayerAdded:Connect(function(player)
        self:AddLog("Network", "INFO", "👤 " .. player.Name .. " joined")
    end)
    
    Players.PlayerRemoving:Connect(function(player)
        self:AddLog("Network", "INFO", "👋 " .. player.Name .. " left")
    end)
end

-- Sistema de Triggers
function AdvancedSecurityMenu:AddTrigger(name, condition, action)
    self.Triggers[name] = {
        Condition = condition,
        Action = action
    }
end

-- CRIAR TODAS AS TABS DE FORMA SEGURA
function AdvancedSecurityMenu:CreateAllTabs()
    -- Garantir que todas as funções de tab existam
    local tabCreators = {
        Dashboard = function(frame)
            local label = Instance.new("TextLabel")
            label.Size = UDim2.new(1, -20, 0, 30)
            label.Position = UDim2.new(0, 10, 0, 10)
            label.BackgroundTransparency = 1
            label.Text = "📊 SECURITY DASHBOARD"
            label.TextColor3 = CurrentTheme.Text
            label.TextXAlignment = Enum.TextXAlignment.Left
            label.Font = Enum.Font.GothamBold
            label.TextSize = 16
            label.Parent = frame
            
            local statsText = string.format(
                "Total Events: %d\nRemote Events: %d\nCharacter Events: %d\nNetwork Events: %d\nInputs: %d\nTriggers: %d\nErrors: %d",
                self.Statistics.totalEvents,
                self.Statistics.remoteEvents,
                self.Statistics.characterEvents,
                self.Statistics.networkEvents,
                self.Statistics.inputs,
                self.Statistics.triggers,
                self.Statistics.errors
            )
            
            local stats = Instance.new("TextLabel")
            stats.Size = UDim2.new(1, -20, 0, 150)
            stats.Position = UDim2.new(0, 10, 0, 50)
            stats.BackgroundTransparency = 1
            stats.Text = statsText
            stats.TextColor3 = CurrentTheme.Text
            stats.TextXAlignment = Enum.TextXAlignment.Left
            stats.Font = Enum.Font.Gotham
            stats.TextSize = 12
            stats.Parent = frame
        end,
        
        RemoteEvents = function(frame)
            local label = Instance.new("TextLabel")
            label.Size = UDim2.new(1, -20, 0, 30)
            label.Position = UDim2.new(0, 10, 0, 10)
            label.BackgroundTransparency = 1
            label.Text = "📡 REMOTE EVENTS"
            label.TextColor3 = CurrentTheme.Text
            label.TextXAlignment = Enum.TextXAlignment.Left
            label.Font = Enum.Font.GothamBold
            label.TextSize = 16
            label.Parent = frame
        end,
        
        Character = function(frame)
            local label = Instance.new("TextLabel")
            label.Size = UDim2.new(1, -20, 0, 30)
            label.Position = UDim2.new(0, 10, 0, 10)
            label.BackgroundTransparency = 1
            label.Text = "🎯 CHARACTER MONITOR"
            label.TextColor3 = CurrentTheme.Text
            label.TextXAlignment = Enum.TextXAlignment.Left
            label.Font = Enum.Font.GothamBold
            label.TextSize = 16
            label.Parent = frame
        end,
        
        Network = function(frame)
            local label = Instance.new("TextLabel")
            label.Size = UDim2.new(1, -20, 0, 30)
            label.Position = UDim2.new(0, 10, 0, 10)
            label.BackgroundTransparency = 1
            label.Text = "🌐 NETWORK MONITOR"
            label.TextColor3 = CurrentTheme.Text
            label.TextXAlignment = Enum.TextXAlignment.Left
            label.Font = Enum.Font.GothamBold
            label.TextSize = 16
            label.Parent = frame
        end,
        
        Inputs = function(frame)
            local label = Instance.new("TextLabel")
            label.Size = UDim2.new(1, -20, 0, 30)
            label.Position = UDim2.new(0, 10, 0, 10)
            label.BackgroundTransparency = 1
            label.Text = "⌨️ INPUTS MONITOR"
            label.TextColor3 = CurrentTheme.Text
            label.TextXAlignment = Enum.TextXAlignment.Left
            label.Font = Enum.Font.GothamBold
            label.TextSize = 16
            label.Parent = frame
        end,
        
        Triggers = function(frame)
            local label = Instance.new("TextLabel")
            label.Size = UDim2.new(1, -20, 0, 30)
            label.Position = UDim2.new(0, 10, 0, 10)
            label.BackgroundTransparency = 1
            label.Text = "🚨 ACTIVE TRIGGERS"
            label.TextColor3 = CurrentTheme.Text
            label.TextXAlignment = Enum.TextXAlignment.Left
            label.Font = Enum.Font.GothamBold
            label.TextSize = 16
            label.Parent = frame
        end,
        
        Logs = function(frame)
            local label = Instance.new("TextLabel")
            label.Size = UDim2.new(1, -20, 0, 30)
            label.Position = UDim2.new(0, 10, 0, 10)
            label.BackgroundTransparency = 1
            label.Text = "📝 ALL LOGS"
            label.TextColor3 = CurrentTheme.Text
            label.TextXAlignment = Enum.TextXAlignment.Left
            label.Font = Enum.Font.GothamBold
            label.TextSize = 16
            label.Parent = frame
        end
    }
    
    return tabCreators
end

-- Criar a Interface do MOD MENU
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
    Title.Text = "🔒 Security MOD MENU"
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
    
    -- Criar frames de conteúdo
    self.ContentFrames = {}
    local tabCreators = self:CreateAllTabs()
    
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
        
        -- Criar conteúdo da tab usando a função correspondente
        if tabCreators[tabName] then
            tabCreators[tabName](Frame)
        end
        
        self.ContentFrames[tabName] = Frame
    end
    
    -- Configurar eventos
    CloseButton.MouseButton1Click:Connect(function()
        self:ToggleMenu()
    end)
    
    self.MainFrame = MainFrame
    self.TabButtons = TabButtons
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
end

function AdvancedSecurityMenu:ToggleMenu()
    self.IsMenuOpen = not self.IsMenuOpen
    self.MainFrame.Visible = self.IsMenuOpen
end

-- Keybind
function AdvancedSecurityMenu:SetupKeybind()
    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if not gameProcessed and input.KeyCode == self.Config.Keybind then
            self:ToggleMenu()
        end
    end)
end

-- Inicialização SEGURA
function AdvancedSecurityMenu:Init()
    local success, err = pcall(function()
        self:CreateMenu()
        self:SetupKeybind()
        
        -- Iniciar monitoramentos
        self:InstrumentRemoteEvents()
        self:MonitorCharacter()
        self:MonitorInputs()
        self:MonitorNetwork()
        
        -- Trigger exemplo
        self:AddTrigger("FastMove", 
            function(data)
                return data.Category == "Character" and data.Message:find("studs") and tonumber(data.Message:match("%d+")) > 50
            end,
            function(data)
                self:AddLog("Triggers", "WARNING", "🚨 FAST MOVEMENT!")
            end
        )
        
        self:AddLog("System", "SUCCESS", "🎮 MOD MENU Loaded! Press F5")
        return true
    end)
    
    if not success then
        warn("MOD MENU Error: " .. tostring(err))
        return false
    end
    
    return true
end

-- Iniciar automaticamente
if AdvancedSecurityMenu.Config.AutoStart then
    task.spawn(function()
        task.wait(3)
        AdvancedSecurityMenu:Init()
    end)
end

-- Tornar global
getgenv().ASM = AdvancedSecurityMenu

return AdvancedSecurityMenu
