local mod = require 'core/mods'
local util = require 'lib/util'

local tuning = require 'tuning/lib/tuning'
local tunings_builtin = require 'tuning/lib/tunings_builtin'

--local
tuning_state = {
   root_note = 69,
   root_freq = 440,
   selected_tuning = 'ptolemaic'
}

--local
tunings = {}

--local
tuning_keys={}

for k,v in pairs(tunings_builtin) do
   tunings[k] = v
   table.insert(tuning_keys, k)
end

-----
-- TODO: read additional tunings from disk

-------------------------------------
-- wrappers for dynamic monkeying

local midi_hz = function(note)
   --print('midi_hz: '..tuning_state.selected_tuning)
   return tunings[tuning_state.selected_tuning].midi_hz(note, tuning_state.root_note, tuning_state.root_freq)
end

local interval_ratio = function(interval)
   return tunings[tuning_state.selected_tuning].interval_ratio(interval)
end

local apply_mod = function()
   print('tuning mod: patching musicutil')
   
   if not musicutil then
      musicutil = require 'lib/musicutil'
   end
   
   musicutil.note_num_to_freq = midi_hz

   if MusicUtil then
      MusicUtil = musicutil
   end
   
   if Musicutil then
      Musicutil = musicutil
   end
   
end


-- mod.hook.register("system_post_startup", "tuning mod startup", ...)

mod.hook.register("script_pre_init", "tuning mod pre_init", apply_mod)

--[[
local m = {}

m.key = function(n, z)
  if n == 2 and z == 1 then
    -- return to the mod selection menu
    mod.menu.exit()
  end
end

m.enc = function(n, d)
  if n == 2 then tuning_state.x = tuning_state.x + d
  elseif n == 3 then tuning_state.y = tuning_state.y + d end
  -- tell the menu system to redraw, which in turn calls the mod's menu redraw
  -- function
  mod.menu.redraw()
end

m.redraw = function()
  screen.clear()
  screen.move(64,40)
  screen.text_center(tuning_state.x .. "/" .. tuning_state.y)
  screen.update()
end

m.init = function()
   scan_tuning_files()
end


m.deinit = function() end


-- register the mod menu
--
-- NOTE: `mod.this_name` is a convienence variable which will be set to the name
-- of the mod which is being loaded. in order for the menu to work it must be
-- registered with a name which matches the name of the mod in the dust folder.
--
mod.menu.register(mod.this_name, m)
--]]

--
-- [optional] returning a value from the module allows the mod to provide
-- library functionality to scripts via the normal lua `require` function.
--
-- NOTE: it is important for scripts to use `require` to load mod functionality
-- instead of the norns specific `include` function. using `require` ensures
-- that only one copy of the mod is loaded. if a script were to use `include`
-- new copies of the menu, hook functions, and tuning_state would be loaded replacing
-- the previous registered functions/menu each time a script was run.
--
-- here we provide a single function which allows a script to get the mod's
-- tuning_state table. using this in a script would look like:
--
-- local mod = require 'name_of_mod/lib/mod'
-- local the_tuning_state = mod.get_state()
--

local api = {}

api.get_state = function()
  return tuning_state
end

return api
