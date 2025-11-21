-- SHAKA LOGGER v3.0 ULTIMATE - DUMPER + EXECUTOR + ADVANCED CAPTURE
-- Sistema completo de análise e exploração de jogos Roblox

repeat task.wait() until game:IsLoaded()

local Logger = {}
Logger.Events = {}
Logger.Logs = {}
Logger.Blocked = {}
Logger.Capture = {Remote = true, Character = false, Input = false, All = true}
Logger.Stats = {Captured = 0, Blocked = 0, Replayed = 0, Dumped = 0}
Logger.IsOpen = false
Logger.CurrentTab = "Dashboard"
Logger.UI = {}
Logger.HookActive = false
Logger.ExecutorCode = ""
Logger.ExecutorHistory = {}
Logger.DumpData = {}
Logger.Filters = {RemoteEvent = true, RemoteFunction = true, BindableEvent = true}

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInput = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local CoreGui = game:GetService("CoreGui")
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Configurações
local MAX_EVENTS = 100
local MAX_LOGS = 100
local OPEN_KEY = Enum.KeyCode.F
local VERSION = "3.0 ULTIMATE"

-- Cores Modernas
local Colors = {
    BG = Color3.fromRGB(15, 15, 20),
    Card = Color3.fromRGB(25, 25, 35),
    CardHover = Color3.fromRGB(30, 30, 40),
    Primary = Color3.fromRGB(99, 102, 241), -- Indigo
    Secondary = Color3.fromRGB(139, 92, 246), -- Purple
    Success = Color3.fromRGB(34, 197, 94), -- Green
    Danger = Color3.fromRGB(239, 68, 68), -- Red
    Warning = Color3.fromRGB(251, 146, 60), -- Orange
    Info = Color3.fromRGB(59, 130, 246), -- Blue
    Text = Color3.fromRGB(248, 250, 252),
    TextDim = Color3.fromRGB(148, 163, 184),
    TextMuted = Color3.fromRGB(100, 116, 139),
    Accent1 = Color3.fromRGB(236, 72, 153), -- Pink
    Accent2 = Color3.fromRGB(14, 165, 233), -- Sky
    Border = Color3.fromRGB(51, 65, 85),
}

-- Cache de funções originais
local OriginalFunctions = {}
local MonitoredRemotes = {}

pcall(function()
    local tempEvent = Instance.new("RemoteEvent")
    local tempFunc = Instance.new("RemoteFunction")
    OriginalFunctions.FireServer = tempEvent.FireServer
    OriginalFunctions.InvokeServer = tempFunc.InvokeServer
    tempEvent:Destroy()
    tempFunc:Destroy()
end)

-- Utilitários
local function SafePrint(...)
    pcall(print, "[SHAKA v3.0]", ...)
end

local function DeepCopy(obj)
    if type(obj) ~= 'table' then return obj end
    local res = {}
    for k, v in pairs(obj) do
        res[DeepCopy(k)] = DeepCopy(v)
    end
    return res
end

