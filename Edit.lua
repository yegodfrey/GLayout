-- YourAddonName.lua

-- 初始化 SavedVariables (如果它们不存在)
-- 确保 YourAddonSavedLayoutDB 在你的 .toc 文件中声明了
-- ## SavedVariables: YourAddonSavedLayoutDB
YourAddonSavedLayoutDB = YourAddonSavedLayoutDB or {}
YourAddonSavedLayoutDB.profiles = YourAddonSavedLayoutDB.profiles or {} -- 用于存储多个配置档案

local addonName = "MyEditModeLoader" -- 给你的插件起个名字，用于打印信息
local defaultProfileName = "default" -- 默认配置档案的名称

local addonFrame = CreateFrame("Frame")
addonFrame:RegisterEvent("PLAYER_LOGIN")

--[[
    核心功能：获取当前编辑模式布局的导出字符串
    注意: C_EditMode.ExportLayout 需要一个布局 UID。
    我们需要先获取当前激活的布局 UID。
]]
local function GetCurrentLayoutExportString()
    local activeLayoutUID = C_EditMode.GetActiveLayoutUID()
    if activeLayoutUID then
        local success, layoutString = pcall(C_EditMode.ExportLayout, activeLayoutUID)
        if success and layoutString and type(layoutString) == "string" then
            return layoutString
        else
            print(addonName .. ": Error exporting layout - " .. (layoutString or "Unknown error"))
            return nil
        end
    else
        print(addonName .. ": No active Edit Mode layout found to export.")
        return nil
    end
end

--[[
    核心功能：导入并应用一个布局字符串
    注意: C_EditMode.ImportLayout 会创建一个新的布局。
    我们需要给它一个名字，然后激活它。
]]
local function ImportAndApplyLayoutString(layoutString, profileName)
    if not layoutString or type(layoutString) ~= "string" then
        print(addonName .. ": Invalid layout string for import.")
        return false
    end

    -- 为导入的布局生成一个唯一的名称，以免与现有布局冲突
    -- 你也可以考虑覆盖同名插件导入的布局
    local importName = addonName .. "_" .. profileName .. "_" .. time()

    local success, newLayoutUID = pcall(C_EditMode.ImportLayout, layoutString, importName)

    if success and newLayoutUID then
        print(addonName .. ": Layout '" .. importName .. "' (from profile '" .. profileName .. "') imported successfully with UID: " .. newLayoutUID)
        local activateSuccess, activateError = pcall(C_EditMode.SetActiveLayout, newLayoutUID)
        if activateSuccess then
            print(addonName .. ": Layout '" .. importName .. "' activated.")
            -- 可选：删除之前由该插件为该档案导入的旧布局，以避免列表混乱
            -- 这需要更复杂的追踪和管理
            return true
        else
            print(addonName .. ": Failed to activate imported layout '" .. importName .. "'. Error: " .. (activateError or "Unknown error"))
            -- 如果激活失败，你可能想删除刚导入的布局
            -- pcall(C_EditMode.DeleteLayout, newLayoutUID)
            return false
        end
    else
        print(addonName .. ": Failed to import layout string for profile '" .. profileName .. "'. Error: " .. (newLayoutUID or "Unknown error"))
        return false
    end
end

-- 函数：保存当前编辑模式布局到指定的档案名
local function SaveCurrentLayoutToProfile(profileNameToSave)
    profileNameToSave = profileNameToSave or defaultProfileName
    local layoutString = GetCurrentLayoutExportString()

    if layoutString then
        YourAddonSavedLayoutDB.profiles[profileNameToSave] = layoutString
        print(addonName .. ": Edit Mode Layout saved to profile '" .. profileNameToSave .. "'.")
    else
        print(addonName .. ": Failed to save layout to profile '" .. profileNameToSave .. "' because export failed.")
    end
end

