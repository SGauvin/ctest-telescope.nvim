# CTest-Telescope

`ctest-telescope` is a simple plugin that allows you to fuzzy find your unit tests with `telescope` and debug them via `nvim-dap`.

## Motivation

If you are looking for a simple solution to run C++ tests with `nvim-dap` through `ctest` without having to manually specify an executable path, this plugin might be for you.

## Installation

Install `ctest-telescope` with your preferred package manager:

### Lazy:

```lua
{
    "SGauvin/ctest-telescope.nvim",
    opts = {
        -- Your config
    }
}
```

You also must have `ctest` installed on your local machine. If `ctest` isn't available in your PATH, you can specify a path in the configuration.

## Configuration

`ctest-telescope` comes with the following defaults:

```lua
{
  -- Path to the ctest executable
  ctest_path = "ctest",

  -- Folder where your compiled executables will be found
  build_folder = "build",

  -- Configuration you would pass to require("dap").configurations.cpp
  dap_config = {
    type = "cppdbg",
    request = "launch",
  },
}
```

You can set the `dap_config` field to specify parameters you want pass to `dap`.
If you specify, `program`, `cwd`, or `args`, they will be overridden (since the goal of this plugin is to select those automatically).

### Example configuration to enable pretty-printing and stopAtEntry

```lua
require("ctest-telescope").setup({
  dap_config = {
    stopAtEntry = true,
    setupCommands = {
      {
        text = "-enable-pretty-printing",
        description = "Enable pretty printing",
        ignoreFailures = false,
      },
    },
  },
})
```

## Usage

`ctest-telescope` exports one useful function: `pick_test_and_debug`.

Here is an example on how you could integrate this in your own config:
```lua
vim.keymap.set("n", "<F5>", function()
  local dap = require("dap")
  if dap.session() == nil then
    -- Only call this on C++ and C files
    if vim.bo.filetype == "c" or vim.bo.filetype == "cpp" then
      require("ctest-telescope").pick_test_and_debug()
    end
  else
    dap.continue()
  end
end, { desc = "Debug: Start/Continue" })
```

## Troubleshooting

If this plugin isn't working for you, try to run this in your terminal: `ctest --test-dir <build_folder> --show-only=json-v1`.

Make sure your `CMakeLists.txt` is making use of `gtest_discover_tests` so that `ctest` can enumerate the available tests.

If this plugin still isn't working, feel free to make an issue or a pull request.