local function FormatArgs(args)
    if not args or type(args) ~= "table" then return "{}" end
    
    local formatted = {}
    for i = 1, math.min(5, #args) do
        local arg = args[i]
        local success, result = pcall(function()
            if type(arg) == "string" then
                return '"' .. tostring(arg):sub(1, 25) .. '"'
            elseif type(arg) == "number" then
                return tostring(math.floor(arg * 100) / 100)
            elseif type(arg) == "boolean" then
                return tostring(arg)
            elseif typeof(arg) == "Instance" then
                return arg.Name or "Instance"
            elseif typeof(arg) == "Vector3" then
                return string.format("Vector3(%.1f, %.1f, %.1f)", arg.X, arg.Y, arg.Z)
            elseif typeof(arg) == "CFrame" then
                return string.format("CFrame(%.1f, %.1f, %.1f)", arg.X, arg.Y, arg.Z)
            elseif type(arg) == "table" then
                return "Table[" .. #arg .. "]"
            else
                return tostring(arg):sub(1, 15)
            end
        end)
        if success then
            table.insert(formatted, result)
        end
    end
    
    if #args > 5 then table.insert(formatted, "...") end
    return "{" .. table.concat(formatted, ", ") .. "}"
end

local function GenerateExploitCode(event)
    local args = FormatArgs(event.Args)
    return string.format([[-- EXPLOIT GERADO AUTOMATICAMENTE
-- Evento: %s
-- Tipo: %s
-- Path: %s

local remote = %s
local args = %s

-- Executar uma vez
remote:FireServer(unpack(args))

-- Executar várias vezes
for i = 1, 10 do
    remote:FireServer(unpack(args))
    task.wait(0.5)
end

-- Loop infinito
while task.wait(0.5) do
    remote:FireServer(unpack(args))
end
]], event.Name, event.Type, event.Path, event.Path, args)
end

-- Sistema de Logs
function Logger:AddLog(category, message, level)
    local log = {
        Time = os.date("%H:%M:%S"),
        Category = category,
        Message = tostring(message),
        Level = level or "info"
    }
    
    table.insert(self.Logs, 1, log)
    while #self.Logs > MAX_LOGS do
        table.remove(self.Logs)
    end
    
    SafePrint(string.format("[%s] %s", category, message))
    
    if self.IsOpen and self.CurrentTab == "Logs" then
        task.spawn(function()
            pcall(function()
                self:RefreshContent()
            end)
        end)
    end
end

-- Sistema de Captura AVANÇADO
function Logger:CaptureEvent(remote, eventType, args, stack)
    if not self.Capture.Remote and not self.Capture.All then return end
    if not remote or not remote.Parent then return end
    
    -- Filtro por tipo
    if eventType == "RemoteEvent" and not self.Filters.RemoteEvent then return end
    if eventType == "RemoteFunction" and not self.Filters.RemoteFunction then return end
    if eventType == "BindableEvent" and not self.Filters.BindableEvent then return end
    
    local path = ""
    local success = pcall(function()
        path = remote:GetFullName()
    end)
    
    if not success or path == "" then return end
    if self.Blocked[path] then return end
    
    -- Clonar args de forma segura
    local clonedArgs = {}
    pcall(function()
        for i, arg in ipairs(args) do
            if type(arg) == "table" then
                clonedArgs[i] = DeepCopy(arg)
            else
                clonedArgs[i] = arg
            end
        end
    end)
    
    local event = {
        Name = remote.Name,
        Type = eventType,
        Path = path,
        Remote = remote,
        Args = clonedArgs,
        Time = os.date("%H:%M:%S"),
        Timestamp = tick(),
        IsLooping = false,
        CallCount = 1,
        Stack = stack or "N/A"
    }
    
    -- Verificar se já existe
    local found = false
    for i, e in ipairs(self.Events) do
        if e.Path == path and FormatArgs(e.Args) == FormatArgs(clonedArgs) then
            e.CallCount = e.CallCount + 1
            e.Time = os.date("%H:%M:%S")
            e.Timestamp = tick()
            found = true
            break
        end
    end
    
    if not found then
        table.insert(self.Events, 1, event)
        while #self.Events > MAX_EVENTS do
            table.remove(self.Events)
        end
    end
    
    self.Stats.Captured = #self.Events
    self:AddLog("Remote", string.format("📡 %s %s (x%d)", remote.Name, FormatArgs(clonedArgs), event.CallCount), "info")
    
    if self.IsOpen and self.CurrentTab == "Events" then
        task.spawn(function()
            pcall(function()
                self:RefreshContent()
            end)
        end)
    end
end

-- Sistema de Hook MELHORADO
function Logger:InstallAdvancedHook()
    local hookSuccess = false
    local monitorSuccess = false
    
    -- Método 1: Hook de metamétodo
    if hookmetamethod and getnamecallmethod and newcclosure then
        pcall(function()
            local old
            old = hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
                local method = getnamecallmethod()
                local args = {...}
                
                if Logger.Capture.All or Logger.Capture.Remote then
                    if method == "FireServer" or method == "InvokeServer" then
                        task.spawn(function()
                            pcall(function()
                                if typeof(self) == "Instance" then
                                    local stack = debug.traceback()
                                    local type = method == "FireServer" and "RemoteEvent" or "RemoteFunction"
                                    Logger:CaptureEvent(self, type, args, stack)
                                end
                            end)
                        end)
                    elseif method == "Fire" and self:IsA("BindableEvent") then
                        task.spawn(function()
                            pcall(function()
                                Logger:CaptureEvent(self, "BindableEvent", args, debug.traceback())
                            end)
                        end)
                    end
                end
                
                return old(self, ...)
            end))
            hookSuccess = true
        end)
    end
    
    -- Método 2: Monitor direto APRIMORADO
    task.spawn(function()
        local function MonitorRemote(remote)
            if MonitoredRemotes[remote] then return end
            MonitoredRemotes[remote] = true
            
            pcall(function()
                if remote:IsA("RemoteEvent") then
                    local oldFire = remote.FireServer
                    remote.FireServer = function(self, ...)
                        local args = {...}
                        if Logger.Capture.All or Logger.Capture.Remote then
                            task.spawn(function()
                                pcall(function()
                                    Logger:CaptureEvent(self, "RemoteEvent", args, debug.traceback())
                                end)
                            end)
                        end
                        return oldFire(self, ...)
                    end
                elseif remote:IsA("RemoteFunction") then
                    local oldInvoke = remote.InvokeServer
                    remote.InvokeServer = function(self, ...)
                        local args = {...}
                        if Logger.Capture.All or Logger.Capture.Remote then
                            task.spawn(function()
                                pcall(function()
                                    Logger:CaptureEvent(self, "RemoteFunction", args, debug.traceback())
                                end)
                            end)
                        end
                        return oldInvoke(self, ...)
                    end
                elseif remote:IsA("BindableEvent") then
                    local oldFire = remote.Fire
                    remote.Fire = function(self, ...)
                        local args = {...}
                        if Logger.Capture.All then
                            task.spawn(function()
                                pcall(function()
                                    Logger:CaptureEvent(self, "BindableEvent", args, debug.traceback())
                                end)
                            end)
                        end
                        return oldFire(self, ...)
                    end
                end
            end)
        end
        
        -- Monitorar existentes
        for _, descendant in ipairs(game:GetDescendants()) do
            if descendant:IsA("RemoteEvent") or descendant:IsA("RemoteFunction") or descendant:IsA("BindableEvent") then
                MonitorRemote(descendant)
            end
        end
        
        -- Monitorar novos
        game.DescendantAdded:Connect(function(descendant)
            if descendant:IsA("RemoteEvent") or descendant:IsA("RemoteFunction") or descendant:IsA("BindableEvent") then
                task.wait(0.1)
                MonitorRemote(descendant)
            end
        end)
        
        monitorSuccess = true
    end)
    
    task.wait(0.5)
    
    if hookSuccess or monitorSuccess then
        self.HookActive = true
        self:AddLog("System", "✅ Sistema de captura AVANÇADO ativo!", "success")
        if hookSuccess then
            self:AddLog("System", "📌 Hook metamétodo: ATIVO", "success")
        end
        if monitorSuccess then
            self:AddLog("System", "📌 Monitor direto: ATIVO", "success")
        end
        return true
    else
        self:AddLog("System", "❌ Falha na instalação do hook", "error")
        return false
    end
end

-- SISTEMA DE DUMPER
function Logger:DumpInstance(instance, depth, maxDepth)
    depth = depth or 0
    maxDepth = maxDepth or 3
    
    if depth > maxDepth then return nil end
    
    local data = {
        Name = instance.Name,
        ClassName = instance.ClassName,
        Path = instance:GetFullName(),
        Children = {},
        Properties = {}
    }
    
    -- Propriedades importantes
    local importantProps = {"Value", "Text", "Position", "Size", "Visible", "Enabled"}
    for _, prop in ipairs(importantProps) do
        pcall(function()
            data.Properties[prop] = tostring(instance[prop])
        end)
    end
    
    -- Filhos
    if depth < maxDepth then
        for _, child in ipairs(instance:GetChildren()) do
            pcall(function()
                table.insert(data.Children, self:DumpInstance(child, depth + 1, maxDepth))
            end)
        end
    end
    
    return data
