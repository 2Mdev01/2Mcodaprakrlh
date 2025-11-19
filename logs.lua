-- SECURITY MENU - TECLA F CORRIGIDA
-- APENAS para pentest autorizado

local SecurityMenu = {}
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

-- Configurações - TECLA F
SecurityMenu.OpenKey = Enum.KeyCode.F
SecurityMenu.IsOpen = false
SecurityMenu.CurrentTab = "Dashboard"

-- Inicializar todas as tabelas de logs CORRETAMENTE
SecurityMenu.Logs = {
    All = {},
    Remote = {},
    Character = {},
    Network = {},
    Input = {},
    Triggers = {},
    System = {}
}

SecurityMenu.Stats = {
    Total = 0,
    Remote = 0,
    Character = 0,
    Network = 0,
    Input = 0,
    Triggers = 0,
    System = 0
}

SecurityMenu.TriggersList = {}
SecurityMenu.MonitoredRemotes = {}

-- Função de logging CORRIGIDA
function SecurityMenu:Log(category, message)
    -- VERIFICAR se a tabela da categoria existe
    if not self.Logs[category] then
        self.Logs[category] = {}
    end
    
    local logEntry = {
        Time = os.date("%H:%M:%S"),
        Category = category,
        Message = message,
        ID = #self.Logs.All + 1
    }
    
    -- Adicionar aos logs com VERIFICAÇÃO
    table.insert(self.Logs.All, logEntry)
    table.insert(self.Logs[category], logEntry)
    
    -- Atualizar estatísticas com VERIFICAÇÃO
    self.Stats.Total = (self.Stats.Total or 0) + 1
    self.Stats[category] = (self.Stats[category] or 0) + 1
    
    -- Print no console
    print("[" .. logEntry.Time .. "] " .. category .. ": " .. message)
    
    -- Atualizar UI se estiver aberta
    if self.IsOpen and self.UpdateDisplay then
        self:UpdateDisplay()
    end
end

-- Sistema de Triggers SEGURO
function SecurityMenu:AddTrigger(name, condition, action)
    self.TriggersList[name] = {
        Condition = condition,
        Action = action
    }
    self:Log("System", "Trigger adicionado: " .. name)
end

function SecurityMenu:CheckTriggers(category, message)
    for triggerName, trigger in pairs(self.TriggersList) do
        local success, result = pcall(trigger.Condition, category, message)
        if success and result then
            pcall(trigger.Action, message)
            self:Log("Triggers", "🚨 " .. triggerName .. " acionado!")
        end
    end
end

-- Monitoramento de RemoteEvents SEGURO
function SecurityMenu:MonitorRemoteEvents()
    self:Log("System", "Iniciando monitoramento de RemoteEvents...")
    
    local function safeMonitor(remote)
        if SecurityMenu.MonitoredRemotes[remote] then return end
        
        if remote:IsA("RemoteEvent") then
            local original = remote.FireServer
            remote.FireServer = function(self, ...)
                local args = {...}
                local success = pcall(original, self, unpack(args))
                SecurityMenu:Log("Remote", "📡 " .. remote.Name)
                SecurityMenu:CheckTriggers("Remote", remote.Name)
                return
            end
        elseif remote:IsA("RemoteFunction") then
            local original = remote.InvokeServer
            remote.InvokeServer = function(self, ...)
                local args = {...}
                local result = original(self, unpack(args))
                SecurityMenu:Log("Remote", "🔧 " .. remote.Name)
                SecurityMenu:CheckTriggers("Remote", remote.Name)
                return result
            end
        end
        
        SecurityMenu.MonitoredRemotes[remote] = true
    end

    -- Monitorar apenas ReplicatedStorage (EVITA ERROS)
    local success, descendants = pcall(function()
        return ReplicatedStorage:GetDescendants()
    end)
    
    if success then
        for _, remote in ipairs(descendants) do
            if remote:IsA("RemoteEvent") or remote:IsA("RemoteFunction") then
                pcall(safeMonitor, remote)
            end
        end
    end
    
    self:Log("System", "RemoteEvents monitorados com sucesso!")
end

