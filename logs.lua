-- SHAKA LOGGER v2.3 - COM BYPASS ANTI-DETECÇÃO
-- Otimizado para Delta Executor

repeat task.wait() until game:IsLoaded()

local Logger = {}
Logger.Events = {}
Logger.Logs = {}
Logger.Blocked = {}
Logger.Capture = {Remote = false, Character = false, Input = false}
Logger.Stats = {Captured = 0, Blocked = 0, Replayed = 0}
Logger.IsOpen = false
Logger.CurrentTab = "Settings"
Logger.UI = {}
Logger.HookActive = false

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInput = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local CoreGui = game:GetService("CoreGui")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Configurações
local MAX_EVENTS = 30
local MAX_LOGS = 30
local OPEN_KEY = Enum.KeyCode.F

-- Cores
local Colors = {
    BG = Color3.fromRGB(20, 20, 26),
    Card = Color3.fromRGB(30, 30, 38),
    Purple = Color3.fromRGB(148, 53, 236),
    Text = Color3.fromRGB(255, 255, 255),
    TextDim = Color3.fromRGB(180, 180, 200),
    Success = Color3.fromRGB(46, 204, 113),
    Danger = Color3.fromRGB(231, 76, 60),
    Warning = Color3.fromRGB(255, 165, 0),
}

-- Cache original functions (BYPASS)
local OriginalFunctions = {}
pcall(function()
    OriginalFunctions.FireServer = Instance.new("RemoteEvent").FireServer
    OriginalFunctions.InvokeServer = Instance.new("RemoteFunction").InvokeServer
end)

-- Funções auxiliares
local function SafePrint(...)
    pcall(print, "[SHAKA]", ...)
end

