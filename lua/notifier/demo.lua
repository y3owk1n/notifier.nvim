-- This is an internal module for demo purposes only

local plugin = require("notifier")

local M = {}

-- Custom formatter for progress updates
local function progress_formatter(opts)
  local progress_bar = "█"
  local steps = math.floor((opts.notif._notif_formatter_data or {}).progress or 0)
  local bar = string.rep(progress_bar, steps) .. string.rep("░", 10 - steps)

  return {
    { display_text = "󰏥 ", hl_group = "Identifier", is_virtual = true },
    { display_text = opts.line, hl_group = "Normal", is_virtual = true },
    { display_text = " [", hl_group = "Comment", is_virtual = true },
    { display_text = bar, hl_group = "String", is_virtual = true },
    { display_text = "]", hl_group = "Comment", is_virtual = true },
  }
end

-- Demo sequence functions
local demo_steps = {}

-- Step 1: Welcome message
demo_steps[1] = function()
  vim.notify("Look at the bottom right now!", vim.log.levels.INFO, {
    icon = "",
    group_name = "center",
    timeout = 3000,
    id = "welcome",
  })
end

-- Step 2: Basic log levels showcase
demo_steps[2] = function()
  plugin.dismiss_all(false)
  local levels = {
    { vim.log.levels.INFO, "This is an info message" },
    { vim.log.levels.WARN, "This is a warning message" },
    { vim.log.levels.ERROR, "This is an error message" },
    { vim.log.levels.DEBUG, "This is a debug message" },
    { vim.log.levels.TRACE, "This is a trace message" },
  }

  for i, level_data in ipairs(levels) do
    vim.defer_fn(function()
      vim.notify(level_data[2], level_data[1], {
        timeout = 0,
      })
    end, (i - 1) * 800)
  end

  vim.defer_fn(function()
    plugin.dismiss_all(false)
    vim.notify("Now look at the top left corner!")
  end, 4000)
end

-- Step 3: Multiple groups demonstration
demo_steps[3] = function()
  plugin.dismiss_all(false)

  vim.notify("Top Left Corner", vim.log.levels.INFO, {
    group_name = "top-left",
    timeout = 0,
  })

  vim.defer_fn(function()
    vim.notify("Top Center Corner", vim.log.levels.INFO, {
      group_name = "top-center",
      timeout = 0,
    })
  end, 400 * 1)

  vim.defer_fn(function()
    vim.notify("Top Right Corner", vim.log.levels.INFO, {
      group_name = "top-right",
      timeout = 0,
    })
  end, 400 * 2)

  vim.defer_fn(function()
    vim.notify("Left Center Corner", vim.log.levels.INFO, {
      group_name = "left-center",
      timeout = 0,
    })
  end, 400 * 3)

  vim.defer_fn(function()
    vim.notify("True Center Corner", vim.log.levels.INFO, {
      group_name = "center",
      timeout = 0,
    })
  end, 400 * 4)

  vim.defer_fn(function()
    vim.notify("Right Center Corner", vim.log.levels.INFO, {
      group_name = "right-center",
      timeout = 0,
    })
  end, 400 * 5)

  vim.defer_fn(function()
    vim.notify("Bottom Left Corner", vim.log.levels.INFO, {
      group_name = "bottom-left",
      timeout = 0,
    })
  end, 400 * 6)

  vim.defer_fn(function()
    vim.notify("Bottom Center Corner", vim.log.levels.INFO, {
      group_name = "bottom-center",
      timeout = 0,
    })
  end, 400 * 7)

  vim.defer_fn(function()
    vim.notify("Bottom Right Corner", vim.log.levels.INFO, {
      group_name = "bottom-right",
      timeout = 0,
    })
  end, 400 * 8)
end

-- Step 4: Multi-line messages
demo_steps[4] = function()
  plugin.dismiss_all(false)

  local multiline_msg = table.concat({
    "Multi-line notifications work great!",
    "",
    "• Feature 1: Smart positioning",
    "• Feature 2: Custom formatting",
    "• Feature 3: Smooth animations",
    "",
    "Perfect for detailed information!",
  }, "\n")

  vim.notify(multiline_msg, vim.log.levels.INFO, {
    timeout = 5000,
  })
end

-- Step 5: ID-based updating
demo_steps[5] = function()
  plugin.dismiss_all(false)
  -- Initial notification
  vim.notify("Processing... 0%", vim.log.levels.INFO, {
    id = "progress",
    timeout = 0, -- No auto-dismiss
    _notif_formatter = progress_formatter,
    _notif_formatter_data = { progress = 0 },
  })

  -- Update progress
  for i = 1, 10 do
    vim.defer_fn(function()
      local percent = i * 10
      vim.notify(string.format("Processing... %d%%", percent), vim.log.levels.INFO, {
        id = "progress",
        timeout = i == 10 and 3000 or 0, -- Auto-dismiss when complete
        _notif_formatter = progress_formatter,
        _notif_formatter_data = { progress = i },
      })
    end, i * 400)
  end