-- Monitoramento de Character
function SecurityMenu:MonitorCharacter()
    local lastPos = nil
    
    RunService.Heartbeat:Connect(function()
        local player = Players.LocalPlayer
        if player and player.Character then
            local root = player.Character:FindFirstChild("HumanoidRootPart")
            if root then
                local currentPos = root.Position
                if lastPos then
                    local dist = (currentPos - lastPos).Magnitude
                    if dist > 3 then
                        SecurityMenu:Log("Character", "🎯 Movimento: " .. math.floor(dist) .. " studs")
                        SecurityMenu:CheckTriggers("Character", "Movimento: " .. math.floor(dist))
                    end
                end
                lastPos = currentPos
            end
        end
    end)
end

-- Monitoramento de Inputs
function SecurityMenu:MonitorInputs()
    local success, result = pcall(function()
        UserInputService.InputBegan:Connect(function(input, processed)
            if not processed and input.UserInputType == Enum.UserInputType.Keyboard then
                SecurityMenu:Log("Input", "⌨️ " .. input.KeyCode.Name)
                SecurityMenu:CheckTriggers("Input", "Tecla: " .. input.KeyCode.Name)
            end
        end)
    end)
    
    if not success then
        SecurityMenu:Log("System", "Erro ao monitorar inputs: " .. tostring(result))
    end
end

-- Monitoramento de Network
function SecurityMenu:MonitorNetwork()
    local success, result = pcall(function()
        Players.PlayerAdded:Connect(function(player)
            SecurityMenu:Log("Network", "👤 " .. player.Name .. " entrou")
        end)
        
        Players.PlayerRemoving:Connect(function(player)
            SecurityMenu:Log("Network", "👋 " .. player.Name .. " saiu")
        end)
    end)
    
    if not success then
        SecurityMenu:Log("System", "Erro ao monitorar network: " .. tostring(result))
    end
end

-- Criar Interface CORRIGIDA
function SecurityMenu:CreateUI()
    -- Destruir UI existente com segurança
    if self.ScreenGui then
        pcall(function() self.ScreenGui:Destroy() end)
    end
    
    -- Criar nova UI
    self.ScreenGui = Instance.new("ScreenGui")
    self.ScreenGui.Parent = game:GetService("CoreGui")
    self.ScreenGui.Name = "SecurityMenu"
    
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
    MainFrame.Size = UDim2.new(0, 650, 0, 500)
    MainFrame.Position = UDim2.new(0.5, -325, 0.5, -250)
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
    Title.Text = "🔒 SECURITY MENU (Tecla: F)"
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
    CloseBtn.Text = "FECHAR [F]"
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
    
    local Tabs = {"Dashboard", "Remote", "Character", "Network", "Input", "Triggers", "Logs"}
    self.TabButtons = {}
    
    for i, tabName in ipairs(Tabs) do
        local TabButton = Instance.new("TextButton")
        TabButton.Size = UDim2.new(0, 92, 1, 0)
        TabButton.Position = UDim2.new(0, (i-1)*92, 0, 0)
        TabButton.BackgroundColor3 = Theme.Tab
        TabButton.BorderSizePixel = 0
        TabButton.Text = tabName
        TabButton.TextColor3 = Theme.TextSecondary
        TabButton.Font = Enum.Font.Gotham
        TabButton.TextSize = 11
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

-- Sistema de Abas CORRIGIDO
function SecurityMenu:SwitchTab(tabName)
    self.CurrentTab = tabName
    
    -- Esconder todas as tabs
    for name, frame in pairs(self.ContentFrames) do
        if frame then
            frame.Visible = false
            -- Limpar conteúdo anterior com segurança
            for _, child in ipairs(frame:GetChildren()) do
                if child:IsA("Frame") then
                    pcall(function() child:Destroy() end)
                end
            end
        end
    end
    
    -- Atualizar botões
    for name, button in pairs(self.TabButtons) do
        if button then
            if name == tabName then
                button.BackgroundColor3 = self.Theme.TabActive
                button.TextColor3 = self.Theme.Text
            else
                button.BackgroundColor3 = self.Theme.Tab
                button.TextColor3 = self.Theme.TextSecondary
            end
        end
    end
    
    -- Mostrar tab atual
    if self.ContentFrames[tabName] then
        self.ContentFrames[tabName].Visible = true
        self:UpdateTabContent(tabName)
    end
end