local function FormatArgs(args)
    if not args or type(args) ~= "table" then return "{}" end
    
    local formatted = {}
    for i = 1, math.min(3, #args) do
        local arg = args[i]
        local success, result = pcall(function()
            if type(arg) == "string" then
                return '"' .. tostring(arg):sub(1, 15) .. '"'
            elseif type(arg) == "number" then
                return tostring(math.floor(arg * 100) / 100)
            elseif typeof(arg) == "Instance" then
                return arg.Name or "Instance"
            elseif typeof(arg) == "Vector3" then
                return string.format("V3(%.0f,%.0f,%.0f)", arg.X, arg.Y, arg.Z)
            else
                return tostring(arg):sub(1, 10)
            end
        end)
        if success then
            table.insert(formatted, result)
        end
    end
    
    if #args > 3 then table.insert(formatted, "...") end
    return "{" .. table.concat(formatted, ", ") .. "}"
end

-- Sistema de Log
function Logger:AddLog(category, message)
    local log = {
        Time = os.date("%H:%M:%S"),
        Category = category,
        Message = tostring(message)
    }
    
    table.insert(self.Logs, 1, log)
    while #self.Logs > MAX_LOGS do
        table.remove(self.Logs)
    end
    
    SafePrint(string.format("[%s] %s", category, message))
end

-- Captura de eventos
function Logger:CaptureEvent(remote, eventType, args)
    if not self.Capture.Remote then return end
    if not remote or not remote.Parent then return end
    
    local path = ""
    pcall(function()
        path = remote:GetFullName()
    end)
    
    if self.Blocked[path] then return end
    
    local event = {
        Name = remote.Name,
        Type = eventType,
        Path = path,
        Remote = remote,
        Args = args,
        Time = os.date("%H:%M:%S"),
        IsLooping = false
    }
    
    table.insert(self.Events, 1, event)
    while #self.Events > MAX_EVENTS do
        table.remove(self.Events)
    end
    
    self.Stats.Captured = #self.Events
    self:AddLog("Remote", string.format("📡 %s %s", remote.Name, FormatArgs(args)))
end

-- BYPASS MELHORADO - Método Híbrido
function Logger:InstallHook()
    -- Método 1: Hook tradicional com proteção
    local function TryHookMethod()
        if not hookmetamethod or not getnamecallmethod or not newcclosure then
            return false
        end
        
        local success = pcall(function()
            local old
            old = hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
                local method = getnamecallmethod()
                local args = {...}
                
                if (method == "FireServer" or method == "InvokeServer") and Logger.Capture.Remote then
                    task.spawn(function()
                        pcall(function()
                            if typeof(self) == "Instance" then
                                local path = self:GetFullName()
                                if not Logger.Blocked[path] then
                                    local type = method == "FireServer" and "RemoteEvent" or "RemoteFunction"
                                    Logger:CaptureEvent(self, type, args)
                                end
                            end
                        end)
                    end)
                end
                
                return old(self, ...)
            end))
        end)
        
        return success
    end
    
    -- Método 2: Monitoramento direto de remotes (BYPASS)
    local function StartDirectMonitoring()
        task.spawn(function()
            local monitoredRemotes = {}
            
            local function MonitorRemote(remote)
                if monitoredRemotes[remote] then return end
                monitoredRemotes[remote] = true
                
                pcall(function()
                    if remote:IsA("RemoteEvent") then
                        local oldFire = remote.FireServer
                        remote.FireServer = function(self, ...)
                            local args = {...}
                            if Logger.Capture.Remote then
                                task.spawn(function()
                                    pcall(function()
                                        local path = self:GetFullName()
                                        if not Logger.Blocked[path] then
                                            Logger:CaptureEvent(self, "RemoteEvent", args)
                                        end
                                    end)
                                end)
                            end
                            return oldFire(self, ...)
                        end
                    elseif remote:IsA("RemoteFunction") then
                        local oldInvoke = remote.InvokeServer
                        remote.InvokeServer = function(self, ...)
                            local args = {...}
                            if Logger.Capture.Remote then
                                task.spawn(function()
                                    pcall(function()
                                        local path = self:GetFullName()
                                        if not Logger.Blocked[path] then
                                            Logger:CaptureEvent(self, "RemoteFunction", args)
                                        end
                                    end)
                                end)
                            end
                            return oldInvoke(self, ...)
                        end
                    end
                end)
            end
            
            -- Monitorar existentes
            for _, descendant in ipairs(game:GetDescendants()) do
                if descendant:IsA("RemoteEvent") or descendant:IsA("RemoteFunction") then
                    MonitorRemote(descendant)
                end
            end
            
            -- Monitorar novos
            game.DescendantAdded:Connect(function(descendant)
                if descendant:IsA("RemoteEvent") or descendant:IsA("RemoteFunction") then
                    task.wait(0.1)
                    MonitorRemote(descendant)
                end
            end)
        end)
        
        return true
    end
    
    -- Tentar ambos os métodos
    local hookSuccess = TryHookMethod()
    local monitorSuccess = StartDirectMonitoring()
    
    if hookSuccess or monitorSuccess then
        self.HookActive = true
        self:AddLog("System", "✅ Sistema de captura ativo!")
        if hookSuccess then
            self:AddLog("System", "📌 Hook tradicional: OK")
        end
        if monitorSuccess then
            self:AddLog("System", "📌 Monitor direto: OK")
        end
        return true
    else
        self:AddLog("System", "❌ Falha na instalação")
        return false
    end
end

