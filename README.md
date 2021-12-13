# Input
## <boolean> Input.Down.<string Key>
### Example
```lua
print(Input.Down.F, Input.Down.LeftControl, input.down.leftcontrol)
```
Return: true or false if a key is down, see https://developer.roblox.com/en-us/api-reference/enum/KeyCode for KeyCode list

## <void> Input:Bind(<string, KeyCode> Key, <function> Function)
Executes on key release
### Example
```lua
Input:Bind('V', function()
    print(Input.Down.LeftControl and 'Control + V Pressed/Up' or 'V Pressed/Up')
end)
```

## <void> Input:BindFirst(<string, KeyCode> Key, <function> Function)
Executes on key down
### Example
```lua
Input:Bind('V', function()
    print(Input.Down.LeftControl and 'Control + V Down' or 'V Down')
end)
```

## <void> Input:WhilePressed(<string, KeyCode> Key, <function> Function, <number> Delay)
Executes while key is pressed
### Example
```lua
Input:WhilePressed('V', function(DT)
    print('V is being held. Time since last execute: ' .. DT)
end, 1)
```

## <void> Input:KeywordBind(<string> Command, <function> Function)
Executes once a set of specific keys is pressed
### Example
```lua
Input:KeywordBind('rejoin', function()
    game:GetService'TeleportService':TeleportToPlaceInstance(game.PlaceId, game.JobId)
end)
```

## <void> Input:Unbind(<string, KeyCode> Key)
Unbinds a keybind, doesn't work for KeywordBinds
### Example
```lua
Input:Unbind('V')
```


# Miscellaneous
## All these functions are put into the global environment, meaning they can be called without 'Miscellaneous.' before them

## <string> Benchmark(<string> Name, <function> Function)
Return: However long a function took to complete in seconds up to 20 decimal points
### Example
```lua
print(Benchmark('Test', function()
    for Index = 1, 10000 do
        workspace:GetDescendants()
    end
end))
````
-> Task `Test` took 0.45830060000025696354 seconds to complete

## <void> Beep(<boolean> Bool, [optional] <number> Volume = 0.75, [optional] <number> Pitch = 1)
### Example
```lua
Beep(1)
task.delay(1, Beep) -- No parameters or false will play a slow beep indicating something is turned off
Input:Bind('V', Beep)
```

## <void> Rejoin(<void>)
Rejoins the specific server you are in
### Example
```lua
Rejoin()
```

## <void> Disconnect([optional] <boolean> Shutdown = false)
Kicks you from your current server, closes roblox if Shutdown is true
### Example
```lua
Disconnect(true)
```

## <string> setclipboard(<string> ...)
This autoexec script overwrites the existing setclipboard to support mulitple parameters and automatically tostrings the provided parameters
### Example
```lua
setclipboard(workspace, 'joe')
```
Result: Workspace joe

## <void> cprint(<variant> ...)
Prints provided parameters to console with timestamps using rconsoleprint
### Example 
```lua
cprint('joe', workspace, 1, true, Locals.Character)
```
Result: [08:31:35] joe Workspace 1 true Player
Note: Set getgenv().RedirectPrints to true to redirect all normal print calls to cprint

## <void> cfprint(<CFrame> CFrame)
Prints a CFrame into console using cprint in script format allowing for quick copy pasting of positions
### Example
```lua
cfprint(CFrame.new(19.6, 73.4, 103.9, 0.7, 0, 0.6, 0, 1, 0, 0.65, 0, 0.7))
```
Result:
```lua
CFrame.new(19.600, 73.400, 103.900) * CFrame.Angles(math.rad(-0.00), math.rad(36.87), math.rad(-0.00))
```
