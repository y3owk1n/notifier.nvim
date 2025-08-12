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
---  border = "none",
---  padding = { top = 0, right = 0, bottom = 0, left = 0 },
---  default_group = "bottom-right",
---  group_configs = {
---    ["bottom-right"] = {
---      anchor = "SE",
---      row = vim.o.lines - 2,
---      col = vim.o.columns,
---      winblend = 0,
---    },
---    ["top-right"] = {
---      anchor = "NE",
---      row = 0,
---      col = vim.o.columns,
---      winblend = 0,
---    },
---    ["top-left"] = {
---      anchor = "NW",
---      row = 0,
---      col = 0,
---      winblend = 0,
---    },
---    ["bottom-left"] = {
---      anchor = "SW",
---      row = vim.o.lines - 2,
---      col = 0,
---      winblend = 0,
---    },
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
---         row = vim.o.lines - 2,
---         col = vim.o.columns,
---         winblend = 20,
---       },
---       ["top-center"] = {
---         anchor = "N",
---         row = 1,
---         col = vim.o.columns / 2,
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
---# Dismiss all notifications ~
---
---Immediately close all active notification windows.
---
--->vim
---   :NotifierDismiss    " Dismiss all notifications
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

---Group positioning and display configuration.
---@class Notifier.GroupConfigs
---@field anchor '"NW"'|'"NE"'|'"SW"'|'"SE"' Window anchor point for positioning
---@field row integer Row position relative to the editor
---@field col integer Column position relative to the editor
---@field winblend? integer Window transparency (0-100, default: 0)

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
---@field border? string Border style for floating windows (default: "none")
---@field icons? table<integer, string> Icons for each log level (keys are vim.log.levels values)
---@field notif_formatter? fun(opts: Notifier.NotificationFormatterOpts): Notifier.FormattedNotifOpts[] Function to format live notifications
---@field notif_history_formatter? fun(opts: Notifier.NotificationFormatterOpts): Notifier.FormattedNotifOpts[] Function to format notifications in history view
---@field padding? Notifier.Config.Padding Padding configuration for notification windows
---@field default_group? Notifier.GroupConfigsKey Default group for notifications without explicit group
---@field group_configs? table<Notifier.GroupConfigsKey, Notifier.GroupConfigs> Configuration for each notification group
---@field animation? Notifier.Config.Animation Animation configuration

---Animation configuration.
---@class Notifier.Config.Animation
---@field enabled? boolean Whether animations are enabled (default: false)
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
  border = "none",
  padding = { top = 0, right = 0, bottom = 0, left = 0 },
  default_group = "bottom-right",
  group_configs = {
    ["bottom-right"] = {
      anchor = "SE",
      row = vim.o.lines - 2,
      col = vim.o.columns,
      winblend = 0,
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
    fade_out_duration = 300,
  },
}

---Validate configuration
---@param config Notifier.Config
---@return boolean, string?
---@private
local function validate_config(config)
  -- Validate timeout
  if config.default_timeout and (type(config.default_timeout) ~= "number" or config.default_timeout < 0) then
    return false, "default_timeout must be a positive number"
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
    local valid_anchors = { NW = true, NE = true, SW = true, SE = true }
    for group_name, group_config in pairs(config.group_configs) do
      if type(group_name) ~= "string" then
        return false, "group config keys must be strings"
      end
      if not valid_anchors[group_config.anchor] then
        return false, string.format("invalid anchor '%s' for group '%s'", tostring(group_config.anchor), group_name)
      end
      if type(group_config.row) ~= "number" or group_config.row < 0 then
        return false, string.format("row must be non-negative number for group '%s'", group_name)
      end
      if type(group_config.col) ~= "number" or group_config.col < 0 then
        return false, string.format("col must be non-negative number for group '%s'", group_name)
      end
      if
        group_config.winblend
        and (type(group_config.winblend) ~= "number" or group_config.winblend < 0 or group_config.winblend > 100)
      then
        return false, string.format("winblend must be 0-100 for group '%s'", group_name)
      end
    end
  end

  return true, nil
end

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

---Debug function to check what colors are being used
---@return table Debug information about colors
function Utils.debug_fade_colors()
  local bg_color = Utils.get_notification_window_bg_color()
  local notifier_hl = Utils.resolve_highlight_group("NotifierNormal")
  local normal_float_hl = Utils.resolve_highlight_group("NormalFloat")
  local normal_hl = Utils.resolve_highlight_group("Normal")

  return {
    background_color = string.format("#%06x", bg_color),
    notifier_normal = notifier_hl,
    normal_float = normal_float_hl,
    normal = normal_hl,
    vim_background = vim.o.background,
  }
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
  local win = vim.api.nvim_open_win(buf, false, {
    relative = "editor",
    width = 1,
    height = 1,
    focusable = false,
    style = "minimal",
    border = M.config.border,
    row = 0,
    col = 0,
    anchor = "NW",
    zindex = 200,
  })

  -- Apply group-specific configuration
  local group_config = M.config.group_configs[name] or M.config.group_configs[M.config.default_group]
  vim.api.nvim_win_set_config(win, {
    relative = "editor",
    row = group_config.row,
    col = group_config.col,
    anchor = group_config.anchor,
    width = 1,
    height = 1,
  })

  -- Set window appearance
  vim.wo[win].winblend = group_config.winblend or 0
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

  for animation_id, anim in pairs(active_animations) do
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

  -- Process notifications (newest first)
  for i = #live, 1, -1 do
    local notif = live[i]

    -- Calculate alpha for animation
    local alpha = notif._animation_alpha or 1.0

    -- Skip if fully faded out
    if alpha <= 0 then
      goto continue
    end

    -- Handle custom formatters with empty messages
    if notif._notif_formatter and type(notif._notif_formatter) == "function" and notif.msg == "" then
      local formatted = notif._notif_formatter({
        notif = notif,
        line = "",
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
      goto continue
    end

    -- Process regular messages line by line
    local msg_lines = vim.split(notif.msg, "\n")
    for _, line in ipairs(msg_lines) do
      local formatted = M.config.notif_formatter({
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
  local pad = Utils.resolve_padding()
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
  local width = 0
  for _, data in pairs(formatted_raw_data) do
    if type(data) == "table" and #data > 0 then
      for _, item in pairs(data) do
        local last_width = ((item.col_end or 0) + (item.virtual_col_end or 0))
          or vim.fn.strdisplaywidth(item.display_text or "")
        width = math.max(width, last_width)
      end
    end
  end
  width = math.min(width, math.floor(vim.o.columns * 0.6))
  local height = #lines

  -- Resize window
  local ok_win, _ = pcall(vim.api.nvim_win_set_config, group.win, {
    relative = "editor",
    row = group.config.row,
    col = group.config.col,
    anchor = group.config.anchor,
    width = width,
    height = height,
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

---Dismiss all active notifications immediately
function UI.dismiss_all()
  for _, group in pairs(State.groups) do
    if vim.api.nvim_win_is_valid(group.win) then
      vim.api.nvim_win_close(group.win, true)
    end
    if vim.api.nvim_buf_is_valid(group.buf) then
      vim.api.nvim_buf_delete(group.buf, { force = true })
    end
  end
  ---@diagnostic disable-next-line: missing-fields
  State.groups = {}
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

  local found_notif
  for _, n in pairs(group.notifications) do
    if n.id ~= nil and id ~= nil and n.id == id then
      found_notif = n
      break
    end
  end

  if group and found_notif then
    opts = vim.tbl_extend("force", found_notif, opts)
  end

  local timeout = Validator.validate_timeout(opts.timeout)
  local hl_group = Validator.validate_hl(opts.hl_group)
  local icon = Validator.validate_icon(opts.icon)
  local now = os.time()
  local _notif_formatter = Validator.validate_formatter(opts._notif_formatter)
  local _notif_formatter_data = type(opts._notif_formatter_data) == "table" and opts._notif_formatter_data or nil

  level = Validator.validate_level(level)
  msg = Validator.validate_msg(msg)

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
        notif._expired = false
        UI.debounce_render()
        return
      end
    end
  end

  -- Add new notification
  table.insert(group.notifications, {
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
  })

  UI.debounce_render()
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
  vim.api.nvim_create_user_command("NotifierDismiss", function()
    UI.dismiss_all()
  end, {
    desc = "Dismiss all notifications",
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

  -- Handle screen resize
  vim.api.nvim_create_autocmd("VimResized", {
    group = group,
    callback = function()
      -- Update group configs to new screen dimensions
      if M.config and M.config.group_configs then
        for _, group_config in pairs(M.config.group_configs) do
          if group_config.anchor:find("E") then
            group_config.col = vim.o.columns
          end
          if group_config.anchor:find("S") then
            group_config.row = vim.o.lines - 2
          end
        end
      end
      UI.debounce_render()
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
  local valid, err = validate_config(config)
  if not valid then
    error("notifier.nvim: Invalid configuration: " .. err)
  end

  M.config = config

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
---@return nil
function M.dismiss_all()
  UI.dismiss_all()
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