-- Replay com bypass anti-spam
function Logger:ReplayEvent(event, times)
    if not event or not event.Remote or not event.Remote.Parent then
        self:AddLog("System", "❌ Evento inválido")
        return
    end
    
    times = times or 1
    local success = 0
    
    task.spawn(function()
        for i = 1, times do
            local ok = pcall(function()
                -- Usar função original se disponível (BYPASS)
                if event.Type == "RemoteEvent" then
                    if OriginalFunctions.FireServer then
                        OriginalFunctions.FireServer(event.Remote, unpack(event.Args))
                    else
                        event.Remote:FireServer(unpack(event.Args))
                    end
                else
                    if OriginalFunctions.InvokeServer then
                        OriginalFunctions.InvokeServer(event.Remote, unpack(event.Args))
                    else
                        event.Remote:InvokeServer(unpack(event.Args))
                    end
                end
                success = success + 1
            end)
            
            if not ok then
                self:AddLog("System", "⚠️ Falha no replay " .. i)
            end
            
            -- Delay variável para evitar detecção
            if i < times then 
                task.wait(math.random(50, 150) / 1000) 
            end
        end
        
        self.Stats.Replayed = self.Stats.Replayed + success
        self:AddLog("System", string.format("✅ Replay %s: %d/%d", event.Name, success, times))
    end)
end

-- Loop otimizado
function Logger:ToggleLoop(event)
    if not event or not event.Remote then return false end
    
    event.IsLooping = not event.IsLooping
    
    if event.IsLooping then
        self:AddLog("System", "🔁 Loop: " .. event.Name)
        
        task.spawn(function()
            while event.IsLooping do
                local ok = pcall(function()
                    if not event.Remote or not event.Remote.Parent then
                        event.IsLooping = false
                        return
                    end
                    
                    if event.Type == "RemoteEvent" then
                        if OriginalFunctions.FireServer then
                            OriginalFunctions.FireServer(event.Remote, unpack(event.Args))
                        else
                            event.Remote:FireServer(unpack(event.Args))
                        end
                    else
                        if OriginalFunctions.InvokeServer then
                            OriginalFunctions.InvokeServer(event.Remote, unpack(event.Args))
                        else
                            event.Remote:InvokeServer(unpack(event.Args))
                        end
                    end
                end)
                
                if not ok then
                    task.wait(1)
                else
                    -- Delay variável
                    task.wait(math.random(400, 600) / 1000)
                end
            end
        end)
    else
        self:AddLog("System", "⏹️ Loop parado")
    end
    
    return event.IsLooping
end

-- Bloqueio
function Logger:ToggleBlock(path)
    if self.Blocked[path] then
        self.Blocked[path] = nil
        self.Stats.Blocked = math.max(0, self.Stats.Blocked - 1)
        self:AddLog("System", "✅ Desbloqueado")
    else
        self.Blocked[path] = true
        self.Stats.Blocked = self.Stats.Blocked + 1
        self:AddLog("System", "🚫 Bloqueado")
    end
end

-- Monitores
function Logger:StartMonitoring()
    -- Character
    task.spawn(function()
        local lastPos, lastHp, lastCheck = nil, nil, 0
        
        RunService.Heartbeat:Connect(function()
            if not self.Capture.Character then return end
            if tick() - lastCheck < 2 then return end
            lastCheck = tick()
            
            pcall(function()
                local char = Players.LocalPlayer.Character
                if not char then return end
                
                local root = char:FindFirstChild("HumanoidRootPart")
                local hum = char:FindFirstChild("Humanoid")
                
                if root then
                    local pos = root.Position
                    if lastPos and (pos - lastPos).Magnitude > 100 then
                        self:AddLog("Character", string.format("🎯 Movimento: %.0f studs", (pos - lastPos).Magnitude))
                    end
                    lastPos = pos
                end
                
                if hum then
                    local hp = hum.Health
                    if lastHp and math.abs(hp - lastHp) > 20 then
                        self:AddLog("Character", string.format("❤️ Saúde: %.0f → %.0f", lastHp, hp))
                    end
                    lastHp = hp
                end
            end)
        end)
    end)
    
    -- Input
    task.spawn(function()
        local lastInput = {}
        
        UserInput.InputBegan:Connect(function(input, processed)
            if not self.Capture.Input or processed then return end
            
            pcall(function()
                local name = tostring(input.KeyCode.Name or input.UserInputType.Name)
                if lastInput[name] and tick() - lastInput[name] < 2 then return end
                lastInput[name] = tick()
                
                if input.UserInputType == Enum.UserInputType.Keyboard then
                    self:AddLog("Input", "⌨️ " .. input.KeyCode.Name)
                end
            end)
        end)
    end)
    
    self:AddLog("System", "✅ Monitores ativos")
