local Environment = getgenv()
local Modules = { List = {} }
local UIS = game:GetService'UserInputService'
local RunService = game:GetService'RunService'
local TeleportService = game:GetService'TeleportService'
local RenderStepped = RunService.RenderStepped
local Print = Environment.OriginalPrint or print
local Players = game:GetService'Players'
local LocalPlayer while not LocalPlayer do task.wait(0.25) LocalPlayer = Players.LocalPlayer end
local PlayerMouse = LocalPlayer:GetMouse()
local InputTypes = { Ended = 0, Began = 1, Repeated = 2 }

Environment.Icey = script
Environment.OriginalPrint = Environment.OriginalPrint or Print
Environment.print = newcclosure(function(...)
    if Environment.RedirectPrints and checkcaller() then
        return (cprint or function(...) local Arguments = {...} for i, v in ipairs(Arguments) do Arguments[i] = tostring(v) end return rconsoleinfo(table.concat(Arguments, ' ')) end)(...)
    end

    return Environment.OriginalPrint(...)
end)
Environment.cfprint = function(Value)
    local X, Y, Z = Value:ToEulerAnglesXYZ()

    return cprint(string.format('CFrame.new(%0.3f, %0.3f, %0.3f) * CFrame.Angles(math.rad(%0.2f), math.rad(%0.2f), math.rad(%0.2f))', Value.X, Value.Y, Value.Z, math.deg(X), math.deg(Y), math.deg(Z)))
end

local function IsEmpty(String)
    if typeof(String) == 'string' then
        return String:match'^%s+$' ~= nil or #String == 0 or String == ''
    end
    
    return true
end

