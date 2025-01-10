--[[
    File: build.lua
    Description: Quick packaging for this project.
    Author: circute
    Date: 2025-01-10
    Version: 1.0.0
    License: GPL-v3
]]

local entryPointFileName = "Base.lua"
local srcDir = "./src/"
local binDir = "./bin/"
local outputFilePrefixName = "BaseBlock_Eggy"
local author = "circute"
local desc = nil

---读取文件内容
---@param dir string 文件所在目录
---@param filename string 文件名
---@return string|nil 文件内容
local function readFileToString(dir, filename)
    local filePath = dir .. "/" .. filename
    local file, _ = io.open(filePath, "r")
    if not file then
        return nil
    end

    local content = file:read("*a")
    file:close()
    return content
end

---字符串写入文件
---@param filePath string 写入文件路径
---@param content string 文件名
---@return boolean 写入标志
local function writeStringToFile(filePath, content)
    local file, _ = io.open(filePath, "r")
    if file then
        local existingContent = file:read("*a")
        file:close()
        if #existingContent > 0 then
            print("[ WARN ] Output file already exists.")
        end
    end

    file, _ = io.open(filePath, "w")
    if not file then
        return false
    end

    file:write(content)
    file:close()
    return true
end

---检测列表是否包含指定元素
---@param list table
---@param element any
---@return boolean
local function contains(list, element)
    for _, value in pairs(list) do
        if value == element then
            return true -- 找到元素，返回 true
        end
    end
    return false -- 未找到元素，返回 false
end

--- 移除 Lua 模块代码末尾的 return 语句及其返回值的定义
---@param code string lua 源代码
---@return string 处理后的代码
local function removeTrailingReturn(code, removeDefine)
    -- 匹配以 "return" 开头的有效代码行（忽略注释）
    local returnPattern = "^%s*return%s+(.+)$"             -- 捕获返回值部分
    local localVarPattern = "^%s*local%s+([%w_]+)%s*="     -- 匹配局部变量定义
    local functionPattern = "^%s*function%s+[%w_%.]+%s*%(" -- 匹配函数定义
    local endPattern = "^%s*end%s*$"                       -- 匹配函数结束
    local isInFunction = false                             -- 用于标记是否在函数中

    local lines = {}
    for line in code:gmatch("[^\r\n]+") do
        table.insert(lines, line)
    end

    local returnVars = nil -- 用于存储 return 返回的变量名列表

    -- 跳过尾部注释行，检查有效代码
    for i = #lines, 1, -1 do
        local trimmedLine = lines[i]:match("^%s*(.-)%s*$") -- 去掉首尾空白
        if not trimmedLine:match("^%-%-") then             -- 忽略单行注释
            if trimmedLine:match(endPattern) then
                isInFunction = true                        -- 标记在函数结束
            elseif trimmedLine:match(functionPattern) then
                isInFunction = false                       -- 退出函数定义
            elseif not isInFunction then
                local returnMatch = trimmedLine:match(returnPattern)
                if returnMatch then
                    -- 提取 return 的返回值变量
                    returnVars = {}
                    for var in returnMatch:gmatch("[%w_]+") do
                        table.insert(returnVars, var)
                    end
                    table.remove(lines, i) -- 移除匹配的 return 行
                    break
                else
                    break -- 非注释行且不匹配 return，直接退出检查
                end
            end
        end
    end

    -- 如果找到 return 变量，删除其局部定义
    if returnVars and removeDefine then
        local i = 1
        while i <= #lines do
            local trimmedLine = lines[i]:match("^%s*(.-)%s*$") -- 去掉首尾空白
            local localVarMatch = trimmedLine:match(localVarPattern)
            if not isInFunction and localVarMatch and table.concat(returnVars, " "):find(localVarMatch) then
                table.remove(lines, i) -- 删除局部变量定义行
            elseif trimmedLine:match(functionPattern) then
                isInFunction = true    -- 进入函数定义
                i = i + 1
            elseif trimmedLine:match(endPattern) then
                isInFunction = false -- 退出函数定义
                i = i + 1
            else
                i = i + 1
            end
        end
    else
        print("[ WARN ] The code does not end with a module-level 'return'. No changes were made.")
    end

    return table.concat(lines, "\n")
end

--- 移除代码开始部分的 require 语句
---@param code string 需要处理的 Lua 代码
---@return string 处理后的代码
local function removeHeaderRequireStatements(code)
    -- 拆分代码为行
    local lines = {}
    for line in code:gmatch("[^\r\n]+") do
        table.insert(lines, line)
    end

    local result = {}
    local requirePattern = "^%s*local%s+%w+%s*=%s*require%([^%)]+%)%s*$"
    local foundNonRequireLine = false

    -- 遍历行，跳过开头的 require 语句
    for _, line in ipairs(lines) do
        if not foundNonRequireLine and line:match(requirePattern) then
            -- 这是开头的 require 语句，跳过
        else
            -- 一旦发现非 require 行，标记并保存
            foundNonRequireLine = true
            table.insert(result, line)
        end
    end

    -- 将结果表连接成完整字符串
    return table.concat(result, "\n")
