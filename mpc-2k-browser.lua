-- mpc-2k-browser.
--
-- @eigen
-- llllllll.co/t/mpc-2k-browser
--
--
-- browse files on vFloppies from a Gotek-formatted USB drive.


local json = include('lib/json')
local inspect = include('lib/inspect')

local ui = require "ui"


-- -------------------------------------------------------------------------
-- STATE

local current_floppy_id = 1


-- -------------------------------------------------------------------------
-- COMMAND

local list_command = "sudo python3 /home/we/dust/code/mpc-2000-floppy-extractor/main.py --src=/dev/sda --floppy 1-99 --out-format json"
local handle = io.popen(list_command)

local floppy_content_json = handle:read("*a")
handle:close()

local floppy_content = json.decode(floppy_content_json)

local floppy_name_list = {}
local floppy_file_list = {}
for floppy_id, floppy_props in ipairs(floppy_content) do
  local floppy_name = floppy_props['name']
  local floppy_files = floppy_props['files']
  table.insert(floppy_name_list, floppy_name)
  table.insert(floppy_file_list, {})
  for _i, file in ipairs(floppy_files) do
    table.insert(floppy_file_list[floppy_id], file["name"])
  end
end


-- -------------------------------------------------------------------------
-- DISPLAY

-- print(inspect(floppy_content))
-- print(inspect(floppy_file_list))

local file_list = ui.ScrollingList.new(8, 10, 1, floppy_file_list[current_floppy_id])


-- -------------------------------------------------------------------------
-- STANDARD API

local fps = 30
local redraw_clock = nil

function init()
  screen.aa(1)
  screen.line_width(1)

  norns.encoders.set_sens(1, 3)
  norns.encoders.set_sens(2, 3)
  norns.encoders.set_accel(1, false)
  norns.encoders.set_accel(2, false)

  redraw_clock = clock.run(
    function()
      local step_s = 1 / fps
      while true do
        clock.sleep(step_s)
        redraw()
      end
  end)
end

function cleanup()
  clock.cancel(redraw_clock)
end

function redraw()
  screen.clear()

  screen.level(15)
  screen.move(0, 8)
  screen.text(current_floppy_id..": "..floppy_name_list[current_floppy_id])
  screen.fill()

  file_list:redraw()

  screen.update()
end

function enc(id,delta)
  local sign = delta > 0 and 1 or -1
  if id == 1 then
    current_floppy_id = util.clamp(current_floppy_id + sign, 1, 99)
    file_list = ui.ScrollingList.new(8, 10, 1, floppy_file_list[current_floppy_id])
  elseif id == 2 then
    file_list:set_index_delta(sign)
  end
end
