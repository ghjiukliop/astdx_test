-- Anime Saga Script

-- Hệ thống kiểm soát logs
local LogSystem = {
    Enabled = true, -- Mặc định bật logs
    WarningsEnabled = true -- Mặc định bật cả warnings
}

-- Ghi đè hàm print để kiểm soát logs
local originalPrint = print
print = function(...)
    if LogSystem.Enabled then
        originalPrint(...)
    end
end

-- Ghi đè hàm warn để kiểm soát warnings
local originalWarn = warn
warn = function(...)
    if LogSystem.WarningsEnabled then
        originalWarn(...)
    end
end

-- Tải thư viện Fluent
local success, err = pcall(function()
    Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()
    SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/SaveManager.lua"))()
    InterfaceManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/InterfaceManager.lua"))()
end)

if not success then
    warn("Lỗi khi tải thư viện Fluent: " .. tostring(err))
    -- Thử tải từ URL dự phòng
    pcall(function()
        Fluent = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Fluent.lua"))()
        SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/SaveManager.lua"))()
        InterfaceManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/InterfaceManager.lua"))()
    end)
end

if not Fluent then
    error("Không thể tải thư viện Fluent. Vui lòng kiểm tra kết nối internet hoặc executor.")
    return
end

-- Hệ thống lưu trữ cấu hình
local ConfigSystem = {}
ConfigSystem.FileName = "AnimeSagaConfig_" .. game:GetService("Players").LocalPlayer.Name .. ".json"
ConfigSystem.DefaultConfig = {
    -- Các cài đặt mặc định
    UITheme = "Amethyst",
    
    -- Cài đặt log
    LogsEnabled = true,
    WarningsEnabled = true,
    
    -- Các cài đặt khác sẽ được thêm vào sau
}
ConfigSystem.CurrentConfig = {}

-- Cache cho ConfigSystem để giảm lượng I/O
ConfigSystem.LastSaveTime = 0
ConfigSystem.SaveCooldown = 2 -- 2 giây giữa các lần lưu
ConfigSystem.PendingSave = false

-- Hàm để lưu cấu hình
ConfigSystem.SaveConfig = function()
    -- Kiểm tra thời gian từ lần lưu cuối
    local currentTime = os.time()
    if currentTime - ConfigSystem.LastSaveTime < ConfigSystem.SaveCooldown then
        -- Đã lưu gần đây, đánh dấu để lưu sau
        ConfigSystem.PendingSave = true
        return
    end
    
    local success, err = pcall(function()
        local HttpService = game:GetService("HttpService")
        writefile(ConfigSystem.FileName, HttpService:JSONEncode(ConfigSystem.CurrentConfig))
    end)
    
    if success then
        ConfigSystem.LastSaveTime = currentTime
        ConfigSystem.PendingSave = false
    else
        warn("Lưu cấu hình thất bại:", err)
    end
end

-- Hàm để tải cấu hình
ConfigSystem.LoadConfig = function()
    local success, content = pcall(function()
        if isfile(ConfigSystem.FileName) then
            return readfile(ConfigSystem.FileName)
        end
        return nil
    end)
    
    if success and content then
        local success2, data = pcall(function()
            local HttpService = game:GetService("HttpService")
            return HttpService:JSONDecode(content)
        end)
        
        if success2 and data then
            -- Merge with default config to ensure all settings exist
            for key, value in pairs(ConfigSystem.DefaultConfig) do
                if data[key] == nil then
                    data[key] = value
                end
            end
            
        ConfigSystem.CurrentConfig = data
        
        -- Cập nhật cài đặt log
        if data.LogsEnabled ~= nil then
            LogSystem.Enabled = data.LogsEnabled
        end
        
        if data.WarningsEnabled ~= nil then
            LogSystem.WarningsEnabled = data.WarningsEnabled
        end
        
        return true
        end
    end
    
    -- Nếu tải thất bại, sử dụng cấu hình mặc định
        ConfigSystem.CurrentConfig = table.clone(ConfigSystem.DefaultConfig)
        ConfigSystem.SaveConfig()
        return false
    end

-- Thiết lập timer để lưu định kỳ nếu có thay đổi chưa lưu
spawn(function()
    while wait(5) do
        if ConfigSystem.PendingSave then
            ConfigSystem.SaveConfig()
        end
    end
end)

-- Tải cấu hình khi khởi động
ConfigSystem.LoadConfig()

-- Thông tin người chơi
local playerName = game:GetService("Players").LocalPlayer.Name

