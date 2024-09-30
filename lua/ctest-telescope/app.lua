local Settings = require("ctest-telescope.settings")

---@class ctest.app
---@field settings ctest.settings
local App = {}
App.__index = App

---@param settings ctest.settings
---@param callback function
---@return table|nil
local get_ctest_json = function(settings)
    -- FIX: Run this command asynchronously in case the ctest command is slow
    -- vim.fn.json_decode is a vimscript function that can't get called in a lua callback
    -- A lua json library should be used

    local ctest_args = { settings:get().ctest_path, "--test-dir", settings:get().build_folder, "--show-only=json-v1" }
    vim.list_extend(ctest_args, settings:get().extra_ctest_args)
    local obj = vim.system(ctest_args, { text = true }):wait()

    if obj.code ~= 0 or obj.stdout == "" then
        error(
            "Couldn't fetch tests from build directory "
                .. settings:get().build_folder
                .. " using "
                .. settings:get().ctest_path
                .. "\n"
                .. obj.stdout
                .. "\n"
                .. obj.stderr
        )
        return
    end

    local json = vim.fn.json_decode(obj.stdout)
    if json ~= nil then
        return json
    else
        error("Couldn't decode ctest's json")
        return
    end
end

---@param json table
local get_test_list_from_json = function(json)
    local all_tests = {}

    local discovered_tests = json.tests
    for _, test in ipairs(discovered_tests) do
        local command = test.command
        if command ~= nil then
            local name = test.name
            table.insert(all_tests, name)
        end
    end

    return all_tests
end

local telescope_select_test_from_list = function(opts, tests, json, settings, callback)
    local action_state = require("telescope.actions.state")
    local actions = require("telescope.actions")
    local conf = require("telescope.config").values
    local finders = require("telescope.finders")
    local pickers = require("telescope.pickers")

    opts = opts or {}

    pickers
        .new(opts, {
            prompt_title = "Select Test",
            finder = finders.new_table({
                results = tests,
            }),
            sorter = conf.generic_sorter(opts),
            attach_mappings = function(prompt_bufnr, _)
                actions.select_default:replace(function()
                    actions.close(prompt_bufnr)
                    local selection = action_state.get_selected_entry()
                    callback(selection[1], json, settings)
                end)
                return true
            end,
        })
        :find()
end

--- @param test_name table
--- @param json table
--- @param settings ctest.settings
local run_dap_test_from_test_name = function(test_name, json, settings)
    local dap = require("dap")

    if json ~= nil then
        local discovered_tests = json.tests
        local dap_cpp_config = nil

        for _, test in ipairs(discovered_tests) do
            local command = test.command
            if command ~= nil then
                if test_name == test.name then
                    local properties = test.properties
                    local working_dir = settings:get().dap_config.cwd or vim.fn.getcwd() -- Set default working_dir to cwd
                    local program_path = table.remove(command, 1)

                    if properties ~= nil then
                        for _, property in ipairs(properties) do
                            if property.name == "WORKING_DIRECTORY" then
                                working_dir = property.value -- Update working_dir from ctest value
                                break
                            end
                        end
                    end

                    local processed_commands = {}
                    for _,arg in ipairs(command) do
                        table.insert(processed_commands, string.gsub(arg, "*", "\\*")
                        processed_commands
                    end
                    
                    local config = {
                        program = program_path,
                        cwd = working_dir,
                        args = processed_commands,
                    }

                    config = vim.tbl_deep_extend("keep", config, settings:get().dap_config)

                    local enrich_config = {
                        type = "cppdbg",
                        name = "Launch test: " .. test_name,
                        request = "launch",
                    }

                    config = vim.tbl_deep_extend("keep", config, enrich_config)

                    dap_cpp_config = config
                    break
                end
            end
        end

        if dap_cpp_config == nil then
            error("Couldn't find test to run")
        else
            dap.run(dap_cpp_config)
        end
    end
end

---A global instance of the Ctest app
---@type ctest.app
local app

---@return ctest.app
function App.get()
    if app then
        return app
    end

    local settings = Settings:new()

    app = App:new(settings)
    app:update()

    return app
end

---@param settings ctest.settings
---@return ctest.app
function App:new(settings)
    local app_local = setmetatable({
        settings = settings,
    }, self)

    return app_local
end

---@param opts? ctest.settings
function App:update(opts)
    self.settings:update(opts)
end

function App:pick_test_and_debug(opts)
    local json = get_ctest_json(self.settings)
    if json ~= nil then
        local test_list = get_test_list_from_json(json)
        telescope_select_test_from_list(opts, test_list, json, self.settings, run_dap_test_from_test_name)
    end
end

return App
