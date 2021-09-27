local mod = require 'core/mods'
local util = require 'lib/util'

local state = {
   root_note = 69,
   root_freq = 440
}

--------------
--- first: just some hardcoded tuning funcs
local midihz_edo12= function(midi)
   print('hi midi '..midi)
   return 440 * (2 ^ ((midi-69) / 12))
end

local hzmidi_edo12 = function(hz)
   return util.clamp(math.floor(12 * math.log(freq / 440.0) / math.log(2) + 69.5), 0, 127)
end

local intratio_edo12 = function(int)
   return math.pow(2, int / 12)
end


-- helper function for octave ratio tables
local midihz_octave_ratio_table = function(midi, rats)
   local degree = midi - state.root_note
   local n = #rats
   local octave = math.floor(degree / n)
   local rat = rats[(degree%n)+1]
   return state.root_freq * rat * (2^octave)
end


local intratio_octave_ratio_table = function(interval, rats)
   local n = #rats
   local rat = rats[(int % n)+1]
   return rat * (2 ^ (math.floor(interval/n)))
end

-- "chromaticized" version of ptolemy's intense diatonic
-- (new intervals constructed from major thirds)
local ptolemaic_octave_ratios = {
   1,            -- C  
   4/3 * 4/5,    -- Db
   9/8,          -- D
   3/2 * 4/5,    -- Eb
   5/4,          -- E
   4/3,          -- F
   9/8 * 5/4,    -- F#
   3/2,          -- G
   5/4 * 5/4,    -- G#
   5/3,          -- A
   9/4 * 4/5,    -- Bb
   15/8,         -- B
}

local midihz_ptolemaic = function(midi)
   return midihz_octave_ratio_table(midi, ptolemaic_octave_ratios)
end

local funcs = {
   midihz = { 
      edo12 = midihz_edo12,   
      ptolemaic = midihz_ptolemaic,
   },
   intratio = {
      edo12 = intratio_edo12,
      ptolemaic = intratio_ptolemaic
   }
}

local tuning_keys = {'edo12','ptolemaic'}

--local selected_tuning = 'edo12'
local selected_tuning = 'ptolemaic'

-------------------------------------
-- wrappers for dynamic monkeying

local midihz = function(note)
   print('midihz: '..selected_tuning)
   return (funcs.midihz[selected_tuning])(note)
end

local intratio = function(int)
   return (funcs.intratio[selected_tuning])(int)
end

local hzmidi = function(note)
   -- doing this in general is not really well defined
   -- we could make up something, like "int == nearest scale degree, decimal == cents"
   -- would require constructing some reverse lookup tables, etc
   return hzmidi_edo12(note)
end
--------------------------------------------
local init_params = function()
   params:add_option("tuning", "tuning", tuning_keys,
      function(i)
	 selected_tuning = tuning_keys[i]
      end
   )		     
end

local apply_mod = function()
   print('tuning mod, patching musicutil')
   if not musicutil then
      print('found musicutil')
      musicutil = require 'lib/musicutil'
   end

   -- :/  found some scripts that call it this, still global:
   if MusicUtil then
      MusicUtil = musicutil
   end
   
   print('musicutil tune func, before: ')
   print(musicutil.note_num_to_freq)
   
   musicutil.note_num_to_freq = midihz
   musicutil.freq_to_note_num = hzmidi

   print('musicutil tune func, after: ')
   print(musicutil.note_num_to_freq)
end


-- [optional] hooks are essentially callbacks which can be used by multiple mods
-- at the same time. each function registered with a hook must also include a
-- name. registering a new function with the name of an existing function will
-- replace the existing function. using descriptive names (which include the
-- name of the mod itself) can help debugging because the name of a callback
-- function will be printed out by matron (making it visible in maiden) before
-- the callback function is called.
mod.hook.register("system_post_startup", "tuning mod startup", init_params)

mod.hook.register("script_pre_init", "tuning mod pre_init", apply_mod)
--
-- [optional] menu: extending the menu system is done by creating a table with
-- all the required menu functions defined.
--


-- TODO
--[[
local m = {}

m.key = function(n, z)
  if n == 2 and z == 1 then
    -- return to the mod selection menu
    mod.menu.exit()
  end
end

m.enc = function(n, d)
  if n == 2 then state.x = state.x + d
  elseif n == 3 then state.y = state.y + d end
  -- tell the menu system to redraw, which in turn calls the mod's menu redraw
  -- function
  mod.menu.redraw()
end

m.redraw = function()
  screen.clear()
  screen.move(64,40)
  screen.text_center(state.x .. "/" .. state.y)
  screen.update()
end

m.init = function() end -- on menu entry, ie, if you wanted to start timers
m.deinit = function() end -- on menu exit


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
-- new copies of the menu, hook functions, and state would be loaded replacing
-- the previous registered functions/menu each time a script was run.
--
-- here we provide a single function which allows a script to get the mod's
-- state table. using this in a script would look like:
--
-- local mod = require 'name_of_mod/lib/mod'
-- local the_state = mod.get_state()
--

--[[
local api = {}

api.get_state = function()
  return state
end

return api
--]]
