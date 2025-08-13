---@module "notifier"

---@brief [[
---*notifier.nvim* Smart notification system for Neovim
---*Notifier*
---
---Features:
--- - Multiple notification groups with configurable positioning
--- - Custom formatters for notifications and history
--- - Timeout-based automatic dismissal
--- - Virtual text rendering with highlights
--- - Notification history viewer
--- - ID-based notification updating
--- - Configurable padding and styling
---
---# Setup ~
---
---This module needs to be set up with `require('notifier').setup({})` (replace
---`{}` with your `config` table).
---
---# Highlighting ~
---
---Plugin defines several highlight groups:
--- - `NotifierNormal` - for notification floating window (linked to `NormalFloat`)
--- - `NotifierBorder` - for notification floating window border (linked to `FloatBorder`)
--- - `NotifierTitle` - for notification floating window title (linked to `FloatTitle`)
--- - `NotifierError` - for notifications with level `ERROR` (linked to `ErrorMsg`)
--- - `NotifierWarn` - for notifications with level `WARN` (linked to `WarningMsg`)
--- - `NotifierInfo` - for notifications with level `INFO` (linked to `MoreMsg`)
--- - `NotifierDebug` - for notifications with level `DEBUG` (linked to `Debug`)
--- - `NotifierTrace` - for notifications with level `TRACE` (linked to `Comment`)
--- - `NotifierHistoryNormal` - for notification history floating window (linked to `NormalFloat`)
--- - `NotifierHistoryBorder` - for notification history floating window border (linked to `FloatBorder`)
--- - `NotifierHistoryTitle` - for notification history floating window title (linked to `FloatTitle`)
---
---To change any highlight group, modify it directly with |:highlight|.
---
---@brief ]]

---@toc notifier.contents

---@mod notifier.setup Setup

---@brief [[
---# Module setup ~
---
--->lua
---   require('notifier').setup() -- use default config
---   -- OR
---   require('notifier').setup({}) -- replace {} with your config table
---<
---
---see also |notifier.setup()|
---@brief ]]

---@mod notifier.config Configuration

---@brief [[
---# Module config ~
---
---Default values:
---{
---  default_timeout = 3000,
---  resize_debounce_ms = 150,
---  border = "none",
---  winblend = 0,
---  padding = { top = 0, right = 0, bottom = 0, left = 0 },
---  default_group = "bottom-right",
---  group_configs = {
---    ["top-left"] = {
---      anchor = "NW",
---      row = function()
---        return 0
---      end,
---      col = function()
---        return 0
---      end,
---    },
---    ["top-center"] = {
---      anchor = "NW",
---      row = function()
---        return 0
---      end,
---      col = function()
---        return vim.o.columns / 2
---      end,
---      center_mode = "horizontal", -- Center horizontally only
---    },
---    ["top-right"] = {
---      anchor = "NE",
---      row = function()
---        return 0
---      end,
---      col = function()
---        return vim.o.columns
---      end,
---    },
---    ["left-center"] = {
---      anchor = "NW",
---      row = function()
---        return vim.o.lines / 2
---      end,
---      col = function()
---        return 0
---      end,
---      center_mode = "vertical", -- Center vertically only
---    },
---    ["center"] = {
---      anchor = "NW",
---      row = function()
---        return vim.o.lines / 2
---      end,
---      col = function()
---        return vim.o.columns / 2
---      end,
---      center_mode = "true", -- Center both horizontally and vertically
---    },
---    ["right-center"] = {
---      anchor = "NE",
---      row = function()
---        return vim.o.lines / 2
---      end,
---      col = function()
---        return vim.o.columns
---      end,
---      center_mode = "vertical", -- Center vertically only
---    },
---    ["bottom-left"] = {
---      anchor = "SW",
---      row = function()
---        return vim.o.lines - 2
---      end,
---      col = function()
---        return 0
---      end,
---    },
---    ["bottom-center"] = {
---      anchor = "SW",
---      row = function()
---        return vim.o.lines - 2
---      end,
---      col = function()
---        return vim.o.columns / 2
---      end,
---      center_mode = "horizontal", -- Center horizontally only
---    },
---    ["bottom-right"] = {
---      anchor = "SE",
---      row = function()
---        return vim.o.lines - 2
---      end,
---      col = function()
---        return vim.o.columns
---      end,
---    },
---  },
---  width = {
---    min_width = 20, -- Minimum notification width
---    max_width = nil, -- Maximum width (nil = auto-calculate)
---    preferred_width = 50, -- Preferred width when content fits
---    max_width_percentage = 0.4, -- Maximum width as percentage of screen
---    adaptive = true, -- Automatically adjust width based on content
---    wrap_text = true, -- Enable text wrapping for long lines
---    wrap_at_words = true, -- Wrap at word boundaries when possible
---  },
---  icons = {
---    [vim.log.levels.TRACE] = "󰔚 ",
---    [vim.log.levels.DEBUG] = " ",
---    [vim.log.levels.INFO] = " ",
---    [vim.log.levels.WARN] = " ",
---    [vim.log.levels.ERROR] = " ",
---  },
---  notif_formatter = U.default_notif_formatter,
---  notif_history_formatter = U.default_notif_history_formatter,
---  animation = {
---    enabled = false,
---    fade_in_duration = 300,
---    fade_out_duration = 300,
---  },
---}
---
---## Group positioning ~
---
---Configure different notification groups for various positions:
--->lua
---   require('notifier').setup({
---     group_configs = {
---       ["bottom-right"] = {
---         anchor = "SE",
---         row = function() return vim.o.lines - 2 end,
---         col = function() return vim.o.columns end,
---         winblend = 20,
---       },
---       ["top-center"] = {
---         anchor = "N",
---         row = function() return 1 end,
---         col = function() return vim.o.columns / 2 end,
---         winblend = 0,
---       }
---     }
---   })
---<
---
---## Custom formatters ~
---
---Override default notification formatting:
--->lua
---   require('notifier').setup({
---     notif_formatter = function(opts)
---       return {
---         { display_text = "[CUSTOM] " .. opts.line, hl_group = "Special", is_virtual = true }
---       }
---     end
---   })
---<
---
---## Timeout configuration ~
---
---Set global and per-notification timeouts:
--->lua
---   require('notifier').setup({
---     default_timeout = 5000, -- 5 seconds default
---   })
---
---   -- Per-notification timeout
---   vim.notify("Long message", vim.log.levels.INFO, { timeout = 10000 })
---<
---@brief ]]

---@mod notifier.commands Commands

---@tag :NotifierHistory

---@brief [[
---# Show notification history ~
---
---Display all active notifications in a floating window with timestamps
---and enhanced formatting.
---
--->vim
---   :NotifierHistory    " Show notification history
---<
---@brief ]]

---@tag :NotifierDismiss

---@brief [[
---# Dismiss all active notifications immediately or with animation ~
---
---Immediately close all active notification windows or animate them out.
---
--->vim
---   :NotifierDismiss    " Dismiss all notifications
---   :NotifierDismiss stagger=50 animated    " Dismiss all notifications with stagger and animation
---   :NotifierDismiss immediate    " Dismiss all notifications immediately
---<
---@brief ]]

local M = {}

-- ============================================================================
-- ENVIRONMENT VALIDATION & SETUP
-- ============================================================================

local ok, uv = pcall(function()
  return vim.uv or vim.loop
end)
if not ok or uv == nil then
  error("Notifier.nvim: libuv not available")
end

local nvim = vim.version()
if nvim.major == 0 and (nvim.minor < 10 or (nvim.minor == 10 and nvim.patch < 0)) then
  error("Notifier.nvim requires Neovim 0.10+")
end

---@private
---Flag to prevent setup from running multiple times
local setup_complete = false

-- ============================================================================
-- TYPE DEFINITIONS
-- ============================================================================

---@mod notifier.types Types

---Represents a single notification entry with display and metadata information.
---@class Notifier.Notification
---@field id? string|number Unique identifier for updating existing notifications
---@field msg? string Message content to display (can contain newlines)
---@field icon? string Custom icon to display (overrides default level icons)
---@field level? integer Log level from vim.log.levels (defaults to INFO)
---@field timeout? integer Timeout in milliseconds before auto-dismissal, set to 0 for no timeout
---@field created_at? number Unix timestamp when notification was first created
---@field updated_at? number Unix timestamp when notification was last updated
---@field hl_group? string Custom highlight group for the notification text
---@field group_name? Notifier.GroupConfigsKey Target group for positioning
---@field _expired? boolean Internal flag marking notification as expired
---@field _notif_formatter? fun(opts: Notifier.NotificationFormatterOpts): Notifier.FormattedNotifOpts[] Custom formatter
---@field _notif_formatter_data? table Arbitrary data passed to custom formatter
---@field _animating? boolean Internal flag marking notification as animating
---@field _animation_alpha? number Animation alpha value (0-1)