end

function Logger:DumpGame()
    self:AddLog("Dumper", "🔍 Iniciando dump do jogo...", "info")
    self.DumpData = {}
    
    task.spawn(function()
        local services = {
            "Workspace",
            "ReplicatedStorage",
            "ReplicatedFirst",
            "ServerStorage",
            "Lighting",
            "Players"
        }
        
        for _, serviceName in ipairs(services) do
            pcall(function()
                local service = game:GetService(serviceName)
                self.DumpData[serviceName] = self:DumpInstance(service, 0, 2)
                self.Stats.Dumped = self.Stats.Dumped + 1
                self:AddLog("Dumper", string.format("✅ %s dumped", serviceName), "success")
            end)
        end
        
        -- Dump de remotes
        self.DumpData.Remotes = {}
        for _, desc in ipairs(game:GetDescendants()) do
            pcall(function()
                if desc:IsA("RemoteEvent") or desc:IsA("RemoteFunction") or desc:IsA("BindableEvent") then
                    table.insert(self.DumpData.Remotes, {
                        Name = desc.Name,
                        Type = desc.ClassName,
                        Path = desc:GetFullName()
                    })
                end
            end)
        end
        
        self:AddLog("Dumper", string.format("✅ Dump completo! %d serviços, %d remotes", 
            self.Stats.Dumped, #self.DumpData.Remotes), "success")
        
        if self.IsOpen and self.CurrentTab == "Dumper" then
            self:RefreshContent()
        end
    end)
end

function Logger:ExportDump()
    if not self.DumpData or not next(self.DumpData) then
        self:AddLog("Dumper", "❌ Nenhum dado para exportar!", "error")
        return
    end
    
    local success, json = pcall(function()
        return HttpService:JSONEncode(self.DumpData)
    end)
    
    if success and setclipboard then
        setclipboard(json)
        self:AddLog("Dumper", "📋 Dump copiado para clipboard!", "success")
    elseif success and writefile then
        local filename = "shaka_dump_" .. os.time() .. ".json"
        writefile(filename, json)
        self:AddLog("Dumper", "💾 Dump salvo: " .. filename, "success")
    else
        self:AddLog("Dumper", "❌ Erro ao exportar dump", "error")
    end
end

-- EXECUTOR MELHORADO
function Logger:ExecuteCode(code)
    if not code or code == "" then
        self:AddLog("Executor", "❌ Código vazio!", "error")
        return
    end
    
    self:AddLog("Executor", "▶️ Executando código...", "info")
    
    -- Adicionar ao histórico
    table.insert(self.ExecutorHistory, 1, {
        Code = code,
        Time = os.date("%H:%M:%S")
    })
    while #self.ExecutorHistory > 10 do
        table.remove(self.ExecutorHistory)
    end
    
    task.spawn(function()
        local success, err = pcall(function()
            local func, loadErr = loadstring(code)
            if not func then
                self:AddLog("Executor", "❌ Erro de sintaxe: " .. tostring(loadErr), "error")
                return
            end
            
            func()
            self:AddLog("Executor", "✅ Código executado com sucesso!", "success")
        end)
        
        if not success then
            self:AddLog("Executor", "❌ Erro: " .. tostring(err), "error")
        end
        
        if self.IsOpen and self.CurrentTab == "Executor" then
            task.wait(0.1)
            self:RefreshContent()
        end
    end)
end

-- Replay e Loop
function Logger:ReplayEvent(event, times)
    if not event or not event.Remote or not event.Remote.Parent then
        self:AddLog("System", "❌ Evento inválido", "error")
        return
    end
    
    times = times or 1
    local success = 0
    
    task.spawn(function()
        for i = 1, times do
            local ok = pcall(function()
                if event.Type == "RemoteEvent" then
                    event.Remote:FireServer(unpack(event.Args))
                elseif event.Type == "RemoteFunction" then
                    event.Remote:InvokeServer(unpack(event.Args))
                end
                success = success + 1
            end)
            
            if i < times then 
                task.wait(math.random(100, 300) / 1000) 
            end
        end
        
        self.Stats.Replayed = self.Stats.Replayed + success
        self:AddLog("System", string.format("✅ Replay %s: %d/%d", event.Name, success, times), "success")
    end)
end

function Logger:ToggleLoop(event)
    if not event or not event.Remote then return false end
    
    event.IsLooping = not event.IsLooping
    
    if event.IsLooping then
        self:AddLog("System", "🔁 Loop iniciado: " .. event.Name, "info")
        
        task.spawn(function()
            while event.IsLooping do
                pcall(function()
                    if not event.Remote or not event.Remote.Parent then
                        event.IsLooping = false
                        return
                    end
                    
                    if event.Type == "RemoteEvent" then
                        event.Remote:FireServer(unpack(event.Args))
                    elseif event.Type == "RemoteFunction" then
                        event.Remote:InvokeServer(unpack(event.Args))
                    end
                end)
                
                task.wait(math.random(400, 800) / 1000)
            end
        end)
    else
        self:AddLog("System", "⏹️ Loop parado: " .. event.Name, "info")
    end
    
    return event.IsLooping
end

function Logger:ToggleBlock(path)
    if self.Blocked[path] then
        self.Blocked[path] = nil
        self.Stats.Blocked = math.max(0, self.Stats.Blocked - 1)
        self:AddLog("System", "✅ Desbloqueado", "success")
    else
        self.Blocked[path] = true
        self.Stats.Blocked = self.Stats.Blocked + 1
        self:AddLog("System", "🚫 Bloqueado", "warning")
    end
end

-- Monitoramento
function Logger:StartMonitoring()
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
                        self:AddLog("Character", string.format("🎯 Movimento: %.0f studs", (pos - lastPos).Magnitude), "info")
                    end
                    lastPos = pos
                end
                
                if hum then
                    local hp = hum.Health
                    if lastHp and math.abs(hp - lastHp) > 20 then
                        self:AddLog("Character", string.format("❤️ HP: %.0f → %.0f", lastHp, hp), "info")
                    end
                    lastHp = hp
                end
            end)
        end)
    end)
    
    task.spawn(function()
        local lastInput = {}
        
        UserInput.InputBegan:Connect(function(input, processed)
            if not self.Capture.Input or processed then return end
            
            pcall(function()
                local name = tostring(input.KeyCode.Name or input.UserInputType.Name)
                if lastInput[name] and tick() - lastInput[name] < 2 then return end
                lastInput[name] = tick()
                
                if input.UserInputType == Enum.UserInputType.Keyboard then
                    self:AddLog("Input", "⌨️ " .. input.KeyCode.Name, "info")
                end
            end)
        end)
    end)
    
    self:AddLog("System", "✅ Monitores ativos", "success")