end

-- Step 6: Custom icons and highlights
demo_steps[6] = function()
  plugin.dismiss_all(false)

  vim.notify("Custom icon notification", vim.log.levels.INFO, {
    icon = "󰚩 ",
    hl_group = "String",
    timeout = 3500,
  })

  vim.defer_fn(function()
    vim.notify("Another custom style", vim.log.levels.WARN, {
      icon = "󰓇 ",
      hl_group = "Identifier",
      timeout = 3500,
    })
  end, 800)

  vim.defer_fn(function()
    vim.notify("And one more!", vim.log.levels.ERROR, {
      icon = "󰙦 ",
      hl_group = "Special",
      timeout = 3500,
    })
  end, 1600)
end

-- Step 7: History demonstration
demo_steps[7] = function()
  plugin.dismiss_all(false)

  vim.notify("Let's create some history...", vim.log.levels.INFO, { timeout = 0 })

  vim.defer_fn(function()
    vim.notify("Message 1 for history", vim.log.levels.DEBUG, { timeout = 0 })
  end, 500)

  vim.defer_fn(function()
    vim.notify("Message 2 for history", vim.log.levels.WARN, { timeout = 0 })
  end, 1000)

  vim.defer_fn(function()
    vim.notify("Message 3 for history", vim.log.levels.ERROR, { timeout = 0 })
  end, 1500)

  vim.defer_fn(function()
    vim.notify("Use `:NotifierHistory` to view history!", vim.log.levels.INFO, {
      timeout = 0,
      hl_group = "Title",
    })
  end, 2000)

  vim.defer_fn(function()
    vim.cmd("NotifierHistory")
  end, 3000)

  vim.defer_fn(function()
    vim.cmd("close")
  end, 5000)
end

-- Step 8: Animation showcase with dismiss
demo_steps[8] = function()
  plugin.dismiss_all(false)

  vim.notify("Let's create some notifications quickly...", vim.log.levels.INFO)

  vim.defer_fn(function()
    -- Create multiple notifications quickly
    vim.notify("Notification 1", vim.log.levels.INFO, { timeout = 0 })
    vim.notify("Notification 2", vim.log.levels.WARN, { timeout = 0 })
    vim.notify("Notification 3", vim.log.levels.ERROR, { timeout = 0 })
    vim.notify("Notification 4", vim.log.levels.DEBUG, { timeout = 0 })
    vim.notify("Notification 5", vim.log.levels.TRACE, { timeout = 0 })
  end, 1000)

  vim.defer_fn(function()
    vim.notify("Watch them cascade out with staggered dismissal!", vim.log.levels.INFO, {
      timeout = 4000,
      hl_group = "Title",
    })
  end, 2000)

  vim.defer_fn(function()
    -- Auto-dismiss with stagger effect
    plugin.dismiss_all({ stagger = 100 })
  end, 3000)
end

-- Step 9: Final showcase
demo_steps[9] = function()
  local features_msg = table.concat({
    "󰌵 notifier.nvim features:",
    "",
    "󰉞 Multiple positioning groups",
    "󰏘 Custom formatters & icons",
    "󰑓 ID-based notification updating",
    "󰘚 Notification history viewer",
    "󰙅 Smooth fade in/out animations",
    "󰏥 Staggered dismiss animations",
    "󰤄 Configurable timeouts & styling",
    "",
    "Ready to enhance your Neovim experience!",
  }, "\n")

  vim.notify(features_msg, vim.log.levels.INFO, {
    group_name = "center",
    icon = "",
    timeout = 8000,
  })
end

-- Main demo function
function M.run_demo()
  -- Clear any existing notifications
  plugin.dismiss_all(false)

  -- Create intro message
  vim.defer_fn(function()
    vim.notify("Starting notifier.nvim demo in 3...", vim.log.levels.INFO, {
      id = "welcome",
      icon = "",
      group_name = "center",
      timeout = 2000,
      hl_group = "Title",
    })
  end, 0)

  vim.defer_fn(function()
    vim.notify("Starting notifier.nvim demo in 2...", vim.log.levels.INFO, {
      id = "welcome",
      icon = "",
      group_name = "center",
      timeout = 2000,
      hl_group = "Title",
    })
  end, 1000)

  vim.defer_fn(function()
    vim.notify("Starting notifier.nvim demo in 1...", vim.log.levels.INFO, {
      id = "welcome",
      icon = "",
      group_name = "center",
      timeout = 2000,
      hl_group = "Title",
    })
  end, 2000)

  -- Run demo steps with timing
  local step_timings = {
    3000, -- Welcome
    4000, -- Log levels
    9000, -- Multiple groups
    13000, -- Multi-line
    15000, -- Progress updates
    20000, -- Custom styling
    24000, -- History
    30000, -- Animation showcase
    35000, -- Final
  }

  for i, step_fn in ipairs(demo_steps) do
    vim.defer_fn(step_fn, step_timings[i] or (i * 3000))
  end
end

return M
