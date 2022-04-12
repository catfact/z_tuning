local mod = require 'core/mods'
local util = require 'lib/util'

local tu = require 'z_tuning/lib/tuning_util'

local tuning = require 'z_tuning/lib/tuning'
local tunings_builtin = require 'z_tuning/lib/tunings_builtin'
local tuning_files = require 'z_tuning/lib/tuning_files'

local tuning_state = {
   root_note = 69,
   root_freq = 440.0,
   selected_tuning = 'ji_ptolemaic'
}

local tunings = {}
local tuning_keys = {}
local tuning_keys_rev = {}
local num_tunings = 0

local setup_tunings = function()
   tunings = {}
   tuning_keys = {}
   tuning_keys_rev = {}
   num_tunings = 0

   -- add built-in tunings
   for k, v in pairs(tunings_builtin) do
      tunings[k] = v
      table.insert(tuning_keys, k)
      num_tunings = num_tunings + 1
   end

   -- add tunings from disk
   local tf = tuning_files.load_files()
   for k, v in pairs(tf) do
      tunings[k] = v
      table.insert(tuning_keys, k)
      num_tunings = num_tunings + 1
   end
   table.sort(tuning_keys)
   for i, v in ipairs(tuning_keys) do
      tuning_keys_rev[v] = i
   end
end

local calc_bend_root = function()
   local st = tu.ratio_st(tuning_state.root_freq / tu.midi_hz(tuning_state.root_note))
   tuning_state.bend_root = st
end

-- set the root note number, without changing root frequency
-- this effects a transposition
local set_root_note = function(num)
   tuning_state.root_note = num
   calc_bend_root()
end

-- set the root frequency, without changing root note
-- this effects a transposition
local set_root_freq = function(freq)
   tuning_state.root_freq = freq
   calc_bend_root()
end

-- set the root note, updating the root frequency,
-- preserving the ratio of root note freq to 12tet A440
local set_root_note_adjusting = function(num)
   local interval = num - tuning_state.root_note
   local ratio = tunings['edo12'].interval_ratio(interval)
   local new_freq = tuning_state.root_freq * ratio
   new_freq = math.floor(new_freq * 16) * 0.0625 -- ???
   tuning_state.root_note = num
   tuning_state.root_freq = new_freq
   calc_bend_root()
end

-- set the root note, updating the root frequency,
-- such that frequency of new root note does not change
local set_root_note_pivoting = function(num)
   local freq = tunings[tuning_state.selected_tuning].note_freq(num, tuning_state.root_note, tuning_state.root_freq)
   tuning_state.root_note = num
   tuning_state.root_freq = freq
   calc_bend_root()
end

-- return the frequency ratio for a given number of scale degrees from the root.
-- (argument is `floor`d to an integer)
local interval_ratio = function(interval)
   return tunings[tuning_state.selected_tuning].interval_ratio(interval)
end

-- return the amount of deviation from 12tet in semitones, for a given note
local get_bend_semitones = function(num)
   local bt = tunings[tuning_state.selected_tuning].bend_table
   local n = #bt
   print("bend n = "..n)
   local idx = ((num - tuning_state.root_note) % n) + 1
   print("bend idx = "..idx)
   return bt[idx] + tuning_state.bend_root
end

-- set the current tuning, by ID string
local set_tuning_id = function(id)
   local idx = tuning_keys_rev[id]
   tuning_state.selected_tuning = tuning_keys[idx]
   calc_bend_root()
end

-- set the current tuning, by numerical index
local select_tuning_index = function(idx)
   tuning_state.selected_tuning = tuning_keys[idx]
   calc_bend_root()
end


