-- Advanced Security Testing Panel - CORRIGIDO
-- APENAS para pentest autorizado em servidores próprios

local AdvancedSecurityPanel = {}
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")

-- Configurações
AdvancedSecurityPanel.Config = {
    AutoStart = true,
    LogLevel = "INFO",
    MaxLogs = 500
}

-- Armazenamento
AdvancedSecurityPanel.Logs = {}
AdvancedSecurityPanel.Triggers = {}
AdvancedSecurityPanel.MonitoredRemotes = {}
AdvancedSecurityPanel.Statistics = {
    eventsLogged = 0,
    triggersActivated = 0,
    errorsCount = 0
}

-- Sistema de logging seguro
function AdvancedSecurityPanel:Log(level, category, message, data)
    local success, result = pcall(function()
        local logEntry = {
            Level = level,
            Category = category,
            Message = message,
            Data = data or {},
            Timestamp = os.time(),
            Tick = tick()
        }
        
        table.insert(self.Logs, logEntry)
        self.Statistics.eventsLogged += 1
        
        if #self.Logs > self.Config.MaxLogs then
            table.remove(self.Logs, 1)
        end
        
        print(string.format("[%s] %s: %s", level, category, message))
        
        return true
    end)
    
    if not success then
        warn("Logging error: " .. tostring(result))
    end
end

-- Instrumentação CORRIGIDA para RemoteEvents
function AdvancedSecurityPanel:InstrumentRemoteSafe(remote)
    local success, result = pcall(function()
        if not remote then
            return false, "Remote is nil"
        end
        
        if not remote:IsA("RemoteEvent") and not remote:IsA("RemoteFunction") then
            return false, "Not a RemoteEvent or RemoteFunction"
        end
        
        if self.MonitoredRemotes[remote] then
            return true, "Already monitored"
        end
        
        -- Para RemoteEvent
        if remote:IsA("RemoteEvent") then
            local originalFire
            local isMetamethod = false
            
            -- Verificar se já tem metamethod
            if getmetatable(remote) then
                local success, value = pcall(function() return remote.FireServer end)
                if success and type(value) == "function" then
                    originalFire = value
                end
            end
            
            if not originalFire then
                originalFire = remote.FireServer
            end
            
            if not originalFire then
                return false, "Could not get FireServer method"
            end
            
            -- Criar nova função com proteção
            local newFire = function(self, ...)
                local args = {...}
                local callSuccess, callResult = pcall(function()
                    return originalFire(self, unpack(args))
                end)
                
                AdvancedSecurityPanel:Log("DEBUG", "REMOTE_EVENT", 
                    string.format("Fired: %s (Success: %s)", remote.Name, tostring(callSuccess)), {
                    argsCount = #args,
                    success = callSuccess
                })
                
                if not callSuccess then
                    AdvancedSecurityPanel:Log("ERROR", "REMOTE_EVENT", 
                        string.format("Fire failed: %s", remote.Name), {
                        error = callResult
                    })
                end
                
                return callResult
            end
            
            -- Aplicar de forma segura
            pcall(function()
                remote.FireServer = newFire
            end)
            
        -- Para RemoteFunction  
        elseif remote:IsA("RemoteFunction") then
            local originalInvoke = remote.InvokeServer
            
            if not originalInvoke then
                return false, "Could not get InvokeServer method"
            end
            
            local newInvoke = function(self, ...)
                local args = {...}
                local callSuccess, callResult = pcall(function()
                    return originalInvoke(self, unpack(args))
                end)
                
                AdvancedSecurityPanel:Log("DEBUG", "REMOTE_FUNCTION", 
                    string.format("Invoked: %s (Success: %s)", remote.Name, tostring(callSuccess)), {
                    argsCount = #args,
                    success = callSuccess
                })
                
                return callResult
            end
            
            pcall(function()
                remote.InvokeServer = newInvoke
            end)
        end
        
        self.MonitoredRemotes[remote] = true
        return true, "Success"
    end)
    
    if not success then
        self:Log("ERROR", "INSTRUMENTATION", 
            string.format("Failed to instrument remote: %s", tostring(remote)), {
            error = result
        })
        return false
    end
    
    return true
end

