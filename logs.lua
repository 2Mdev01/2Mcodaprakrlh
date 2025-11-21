-- SHAKA LOGGER v2.5 - COM EXECUTOR LUA INTEGRADO
-- Compatível com Delta Executor e outros executores modernos

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
Logger.ExecutorCode = ""
Logger.ExecutorThread = nil
Logger.ExecutorRunning = false

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInput = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local CoreGui = game:GetService("CoreGui")

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
    Blue = Color3.fromRGB(52, 152, 219),
}

-- Cache de funções originais
local OriginalFunctions = {}
pcall(function()
    local tempEvent = Instance.new("RemoteEvent")
    local tempFunc = Instance.new("RemoteFunction")
    OriginalFunctions.FireServer = tempEvent.FireServer
    OriginalFunctions.InvokeServer = tempFunc.InvokeServer
    tempEvent:Destroy()
    tempFunc:Destroy()
end)

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
    
    if self.IsOpen and self.CurrentTab == "Logs" then
        task.spawn(function()
            pcall(function()
                self:RefreshContent()
            end)
        end)
    end
end

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
    
    if self.IsOpen and self.CurrentTab == "Events" then
        task.spawn(function()
            pcall(function()
                self:RefreshContent()
            end)
        end)
    end
end

function Logger:InstallHook()
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
            
            for _, descendant in ipairs(game:GetDescendants()) do
                if descendant:IsA("RemoteEvent") or descendant:IsA("RemoteFunction") then
                    MonitorRemote(descendant)
                end
            end
            
            game.DescendantAdded:Connect(function(descendant)
                if descendant:IsA("RemoteEvent") or descendant:IsA("RemoteFunction") then
                    task.wait(0.1)
                    MonitorRemote(descendant)
                end
            end)
        end)
        
        return true
    end
    
    local hookSuccess = TryHookMethod()
    local monitorSuccess = StartDirectMonitoring()
    
    if hookSuccess or monitorSuccess then
        self.HookActive = true
        self:AddLog("System", "✅ Sistema de captura ativo!")
        if hookSuccess then
            self:AddLog("System", "📌 Hook metamétodo: OK")
        end
        if monitorSuccess then
            self:AddLog("System", "📌 Monitor direto: OK")
        end
        return true
    else
        self:AddLog("System", "❌ Falha na instalação do hook")
        return false
    end
end

function Logger:ExecuteCode(code)
    if self.ExecutorRunning then
        self:AddLog("Executor", "⚠️ Código já está em execução!")
        return
    end
    
    if not code or code == "" then
        self:AddLog("Executor", "❌ Código vazio!")
        return
    end
    
    self.ExecutorRunning = true
    self:AddLog("Executor", "▶️ Executando código...")
    
    self.ExecutorThread = task.spawn(function()
        local success, err = pcall(function()
            local func, loadErr = loadstring(code)
            if not func then
                self:AddLog("Executor", "❌ Erro de sintaxe: " .. tostring(loadErr))
                return
            end
            
            func()
            self:AddLog("Executor", "✅ Código executado com sucesso!")
        end)
        
        if not success then
            self:AddLog("Executor", "❌ Erro: " .. tostring(err))
        end
        
        self.ExecutorRunning = false
        if self.IsOpen and self.CurrentTab == "Executor" then
            task.wait(0.1)
            self:RefreshContent()
        end
    end)
end

function Logger:StopExecution()
    if not self.ExecutorRunning then
        self:AddLog("Executor", "⚠️ Nenhum código em execução!")
        return
    end
    
    if self.ExecutorThread then
        task.cancel(self.ExecutorThread)
        self.ExecutorThread = nil
    end
    
    self.ExecutorRunning = false
    self:AddLog("Executor", "⏹️ Execução interrompida!")
    
    if self.IsOpen and self.CurrentTab == "Executor" then
        self:RefreshContent()
    end
end

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
            
            if i < times then 
                task.wait(math.random(50, 150) / 1000) 
            end
        end
        
        self.Stats.Replayed = self.Stats.Replayed + success
        self:AddLog("System", string.format("✅ Replay %s: %d/%d", event.Name, success, times))
    end)
end

function Logger:ToggleLoop(event)
    if not event or not event.Remote then return false end
    
    event.IsLooping = not event.IsLooping
    
    if event.IsLooping then
        self:AddLog("System", "🔁 Loop iniciado: " .. event.Name)
        
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
                
                task.wait(math.random(400, 600) / 1000)
            end
        end)
    else
        self:AddLog("System", "⏹️ Loop parado: " .. event.Name)
    end
    
    return event.IsLooping