end

-- UI COMPONENTS
function Logger:CreateGradient(parent, colors)
    local gradient = Instance.new("UIGradient")
    gradient.Color = ColorSequence.new(colors)
    gradient.Rotation = 45
    gradient.Parent = parent
    return gradient
end

function Logger:CreateButton(parent, text, color, callback)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 120, 0, 36)
    btn.BackgroundColor3 = color
    btn.Text = text
    btn.TextColor3 = Colors.Text
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 12
    btn.BorderSizePixel = 0
    btn.AutoButtonColor = false
    btn.ZIndex = 10
    btn.Parent = parent
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = btn
    
    local gradient = self:CreateGradient(btn, {color, Color3.fromRGB(
        math.min(255, color.R * 255 + 20),
        math.min(255, color.G * 255 + 20),
        math.min(255, color.B * 255 + 20)
    )})
    
    btn.MouseEnter:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.2), {Size = UDim2.new(0, 125, 0, 38)}):Play()
    end)
    
    btn.MouseLeave:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.2), {Size = UDim2.new(0, 120, 0, 36)}):Play()
    end)
    
    if callback then
        btn.MouseButton1Click:Connect(callback)
    end
    
    return btn
end

function Logger:CreateCard(parent, title, height, icon)
    local card = Instance.new("Frame")
    card.Size = UDim2.new(1, 0, 0, height)
    card.BackgroundColor3 = Colors.Card
    card.BorderSizePixel = 0
    card.ZIndex = 3
    card.Parent = parent
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 12)
    corner.Parent = card
    
    local stroke = Instance.new("UIStroke")
    stroke.Color = Colors.Border
    stroke.Thickness = 1
    stroke.Transparency = 0.5
    stroke.Parent = card
    
    if title then
        local header = Instance.new("Frame")
        header.Size = UDim2.new(1, 0, 0, 45)
        header.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
        header.BorderSizePixel = 0
        header.ZIndex = 4
        header.Parent = card
        
        local headerCorner = Instance.new("UICorner")
        headerCorner.CornerRadius = UDim.new(0, 12)
        headerCorner.Parent = header
        
        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(1, -20, 1, 0)
        label.Position = UDim2.new(0, 15, 0, 0)
        label.BackgroundTransparency = 1
        label.Text = (icon or "📊") .. " " .. title
        label.TextColor3 = Colors.Primary
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.Font = Enum.Font.GothamBold
        label.TextSize = 16
        label.ZIndex = 5
        label.Parent = header
        
        self:CreateGradient(label, {Colors.Primary, Colors.Secondary})
    end
    
    return card
end

function Logger:CreateToggle(parent, name, yPos, icon)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, -20, 0, 42)
    frame.Position = UDim2.new(0, 10, 0, yPos)
    frame.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
    frame.BorderSizePixel = 0
    frame.ZIndex = 4
    frame.Parent = parent
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = frame
    
    local stroke = Instance.new("UIStroke")
    stroke.Color = Colors.Border
    stroke.Thickness = 1
    stroke.Transparency = 0.7
    stroke.Parent = frame
    
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -100, 1, 0)
    label.Position = UDim2.new(0, 15, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = (icon or "⚙️") .. " " .. name
    label.TextColor3 = Colors.Text
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Font = Enum.Font.GothamBold
    label.TextSize = 13
    label.ZIndex = 5
    label.Parent = frame
    
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 70, 0, 30)
    btn.Position = UDim2.new(1, -80, 0.5, -15)
    btn.BackgroundColor3 = self.Capture[name] and Colors.Success or Colors.Danger
    btn.Text = self.Capture[name] and "ON" or "OFF"
    btn.TextColor3 = Colors.Text
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 11
    btn.BorderSizePixel = 0
    btn.ZIndex = 5
    btn.AutoButtonColor = false
    btn.Parent = frame
    
    local btnCorner = Instance.new("UICorner")
    btnCorner.CornerRadius = UDim.new(0, 6)
    btnCorner.Parent = btn
    
    btn.MouseButton1Click:Connect(function()
        self.Capture[name] = not self.Capture[name]
        
        TweenService:Create(btn, TweenInfo.new(0.3), {
            BackgroundColor3 = self.Capture[name] and Colors.Success or Colors.Danger
        }):Play()
        
        btn.Text = self.Capture[name] and "ON" or "OFF"
        self:AddLog("System", name .. ": " .. (self.Capture[name] and "ON" or "OFF"), "info")
    end)
end