-- Monitoramento de RemoteEvents CORRIGIDO
function AdvancedSecurityPanel:MonitorRemoteEvents()
    self:Log("INFO", "SYSTEM", "Starting safe RemoteEvents monitoring")
    
    local function safeInstrumentFolder(folder)
        local success, descendants = pcall(function()
            return folder:GetDescendants()
        end)
        
        if not success then
            self:Log("ERROR", "MONITORING", 
                string.format("Failed to get descendants of: %s", folder.Name), {
                error = descendants
            })
            return
        end
        
        for _, child in ipairs(descendants) do
            if child:IsA("RemoteEvent") or child:IsA("RemoteFunction") then
                self:InstrumentRemoteSafe(child)
            end
        end
    end
    
    -- Monitorar pastas principais
    local foldersToMonitor = {
        ReplicatedStorage,
        game:GetService("Workspace"),
        game:GetService("Lighting"),
        game:GetService("StarterPack"),
        game:GetService("StarterGui")
    }
    
    for _, folder in ipairs(foldersToMonitor) do
        safeInstrumentFolder(folder)
    end
    
    -- Monitorar novos remotes de forma segura
    local function safeDescendantAdded(descendant)
        local success = pcall(function()
            if descendant:IsA("RemoteEvent") or descendant:IsA("RemoteFunction") then
                task.wait(0.5) -- Esperar inicialização
                AdvancedSecurityPanel:InstrumentRemoteSafe(descendant)
            end
        end)
        
        if not success then
            AdvancedSecurityPanel:Log("ERROR", "MONITORING", 
                "Failed to monitor new descendant")
        end
    end
    
    -- Conectar de forma segura
    for _, folder in ipairs(foldersToMonitor) do
        pcall(function()
            folder.DescendantAdded:Connect(safeDescendantAdded)
        end)
    end
end

-- Monitoramento de Personagem CORRIGIDO
function AdvancedSecurityPanel:MonitorCharacterActions()
    self:Log("INFO", "SYSTEM", "Starting Character monitoring")
    
    local function safeCharacterMonitor()
        local player = Players.LocalPlayer
        if not player then return end
        
        local lastPosition = nil
        
        -- Monitorar movimento
        RunService.Heartbeat:Connect(function()
            local success = pcall(function()
                if player.Character then
                    local rootPart = player.Character:FindFirstChild("HumanoidRootPart")
                    if rootPart then
                        local currentPosition = rootPart.Position
                        if lastPosition then
                            local distance = (currentPosition - lastPosition).Magnitude
                            if distance > 2 then -- Apenas logar movimentos significativos
                                AdvancedSecurityPanel:Log("DEBUG", "CHARACTER_MOVEMENT", 
                                    string.format("Moved: %.2f studs", distance), {
                                    from = lastPosition,
                                    to = currentPosition
                                })
                            end
                        end
                        lastPosition = currentPosition
                    end
                end
            end)
            
            if not success then
                -- Silenciar erros de character não críticos
            end
        end)
    end
    
    pcall(safeCharacterMonitor)
end

-- Monitoramento de Inputs
function AdvancedSecurityPanel:MonitorInputs()
    local success = pcall(function()
        UserInputService.InputBegan:Connect(function(input, gameProcessed)
            if not gameProcessed then
                AdvancedSecurityPanel:Log("DEBUG", "PLAYER_INPUT", 
                    string.format("Input: %s", input.KeyCode.Name), {
                    inputType = input.UserInputType.Name
                })
            end
        end)
    end)
    
    if not success then
        self:Log("ERROR", "INPUT_MONITOR", "Failed to monitor inputs")
    end
end

-- Monitoramento de Players
function AdvancedSecurityPanel:MonitorPlayers()
    local success = pcall(function()
        Players.PlayerAdded:Connect(function(player)
            AdvancedSecurityPanel:Log("INFO", "PLAYER_JOINED", 
                string.format("Player joined: %s", player.Name), {
                userId = player.UserId
            })
        end)
        
        Players.PlayerRemoving:Connect(function(player)
            AdvancedSecurityPanel:Log("INFO", "PLAYER_LEFT", 
                string.format("Player left: %s", player.Name), {
                userId = player.UserId
            })
        end)
    end)
    
    if not success then
        self:Log("ERROR", "PLAYER_MONITOR", "Failed to monitor players")
    end
end

-- Sistema de Triggers Simples
function AdvancedSecurityPanel:AddTrigger(name, eventType, condition, action)
    AdvancedSecurityPanel.Triggers[name] = {
        EventType = eventType,
        Condition = condition,
        Action = action
    }
    
    self:Log("INFO", "TRIGGER", string.format("Trigger added: %s", name))
