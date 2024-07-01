# ctest-telescope

`ctest-telescope` is a simple plugin that integrates with [CTest](https://cmake.org/cmake/help/book/mastering-cmake/chapter/Testing%20With%20CMake%20and%20CTest.html) to allows you to fuzzy find your tests with [`telescope`](https://github.com/nvim-telescope/telescope.nvim) and debug them via [`nvim-dap`](https://github.com/mfussenegger/nvim-dap).

## Motivation

If you are looking for a simple solution to run C++ tests with `nvim-dap` through `ctest` without having to manually specify an executable path, arguments, and the working directory, this plugin might be for you.

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
If you specify `program`, `cwd`, or `args`, they will be overridden (since the goal of this plugin is to select those automatically).

You can learn more about what fields are available for cppdbg [here](https://github.com/mfussenegger/nvim-dap/wiki/C-C---Rust-(gdb-via--vscode-cpptools)#configuration).

It should be possible to override `cppdbg` with [`codelldb`](https://github.com/mfussenegger/nvim-dap/wiki/C-C---Rust-(via--codelldb)) or any other debug adapter that works with C++, but this hasn't been testing yet:

```lua
dap_config = {
  type = "codelldb",
},
```

### Example configuration to enable pretty-printing and stopAtEntry

Note: If you are using `lazy.nvim`, you should pass these options to `opts` ([example](https://github.com/SGauvin/ctest-telescope.nvim?tab=readme-ov-file#lazy)) instead of explicitly passing them to `setup`.
```lua
-- Note: If you are using lazy.nvim, you should pass these options to 
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

If this plugin isn't working for you, try running this in your terminal: `ctest --test-dir <build_folder> --show-only=json-v1`.

Make sure your `CMakeLists.txt` is set up properly with automatic tests registration.
For gtest, [`gtest_discover_tests`](https://cmake.org/cmake/help/latest/module/GoogleTest.html#command:gtest_discover_tests) has to be used.
For catch2, [`catch_discover_tests`](https://github.com/catchorg/Catch2/blob/devel/docs/cmake-integration.md#automatic-test-registration) has to be used.

If this plugin still isn't working, feel free to make an issue or a pull request.

## Alternatives

If you use only gtest, don't mind having to manually specify an executable, and don't mind a bit more configuration, you might want to try [neotest-gtest](https://github.com/alfaix/neotest-gtest), as it integrates with [neotest](https://github.com/nvim-neotest/neotest).
