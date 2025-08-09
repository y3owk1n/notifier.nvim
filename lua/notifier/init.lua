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
---This module needs to be explicitly set up with `require('notifier').setup({})`.
---It will replace `vim.notify` with enhanced functionality.
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
---<
---@brief ]]

---@toc notifier.contents

---@mod notifier.setup Setup
---@divider =

---@tag Notifier.setup()
---@tag Notifier-setup

---@brief [[
---# Module setup ~
---
--->lua
---  require('notifier').setup() -- use default config
---  -- OR
---  require('notifier').setup({}) -- replace {} with your config table
---<
---@brief ]]

---@mod notifier.config Configuration
---@divider =

---@tag Notifier.config

---@brief [[
---# Module config ~
---
---Default values:
---{
---  default_timeout = 3000, -- milliseconds
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
---}
---@brief ]]

---@mod notifier.api API
---@divider =

-- Lubuv availability check
local ok, uv = pcall(function()
  return vim.uv or vim.loop
end)

if not ok or uv == nil then
  error("notifier.nvim: libuv not available")
end

-- Version compatibility check
local nvim = vim.version()
if nvim.major == 0 and (nvim.minor < 10 or (nvim.minor == 10 and nvim.patch < 0)) then
  vim.notify("notifier.nvim requires Neovim 0.10+", vim.log.levels.ERROR)
  return
end

------------------------------------------------------------------
-- Modules & internal namespaces
------------------------------------------------------------------

---@tag Notifier
---@tag notifier-main

---Main module table
---@class Notifier
local Notifier = {}

---@private
---Internal helper functions
---@class Notifier.Helpers
local H = {}

---@private
---UI rendering and management functions
---@class Notifier.UI
local U = {}

---@private
---Input validation and sanitization functions
---@class Notifier.Validator
local V = {}

---Vim API reference for cleaner code
local api = vim.api

------------------------------------------------------------------
-- Type Definitions
------------------------------------------------------------------

---Notification object containing all display and metadata information
---@class Notifier.Notification
---@field id? string|number Unique identifier for the notification. Allows updating existing notifications.
---@field msg? string The message content to display. Can contain newlines or be empty if using custom formatter.
---@field icon? string Custom icon to display with the notification. Overrides default level icons.
---@field level? integer Log level (vim.log.levels.ERROR, WARN, INFO, DEBUG, TRACE). Defaults to INFO.
---@field timeout? integer Timeout in milliseconds before auto-dismissal. Defaults to config.default_timeout.
---@field created_at? number Unix timestamp (seconds) when notification was first created.
---@field updated_at? number Unix timestamp (seconds) when notification was last updated.
---@field hl_group? string Custom highlight group for the notification text.
---@field _expired? boolean Internal flag marking notification as expired during cleanup.
---@field _notif_formatter? fun(opts: Notifier.NotificationFormatterOpts): Notifier.FormattedNotifOpts[] Custom formatter function for this specific notification.
---@field _notif_formatter_data? table Arbitrary data passed to the custom formatter function.

---Extended notification with group configuration
---@class Notifier.NotificationGroup : Notifier.Notification
---@field group_name? Notifier.GroupConfigsKey Target group for positioning this notification.

---Internal group state management
---@class Notifier.Group
---@field name string Group identifier matching config keys.
---@field buf integer Buffer handle for the floating window.
---@field win integer Window handle for the notification display.
---@field notifications Notifier.Notification[] Array of all notifications in this group.
---@field config Notifier.GroupConfigs Configuration settings for this group.

---Mapping of log levels to display properties
---@alias Notifier.LogLevelKey
---| '"ERROR"'
---| '"WARN"'
---| '"INFO"'
---| '"DEBUG"'
---| '"TRACE"'

---Log level configuration mapping
---@class Notifier.LogLevelEntry
---@field level_key Notifier.LogLevelKey String representation of the level.
---@field hl_group string Default highlight group for this level.