-- Tạo Window
local Window = Fluent:CreateWindow({
    Title = "HT Hub | All star tower defense X",
    SubTitle = "",
    TabWidth = 140,
    Size = UDim2.fromOffset(450, 350),
    Acrylic = true,
    Theme = ConfigSystem.CurrentConfig.UITheme or "Dark",
    MinimizeKey = Enum.KeyCode.LeftControl
})

-- Tạo tab Info
local InfoTab = Window:AddTab({
    Title = "Info",
    Icon = "rbxassetid://7733964719"
})

-- Thêm tab Play
local PlayTab = Window:AddTab({
    Title = "Play",
    Icon = "rbxassetid://7734053495" -- Bạn có thể thay icon khác nếu muốn
})

local MacroTab = Window:AddTab({
    Title = "Macro",
    Icon = "rbxassetid://7734053495" -- Đổi icon nếu muốn
})
-- Thêm hỗ trợ Logo khi minimize
repeat task.wait(0.25) until game:IsLoaded()
getgenv().Image = "rbxassetid://90319448802378" -- ID tài nguyên hình ảnh logo
getgenv().ToggleUI = "LeftControl" -- Phím để bật/tắt giao diện

-- Tạo logo để mở lại UI khi đã minimize
task.spawn(function()
    local success, errorMsg = pcall(function()
        if not getgenv().LoadedMobileUI == true then 
            getgenv().LoadedMobileUI = true
            local OpenUI = Instance.new("ScreenGui")
            local ImageButton = Instance.new("ImageButton")
            local UICorner = Instance.new("UICorner")
            
            -- Kiểm tra môi trường
            if syn and syn.protect_gui then
                syn.protect_gui(OpenUI)
                OpenUI.Parent = game:GetService("CoreGui")
            elseif gethui then
                OpenUI.Parent = gethui()
            else
                OpenUI.Parent = game:GetService("CoreGui")
            end
            
            OpenUI.Name = "OpenUI"
            OpenUI.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
            
            ImageButton.Parent = OpenUI
            ImageButton.BackgroundColor3 = Color3.fromRGB(105,105,105)
            ImageButton.BackgroundTransparency = 0.8
            ImageButton.Position = UDim2.new(0.9,0,0.1,0)
            ImageButton.Size = UDim2.new(0,50,0,50)
            ImageButton.Image = getgenv().Image
            ImageButton.Draggable = true
            ImageButton.Transparency = 0.2
            
            UICorner.CornerRadius = UDim.new(0,200)
            UICorner.Parent = ImageButton
            
            -- Khi click vào logo sẽ mở lại UI
            ImageButton.MouseButton1Click:Connect(function()
                game:GetService("VirtualInputManager"):SendKeyEvent(true,getgenv().ToggleUI,false,game)
            end)
        end
    end)
    
    if not success then
        warn("Lỗi khi tạo nút Logo UI: " .. tostring(errorMsg))
    end
end)

-- Tự động chọn tab Info khi khởi động
Window:SelectTab(1) -- Chọn tab đầu tiên (Info)

-- Thêm section thông tin trong tab Info
local InfoSection = InfoTab:AddSection("Thông tin")

InfoSection:AddParagraph({
    Title = "All Star Tower Defense X",
    Content = "Phiên bản: 1.0 Beta\nTrạng thái: Hoạt động"
})

InfoSection:AddParagraph({
    Title = "Người phát triển",
    Content = "Script được phát triển bởi Dương Tuấn và ghjiukliop"
})

-- Thêm section thiết lập trong tab Settings
local SettingsTab = Window:AddTab({
    Title = "Settings",
    Icon = "rbxassetid://6031280882"
})

local SettingsSection = SettingsTab:AddSection("Thiết lập")

-- Dropdown chọn theme
SettingsSection:AddDropdown("ThemeDropdown", {
    Title = "Chọn Theme",
    Values = {"Dark", "Light", "Darker", "Aqua", "Amethyst"},
    Multi = false,
    Default = ConfigSystem.CurrentConfig.UITheme or "Dark",
    Callback = function(Value)
        ConfigSystem.CurrentConfig.UITheme = Value
        ConfigSystem.SaveConfig()
        print("Đã chọn theme: " .. Value)
    end
})

-- Auto Save Config
local function AutoSaveConfig()
    spawn(function()
        while wait(5) do -- Lưu mỗi 5 giây
            pcall(function()
                ConfigSystem.SaveConfig()
            end)
        end
    end)
end