function SecurityMenu:UpdateTabContent(tabName)
    local frame = self.ContentFrames[tabName]
    if not frame then return end
    
    if tabName == "Dashboard" then
        self:CreateDashboard(frame)
    elseif tabName == "Remote" then
        self:CreateRemoteTab(frame)
    elseif tabName == "Character" then
        self:CreateCharacterTab(frame)
    elseif tabName == "Network" then
        self:CreateNetworkTab(frame)
    elseif tabName == "Input" then
        self:CreateInputTab(frame)
    elseif tabName == "Triggers" then
        self:CreateTriggersTab(frame)
    elseif tabName == "Logs" then
        self:CreateLogsTab(frame)
    end
end

-- Conteúdo das Abas CORRIGIDO
function SecurityMenu:CreateDashboard(frame)
    -- Estatísticas
    local statsFrame = self:CreateSection(frame, "📊 ESTATÍSTICAS", 10)
    
    local stats = {
        {"Total Events", "Total"},
        {"Remote Events", "Remote"},
        {"Character Events", "Character"},
        {"Network Events", "Network"},
        {"Input Events", "Input"},
        {"Triggers", "Triggers"}
    }
    
    for i, stat in ipairs(stats) do
        self:CreateStatRow(statsFrame, stat[1], self.Stats[stat[2]] or 0, i)
    end
    
    -- Controles
    local controlsFrame = self:CreateSection(frame, "🛠️ CONTROLES", 160)
    
    local clearBtn = Instance.new("TextButton")
    clearBtn.Size = UDim2.new(0, 140, 0, 30)
    clearBtn.Position = UDim2.new(0, 20, 0, 30)
    clearBtn.BackgroundColor3 = self.Theme.Warning
    clearBtn.BorderSizePixel = 0
    clearBtn.Text = "🧹 LIMPAR LOGS"
    clearBtn.TextColor3 = self.Theme.Text
    clearBtn.Font = Enum.Font.GothamBold
    clearBtn.TextSize = 12
    clearBtn.Parent = controlsFrame
    
    clearBtn.MouseButton1Click:Connect(function()
        self:ClearLogs()
    end)
end

function SecurityMenu:CreateRemoteTab(frame)
    local section = self:CreateSection(frame, "📡 REMOTE EVENTS", 10)
    self:DisplayLogs(section, self.Logs.Remote or {}, 12)
end

function SecurityMenu:CreateCharacterTab(frame)
    local section = self:CreateSection(frame, "🎯 CHARACTER", 10)
    self:DisplayLogs(section, self.Logs.Character or {}, 12)
end

function SecurityMenu:CreateNetworkTab(frame)
    local section = self:CreateSection(frame, "🌐 NETWORK", 10)
    self:DisplayLogs(section, self.Logs.Network or {}, 12)
end

function SecurityMenu:CreateInputTab(frame)
    local section = self:CreateSection(frame, "⌨️ INPUTS", 10)
    self:DisplayLogs(section, self.Logs.Input or {}, 12)
end

function SecurityMenu:CreateTriggersTab(frame)
    local section = self:CreateSection(frame, "🚨 TRIGGERS", 10)
    self:DisplayLogs(section, self.Logs.Triggers or {}, 12)
end

function SecurityMenu:CreateLogsTab(frame)
    local section = self:CreateSection(frame, "📝 TODOS OS LOGS", 10)
    self:DisplayLogs(section, self.Logs.All or {}, 15)
end

-- Funções auxiliares de UI CORRIGIDAS
function SecurityMenu:CreateSection(parent, title, yPos)
    local section = Instance.new("Frame")
    section.Size = UDim2.new(1, -20, 0, 0)
    section.Position = UDim2.new(0, 10, 0, yPos)
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

function SecurityMenu:CreateStatRow(parent, label, value, index)
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
    valueText.TextColor3 = self.Theme.Success
    valueText.TextXAlignment = Enum.TextXAlignment.Right
    valueText.Font = Enum.Font.GothamBold
    valueText.TextSize = 12
    valueText.Parent = row
end

function SecurityMenu:DisplayLogs(section, logs, maxLogs)
    if not logs then return end
    
    local recentLogs = {}
    local logCount = #logs
    local startIndex = math.max(1, logCount - maxLogs + 1)
    
    for i = startIndex, logCount do
        if logs[i] then
            table.insert(recentLogs, logs[i])
        end
    end
    
    for i, log in ipairs(recentLogs) do
        self:CreateLogRow(section, log, i)
    end