---Complete log level mapping table
---@alias Notifier.LogLevelMap table<integer, Notifier.LogLevelEntry>

---Padding configuration for notification windows
---@class Notifier.Config.Padding
---@field top? integer Top padding in characters. Default: 0.
---@field right? integer Right padding in characters. Default: 0.
---@field bottom? integer Bottom padding in characters. Default: 0.
---@field left? integer Left padding in characters. Default: 0.

---Available notification group positions
---@alias Notifier.GroupConfigsKey
---| '"bottom-right"'
---| '"top-right"'
---| '"top-left"'
---| '"bottom-left"'

---Group positioning and display configuration
---@class Notifier.GroupConfigs
---@field anchor '"NW"'|'"NE"'|'"SW"'|'"SE"' Window anchor point for positioning.
---@field row integer Row position relative to the editor.
---@field col integer Column position relative to the editor.
---@field winblend? integer Window transparency (0-100). Default: 0.

---Raw formatted notification piece before computation
---@class Notifier.FormattedNotifOpts
---@field display_text string The text content to display.
---@field hl_group? string Highlight group to apply to this text segment.
---@field is_virtual? boolean Whether this text should be rendered as virtual text. Default: false.

---Computed line piece with calculated positions
---@class Notifier.ComputedLineOpts : Notifier.FormattedNotifOpts
---@field col_start? number Starting column position (0-indexed). Calculated internally.
---@field col_end? number Ending column position (0-indexed). Calculated internally.
---@field virtual_col_start? number Starting virtual column position. Calculated internally.
---@field virtual_col_end? number Ending virtual column position. Calculated internally.

---Parameters passed to notification formatter functions
---@class Notifier.NotificationFormatterOpts
---@field notif Notifier.Notification The notification being formatted.
---@field line string Current line of the notification message.
---@field config Notifier.Config Current plugin configuration.
---@field log_level_map Notifier.LogLevelMap Log level to display property mapping.

---Main plugin configuration
---@class Notifier.Config
---@field default_timeout? integer Default timeout in milliseconds for notifications. Default: 3000.
---@field border? string Border style for floating windows. Any valid nvim_open_win border. Default: "none".
---@field icons? table<integer, string> Icons for each log level. Keys are vim.log.levels values.
---@field notif_formatter? fun(opts: Notifier.NotificationFormatterOpts): Notifier.FormattedNotifOpts[] Function to format live notifications.
---@field notif_history_formatter? fun(opts: Notifier.NotificationFormatterOpts): Notifier.FormattedNotifOpts[] Function to format notifications in history view.
---@field padding? Notifier.Config.Padding Padding configuration for notification windows.
---@field default_group? Notifier.GroupConfigsKey Default group for notifications without explicit group.
---@field group_configs? table<Notifier.GroupConfigsKey, Notifier.GroupConfigs> Configuration for each notification group.

------------------------------------------------------------------
-- Constants & State
------------------------------------------------------------------

---Active notification groups
---@type table<string, Notifier.Group>
local groups = {}

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

------------------------------------------------------------------
-- Helper Functions
------------------------------------------------------------------

---Resolve effective padding from configuration
---@return Notifier.Config.Padding # Resolved padding with all fields set
function H.resolve_padding()
  local c = Notifier.config.padding
  return {
    top = (c and c.top) or 0,
    right = (c and c.right) or 0,
    bottom = (c and c.bottom) or 0,
    left = (c and c.left) or 0,
  }
end

