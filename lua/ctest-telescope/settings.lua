---@class ctest.settings
---@field inner table
---@field update function
---@field get function

local Settings = {}
Settings.__index = Settings

---@class ctest.setting_values
---@field ctest_path string
---@field build_folder string
---@field dap_config table

---@type ctest.setting_values
local DEFAULT_SETTINGS = {
    ---Path to ctest
    ---@type string
    ctest_path = "ctest",

    ---Build folder
    ---@type string
    build_folder = "build",

    ---Dap config
    ---@type table
    dap_config = {
        type = "cppdbg",
        request = "launch",
    },
}

---@return ctest.settings
function Settings:new()
    return setmetatable({
        inner = vim.deepcopy(DEFAULT_SETTINGS),
    }, self)
end

-- Update settings in-place
---@param opts? ctest.setting_values
function Settings:update(opts)
    self.inner = vim.tbl_deep_extend("force", self.inner, opts or {})
end

-- Gets settings
---@return ctest.setting_values
function Settings:get()
    return self.inner
end

return Settings