end

--- 给 Lua 代码中的局部变量和局部函数添加前缀（函数参数和 self 除外）
local function addPrefixToLocalVariables(code, prefix, protectedVarNameList)
    local replacedCode = code

    local localVarPattern = "local%s+([%w_]+)%s*="              -- local var = ...
    local localFuncPattern = "local%s+function%s+([%w_]+)%s*%(" -- local function func(...)

    local replacementMap = {}

    replacedCode = replacedCode:gsub(localVarPattern, function(var)
        if contains(protectedVarNameList, var) then
            print("[ WARN ] Variable naming may conflicts: [ " .. "var" .. " ].")
        end
        if var == "self" then
            return "local " .. var .. " ="
        end
        local newName = prefix .. var
        replacementMap[var] = newName
        return "local " .. newName .. " ="
    end)

    replacedCode = replacedCode:gsub(localFuncPattern, function(func)
        if contains(protectedVarNameList, func) then
            print("[ WARN ] Function naming may conflicts: [ " .. "var" .. " ].")
        end
        if func == "self" then
            return "local function " .. func .. "("
        end
        local newName = prefix .. func
        replacementMap[func] = newName
        return "local function " .. newName .. "("
    end)

    for oldName, newName in pairs(replacementMap) do
        replacedCode = replacedCode:gsub("([^%w_])" .. oldName .. "([^%w_])", "%1" .. newName .. "%2")
        replacedCode = replacedCode:gsub("([^%w_])" .. oldName .. "$", "%1" .. newName) -- Handle end of line
    end

    return replacedCode