-- Thêm event listener để lưu ngay khi thay đổi giá trị
local function setupSaveEvents()
    for _, tab in pairs({InfoTab, SettingsTab}) do
        if tab and tab._components then
            for _, element in pairs(tab._components) do
                if element and element.OnChanged then
                    element.OnChanged:Connect(function()
                        pcall(function()
                            ConfigSystem.SaveConfig()
                        end)
                    end)
                end
            end
        end
    end
end

-- ...existing code...


local MacroSection = MacroTab:AddSection("Record/Play Macro")

-- Thư mục lưu macro
local macroFolder = "HTHubAS/Macros"
if not isfolder(macroFolder) then
    makefolder(macroFolder)
end

-- Lấy danh sách file macro
-- ...existing code...

local function getMacroFiles()
    -- Đảm bảo thư mục tồn tại trước khi listfiles
    if not isfolder(macroFolder) then
        makefolder(macroFolder)
    end
    local files = listfiles(macroFolder)
    local macroFiles = {}
    for _, file in ipairs(files) do
        if file:match("%.json$") then
            local name = file:match("([^\\/]*)%.json$")
            table.insert(macroFiles, name)
        end
    end
    return macroFiles
end

-- ...existing code...

-- Input để tạo file macro mới
local macroFileName = ""
MacroSection:AddInput("MacroFileInput", {
    Title = "Tạo file macro mới",
    Placeholder = "Nhập tên macro và nhấn Enter",
    Callback = function(value)
        macroFileName = value
    end,
    OnEnter = function(value)
        if value and value ~= "" then
            local filePath = macroFolder .. "/" .. value .. ".json"
            if not isfile(filePath) then
                writefile(filePath, "[]")
                Fluent:Notify({
                    Title = "Macro",
                    Content = "Đã tạo file macro: " .. value,
                    Duration = 3
                })
            else
                Fluent:Notify({
                    Title = "Macro",
                    Content = "File macro đã tồn tại!",
                    Duration = 3
                })
            end
        end
    end
})

-- Dropdown chọn file macro
local selectedMacro = nil
local macroDropdown = MacroSection:AddDropdown("MacroFileDropdown", {
    Title = "Chọn file macro",
    Values = getMacroFiles(),
    Multi = false,
    Callback = function(value)
        selectedMacro = value
    end
})

-- Làm mới dropdown khi tạo file mới
MacroSection:AddButton({
    Title = "Làm mới danh sách macro",
    Callback = function()
        macroDropdown:SetValues(getMacroFiles())
    end
})
-- ...existing code...

-- 2 Toggle: Record và Play
local isRecording = false
local isPlaying = false
local currentMacro = {}
local macroPlayThread = nil

-- Hàm ghi thao tác vào macro
local function recordAction(actionType, data)
    if isRecording and selectedMacro then
        table.insert(currentMacro, {
            time = tick(),
            action = actionType,
            data = data
        })
        updateMacroStatus()
    end
end

-- Hook các thao tác: Place, Upgrade, Sell
-- Bạn cần gọi các hàm này khi thực hiện thao tác tương ứng trong UI/game

-- Ghi thao tác Place
local function recordPlace(unitName, cframe)
    recordAction("Place", {
        unit = unitName,
        cframe = {cframe.X, cframe.Y, cframe.Z, cframe:ToOrientation()}
    })
end

-- Ghi thao tác Upgrade
local function recordUpgrade(unitName)
    recordAction("Upgrade", {
        unit = unitName
    })
end

-- Ghi thao tác Sell
local function recordSell(unitName)
    recordAction("Sell", {
        unit = unitName
    })
end

-- Lưu macro ra file
local function saveMacroToFile()
    if selectedMacro then
        local filePath = macroFolder .. "/" .. selectedMacro .. ".json"
        local HttpService = game:GetService("HttpService")
        writefile(filePath, HttpService:JSONEncode(currentMacro))
    end
end

-- Tải macro từ file
local function loadMacroFromFile()
    if selectedMacro then
        local filePath = macroFolder .. "/" .. selectedMacro .. ".json"
        if isfile(filePath) then
            local HttpService = game:GetService("HttpService")
            local content = readfile(filePath)
            currentMacro = HttpService:JSONDecode(content)
        else
            currentMacro = {}
        end
    end
end

-- Khi bật Record
MacroSection:AddToggle("RecordMacroToggle", {
    Title = "Record Macro",
    Default = false,
    Callback = function(state)
        isRecording = state
        if state then
            currentMacro = {}
            macroStatus.status = "Recording"
            Fluent:Notify({Title = "Macro", Content = "Đang ghi macro...", Duration = 2})
        else
            macroStatus.status = "Idle"
            saveMacroToFile()
            Fluent:Notify({Title = "Macro", Content = "Đã dừng ghi macro.", Duration = 2})
        end
        updateMacroStatus()
    end
})