end

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
                        self:AddLog("Character", string.format("🎯 Movimento: %.0f studs", (pos - lastPos).Magnitude))
                    end
                    lastPos = pos
                end
                
                if hum then
                    local hp = hum.Health
                    if lastHp and math.abs(hp - lastHp) > 20 then
                        self:AddLog("Character", string.format("❤️ HP: %.0f → %.0f", lastHp, hp))
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
                    self:AddLog("Input", "⌨️ " .. input.KeyCode.Name)
                end
            end)
        end)
    end)
    
    self:AddLog("System", "✅ Monitores ativos")
end

function Logger:CreateButton(parent, text, color, xPos, yPos, width, height)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, width, 0, height)
    btn.Position = UDim2.new(1, xPos, 0, yPos)
    btn.BackgroundColor3 = color
    btn.Text = text
    btn.TextColor3 = Colors.Text
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 10
    btn.BorderSizePixel = 0
    btn.AutoButtonColor = false
    btn.ZIndex = 1005
    btn.Parent = parent
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 5)
    corner.Parent = btn
    
    btn.MouseEnter:Connect(function()
        local r = math.min(255, color.R * 255 + 25)
        local g = math.min(255, color.G * 255 + 25)
        local b = math.min(255, color.B * 255 + 25)
        btn.BackgroundColor3 = Color3.fromRGB(r, g, b)
    end)
    
    btn.MouseLeave:Connect(function()
        btn.BackgroundColor3 = color
    end)
    
    return btn
end

function Logger:CreateCard(parent, title, height)
    local card = Instance.new("Frame")
    card.Size = UDim2.new(1, 0, 0, height)
    card.BackgroundColor3 = Colors.Card
    card.BorderSizePixel = 0
    card.ZIndex = 1003
    card.Parent = parent
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = card
    
    if title then
        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(1, -15, 0, 28)
        label.Position = UDim2.new(0, 10, 0, 5)
        label.BackgroundTransparency = 1
        label.Text = title
        label.TextColor3 = Colors.Purple
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.Font = Enum.Font.GothamBold
        label.TextSize = 13
        label.ZIndex = 1004
        label.Parent = card
    end
    
    return card
end

function Logger:CreateToggle(parent, name, yPos)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, -20, 0, 35)
    frame.Position = UDim2.new(0, 10, 0, yPos)
    frame.BackgroundColor3 = Color3.fromRGB(40, 40, 48)
    frame.BorderSizePixel = 0
    frame.ZIndex = 1004
    frame.Parent = parent
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = frame
    
    local icons = {Remote = "📡", Character = "🎯", Input = "⌨️"}
    
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -90, 1, 0)
    label.Position = UDim2.new(0, 12, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = (icons[name] or "📊") .. " " .. name
    label.TextColor3 = Colors.Text
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Font = Enum.Font.GothamBold
    label.TextSize = 12
    label.ZIndex = 1005
    label.Parent = frame
    
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 65, 0, 26)
    btn.Position = UDim2.new(1, -72, 0.5, -13)
    btn.BackgroundColor3 = self.Capture[name] and Colors.Success or Colors.Danger
    btn.Text = self.Capture[name] and "ON" or "OFF"
    btn.TextColor3 = Colors.Text
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 11
    btn.BorderSizePixel = 0
    btn.ZIndex = 1005
    btn.AutoButtonColor = false
    btn.Parent = frame
    
    local btnCorner = Instance.new("UICorner")
    btnCorner.CornerRadius = UDim.new(0, 5)
    btnCorner.Parent = btn
    
    btn.MouseButton1Click:Connect(function()
        self.Capture[name] = not self.Capture[name]
        btn.BackgroundColor3 = self.Capture[name] and Colors.Success or Colors.Danger
        btn.Text = self.Capture[name] and "ON" or "OFF"
        self:AddLog("System", name .. ": " .. (self.Capture[name] and "ON" or "OFF"))
    end)
end

