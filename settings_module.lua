local Mouse = game:GetService("Players").LocalPlayer:GetMouse()
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local TextService = game:GetService("TextService")
local UIS = game:GetService("UserInputService")

local function Enum2JSON(enum)
    return HttpService:JSONEncode({
        EnumType = tostring(enum.EnumType),
        Name = enum.Name        
    })
end

local function JSON2Enum(json)
    local tbl = HttpService:JSONDecode(json)
    return (tbl.EnumType and tbl.Name) and Enum[tbl.EnumType][tbl.Name] or false
end

local function EmptyString(length)
    local str = ""
    for i=1,length do
        str = str.." "
    end
    return str
end

local function newNumbOption(name, number, tooltip, gui)
    local Main = Instance.new("Frame")
    local NameLabel = Instance.new("TextLabel")
    local TextButton = Instance.new("TextButton")
    local TextBox = Instance.new("TextBox")

    Main.Name = "Main"
    Main.BackgroundTransparency = 1
    Main.Size = UDim2.new(1, 0, 0, 30)

    NameLabel.Name = "NameLabel"
    NameLabel.Parent = Main
    NameLabel.BackgroundTransparency = 1
    NameLabel.Size = UDim2.fromScale(1,1)
    NameLabel.Text = name..": "
    NameLabel.Font = "Code"
    NameLabel.TextSize = 18
    NameLabel.TextColor3 = Color3.new(1,1,1)
    NameLabel.TextStrokeColor3 = NameLabel.TextColor3:lerp(Color3.new(), .67) 
    NameLabel.TextStrokeTransparency = 0.25
    NameLabel.TextXAlignment = Enum.TextXAlignment.Left

    local Empty = EmptyString(#NameLabel.Text)

    TextButton.Parent = NameLabel
    TextButton.BackgroundTransparency = 1
    TextButton.Size = UDim2.fromScale(1,1)
    TextButton.Text = Empty..tostring(number.Value)
    TextButton.Font = "Code"
    TextButton.TextSize = 18
    TextButton.TextColor3 = Color3.fromRGB(209, 154, 102)
    TextButton.TextStrokeColor3 = TextButton.TextColor3:lerp(Color3.new(), .67)
    TextButton.TextStrokeTransparency = 0.25
    TextButton.TextXAlignment = Enum.TextXAlignment.Left

    TextBox.Parent = NameLabel
    TextBox.Visible = false
    TextBox.BackgroundTransparency = 1
    TextBox.AnchorPoint = Vector2.new(1,0)
    TextBox.Size = UDim2.new(1, -TextService:GetTextSize(NameLabel.Text, NameLabel.TextSize, NameLabel.Font, NameLabel.AbsoluteSize).X, 1, 0)
    TextBox.Position = UDim2.fromScale(1,0)
    TextBox.Text = ""
    TextBox.Font = "Code"
    TextBox.TextSize = 18
    TextBox.TextColor3 = Color3.fromRGB(209, 154, 102)
    TextBox.TextStrokeColor3 = TextButton.TextColor3:lerp(Color3.new(), .67)
    TextBox.TextStrokeTransparency = 0.25
    TextBox.TextXAlignment = Enum.TextXAlignment.Left

    local lastPressTick
    local shortPressLength = 200

    TextButton.MouseButton1Down:Connect(function()
        lastPressTick = tick()*1000
        oldNumber = number.Value
        local lastMousePos = Vector2.new(Mouse.X, Mouse.Y)
        while UIS:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) do
            local delta = Vector2.new(Mouse.X, Mouse.Y) - lastMousePos
            number.Value = math.max(0, math.floor(oldNumber+delta.X/5))
            TextButton.Text = Empty..tostring(number.Value)
            RunService.RenderStepped:wait()
        end
    end)

    if tooltip then
        TextButton.MouseEnter:Connect(function()
            if not UIS:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) then
                RunService.RenderStepped:wait()
                gui.Tooltip(tooltip)
            end
        end)

        TextButton.MouseLeave:Connect(function()
            gui.Tooltip(false)
        end)
    end

    TextButton.MouseButton1Up:Connect(function()
        gui.Tooltip(false)
        if lastPressTick and tick()*1000 - lastPressTick <= shortPressLength then
            TextButton.Visible = false
            TextBox.Visible = true

            local focusLost
            focusLost = TextBox.FocusLost:Connect(function(enterPressed)
                if enterPressed and tonumber(TextBox.Text) then
                    number.Value = math.abs(tonumber(TextBox.Text))
                    TextButton.Text = Empty..tostring(number.Value)
                end

                TextBox.Visible = false
                TextButton.Visible = true
                focusLost:Disconnect()
            end)

            TextBox:CaptureFocus()
        end
    end)

    return Main