end
--- 获取 Lua 代码开头引用的模块
---@param code string 要处理的 Lua 代码
---@return table 引用的模块列表
local function getRequireModules(code)
    local modules = {}
    local requirePattern = [[require%s*%(?%s*["'](.-)["']%s*%)?]]

    -- 遍历代码每一行
    for line in code:gmatch("[^\r\n]+") do
        local trimmedLine = line:match("^%s*(.-)%s*$") -- 去掉首尾空白

        if trimmedLine:match("^%-%-") then
            -- 忽略注释行
        else
            -- 提取模块名
            for moduleName in trimmedLine:gmatch(requirePattern) do
                table.insert(modules, moduleName)
            end
        end
    end

    return modules
end

---生成唯一小写字母字符串前缀
---@param storage table 存储表
---@param length number 字符串长度
---@return string 唯一前缀
local function getUniqueRandomString(storage, length)
    -- 确保传入的存储表有效
    storage = storage or {}
    length = length or math.random(5, 10) -- 如果未指定长度，使用默认随机长度

    while true do
        -- 生成随机字符串
        local result = {}
        for _ = 1, length do
            table.insert(result, string.char(math.random(97, 122))) -- 生成 'a' 到 'z'
        end
        local newString = table.concat(result)

        -- 检查是否已生成过
        if not storage[newString] then
            storage[newString] = true -- 标记为已生成
            return newString .. "_"
        end
    end
end

local function processModules(modules, dir)
    local processed = {} -- 用于记录已处理的模块，避免重复处理

    -- 定义递归处理函数
    local function process(moduleName)
        -- 如果模块已处理过，则跳过
        if processed[moduleName] then
            return
        end

        -- 标记当前模块为已处理
        processed[moduleName] = true

        -- 构建模块路径
        local modulePath = dir .. moduleName .. ".lua"

        -- 尝试读取模块文件
        local file = io.open(modulePath, "r")
        if not file then
            print("[ WARN ] Module file not found: " .. modulePath)
            return
        end

        local code = file:read("*a") -- 读取文件内容
        file:close()

        -- 获取模块引用的其他模块
        local newModules = getRequireModules(code)

        -- 遍历新模块列表，添加到主列表并递归处理
        for _, newModule in ipairs(newModules) do
            if not contains(modules, newModule) then
                table.insert(modules, newModule) -- 添加到模块列表
            end
            process(newModule)                   -- 递归处理新模块
        end
    end

    -- 遍历初始模块列表并处理
    for _, moduleName in ipairs(modules) do
        process(moduleName)
    end
end

--- 生成打包信息的函数，支持添加详细信息
---@param modules table 模块名列表
---@param folder string 模块存储的文件夹路径
---@param authorName string|nil 作者名称
---@param description string|nil 打包描述信息
---@return string 打包信息字符串
local function generatePackageInfo(modules, folder, authorName, description)
    local metadata = {} -- 用于存储打包的元数据

    -- 获取当前时间
    local packageTime = os.date("%Y-%m-%d %H:%M:%S")

    -- 打包元数据
    metadata.author = authorName or "Unknown Author"
    metadata.description = description or "No description provided"
    metadata.packageTime = packageTime
    metadata.packageDir = folder

    -- 合并所有模块信息为单个字符串
    local packageInfo = {}

    -- 添加打包元数据
    table.insert(packageInfo, string.format("--[[\nPackage Information:\nAuthor: %s\nDescription: %s\nPackage Time: %s\nPackage Folder: %s\nModules: %d\n]]\n",
        metadata.author, metadata.description, metadata.packageTime, metadata.packageDir, #modules))

    -- 添加模块名列表
    table.insert(packageInfo, "-- Modules:")
    for _, moduleName in ipairs(modules) do
        table.insert(packageInfo, string.format("-- %s", moduleName))
    end

    -- 返回最终打包信息字符串
    return table.concat(packageInfo, "\n")
end

--- 移除 Lua 代码中的单行和段注释（保留以 "---" 开头的注释）
---@param code string 要处理的 Lua 源代码
---@return string 处理后的代码
local function removeComments(code)
    -- 移除多行注释（--[[ ... ]]）
    code = code:gsub("%-%-%[%[.-%]%]", "")

    -- 移除单行注释（-- ...）
    code = code:gsub("%-%-[^\n]*", "")

    return code
end

local function extractTableKeys(code)
    -- 用于存储表名和键名的结果
    local result = {}

    -- 匹配表名.key
    for tableName, key in code:gmatch('([%a_][%w_]*)%s*%.%s*([%a_][%w_]*)') do
        -- 如果表名不存在于result中，初始化它
        if not result[tableName] then
            result[tableName] = {}
        end
        -- 将key添加到表名对应的表中
        table.insert(result[tableName], key)
    end

    -- 匹配表名[key]
    for tableName, index in code:gmatch('([%a_][%w_]*)%s*%[%s*(["\'].*?["\']|[%a_][%w_]*)%s*%]') do
        -- 如果表名不存在于result中，初始化它
        if not result[tableName] then
            result[tableName] = {}
        end
        -- 将index添加到表名对应的表中
        table.insert(result[tableName], index)
    end

    return result
end

local function extractCoreVersion(code)
    -- 使用模式匹配查找 Core.VERSION 的值
    local version = code:match("Core%.CORE_VERSION%s*=%s*[\"']([^\"']+)[\"']")
    return version or "Version not found"
end

-- >>>>>>>>>>>>>>>>>>>>>>>>>>>>> 处理逻辑
-- 读取文件
local baseCode = readFileToString(srcDir, entryPointFileName)

local moduleList = {}
if baseCode then
    for _, value in ipairs(getRequireModules(baseCode)) do
        if not contains(moduleList, value) then
            table.insert(moduleList, value)
        end
    end
else
    print("[ ERROR ] File not found. " .. entryPointFileName .. ".")
    return
end

-- 加载所有关联模块
processModules(moduleList, srcDir)

local outputCode = generatePackageInfo(moduleList, srcDir, author, desc)
outputCode = outputCode .. "\n\n"

for _, value in ipairs(moduleList) do
    local moduleDefine = string.format("local %s = {}\n", value)
    outputCode = outputCode .. moduleDefine
end

local moduleDefineList = {}


-- for index, value in ipairs(moduleList) do
--     if value == "Enums" then
--         table.remove(moduleList, index)
--         table.insert(moduleList, 1, value)
--         break
--     end
-- end


for _, value in ipairs(moduleList) do
    print("[ INFO ] Processing Module ==> Current Module: " .. value .. ".")
    local moduleDefine = readFileToString(srcDir, value .. ".lua")
    if not moduleDefine then
        print("[ error ] File not Found. " .. value .. ".")
        return
    end


    -- 移除注释
    moduleDefine = removeComments(moduleDefine)

    local propertyTreeList = extractTableKeys(moduleDefine)
    local propertyList = {}
    for _, props in pairs(propertyTreeList) do
        for _, propName in ipairs(props) do
            table.insert(propertyList, propName)
        end
    end

    -- 移除模块引用
    moduleDefine = removeHeaderRequireStatements(moduleDefine)

    -- 移除模块返回语句和模块定义，枚举模块除外
    moduleDefine = removeTrailingReturn(moduleDefine, true)

    -- 枚举模块处理
    if value ~= "Enums" then
        -- 局部变量添加唯一前缀
        local prefixCache = {}
        local uniquePrefix = getUniqueRandomString(prefixCache, 5)
        moduleDefine = addPrefixToLocalVariables(moduleDefine, uniquePrefix, propertyList)
    end
    moduleDefine = moduleDefine .. "\n"
    table.insert(moduleDefineList, moduleDefine)
end

for _, value in ipairs(moduleDefineList) do
    outputCode = outputCode .. value
end

outputCode = outputCode .. removeHeaderRequireStatements(baseCode)

local version = extractCoreVersion(readFileToString(srcDir, "Core.lua"))

local fileName = outputFilePrefixName .. "_" .. version .. ".lua"
if writeStringToFile(binDir .. fileName, outputCode) then
    print("[ OK ] Done.")
end