function Logger:CreateEventCard(parent, event)
    if not event then return end
    
    local isBlocked = self.Blocked[event.Path]
    
    local card = Instance.new("Frame")
    card.Size = UDim2.new(1, 0, 0, 90)
    card.BackgroundColor3 = Colors.Card
    card.BorderSizePixel = 0
    card.ZIndex = 1003
    card.Parent = parent
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = card
    
    local stroke = Instance.new("UIStroke")
    stroke.Color = isBlocked and Colors.Danger or Colors.Purple
    stroke.Thickness = 2
    stroke.Transparency = 0.5
    stroke.Parent = card
    
    local name = Instance.new("TextLabel")
    name.Size = UDim2.new(1, -270, 0, 20)
    name.Position = UDim2.new(0, 10, 0, 8)
    name.BackgroundTransparency = 1
    name.Text = "📡 " .. event.Name
    name.TextColor3 = Colors.Purple
    name.TextXAlignment = Enum.TextXAlignment.Left
    name.Font = Enum.Font.GothamBold
    name.TextSize = 13
    name.TextTruncate = Enum.TextTruncate.AtEnd
    name.ZIndex = 1004
    name.Parent = card
    
    local path = Instance.new("TextLabel")
    path.Size = UDim2.new(1, -270, 0, 15)
    path.Position = UDim2.new(0, 10, 0, 30)
    path.BackgroundTransparency = 1
    path.Text = event.Path
    path.TextColor3 = Colors.TextDim
    path.TextXAlignment = Enum.TextXAlignment.Left
    path.Font = Enum.Font.Code
    path.TextSize = 9
    path.TextTruncate = Enum.TextTruncate.AtEnd
    path.ZIndex = 1004
    path.Parent = card
    
    local args = Instance.new("TextLabel")
    args.Size = UDim2.new(1, -270, 0, 15)
    args.Position = UDim2.new(0, 10, 0, 48)
    args.BackgroundTransparency = 1
    args.Text = FormatArgs(event.Args)
    args.TextColor3 = Colors.Warning
    args.TextXAlignment = Enum.TextXAlignment.Left
    args.Font = Enum.Font.Code
    args.TextSize = 9
    args.TextTruncate = Enum.TextTruncate.AtEnd
    args.ZIndex = 1004
    args.Parent = card
    
    if isBlocked then
        local blocked = Instance.new("TextLabel")
        blocked.Size = UDim2.new(0, 75, 0, 16)
        blocked.Position = UDim2.new(0, 10, 0, 68)
        blocked.BackgroundColor3 = Colors.Danger
        blocked.Text = "🚫 BLOQUEADO"
        blocked.TextColor3 = Colors.Text
        blocked.Font = Enum.Font.GothamBold
        blocked.TextSize = 8
        blocked.BorderSizePixel = 0
        blocked.ZIndex = 1004
        blocked.Parent = card
        
        local blockedCorner = Instance.new("UICorner")
        blockedCorner.CornerRadius = UDim.new(0, 4)
        blockedCorner.Parent = blocked
    end
    
    local btnX = -260
    
    local btn1 = self:CreateButton(card, "▶️", Colors.Success, btnX, 8, 55, 24)
    btn1.MouseButton1Click:Connect(function()
        self:ReplayEvent(event, 1)
    end)
    
    local btn5 = self:CreateButton(card, "⚡x5", Colors.Purple, btnX + 60, 8, 55, 24)
    btn5.MouseButton1Click:Connect(function()
        self:ReplayEvent(event, 5)
    end)
    
    local btn10 = self:CreateButton(card, "🔥x10", Colors.Warning, btnX + 120, 8, 55, 24)
    btn10.MouseButton1Click:Connect(function()
        self:ReplayEvent(event, 10)
    end)
    
    local btnLoop = self:CreateButton(card, event.IsLooping and "⏹️" or "🔁", 
        event.IsLooping and Colors.Danger or Color3.fromRGB(52, 152, 219), 
        btnX, 36, 55, 24)
    btnLoop.MouseButton1Click:Connect(function()
        local looping = self:ToggleLoop(event)
        btnLoop.Text = looping and "⏹️" or "🔁"
        btnLoop.BackgroundColor3 = looping and Colors.Danger or Color3.fromRGB(52, 152, 219)
    end)
    
    local btnBlock = self:CreateButton(card, isBlocked and "✅" or "🚫", 
        isBlocked and Colors.Success or Colors.Danger, 
        btnX + 60, 36, 55, 24)
    btnBlock.MouseButton1Click:Connect(function()
        self:ToggleBlock(event.Path)
        task.wait(0.1)
        self:RefreshContent()
    end)
    
    local btnCopy = self:CreateButton(card, "📋", Colors.Purple, btnX + 120, 36, 55, 24)
    btnCopy.MouseButton1Click:Connect(function()
        if setclipboard then
            local code = string.format([[
-- Exploit gerado pelo SHAKA LOGGER
local remote = game:GetService("%s")
remote:FireServer(%s)
]], event.Path:match("^(.+)%."), FormatArgs(event.Args))
            setclipboard(code)
            self:AddLog("System", "📋 Código copiado!")
        else
            self:AddLog("System", "❌ setclipboard não disponível")
        end
    end)
    
    local btnDel = self:CreateButton(card, "🗑️", Color3.fromRGB(60, 60, 70), btnX, 64, 180, 20)
    btnDel.MouseButton1Click:Connect(function()
        for i, e in ipairs(self.Events) do
            if e == event then
                table.remove(self.Events, i)
                self.Stats.Captured = #self.Events
                self:AddLog("System", "🗑️ Evento removido")
                self:RefreshContent()
                break
            end
        end
    end)
