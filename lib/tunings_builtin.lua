local Tuning = require 'z_tuning/lib/tuning'
local JI = require 'lib/intonation'

local tunings = {}

--- standard 12tet 
tunings['edo12'] = Tuning.new {
   note_freq = function(midi, root_note, root_freq)
      local deg = midi - root_note
      return root_freq * (2 ^ ((midi - root_note) / 12))
   end,

   interval_ratio = function(interval)
      return math.pow(2, interval / 12)
   end
}

tunings['ji_normal'] = Tuning.new {
   ratios = JI.normal()
}

tunings['ji_overtone'] = Tuning.new {
   ratios = JI.overtone()
}

tunings['ji_undertone'] = Tuning.new {
   ratios = JI.undertone()
}

-- 43-tone
tunings['ji_partch'] = Tuning.new {
   ratios = JI.partch()
}

-- 168-tone!
tunings['ji_gamut'] = Tuning.new {
   ratios = JI.gamut()
}


return tunings
