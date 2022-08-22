local mod = require 'core/mods'
local util = require 'lib/util'
local ControlSpec = require 'controlspec'

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

local build_tuning_keys_reversed = function()
   table.sort(tuning_keys)
   tuning_keys_rev = {}
   for i, v in ipairs(tuning_keys) do
      tuning_keys_rev[v] = i
   end
end

local setup_tunings = function()
   tunings = {}
   tuning_keys = {}
   tuning_keys_rev = {}

   -- add built-in tunings
   for k, v in pairs(tunings_builtin) do
      tunings[k] = v
      table.insert(tuning_keys, k)
   end

   -- add tunings from disk
   local tf = tuning_files.load_files()
   for k, v in pairs(tf) do
      tunings[k] = v
      table.insert(tuning_keys, k)
   end
   num_tunings = #tuning_keys
   build_tuning_keys_reversed()
   
   print("tuning_keys_rev:")
   tab.print(tuning_keys_rev)
   
end


local tuning_change_callback = function() end

local calc_bend_root = function()
   local st = tu.ratio_st(tuning_state.root_freq / tu.midi_hz(tuning_state.root_note))
   tuning_state.bend_root = st
end

-- set the root note number, without changing root frequency
-- this effects a transposition
local set_root_note = function(num)
   tuning_state.root_note = num
   calc_bend_root()
   params:set('zt_root_note_adj', num, true)
   params:set('zt_root_note_piv', num, true)
   tuning_change_callback()
end

-- set the root frequency, without changing root note
-- this effects a transposition
local set_root_frequency = function(freq)
   tuning_state.root_freq = freq
   calc_bend_root()
   params:set('zt_root_freq', freq, true)
   tuning_change_callback()
end

-- set the root note, updating the root frequency,
-- preserving the ratio of root note freq to 12tet A440
local set_root_note_adjusting = function(num)
   local interval = num - tuning_state.root_note
   local ratio = tunings['edo12'].interval_ratio(interval)
   local new_freq = tuning_state.root_freq * ratio
   -- FIXME, why are we rounding here? (only to 1/16hz but still)
   -- if its just for display purposes that seems silly
   new_freq = math.floor(new_freq * 16) * 0.0625 
   tuning_state.root_note = num
   tuning_state.root_freq = new_freq
   calc_bend_root()
   params:set('zt_root_note', num, true)
   params:set('zt_root_note_piv', num, true)
   params:set('zt_root_freq', new_freq, true)
   tuning_change_callback()
end

-- set the root note, updating the root frequency,
-- such that frequency of new root note does not change
local set_root_note_pivoting = function(num)
   local freq = tunings[tuning_state.selected_tuning].note_freq(num, tuning_state.root_note, tuning_state.root_freq)
   tuning_state.root_note = num
   tuning_state.root_freq = freq
   params:set('zt_root_note', num, true)
   params:set('zt_root_note_adj', num, true)
   params:set('zt_root_freq', freq, true)
   calc_bend_root()
   tuning_change_callback()
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
local set_tuning_id = function(key)
   tuning_state.selected_tuning = key
   calc_bend_root()
   tuning_change_callback()
end

-- set the current tuning, by numerical index
local set_tuning_index = function(idx)
   tuning_state.selected_tuning = tuning_keys[idx]
   calc_bend_root()
   tuning_change_callback()
end

-- add a new tuning object to the list
-- @param k: the key to use
-- @param t: a Tuning table (e.g. constructed with Tuning.new)
local add_tuning = function(k, t)
   tunings[k] = t
   table.insert(tuning_keys, k)
   num_tunings = #tuning_keys
   build_tuning_keys_reversed()
   -- hack: change the options list for the corresponding param
   local p = params.params[params.lookup('zt_tuning')]
   p.options = tuning_keys
   p.count = num_tunings
end