end

function Logger:CreateLogRow(parent, log)
    local card = Instance.new("Frame")
    card.Size = UDim2.new(1, 0, 0, 28)
    card.BackgroundColor3 = Colors.Card
    card.BorderSizePixel = 0
    card.ZIndex = 1003
    card.Parent = parent
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = card
    
    local time = Instance.new("TextLabel")
    time.Size = UDim2.new(0, 55, 1, 0)
    time.Position = UDim2.new(0, 8, 0, 0)
    time.BackgroundTransparency = 1
    time.Text = log.Time
    time.TextColor3 = Colors.TextDim
    time.TextXAlignment = Enum.TextXAlignment.Left
    time.Font = Enum.Font.Code
    time.TextSize = 10
    time.ZIndex = 1004
    time.Parent = card
    
    local cat = Instance.new("TextLabel")
    cat.Size = UDim2.new(0, 70, 1, 0)
    cat.Position = UDim2.new(0, 68, 0, 0)
    cat.BackgroundTransparency = 1
    cat.Text = "[" .. log.Category .. "]"
    cat.TextColor3 = Colors.Purple
    cat.TextXAlignment = Enum.TextXAlignment.Left
    cat.Font = Enum.Font.GothamBold
    cat.TextSize = 10
    cat.ZIndex = 1004
    cat.Parent = card
    
    local msg = Instance.new("TextLabel")
    msg.Size = UDim2.new(1, -148, 1, 0)
    msg.Position = UDim2.new(0, 143, 0, 0)
    msg.BackgroundTransparency = 1
    msg.Text = log.Message
    msg.TextColor3 = Colors.Text
    msg.TextXAlignment = Enum.TextXAlignment.Left
    msg.Font = Enum.Font.Gotham
    msg.TextSize = 10
    msg.TextTruncate = Enum.TextTruncate.AtEnd
    msg.ZIndex = 1004
    msg.Parent = card
end