-- 函数：从指定的档案名加载并应用编辑模式布局
local function ApplySavedLayoutFromProfile(profileNameToLoad)
    profileNameToLoad = profileNameToLoad or defaultProfileName
    if YourAddonSavedLayoutDB and YourAddonSavedLayoutDB.profiles and YourAddonSavedLayoutDB.profiles[profileNameToLoad] then
        local layoutString = YourAddonSavedLayoutDB.profiles[profileNameToLoad]
        print(addonName .. ": Applying layout from profile '" .. profileNameToLoad .. "'.")
        ImportAndApplyLayoutString(layoutString, profileNameToLoad)
    else
        print(addonName .. ": No saved layout found for profile '" .. profileNameToLoad .. "'. Use /lllsave [profile_name] to save one.")
    end
end

-- 事件处理
addonFrame:SetScript("OnEvent", function(self, event, ...)
    if event == "PLAYER_LOGIN" then
        -- 玩家登录时自动应用默认配置 (如果存在)
        -- 你可以根据需要决定是否默认加载，或者添加一个选项来控制
        C_Timer.After(7, function() -- 稍微延迟以确保编辑模式系统完全加载
            print(addonName .. ": Checking for default layout to apply on login...")
            ApplySavedLayoutFromProfile(defaultProfileName) -- 自动应用默认配置
        end)
    end
end)

-- 斜杠命令处理
--[[
    /lllsave [profile_name] - 保存当前布局到指定名称 (如果未提供名称，则为 'default')
    /lllout [profile_name]  - 加载并应用指定名称的布局 (如果未提供名称，则为 'default')
    /lllhelp                - 显示帮助信息
]]
SLASH_MYLAYOUTLOADER1 = "/lllsave"
SLASH_MYLAYOUTLOADER2 = "/lllout"
SLASH_MYLAYOUTLOADER3 = "/lllhelp" -- 新增一个帮助命令

SlashCmdList["MYLAYOUTLOADER"] = function(msg, editBox)
    local command, profileName = msg:match("^(%S*)%s*(.*)$") -- 分割命令和可选的参数
    profileName = profileName and profileName:trim() ~= "" and profileName:trim() or defaultProfileName

    if command == "save" or msg:lower() == "save" then -- 兼容 /lllsave 和 /lllsave profilename
        if profileName == defaultProfileName and msg:match("^(%S*)%s*(.*)$"):match("%S*%s*(.*)"):trim() ~= "" then
             -- 如果是 /lllsave profilename 这种形式
             profileName = msg:match("^(%S*)%s*(.*)$"):match("%S*%s*(.*)"):trim()
        end
        SaveCurrentLayoutToProfile(profileName)
    elseif command == "out" or msg:lower() == "out" then -- 兼容 /lllout 和 /lllout profilename
        if profileName == defaultProfileName and msg:match("^(%S*)%s*(.*)$"):match("%S*%s*(.*)"):trim() ~= "" then
            profileName = msg:match("^(%S*)%s*(.*)$"):match("%S*%s*(.*)"):trim()
        end
        ApplySavedLayoutFromProfile(profileName)
    elseif command == "help" or msg:lower() == "help" then
        print(addonName .. " Slash Commands:")
        print("|cffffff00/lllsave [profile_name]|r - Saves the current Edit Mode layout. If [profile_name] is omitted, uses '"..defaultProfileName.."'.")
        print("|cffffff00/lllout [profile_name]|r - Applies the saved Edit Mode layout. If [profile_name] is omitted, uses '"..defaultProfileName.."'.")
        print("|cffffff00/lllhelp|r - Shows this help message.")
    else
        -- 兼容旧的单一命令模式 (如果你的命令前缀是 /lll 而不是 /lllsave)
        -- 例如，如果你的 .toc 中定义的是 SLASH_LLL1 = "/lll"
        -- SlashCmdList["LLL"] = function(msg) ...
        -- 在那种情况下，你需要在这里做不同的判断

        -- 为了清晰，我们假设 SLASH 命令定义的是命令本身
        -- 如果命令不匹配，可以给一些提示
        print(addonName .. ": Unknown command '" .. msg .. "'. Use /lllhelp for available commands.")
    end
end

print(addonName .. " Loaded! Use /lllhelp for commands.")