-- CRIAR UI PRINCIPAL
function Logger:CreateUI()
    pcall(function()
        local old = CoreGui:FindFirstChild("ShakaLoggerV3")
        if old then old:Destroy() end
    end)
    
    local gui = Instance.new("ScreenGui")
    gui.Name = "ShakaLoggerV3"
    gui.ResetOnSpawn = false
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    gui.IgnoreGuiInset = true
    
    pcall(function() gui.Parent = CoreGui end)
    if not gui.Parent then
        gui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")
    end
    
    -- Main Container
    local main = Instance.new("Frame")
    main.Name = "Main"
    main.Size = UDim2.new(0, 950, 0, 650)
    main.Position = UDim2.new(0.5, -475, 0.5, -325)
    main.BackgroundColor3 = Colors.BG
    main.BorderSizePixel = 0
    main.Visible = false
    main.ZIndex = 1
    main.Parent = gui
    
    self.UI.Main = main
    
    local mainCorner = Instance.new("UICorner")
    mainCorner.CornerRadius = UDim.new(0, 16)
    mainCorner.Parent = main
    
    local mainStroke = Instance.new("UIStroke")
    mainStroke.Color = Colors.Primary
    mainStroke.Thickness = 2
    mainStroke.Transparency = 0.5
    mainStroke.Parent = main
    
    -- Efeito de sombra
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
    
    -- Header com gradiente
    local header = Instance.new("Frame")
    header.Size = UDim2.new(1, 0, 0, 70)
    header.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
    header.BorderSizePixel = 0
    header.ZIndex = 2
    header.Parent = main
    
    local headerCorner = Instance.new("UICorner")
    headerCorner.CornerRadius = UDim.new(0, 16)
    headerCorner.Parent = header
    
    local headerGradient = self:CreateGradient(header, {Colors.Primary, Colors.Secondary})
    headerGradient.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.7),
        NumberSequenceKeypoint.new(1, 0.9)
    })
    
    -- Logo e Título
    local logo = Instance.new("TextLabel")
    logo.Size = UDim2.new(0, 50, 0, 50)
    logo.Position = UDim2.new(0, 20, 0, 10)
    logo.BackgroundTransparency = 1
    logo.Text = "⚡"
    logo.TextColor3 = Colors.Primary
    logo.Font = Enum.Font.GothamBold
    logo.TextSize = 36
    logo.ZIndex = 3
    logo.Parent = header
    
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(0, 400, 0, 30)
    title.Position = UDim2.new(0, 75, 0, 10)
    title.BackgroundTransparency = 1
    title.Text = "SHAKA LOGGER"
    title.TextColor3 = Colors.Text
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Font = Enum.Font.GothamBold
    title.TextSize = 24
    title.ZIndex = 3
    title.Parent = header
    
    local subtitle = Instance.new("TextLabel")
    subtitle.Size = UDim2.new(0, 400, 0, 20)
    subtitle.Position = UDim2.new(0, 75, 0, 40)
    subtitle.BackgroundTransparency = 1
    subtitle.Text = "v" .. VERSION .. " • Ultimate Edition"
    subtitle.TextColor3 = Colors.TextDim
    subtitle.TextXAlignment = Enum.TextXAlignment.Left
    subtitle.Font = Enum.Font.Gotham
    subtitle.TextSize = 12
    subtitle.ZIndex = 3
    subtitle.Parent = header
    
    -- Botões do header
    local minimize = Instance.new("TextButton")
    minimize.Size = UDim2.new(0, 40, 0, 40)
    minimize.Position = UDim2.new(1, -150, 0, 15)
    minimize.BackgroundColor3 = Colors.Info
    minimize.Text = "−"
    minimize.TextColor3 = Colors.Text
    minimize.Font = Enum.Font.GothamBold
    minimize.TextSize = 20
    minimize.BorderSizePixel = 0
    minimize.ZIndex = 3
    minimize.AutoButtonColor = false
    minimize.Parent = header
    
    local minCorner = Instance.new("UICorner")
    minCorner.CornerRadius = UDim.new(0, 10)
    minCorner.Parent = minimize
    
    minimize.MouseButton1Click:Connect(function()
        TweenService:Create(main, TweenInfo.new(0.3), {
            Size = UDim2.new(0, 950, 0, 70)
        }):Play()
    end)
    
    local close = Instance.new("TextButton")
    close.Size = UDim2.new(0, 40, 0, 40)
    close.Position = UDim2.new(1, -100, 0, 15)
    close.BackgroundColor3 = Colors.Danger
    close.Text = "✖"
    close.TextColor3 = Colors.Text
    close.Font = Enum.Font.GothamBold
    close.TextSize = 18
    close.BorderSizePixel = 0
    close.ZIndex = 3
    close.AutoButtonColor = false
    close.Parent = header
    
    local closeCorner = Instance.new("UICorner")
    closeCorner.CornerRadius = UDim.new(0, 10)
    closeCorner.Parent = close
    
    close.MouseButton1Click:Connect(function()
        self:Toggle()
    end)
    
    local refresh = Instance.new("TextButton")
    refresh.Size = UDim2.new(0, 40, 0, 40)
    refresh.Position = UDim2.new(1, -50, 0, 15)
    refresh.BackgroundColor3 = Colors.Success
    refresh.Text = "🔄"
    refresh.TextColor3 = Colors.Text
    refresh.Font = Enum.Font.GothamBold
    refresh.TextSize = 16
    refresh.BorderSizePixel = 0
    refresh.ZIndex = 3
    refresh.AutoButtonColor = false
    refresh.Parent = header
    
    local refreshCorner = Instance.new("UICorner")
    refreshCorner.CornerRadius = UDim.new(0, 10)
    refreshCorner.Parent = refresh
    
    refresh.MouseButton1Click:Connect(function()
        self:RefreshContent()
        TweenService:Create(refresh, TweenInfo.new(0.5), {Rotation = 360}):Play()
        task.wait(0.5)
        refresh.Rotation = 0
    end)
    
    -- Sidebar de Navegação
    local sidebar = Instance.new("Frame")
    sidebar.Size = UDim2.new(0, 200, 1, -80)
    sidebar.Position = UDim2.new(0, 10, 0, 75)
    sidebar.BackgroundColor3 = Colors.Card
    sidebar.BorderSizePixel = 0
    sidebar.ZIndex = 2
    sidebar.Parent = main
    
    local sidebarCorner = Instance.new("UICorner")
    sidebarCorner.CornerRadius = UDim.new(0, 12)
    sidebarCorner.Parent = sidebar
    
    local sidebarStroke = Instance.new("UIStroke")
    sidebarStroke.Color = Colors.Border
    sidebarStroke.Thickness = 1
    sidebarStroke.Transparency = 0.5
    sidebarStroke.Parent = sidebar
    
    -- Tabs
    self.UI.TabButtons = {}
    local tabs = {
        {Name = "Dashboard", Icon = "🏠", Color = Colors.Primary},
        {Name = "Events", Icon = "📡", Color = Colors.Info},
        {Name = "Executor", Icon = "💻", Color = Colors.Accent1},
        {Name = "Dumper", Icon = "📦", Color = Colors.Warning},
        {Name = "Logs", Icon = "📝", Color = Colors.Success},
        {Name = "Settings", Icon = "⚙️", Color = Colors.Secondary}
    }
    
    local yPos = 10
    for _, tab in ipairs(tabs) do
        local btn = Instance.new("TextButton")
        btn.Name = tab.Name
        btn.Size = UDim2.new(1, -20, 0, 50)
        btn.Position = UDim2.new(0, 10, 0, yPos)
        btn.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
        btn.Text = ""
        btn.BorderSizePixel = 0
        btn.ZIndex = 3
        btn.AutoButtonColor = false
        btn.Parent = sidebar
        
        local btnCorner = Instance.new("UICorner")
        btnCorner.CornerRadius = UDim.new(0, 10)
        btnCorner.Parent = btn
        
        local icon = Instance.new("TextLabel")
        icon.Size = UDim2.new(0, 40, 1, 0)
        icon.Position = UDim2.new(0, 10, 0, 0)
        icon.BackgroundTransparency = 1
        icon.Text = tab.Icon
        icon.TextColor3 = Colors.TextDim
        icon.Font = Enum.Font.GothamBold
        icon.TextSize = 20
        icon.ZIndex = 4
        icon.Parent = btn
        
        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(1, -55, 1, 0)
        label.Position = UDim2.new(0, 50, 0, 0)
        label.BackgroundTransparency = 1
        label.Text = tab.Name
        label.TextColor3 = Colors.TextDim
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.Font = Enum.Font.GothamBold
        label.TextSize = 13
        label.ZIndex = 4
        label.Parent = btn
        
        btn.MouseEnter:Connect(function()
            if self.CurrentTab ~= tab.Name then
                TweenService:Create(btn, TweenInfo.new(0.2), {
                    BackgroundColor3 = Color3.fromRGB(40, 40, 50)
                }):Play()
            end
        end)
        
        btn.MouseLeave:Connect(function()
            if self.CurrentTab ~= tab.Name then
                TweenService:Create(btn, TweenInfo.new(0.2), {
                    BackgroundColor3 = Color3.fromRGB(30, 30, 40)
                }):Play()
            end
        end)
        
        btn.MouseButton1Click:Connect(function()
            self:SwitchTab(tab.Name)
        end)
        
        self.UI.TabButtons[tab.Name] = {Button = btn, Icon = icon, Label = label, Color = tab.Color}
        yPos = yPos + 60
    end
    
    -- Content Area
    local content = Instance.new("Frame")
    content.Size = UDim2.new(1, -230, 1, -80)
    content.Position = UDim2.new(0, 220, 0, 75)
    content.BackgroundTransparency = 1
    content.BorderSizePixel = 0
    content.ZIndex = 2
    content.Parent = main
    
    self.UI.ContentFrames = {}
    
    for _, tab in ipairs(tabs) do
        local frame = Instance.new("ScrollingFrame")
        frame.Name = tab.Name
        frame.Size = UDim2.new(1, 0, 1, 0)
        frame.BackgroundTransparency = 1
        frame.BorderSizePixel = 0
        frame.ScrollBarThickness = 6
        frame.ScrollBarImageColor3 = Colors.Primary
        frame.Visible = false
        frame.CanvasSize = UDim2.new(0, 0, 0, 0)
        frame.AutomaticCanvasSize = Enum.AutomaticSize.Y
        frame.ZIndex = 3
        frame.Parent = content
        
        local layout = Instance.new("UIListLayout")
        layout.Padding = UDim.new(0, 15)
        layout.Parent = frame
        
        self.UI.ContentFrames[tab.Name] = frame
    end
    
    self:AddLog("System", "✅ UI Ultra criada com sucesso!", "success")
