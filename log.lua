-- Advanced Security MOD MENU
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
    Keybind = Enum.KeyCode.F5, -- Tecla para abrir/fechar
    Theme = "Dark", -- Dark, Light, Blue, Green
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
    },
    Light = {
        Background = Color3.fromRGB(245, 245, 245),
        Header = Color3.fromRGB(225, 225, 225),
        Tab = Color3.fromRGB(235, 235, 235),
        TabActive = Color3.fromRGB(0, 120, 215),
        Text = Color3.fromRGB(0, 0, 0),
        TextSecondary = Color3.fromRGB(100, 100, 100),
        Success = Color3.fromRGB(56, 142, 60),
        Warning = Color3.fromRGB(245, 124, 0),
        Error = Color3.fromRGB(211, 47, 47)
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
    if self.IsMenuOpen then
        self:UpdateLogDisplay(category)
    end
end

-- Sistema de instrumentação de RemoteEvents
function AdvancedSecurityMenu:InstrumentRemoteEvents()
    local function instrumentRemote(remote)
        if self.MonitoredRemotes[remote] then return end
        
        if remote:IsA("RemoteEvent") then
            local originalFire = remote.FireServer
            remote.FireServer = function(self, ...)
                local args = {...}
                local success, result = pcall(originalFire, self, unpack(args))
                
                self:AddLog("RemoteEvents", "INFO", 
                    string.format("📡 %s fired", remote.Name), {
                    ArgsCount = #args,
                    Success = success,
                    ArgsPreview = self:PreviewArgs(args)
                })
                
                return result
            end
        elseif remote:IsA("RemoteFunction") then
            local originalInvoke = remote.InvokeServer
            remote.InvokeServer = function(self, ...)
                local args = {...}
                local success, result = pcall(originalInvoke, self, unpack(args))
                
                self:AddLog("RemoteEvents", "INFO", 
                    string.format("🔧 %s invoked", remote.Name), {
                    ArgsCount = #args,
                    Success = success,
                    ResultPreview = tostring(result)
                })
                
                return result
            end
        end
        
        self.MonitoredRemotes[remote] = true
    end

    -- Instrumentar existentes
    for _, remote in ipairs(ReplicatedStorage:GetDescendants()) do
        if remote:IsA("RemoteEvent") or remote:IsA("RemoteFunction") then
            pcall(instrumentRemote, remote)
        end
    end

    -- Monitorar novos
    ReplicatedStorage.DescendantAdded:Connect(function(descendant)
        if descendant:IsA("RemoteEvent") or descendant:IsA("RemoteFunction") then
            task.wait(0.1)
            pcall(instrumentRemote, descendant)
        end
    end)
end

-- Preview de argumentos
function AdvancedSecurityMenu:PreviewArgs(args)
    local preview = {}
    for i, arg in ipairs(args) do
        if type(arg) == "string" then
            preview[i] = #arg > 20 and string.sub(arg, 1, 20).."..." or arg
        elseif type(arg) == "number" then
            preview[i] = tostring(arg)
        elseif type(arg) == "boolean" then
            preview[i] = tostring(arg)
        else
            preview[i] = type(arg)
        end
    end
    return preview
end

-- Monitoramento de Character
function AdvancedSecurityMenu:MonitorCharacter()
    local lastPosition = nil
    local lastHealth = nil
    
    RunService.Heartbeat:Connect(function()
        local player = Players.LocalPlayer
        if not player or not player.Character then return end
        
        local character = player.Character
        local humanoid = character:FindFirstChildOfClass("Humanoid")
        local rootPart = character:FindFirstChild("HumanoidRootPart")
        
        if rootPart then
            local currentPosition = rootPart.Position
            if lastPosition and (currentPosition - lastPosition).Magnitude > 5 then
                self:AddLog("Character", "INFO", "🎯 Character moved", {
                    Distance = (currentPosition - lastPosition).Magnitude,
                    Position = currentPosition,
                    Velocity = rootPart.Velocity.Magnitude
                })
            end
            lastPosition = currentPosition
        end
        
        if humanoid then
            local currentHealth = humanoid.Health
            if lastHealth and math.abs(currentHealth - lastHealth) > 5 then
                self:AddLog("Character", "WARNING", "❤️ Health changed", {
                    OldHealth = lastHealth,
                    NewHealth = currentHealth,
                    Difference = currentHealth - lastHealth
                })
            end
            lastHealth = currentHealth
        end
    end)
end

-- Monitoramento de Inputs
function AdvancedSecurityMenu:MonitorInputs()
    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if not gameProcessed and input.UserInputType == Enum.UserInputType.Keyboard then
            self:AddLog("Inputs", "DEBUG", "⌨️ Key pressed", {
                Key = input.KeyCode.Name,
                KeyCode = input.KeyCode.Value
            })
        end
    end)