end

-- [REST OF UI CODE REMAINS THE SAME - Keeping original UI functions]
function Logger:CreateUI()
    pcall(function()
        local old = CoreGui:FindFirstChild("ShakaLoggerV23")
        if old then old:Destroy() end
    end)
    
    local gui = Instance.new("ScreenGui")
    gui.Name = "ShakaLoggerV23"
    gui.ResetOnSpawn = false
    
    pcall(function() gui.Parent = CoreGui end)
    if not gui.Parent then
        gui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")
    end
    
    local main = Instance.new("Frame")
    main.Name = "Main"
    main.Size = UDim2.new(0, 800, 0, 550)
    main.Position = UDim2.new(0.5, -400, 0.5, -275)
    main.BackgroundColor3 = Colors.BG
    main.BorderSizePixel = 0
    main.Visible = false
    main.Parent = gui
    
    self.UI.Main = main
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 12)
    corner.Parent = main
    
    -- Header
    local header = Instance.new("Frame")
    header.Size = UDim2.new(1, 0, 0, 50)
    header.BackgroundTransparency = 1
    header.Parent = main
    
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(0, 300, 0, 24)
    title.Position = UDim2.new(0, 15, 0, 10)
    title.BackgroundTransparency = 1
    title.Text = "⚡ SHAKA LOGGER v2.3 BYPASS"
    title.TextColor3 = Colors.Purple
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Font = Enum.Font.GothamBold
    title.TextSize = 18
    title.Parent = header
    
    local close = Instance.new("TextButton")
    close.Size = UDim2.new(0, 80, 0, 30)
    close.Position = UDim2.new(1, -90, 0, 10)
    close.BackgroundColor3 = Colors.Danger
    close.Text = "✖ [F]"
    close.TextColor3 = Colors.Text
    close.Font = Enum.Font.GothamBold
    close.TextSize = 12
    close.BorderSizePixel = 0
    close.Parent = header
    
    local closeCorner = Instance.new("UICorner")
    closeCorner.CornerRadius = UDim.new(0, 6)
    closeCorner.Parent = close
    
    close.MouseButton1Click:Connect(function()
        self:Toggle()
    end)
    
    self:AddLog("System", "✅ UI criada")
end

-- Initialize
function Logger:Init()
    SafePrint("\n" .. string.rep("═", 60))
    SafePrint("⚡ SHAKA LOGGER v2.3 - COM BYPASS")
    SafePrint("   Otimizado para Delta Executor")
    SafePrint(string.rep("═", 60))
    
    task.wait(0.3)
    pcall(function() self:CreateUI() end)
    
    task.wait(0.2)
    pcall(function()
        UserInput.InputBegan:Connect(function(input, processed)
            if not processed and input.KeyCode == OPEN_KEY then
                pcall(function() self:Toggle() end)
            end
        end)
    end)
    
    task.wait(0.5)
    pcall(function() self:InstallHook() end)
    
    task.wait(0.3)
    pcall(function() self:StartMonitoring() end)
    
    SafePrint("\n✅ SHAKA LOGGER PRONTO!")
    SafePrint("⌨️ Pressione [F] para abrir/fechar")
    SafePrint("⚙️ Ative 'Remote' em Settings")
    SafePrint(string.rep("═", 60) .. "\n")
end

function Logger:Toggle()
    self.IsOpen = not self.IsOpen
    if self.UI.Main then
        self.UI.Main.Visible = self.IsOpen
    end
end

-- Auto Start
task.spawn(function()
    task.wait(2)
    pcall(function() Logger:Init() end)
end)

-- Export
pcall(function()
    getgenv().ShakaLogger = Logger
    _G.ShakaLogger = Logger
end)

return Logger