end

function Logger:SwitchTab(tabName)
    self.CurrentTab = tabName
    
    for name, data in pairs(self.UI.TabButtons) do
        if name == tabName then
            TweenService:Create(data.Button, TweenInfo.new(0.3), {
                BackgroundColor3 = data.Color
            }):Play()
            TweenService:Create(data.Icon, TweenInfo.new(0.3), {
                TextColor3 = Colors.Text
            }):Play()
            TweenService:Create(data.Label, TweenInfo.new(0.3), {
                TextColor3 = Colors.Text
            }):Play()
        else
            TweenService:Create(data.Button, TweenInfo.new(0.3), {
                BackgroundColor3 = Color3.fromRGB(30, 30, 40)
            }):Play()
            TweenService:Create(data.Icon, TweenInfo.new(0.3), {
                TextColor3 = Colors.TextDim
            }):Play()
            TweenService:Create(data.Label, TweenInfo.new(0.3), {
                TextColor3 = Colors.TextDim
            }):Play()
        end
    end
    
    for name, frame in pairs(self.UI.ContentFrames) do
        frame.Visible = (name == tabName)
    end
    
    self:RefreshContent()
end

function Logger:RefreshContent()
    task.spawn(function()
        pcall(function()
            local frame = self.UI.ContentFrames[self.CurrentTab]
            if not frame then return end
            
            for _, child in ipairs(frame:GetChildren()) do
                if not child:IsA("UIListLayout") then
                    child:Destroy()
                end
            end
            
            if self.CurrentTab == "Dashboard" then
                self:BuildDashboard(frame)
            elseif self.CurrentTab == "Events" then
                self:BuildEvents(frame)
            elseif self.CurrentTab == "Executor" then
                self:BuildExecutor(frame)
            elseif self.CurrentTab == "Dumper" then
                self:BuildDumper(frame)
            elseif self.CurrentTab == "Logs" then
                self:BuildLogs(frame)
            elseif self.CurrentTab == "Settings" then
                self:BuildSettings(frame)
            end
        end)
    end)