end

function AdvancedSecurityPanel:CheckTrigger(eventType, data)
    for name, trigger in pairs(AdvancedSecurityPanel.Triggers) do
        if trigger.EventType == eventType then
            local shouldTrigger = true
            
            if trigger.Condition then
                local success, result = pcall(trigger.Condition, data)
                shouldTrigger = success and result
            end
            
            if shouldTrigger then
                pcall(trigger.Action, data)
                AdvancedSecurityPanel.Statistics.triggersActivated += 1
            end
        end
    end
end

-- Triggers padrão
function AdvancedSecurityPanel:SetupDefaultTriggers()
    -- Trigger para movimento rápido
    self:AddTrigger("FAST_MOVEMENT", "CHARACTER_MOVEMENT", 
        function(data)
            return data.distance and data.distance > 50
        end,
        function(data)
            AdvancedSecurityPanel:Log("WARN", "SUSPICIOUS", 
                "Fast movement detected!", {
                speed = data.distance,
                position = data.to
            })
        end
    )
    
    -- Trigger para muitos eventos em curto tempo
    local eventCount = 0
    local lastReset = tick()
    
    self:AddTrigger("EVENT_SPAM", "REMOTE_EVENT", 
        function(data)
            local now = tick()
            if now - lastReset > 1 then -- Reset a cada segundo
                eventCount = 0
                lastReset = now
            end
            
            eventCount = eventCount + 1
            return eventCount > 10 -- Mais de 10 eventos por segundo
        end,
        function(data)
            AdvancedSecurityPanel:Log("WARN", "SUSPICIOUS", 
                "Possible event spam detected!")
        end
    )
end

-- Interface Simples no Console
function AdvancedSecurityPanel:CreateConsoleInterface()
    self:Log("INFO", "SYSTEM", "=== ADVANCED SECURITY PANEL STARTED ===")
    self:Log("INFO", "SYSTEM", "Monitoring: RemoteEvents, Character, Inputs, Players")
    self:Log("INFO", "SYSTEM", "Triggers: Fast Movement, Event Spam")
    self:Log("INFO", "SYSTEM", "Use: AdvancedSecurityPanel:Log('INFO', 'TEST', 'Message')")
    self:Log("INFO", "SYSTEM", "========================================")
end

-- Inicialização CORRIGIDA
function AdvancedSecurityPanel:Init()
    self:Log("INFO", "SYSTEM", "Initializing Advanced Security Panel...")
    
    -- Inicializar componentes com proteção
    local components = {
        {"RemoteEvents", function() self:MonitorRemoteEvents() end},
        {"Character", function() self:MonitorCharacterActions() end},
        {"Inputs", function() self:MonitorInputs() end},
        {"Players", function() self:MonitorPlayers() end},
        {"Triggers", function() self:SetupDefaultTriggers() end},
        {"Interface", function() self:CreateConsoleInterface() end}
    }
    
    for _, component in ipairs(components) do
        local name, func = component[1], component[2]
        local success, err = pcall(func)
        
        if not success then
            self:Log("ERROR", "INIT", 
                string.format("Failed to initialize %s", name), {
                error = err
            })
        else
            self:Log("INFO", "INIT", 
                string.format("Successfully initialized %s", name))
        end
    end
    
    self:Log("INFO", "SYSTEM", "Advanced Security Panel Ready!")
    return true
end

-- Funções públicas para uso
function AdvancedSecurityPanel:GetLogs()
    return self.Logs
end

function AdvancedSecurityPanel:GetStats()
    return self.Statistics
end

function AdvancedSecurityPanel:ClearLogs()
    self.Logs = {}
    self.Statistics.eventsLogged = 0
    self:Log("INFO", "SYSTEM", "Logs cleared")
end

-- Auto-inicialização
if AdvancedSecurityPanel.Config.AutoStart then
    local success, err = pcall(function()
        return AdvancedSecurityPanel:Init()
    end)
    
    if not success then
        warn("AdvancedSecurityPanel: Critical initialization failed - " .. tostring(err))
    end
end

-- Tornar global para acesso fácil
getgenv().AdvancedSecurityPanel = AdvancedSecurityPanel

return AdvancedSecurityPanel