---Internal group state management for notification positioning.
---@class Notifier.Group
---@field name string Group identifier matching config keys
---@field buf integer Buffer handle for the floating window
---@field win integer Window handle for the notification display
---@field notifications Notifier.Notification[] Array of all notifications in this group
---@field config Notifier.GroupConfigs Configuration settings for this group

---@alias Notifier.GroupConfigsKey
---| '"bottom-right"'
---| '"top-right"'
---| '"top-left"'
---| '"bottom-left"'
---| '"center"'
---| '"top-center"'
---| '"bottom-center"'
---| '"left-center"'
---| '"right-center"'

---Group positioning and display configuration.
---@class Notifier.GroupConfigs
---@field anchor '"NW"'|'"NE"'|'"SW"'|'"SE"' Window anchor point for positioning
---@field row fun(): integer Row position relative to the editor
---@field col fun(): integer Column position relative to the editor
---@field _cached_row? integer Cached row position relative to the editor, for internal use only
---@field _cached_col? integer Cached column position relative to the editor, for internal use only
---@field winblend? integer Window transparency (0-100, default: 0)
---@field center_mode? '"true"'|'"horizontal"'|'"vertical"' Enable center positioning calculations

---Padding configuration for notification windows.
---@class Notifier.Config.Padding
---@field top? integer Top padding in characters (default: 0)
---@field right? integer Right padding in characters (default: 0)
---@field bottom? integer Bottom padding in characters (default: 0)
---@field left? integer Left padding in characters (default: 0)

---Raw formatted notification piece before position computation.
---@class Notifier.FormattedNotifOpts
---@field display_text string The text content to display
---@field hl_group? string Highlight group to apply to this text segment
---@field is_virtual? boolean Whether this text should be rendered as virtual text

---Computed line piece with calculated positions for rendering.
---@class Notifier.ComputedLineOpts : Notifier.FormattedNotifOpts
---@field col_start? number Starting column position (0-indexed)
---@field col_end? number Ending column position (0-indexed)
---@field virtual_col_start? number Starting virtual column position
---@field virtual_col_end? number Ending virtual column position

---Parameters passed to notification formatter functions.
---@class Notifier.NotificationFormatterOpts
---@field notif Notifier.Notification The notification being formatted
---@field line string Current line of the notification message
---@field config Notifier.Config Current plugin configuration
---@field log_level_map Notifier.LogLevelMap Log level to display property mapping

---Mapping of log level to display properties.
---@class Notifier.LogLevelEntry
---@field level_key string String representation of the level
---@field hl_group string Default highlight group for this level

---@alias Notifier.LogLevelMap table<integer, Notifier.LogLevelEntry>

---Main plugin configuration table.
---@class Notifier.Config
---@field default_timeout? integer Default timeout in milliseconds (default: 3000)
---@field resize_debounce_ms? integer Debounce time for window resize events (default: 150)
---@field border? string Border style for floating windows (default: "none")
---@field winblend? integer Window transparency (0-100, default: 0)
---@field icons? table<integer, string> Icons for each log level (keys are vim.log.levels values)
---@field notif_formatter? fun(opts: Notifier.NotificationFormatterOpts): Notifier.FormattedNotifOpts[] Function to format live notifications
---@field notif_history_formatter? fun(opts: Notifier.NotificationFormatterOpts): Notifier.FormattedNotifOpts[] Function to format notifications in history view
---@field padding? Notifier.Config.Padding Padding configuration for notification windows
---@field default_group? Notifier.GroupConfigsKey Default group for notifications without explicit group
---@field group_configs? table<Notifier.GroupConfigsKey, Notifier.GroupConfigs> Configuration for each notification group
---@field animation? Notifier.Config.Animation Animation configuration
---@field width? Notifier.Config.Width Width configuration

---@class Notifier.Config.Width
---@field min_width? integer Minimum notification width (default: 20)
---@field max_width? integer Maximum width (nil = auto-calculate) (default: nil)
---@field preferred_width? integer Preferred width when content fits (default: 50)
---@field max_width_percentage? number Maximum width as percentage of screen (default: 0.4)
---@field adaptive? boolean Automatically adjust width based on content (default: true)
---@field wrap_text? boolean Enable text wrapping for long lines (default: true)
---@field wrap_at_words? boolean Wrap at word boundaries when possible (default: true)

---Animation configuration.
---@class Notifier.Config.Animation
---@field enabled? boolean Whether animations are enabled (default: false)
---@field fade_in_duration? integer Duration of fade in animations in milliseconds (default: 300)
---@field fade_out_duration? integer Duration of fade out animations in milliseconds (default: 300)

-- ============================================================================
-- CONSTANTS & GLOBAL STATE
-- ============================================================================

---Log level to display property mapping
---@type Notifier.LogLevelMap
local log_level_map = {
  [vim.log.levels.ERROR] = {
    level_key = "ERROR",
    hl_group = "NotifierError",
  },
  [vim.log.levels.WARN] = {
    level_key = "WARN",
    hl_group = "NotifierWarn",
  },
  [vim.log.levels.INFO] = {
    level_key = "INFO",
    hl_group = "NotifierInfo",
  },
  [vim.log.levels.DEBUG] = {
    level_key = "DEBUG",
    hl_group = "NotifierDebug",
  },
  [vim.log.levels.TRACE] = {
    level_key = "TRACE",
    hl_group = "NotifierTrace",
  },
}

---@type table<string, Notifier.Group>
local State = {
  ---@diagnostic disable-next-line: missing-fields
  groups = {},
}

---Initialize state
---@private
---@return nil
local function init_state()
  ---@diagnostic disable-next-line: missing-fields
  State.groups = {}
end

-- ============================================================================
-- CONFIGURATION MANAGEMENT
-- ============================================================================

---Default configuration
---@type Notifier.Config
local DEFAULT_CONFIG = {
  default_timeout = 3000,
  resize_debounce_ms = 150,
  border = "none",
  winblend = 0,
  padding = { top = 0, right = 0, bottom = 0, left = 0 },
  default_group = "bottom-right",
  group_configs = {
    ["top-left"] = {
      anchor = "NW",
      row = function()
        return 0
      end,
      col = function()
        return 0
      end,
    },
    ["top-center"] = {
      anchor = "NW",
      row = function()
        return 0
      end,
      col = function()
        return vim.o.columns / 2
      end,
      center_mode = "horizontal", -- Center horizontally only
    },
    ["top-right"] = {
      anchor = "NE",
      row = function()
        return 0
      end,
      col = function()
        return vim.o.columns
      end,
    },
    ["left-center"] = {
      anchor = "NW",
      row = function()
        return vim.o.lines / 2
      end,
      col = function()
        return 0
      end,
      center_mode = "vertical", -- Center vertically only
    },
    ["center"] = {
      anchor = "NW",
      row = function()
        return vim.o.lines / 2
      end,
      col = function()
        return vim.o.columns / 2
      end,
      center_mode = "true", -- Center both horizontally and vertically
    },
    ["right-center"] = {
      anchor = "NE",
      row = function()
        return vim.o.lines / 2
      end,
      col = function()
        return vim.o.columns
      end,
      center_mode = "vertical", -- Center vertically only
    },
    ["bottom-left"] = {
      anchor = "SW",
      row = function()
        return vim.o.lines - 2
      end,
      col = function()
        return 0
      end,
    },
    ["bottom-center"] = {
      anchor = "SW",
      row = function()
        return vim.o.lines - 2
      end,
      col = function()
        return vim.o.columns / 2
      end,
      center_mode = "horizontal", -- Center horizontally only
    },
    ["bottom-right"] = {
      anchor = "SE",
      row = function()
        return vim.o.lines - 2
      end,
      col = function()
        return vim.o.columns
      end,
    },
  },
  width = {
    min_width = 20, -- Minimum notification width
    max_width = nil, -- Maximum width (nil = auto-calculate)
    preferred_width = 50, -- Preferred width when content fits
    max_width_percentage = 0.4, -- Maximum width as percentage of screen
    adaptive = true, -- Automatically adjust width based on content
    wrap_text = true, -- Enable text wrapping for long lines
    wrap_at_words = true, -- Wrap at word boundaries when possible
  },
  icons = {
    [vim.log.levels.TRACE] = "󰔚 ",
    [vim.log.levels.DEBUG] = " ",
    [vim.log.levels.INFO] = " ",
    [vim.log.levels.WARN] = " ",
    [vim.log.levels.ERROR] = " ",
  },
  notif_formatter = nil, -- Set below
  notif_history_formatter = nil, -- Set below
  animation = {
    enabled = false,
    fade_in_duration = 300,
    fade_out_duration = 300,
  },
}

-- ============================================================================
-- UTILITY FUNCTIONS
-- ============================================================================

---@private
---@class Notifier.Utils
local Utils = {}

---Display notification with proper formatting
---@param msg string Message content
---@param level? integer Log level
---@param opts? table Additional options
function Utils.notify(msg, level, opts)
  opts = opts or {}
  opts.title = opts.title or "notifier.nvim"
  vim.notify(msg, level or vim.log.levels.INFO, opts)
end