-- patch the `musicutil` library functions
local apply_mod = function()
   print('applying tuning mod')
   local musicutil = require 'musicutil'
   musicutil.note_num_to_freq = function(num)
      return tunings[tuning_state.selected_tuning].note_freq(num, tuning_state.root_note, tuning_state.root_freq)
   end
   musicutil.interval_to_ratio = interval_to_ratio

   -- FIXME? this is a tricky one...
   -- (in fact i'm going to say, impossible in general 
   -- since int->ratio not be invertible/continuous/monotonic
   -- musicutil.ratio_to_interval = ...
end

----------------------
--- state persistence
local state_path = _path.data .. 'tuning_state.lua'

local save_tuning_state = function()
   print('save tuning state')
   local f = io.open(state_path, 'w')
   io.output(f)
   io.write('return { \n')
   local keys = {'selected_tuning', 'root_note', 'root_freq'}
   for _, k in pairs(keys) do
      local v = tuning_state[k]
      local vstr = v
      if type(v) == 'string' then
         vstr = "'" .. v .. "'"
      end
      io.write('  ' .. k .. ' = ' .. vstr .. ',\n')
   end
   io.write('}\n')
   io.close(f)
end

local recall_tuning_state = function()
   print('recall tuning state')
   local f = io.open(state_path)
   if f then
      io.close(f)
      tuning_state = dofile(state_path)
   end
end

local mod_init = function()
   print('init tuning mod')
   tuning_files.bootstrap()
   setup_tunings()
   apply_mod()
   calc_bend_root()
end

local add_mod_params = function()
   print('add tuning mod params')
   --- TODO!!!
end

-----------------------------
---- hooks!

mod.hook.register("system_post_startup", "init tuning mod", mod_init)

mod.hook.register("system_post_startup", "recall tuning mod settings", recall_tuning_state)

mod.hook.register("system_pre_shutdown", "save tuning mod settings", save_tuning_state)

mod.hook.register("script_pre_init", "add tuning mod parameters", add_mod_params)

-----------------------------
---- menu UI

local edit_select = {
   [1] = 'tuning',
   [2] = 'note',
   [3] = 'freq'
}
local num_edit_select = 3

local m = {
   edit_select = 1,
   freq_mode_adjusting = true
}

m.key = function(n, z)
   if n == 3 then
      m.freq_mode_adjusting = (z > 0)
   end

   if n == 2 and z > 0 then
      -- return to the mod selection menu
      mod.menu.exit()
   end

end

m_enc = {
   [2] = function(d)
      m.edit_select = util.clamp(m.edit_select + d, 1, num_edit_select)
   end,

   [3] = function(d)
      (m_incdec[m.edit_select])(d)
   end
}

m_incdec = {
   -- edit tuning selection
   [1] = function(d)
      local sel = tuning_state.selected_tuning
      local i = tuning_keys_rev[sel]
      i = util.clamp(i + d, 1, num_tunings)
      tuning_state.selected_tuning = tuning_keys[i]
   end,
   -- edit root note
   [2] = function(d)
      local num = util.clamp(tuning_state.root_note + d, 0, 127)
      if m.freq_mode_adjusting then
         set_root_note_adjusting(num)
      else
         set_root_note(num)
      end
   end,
   -- edit base frequency
   [3] = function(d)
      tuning_state.root_freq = math.floor((tuning_state.root_freq + (d * 0.0625)) * 16) * 0.0625
      tuning_state.root_freq = util.clamp(tuning_state.root_freq, 1, 10000)
   end
}

m.enc = function(n, d)
   if m_enc[n] then
      (m_enc[n])(d)
   end
   mod.menu.redraw()
end

m.redraw = function()
   screen.clear()

   screen.move(0, 10)
   if edit_select[m.edit_select] == 'tuning' then
      screen.level(15)
   else
      screen.level(4)
   end
   screen.text("temperament: " .. tuning_state.selected_tuning)

   screen.move(0, 20)
   if edit_select[m.edit_select] == 'note' then
      screen.level(15)
   else
      screen.level(4)
   end
   screen.text("root note: " .. tuning_state.root_note)

   screen.move(0, 30)
   if edit_select[m.edit_select] == 'freq' then
      screen.level(15)
   else
      screen.level(4)
   end
   screen.text("root freq: " .. tuning_state.root_freq)

   --- TODO:
   -- show some more basic data on selected tuning
   --- (pseudo-octave, degree count)

   screen.update()
end

m.init = function()
  print ('z_tuning: init menu?')
   -- (nothing to do)
end

m.deinit = function()
   print ('z_tuning: deinit menu?')
   -- (nothing to do)
end

mod.menu.register(mod.this_name, m)

-----------------------------
---- hooks!

mod.hook.register("system_post_startup", "init tuning mod", mod_init)

mod.hook.register("system_post_startup", "recall tuning mod settings", recall_tuning_state)

mod.hook.register("system_pre_shutdown", "save tuning mod settings", save_tuning_state)

mod.hook.register("script_pre_init", "add tuning mod parameters", add_mod_params)

----------------------
--- API

local api = {}

-- return the current state of the mod, a table containing:
api.get_tuning_state = function()
   return tuning_state
end

-- get the entire collection of tuning data
api.get_tuning_data = function()
   return tunings
end

api.save_state = save_tuning_state
api.recall_state = recall_tuning_state
api.set_root_note = set_root_note
api.set_root_frequency = set_root_frequency
api.set_root_note_adjusting = set_root_note_adjusting
api.set_root_note_pivoting = set_root_note_pivoting
api.select_tuning_index = select_tuning_index
api.select_tuning_id = set_tuning_id 
api.get_bend_semitones = get_bend_semitones

return api