end

-- Monitoramento de Network
function AdvancedSecurityMenu:MonitorNetwork()
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
end

-- Sistema de Triggers
function AdvancedSecurityMenu:AddTrigger(name, condition, action)
    self.Triggers[name] = {
        Condition = condition,
        Action = action,
        Cooldown = 0,
        LastTriggered = 0
    }
end

-- Criar a Interface do MOD MENU
function AdvancedSecurityMenu:CreateMenu()
    if self.ScreenGui then self.ScreenGui:Destroy() end
    
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
    
    local Tabs = {"Dashboard", "Remote Events", "Character", "Network", "Inputs", "Triggers", "Logs"}
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
        TabButton.TextSize = 12
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
        Frame.Parent = ContentFrame
        
        self.ContentFrames[tabName] = Frame
    end
    
    -- Configurar eventos
    CloseButton.MouseButton1Click:Connect(function()
        self:ToggleMenu()
    end)
    
    self.MainFrame = MainFrame
    self.TabButtons = TabButtons
end

-- Criar conteúdo das tabs
function AdvancedSecurityMenu:CreateTabContent()
    -- Dashboard
    self:CreateDashboardTab()
    
    -- Remote Events
    self:CreateRemoteEventsTab()
    
    -- Character
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
    
    -- Estatísticas
    local StatsLabel = Instance.new("TextLabel")
    StatsLabel.Size = UDim2.new(1, -20, 0, 30)
    StatsLabel.Position = UDim2.new(0, 10, 0, 10)
    StatsLabel.BackgroundTransparency = 1
    StatsLabel.Text = "📊 REAL-TIME STATISTICS"
    StatsLabel.TextColor3 = CurrentTheme.Text
    StatsLabel.TextXAlignment = Enum.TextXAlignment.Left
    StatsLabel.Font = Enum.Font.GothamBold
    StatsLabel.TextSize = 16
    StatsLabel.Parent = frame
    
    -- Controles
    local Controls = Instance.new("Frame")
    Controls.Size = UDim2.new(1, -20, 0, 100)
    Controls.Position = UDim2.new(0, 10, 0, 200)
    Controls.BackgroundColor3 = CurrentTheme.Header
    Controls.BorderSizePixel = 0
    Controls.Parent = frame
    
    local ClearLogsBtn = Instance.new("TextButton")
    ClearLogsBtn.Size = UDim2.new(0, 120, 0, 30)
    ClearLogsBtn.Position = UDim2.new(0, 10, 0, 10)
    ClearLogsBtn.BackgroundColor3 = CurrentTheme.Warning
    ClearLogsBtn.BorderSizePixel = 0
    ClearLogsBtn.Text = "🧹 Clear Logs"
    ClearLogsBtn.TextColor3 = CurrentTheme.Text
    ClearLogsBtn.Font = Enum.Font.Gotham
    ClearLogsBtn.TextSize = 12
    ClearLogsBtn.Parent = Controls
    
    ClearLogsBtn.MouseButton1Click:Connect(function()
        self:ClearAllLogs()
    end)
end

function AdvancedSecurityMenu:CreateRemoteEventsTab()
    local frame = self.ContentFrames["Remote Events"]
    -- Conteúdo específico para Remote Events
end

-- Implementar outras tabs similares...

function AdvancedSecurityMenu:SwitchTab(tabName)
    self.CurrentTab = tabName
    
    for name, frame in pairs(self.ContentFrames) do
        frame.Visible = (name == tabName)
    end
    
    self:UpdateTabContent(tabName)
end

function AdvancedSecurityMenu:UpdateTabContent(tabName)
    if tabName == "Dashboard" then
        self:UpdateDashboard()
    elseif tabName == "Remote Events" then
        self:UpdateRemoteEvents()
    -- Atualizar outras tabs...
    end
end

function AdvancedSecurityMenu:UpdateDashboard()
    local frame = self.ContentFrames["Dashboard"]
    -- Atualizar estatísticas em tempo real
end

function AdvancedSecurityMenu:UpdateLogDisplay(category)
    if self.CurrentTab == "Logs" or self.CurrentTab == category then
        self:UpdateTabContent(self.CurrentTab)
    end
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

-- Inicialização
function AdvancedSecurityMenu:Init()
    self:CreateMenu()
    self:CreateTabContent()
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
    
    print("🎮 Advanced Security MOD MENU Loaded! Press F5 to open.")
end

-- Iniciar automaticamente
if AdvancedSecurityMenu.Config.AutoStart then
    AdvancedSecurityMenu:Init()
end

-- Tornar global
getgenv().ASM = AdvancedSecurityMenu

return AdvancedSecurityMenu