---Resolve effective padding from configuration
---@return Notifier.Config.Padding Resolved padding with all fields set
function Utils.resolve_padding()
  local c = M.config.padding or DEFAULT_CONFIG.padding
  return {
    top = (c and c.top) or 0,
    right = (c and c.right) or 0,
    bottom = (c and c.bottom) or 0,
    left = (c and c.left) or 0,
  }
end

---Parse formatter function results into computed line pieces
---@param format_result Notifier.FormattedNotifOpts[] Raw formatter output
---@param ignore_padding? boolean Skip padding calculations (default: false)
---@return Notifier.ComputedLineOpts[] Parsed pieces with computed positions
function Utils.parse_format_fn_result(format_result, ignore_padding)
  ignore_padding = ignore_padding or false
  local pad = Utils.resolve_padding()

  ---@type Notifier.ComputedLineOpts[]
  local parsed = {}

  -- Position tracking
  local current_line_col = 0
  local current_line_virtual_col = 0

  -- Prepare with padding
  ---@type Notifier.ComputedLineOpts[]
  local prepare_lines = {}

  -- Add left padding
  if not ignore_padding and pad.left then
    table.insert(prepare_lines, {
      display_text = string.rep(" ", pad.left),
    })
  end

  -- Add main content
  for _, item in ipairs(format_result) do
    table.insert(prepare_lines, item)
  end

  -- Add right padding
  if not ignore_padding and pad.right then
    table.insert(prepare_lines, {
      display_text = string.rep(" ", pad.right),
    })
  end

  -- Process each piece
  for _, item in ipairs(prepare_lines) do
    if type(item) ~= "table" then
      goto continue
    end

    ---@type Notifier.ComputedLineOpts
    ---@diagnostic disable-next-line: missing-fields
    local parsed_item = {}

    parsed_item.is_virtual = item.is_virtual or false

    -- Process display text
    if item.display_text then
      if type(item.display_text) == "string" then
        parsed_item.display_text = item.display_text
      elseif type(item.display_text) == "number" then
        parsed_item.display_text = tostring(item.display_text)
      end

      local text_length = parsed_item.is_virtual and vim.fn.strdisplaywidth(parsed_item.display_text)
        or #parsed_item.display_text

      -- Calculate positions based on text type
      if not parsed_item.is_virtual then
        parsed_item.col_start = current_line_col
        current_line_col = parsed_item.col_start + text_length
        parsed_item.col_end = current_line_col

        parsed_item.virtual_col_start = current_line_virtual_col
        parsed_item.virtual_col_end = current_line_virtual_col
      else
        parsed_item.col_start = current_line_col
        parsed_item.col_end = current_line_col

        parsed_item.virtual_col_start = current_line_virtual_col
        current_line_virtual_col = parsed_item.virtual_col_start + text_length
        parsed_item.virtual_col_end = current_line_virtual_col
      end
    end

    -- Copy highlight group
    if item.hl_group and type(item.hl_group) == "string" then
      parsed_item.hl_group = item.hl_group
    end

    table.insert(parsed, parsed_item)

    ::continue::
  end

  return parsed
end

---Convert parsed line pieces back to concatenated string
---@param parsed Notifier.ComputedLineOpts[] Computed line pieces
---@param include_virtual? boolean Include virtual text in output (default: false)
---@return string Concatenated display text
function Utils.convert_parsed_format_result_to_string(parsed, include_virtual)
  include_virtual = include_virtual or false
  local display_lines = {}

  for _, item in ipairs(parsed) do
    if item.display_text then
      if include_virtual then
        table.insert(display_lines, item.display_text)
      else
        if not item.is_virtual then
          table.insert(display_lines, item.display_text)
        end
      end
    end
  end

  return table.concat(display_lines, "")
end