-----------------------------------------------------
-- MONKEY TIME
-- patch the `musicutil` library functions
local apply_mod = function()
   print('applying tuning mod')
   local musicutil = require 'musicutil'
   musicutil.note_num_to_freq = function(num)
      local freq = tunings[tuning_state.selected_tuning].note_freq(num, tuning_state.root_note, tuning_state.root_freq)
      --print(''..num..' -> '..freq)
      return freq
   end
   musicutil.interval_to_ratio = interval_to_ratio

   -- FIXME? this is a tricky one...
   -- (in fact i'm going to say, impossible in general 
   -- since int->ratio need not be invertible/continuous/monotonic
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
   
   -- a pretty nasty issue with option params:
   -- in pset, option param stores index as a number.
   -- this makes it useless if the option list is dynamically built
   -- only workaround i can think is to *also* store the ID string as a separate param
   -- this gets very ugly! so for now i'm not gonna worry about it...
   
   params:add_group("Z_TUNING", 5)

   params:add({type='option', name='tuning', id='zt_tuning', 
      options=tuning_keys, action=set_tuning_index})

   params:add({type='number', name='root note (transposing)', id='zt_root_note', 
   min=0, max=127, default=69, action=set_root_note})

   params:add({type='number', name='root note (adjusting)', id='zt_root_note_adj', 
   min=0, max=127, default=69, action=set_root_note_adjusting})

   params:add({type='number', name='root note (pivoting)', id='zt_root_note_piv', 
   min=0, max=127, default=69, action=set_root_note_pivoting})

   params:add({type='control',name='root frequency', id='zt_root_freq', 
   controlspec = ControlSpec.FREQ, action = set_root_frequency})
end

local pre_init = function()
   local init1 = init
   init = function()
      init1()
      add_mod_params()
      -- after adding our params, we want to re-load default/existing values
      -- but, we don't want to re-bang script params, 
      -- or bang our params which have conflicting side-effects
      params:read(nil, true)
      local bangers = { 'zt_tuning', 'zt_root_note', 'zt_root_freq'}
      for _,id in ipairs(bangers) do 
         params.params[params.lookup[id]]:bang()
      end
   end
end

local set_tuning_change_callback = function(f) tuning_change_callback = f end

local clear_tuning_change_callback = function() tuning_change_callback = function() end end

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
      set_tuning_index(i)
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
      local freq = math.floor((tuning_state.root_freq + (d * 0.0625)) * 16) * 0.0625
      tuning_state.root_freq = util.clamp(freq, 1, 10000)
      set_root_frequency(freq)
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
   screen.text("tuning: " .. tuning_state.selected_tuning)

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

   --- draw bend table:
   -- TODO?
   --[[
   local bt = tunings[tuning_state.selected_tuning].bend_table
   local n = #bt
   local w = math.floor(128 / n)
   local h = 0
   local y = 50
   local x = 0
   screen.level(12)
   for i=1,n do
      x = (i-1)*w
      h = bt[i].linlin(0, 100, -10, 10)
      screen.rect(x, y, x+w, y+h); screen.fill()
   end
   --]]

   screen.update()
end

m.init = function()
  -- print ('z_tuning: init menu?')
   -- (nothing to do)
end

m.deinit = function()
   -- print ('z_tuning: deinit menu?')
   -- (nothing to do)
end

mod.menu.register(mod.this_name, m)


-----------------------------
---- hooks!

mod.hook.register("system_post_startup", "init tuning mod", mod_init)

mod.hook.register("system_post_startup", "recall tuning mod settings", recall_tuning_state)

mod.hook.register("system_pre_shutdown", "save tuning mod settings", save_tuning_state)

mod.hook.register("script_pre_init", "add tuning mod parameters", pre_init)

mod.hook.register("script_post_cleanup", "clean up tuning mod callbacks", clear_tuning_change_callback)

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
api.set_tuning_index = set_tuning_index
api.set_tuning_id = set_tuning_id 
api.get_bend_semitones = get_bend_semitones
api.set_tuning_change_callback = set_tuning_change_callback
api.clear_tuning_change_callback = clear_tuning_change_callback
api.add_tuning = add_tuning

return api