local function QuickClone(Table) return { unpack(Table) } end
local function StringToTable(String) local Characters = {} for Index = 1, #String do table.insert(Characters, String:sub(Index, Index)) end return Characters end
local function CombineTable(Table, StartIndex, EndIndex) StartIndex = StartIndex or 1 EndIndex = EndIndex and StartIndex + EndIndex or StartIndex local Combined = {} for Index = StartIndex or 1, math.clamp(EndIndex, StartIndex, #Table) do table.insert(Combined, Table[Index]) end return Combined end

function Modules:Add(Name, FTable)
    if FTable.Initialize then FTable:Initialize(Environment) end

    if FTable.Definitions then table.foreach(FTable.Definitions, function(Index, Value) Environment[Index] = Value end) end

    Environment[Name] = FTable
end

local Input = { Keybinds = {}, KeywordBinds = {}, RecentKeys = {}, Down = setmetatable({}, {
    __index = function(self, Key)
        if typeof(Key) == 'EnumItem' then Key = Key.Name end

        assert(typeof(Key) == 'string', 'string expected on Input.Down got ' .. typeof(Key))
        
        Key = Key:lower()

        if (Key:sub(1, 1) == 'm' or Key:sub(1, 5) == 'mouse') and Key:len() > 1 and Key:find'%d+' then return UIS:IsMouseButtonPressed(tonumber(Key:sub(Key:find'%d+')) - 1) end
        
        return rawget(self, Key:lower()) or false
    end
}) }

function Input:Initialize()
    Input.down = setmetatable({}, { __index = self.Down })
    Environment.input = Input

    self.Definitions = { -- Old script support
        bind = function(...) return self:Bind(...) end,
        bind_first = function(...) return self:BindFirst(...) end,
        unbind = function(...) return self:Unbind(...) end
    }

    local function HandleInput(Input, Process, Type, IgnoreProcessed)
        if script ~= Environment.Icey or (Process and UIS:GetFocusedTextBox() and not IgnoreProcessed) or Input.KeyCode.Name == 'Unknown' then return end

        self.Down[Input.KeyCode.Name:lower()] = Type >= 1

        if Input.UserInputType == Enum.UserInputType.Keyboard then
            if Type == InputTypes.Began then
                table.insert(self.RecentKeys, { Key = Input.KeyCode.Name:lower(), Time = tick() })

                if #self.RecentKeys > 64 then
                    for Index, Data in pairs(QuickClone(self.RecentKeys)) do
                        if tick() - Data.Time > 3 then table.remove(self.RecentKeys, Index) continue end
                    end
                end
            elseif Type == InputTypes.Ended then
                if Input.KeyCode.Name == 'Return' then
                    local Keys = {}

                    for Index, Data in pairs(QuickClone(self.RecentKeys)) do
                        if tick() - Data.Time > 3 then table.remove(self.RecentKeys, Index) continue end

                        table.insert(Keys, Data.Key)
                    end

                    for Index, Key in pairs(Keys) do
                        for Keyword, Function in pairs(self.KeywordBinds) do
                            local Characters = StringToTable(Keyword)

                            if Key == Characters[1] and Keys[Index + #Characters - 1] == Characters[#Characters] and Keys[Index + #Characters] == 'return' and table.concat(CombineTable(Keys, Index, #Characters - 1)) == Keyword then
                                local Success, Error = pcall(Function)

                                table.clear(self.RecentKeys)

                                if not Success then
                                    print(string.format('KeyBind %s encountered an error: %s', Input.KeyCode.Name, Error))
                                end

                                break
                            end
                        end
                    end
                elseif Input.KeyCode.Name == 'Escape' then
                    self.RecentKeys = {}
                end
            end

            local Data = self.Keybinds[Input.KeyCode]

            if Data then
                if Data.Type == Type and not UIS:GetFocusedTextBox() then
                    local Success, Error = pcall(Data.Function)

                    if not Success then
                        print(string.format('KeyBind %s encountered an error: %s', Input.KeyCode.Name, Error))
                    end
                elseif Data.Type == InputTypes.Repeated then
                    local DT = Data.Delay or 0

                    while self.Down[Input.KeyCode] do
                        local Success, Error = pcall(Data.Function, DT)
                        
                        if not Success then
                            print(string.format('KeyBind %s encountered an error: %s', Input.KeyCode.Name, Error))
                            break
                        end

                        DT = task.wait(Data.Delay)
                    end
                end
            end
        end
    end

    UIS.InputBegan:Connect(function(Input, Process) HandleInput(Input, Process, 1) end)
    UIS.InputEnded:Connect(function(Input, Process) HandleInput(Input, Process, 0, true) end)
end

function Input:GetKeyCode(Key)
    if typeof(Key) ~= 'string' then return Enum.KeyCode.Unknown end
    
    for Index, Code in pairs(Enum.KeyCode:GetEnumItems()) do
        if Code.Name:lower() == Key:lower() then
            return Code
        end
    end
end

function Input:Bind(Key, Function)
    local KeyCode = typeof(Key) == 'EnumItem' and Key or self:GetKeyCode(Key)
    
    assert(KeyCode ~= nil, 'Expected KeyCode or string in argument #1 got ' .. typeof(Key))
    assert(KeyCode ~= Enum.KeyCode.Unknown, 'Expected KeyCode or string in argument #1 got ' .. typeof(Key))
    
    self.Keybinds[KeyCode] = {
        Type = InputTypes.Ended,
        Function = Function
    }
end

function Input:BindFirst(Key, Function)
    local KeyCode = typeof(Key) == 'EnumItem' and Key or self:GetKeyCode(Key)
    
    assert(KeyCode ~= Enum.KeyCode.Unknown, 'Expected KeyCode or string in argument #1 got ' .. typeof(Key))
    
    self.Keybinds[KeyCode] = {
        Type = InputTypes.Began,
        Function = Function
    }
end

function Input:WhilePressed(Key, Function, Delay)
    local KeyCode = typeof(Key) == 'EnumItem' and Key or self:GetKeyCode(Key)
    
    assert(KeyCode ~= Enum.KeyCode.Unknown, 'Expected KeyCode or string in argument #1 got ' .. typeof(Key))
    
    self.Keybinds[KeyCode] = {
        Type = InputTypes.Repeated,
        Function = Function,
        Delay = typeof(Delay) == 'number' and Delay or 0.0
    }
end

function Input:KeywordBind(Command, Function)
    assert(typeof(Command) == 'string', 'Expected string in argument #1 got ' .. typeof(Command))

    self.KeywordBinds[Command:lower()] = Function
end

function Input:Unbind(Key)
    local KeyCode = typeof(self) == 'EnumItem' or self:GetKeyCode(Key)

    assert(KeyCode ~= nil, 'Expected KeyCode or string in argument #1 got ' .. typeof(Key))
    assert(KeyCode ~= Enum.KeyCode.Unknown, 'Expected KeyCode or string in argument #1 got ' .. typeof(Key))

    self.Keybinds[KeyCode] = nil
end

local Miscellaneous = {}

function Miscellaneous:Initialize()
    local function cprint(...)
        local Lines = { {} }
        local Arguments = {...}
    
        for Index, Value in pairs(Arguments) do
            local LN = #Lines
            local CurrentLine = Lines[LN] or {}
            local String = tostring(Value) if IsEmpty(String) then continue end
            local NewLine = String:find'\n'
    
            if NewLine then
                local Leftover = String:sub(NewLine + 1)
                String = String:sub(1, NewLine - 1)
    
                table.insert(CurrentLine, String)
                table.insert(Arguments, Index + 1, Leftover)
    
                Lines[LN] = CurrentLine
                Lines[LN + 1] = { }
    
                continue
            end
            
            table.insert(CurrentLine, String)
            
            Lines[LN] = CurrentLine
        end
    
        local OSTime = os.time()
        local Time = os.date('*t', OSTime) Time = string.format('%02d:%02d:%02d', Time.hour % 12, Time.min, Time.sec)
    
        for i, v in pairs(Lines) do
            Lines[i] = table.concat(Lines[i], ' ')
        end
    
        rconsoleprint(string.format('[%s] %s\n', Time, table.concat(Lines, '\n' .. (' '):rep(11))))
    end

    local LocalDefinitions = {}
    local LocalShortcuts = {
        ['Player,player,LocalPlayer,localplayer,p'] = LocalPlayer,
        ['Mouse,mouse,m'] = PlayerMouse,
        ['Character,character,Char,char,c'] = function() return LocalPlayer.Character end
    }

    for Index, Value in pairs(LocalShortcuts) do
        for Definition in Index:gmatch'[^,]+' do
            LocalDefinitions[Definition] = Value
        end
    end

    local Locals = setmetatable({}, { __index = function(self, Index)
        local V = rawget(LocalDefinitions, Index)

        return (typeof(V) == 'function' and V() or V) or rawget(self, Index)
    end })

    self.Definitions = { beep = self.Beep, Beep = self.Beep, bench = self.Benchmark, benchmark = self.Benchmark, Benchmark = self.Benchmark, rejoin = self.Rejoin, Rejoin = self.Rejoin, cprint = cprint, Locals = Locals, locals = Locals }
end

local Beep_On = 'rbxassetid://138081500'
local Beep_Off = 'rbxassetid://917942453'

function Miscellaneous.Benchmark(Name, Function)
    if typeof(Name) == 'function' then Function = Name end
    if typeof(Function) ~= 'function' then return end

    local Name = typeof(Name) == 'string' and Name or 'Task'
    local Start = os.clock()

    Function()

    local End = os.clock()

    return ('Task `%s` took %0.20f seconds to complete'):format(Name, End - Start)
end

function Miscellaneous.Beep(Bool, Volume, Pitch)
    local SoundID = Bool and Beep_On or Beep_Off
    local SoundName = Bool and 'BeepOn' or 'BeepOff'
    
    local SoundService = game:GetService'SoundService'
    local Sound = SoundService:FindFirstChild(SoundName) or Instance.new('Sound', game.SoundService)
    Sound.Name = SoundName
    Sound.SoundId = SoundID
    Sound.Pitch = typeof(Pitch) == 'number' and Pitch or 1
    Sound.Volume = typeof(Volume) == 'number' and Volume or 0.75
    Sound.Looped = false
    Sound:Play()
end

function Miscellaneous:Rejoin()
    TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId)
end

function Miscellaneous:Disconnect(Shutdown)
    if LocalPlayer.Character then LocalPlayer.Character:Destroy() end

    LocalPlayer:Kick'Disconnected'

    if Shutdown then game:Shutdown() end
end

local OrigSetClipboard = setclipboard

getgenv().setclipboard = function(...) -- Automatically convert multiple setclipboard arguments to strings
    local Strings = {}

    for Index, Value in pairs {...} do
        table.insert(Strings, tostring(Value))
    end

    return OrigSetClipboard(table.concat(Strings, ' '))
end

Modules:Add('Input', Input)
Modules:Add('Misc', Miscellaneous)

Input:KeywordBind('rejoin', Miscellaneous.Rejoin)
Input:KeywordBind('die', function() Locals.Character:BreakJoints() end)
Input:KeywordBind('delete', function() Locals.Character:Destroy() end)
Input:KeywordBind('disc', Misc.Disconnect)
Input:KeywordBind('disconnect', Misc.Disconnect)
Input:KeywordBind('shutdown', function() Misc:Disconnect(true) end)

Input:KeywordBind('esp', function()
    loadstring(game:HttpGet'https://raw.githubusercontent.com/ic3w0lf22/Unnamed-ESP/master/UnnamedESP.lua')()
end)