function Logger:CreateUI()
    pcall(function()
        local old = CoreGui:FindFirstChild("ShakaLoggerV25")
        if old then old:Destroy() end
    end)
    
    local gui = Instance.new("ScreenGui")
    gui.Name = "ShakaLoggerV25"
    gui.ResetOnSpawn = false
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    
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
    main.ZIndex = 1000
    main.Parent = gui
    
    self.UI.Main = main
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 12)
    corner.Parent = main
    
    local header = Instance.new("Frame")
    header.Size = UDim2.new(1, 0, 0, 50)
    header.BackgroundTransparency = 1
    header.ZIndex = 1001
    header.Parent = main
    
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(0, 350, 0, 24)
    title.Position = UDim2.new(0, 15, 0, 13)
    title.BackgroundTransparency = 1
    title.Text = "⚡ SHAKA LOGGER v2.5 + EXECUTOR"
    title.TextColor3 = Colors.Purple
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Font = Enum.Font.GothamBold
    title.TextSize = 18
    title.ZIndex = 1002
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
    close.ZIndex = 1002
    close.AutoButtonColor = false
    close.Parent = header
    
    local closeCorner = Instance.new("UICorner")
    closeCorner.CornerRadius = UDim.new(0, 6)
    closeCorner.Parent = close
    
    close.MouseButton1Click:Connect(function()
        self:Toggle()
    end)
    
    local tabBar = Instance.new("Frame")
    tabBar.Size = UDim2.new(1, -30, 0, 40)
    tabBar.Position = UDim2.new(0, 15, 0, 55)
    tabBar.BackgroundTransparency = 1
    tabBar.ZIndex = 1001
    tabBar.Parent = main
    
    local tabLayout = Instance.new("UIListLayout")
    tabLayout.FillDirection = Enum.FillDirection.Horizontal
    tabLayout.Padding = UDim.new(0, 8)
    tabLayout.Parent = tabBar
    
    self.UI.TabButtons = {}
    local tabs = {
        {Name = "Settings", Icon = "⚙️"},
        {Name = "Events", Icon = "📡"},
        {Name = "Executor", Icon = "💻"},
        {Name = "Logs", Icon = "📝"}
    }
    
    for _, tab in ipairs(tabs) do
        local btn = Instance.new("TextButton")
        btn.Name = tab.Name
        btn.Size = UDim2.new(0, 180, 1, 0)
        btn.BackgroundColor3 = Colors.Card
        btn.Text = tab.Icon .. " " .. tab.Name
        btn.TextColor3 = Colors.TextDim
        btn.Font = Enum.Font.GothamBold
        btn.TextSize = 13
        btn.BorderSizePixel = 0
        btn.ZIndex = 1002
        btn.AutoButtonColor = false
        btn.Parent = tabBar
        
        local btnCorner = Instance.new("UICorner")
        btnCorner.CornerRadius = UDim.new(0, 8)
        btnCorner.Parent = btn
        
        btn.MouseButton1Click:Connect(function()
            self:SwitchTab(tab.Name)
        end)
        
        self.UI.TabButtons[tab.Name] = btn
    end
    
    local content = Instance.new("Frame")
    content.Size = UDim2.new(1, -30, 1, -110)
    content.Position = UDim2.new(0, 15, 0, 100)
    content.BackgroundTransparency = 1
    content.ZIndex = 1001
    content.Parent = main
    
    self.UI.ContentFrames = {}
    
    for _, tab in ipairs(tabs) do
        local frame = Instance.new("ScrollingFrame")
        frame.Name = tab.Name
        frame.Size = UDim2.new(1, 0, 1, 0)
        frame.BackgroundTransparency = 1
        frame.BorderSizePixel = 0
        frame.ScrollBarThickness = 8
        frame.ScrollBarImageColor3 = Colors.Purple
        frame.Visible = false
        frame.CanvasSize = UDim2.new(0, 0, 0, 0)
        frame.AutomaticCanvasSize = Enum.AutomaticSize.Y
        frame.ZIndex = 1002
        frame.Parent = content
        
        local layout = Instance.new("UIListLayout")
        layout.Padding = UDim.new(0, 10)
        layout.Parent = frame
        
        self.UI.ContentFrames[tab.Name] = frame
    end
    
    self:AddLog("System", "✅ UI criada com sucesso")
end

function Logger:SwitchTab(tabName)
    self.CurrentTab = tabName
    
    for name, btn in pairs(self.UI.TabButtons) do
        if name == tabName then
            btn.BackgroundColor3 = Colors.Purple
            btn.TextColor3 = Colors.Text
        else
            btn.BackgroundColor3 = Colors.Card
            btn.TextColor3 = Colors.TextDim
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
            
            if self.CurrentTab == "Settings" then
                self:BuildSettings(frame)
            elseif self.CurrentTab == "Events" then
                self:BuildEvents(frame)
            elseif self.CurrentTab == "Executor" then
                self:BuildExecutor(frame)
            elseif self.CurrentTab == "Logs" then
                self:BuildLogs(frame)
            end
        end)
    end)
end

function Logger:BuildSettings(parent)
    local card1 = self:CreateCard(parent, "📊 STATUS", 90)
    
    local status = Instance.new("TextLabel")
    status.Size = UDim2.new(1, -20, 0, 50)
    status.Position = UDim2.new(0, 10, 0, 35)
    status.BackgroundTransparency = 1
    status.Text = string.format("Eventos: %d • Bloqueados: %d • Replays: %d",
        self.Stats.Captured, self.Stats.Blocked, self.Stats.Replayed)
    status.TextColor3 = Colors.Text
    status.Font = Enum.Font.GothamBold
    status.TextSize = 13
    status.ZIndex = 1003
    status.Parent = card1
    
    local card2 = self:CreateCard(parent, "🎯 CAPTURA", 170)
    
    local y = 40
    for name, enabled in pairs(self.Capture) do
        self:CreateToggle(card2, name, y)
        y = y + 42
    end
    
    local card3 = self:CreateCard(parent, "🔧 AÇÕES", 110)
    
    local btn1 = self:CreateButton(card3, "🗑️ Limpar Eventos", Colors.Danger, 10, 40, 350, 32)
    btn1.Position = UDim2.new(0, 10, 0, 40)
    btn1.MouseButton1Click:Connect(function()
        self.Events = {}
        self.Stats.Captured = 0
        self:AddLog("System", "🗑️ Eventos limpos")
        self:RefreshContent()
    end)
    
    local btn2 = self:CreateButton(card3, "✅ Desbloquear Todos", Colors.Success, 10, 78, 350, 32)
    btn2.Position = UDim2.new(0, 10, 0, 78)
    btn2.MouseButton1Click:Connect(function()
        self.Blocked = {}
        self.Stats.Blocked = 0
        self:AddLog("System", "✅ Todos desbloqueados")
        self:RefreshContent()
    end)
