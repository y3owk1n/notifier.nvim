# 🔔 notifier.nvim

A modern, feature-rich notification system for Neovim that transforms the standard `vim.notify` experience with beautiful UI, smart grouping, and powerful customization options.

![Neovim](https://img.shields.io/badge/Neovim-0.10+-green.svg?style=flat-square)
![License](https://img.shields.io/badge/License-MIT-blue.svg?style=flat-square)

<https://github.com/user-attachments/assets/995187ad-1ead-412d-b6c0-dd13b2f1a8a1>

## ✨ Features

- 🎯 **Smart Positioning** - Multiple notification groups (corners) with independent management
- 🎨 **Beautiful UI** - Virtual text rendering with syntax highlighting and custom formatting
- ⏱️ **Timeout Management** - Automatic dismissal with configurable timeouts per notification
- 🔄 **ID-based Updates** - Update existing notifications instead of creating duplicates
- 📜 **History Viewer** - Browse all active notifications in a scrollable floating window
- 🎭 **Custom Formatters** - Create your own notification layouts and styling
- ⚡ **High Performance** - Debounced rendering and efficient virtual text handling
- 🎛️ **Fully Configurable** - Every aspect customizable through comprehensive options

## 📦 Installation

### Using [lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
{
  "y3owk1n/notifier.nvim",
  config = function()
    require("notifier").setup({
      -- your configuration here
    })
  end
}
```

Then in your `init.lua`:

```lua
require("notifier").setup()
```

## 🚀 Quick Start

```lua
-- Basic setup with defaults
require("notifier").setup()

-- Now use enhanced vim.notify
vim.notify("Hello, World!")
vim.notify("Warning message", vim.log.levels.WARN)
vim.notify("Error occurred", vim.log.levels.ERROR)
```

## ⚙️ Configuration

### Default Configuration

```lua
require("notifier").setup({
  -- Notification timeout in milliseconds
  default_timeout = 3000,

  -- Border style for floating windows
  border = "none", -- "none", "single", "double", "rounded", "solid", "shadow"

  -- Padding around notification content
  padding = {
    top = 0,
    right = 0,
    bottom = 0,
    left = 0
  },

  -- Default notification group
  default_group = "bottom-right",

  -- Group positioning configurations
  group_configs = {
    ["bottom-right"] = {
      anchor = "SE",
      row = vim.o.lines - 2,
      col = vim.o.columns,
      winblend = 0, -- 0-100 transparency
    },
    ["top-right"] = {
      anchor = "NE",
      row = 0,
      col = vim.o.columns,
      winblend = 0,
    },
    ["top-left"] = {
      anchor = "NW",
      row = 0,
      col = 0,
      winblend = 0,
    },
    ["bottom-left"] = {
      anchor = "SW",
      row = vim.o.lines - 2,
      col = 0,
      winblend = 0,
    },
  },

  -- Icons for different log levels
  icons = {
    [vim.log.levels.TRACE] = "󰔚 ",
    [vim.log.levels.DEBUG] = " ",
    [vim.log.levels.INFO] = " ",
    [vim.log.levels.WARN] = " ",
    [vim.log.levels.ERROR] = " ",
  }

  -- Formatters
  notif_formatter = nil,
  notif_history_formatter = nil,

  -- Animation
  animation = {
    enabled = false, -- animation is off by default
    fade_in_duration = 300,
    fade_out_duration = 300,
  },
})
```

### Custom Styling Example

```lua
require("notifier").setup({
  default_timeout = 5000,
  border = "rounded",
  padding = { top = 1, right = 2, bottom = 1, left = 2 },

  group_configs = {
    ["bottom-right"] = {
      anchor = "SE",
      row = vim.o.lines - 3, -- Leave more space from bottom
      col = vim.o.columns - 1,
      winblend = 20, -- Semi-transparent
    }
  },

  -- Custom icons
  icons = {
    [vim.log.levels.ERROR] = "✗ ",
    [vim.log.levels.WARN] = "⚠ ",
    [vim.log.levels.INFO] = "ℹ ",
    [vim.log.levels.DEBUG] = "🐛 ",
    [vim.log.levels.TRACE] = "👁 ",
  }
})
```

## 📖 Usage Examples

### Basic Notifications

```lua
-- Simple notification
vim.notify("Task completed successfully!")

-- With log level
vim.notify("Configuration reloaded", vim.log.levels.INFO)

-- Multi-line message
vim.notify("Build failed:\n- Syntax error on line 42\n- Missing dependency")
```

<https://github.com/user-attachments/assets/f2c0baac-665f-4930-ac35-45dde5540343>

### Advanced Options with Data and Inline Formatters

```lua
-- Notification with custom timeout and icon
vim.notify("Long running task started", vim.log.levels.INFO, {
  timeout = 10000, -- 10 seconds
  icon = "⏳ "
})

-- Target specific group
vim.notify("Debug info", vim.log.levels.DEBUG, {
  group_name = "top-left",
  timeout = 0 -- Always there unless manually dismissed
})

-- Updateable notification with ID
vim.notify("Downloading... 0%", vim.log.levels.INFO, {
  id = "download-progress"
})

-- Update the same notification
vim.notify("Downloading... 50%", vim.log.levels.INFO, {
  id = "download-progress" -- Same ID updates existing
})

vim.notify("Download complete!", vim.log.levels.INFO, {
  id = "download-progress"
})

-- Inline formatter with custom data - no message needed!
vim.notify("", vim.log.levels.INFO, {
  id = "server-status",
  _notif_formatter = function(opts)
    local data = opts.notif._notif_formatter_data
    local status_icon = data.online and "🟢" or "🔴"
    local status_text = data.online and "ONLINE" or "OFFLINE"
    local status_color = data.online and "String" or "ErrorMsg"

    return {
      { display_text = "🖥️  Server ", hl_group = "NotifierInfo", is_virtual = true },
      { display_text = data.name, hl_group = "Identifier", is_virtual = true },
      { display_text = " " .. status_icon .. " ", hl_group = status_color, is_virtual = true },
      { display_text = status_text, hl_group = status_color, is_virtual = true },
      data.uptime and { display_text = " (up " .. data.uptime .. ")", hl_group = "Comment", is_virtual = true } or nil,
    }
  end,
  _notif_formatter_data = {
    name = "prod-api-01",
    online = true,
    uptime = "2d 5h"
  }
})

-- Update server status with new data
vim.notify("", vim.log.levels.WARN, {
  id = "server-status", -- Same ID updates the notification
  _notif_formatter_data = {
    name = "prod-api-01",
    online = false,
    uptime = nil
  }
})
```

<https://github.com/user-attachments/assets/90a2a491-e1af-4fee-8fe4-89d59748cf00>

### Custom Highlight Groups

```lua
-- Use custom highlight group
vim.notify("Special message", vim.log.levels.INFO, {
  hl_group = "MyCustomHighlight"
})
```

Define your highlight group:

```lua
vim.api.nvim_set_hl(0, "MyCustomHighlight", {
  fg = "#ff6b6b",
  bold = true
})
```

## 🎨 Custom Formatters

Create your own notification layouts with powerful formatting options:

### Global Custom Formatter

```lua
-- Custom formatter function
local function my_formatter(opts)
  local notif = opts.notif
  local line = opts.line
  local config = opts.config

  return {
    { display_text = ">> ", hl_group = "Comment", is_virtual = true },
    { display_text = line, hl_group = notif.hl_group, is_virtual = true },
    { display_text = " <<", hl_group = "Comment", is_virtual = true },
  }
end

require("notifier").setup({
  notif_formatter = my_formatter
})
```

<https://github.com/user-attachments/assets/562c19c1-93d0-43c6-a4be-ede562ae6437>

### Inline Custom Formatters with Data

Pass custom data and formatters for specific notifications:

```lua
-- Progress bar formatter with custom data
vim.notify("", vim.log.levels.INFO, {
  id = "progress-bar",
  timeout = 10000,
  _notif_formatter = function(opts)
    local data = opts.notif._notif_formatter_data
    local progress = data.progress or 0
    local task = data.task or "Processing"
    local total_width = 20
    local filled = math.floor((progress / 100) * total_width)
    local empty = total_width - filled

    local bar = "█" .. string.rep("█", filled) .. string.rep("░", empty) .. "█"
    local percentage = string.format("%3d%%", progress)

    return {
      { display_text = data.icon or "⏳ ", hl_group = "NotifierInfo", is_virtual = true },
      { display_text = task .. ": ", hl_group = "NotifierInfo", is_virtual = true },
      { display_text = bar, hl_group = progress == 100 and "NotifierInfo" or "Comment", is_virtual = true },
      { display_text = " " .. percentage, hl_group = "NotifierInfo", is_virtual = true },
    }
  end,
  _notif_formatter_data = {
    progress = 45,
    task = "Downloading files",
    icon = "📥 "
  }
})

-- Update progress (same ID with new data)
vim.notify("", vim.log.levels.INFO, {
  id = "progress-bar",
  _notif_formatter_data = {
    progress = 75,
    task = "Downloading files",
    icon = "📥 "
  }
})

-- Complete
vim.notify("", vim.log.levels.INFO, {
  id = "progress-bar",
  timeout = 3000,
  _notif_formatter_data = {
    progress = 100,
    task = "Download complete",
    icon = "✅ "
  }
})
```

<https://github.com/user-attachments/assets/06145f69-6440-438c-a68a-9e0e5ef00853>

### Advanced Data-Driven Formatters

```lua
-- Git status formatter with rich data
vim.notify("", vim.log.levels.INFO, {
  id = "git-status",
  timeout = 8000,
  _notif_formatter = function(opts)
    local data = opts.notif._notif_formatter_data
    local parts = {}

    -- Title
    table.insert(parts, { display_text = "🌿 Git Status", hl_group = "NotifierInfo", is_virtual = true })

    if data.branch then
      table.insert(parts, { display_text = " on ", hl_group = "Comment", is_virtual = true })
      table.insert(parts, { display_text = data.branch, hl_group = "String", is_virtual = true })
    end

    -- Stats with colors
    if data.added and data.added > 0 then
      table.insert(parts, { display_text = " +" .. data.added, hl_group = "diffAdded", is_virtual = true })
    end

    if data.modified and data.modified > 0 then
      table.insert(parts, { display_text = " ~" .. data.modified, hl_group = "diffChanged", is_virtual = true })
    end

    if data.deleted and data.deleted > 0 then
      table.insert(parts, { display_text = " -" .. data.deleted, hl_group = "diffRemoved", is_virtual = true })
    end

    return parts
  end,
  _notif_formatter_data = {
    branch = "feature/new-ui",
    added = 5,
    modified = 3,
    deleted = 1
  }
})

-- LSP diagnostic summary formatter
vim.notify("", vim.log.levels.WARN, {
  id = "lsp-diagnostics",
  _notif_formatter = function(opts)
    local data = opts.notif._notif_formatter_data
    local parts = {
      { display_text = "🔍 Diagnostics: ", hl_group = "NotifierInfo", is_virtual = true }
    }

    if data.errors > 0 then
      table.insert(parts, { display_text = " " .. data.errors, hl_group = "DiagnosticError", is_virtual = true })
    end
    if data.warnings > 0 then
      table.insert(parts, { display_text = " " .. data.warnings, hl_group = "DiagnosticWarn", is_virtual = true })
    end
    if data.info > 0 then
      table.insert(parts, { display_text = "ℹ " .. data.info, hl_group = "DiagnosticInfo", is_virtual = true })
    end
    if data.hints > 0 then
      table.insert(parts, { display_text = " " .. data.hints, hl_group = "DiagnosticHint", is_virtual = true })
    end

    return parts
  end,
  _notif_formatter_data = {
    errors = 2,
    warnings = 5,
    info = 3,
    hints = 1
  }
})

-- Build status with timing information
vim.notify("", vim.log.levels.INFO, {
  id = "build-status",
  _notif_formatter = function(opts)
    local data = opts.notif._notif_formatter_data
    local icon = data.status == "success" and "✅" or
                 data.status == "error" and "❌" or "⏳"
    local color = data.status == "success" and "NotifierInfo" or
                  data.status == "error" and "NotifierError" or "NotifierWarn"

    return {
      { display_text = icon .. " Build ", hl_group = color, is_virtual = true },
      { display_text = data.status, hl_group = color, is_virtual = true },
      data.duration and { display_text = " (" .. data.duration .. "s)", hl_group = "Comment", is_virtual = true } or nil,
      data.target and { display_text = " [" .. data.target .. "]", hl_group = "Identifier", is_virtual = true } or nil,
    }
  end,
  _notif_formatter_data = {
    status = "success",
    duration = 2.5,
    target = "release"
  }
})
```

<https://github.com/user-attachments/assets/cb70c877-18ea-4d0f-a78a-471d09b839fa>

### Real-World Integration Examples

```lua
-- Function to update download progress with rich visualization
local function update_download_progress(filename, current, total)
  local progress = math.floor((current / total) * 100)
  local speed = current > 0 and string.format("%.1f MB/s", (current / 1024 / 1024)) or "0 MB/s"

  vim.notify("", vim.log.levels.INFO, {
    id = "download-" .. filename,
    timeout = progress == 100 and 3000 or 15000,
    _notif_formatter = function(opts)
      local data = opts.notif._notif_formatter_data
      local bar_width = 25
      local filled = math.floor((data.progress / 100) * bar_width)
      local bar = string.rep("█", filled) .. string.rep("▒", bar_width - filled)

      return {
        { display_text = "📁 ", hl_group = "Directory", is_virtual = true },
        { display_text = data.filename, hl_group = "NotifierInfo", is_virtual = true },
        { display_text = " [", hl_group = "Comment", is_virtual = true },
        { display_text = bar, hl_group = data.progress == 100 and "String" or "Comment", is_virtual = true },
        { display_text = "] ", hl_group = "Comment", is_virtual = true },
        { display_text = data.progress .. "%", hl_group = "Number", is_virtual = true },
        { display_text = " @ " .. data.speed, hl_group = "Comment", is_virtual = true },
      }
    end,
    _notif_formatter_data = {
      filename = filename,
      progress = progress,
      current = current,
      total = total,
      speed = speed
    }
  })
end

-- Usage
update_download_progress("large-file.zip", 0, 100)      -- 0%
update_download_progress("large-file.zip", 50, 100)     -- 50%
update_download_progress("large-file.zip", 100, 100)    -- 100%
```

<https://github.com/user-attachments/assets/75eaba94-4b71-41a4-8969-ccb9c62ce06d>

## 🔧 Commands and Functions

### Core Functions

```lua
-- Show notification history
require("notifier").show_history()

-- Dismiss all notifications immediately
require("notifier").dismiss_all()
```

### Keybindings Example

```lua
-- Add to your init.lua
vim.keymap.set("n", "<leader>nh", function()
  require("notifier").show_history()
end, { desc = "Show notification history" })

vim.keymap.set("n", "<leader>nd", function()
  require("notifier").dismiss_all()
end, { desc = "Dismiss all notifications" })
```

## 🎯 Notification Groups

Organize notifications by positioning them in different screen areas:

```lua
-- Bottom right (default)
vim.notify("System ready", vim.log.levels.INFO)

-- Top right for less intrusive messages
vim.notify("Background task completed", vim.log.levels.INFO, {
  group_name = "top-right"
})

-- Top left for debug information
vim.notify("Variable value: " .. tostring(value), vim.log.levels.DEBUG, {
  group_name = "top-left"
})

-- Bottom left for status updates
vim.notify("Syncing files...", vim.log.levels.INFO, {
  group_name = "bottom-left",
  id = "sync-status"
})
```

## 🎨 Highlight Groups

Customize colors by overriding these highlight groups:

```lua
-- Main notification styling
vim.api.nvim_set_hl(0, "NotifierNormal", { bg = "#1a1a1a", fg = "#ffffff" })
vim.api.nvim_set_hl(0, "NotifierBorder", { fg = "#444444" })

-- Level-specific colors
vim.api.nvim_set_hl(0, "NotifierError", { fg = "#ff6b6b", bold = true })
vim.api.nvim_set_hl(0, "NotifierWarn", { fg = "#feca57", bold = true })
vim.api.nvim_set_hl(0, "NotifierInfo", { fg = "#48cae4" })
vim.api.nvim_set_hl(0, "NotifierDebug", { fg = "#a8a8a8" })
vim.api.nvim_set_hl(0, "NotifierTrace", { fg = "#6c757d" })

-- History window styling
vim.api.nvim_set_hl(0, "NotifierHistoryNormal", { bg = "#0d1117" })
vim.api.nvim_set_hl(0, "NotifierHistoryBorder", { fg = "#30363d" })
vim.api.nvim_set_hl(0, "NotifierHistoryTitle", { fg = "#f0f6fc", bold = true })
```

## 📱 Integration Examples

### LSP Progress Notifications with Rich Data

```lua
-- Enhanced LSP progress with inline formatters

---Setup a progress spinner for LSP.
---@return nil
local function setup_progress_spinner_custom()
  local spinner_chars = { "⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏" }
  local last_spinner = 0
  local spinner_idx = 1

  ---@type table<string, uv.uv_timer_t|nil>
  local active_timers = {}

  vim.lsp.handlers["$/progress"] = function(_, result, ctx)
    local client = vim.lsp.get_client_by_id(ctx.client_id)
    if not client or type(result.value) ~= "table" then
      return
    end

    local value = result.value
    local token = result.token
    local is_complete = value.kind == "end"
    local has_percentage = value.percentage ~= nil

    local function render()
      local progress_data = {
        percentage = value.percentage or nil,
        description = value.title or "Loading workspace",
        file_progress = value.message or nil,
      }

      if is_complete then
        progress_data.description = "Done"
        progress_data.file_progress = nil
      end

      local icon
      if is_complete then
        icon = " "
      else
        local now = vim.uv.hrtime()
        if now - last_spinner > 80e6 then
          spinner_idx = (spinner_idx % #spinner_chars) + 1
          last_spinner = now
        end
        icon = spinner_chars[spinner_idx]
      end

      vim.notify("", vim.log.levels.INFO, {
        id = string.format("lsp_progress_%s_%s", client.name, token),
        title = client.name,
        _notif_formatter = function(opts)
          local notif = opts.notif
          local _notif_formatter_data = notif._notif_formatter_data

          if not _notif_formatter_data then
            return {}
          end

          local separator = { display_text = " " }

          local icon_hl = notif.hl_group or opts.log_level_map[notif.level].hl_group

          local percent_text = _notif_formatter_data.percentage
              and string.format("%3d%%", _notif_formatter_data.percentage)
            or nil

          local description_text = _notif_formatter_data.description

          local file_progress_text = _notif_formatter_data.file_progress or nil

          local client_name = client.name

          ---@type Notifier.FormattedNotifOpts[]
          local entries = {}

          if icon then
            table.insert(entries, { display_text = icon, hl_group = icon_hl })
            table.insert(entries, separator)
          end

          if percent_text then
            table.insert(entries, { display_text = percent_text, hl_group = "CmdHistoryIdentifier" })
            table.insert(entries, separator)
          end

          table.insert(entries, { display_text = description_text, hl_group = "Comment" })

          if file_progress_text then
            table.insert(entries, separator)
            table.insert(entries, { display_text = file_progress_text, hl_group = "Removed" })
          end

          if client_name then
            table.insert(entries, separator)
            table.insert(entries, { display_text = client_name, hl_group = "ErrorMsg" })
          end

          return entries
        end,
        _notif_formatter_data = progress_data,
      })
    end

    render()

    if not has_percentage then
      if not is_complete then
        local timer = active_timers[token]
        if not timer or timer:is_closing() then
          timer = vim.uv.new_timer()
          active_timers[token] = timer
        end

        if timer then
          timer:start(0, 150, function()
            vim.schedule(render)
          end)
        end
      else
        local timer = active_timers[token]
        if timer and not timer:is_closing() then
          timer:stop()
          timer:close()
          active_timers[token] = nil
        end
        vim.schedule(render)
      end
    end
  end
end
```

### Git Integration with Data Formatting

```lua
-- Git status with rich formatting and data
local function show_git_status(branch, stats)
  vim.notify("", vim.log.levels.INFO, {
    id = "git-status",
    timeout = 8000,
    _notif_formatter = function(opts)
      local data = opts.notif._notif_formatter_data
      local parts = {
        { display_text = "🌿 ", hl_group = "String", is_virtual = true },
        { display_text = data.branch, hl_group = "Identifier", is_virtual = true },
      }

      if data.stats.ahead > 0 then
        table.insert(parts, { display_text = " ↑" .. data.stats.ahead, hl_group = "diffAdded", is_virtual = true })
      end

      if data.stats.behind > 0 then
        table.insert(parts, { display_text = " ↓" .. data.stats.behind, hl_group = "diffRemoved", is_virtual = true })
      end

      if data.stats.modified > 0 then
        table.insert(parts, { display_text = " ~" .. data.stats.modified, hl_group = "diffChanged", is_virtual = true })
      end

      if data.stats.untracked > 0 then
        table.insert(parts, { display_text = " +" .. data.stats.untracked, hl_group = "diffAdded", is_virtual = true })
      end

      return parts
    end,
    _notif_formatter_data = {
      branch = branch,
      stats = stats
    }
  })
end

-- Usage
show_git_status("main", { ahead = 2, behind = 0, modified = 3, untracked = 1 })

-- Test results with detailed breakdown
vim.notify("", vim.log.levels.INFO, {
  id = "test-results",
  timeout = 10000,
  _notif_formatter = function(opts)
    local data = opts.notif._notif_formatter_data
    local icon = data.passed == data.total and "✅" or "❌"
    local color = data.passed == data.total and "String" or "ErrorMsg"

    return {
      { display_text = icon .. " Tests: ", hl_group = color, is_virtual = true },
      { display_text = data.passed .. "/" .. data.total, hl_group = color, is_virtual = true },
      { display_text = " passed", hl_group = "Comment", is_virtual = true },
      data.duration and { display_text = " (" .. data.duration .. "ms)", hl_group = "Comment", is_virtual = true } or nil,
      data.coverage and { display_text = " " .. data.coverage .. "% coverage", hl_group = "Number", is_virtual = true } or nil,
    }
  end,
  _notif_formatter_data = {
    passed = 45,
    total = 48,
    duration = 2340,
    coverage = 87.5
  }
})
```

## 📋 Requirements

- Neovim 0.10+
- A terminal that supports Unicode icons (optional, for best experience)

## 🐛 Troubleshooting

### Common Issues

**Notifications not showing:**

- Ensure you've called `require("notifier").setup()`
- Check that your Neovim version is 0.10+

**Icons not displaying:**

- Install a Nerd Font and set it as your terminal font
- Or customize the `icons` config with plain text alternatives

**Performance issues:**

- Reduce `default_timeout` for faster cleanup
- Consider using fewer notification groups

**Window positioning problems:**

- Adjust `row` and `col` values in `group_configs`
- Check your terminal size with `:echo &columns` and `:echo &lines`

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request. For major changes, please open an issue first to discuss what you would like to change.
