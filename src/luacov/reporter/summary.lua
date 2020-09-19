local M = {}

local ipairs = ipairs
local print = print
local require = require
local setmetatable = setmetatable
local tostring = tostring

local tbl_concat = table.concat
local math_max = math.max

local _ENV = M

local reporter = require 'luacov.reporter'

local DefaultReporter = reporter.DefaultReporter
local ConsoleReporter = setmetatable({}, DefaultReporter)
ConsoleReporter.__index = ConsoleReporter

local ColorEscapes = {
  reset = '\27[0m',
  red = '\27[31m',
  green = '\27[32m',
  yellow = '\27[33m',
  white = '\27[37m',
}

local function get_line_color(coverage)
  if coverage < 0.25 then
    return 'red'
  elseif coverage < 0.50 then
    return 'yellow'
  elseif coverage < 0.75 then
    return 'white'
  end
  return 'green'
end

local function coverage_to_string(coverage)
  return ("%.2f%%"):format(100 * coverage)
end

local function calculate_coverage(hits, missed)
  local total = hits + missed
  return total == 0 and 0 or hits / total
end

local function print_ruler(length, c)
  print(c:rep(length))
end

function ConsoleReporter:print_summary()
  local lines = {{"File", "Hits", "Missed", "Coverage"}}
  local total_hits, total_missed = 0, 0

  for _, filename in ipairs(self:files()) do
     local summary = self._summary[filename]
     if summary then
        local hits, missed = summary.hits, summary.miss
        local coverage = calculate_coverage(hits, missed)
        lines[#lines + 1] = {
          color = get_line_color(coverage),
          filename,
          tostring(summary.hits),
          tostring(summary.miss),
          coverage_to_string(coverage)
        }
        total_hits, total_missed = total_hits + hits, total_missed + missed
     end
  end

  local coverage = calculate_coverage(total_hits, total_missed)
  lines[#lines + 1] = {
    color = get_line_color(coverage),
    "Total",
    tostring(total_hits),
    tostring(total_missed),
    coverage_to_string(coverage)
  }

  local max_column_lengths = {}

  for _, line in ipairs(lines) do
     for i, column in ipairs(line) do
        max_column_lengths[i] = math_max(max_column_lengths[i] or -1, #column)
     end
  end

  local table_width = #max_column_lengths - 1

  for _, column_length in ipairs(max_column_lengths) do
     table_width = table_width + column_length
  end

  print_ruler(table_width, '=')
  print("Summary")
  print_ruler(table_width, '=')
  print()

  local cfg = self:config()
  local use_color = cfg.console and cfg.console.use_color
  for i, line in ipairs(lines) do
    if i == #lines or i == 2 then
      print_ruler(table_width, '-')
    end

    local buf = {}
    for j, column in ipairs(line) do
      if j == #line and use_color then
        buf[# buf + 1] = ColorEscapes[line.color]
      end

      buf[#buf + 1] = column
      if j < #line then
        buf[#buf + 1] = (" "):rep(max_column_lengths[j] - #column + 1)
      end
    end
    if use_color then
      buf[#buf + 1] = ColorEscapes.reset
    end

    print(tbl_concat(buf))
  end
end

function ConsoleReporter:on_end()
  DefaultReporter.on_end(self)
  self:print_summary()
end

function report()
   reporter.report(ConsoleReporter)
end

return M