end

function SecurityMenu:CreateLogRow(parent, log, index)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, -20, 0, 25)
    row.Position = UDim2.new(0, 10, 0, 30 + (index-1)*30)
    row.BackgroundColor3 = self.Theme.Tab
    row.BorderSizePixel = 0
    row.Parent = parent
    
    local timeLabel = Instance.new("TextLabel")
    timeLabel.Size = UDim2.new(0, 50, 1, 0)
    timeLabel.Position = UDim2.new(0, 5, 0, 0)
    timeLabel.BackgroundTransparency = 1
    timeLabel.Text = log.Time or "00:00:00"
    timeLabel.TextColor3 = self.Theme.TextSecondary
    timeLabel.TextXAlignment = Enum.TextXAlignment.Left
    timeLabel.Font = Enum.Font.Gotham
    timeLabel.TextSize = 9
    timeLabel.Parent = row
    
    local msgLabel = Instance.new("TextLabel")
    msgLabel.Size = UDim2.new(1, -60, 1, 0)
    msgLabel.Position = UDim2.new(0, 60, 0, 0)
    msgLabel.BackgroundTransparency = 1
    msgLabel.Text = log.Message or "Sem mensagem"
    msgLabel.TextColor3 = self.Theme.Text
    msgLabel.TextXAlignment = Enum.TextXAlignment.Left
    msgLabel.Font = Enum.Font.Gotham
    msgLabel.TextSize = 10
    msgLabel.TextTruncate = Enum.TextTruncate.AtEnd
    msgLabel.Parent = row
end

function SecurityMenu:UpdateDisplay()
    if self.CurrentTab then
        self:UpdateTabContent(self.CurrentTab)
    end
end

function SecurityMenu:ClearLogs()
    -- Limpar todas as tabelas de logs
    for category, _ in pairs(self.Logs) do
        self.Logs[category] = {}
    end
    
    -- Resetar estatísticas
    for stat, _ in pairs(self.Stats) do
        self.Stats[stat] = 0
    end
    
    self:Log("System", "🧹 Todos os logs foram limpos!")
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

-- Keybind CORRIGIDO para TECLA F
function SecurityMenu:SetupKeybind()
    local success, result = pcall(function()
        UserInputService.InputBegan:Connect(function(input, processed)
            if not processed and input.KeyCode == self.OpenKey then
                self:ToggleMenu()
            end
        end)
    end)
    
    if not success then
        self:Log("System", "Erro no keybind: " .. tostring(result))
    end
end

-- Triggers de Exemplo
function SecurityMenu:SetupTriggers()
    -- Trigger para movimento rápido
    self:AddTrigger("MovimentoRapido",
        function(category, message)
            return category == "Character" and message:find("Movimento:") and tonumber(message:match("%d+") or 0) > 20
        end,
        function(message)
            -- Ação quando trigger é acionado
        end
    )
end

-- Inicialização CORRIGIDA
function SecurityMenu:Init()
    self:Log("System", "🚀 Iniciando Security Menu...")
    
    local success, err = pcall(function()
        self:CreateUI()
        self:SetupKeybind()
        self:SetupTriggers()
        
        -- Iniciar monitoramentos com delays
        task.wait(1)
        self:MonitorRemoteEvents()
        task.wait(0.5)
        self:MonitorCharacter()
        task.wait(0.5)
        self:MonitorInputs()
        task.wait(0.5)
        self:MonitorNetwork()
        
        self:Log("System", "✅ SECURITY MENU PRONTO! Pressione adawdasdawd ad F para abrir")
        return true
    end)
    
    if not success then
        self:Log("System", "❌ Erro na inicialização: " .. tostring(err))
        return false
    end
    
    return true
end

-- INICIAR AUTOMATICAMENTE COM SEGURANÇA
task.spawn(function()
    task.wait(3) -- Esperar o jogo carregar completamente
    local success = SecurityMenu:Init()
    if not success then
        warn("SecurityMenu: Falha na inicialização")
    end
end)

-- Tornar global para acesso
getgenv().SecurityMenu = SecurityMenu

return SecurityMenu