end

local function newBoolOption(name, bool, tooltip, gui)
    local Main = Instance.new("Frame")
    local NameLabel = Instance.new("TextLabel")
    local TextButton = Instance.new("TextButton")

    Main.Name = "Main"
    Main.BackgroundTransparency = 1
    Main.Size = UDim2.new(1, 0, 0, 30)

    NameLabel.Name = "NameLabel"
    NameLabel.Parent = Main
    NameLabel.BackgroundTransparency = 1
    NameLabel.Size = UDim2.fromScale(1,1)
    NameLabel.Text = name..": "
    NameLabel.Font = "Code"
    NameLabel.TextSize = 18
    NameLabel.TextColor3 = Color3.new(1,1,1)
    NameLabel.TextStrokeColor3 = NameLabel.TextColor3:lerp(Color3.new(), .67) 
    NameLabel.TextStrokeTransparency = 0.25
    NameLabel.TextXAlignment = Enum.TextXAlignment.Left

    local Empty = EmptyString(#NameLabel.Text)

    TextButton.Parent = NameLabel
    TextButton.BackgroundTransparency = 1
    TextButton.Size = UDim2.fromScale(1,1)
    TextButton.Text = Empty..tostring(bool.Value)
    TextButton.Font = "Code"
    TextButton.TextSize = 18
    TextButton.TextColor3 = Color3.fromRGB(86, 182, 194)
    TextButton.TextStrokeColor3 = TextButton.TextColor3:lerp(Color3.new(), .67)
    TextButton.TextStrokeTransparency = 0.25
    TextButton.TextXAlignment = Enum.TextXAlignment.Left

    if tooltip then
        TextButton.MouseEnter:Connect(function()
            RunService.RenderStepped:wait()
            gui.Tooltip(tooltip)
        end)

        TextButton.MouseLeave:Connect(function()
            gui.Tooltip(false)
        end)
    end

    TextButton.MouseButton1Click:Connect(function()
        if tooltip then gui.Tooltip(false) end
        bool.Value = not bool.Value
        TextButton.Text = Empty..tostring(bool.Value)
    end)

    return Main
end

local function newEnumOption(name, enum, tooltip, gui)
    local acceptedEnumTypes = {"KeyCode", "UserInputType"}
    local enumTbl = HttpService:JSONDecode(enum.Value)
    assert(table.find(acceptedEnumTypes, tostring(enumTbl.EnumType)), "Unsupported enum-type: "..tostring(enumTbl.EnumType)..", the only supported types are KeyCodes and UserInputTypes (aka Key Enums).")

    local Main = Instance.new("Frame")
    local NameLabel = Instance.new("TextLabel")
    local TextButton = Instance.new("TextButton")

    Main.Name = "Main"
    Main.BackgroundTransparency = 1
    Main.Size = UDim2.new(1, 0, 0, 30)

    NameLabel.Name = "NameLabel"
    NameLabel.Parent = Main
    NameLabel.BackgroundTransparency = 1
    NameLabel.Size = UDim2.fromScale(1,1)
    NameLabel.Text = name..": "
    NameLabel.Font = "Code"
    NameLabel.TextSize = 18
    NameLabel.TextColor3 = Color3.new(1,1,1)
    NameLabel.TextStrokeColor3 = NameLabel.TextColor3:lerp(Color3.new(), .67) 
    NameLabel.TextStrokeTransparency = 0.25
    NameLabel.TextXAlignment = Enum.TextXAlignment.Left

    local Empty = EmptyString(#NameLabel.Text)

    TextButton.Parent = NameLabel
    TextButton.BackgroundTransparency = 1
    TextButton.Size = UDim2.fromScale(1,1)
    TextButton.Text = Empty..enumTbl.Name
    TextButton.Font = "Code"
    TextButton.TextSize = 18
    TextButton.TextColor3 = Color3.fromRGB(224, 108, 117)
    TextButton.TextStrokeColor3 = TextButton.TextColor3:lerp(Color3.new(), .67)
    TextButton.TextStrokeTransparency = 0.25
    TextButton.TextXAlignment = Enum.TextXAlignment.Left

    local acceptedInputTypes = {1, 2, 8, 12}

    if tooltip then
        TextButton.MouseEnter:Connect(function()
            if not UIS:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) then
                RunService.RenderStepped:wait()
                gui.Tooltip(tooltip)
            end
        end)

        TextButton.MouseLeave:Connect(function()
            gui.Tooltip(false)
        end)
    end

    TextButton.MouseButton1Click:Connect(function()
        gui.Tooltip (false)
        TextButton.Text = ""
        
        local InputComplete = false
        local WaitForInput 
        WaitForInput = UIS.InputBegan:Connect(function(key)
            if key.KeyCode == Enum.KeyCode.Escape then
                TextButton.Text = Empty..enumTbl.Name
                InputComplete = true
                WaitForInput:Disconnect()
            elseif table.find(acceptedInputTypes, key.UserInputType.Value) then
                enum.Value = Enum2JSON((key.UserInputType.Value == 8 or key.UserInputType.Value == 12) and key.KeyCode or key.UserInputType)
                enumTbl = HttpService:JSONDecode(enum.Value)
                TextButton.Text = Empty..((key.UserInputType.Value == 8 or key.UserInputType.Value == 12) and key.KeyCode or key.UserInputType).Name
                InputComplete = true
                WaitForInput:Disconnect()
            end
        end)

        while not InputComplete do
            TextButton.Text = TextButton.Text == "" and Empty.."_" or ""
            wait(.5)
        end
    end)

    return Main
end

local function newColumn(parent)
    local Column = Instance.new("Frame")
    local UIListLayout = Instance.new("UIListLayout")

    Column.Name = "Column"
    Column.Parent = parent
    Column.BackgroundTransparency = 1
    Column.Size = UDim2.new(0,180,1,0)
    
    UIListLayout.Parent = Column
    UIListLayout.FillDirection = Enum.FillDirection.Vertical
    UIListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    UIListLayout.VerticalAlignment = Enum.VerticalAlignment.Top


    local function resize()
        local max_length = 0
        for _,v in next, Column:GetChildren() do
            if v:IsA("Frame") then
                local textButton = v.NameLabel:FindFirstChildOfClass("TextButton")
                local textBounds = TextService:GetTextSize(textButton.Text:gsub("%s", "-"), textButton.TextSize, textButton.Font, Vector2.new(math.huge,math.huge))
                max_length = math.max(max_length, textBounds.X)
            end
        end

        Column.Size = UDim2.new(0, max_length, 1, 0)
        UIListLayout:ApplyLayout()
    end

    Column.ChildAdded:Connect(function(child)
        resize()
        if child:IsA("Frame") then
            child.NameLabel:FindFirstChildOfClass("TextButton"):GetPropertyChangedSignal("TextBounds"):Connect(resize)
        end
    end)

    return Column
end

return {
    new = function(binding)
        local ScreenGui = Instance.new("ScreenGui"); syn.protect_gui(ScreenGui)
        local Modal = Instance.new("ImageButton")
        local Holder = Instance.new("Frame")
        local UIListLayout = Instance.new("UIListLayout")
        local UIPadding = Instance.new("UIPadding")
        local MousePos = Instance.new("Frame")
        local Cursor = Instance.new("ImageLabel")
        local Tooltip = Instance.new("Frame")
        local Main = Instance.new("ImageLabel")
        local MainOutline = Instance.new("ImageLabel")
        local TextLabel = Instance.new("TextLabel")
        local MainDropshadow = Instance.new("ImageLabel")

        ScreenGui.Parent = game.CoreGui
        ScreenGui.Enabled = false
        ScreenGui.DisplayOrder = 1
        ScreenGui.ResetOnSpawn = false

        Modal.Name = "Modal"
        Modal.Parent = ScreenGui
        Modal.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        Modal.BackgroundTransparency = 1
        Modal.Selectable = false
        Modal.Size = UDim2.fromScale(1, 1)
        Modal.AutoButtonColor = false
        Modal.Modal = true
        Modal.ImageTransparency = 1

        Holder.Name = "Holder"
        Holder.Parent = Modal
        Holder.AnchorPoint = Vector2.new(0, 1)
        Holder.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        Holder.BackgroundTransparency = 1
        Holder.Position = UDim2.new(0, 0, 0.8, 0)
        Holder.Size = UDim2.fromScale(1, 0.15)
        Holder.ZIndex = 2

        UIListLayout.Parent = Holder
        UIListLayout.Padding = UDim.new(0, 15)
        UIListLayout.FillDirection = Enum.FillDirection.Horizontal
        UIListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
        UIListLayout.VerticalAlignment = Enum.VerticalAlignment.Center
        UIListLayout.SortOrder = Enum.SortOrder.Name

        UIPadding.Parent = Holder
        UIPadding.PaddingTop = UDim.new(0, 15)
        UIPadding.PaddingBottom =-UDim.new(0, 15)
        UIPadding.PaddingLeft = UDim.new(0, 15)
        UIPadding.PaddingRight = UDim.new(0, 15)

        MousePos.Name = "MousePos"
        MousePos.Parent = ScreenGui
        MousePos.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        MousePos.BackgroundTransparency = 1.000

        Tooltip.Name = "Tooltip"
        Tooltip.Visible = false
        Tooltip.Parent = MousePos
        Tooltip.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        Tooltip.BackgroundTransparency = 1.000
        Tooltip.BorderSizePixel = 0
        Tooltip.Position = UDim2.new(0, 24, 0, 16)
        Tooltip.Size = UDim2.new(0, 240, 0, 20)

        Main.Name = "Main"
        Main.Parent = Tooltip
        Main.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        Main.BackgroundTransparency = 1.000
        Main.Size = UDim2.new(1, 0, 1, 0)
        Main.Image = "rbxassetid://5152041659"
        Main.ImageColor3 = Color3.fromRGB(60, 60, 60)
        Main.ScaleType = Enum.ScaleType.Slice
        Main.SliceCenter = Rect.new(100, 100, 100, 100)
        Main.SliceScale = 0.050

        MainOutline.Name = "MainOutline"
        MainOutline.Parent = Main
        MainOutline.AnchorPoint = Vector2.new(0.5, 0.5)
        MainOutline.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        MainOutline.BackgroundTransparency = 1.000
        MainOutline.Position = UDim2.new(0.5, 0, 0.5, 0)
        MainOutline.Size = UDim2.new(1, 2, 1, 2)
        MainOutline.ZIndex = -1
        MainOutline.Image = "rbxassetid://5152041659"
        MainOutline.ImageColor3 = Color3.fromRGB(100, 100, 100)
        MainOutline.ScaleType = Enum.ScaleType.Slice
        MainOutline.SliceCenter = Rect.new(100, 100, 100, 100)
        MainOutline.SliceScale = 0.050

        TextLabel.Parent = Main
        TextLabel.AnchorPoint = Vector2.new(0.5, 0.5)
        TextLabel.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        TextLabel.BackgroundTransparency = 1.000
        TextLabel.Position = UDim2.new(0.5, 0, 0.5, 0)
        TextLabel.Size = UDim2.new(1, -10, 1, -4)
        TextLabel.Font = Enum.Font.SourceSans
        TextLabel.Text = "Lorem Ipsum Dolor"
        TextLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
        TextLabel.TextSize = 15.000
        TextLabel.TextStrokeColor3 = Color3.fromRGB(100, 100, 100)
        TextLabel.TextStrokeTransparency = 0.750
        TextLabel.TextWrapped = true
        TextLabel.TextXAlignment = Enum.TextXAlignment.Left
        TextLabel.TextYAlignment = Enum.TextYAlignment.Top

        MainDropshadow.Name = "MainDropshadow"
        MainDropshadow.Parent = Main
        MainDropshadow.AnchorPoint = Vector2.new(0.5, 0.5)
        MainDropshadow.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        MainDropshadow.BackgroundTransparency = 1.000
        MainDropshadow.Position = UDim2.new(0.5, 2, 0.5, 1)
        MainDropshadow.Size = UDim2.new(1, 6, 1, 6)
        MainDropshadow.ZIndex = -2
        MainDropshadow.Image = "rbxassetid://5152055058"
        MainDropshadow.ImageColor3 = Color3.fromRGB(0, 0, 0)
        MainDropshadow.ScaleType = Enum.ScaleType.Slice
        MainDropshadow.SliceCenter = Rect.new(100, 100, 100, 100)
        MainDropshadow.SliceScale = 0.100

        if not binding then warn('Keybind was not set, defaulting to LeftAlt.') end

        local Key = binding or Enum.KeyCode.LeftAlt
        local Enabled = false
        local ChangedConnections = getconnections(UIS:GetPropertyChangedSignal("MouseIconEnabled"))
        BindConnection = UIS.InputBegan:Connect(function(input)
            if input[tostring(Key.EnumType)] == Key then
                ScreenGui.Enabled = not ScreenGui.Enabled
                Enabled = ScreenGui.Enabled
                UIS.MouseIconEnabled = true
            end
        end)

        do
            local mt = getrawmetatable(game); setreadonly(mt, false)
            local old = mt.__newindex

            mt.__newindex = newcclosure(function(self, key, value)
                if Enabled and self == UIS and key == 'MouseIconEnabled' then
                    if not value then return old(self, key, true) end
                end

                return old(self, key, value)
            end)
        end

        MouseConnection = RunService.RenderStepped:Connect(function()
            MousePos.Position = UDim2.fromOffset(Mouse.X, Mouse.Y)
        end)

        local settings_gui = setmetatable({}, {
            columns = {},
            __index = ScreenGui
        })

        function settings_gui.Tooltip(input)
            if typeof(input) == "boolean" then
                Tooltip.Visible = input
            elseif typeof(input) == "string" then
                local textVector = TextService:GetTextSize(input, 15, Enum.Font.Code, Vector2.new(240, math.huge))
                Tooltip.Size = UDim2.fromOffset(textVector.X, textVector.Y) + UDim2.fromOffset(10, 10)
                TextLabel.Text = input
                Tooltip.Visible = true
            else
                error(input == nil and 'First argument was not given.' or 'First argument wasn\'t a string or bool.')
            end
        end

        function settings_gui:Option(name, valueToChange, toolTip)
            assert(name ~= nil, "Missing first argument: (name)")
            assert(valueToChange ~= nil, "Missing second argument: (valueToChange)")
            assert(toolTip and typeof(toolTip) == "string" or not toolTip, "Third argument expected string, got: "..typeof(toolTip))
            local acceptedTypes = {"number", "boolean", "string"}
            assert(table.find(acceptedTypes, typeof(valueToChange.Value)), "Unsupported value-type: "..typeof(valueToChange.Value))
            
            local mt = getmetatable(self)
            local columns = mt.columns
            local column

            if #columns == 0 then
                column = newColumn(Holder)
                columns[#columns+1] = column
            else
                column = columns[#columns]
            end

            if column.UIListLayout.AbsoluteContentSize.Y + 30 > column.AbsoluteSize.Y then
                column = newColumn(Holder)
                columns[#columns+1] = column
            end
            
            local func = typeof(valueToChange.Value) == 'number' and newNumbOption or typeof(valueToChange.Value) == 'boolean' and newBoolOption or newEnumOption
            local row = func(name, valueToChange, toolTip, self)
            row.Name = name
            row.Parent = column

            return row
        end

        return settings_gui
    end
}