end

-- BUILD DASHBOARD
function Logger:BuildDashboard(parent)
    -- Stats Cards
    local statsContainer = Instance.new("Frame")
    statsContainer.Size = UDim2.new(1, 0, 0, 120)
    statsContainer.BackgroundTransparency = 1
    statsContainer.Parent = parent
    
    local statsLayout = Instance.new("UIListLayout")
    statsLayout.FillDirection = Enum.FillDirection.Horizontal
    statsLayout.Padding = UDim.new(0, 15)
    statsLayout.Parent = statsContainer
    
    local stats = {
        {Title = "Eventos", Value = self.Stats.Captured, Icon = "📡", Color = Colors.Info},
        {Title = "Replays", Value = self.Stats.Replayed, Icon = "🔁", Color = Colors.Success},
        {Title = "Bloqueados", Value = self.Stats.Blocked, Icon = "🚫", Color = Colors.Danger},
        {Title = "Dumps", Value = self.Stats.Dumped, Icon = "📦", Color = Colors.Warning}
    }
    
    for _, stat in ipairs(stats) do
        local card = Instance.new("Frame")
        card.Size = UDim2.new(0, 160, 1, 0)
        card.BackgroundColor3 = Colors.Card
        card.BorderSizePixel = 0
        card.ZIndex = 3
        card.Parent = statsContainer
        
        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 12)
        corner.Parent = card
        
        local stroke = Instance.new("UIStroke")
        stroke.Color = stat.Color
        stroke.Thickness = 2
        stroke.Transparency = 0.5
        stroke.Parent = card
        
        local icon = Instance.new("TextLabel")
        icon.Size = UDim2.new(0, 50, 0, 50)
        icon.Position = UDim2.new(0, 15, 0, 15)
        icon.BackgroundTransparency = 1
        icon.Text = stat.Icon
        icon.TextColor3 = stat.Color
        icon.Font = Enum.Font.GothamBold
        icon.TextSize = 32
        icon.ZIndex = 4
        icon.Parent = card
        
        local value = Instance.new("TextLabel")
        value.Size = UDim2.new(1, -70, 0, 30)
        value.Position = UDim2.new(0, 70, 0, 20)
        value.BackgroundTransparency = 1
        value.Text = tostring(stat.Value)
        value.TextColor3 = Colors.Text
        value.TextXAlignment = Enum.TextXAlignment.Left
        value.Font = Enum.Font.GothamBold
        value.TextSize = 28
        value.ZIndex = 4
        value.Parent = card
        
        local title = Instance.new("TextLabel")
        title.Size = UDim2.new(1, -70, 0, 20)
        title.Position = UDim2.new(0, 70, 0, 50)
        title.BackgroundTransparency = 1
        title.Text = stat.Title
        title.TextColor3 = Colors.TextDim
        title.TextXAlignment = Enum.TextXAlignment.Left
        title.Font = Enum.Font.Gotham
        title.TextSize = 12
        title.ZIndex = 4
        title.Parent = card
    end
    
    -- Quick Actions
    local actions = self:CreateCard(parent, "AÇÕES RÁPIDAS", 180, "⚡")
    
    local actionsGrid = Instance.new("Frame")
    actionsGrid.Size = UDim2.new(1, -20, 1, -55)
    actionsGrid.Position = UDim2.new(0, 10, 0, 50)
    actionsGrid.BackgroundTransparency = 1
    actionsGrid.ZIndex = 4
    actionsGrid.Parent = actions
    
    local gridLayout = Instance.new("UIGridLayout")
    gridLayout.CellSize = UDim2.new(0, 200, 0, 50)
    gridLayout.CellPadding = UDim2.new(0, 10, 0, 10)
    gridLayout.Parent = actionsGrid
    
    local quickActions = {
        {Text = "🗑️ Limpar Eventos", Color = Colors.Danger, Action = function()
            self.Events = {}
            self.Stats.Captured = 0
            self:AddLog("System", "🗑️ Eventos limpos", "success")
            self:RefreshContent()
        end},
        {Text = "✅ Desbloquear Tudo", Color = Colors.Success, Action = function()
            self.Blocked = {}
            self.Stats.Blocked = 0
            self:AddLog("System", "✅ Todos desbloqueados", "success")
            self:RefreshContent()
        end},
        {Text = "📦 Iniciar Dump", Color = Colors.Warning, Action = function()
            self:DumpGame()
        end},
        {Text = "🔄 Reset Stats", Color = Colors.Info, Action = function()
            self.Stats.Replayed = 0
            self:AddLog("System", "🔄 Stats resetadas", "info")
            self:RefreshContent()
        end}
    }
    
    for _, action in ipairs(quickActions) do
        local btn = Instance.new("TextButton")
        btn.BackgroundColor3 = action.Color
        btn.Text = action.Text
        btn.TextColor3 = Colors.Text
        btn.Font = Enum.Font.GothamBold
        btn.TextSize = 12
        btn.BorderSizePixel = 0
        btn.ZIndex = 5
        btn.AutoButtonColor = false
        btn.Parent = actionsGrid
        
        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 8)
        corner.Parent = btn
        
        btn.MouseButton1Click:Connect(action.Action)
    end
    
    -- System Status
    local status = self:CreateCard(parent, "STATUS DO SISTEMA", 160, "🔧")
    
    local statusText = Instance.new("TextLabel")
    statusText.Size = UDim2.new(1, -30, 0, 100)
    statusText.Position = UDim2.new(0, 15, 0, 50)
    statusText.BackgroundTransparency = 1
    statusText.Text = string.format([[
Hook Status: %s
Capture Mode: %s
Total Remotes: %d
FPS: %d
    ]], 
        self.HookActive and "✅ ATIVO" or "❌ INATIVO",
        self.Capture.All and "COMPLETO" or "PARCIAL",
        #MonitoredRemotes,
        math.floor(1 / RunService.Heartbeat:Wait())
    )
    statusText.TextColor3 = Colors.Text
    statusText.TextXAlignment = Enum.TextXAlignment.Left
    statusText.TextYAlignment = Enum.TextYAlignment.Top
    statusText.Font = Enum.Font.Code
    statusText.TextSize = 13
    statusText.ZIndex = 4
    statusText.Parent = status