-- Khi bật Play
MacroSection:AddToggle("PlayMacroToggle", {
    Title = "Play Macro",
    Default = false,
    Callback = function(state)
        isPlaying = state
        if state then
            macroStatus.status = "Playing"
            loadMacroFromFile()
            if macroPlayThread then
                coroutine.close(macroPlayThread)
            end
            macroPlayThread = coroutine.create(function()
                for i, action in ipairs(currentMacro) do
                    macroStatus.action = i
                    macroStatus.type = action.action
                    macroStatus.unit = action.data.unit or ""
                    macroStatus.waiting = ""
                    updateMacroStatus()
                    if action.action == "Place" then
                        local c = action.data.cframe
                        local cf = CFrame.new(c[1], c[2], c[3]) * CFrame.Angles(c[4], c[5], c[6])
                        local args = {
                            [1] = "GameStuff",
                            [2] = {
                                [1] = "Summon",
                                [2] = action.data.unit,
                                [3] = cf
                            }
                        }
                        game:GetService("ReplicatedStorage").Remotes.SetEvent:FireServer(unpack(args))
                    elseif action.action == "Upgrade" then
                        local args = {
                            [1] = {["Type"] = "GameStuff"},
                            [2] = {
                                [1] = "Upgrade",
                                [2] = workspace.UnitFolder:FindFirstChild(action.data.unit)
                            }
                        }
                        game:GetService("ReplicatedStorage").Remotes.GetFunction:InvokeServer(unpack(args))
                    elseif action.action == "Sell" then
                        local args = {
                            [1] = {["Type"] = "GameStuff"},
                            [2] = {
                                [1] = "Sell",
                                [2] = workspace.UnitFolder:FindFirstChild(action.data.unit)
                            }
                        }
                        game:GetService("ReplicatedStorage").Remotes.GetFunction:InvokeServer(unpack(args))
                    end
                    wait(0.5) -- delay giữa các thao tác, có thể chỉnh
                end
                macroStatus.status = "Idle"
                macroStatus.action = 0
                macroStatus.type = ""
                macroStatus.unit = ""
                macroStatus.waiting = ""
                updateMacroStatus()
                Fluent:Notify({Title = "Macro", Content = "Đã chạy xong macro.", Duration = 2})
            end)
            coroutine.resume(macroPlayThread)
            Fluent:Notify({Title = "Macro", Content = "Đang chạy macro...", Duration = 2})
        else
            macroStatus.status = "Idle"
            macroStatus.action = 0
            macroStatus.type = ""
            macroStatus.unit = ""
            macroStatus.waiting = ""
            updateMacroStatus()
            Fluent:Notify({Title = "Macro", Content = "Đã dừng chạy macro.", Duration = 2})
        end
    end
})

-- Ô hiển thị trạng thái macro
local statusParagraph = MacroSection:AddParagraph({
    Title = "Macro Status",
    Content = "Macro Status: Idle"
})

function updateMacroStatus()
    local content = string.format(
        "Macro Status: %s\nAction: %s\nType: %s\nUnit: %s\nWaiting for: %s",
        macroStatus.status or "Idle",
        macroStatus.action or "",
        macroStatus.type or "",
        macroStatus.unit or "",
        macroStatus.waiting or ""
    )
    statusParagraph:SetContent(content)
end

-- Khi chọn macro mới thì load lại
macroDropdown:OnChanged(function(value)
    selectedMacro = value
    loadMacroFromFile()
end)

-- ...existing code...



-- Tích hợp với SaveManager
SaveManager:SetLibrary(Fluent)
InterfaceManager:SetLibrary(Fluent)

-- Thay đổi cách lưu cấu hình để sử dụng tên người chơi
InterfaceManager:SetFolder("HTHubAS")
SaveManager:SetFolder("HTHubAS/" .. playerName)

-- Thêm thông tin vào tab Settings
SettingsTab:AddParagraph({
    Title = "Cấu hình tự động",
    Content = "Cấu hình của bạn đang được tự động lưu theo tên nhân vật: " .. playerName
})

SettingsTab:AddParagraph({
    Title = "Phím tắt",
    Content = "Nhấn LeftControl để ẩn/hiện giao diện"
})

-- Thực thi tự động lưu cấu hình
AutoSaveConfig()

-- Thiết lập events
setupSaveEvents()

print("HT Hub | Anime Saga đã được tải thành công!")