end

function Logger:BuildExecutor(parent)
    local card = self:CreateCard(parent, "💻 EXECUTOR LUA", 380)
    
    -- Status do executor
    local statusFrame = Instance.new("Frame")
    statusFrame.Size = UDim2.new(1, -20, 0, 30)
    statusFrame.Position = UDim2.new(0, 10, 0, 35)
    statusFrame.BackgroundColor3 = self.ExecutorRunning and Colors.Success or Color3.fromRGB(40, 40, 48)
    statusFrame.BorderSizePixel = 0
    statusFrame.ZIndex = 1004
    statusFrame.Parent = card
    
    local statusCorner = Instance.new("UICorner")
    statusCorner.CornerRadius = UDim.new(0, 6)
    statusCorner.Parent = statusFrame
    
    local statusText = Instance.new("TextLabel")
    statusText.Size = UDim2.new(1, -20, 1, 0)
    statusText.Position = UDim2.new(0, 10, 0, 0)
    statusText.BackgroundTransparency = 1
    statusText.Text = self.ExecutorRunning and "🟢 EXECUTANDO..." or "⚪ AGUARDANDO CÓDIGO"
    statusText.TextColor3 = Colors.Text
    statusText.TextXAlignment = Enum.TextXAlignment.Left
    statusText.Font = Enum.Font.GothamBold
    statusText.TextSize = 11
    statusText.ZIndex = 1005
    statusText.Parent = statusFrame
    
    -- Caixa de texto para código
    local textBoxFrame = Instance.new("Frame")
    textBoxFrame.Size = UDim2.new(1, -20, 0, 240)
    textBoxFrame.Position = UDim2.new(0, 10, 0, 72)
    textBoxFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 32)
    textBoxFrame.BorderSizePixel = 0
    textBoxFrame.ZIndex = 1004
    textBoxFrame.Parent = card
    
    local textBoxCorner = Instance.new("UICorner")
    textBoxCorner.CornerRadius = UDim.new(0, 6)
    textBoxCorner.Parent = textBoxFrame
    
    local textBox = Instance.new("TextBox")
    textBox.Size = UDim2.new(1, -20, 1, -20)
    textBox.Position = UDim2.new(0, 10, 0, 10)
    textBox.BackgroundTransparency = 1
    textBox.Text = self.ExecutorCode
    textBox.PlaceholderText = "-- Cole seu código Lua aqui\n-- Exemplo:\nprint('Hello from SHAKA!')\nwait(1)\nprint('Executor funcionando!')"
    textBox.TextColor3 = Colors.Text
    textBox.PlaceholderColor3 = Colors.TextDim
    textBox.TextXAlignment = Enum.TextXAlignment.Left
    textBox.TextYAlignment = Enum.TextYAlignment.Top
    textBox.Font = Enum.Font.Code
    textBox.TextSize = 12
    textBox.MultiLine = true
    textBox.ClearTextOnFocus = false
    textBox.TextWrapped = true
    textBox.ZIndex = 1005
    textBox.Parent = textBoxFrame
    
    textBox:GetPropertyChangedSignal("Text"):Connect(function()
        self.ExecutorCode = textBox.Text
    end)
    
    -- Botões de controle
    local btnRun = Instance.new("TextButton")
    btnRun.Size = UDim2.new(0, 240, 0, 38)
    btnRun.Position = UDim2.new(0, 10, 0, 320)
    btnRun.BackgroundColor3 = self.ExecutorRunning and Colors.TextDim or Colors.Success
    btnRun.Text = self.ExecutorRunning and "⏳ EXECUTANDO..." or "▶️ EXECUTAR CÓDIGO"
    btnRun.TextColor3 = Colors.Text
    btnRun.Font = Enum.Font.GothamBold
    btnRun.TextSize = 13
    btnRun.BorderSizePixel = 0
    btnRun.ZIndex = 1004
    btnRun.AutoButtonColor = false
    btnRun.Active = not self.ExecutorRunning
    btnRun.Parent = card
    
    local btnRunCorner = Instance.new("UICorner")
    btnRunCorner.CornerRadius = UDim.new(0, 6)
    btnRunCorner.Parent = btnRun
    
    btnRun.MouseButton1Click:Connect(function()
        if not self.ExecutorRunning then
            self:ExecuteCode(self.ExecutorCode)
            task.wait(0.1)
            self:RefreshContent()
        end
    end)
    
    local btnStop = Instance.new("TextButton")
    btnStop.Size = UDim2.new(0, 240, 0, 38)
    btnStop.Position = UDim2.new(0, 260, 0, 320)
    btnStop.BackgroundColor3 = self.ExecutorRunning and Colors.Danger or Colors.TextDim
    btnStop.Text = "⏹️ PARAR EXECUÇÃO"
    btnStop.TextColor3 = Colors.Text
    btnStop.Font = Enum.Font.GothamBold
    btnStop.TextSize = 13
    btnStop.BorderSizePixel = 0
    btnStop.ZIndex = 1004
    btnStop.AutoButtonColor = false
    btnStop.Active = self.ExecutorRunning
    btnStop.Parent = card
    
    local btnStopCorner = Instance.new("UICorner")
    btnStopCorner.CornerRadius = UDim.new(0, 6)
    btnStopCorner.Parent = btnStop
    
    btnStop.MouseButton1Click:Connect(function()
        if self.ExecutorRunning then
            self:StopExecution()
        end
    end)
    
    local btnClear = Instance.new("TextButton")
    btnClear.Size = UDim2.new(0, 240, 0, 38)
    btnClear.Position = UDim2.new(0, 510, 0, 320)
    btnClear.BackgroundColor3 = Colors.Warning
    btnClear.Text = "🗑️ LIMPAR CÓDIGO"
    btnClear.TextColor3 = Colors.Text
    btnClear.Font = Enum.Font.GothamBold
    btnClear.TextSize = 13
    btnClear.BorderSizePixel = 0
    btnClear.ZIndex = 1004
    btnClear.AutoButtonColor = false
    btnClear.Parent = card
    
    local btnClearCorner = Instance.new("UICorner")
    btnClearCorner.CornerRadius = UDim.new(0, 6)
    btnClearCorner.Parent = btnClear
    
    btnClear.MouseButton1Click:Connect(function()
        self.ExecutorCode = ""
        textBox.Text = ""
        self:AddLog("Executor", "🗑️ Código limpo")
    end)
    
    -- Scripts de exemplo
    local examplesCard = self:CreateCard(parent, "📚 EXEMPLOS RÁPIDOS", 140)
    
    local examples = {
        {name = "🎯 Teleporte", code = [[-- Teleportar para coordenadas
local hrp = game.Players.LocalPlayer.Character.HumanoidRootPart
hrp.CFrame = CFrame.new(0, 50, 0)
print("Teleportado!")]]},
        {name = "🏃 Speed", code = [[-- Aumentar velocidade
local hum = game.Players.LocalPlayer.Character.Humanoid
hum.WalkSpeed = 100
print("Speed aumentado!")]]},
        {name = "🔁 Loop", code = [[-- Loop infinito
while task.wait(1) do
    print("Loop executando...")
end]]}
    }
    
    local yPos = 40
    for i, ex in ipairs(examples) do
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(0, 240, 0, 28)
        btn.Position = UDim2.new(0, 10 + ((i-1) * 250), 0, yPos)
        btn.BackgroundColor3 = Colors.Blue
        btn.Text = ex.name
        btn.TextColor3 = Colors.Text
        btn.Font = Enum.Font.GothamBold
        btn.TextSize = 11
        btn.BorderSizePixel = 0
        btn.ZIndex = 1004
        btn.AutoButtonColor = false
        btn.Parent = examplesCard
        
        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 5)
        corner.Parent = btn
        
        btn.MouseButton1Click:Connect(function()
            self.ExecutorCode = ex.code
            self:AddLog("Executor", "📋 Exemplo carregado: " .. ex.name)
            self:RefreshContent()
        end)
    end
    
    local info = Instance.new("TextLabel")
    info.Size = UDim2.new(1, -20, 0, 50)
    info.Position = UDim2.new(0, 10, 0, 75)
    info.BackgroundTransparency = 1
    info.Text = "💡 Dica: Clique nos exemplos acima para carregar código pronto!\nVocê pode editar e executar qualquer código Lua."
    info.TextColor3 = Colors.TextDim
    info.Font = Enum.Font.Gotham
    info.TextSize = 10
    info.TextWrapped = true
    info.TextXAlignment = Enum.TextXAlignment.Left
    info.ZIndex = 1004
    info.Parent = examplesCard