end

-- BUILD EVENTS
function Logger:BuildEvents(parent)
    if #self.Events == 0 then
        local empty = self:CreateCard(parent, "SEM EVENTOS", 100, "⚠️")
        
        local msg = Instance.new("TextLabel")
        msg.Size = UDim2.new(1, -30, 0, 40)
        msg.Position = UDim2.new(0, 15, 0, 55)
        msg.BackgroundTransparency = 1
        msg.Text = self.Capture.Remote and "Interaja com o jogo para capturar eventos..." or "Ative a captura em Settings!"
        msg.TextColor3 = Colors.TextDim
        msg.Font = Enum.Font.Gotham
        msg.TextSize = 13
        msg.TextWrapped = true
        msg.ZIndex = 4
        msg.Parent = empty
        return
    end
    
    -- Filtros
    local filters = self:CreateCard(parent, "FILTROS", 100, "🔍")
    
    local yPos = 55
    for filterName, enabled in pairs(self.Filters) do
        local toggle = Instance.new("TextButton")
        toggle.Size = UDim2.new(0, 180, 0, 35)
        toggle.Position = UDim2.new(0, 15 + ((yPos - 55) * 2), 0, yPos)
        toggle.BackgroundColor3 = enabled and Colors.Success or Colors.Danger
        toggle.Text = filterName .. ": " .. (enabled and "ON" or "OFF")
        toggle.TextColor3 = Colors.Text
        toggle.Font = Enum.Font.GothamBold
        toggle.TextSize = 11
        toggle.BorderSizePixel = 0
        toggle.ZIndex = 5
        toggle.AutoButtonColor = false
        toggle.Parent = filters
        
        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 6)
        corner.Parent = toggle
        
        toggle.MouseButton1Click:Connect(function()
            self.Filters[filterName] = not self.Filters[filterName]
            self:RefreshContent()
        end)
        
        yPos = yPos + 0
    end
    
    -- Lista de eventos
    for i, event in ipairs(self.Events) do
        if i > 20 then break end
        pcall(function()
            self:CreateEventCard(parent, event)
        end)
    end
end

function Logger:CreateEventCard(parent, event)
    local isBlocked = self.Blocked[event.Path]
    
    local card = Instance.new("Frame")
    card.Size = UDim2.new(1, 0, 0, 140)
    card.BackgroundColor3 = Colors.Card
    card.BorderSizePixel = 0
    card.ZIndex = 3
    card.Parent = parent
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 12)
    corner.Parent = card
    
    local stroke = Instance.new("UIStroke")
    stroke.Color = isBlocked and Colors.Danger or (event.IsLooping and Colors.Success or Colors.Primary)
    stroke.Thickness = 2
    stroke.Transparency = 0.3
    stroke.Parent = card
    
    -- Header do evento
    local header = Instance.new("Frame")
    header.Size = UDim2.new(1, 0, 0, 50)
    header.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
    header.BorderSizePixel = 0
    header.ZIndex = 4
    header.Parent = card
    
    local headerCorner = Instance.new("UICorner")
    headerCorner.CornerRadius = UDim.new(0, 12)
    headerCorner.Parent = header
    
    local typeIcon = "📡"
    if event.Type == "RemoteFunction" then typeIcon = "🔄"
    elseif event.Type == "BindableEvent" then typeIcon = "🔗" end
    
    local name = Instance.new("TextLabel")
    name.Size = UDim2.new(1, -350, 1, 0)
    name.Position = UDim2.new(0, 15, 0, 0)
    name.BackgroundTransparency = 1
    name.Text = typeIcon .. " " .. event.Name
    name.TextColor3 = Colors.Primary
    name.TextXAlignment = Enum.TextXAlignment.Left
    name.Font = Enum.Font.GothamBold
    name.TextSize = 14
    name.TextTruncate = Enum.TextTruncate.AtEnd
    name.ZIndex = 5
    name.Parent = header
    
    local count = Instance.new("TextLabel")
    count.Size = UDim2.new(0, 100, 1, 0)
    count.Position = UDim2.new(1, -250, 0, 0)
    count.BackgroundTransparency = 1
    count.Text = "Calls: " .. event.CallCount
    count.TextColor3 = Colors.Warning
    count.Font = Enum.Font.GothamBold
    count.TextSize = 12
    count.ZIndex = 5
    count.Parent = header
    
    local time = Instance.new("TextLabel")
    time.Size = UDim2.new(0, 140, 1, 0)
    time.Position = UDim2.new(1, -140, 0, 0)
    time.BackgroundTransparency = 1
    time.Text = "🕐 " .. event.Time
    time.TextColor3 = Colors.TextDim
    time.Font = Enum.Font.Code
    time.TextSize = 11
    time.ZIndex = 5
    time.Parent = header
    
    -- Info do evento
    local path = Instance.new("TextLabel")
    path.Size = UDim2.new(1, -30, 0, 18)
    path.Position = UDim2.new(0, 15, 0, 58)
    path.BackgroundTransparency = 1
    path.Text = "📍 " .. event.Path
    path.TextColor3 = Colors.TextDim
    path.TextXAlignment = Enum.TextXAlignment.Left
    path.Font = Enum.Font.Code
    path.TextSize = 10
    path.TextTruncate = Enum.TextTruncate.AtEnd
    path.ZIndex = 4
    path.Parent = card
    
    local args = Instance.new("TextLabel")
    args.Size = UDim2.new(1, -30, 0, 18)
    args.Position = UDim2.new(0, 15, 0, 78)
    args.BackgroundTransparency = 1
    args.Text = "📦 " .. FormatArgs(event.Args)
    args.TextColor3 = Colors.Warning
    args.TextXAlignment = Enum.TextXAlignment.Left
    args.Font = Enum.Font.Code
    args.TextSize = 10
    args.TextTruncate = Enum.TextTruncate.AtEnd
    args.ZIndex = 4
    args
