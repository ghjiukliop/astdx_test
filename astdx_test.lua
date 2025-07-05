local success, err = pcall(function()
    Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()
    SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/SaveManager.lua"))()
    InterfaceManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/InterfaceManager.lua"))()
end)

if not success then
    warn("Failed to load Fluent UI:", err)
    return
end

-- Hệ thống lưu trữ cấu hình
local ConfigSystem = {}
ConfigSystem.FileName = "HTHubConfig_" .. game:GetService("Players").LocalPlayer.Name .. ".json"
ConfigSystem.DefaultConfig = {
    -- Map Settings
}
ConfigSystem.CurrentConfig = {}

-- Hàm để lưu cấu hình
ConfigSystem.SaveConfig = function()
    local success, err = pcall(function()
        writefile(ConfigSystem.FileName, game:GetService("HttpService"):JSONEncode(ConfigSystem.CurrentConfig))
    end)
    if success then
        print("Đã lưu cấu hình thành công!")
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
        local data = game:GetService("HttpService"):JSONDecode(content)
        ConfigSystem.CurrentConfig = data
        return true
    else
        ConfigSystem.CurrentConfig = table.clone(ConfigSystem.DefaultConfig)
        ConfigSystem.SaveConfig()
        return false
    end
end

-- Tải cấu hình khi khởi động
ConfigSystem.LoadConfig()

local window = Fluent:CreateWindow({
    Title = "HT Hub",
    SubTitle = "",
    TabWidth = 80,
    Size = UDim2.fromOffset(300, 220),
    Acrylic = true,
    Theme = "Amethyst",
    MinimizeKey = Enum.KeyCode.RightControl
})

-- Lớp Tab
local mainTab = window:AddTab({
    Title = "Map",
    Icon = "home"
})

local settingTab = window:AddTab({
    Title = "Setting",
    Icon = "settings"
})

-- Thêm hỗ trợ Logo khi minimize
repeat task.wait(0.25) until game:IsLoaded()
getgenv().Image = "rbxassetid://13099788281" -- ID tài nguyên hình ảnh logo
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

-- Settings tab
local SettingsSection = settingTab:AddSection("Script Settings")
-- Integration with SaveManager
SaveManager:SetLibrary(Fluent)
InterfaceManager:SetLibrary(Fluent)

-- Lưu cấu hình để sử dụng tên người chơi
local playerName = game:GetService("Players").LocalPlayer.Name
InterfaceManager:SetFolder("HTHubASTD")
SaveManager:SetFolder("HTHubASTD/" .. playerName)

-- Auto Save Config - chạy ít thường xuyên hơn
local function AutoSaveConfig()
    spawn(function()
        while wait(5) do -- Lưu mỗi 5 giây
            pcall(function()
                ConfigSystem.SaveConfig()
            end)
        end
    end)
end

-- Thực thi tự động lưu cấu hình
AutoSaveConfig()

-- Thêm thông tin vào tab Settings
settingTab:AddParagraph({
    Title = "Cấu hình tự động",
    Content = "Cấu hình của bạn đang được tự động lưu theo tên nhân vật: " .. playerName
})

settingTab:AddParagraph({
    Title = "Phím tắt",
    Content = "Nhấn LeftControl để ẩn/hiện giao diện"
})

-- ...existing code...

-- Tạo tab Macro
local macroTab = window:AddTab({
    Title = "Macro",
    Icon = "film"
})

local macroSection = macroTab:AddSection("Record/Play Macro")

-- Thư mục lưu macro
local macroFolder = "HTHubASTD/Macros"
if not isfolder(macroFolder) then
    makefolder(macroFolder)
end

-- Lấy danh sách file macro
local function getMacroFiles()
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

-- Input để tạo file macro mới
local macroFileName = ""
macroSection:AddInput("MacroFileInput", {
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
local macroDropdown = macroSection:AddDropdown("MacroFileDropdown", {
    Title = "Chọn file macro",
    Values = getMacroFiles(),
    Multi = false,
    Callback = function(value)
        selectedMacro = value
    end
})

-- Làm mới dropdown khi tạo file mới
macroSection:AddButton({
    Title = "Làm mới danh sách macro",
    Callback = function()
        macroDropdown:SetValues(getMacroFiles())
    end
})

-- 2 Toggle: Record và Play
local isRecording = false
local isPlaying = false

macroSection:AddToggle("RecordMacroToggle", {
    Title = "Record Macro",
    Default = false,
    Callback = function(state)
        isRecording = state
        if state then
            Fluent:Notify({Title = "Macro", Content = "Đang ghi macro...", Duration = 2})
        else
            Fluent:Notify({Title = "Macro", Content = "Đã dừng ghi macro.", Duration = 2})
        end
    end
})

macroSection:AddToggle("PlayMacroToggle", {
    Title = "Play Macro",
    Default = false,
    Callback = function(state)
        isPlaying = state
        if state then
            Fluent:Notify({Title = "Macro", Content = "Đang chạy macro...", Duration = 2})
        else
            Fluent:Notify({Title = "Macro", Content = "Đã dừng chạy macro.", Duration = 2})
        end
    end
})

-- Ô hiển thị trạng thái macro (giống ảnh)
local macroStatus = {
    status = "Idle",
    action = 0,
    type = "",
    unit = "",
    waiting = ""
}

local statusParagraph = macroSection:AddParagraph({
    Title = "Macro Status",
    Content = "Status: Idle"
})

-- Hàm cập nhật trạng thái hiển thị
local function updateMacroStatus()
    local content = string.format(
        "Macro Status: %s\nAction: %s\nType: %s\nUnit: %s\nWaiting for: %s",
        macroStatus.status,
        macroStatus.action,
        macroStatus.type,
        macroStatus.unit,
        macroStatus.waiting
    )
    statusParagraph:SetContent(content)
end

-- Ví dụ cập nhật trạng thái khi record/play (bạn cần tích hợp vào logic thực tế)
-- Khi bắt đầu record/play:
-- macroStatus.status = isRecording and "Recording" or (isPlaying and "Playing" or "Idle")
-- macroStatus.action = 1 -- số bước hiện tại
-- macroStatus.type = "Selling Unit"
-- macroStatus.unit = "Goku"
-- macroStatus.waiting = "550¥"
-- updateMacroStatus()

--