end

function Logger:BuildEvents(parent)
    if #self.Events == 0 then
        local empty = self:CreateCard(parent, "⚠️ Nenhum Evento Capturado", 80)
        
        local msg = Instance.new("TextLabel")
        msg.Size = UDim2.new(1, -20, 0, 40)
        msg.Position = UDim2.new(0, 10, 0, 35)
        msg.BackgroundTransparency = 1
        msg.Text = self.Capture.Remote and "Interaja com o jogo para capturar eventos..." or "Ative 'Remote' em Settings primeiro!"
        msg.TextColor3 = Colors.TextDim
        msg.Font = Enum.Font.Gotham
        msg.TextSize = 12
        msg.TextWrapped = true
        msg.ZIndex = 1003
        msg.Parent = empty
        return
    end
    
    for i, event in ipairs(self.Events) do
        if i > 15 then break end
        pcall(function()
            self:CreateEventCard(parent, event)
        end)
    end
end

function Logger:BuildLogs(parent)
    if #self.Logs == 0 then
        local empty = self:CreateCard(parent, "📭 Sem Logs", 60)
        
        local msg = Instance.new("TextLabel")
        msg.Size = UDim2.new(1, -20, 0, 25)
        msg.Position = UDim2.new(0, 10, 0, 30)
        msg.BackgroundTransparency = 1
        msg.Text = "Nenhum log registrado ainda"
        msg.TextColor3 = Colors.TextDim
        msg.Font = Enum.Font.Gotham
        msg.TextSize = 11
        msg.ZIndex = 1003
        msg.Parent = empty
        return
    end
    
    for i, log in ipairs(self.Logs) do
        if i > 20 then break end
        pcall(function()
            self:CreateLogRow(parent, log)
        end)
    end
