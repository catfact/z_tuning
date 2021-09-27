
local mod = require 'tuning/lib/mod'
local tunings = mod.get_tuning_data()
local state = mod.get_tuning_state()

init = function()
   for k,tun in pairs(tunings) do
      print(k)
      --tab.print(v)
      for i=0,11 do
	 local note = state.root_note + i
	 local freq = tun.note_freq(note, state.root_note, state.root_freq)
	 print('  n = '..note..'; r = '..freq/state.root_freq)
      end
      print('')
   end
end