---Set extmarks and virtual text highlights for computed line pieces
---@param ns integer Namespace ID from nvim_create_namespace
---@param bufnr integer Target buffer number
---@param line_data Notifier.ComputedLineOpts[][] Array of lines containing arrays of pieces
---@param ignore_padding? boolean Skip padding-based line filtering (default: false)
function Utils.setup_virtual_text_hls(ns, bufnr, line_data, ignore_padding)
  ignore_padding = ignore_padding or false
  vim.api.nvim_buf_clear_namespace(bufnr, ns, 0, -1)

  ---@type Notifier.Config.Padding?
  local padding

  if not ignore_padding then
    padding = Utils.resolve_padding()
  end

  for line_number, line in ipairs(line_data) do
    -- Skip padding lines
    if padding and (line_number <= padding.top or line_number > #line_data - padding.bottom) then
      goto continue
    end

    -- Process virtual text in reverse order for proper positioning
    local reversed_line = {}
    for i = #line, 1, -1 do
      table.insert(reversed_line, line[i])
    end

    for _, data in ipairs(reversed_line) do
      if data.is_virtual then
        -- Set virtual text with highlight
        vim.api.nvim_buf_set_extmark(bufnr, ns, line_number - 1, data.col_start, {
          virt_text = { { data.display_text, data.hl_group } },
          virt_text_pos = "inline",
        })
      else
        -- Set regular text highlight
        if data.col_start and data.col_end then
          vim.api.nvim_buf_set_extmark(bufnr, ns, line_number - 1, data.col_start, {
            end_col = data.col_end,
            hl_group = data.hl_group,
          })
        end
      end
    end
    ::continue::
  end
end

---Mark all entries in line data as virtual
---@param line_data Notifier.FormattedNotifOpts[] Input line pieces
---@return Notifier.FormattedNotifOpts[] Modified line data with is_virtual = true
function Utils.ensure_is_virtual(line_data)
  for _, item in ipairs(line_data) do
    item.is_virtual = true
  end
  return line_data
end

---Apply alpha transparency to formatted notification content
---@param formatted Notifier.FormattedNotifOpts[] Formatted content
---@param alpha number Alpha value (0-1)
---@return Notifier.FormattedNotifOpts[] Modified content with alpha applied
function Utils.apply_alpha_to_formatted(formatted, alpha)
  if alpha >= 1.0 then
    return formatted
  end

  for _, item in ipairs(formatted) do
    -- Create faded highlight group
    item.hl_group = Utils.create_faded_highlight(item.hl_group or "NotifierNormal", alpha)
  end

  return formatted
end

---Create a faded version of a highlight group
---@param hl_group string Original highlight group
---@param alpha number Alpha value (0-1)
---@return string Name of the faded highlight group
function Utils.create_faded_highlight(hl_group, alpha)
  local faded_name = "notifier_" .. hl_group .. "_fade_" .. math.floor(alpha * 100)

  -- Check if the highlight already exists
  local existing = vim.api.nvim_get_hl(0, { name = faded_name })
  if existing and not vim.tbl_isempty(existing) then
    return faded_name
  end

  -- Get resolved highlight (following links)
  local resolved_hl = Utils.resolve_highlight_group(hl_group)
  if not resolved_hl or vim.tbl_isempty(resolved_hl) then
    return hl_group
  end

  -- Create faded version
  local faded_hl = vim.deepcopy(resolved_hl)

  -- Apply alpha to foreground
  if faded_hl.fg then
    faded_hl.fg = Utils.blend_color_with_background(faded_hl.fg, alpha)
  end

  -- Apply alpha to background
  if faded_hl.bg then
    faded_hl.bg = Utils.blend_color_with_background(faded_hl.bg, alpha)
  end

  -- Remove any link property since we're creating a concrete highlight
  faded_hl.link = nil

  vim.api.nvim_set_hl(0, faded_name, faded_hl)

  return faded_name
end

---Blend a color with background using alpha
---@param color number Color value
---@param alpha number Alpha value (0-1)
---@return number Blended color
function Utils.blend_color_with_background(color, alpha)
  if alpha >= 1.0 then
    return color
  end

  -- Get notification window background color
  local bg_color = Utils.get_notification_window_bg_color()

  -- Convert to RGB
  local function to_rgb(c)
    return {
      r = math.floor(c / 65536) % 256, -- Extract red
      g = math.floor(c / 256) % 256, -- Extract green
      b = c % 256, -- Extract blue
    }
  end

  -- Convert from RGB
  local function from_rgb(rgb)
    return rgb.r * 65536 + rgb.g * 256 + rgb.b
  end

  local fg_rgb = to_rgb(color)
  local bg_rgb = to_rgb(bg_color)

  -- Blend
  local blended = {
    r = math.floor(fg_rgb.r * alpha + bg_rgb.r * (1 - alpha)),
    g = math.floor(fg_rgb.g * alpha + bg_rgb.g * (1 - alpha)),
    b = math.floor(fg_rgb.b * alpha + bg_rgb.b * (1 - alpha)),
  }

  local result = from_rgb(blended)

  return result
end

---Resolve a highlight group, following links to get actual color values
---@param hl_name string Highlight group name
---@param max_depth? number Maximum recursion depth (default: 10)
---@return table|nil Resolved highlight table with actual colors
function Utils.resolve_highlight_group(hl_name, max_depth)
  max_depth = max_depth or 10

  if max_depth <= 0 then
    return nil -- Prevent infinite recursion
  end

  local hl = vim.api.nvim_get_hl(0, { name = hl_name })
  if not hl or vim.tbl_isempty(hl) then
    return nil
  end

  -- If this highlight has a link, follow it
  if hl.link then
    return Utils.resolve_highlight_group(hl.link, max_depth - 1)
  end

  -- If it has actual color values, return them
  if hl.fg or hl.bg or hl.sp then
    return hl
  end

  return nil
end

---Get the background color of notification windows
---@return number Background color value
function Utils.get_notification_window_bg_color()
  -- Priority list of highlight groups to check
  local hl_groups = {
    "NotifierNormal",
    "NormalFloat",
    "Normal",
  }

  for _, hl_name in ipairs(hl_groups) do
    local resolved_hl = Utils.resolve_highlight_group(hl_name)
    if resolved_hl and resolved_hl.bg then
      return resolved_hl.bg
    end
  end

  -- Try to get background from terminal colors if available
  local term_bg = vim.g.terminal_color_background
  if term_bg then
    -- Convert from hex string if needed
    if type(term_bg) == "string" then
      local hex = term_bg:gsub("#", "")
      return tonumber(hex, 16) or 0x000000
    elseif type(term_bg) == "number" then
      return term_bg
    end
  end

  -- Ultimate fallback - use a reasonable dark/light default
  local bg_option = vim.o.background
  if bg_option == "dark" then
    return 0x1e1e2e -- Dark purple-ish instead of pure black
  else
    return 0xf8f8f2 -- Slightly off-white instead of pure white
  end
end

---Calculate optimal width for notification content
---@param lines string[] Array of text lines to measure
---@param config Notifier.Config Configuration options
---@return integer width Optimal width in characters
function Utils.calculate_optimal_width(lines, config)
  local width_config = config.width or DEFAULT_CONFIG.width

  -- Calculate screen-based constraints
  local screen_width = vim.o.columns
  ---@diagnostic disable-next-line: need-check-nil
  local min_width = width_config.min_width or 20
  ---@diagnostic disable-next-line: need-check-nil
  local max_width = width_config.max_width or math.floor(screen_width * (width_config.max_width_percentage or 0.4))
  ---@diagnostic disable-next-line: need-check-nil
  local preferred_width = width_config.preferred_width or 50

  ---@diagnostic disable-next-line: need-check-nil
  if not width_config.adaptive then
    return math.min(preferred_width, max_width)
  end

  -- Calculate natural content width
  local content_width = 0
  for _, line in ipairs(lines) do
    local line_width = vim.fn.strdisplaywidth(line)
    content_width = math.max(content_width, line_width)
  end

  -- Apply constraints
  local optimal_width = math.max(min_width, math.min(max_width, content_width))

  -- Use preferred width if content fits comfortably
  if content_width <= preferred_width and preferred_width <= max_width then
    optimal_width = preferred_width
  end

  -- Ensure we don't go below minimum even with small content
  return math.max(min_width, optimal_width)
end

---Wrap text to fit within specified width
---@param text string Text to wrap
---@param width integer Target width in characters
---@param wrap_at_words? boolean Whether to wrap at word boundaries (default: true)
---@return string[] wrapped_lines Array of wrapped lines
function Utils.wrap_text(text, width, wrap_at_words)
  if width <= 0 then
    return { text }
  end

  -- If text already fits, return as-is
  if vim.fn.strdisplaywidth(text) <= width then
    return { text }
  end

  wrap_at_words = wrap_at_words ~= false -- Default to true

  if not wrap_at_words then
    -- Hard wrap - just break at width
    return Utils.hard_wrap_text(text, width)
  end

  -- Smart wrap at word boundaries
  local words = vim.split(text, " ")
  local lines = {}
  local current_line = ""

  for _, word in ipairs(words) do
    local test_line = current_line == "" and word or current_line .. " " .. word
    local test_width = vim.fn.strdisplaywidth(test_line)

    if test_width <= width then
      current_line = test_line
    else
      -- Current word doesn't fit
      if current_line ~= "" then
        -- Save current line and start new one
        table.insert(lines, current_line)
        current_line = word
      else
        -- Even single word doesn't fit - force break it
        local broken_words = Utils.hard_wrap_text(word, width)
        for i, broken_word in ipairs(broken_words) do
          if i == #broken_words then
            current_line = broken_word -- Last piece becomes current line
          else
            table.insert(lines, broken_word)
          end
        end
      end
    end
  end

  -- Add remaining content
  if current_line ~= "" then
    table.insert(lines, current_line)
  end

  return lines
end

---Hard wrap text at character boundaries
---@param text string Text to wrap
---@param width integer Target width
---@return string[] wrapped_lines Array of wrapped lines
function Utils.hard_wrap_text(text, width)
  if width <= 0 then
    return { text }
  end

  local lines = {}
  local pos = 1
  local text_len = #text

  while pos <= text_len do
    local end_pos = pos + width - 1
    if end_pos >= text_len then
      -- Last piece
      table.insert(lines, string.sub(text, pos))
      break
    else
      table.insert(lines, string.sub(text, pos, end_pos))
      pos = end_pos + 1
    end
  end

  return #lines > 0 and lines or { text }
end

---Process notification message with wrapping support
---@param msg string Original message
---@param width integer Target width for wrapping
---@param config Notifier.Config Configuration options
---@return string[] processed_lines Array of processed message lines
function Utils.process_message_with_wrapping(msg, width, config)
  local width_config = config.width or DEFAULT_CONFIG.width

  ---@diagnostic disable-next-line: need-check-nil
  local should_wrap = width_config.wrap_text ~= false

  ---@diagnostic disable-next-line: need-check-nil
  local wrap_at_words = width_config.wrap_at_words ~= false

  -- Split original message into lines
  local original_lines = vim.split(msg, "\n")
  local processed_lines = {}

  for _, line in ipairs(original_lines) do
    if should_wrap and vim.fn.strdisplaywidth(line) > width then
      -- Wrap this line
      local wrapped_lines = Utils.wrap_text(line, width, wrap_at_words)
      vim.list_extend(processed_lines, wrapped_lines)
    else
      -- Keep line as-is
      table.insert(processed_lines, line)
    end
  end

  return processed_lines
end

---Calculate and cache row and column positions
function Utils.cache_config_group_row_col()
  for _, group in pairs(M.config.group_configs) do
    group._cached_row = group.row()
    group._cached_col = group.col()
  end
end

-- ============================================================================
-- GROUP MANAGEMENT
-- ============================================================================

---@private
---@class Notifier.GroupManager
local GroupManager = {}

---Get or create a notification group
---@param name string Group identifier from config keys
---@return Notifier.Group Active group ready for use
function GroupManager.get_group(name)
  -- Reuse existing group if valid
  if State.groups[name] then
    local buf_valid = vim.api.nvim_buf_is_valid(State.groups[name].buf)
    local win_valid = vim.api.nvim_win_is_valid(State.groups[name].win)
    if buf_valid and win_valid then
      return State.groups[name]
    end
    -- Clear invalid handles for recreation
    State.groups[name].buf = nil
    State.groups[name].win = nil
  end

  -- Create new buffer and window
  local buf = vim.api.nvim_create_buf(false, true)

  -- Get group configuration
  local group_config = M.config.group_configs[name] or M.config.group_configs[M.config.default_group]

  -- Create window with valid anchor (position will be calculated in render_group)
  local initial_config = {
    relative = "editor",
    width = 1,
    height = 1,
    focusable = false,
    style = "minimal",
    border = M.config.border,
    row = group_config._cached_row or group_config.row(),
    col = group_config._cached_col or group_config.col(),
    anchor = group_config.anchor, -- Always a valid corner anchor
    zindex = 200,
  }

  local win = vim.api.nvim_open_win(buf, false, initial_config)

  -- Set window appearance
  local effective_winblend = group_config.winblend
  if effective_winblend == nil then
    effective_winblend = M.config.winblend or 0
  end
  vim.wo[win].winblend = effective_winblend
  vim.wo[win].winhighlight = string.format("NormalFloat:%s,FloatBorder:%s", "NotifierNormal", "NotifierBorder")

  -- Store group state
  State.groups[name] = vim.tbl_deep_extend("keep", State.groups[name] or {}, {
    name = name,
    buf = buf,
    win = win,
    notifications = {},
    config = group_config,
  })

  return State.groups[name]
end

---Cleanup expired notifications from all groups
function GroupManager.cleanup_expired()
  for _, group in pairs(State.groups) do
    for i = #group.notifications, 1, -1 do
      local notif = group.notifications[i]
      if notif._expired and not notif._animating then
        table.remove(group.notifications, i)
      end
    end
  end
end

-- ============================================================================
-- ANIMATION SYSTEM
-- ============================================================================

---@private
---@class Notifier.AnimationManager
local AnimationManager = {}

---Animation state for notifications
---@class Notifier.AnimationState
---@field notification Notifier.Notification Reference to the notification
---@field start_time number Animation start timestamp
---@field duration number Animation duration in milliseconds
---@field type string Animation type ('fade_out')
---@field progress number Current progress (0-1)
---@field completed boolean Whether animation is complete

---Active animations map: notification_id -> AnimationState
---@type table<any, Notifier.AnimationState>
local active_animations = {}

---Animation timer
---@type uv.uv_timer_t?
local animation_timer = nil

---Start fade in animation for a notification
---@param notification Notifier.Notification
---@param duration? number Animation duration in ms (default: 200)
function AnimationManager.start_fade_in(notification, duration)
  -- Safety check - don't animate if disabled
  if not M.config.animation.enabled then
    notification._animation_alpha = 1.0
    return
  end

  duration = duration or M.config.animation.fade_in_duration or 200
  local animation_id = notification.id or tostring(notification)

  active_animations[animation_id] = {
    notification = notification,
    start_time = uv.hrtime() / 1e6, -- Convert to milliseconds
    duration = duration,
    type = "fade_in",
    progress = 0,
    completed = false,
  }

  -- Mark notification as animating and start fully transparent
  notification._animating = true
  notification._animation_alpha = 0.0

  AnimationManager.start_animation_loop()
end

---Start fade out animation for a notification
---@param notification Notifier.Notification
---@param duration? number Animation duration in ms (default: 300)
function AnimationManager.start_fade_out(notification, duration)
  if not M.config.animation.enabled then
    notification._expired = true
    return
  end

  duration = duration or M.config.animation.fade_out_duration or 300
  local animation_id = notification.id or tostring(notification)

  active_animations[animation_id] = {
    notification = notification,
    start_time = uv.hrtime() / 1e6, -- Convert to milliseconds
    duration = duration,
    type = "fade_out",
    progress = 0,
    completed = false,
  }

  -- Mark notification as animating
  notification._animating = true
  notification._animation_alpha = 1.0

  AnimationManager.start_animation_loop()
end

---Start the animation loop if not already running
function AnimationManager.start_animation_loop()
  if animation_timer and not animation_timer:is_closing() then
    return -- Already running
  end

  animation_timer = uv.new_timer()
  if not animation_timer then
    return
  end

  animation_timer:start(
    16,
    16,
    vim.schedule_wrap(function() -- ~60fps
      AnimationManager.update_animations()
    end)
  )
end

---Update all active animations
function AnimationManager.update_animations()
  local current_time = uv.hrtime() / 1e6
  local any_active = false
  local groups_to_render = {}

  for _, anim in pairs(active_animations) do
    if not anim.completed then
      local elapsed = current_time - anim.start_time
      anim.progress = math.min(elapsed / anim.duration, 1.0)

      if anim.type == "fade_out" then
        -- Smooth fade out using easing
        local alpha = 1.0 - AnimationManager.ease_out_cubic(anim.progress)
        anim.notification._animation_alpha = alpha

        if anim.progress >= 1.0 then
          anim.completed = true
          anim.notification._expired = true
          anim.notification._animating = false
          anim.notification._animation_alpha = 0
        end
      elseif anim.type == "fade_in" then
        -- Smooth fade in using easing
        local alpha = AnimationManager.ease_out_cubic(anim.progress)
        anim.notification._animation_alpha = alpha

        if anim.progress >= 1.0 then
          anim.completed = true
          anim.notification._animating = false
          anim.notification._animation_alpha = 1.0
        end
      end

      any_active = true

      -- Mark groups for re-render
      for group_name, group in pairs(State.groups) do
        for _, notif in ipairs(group.notifications) do
          if notif == anim.notification then
            groups_to_render[group_name] = group
            break
          end
        end
      end
    end
  end

  -- Render affected groups
  for _, group in pairs(groups_to_render) do
    M._internal.ui.render_group(group)
  end

  -- Clean up completed animations
  for animation_id, anim in pairs(active_animations) do
    if anim.completed then
      active_animations[animation_id] = nil
    end
  end

  -- Stop animation loop if no active animations
  if not any_active then
    AnimationManager.stop_animation_loop()
  end
end

---Easing function for smooth animation
---@param t number Progress (0-1)
---@return number Eased value
function AnimationManager.ease_out_cubic(t)
  return 1 - math.pow(1 - t, 3)
end

---Stop the animation loop
function AnimationManager.stop_animation_loop()
  if animation_timer and not animation_timer:is_closing() then
    animation_timer:stop()
    animation_timer:close()
    animation_timer = nil
  end
end

-- Add a batch animation method to AnimationManager for better performance
---Start fade out animations for multiple notifications
---@param notifications Notifier.Notification[] Array of notifications to animate
---@param duration? number Animation duration in ms
---@param stagger_delay? number Optional delay between starting each animation (ms)
function AnimationManager.start_batch_fade_out(notifications, duration, stagger_delay)
  if not M.config.animation.enabled then
    -- Mark all as expired immediately
    for _, notif in ipairs(notifications) do
      notif._expired = true
    end
    return
  end

  duration = duration or M.config.animation.fade_out_duration or 300
  stagger_delay = stagger_delay or 0

  -- Start animations with optional staggering
  for i, notification in ipairs(notifications) do
    if stagger_delay > 0 then
      -- Use a timer for staggered start
      local delay_timer = uv.new_timer()
      if delay_timer then
        local start_delay = (i - 1) * stagger_delay
        delay_timer:start(
          start_delay,
          0,
          vim.schedule_wrap(function()
            AnimationManager.start_fade_out(notification, duration)
            delay_timer:close()
          end)
        )
      end
    else
      -- Start immediately
      AnimationManager.start_fade_out(notification, duration)
    end
  end
end

-- ============================================================================
-- FORMATTERS
-- ============================================================================

---@private
---@class Notifier.Formatters
local Formatters = {}

---Default formatter for live notifications
---@param opts Notifier.NotificationFormatterOpts Formatting context
---@return Notifier.FormattedNotifOpts[] Formatted pieces for display
function Formatters.default_notif_formatter(opts)
  local notif = opts.notif
  local line = opts.line
  local config = opts.config

  local separator = { display_text = " ", is_virtual = true }
  local icon = notif.icon or config.icons[notif.level]
  local icon_hl = notif.hl_group or log_level_map[notif.level].hl_group

  return {
    icon and { display_text = icon, hl_group = icon_hl, is_virtual = true } or nil,
    icon and separator or nil,
    { display_text = line, hl_group = notif.hl_group, is_virtual = true },
  }
end

---Default formatter for notification history view
---@param opts Notifier.NotificationFormatterOpts Formatting context
---@return Notifier.FormattedNotifOpts[] Formatted pieces for display
function Formatters.default_notif_history_formatter(opts)
  local virtual_separator = { display_text = " ", is_virtual = true }
  local line = opts.line
  local notif = opts.notif
  local hl = notif.hl_group

  local pretty_time = os.date("%Y-%m-%d %H:%M:%S", notif.updated_at or notif.created_at)

  return {
    {
      display_text = pretty_time,
      hl_group = "Comment",
      is_virtual = true,
    },
    virtual_separator,
    {
      display_text = string.format("[%s]", string.sub(log_level_map[notif.level].level_key, 1, 3)),
      hl_group = log_level_map[notif.level].hl_group,
      is_virtual = true,
    },
    virtual_separator,
    { display_text = line, hl_group = hl },
  }
end

-- ============================================================================
-- UI RENDERING
-- ============================================================================

---@private
---@class Notifier.UI
local UI = {}

---Debounced rendering timer
---@type uv.uv_timer_t?
local render_timer = uv.new_timer()

---Dirty flag for render scheduling
---@type boolean
local dirty = false

---Schedule debounced render of all active groups
function UI.debounce_render()
  dirty = true
  if not render_timer then
    return
  end
  render_timer:stop()
  render_timer:start(
    50,
    0,
    vim.schedule_wrap(function()
      if not dirty then
        return
      end
      dirty = false
      for _, g in pairs(State.groups) do
        UI.render_group(g)
      end
    end)
  )
end

---Render notifications for a specific group
---@param group Notifier.Group Group to render
function UI.render_group(group)
  -- Filter active notifications
  ---@type Notifier.Notification[]
  local live = vim.tbl_filter(function(n)
    return not n._expired
  end, group.notifications)

  -- Close group if no notifications
  if #live == 0 then
    pcall(vim.api.nvim_win_close, group.win, true)
    pcall(vim.api.nvim_buf_delete, group.buf, { force = true })
    return
  end

  ---@type string[]
  local lines = {}
  ---@type Notifier.ComputedLineOpts[][]
  local formatted_raw_data = {}

  local all_message_lines = {}

  for i = #live, 1, -1 do
    local notif = live[i]
    local alpha = notif._animation_alpha or 1.0

    if alpha > 0 then
      local msg_lines = vim.split(notif.msg, "\n")
      vim.list_extend(all_message_lines, msg_lines)
    end
  end

  -- Calculate optimal width based on all content
  local optimal_width = Utils.calculate_optimal_width(all_message_lines, M.config)

  -- Account for padding in width calculations
  local pad = Utils.resolve_padding()
  local content_width = optimal_width - pad.left - pad.right
  content_width = math.max(1, content_width) -- Ensure positive width

  -- Process notifications (newest first)
  for i = #live, 1, -1 do
    local notif = live[i]

    -- Calculate alpha for animation
    local alpha = notif._animation_alpha or 1.0

    -- Skip if fully faded out
    if alpha <= 0 then
      goto continue
    end

    -- Process message with wrapping
    local processed_lines = Utils.process_message_with_wrapping(notif.msg, content_width, M.config)

    for _, line in ipairs(processed_lines) do
      local formatter = notif._notif_formatter or M.config.notif_formatter

      ---@diagnostic disable-next-line: need-check-nil
      local formatted = formatter({
        notif = notif,
        line = line,
        config = M.config,
        log_level_map = log_level_map,
      })

      formatted = Utils.ensure_is_virtual(formatted)

      -- Apply alpha to formatted content
      formatted = Utils.apply_alpha_to_formatted(formatted, alpha)

      local formatted_line_data = Utils.parse_format_fn_result(formatted)
      local formatted_line = Utils.convert_parsed_format_result_to_string(formatted_line_data)

      table.insert(lines, formatted_line)
      table.insert(formatted_raw_data, formatted_line_data)
    end

    ::continue::
  end

  -- Add padding lines
  for _ = 1, pad.top do
    table.insert(lines, 1, "")
    table.insert(formatted_raw_data, 1, {})
  end
  for _ = 1, pad.bottom do
    table.insert(lines, #lines + 1, "")
    table.insert(formatted_raw_data, #formatted_raw_data + 1, {})
  end

  -- Update buffer content
  pcall(vim.api.nvim_buf_set_lines, group.buf, 0, -1, false, lines)

  -- Setup highlights
  local ns = vim.api.nvim_create_namespace("notifier-notification")
  Utils.setup_virtual_text_hls(ns, group.buf, formatted_raw_data)

  -- Calculate window dimensions
  -- Use the optimal width we calculated, accounting for padding
  local window_width = optimal_width
  local window_height = #lines

  -- Calculate position based on center_mode
  local row, col, anchor =
    group.config._cached_row or group.config.row(), group.config._cached_col or group.config.col(), group.config.anchor

  if group.config.center_mode then
    if group.config.center_mode == "true" then
      -- Center both horizontally and vertically
      row = math.max(0, row - math.floor(window_height / 2))
      col = math.max(0, col - math.floor(window_width / 2))
      anchor = "NW" -- Always use NW when centering both dimensions
    elseif group.config.center_mode == "horizontal" then
      -- Center horizontally only
      col = math.max(0, col - math.floor(window_width / 2))
      -- Keep the original anchor for vertical positioning
      if anchor == "SW" or anchor == "SE" then
        row = row
      else
        row = row
      end
      -- Convert to NW/SW for horizontal centering
      anchor = (anchor == "SW" or anchor == "SE") and "SW" or "NW"
    elseif group.config.center_mode == "vertical" then
      -- Center vertically only
      row = math.max(0, row - math.floor(window_height / 2))
      -- Keep the original anchor for horizontal positioning
      if anchor == "NE" or anchor == "SE" then
        col = col
      else
        col = col
      end
      -- Convert to NW/NE for vertical centering
      anchor = (anchor == "NE" or anchor == "SE") and "NE" or "NW"
    end
  end

  -- Resize window
  local ok_win, _ = pcall(vim.api.nvim_win_set_config, group.win, {
    relative = "editor",
    row = row,
    col = col,
    anchor = anchor,
    width = window_width,
    height = window_height,
  })

  if not ok_win then
    return
  end
end

---Show notification history in floating window
function UI.show_history()
  local width = math.floor(vim.o.columns * 0.6)
  local height = math.floor(vim.o.lines * 0.6)

  -- Collect all active notifications
  local all = {}
  for _, g in pairs(State.groups) do
    vim.list_extend(all, g.notifications)
  end

  if #all == 0 then
    Utils.notify("No active notifications", vim.log.levels.INFO)
    return
  end

  -- Sort chronologically (oldest → newest)
  table.sort(all, function(a, b)
    return a.created_at < b.created_at
  end)

  -- Create history window
  local buf = vim.api.nvim_create_buf(false, true)
  local win = vim.api.nvim_open_win(buf, false, {
    relative = "editor",
    width = width,
    height = height,
    col = (vim.o.columns - width) / 2,
    row = (vim.o.lines - height) / 2,
    style = "minimal",
    border = "rounded",
    title = "Notification History",
  })

  -- Set window appearance
  vim.wo[win].winhighlight = string.format(
    "NormalFloat:%s,FloatBorder:%s,FloatTitle:%s",
    "NotifierHistoryNormal",
    "NotifierHistoryBorder",
    "NotifierHistoryTitle"
  )

  -- Configure buffer
  vim.bo[buf].buftype = "nofile"
  vim.bo[buf].bufhidden = "wipe"
  vim.bo[buf].swapfile = false
  vim.bo[buf].modifiable = true
  vim.bo[buf].buflisted = false

  -- Setup close handlers
  local close = function()
    pcall(vim.api.nvim_win_close, win, true)
  end

  for _, key in ipairs({ "<Esc>", "q", "<C-c>" }) do
    vim.keymap.set("n", key, close, { buffer = buf, nowait = true })
  end

  vim.api.nvim_create_autocmd("WinLeave", {
    buffer = buf,
    once = true,
    callback = close,
  })

  ---@type string[]
  local lines = {}
  ---@type Notifier.ComputedLineOpts[][]
  local formatted_raw_data = {}

  -- Process notifications (newest first for display)
  for i = #all, 1, -1 do
    local notif = all[i]

    -- Handle custom formatters
    if notif._notif_formatter and type(notif._notif_formatter) == "function" and notif.msg == "" then
      local formatted = notif._notif_formatter({
        notif = notif,
        line = "",
        config = M.config,
        log_level_map = log_level_map,
      })
      local formatted_line_data = Utils.parse_format_fn_result(formatted, true)
      local formatted_line = Utils.convert_parsed_format_result_to_string(formatted_line_data, true)

      -- Store formatted message for history
      notif.msg = formatted_line
    end

    -- Process message lines
    local msg_lines = vim.split(notif.msg, "\n")
    for _, line in ipairs(msg_lines) do
      local formatted = M.config.notif_history_formatter({
        notif = notif,
        line = line,
        config = M.config,
        log_level_map = log_level_map,
      })
      local formatted_line_data = Utils.parse_format_fn_result(formatted, true)
      local formatted_line = Utils.convert_parsed_format_result_to_string(formatted_line_data)

      table.insert(lines, formatted_line)
      table.insert(formatted_raw_data, formatted_line_data)
    end
  end

  -- Update buffer with content
  pcall(vim.api.nvim_buf_set_lines, buf, 0, -1, false, lines)
  vim.bo[buf].modifiable = false

  -- Setup highlights
  local ns = vim.api.nvim_create_namespace("notifier-history")
  Utils.setup_virtual_text_hls(ns, buf, formatted_raw_data, true)

  -- Focus the history window
  vim.api.nvim_set_current_win(win)
end

---Dismiss all active notifications immediately or with animation
---@param opts? boolean|{ animated?: boolean, stagger?: number } Options for dismissal
function UI.dismiss_all(opts)
  if type(opts) == "boolean" then
    opts = { animated = opts }
  end

  opts = opts or {}
  local animated = opts.animated
  local stagger_delay = opts.stagger or 0

  -- Default to config setting if not specified
  if animated == nil then
    animated = M.config.animation.enabled
  end

  if not animated then
    -- Immediate dismissal
    for _, group in pairs(State.groups) do
      if vim.api.nvim_win_is_valid(group.win) then
        vim.api.nvim_win_close(group.win, true)
      end
      if vim.api.nvim_buf_is_valid(group.buf) then
        vim.api.nvim_buf_delete(group.buf, { force = true })
      end
    end
    return
  end

  -- Animated dismissal
  local notifications_to_animate = {}

  -- Collect all active notifications
  for _, group in pairs(State.groups) do
    for _, notif in ipairs(group.notifications) do
      if not notif._expired and not notif._animating then
        table.insert(notifications_to_animate, notif)
      end
    end
  end

  -- If no notifications to animate, just return
  if #notifications_to_animate == 0 then
    return
  end

  -- Start animations with optional staggering
  AnimationManager.start_batch_fade_out(notifications_to_animate, M.config.animation.fade_out_duration, stagger_delay)

  -- Set up delayed cleanup
  local total_animation_time = (M.config.animation.fade_out_duration or 300)
  if stagger_delay > 0 then
    total_animation_time = total_animation_time + (stagger_delay * #notifications_to_animate)
  end

  local cleanup_timer = uv.new_timer()
  if cleanup_timer then
    cleanup_timer:start(
      total_animation_time + 100,
      0,
      vim.schedule_wrap(function()
        -- Clean up any remaining windows and buffers
        for _, group in pairs(State.groups) do
          if vim.api.nvim_win_is_valid(group.win) then
            vim.api.nvim_win_close(group.win, true)
          end
          if vim.api.nvim_buf_is_valid(group.buf) then
            vim.api.nvim_buf_delete(group.buf, { force = true })
          end
        end

        cleanup_timer:close()
      end)
    )
  end
end

-- ============================================================================
-- VALIDATION FUNCTIONS
-- ============================================================================

---@private
---@class Notifier.Validator
local Validator = {}

---Validate and clamp log level to valid range
---@param level any Input level value
---@return integer Valid log level
function Validator.validate_level(level)
  if type(level) ~= "number" then
    return vim.log.levels.INFO
  end
  local min_level, max_level = vim.log.levels.TRACE, vim.log.levels.ERROR
  if level < min_level then
    return min_level
  elseif level > max_level then
    return max_level
  end
  return level
end

---Validate message ensuring string output
---@param msg any Input message value
---@return string Valid message string
function Validator.validate_msg(msg)
  if type(msg) ~= "string" then
    return tostring(msg or "")
  end
  return msg
end

---Validate timeout ensuring positive milliseconds
---@param timeout any Input timeout value
---@return integer Valid timeout in milliseconds
function Validator.validate_timeout(timeout)
  if type(timeout) ~= "number" then
    return M.config.default_timeout or DEFAULT_CONFIG.default_timeout or 3000
  end
  return timeout
end

---Validate icon string
---@param icon any Input icon value
---@return string|nil Valid icon or nil
function Validator.validate_icon(icon)
  if type(icon) == "string" then
    return icon
  end
  return nil
end

---Validate highlight group name
---@param hl any Input highlight group
---@return string|nil Valid highlight group or nil
function Validator.validate_hl(hl)
  if type(hl) == "string" and #hl > 0 then
    return hl
  end
  return nil
end

---Validate group name against available configurations
---@param name any Input group name
---@return Notifier.GroupConfigsKey Valid group name
function Validator.validate_group_name(name)
  if type(name) ~= "string" then
    ---@diagnostic disable-next-line: return-type-mismatch
    return M.config.default_group or DEFAULT_CONFIG.default_group
  end
  ---@diagnostic disable-next-line: param-type-mismatch
  local valid_groups = vim.tbl_keys(M.config.group_configs or DEFAULT_CONFIG.group_configs)
  if not vim.tbl_contains(valid_groups, name) then
    ---@diagnostic disable-next-line: return-type-mismatch
    return M.config.default_group or DEFAULT_CONFIG.default_group
  end
  return name
end

---Validate formatter function
---@param formatter any Input formatter
---@return fun(opts:Notifier.NotificationFormatterOpts):Notifier.FormattedNotifOpts[] Valid formatter
function Validator.validate_formatter(formatter)
  if type(formatter) == "function" then
    return formatter
  end
  return Formatters.default_notif_formatter
end

---Validate width configuration
---@param width_config table Width configuration
---@return boolean, string?
function Validator.validate_width_config(width_config)
  if not width_config then
    return true -- Optional config
  end

  if width_config.min_width and (type(width_config.min_width) ~= "number" or width_config.min_width < 1) then
    return false, "width.min_width must be a positive number"
  end

  if width_config.max_width and (type(width_config.max_width) ~= "number" or width_config.max_width < 1) then
    return false, "width.max_width must be a positive number"
  end

  if
    width_config.preferred_width
    and (type(width_config.preferred_width) ~= "number" or width_config.preferred_width < 1)
  then
    return false, "width.preferred_width must be a positive number"
  end

  if
    width_config.max_width_percentage
    and (
      type(width_config.max_width_percentage) ~= "number"
      or width_config.max_width_percentage <= 0
      or width_config.max_width_percentage > 1
    )
  then
    return false, "width.max_width_percentage must be a number between 0 and 1"
  end

  -- Check logical consistency
  if width_config.min_width and width_config.max_width and width_config.min_width > width_config.max_width then
    return false, "width.min_width cannot be greater than width.max_width"
  end

  return true
end

---Validate configuration
---@param config Notifier.Config
---@return boolean, string?
---@private
function Validator.validate_config(config)
  -- Validate timeout
  if config.default_timeout and (type(config.default_timeout) ~= "number" or config.default_timeout < 0) then
    return false, "default_timeout must be a positive number"
  end

  -- Validate global winblend
  if config.winblend and (type(config.winblend) ~= "number" or config.winblend < 0 or config.winblend > 100) then
    return false, "winblend must be a number between 0 and 100"
  end

  -- Validate padding
  if config.padding then
    local function is_valid_padding(v)
      return v == nil or (type(v) == "number" and v >= 0)
    end
    if
      not (
        is_valid_padding(config.padding.top)
        and is_valid_padding(config.padding.right)
        and is_valid_padding(config.padding.bottom)
        and is_valid_padding(config.padding.left)
      )
    then
      return false, "padding values must be non-negative numbers"
    end
  end

  -- Validate group configs
  if config.group_configs then
    local valid_anchors = { NW = true, NE = true, SW = true, SE = true } -- Only corner anchors
    local valid_center_modes = { ["true"] = true, horizontal = true, vertical = true }

    for group_name, group_config in pairs(config.group_configs) do
      if type(group_name) ~= "string" then
        return false, "group config keys must be strings"
      end
      if not valid_anchors[group_config.anchor] then
        return false,
          string.format(
            "invalid anchor '%s' for group '%s' (only NW, NE, SW, SE supported)",
            tostring(group_config.anchor),
            group_name
          )
      end
      if type(group_config.row) ~= "function" then
        return false, string.format("row must be a function that returns number for group '%s'", group_name)
      end
      if type(group_config.col) ~= "function" then
        return false, string.format("col must be a function that returns number for group '%s'", group_name)
      end

      if
        group_config.winblend
        and (type(group_config.winblend) ~= "number" or group_config.winblend < 0 or group_config.winblend > 100)
      then
        return false, string.format("winblend must be 0-100 for group '%s'", group_name)
      end
      if group_config.center_mode and not valid_center_modes[group_config.center_mode] then
        return false,
          string.format("invalid center_mode '%s' for group '%s'", tostring(group_config.center_mode), group_name)
      end
    end
  end

  -- Validate width configuration
  if config.width then
    local valid, err = Validator.validate_width_config(config.width)
    if not valid then
      return false, err
    end
  end

  return true, nil
end

-- ============================================================================
-- NOTIFICATION MANAGEMENT
-- ============================================================================

---@private
---@class Notifier.NotificationManager
local NotificationManager = {}

---Enhanced vim.notify replacement with group and formatting support
---@param msg string Message content to display
---@param level? integer Log level (vim.log.levels.ERROR, WARN, INFO, DEBUG, TRACE)
---@param opts? Notifier.Notification Additional notification options
---@return nil
function NotificationManager.notify(msg, level, opts)
  opts = opts or {}
  local id = opts.id
  local group_name = Validator.validate_group_name(opts.group_name)
  local group = GroupManager.get_group(group_name)

  ---@type Notifier.Notification
  local found_notif = {}
  for _, n in pairs(group.notifications) do
    if n.id ~= nil and id ~= nil and n.id == id then
      found_notif = n
      break
    end
  end

  opts = vim.tbl_deep_extend("force", found_notif or {}, opts)

  local timeout = Validator.validate_timeout(opts.timeout)
  local hl_group = Validator.validate_hl(opts.hl_group)
  local icon = Validator.validate_icon(opts.icon)
  local now = os.time()
  local _notif_formatter = Validator.validate_formatter(opts._notif_formatter)
  local _notif_formatter_data = type(opts._notif_formatter_data) == "table" and opts._notif_formatter_data or nil

  level = Validator.validate_level(level)
  msg = Validator.validate_msg(msg ~= "" and msg or found_notif.msg)

  -- Replace existing notification with same ID
  if id then
    for _, notif in ipairs(group.notifications) do
      if notif.id == id then
        notif.msg = msg
        notif.level = level or vim.log.levels.INFO
        notif.timeout = timeout
        notif.icon = icon
        notif.updated_at = now
        notif.hl_group = hl_group
        notif._notif_formatter = _notif_formatter
        notif._notif_formatter_data = _notif_formatter_data
        notif._expired = false -- reset the expired flag
        notif._animation_alpha = 1.0 -- reset the alpha

        -- Always render immediately regardless of animation setting
        -- We don't want to animate the notification if it's updating the existing one
        UI.debounce_render()
        return
      end
    end
  end

  local new_notif = {
    id = id,
    msg = msg,
    icon = icon,
    level = level or vim.log.levels.INFO,
    timeout = timeout,
    created_at = now,
    updated_at = nil,
    hl_group = hl_group,
    _expired = false,
    _notif_formatter = _notif_formatter,
    _notif_formatter_data = _notif_formatter_data,
  }

  -- Add new notification
  table.insert(group.notifications, new_notif)

  if M.config.animation.enabled then
    AnimationManager.start_fade_in(new_notif, M.config.animation.fade_in_duration)
  else
    UI.debounce_render()
  end
end

-- ============================================================================
-- CLEANUP TIMER
-- ============================================================================

---Cleanup timer for expired notifications
---@type uv.uv_timer_t?
local cleanup_timer = nil

---Start the cleanup timer for automatic notification expiration
local function start_cleanup_timer()
  if cleanup_timer and not cleanup_timer:is_closing() then
    cleanup_timer:stop()
    cleanup_timer:close()
  end

  cleanup_timer = uv.new_timer()
  if not cleanup_timer then
    return
  end

  cleanup_timer:start(
    1000,
    1000,
    vim.schedule_wrap(function()
      local now = os.time() * 1000
      for _, group in pairs(State.groups) do
        local changed = false
        for i = #group.notifications, 1, -1 do
          local notif = group.notifications[i]
          if notif._expired or notif._animating then
            goto continue
          end

          local elapsed_ms = (now - ((notif.updated_at or notif.created_at) * 1000))
          if notif.timeout > 0 and elapsed_ms >= notif.timeout then
            if M.config.animation.enabled then
              AnimationManager.start_fade_out(notif)
            else
              notif._expired = true
              changed = true
            end
          end
          ::continue::
        end
        if changed then
          UI.debounce_render()
        end
      end
    end)
  )
end

-- ============================================================================
-- USER COMMANDS SETUP
-- ============================================================================

---@private
---@class Notifier.Commands
local Commands = {}

---Setup all user commands
function Commands.setup()
  Commands.setup_history_command()
  Commands.setup_dismiss_command()
end

---Setup :NotifierHistory command
function Commands.setup_history_command()
  vim.api.nvim_create_user_command("NotifierHistory", function()
    UI.show_history()
  end, {
    desc = "Show notification history",
  })
end

---Setup :NotifierDismiss command
function Commands.setup_dismiss_command()
  vim.api.nvim_create_user_command("NotifierDismiss", function(cmd)
    local opts = {}

    -- Parse arguments
    if cmd.args and cmd.args ~= "" then
      local args = vim.split(cmd.args, "%s+")

      for _, arg in ipairs(args) do
        if arg == "immediate" or arg == "false" then
          opts.animated = false
        elseif arg == "animated" or arg == "true" then
          opts.animated = true
        elseif arg:match("^stagger=(%d+)") then
          local delay = tonumber(arg:match("^stagger=(%d+)"))
          if delay then
            opts.stagger = delay
            opts.animated = true -- Enable animation if stagger is specified
          end
        end
      end
    end

    M.dismiss_all(opts)
  end, {
    desc = "Dismiss all notifications with optional animation and stagger",
    nargs = "*",
    complete = function(arg_lead)
      local completions = { "animated", "immediate", "stagger=50", "stagger=100" }

      -- Filter completions based on what's already typed
      if arg_lead ~= "" then
        return vim.tbl_filter(function(comp)
          return vim.startswith(comp, arg_lead)
        end, completions)
      end

      return completions
    end,
  })
end

-- ============================================================================
-- AUTOCMDS & CLEANUP
-- ============================================================================

---Setup autocmds for cleanup and resource management
local function setup_autocmds()
  local group = vim.api.nvim_create_augroup("NotifierNvim", { clear = true })

  vim.api.nvim_create_autocmd("VimLeavePre", {
    group = group,
    callback = function()
      -- Stop cleanup timer
      if cleanup_timer and not cleanup_timer:is_closing() then
        cleanup_timer:stop()
        cleanup_timer:close()
      end

      -- Stop render timer
      if render_timer and not render_timer:is_closing() then
        render_timer:stop()
        render_timer:close()
      end

      -- Stop animation loop
      AnimationManager.stop_animation_loop()

      -- Clean up notification windows and buffers
      UI.dismiss_all()
    end,
  })

  ---@type uv.uv_timer_t?
  local resize_timer = nil

  -- Handle screen resize
  vim.api.nvim_create_autocmd("VimResized", {
    group = group,
    callback = function()
      if resize_timer and not resize_timer:is_closing() then
        resize_timer:stop()
      end

      resize_timer = uv.new_timer()

      if not resize_timer then
        return
      end

      local debounce_ms = M.config.resize_debounce_ms or DEFAULT_CONFIG.resize_debounce_ms or 150

      resize_timer:start(
        debounce_ms,
        0,
        vim.schedule_wrap(function()
          Utils.cache_config_group_row_col()
          UI.debounce_render()
        end)
      )
    end,
  })
end

-- ============================================================================
-- HIGHLIGHT GROUPS
-- ============================================================================

---Setup default highlight groups
local function setup_highlights()
  local highlights = {
    NotifierNormal = { link = "Normal", default = true },
    NotifierBorder = { link = "FloatBorder", default = true },
    NotifierError = { link = "ErrorMsg", default = true },
    NotifierWarn = { link = "WarningMsg", default = true },
    NotifierInfo = { link = "MoreMsg", default = true },
    NotifierDebug = { link = "Debug", default = true },
    NotifierTrace = { link = "Comment", default = true },
    NotifierHistoryNormal = { link = "NormalFloat", default = true },
    NotifierHistoryBorder = { link = "FloatBorder", default = true },
    NotifierHistoryTitle = { link = "FloatTitle", default = true },
  }

  for name, opts in pairs(highlights) do
    vim.api.nvim_set_hl(0, name, opts)
  end
end

-- ============================================================================
-- HEALTH CHECK
-- ============================================================================

---@private
---Health check for :checkhealth
function M.check()
  if not setup_complete then
    vim.health.error("notifier.nvim not setup", "Run require('notifier').setup()")
    return
  end

  vim.health.start("notifier.nvim")

  -- Check environment
  if uv then
    vim.health.ok("libuv available")
  else
    vim.health.error("libuv not available")
  end

  -- Check configuration
  local issues = {}
  if M.config.default_timeout <= 0 then
    table.insert(issues, "default_timeout should be positive")
  end

  if #issues > 0 then
    for _, issue in ipairs(issues) do
      vim.health.warn("Configuration: " .. issue)
    end
  else
    vim.health.ok("Configuration valid")
  end

  -- Check active notifications
  local total_notifications = 0
  for _, group in pairs(State.groups) do
    total_notifications = total_notifications + #group.notifications
  end
  vim.health.info(string.format("Active notifications: %d", total_notifications))
  vim.health.info(string.format("Active groups: %d", vim.tbl_count(State.groups)))
end

-- ============================================================================
-- PUBLIC API & SETUP
-- ============================================================================

---@mod notifier.public Public API

-- Set default formatters (avoiding circular dependency)
DEFAULT_CONFIG.notif_formatter = Formatters.default_notif_formatter
DEFAULT_CONFIG.notif_history_formatter = Formatters.default_notif_history_formatter

---@tag notifier.setup()

---Setup the notifier plugin with user configuration
---@param user_config? Notifier.Config User configuration to merge with defaults
---@return nil
function M.setup(user_config)
  if setup_complete then
    return
  end

  -- Validate and merge configuration
  local config = vim.tbl_deep_extend("force", DEFAULT_CONFIG, user_config or {})
  local valid, err = Validator.validate_config(config)
  if not valid then
    error("notifier.nvim: Invalid configuration: " .. err)
  end

  M.config = config

  Utils.cache_config_group_row_col()

  -- Initialize systems
  init_state()
  setup_highlights()
  setup_autocmds()
  Commands.setup()

  -- Replace vim.notify with enhanced version
  vim.notify = NotificationManager.notify

  -- Start automatic cleanup
  start_cleanup_timer()

  setup_complete = true
end

---@tag notifier.notify()

---Enhanced vim.notify replacement with group and formatting support
---@param msg string Message content to display
---@param level? integer Log level (vim.log.levels.ERROR, WARN, INFO, DEBUG, TRACE)
---@param opts? Notifier.Notification Additional notification options
---@return nil
function M.notify(msg, level, opts)
  NotificationManager.notify(msg, level, opts)
end

---@tag notifier.show_history()

---Display notification history in a floating window
---@return nil
function M.show_history()
  UI.show_history()
end

---@tag notifier.dismiss_all()

---Dismiss all active notifications immediately
---@param opts? boolean|{ animated?: boolean, stagger?: number } Options for dismissal
---@return nil
function M.dismiss_all(opts)
  UI.dismiss_all(opts)
end

-- ============================================================================
-- BUILT-INS & FORMATTERS
-- ============================================================================

---Built-in formatters for notifications
---@type table
M.formatters = {
  default_notif = Formatters.default_notif_formatter,
  default_history = Formatters.default_notif_history_formatter,
}

-- ============================================================================
-- DEVELOPMENT API
-- ============================================================================

---@private
---Internal API for development and testing
M._internal = {
  state = function()
    return State
  end,
  utils = Utils,
  formatters = Formatters,
  ui = UI,
  group_manager = GroupManager,
  notification_manager = NotificationManager,
  validator = Validator,
  commands = Commands,
  animation_manager = AnimationManager,
}

return M