end

function Logger:Toggle()
    self.IsOpen = not self.IsOpen
    
    if not self.UI.Main then return end
    
    pcall(function()
        if self.IsOpen then
            self.UI.Main.Visible = true
            self.UI.Main.Size = UDim2.new(0, 0, 0, 0)
            
            TweenService:Create(self.UI.Main, 
                TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
                {Size = UDim2.new(0, 800, 0, 550)}):Play()
            
            task.wait(0.15)
            self:RefreshContent()
        else
            TweenService:Create(self.UI.Main, 
                TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.In),
                {Size = UDim2.new(0, 0, 0, 0)}):Play()
            
            task.wait(0.2)
            self.UI.Main.Visible = false
        end
    end)
end

function Logger:SetupKeybind()
    UserInput.InputBegan:Connect(function(input, processed)
        if not processed and input.KeyCode == OPEN_KEY then
            pcall(function()
                self:Toggle()
            end)
        end
    end)
end

function Logger:Init()
    SafePrint("\n" .. string.rep("═", 70))
    SafePrint("⚡ SHAKA LOGGER v2.5 - COM EXECUTOR LUA")
    SafePrint("   UI Completa • Executor Integrado • Sistema de Exploits")
    SafePrint(string.rep("═", 70))
    
    SafePrint("\n🔍 Verificando executor...")
    local features = {
        hookmetamethod = hookmetamethod ~= nil,
        getnamecallmethod = getnamecallmethod ~= nil,
        newcclosure = newcclosure ~= nil,
        setclipboard = setclipboard ~= nil,
        loadstring = loadstring ~= nil
    }
    
    for name, supported in pairs(features) do
        SafePrint((supported and "✅" or "❌") .. " " .. name)
    end
    
    task.wait(0.3)
    pcall(function()
        self:CreateUI()
    end)
    
    task.wait(0.2)
    pcall(function()
        self:SetupKeybind()
    end)
    
    task.wait(0.5)
    pcall(function()
        self:InstallHook()
    end)
    
    task.wait(0.3)
    pcall(function()
        self:StartMonitoring()
    end)
    
    task.wait(1)
    pcall(function()
        self:Toggle()
        task.wait(0.2)
        self:SwitchTab("Settings")
    end)
    
    SafePrint("\n✅ SHAKA LOGGER PRONTO!")
    SafePrint("⌨️ Pressione [F] para abrir/fechar")
    SafePrint("💻 Nova aba EXECUTOR para rodar código Lua!")
    SafePrint("📋 Use o botão 📋 para copiar exploits prontos!")
    SafePrint(string.rep("═", 70) .. "\n")
end

task.spawn(function()
    task.wait(2)
    pcall(function()
        Logger:Init()
    end)
end)

pcall(function()
    getgenv().ShakaLogger = Logger
    _G.ShakaLogger = Logger
end)

return Logger
