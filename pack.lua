

--- Helper function to read a file
local function read_file(file_path)
    local file = io.open(file_path, "r")
    if not file then error("Failed to open file: " .. file_path) end
    local content = file:read("*a")
    file:close()
    return content
end

--- Helper function to write to a file
local function write_file(file_path, content)
    local file = io.open(file_path, "w")
    if not file then error("Failed to write file: " .. file_path) end
    file:write(content)
    file:close()
end

--- Generate a unique module ID
local function generate_module_id(name)
    return "__module_" .. name:gsub("[%.%-]", "_") .. "__"
end

--- Parse `require` statements in the main.lua
local function parse_requires(main_content)
    local requires = {}
    for line in main_content:gmatch("(.-)\n") do
        local module_name = line:match("^%s*local%s+[%w_]+%s*=%s*require%(['\"]([%w%._%-]+)['\"]%)")
        if module_name then
            local var_name = line:match("^%s*local%s+([%w_]+)%s*=")
            if var_name then
                requires[#requires + 1] = { var_name = var_name, module_name = module_name }
            end
        end
    end
    return requires
end

--- Resolve and embed modules
local function resolve_modules(base_path, requires)
    local embedded_modules = {}
    local resolved_order = {}
    local in_progress = {}

    local function resolve_module(module_name)
        if embedded_modules[module_name] then return end
        if in_progress[module_name] then
            -- Handle circular reference by predefining the module
            if not embedded_modules[module_name] then
                local module_id = generate_module_id(module_name)
                embedded_modules[module_name] = {
                    id = module_id,
                    content = "local " .. module_id .. " = {}"
                }
                resolved_order[#resolved_order + 1] = module_name
            end
            return
        end

        in_progress[module_name] = true
        local module_path = base_path .. "/" .. module_name:gsub("%.", "/") .. ".lua"
        local module_content = read_file(module_path)

        -- Parse nested requires
        local nested_requires = parse_requires(module_content)
        for _, nested in ipairs(nested_requires) do
            resolve_module(nested.module_name)
        end

        -- Transform module content
        local module_id = generate_module_id(module_name)
        module_content = module_content:gsub("local%s+([%w_]+)", module_id .. "_%1")
        module_content = module_content:gsub("return%s+([%w_]+)", "")

        embedded_modules[module_name] = {
            id = module_id,
            content = module_content
        }
        resolved_order[#resolved_order + 1] = module_name
        in_progress[module_name] = nil
    end

    for _, req in ipairs(requires) do
        resolve_module(req.module_name)
    end

    return embedded_modules, resolved_order
end

--- Embed all modules into the new file
local function embed_modules(output_path, main_content, requires, embedded_modules, resolved_order)
    local output = {}

    -- Add placeholder definitions for all modules
    for _, module_name in ipairs(resolved_order) do
        local module_id = embedded_modules[module_name].id
        output[#output + 1] = "local " .. module_id .. " = {}"
    end

    -- Add module contents
    for _, module_name in ipairs(resolved_order) do
        local module_content = embedded_modules[module_name].content
        output[#output + 1] = module_content
    end

    -- Replace requires in main.lua
    for _, req in ipairs(requires) do
        local module_id = embedded_modules[req.module_name].id
        main_content = main_content:gsub(
            "local%s+" .. req.var_name .. "%s*=%s*require%(['\"]" .. req.module_name .. "['\"]%)",
            "local " .. req.var_name .. " = " .. module_id
        )
    end

    -- Add transformed main.lua
    output[#output + 1] = main_content

    -- Write to the output file
    write_file(output_path, table.concat(output, "\n"))
end

--- Main function
local function main()
    local base_path = "./src/"           -- Replace with your modules directory
    local main_file_path = "./src/Base.lua"     -- Replace with your main.lua file path
    local output_file_path = "output.lua" -- Replace with desired output file path

    -- Read main.lua
    local main_content = read_file(main_file_path)

    -- Parse requires
    local requires = parse_requires(main_content)

    -- Resolve and embed modules
    local embedded_modules, resolved_order = resolve_modules(base_path, requires)

    -- Generate output file
    embed_modules(output_file_path, main_content, requires, embedded_modules, resolved_order)
    print("Output written to: " .. output_file_path)
end

main()