---Get or create a notification group
---
---Reuses existing valid groups or creates new ones with floating window and buffer.
---Cleans up invalid handles automatically.
---
---@param name string Group identifier from config keys
---@return Notifier.Group group Active group ready for use
function H.get_group(name)
  -- Reuse existing group if valid
  if groups[name] then
    local buf_valid = api.nvim_buf_is_valid(groups[name].buf)
    local win_valid = api.nvim_win_is_valid(groups[name].win)

    if buf_valid and win_valid then
      return groups[name]
    end

    -- Clear invalid handles for recreation
    groups[name].buf = nil
    groups[name].win = nil
  end

  -- Create new buffer and window
  local buf = api.nvim_create_buf(false, true)
  local win = api.nvim_open_win(buf, false, {
    relative = "editor",
    width = 1,
    height = 1,
    focusable = false,
    style = "minimal",
    border = Notifier.config.border,
    row = 0,
    col = 0,
    anchor = "NW",
    zindex = 200,
  })

  -- Apply group-specific configuration
  local group_config = Notifier.config.group_configs[name]
    or Notifier.config.group_configs[Notifier.config.default_group]

  api.nvim_win_set_config(win, {
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
  groups[name] = vim.tbl_deep_extend("keep", groups[name] or {}, {
    name = name,
    buf = buf,
    win = win,
    notifications = {},
    config = group_config,
  })

  return groups[name]
end

---Parse formatter function results into computed line pieces
---
---Processes display_text, computes positions, and handles virtual text setup.
---
---@param format_result Notifier.FormattedNotifOpts[] Raw formatter output
---@param ignore_padding? boolean Skip padding calculations. Default: false
---@return Notifier.ComputedLineOpts[] line Parsed pieces with computed positions
function H.parse_format_fn_result(format_result, ignore_padding)
  ignore_padding = ignore_padding or false
  local pad = H.resolve_padding()

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
---
---@param parsed Notifier.ComputedLineOpts[] Computed line pieces
---@param include_virtual? boolean Include virtual text in output. Default: false
---@return string line Concatenated display text
function H.convert_parsed_format_result_to_string(parsed, include_virtual)
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
---
---@param ns integer Namespace ID from nvim_create_namespace
---@param bufnr integer Target buffer number
---@param line_data Notifier.ComputedLineOpts[][] Array of lines containing arrays of pieces
---@param ignore_padding? boolean Skip padding-based line filtering. Default: false
function H.setup_virtual_text_hls(ns, bufnr, line_data, ignore_padding)
  ignore_padding = ignore_padding or false
  api.nvim_buf_clear_namespace(bufnr, ns, 0, -1)

  ---@type Notifier.Config.Padding?
  local padding

  if not ignore_padding then
    padding = H.resolve_padding()
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
        api.nvim_buf_set_extmark(bufnr, ns, line_number - 1, data.col_start, {
          virt_text = { { data.display_text, data.hl_group } },
          virt_text_pos = "inline",
        })
      else
        -- Set regular text highlight
        if data.col_start and data.col_end then
          api.nvim_buf_set_extmark(bufnr, ns, line_number - 1, data.col_start, {
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
---
---Used primarily by notification formatters to ensure consistent rendering.
---
---@param line_data Notifier.FormattedNotifOpts[] Input line pieces
---@return Notifier.FormattedNotifOpts[] # Modified line data with is_virtual = true
function H.ensure_is_virtual(line_data)
  for i = #line_data, 1, -1 do
    local item = line_data[i]
    item.is_virtual = true
  end
  return line_data
end

------------------------------------------------------------------
-- UI Functions
------------------------------------------------------------------

---Debounced rendering timer
---@type uv.uv_timer_t?
local render_timer = assert(uv.new_timer(), "uv_timer_t")

---Dirty flag for render scheduling
---@type boolean
local dirty = false

---Schedule debounced render of all active groups
---
---Uses libuv timer to batch render operations and avoid excessive redraws.
function U.debounce_render()
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
      for _, g in pairs(groups) do
        U.render_group(g)
      end
    end)
  )
end

---Default formatter for live notifications
---
---Creates icon + separator + message layout with proper highlighting.
---
---@param opts Notifier.NotificationFormatterOpts Formatting context
---@return Notifier.FormattedNotifOpts[] # Formatted pieces for display
function U.default_notif_formatter(opts)
  local notif = opts.notif
  local line = opts.line
  local config = opts.config
  local _log_level_map = opts.log_level_map

  local separator = { display_text = " ", is_virtual = true }

  local icon = notif.icon or config.icons[notif.level]
  local icon_hl = notif.hl_group or _log_level_map[notif.level].hl_group

  return {
    icon and { display_text = icon, hl_group = icon_hl, is_virtual = true },
    icon and separator,
    { display_text = line, hl_group = notif.hl_group, is_virtual = true },
  }
end

---Default formatter for notification history view
---
---Creates timestamp + level + message layout with enhanced context.
---
---@param opts Notifier.NotificationFormatterOpts Formatting context
---@return Notifier.FormattedNotifOpts[] # Formatted pieces for display
function U.default_notif_history_formatter(opts)
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

---Render notifications for a specific group
---
---Formats all active notifications, applies padding, sets up highlights,
---and resizes the floating window appropriately.
---
---@param group Notifier.Group Group to render
function U.render_group(group)
  -- Filter active notifications
  ---@type Notifier.Notification[]
  local live = vim.tbl_filter(function(n)
    return not n._expired
  end, group.notifications)

  -- Close group if no notifications
  if #live == 0 then
    pcall(api.nvim_win_close, group.win, true)
    pcall(api.nvim_buf_delete, group.buf, { force = true })
    return
  end

  ---@type string[]
  local lines = {}

  ---@type Notifier.ComputedLineOpts[][]
  local formatted_raw_data = {}

  -- Process notifications (newest first)
  for i = #live, 1, -1 do
    local notif = live[i]

    -- Handle custom formatters with empty messages
    if notif._notif_formatter and type(notif._notif_formatter) == "function" and notif.msg == "" then
      local formatted =
        notif._notif_formatter({ notif = notif, line = "", config = Notifier.config, log_level_map = log_level_map })

      formatted = H.ensure_is_virtual(formatted)
      local formatted_line_data = H.parse_format_fn_result(formatted)
      local formatted_line = H.convert_parsed_format_result_to_string(formatted_line_data)

      table.insert(lines, formatted_line)
      table.insert(formatted_raw_data, formatted_line_data)
      goto continue
    end

    -- Process regular messages line by line
    local msg_lines = vim.split(notif.msg, "\n")

    for _, line in ipairs(msg_lines) do
      local formatted = Notifier.config.notif_formatter({
        notif = notif,
        line = line,
        config = Notifier.config,
        log_level_map = log_level_map,
      })

      formatted = H.ensure_is_virtual(formatted)
      local formatted_line_data = H.parse_format_fn_result(formatted)
      local formatted_line = H.convert_parsed_format_result_to_string(formatted_line_data)

      table.insert(lines, formatted_line)
      table.insert(formatted_raw_data, formatted_line_data)
    end
    ::continue::
  end

  -- Add padding lines
  local pad = H.resolve_padding()

  for _ = 1, pad.top do
    table.insert(lines, 1, "")
    table.insert(formatted_raw_data, 1, "")
  end

  for _ = 1, pad.bottom do
    table.insert(lines, #lines + 1, "")
    table.insert(formatted_raw_data, #formatted_raw_data + 1, "")
  end

  -- Update buffer content
  pcall(api.nvim_buf_set_lines, group.buf, 0, -1, false, lines)

  -- Setup highlights
  local ns = vim.api.nvim_create_namespace("notifier-notification")
  H.setup_virtual_text_hls(ns, group.buf, formatted_raw_data)

  -- Calculate window dimensions
  local width = 0
  for _, data in pairs(formatted_raw_data) do
    if data ~= "" then
      for _, item in pairs(data) do
        local last_width = ((item.col_end or 0) + (item.virtual_col_end or 0))
          or vim.fn.strdisplaywidth(item.display_text)
        width = math.max(width, last_width)
      end
    end
  end

  width = math.min(width, math.floor(vim.o.columns * 0.6))
  local height = #lines

  -- Resize window
  local ok_win, _ = pcall(api.nvim_win_set_config, group.win, {
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

------------------------------------------------------------------
-- Validation Functions
------------------------------------------------------------------

---Validate and clamp log level to valid range
---@param level any Input level value
---@return integer # Valid log level
function V.validate_level(level)
  if type(level) ~= "number" then
    return vim.log.levels.INFO
  end

  -- Clamp to valid range
  local min_level, max_level = vim.log.levels.TRACE, vim.log.levels.ERROR
  if level < min_level then
    return min_level
  elseif level > max_level then
    return max_level
  end

  return level
end

--- Validate message ensuring string output
---@param msg any Input message value
---@return string # Valid message string
function V.validate_msg(msg)
  if type(msg) ~= "string" then
    return tostring(msg or "")
  end
  return msg
end

--- Validate padding table with numeric non-negative values
---@param padding any Input padding configuration
---@return Notifier.Config.Padding # Valid padding configuration
function V.validate_padding(padding)
  local function safe_num(v)
    return (type(v) == "number" and v >= 0) and v or 0
  end
  if type(padding) ~= "table" then
    return { top = 0, right = 0, bottom = 0, left = 0 }
  end
  return {
    top = safe_num(padding.top),
    right = safe_num(padding.right),
    bottom = safe_num(padding.bottom),
    left = safe_num(padding.left),
  }
end

---Validate window anchor value
---@param anchor any Input anchor value
---@return "NW"|"NE"|"SW"|"SE" # Valid anchor
function V.validate_anchor(anchor)
  local valid = { NW = true, NE = true, SW = true, SE = true }
  if type(anchor) == "string" and valid[anchor] then
    return anchor
  end
  return "SE"
end

---Validate row/column position values
---@param row_col any Input position value
---@return number # Valid position (>= 0)
function V.validate_row_col(row_col)
  if type(row_col) == "number" and row_col >= 0 then
    return row_col
  end
  return 0
end

---Validate timeout ensuring positive milliseconds
---@param timeout any Input timeout value
---@return integer # Valid timeout in milliseconds
function V.validate_timeout(timeout)
  if type(timeout) ~= "number" or timeout < 0 then
    return Notifier.config.default_timeout or Notifier.defaults.default_timeout or 3000
  end
  return timeout
end

---Validate formatter function
---@param formatter any Input formatter
---@return fun(opts:Notifier.NotificationFormatterOpts):Notifier.FormattedNotifOpts[] # Valid formatter
function V.validate_formatter(formatter)
  if type(formatter) == "function" then
    return formatter
  end
  return Notifier.defaults.notif_formatter
end

---Validate icon string
---@param icon any Input icon value
---@return string|nil # Valid icon or nil
function V.validate_icon(icon)
  if type(icon) == "string" then
    return icon
  end
  return nil
end

---Validate highlight group name
---@param hl any Input highlight group
---@return string|nil # Valid highlight group or nil
function V.validate_hl(hl)
  if type(hl) == "string" and #hl > 0 then
    return hl
  end
  return nil
end

---Validate group name against available configurations
---@param name any Input group name
---@return Notifier.GroupConfigsKey # Valid group name
function V.validate_group_name(name)
  if type(name) ~= "string" then
    return Notifier.defaults.default_group
  end

  local valid_groups = vim.tbl_keys(Notifier.config.group_configs)
  if not vim.tbl_contains(valid_groups, name) then
    return Notifier.defaults.default_group
  end

  return name
end

---Validate group configurations table
---@param group_configs any Input group configurations
---@return table<Notifier.GroupConfigsKey, Notifier.GroupConfigs> # Valid group configs
function V.validate_group_configs(group_configs)
  if type(group_configs) ~= "table" then
    return Notifier.defaults.group_configs
  end

  local valid_groups = vim.tbl_keys(Notifier.defaults.group_configs)
  for group_name, _ in pairs(group_configs) do
    if not vim.tbl_contains(valid_groups, group_name) then
      return Notifier.defaults.group_configs
    end
  end

  return group_configs
end

---Validate window blend value (0-100)
---@param winblend any Input winblend value
---@return number # Valid winblend (0-100)
function V.validate_winblend(winblend)
  if type(winblend) == "number" and winblend >= 0 and winblend <= 100 then
    return winblend
  end
  return 0
end

------------------------------------------------------------------
-- Public Interface
------------------------------------------------------------------

---Enhanced vim.notify replacement with group and formatting support
---
---Displays notifications with advanced features like grouping, custom formatting,
---and ID-based updating. Replaces existing notifications with matching IDs.
---
---# Parameters ~
---
--- • {msg} (string) Message content, can contain newlines
--- • {level} (integer, optional) Log level from vim.log.levels
--- • {opts} (Notifier.NotificationGroup, optional) Additional options:
---   - {id}: Unique identifier for updating existing notifications
---   - {timeout}: Custom timeout in milliseconds
---   - {icon}: Override default level icon
---   - {hl_group}: Custom highlight group
---   - {group_name}: Target notification group for positioning
---   - {_notif_formatter}: Custom formatter function for this notification
---   - {_notif_formatter_data}: Data passed to custom formatter
---
---@param msg string Message content to display
---@param level? integer Log level (vim.log.levels.ERROR, WARN, INFO, DEBUG, TRACE)
---@param opts? Notifier.NotificationGroup Additional notification options
---@return nil
---@usage [[
---   -- Basic notification
---   require('notifier').notify("Hello world!")
---
---   -- With custom options
---   require('notifier').notify("Warning message", vim.log.levels.WARN, {
---     id = "my-warning",
---     timeout = 5000,
---     group_name = "top-right"
---   })
---
---   -- Update existing notification
---   require('notifier').notify("Updated message", vim.log.levels.INFO, {
---     id = "my-warning"  -- Same ID updates the previous notification
---   })
---@usage ]]
function Notifier.notify(msg, level, opts)
  opts = opts or {}
  local id = opts.id
  local group_name = V.validate_group_name(opts.group_name)
  local group = H.get_group(group_name)

  local found_notif

  for _, n in pairs(group.notifications) do
    if n.id == id then
      found_notif = n
      break
    end
  end

  if group and found_notif then
    opts = vim.tbl_extend("force", found_notif, opts)
  end

  local timeout = V.validate_timeout(opts.timeout)
  local hl_group = V.validate_hl(opts.hl_group)
  local icon = V.validate_icon(opts.icon)
  local now = os.time()
  local _notif_formatter = V.validate_formatter(opts._notif_formatter)
  local _notif_formatter_data = type(opts._notif_formatter_data) == "table" and opts._notif_formatter_data or nil
  level = V.validate_level(level)
  msg = V.validate_msg(msg)

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
        U.debounce_render()
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
    _notif_formatter = _notif_formatter,
    _notif_formatter_data = _notif_formatter_data,
  })

  U.debounce_render()
end

---Cleanup timer for expired notifications
---@type uv.uv_timer_t?
local cleanup_timer = nil

---Start the cleanup timer for automatic notification expiration
---
---Runs every second to check notification timeouts and mark expired ones
---for removal during the next render cycle.
local function start_cleanup_timer()
  if cleanup_timer and not cleanup_timer:is_closing() then
    cleanup_timer:stop()
    cleanup_timer:close()
  end

  cleanup_timer = assert(uv.new_timer(), "uv_timer_t")

  if not cleanup_timer then
    return
  end

  cleanup_timer:start(
    1000,
    1000,
    vim.schedule_wrap(function()
      local now = os.time() * 1000

      for _, group in pairs(groups) do
        local changed = false
        for i = #group.notifications, 1, -1 do
          local notif = group.notifications[i]

          if notif._expired then
            goto continue
          end

          local elapsed_ms = (now - ((notif.updated_at or notif.created_at) * 1000))
          if elapsed_ms >= notif.timeout then
            notif._expired = true
            changed = true
          end
          ::continue::
        end
        if changed then
          U.debounce_render()
        end
      end
    end)
  )
end

---Display notification history in a floating window
---
---Shows all currently active notifications across all groups in chronological order
---with enhanced formatting including timestamps and level indicators.
---
---# Features ~
--- • Scrollable floating window with all active notifications
--- • Chronological ordering (oldest to newest)
--- • Enhanced formatting with timestamps and log levels
--- • Keyboard shortcuts for closing (Esc, q, Ctrl-C)
--- • Auto-close when window loses focus
---
---@usage `require('notifier').show_history()`
function Notifier.show_history()
  local width = math.floor(vim.o.columns * 0.6)
  local height = math.floor(vim.o.lines * 0.6)

  -- Collect all active notifications
  ---@type Notifier.Notification[]
  local all = {}

  for _, g in pairs(groups) do
    vim.list_extend(all, g.notifications)
  end

  if #all == 0 then
    vim.notify("No active notifications", vim.log.levels.INFO)
    return
  end

  -- Sort chronologically (oldest → newest)
  table.sort(all, function(a, b)
    return a.created_at < b.created_at
  end)

  -- Create history window
  local buf = api.nvim_create_buf(false, true)
  local win = api.nvim_open_win(buf, false, {
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

  -- Setup close handlers
  local close = function()
    pcall(api.nvim_win_close, win, true)
  end

  for _, key in ipairs({ "<Esc>", "q", "<C-c>" }) do
    vim.keymap.set("n", key, close, { buffer = buf, nowait = true })
  end

  api.nvim_create_autocmd("WinLeave", { buffer = buf, once = true, callback = close })

  ---@type string[]
  local lines = {}

  ---@type Notifier.FormattedNotifOpts[][]
  local formatted_raw_data = {}

  -- Process notifications (newest first for display)
  for i = #all, 1, -1 do
    local notif = all[i]

    -- Handle custom formatters
    if notif._notif_formatter and type(notif._notif_formatter) == "function" and notif.msg == "" then
      local formatted =
        notif._notif_formatter({ notif = notif, line = "", config = Notifier.config, log_level_map = log_level_map })

      local formatted_line_data = H.parse_format_fn_result(formatted, true)
      local formatted_line = H.convert_parsed_format_result_to_string(formatted_line_data, true)

      -- Store formatted message for history
      notif.msg = formatted_line
    end

    -- Process message lines
    local msg_lines = vim.split(notif.msg, "\n")

    for _, line in ipairs(msg_lines) do
      local formatted = Notifier.config.notif_history_formatter({
        notif = notif,
        line = line,
        config = Notifier.config,
        log_level_map = log_level_map,
      })

      local formatted_line_data = H.parse_format_fn_result(formatted, true)
      local formatted_line = H.convert_parsed_format_result_to_string(formatted_line_data)

      table.insert(lines, formatted_line)
      table.insert(formatted_raw_data, formatted_line_data)
    end
  end

  -- Update buffer with content
  pcall(api.nvim_buf_set_lines, buf, 0, -1, false, lines)
  vim.bo[buf].modifiable = false

  -- Setup highlights
  local ns = vim.api.nvim_create_namespace("notifier-history")
  H.setup_virtual_text_hls(ns, buf, formatted_raw_data, true)

  -- Focus the history window
  api.nvim_set_current_win(win)
end

---Dismiss all active notifications immediately
---
---Closes all notification windows and clears their buffers across all groups.
---This provides an immediate way to clear the screen of notifications.
---
---@usage `require('notifier').dismiss_all()`
function Notifier.dismiss_all()
  for _, group in pairs(groups) do
    if api.nvim_win_is_valid(group.win) then
      api.nvim_win_close(group.win, true)
    end
    if api.nvim_buf_is_valid(group.buf) then
      api.nvim_buf_delete(group.buf, { force = true })
    end
  end
end

------------------------------------------------------------------
-- Configuration and Setup
------------------------------------------------------------------

---@tag Notifier.config

---Current plugin configuration
---@type Notifier.Config
Notifier.config = {}

---@tag Notifier.defaults

---Default configuration values
---@type Notifier.Config
Notifier.defaults = {
  default_timeout = 3000, -- milliseconds
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
  notif_formatter = U.default_notif_formatter,
  notif_history_formatter = U.default_notif_history_formatter,
}

---Setup default highlight groups for notifications
---
---Creates default highlight groups that link to standard Neovim groups.
---These can be overridden by colorschemes or user configuration.
local function setup_hls()
  local hi = function(name, opts)
    opts.default = true
    vim.api.nvim_set_hl(0, name, opts)
  end

  -- Main notification highlights
  hi("NotifierNormal", { link = "Normal" })
  hi("NotifierBorder", { link = "FloatBorder" })

  -- Level-specific highlights
  hi("NotifierError", { link = "ErrorMsg" })
  hi("NotifierWarn", { link = "WarningMsg" })
  hi("NotifierInfo", { link = "MoreMsg" })
  hi("NotifierDebug", { link = "Debug" })
  hi("NotifierTrace", { link = "Comment" })

  -- History window highlights
  hi("NotifierHistoryNormal", { link = "NormalFloat" })
  hi("NotifierHistoryBorder", { link = "FloatBorder" })
  hi("NotifierHistoryTitle", { link = "FloatTitle" })
end

---@tag Notifier.setup()

---Setup the notifier plugin with user configuration
---
---Initializes the plugin with merged default and user configurations,
---validates all settings, creates highlight groups, replaces vim.notify,
---and starts the cleanup timer for automatic notification expiration.
---
---@param user_config? Notifier.Config User configuration to merge with defaults
---@return nil
---@usage [[
---   -- Minimal setup
---   require('notifier').setup()
---
---   -- Custom configuration
---   require('notifier').setup({
---     default_timeout = 5000,
---     border = "rounded",
---     padding = { top = 1, right = 2, bottom = 1, left = 2 },
---     group_configs = {
---       ["bottom-right"] = {
---         anchor = "SE",
---         row = vim.o.lines - 3,
---         col = vim.o.columns - 1,
---         winblend = 20,
---       }
---     },
---     icons = {
---       [vim.log.levels.ERROR] = "✗ ",
---       [vim.log.levels.WARN] = "⚠ ",
---       [vim.log.levels.INFO] = "ℹ ",
---     }
---   })
---@usage ]]
function Notifier.setup(user_config)
  -- Merge configurations
  Notifier.config = vim.tbl_deep_extend("force", Notifier.defaults, user_config or {})

  -- Validate configuration components
  Notifier.config.padding = V.validate_padding(Notifier.config.padding)
  Notifier.config.group_configs = V.validate_group_configs(Notifier.config.group_configs)

  -- Validate individual group configurations
  for _, group_config in pairs(Notifier.config.group_configs or {}) do
    group_config.anchor = V.validate_anchor(group_config.anchor)
    group_config.row = V.validate_row_col(group_config.row)
    group_config.col = V.validate_row_col(group_config.col)
    group_config.winblend = V.validate_winblend(group_config.winblend)
  end

  Notifier.config.default_group = V.validate_group_name(Notifier.config.default_group)

  -- Initialize appearance and functionality
  setup_hls()

  -- Replace vim.notify with enhanced version
  vim.notify = Notifier.notify

  -- Start automatic cleanup
  start_cleanup_timer()
end

return Notifier
