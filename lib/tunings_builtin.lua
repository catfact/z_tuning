local Tuning = require 'tuning/lib/tuning'
local JI = require 'lib/intonation'

local tunings = {}

--- standard 12tet 
tunings['edo_12'] = Tuning.new {
   note_freq = function(midi, root_note, root_freq)
      local deg = midi - root_note
      return root_freq * (2 ^ ((midi - root_note)/12))
   end,
   
   interval_ratio = function(interval)
      return math.pow(2, interval/12)
   end
}
   
-- "chromaticized" version of ptolemy's intense diatonic
-- (new intervals constructed from major thirds)
tunings['ji_ptolemaic'] = Tuning.new {
   ratios = {	    
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
}

tunings['ji_normal'] = Tuning.new { ratios = JI.normal() }

tunings['ji_overtone'] = Tuning.new { ratios = JI.overtone() }

tunings['ji_undertone'] = Tuning.new { ratios = JI.undertone() }

local pythag = function()
   local function p5(a, b)
      return (3^a) / (2^b)
   end
   local function p4(a, b)
      return (2^a) / (3^b)
   end
   return {
      1,          -- unison
      p4(8, 5),   -- min 2nd
      p5(2, 3),   -- Maj 2nd
      p4(5, 3),   -- min 3rd
      p5(4, 6),   -- Maj 3rd
      p4(2, 1),   -- p 4th
      --p4(10, 6),  -- dim 5th
      p5(6, 9),   -- aug 4th
      p5(1, 1),   -- p 5th
      p4(7, 4),   -- min 6th
      p5(3, 4),   -- maj 6th
      p4(4, 2),   -- min 7th
      p5(5, 7),   -- maj 7th
   }
end
tunings['ji_pythagorean'] = Tuning.new { ratios = pythag() }

-- quarter-comma meantone
local qmt = function()
   local a = 5 ^ 0.5
   local b = 5 ^ 0.25
   local c = a * b
   return {
      1,           -- unison
      8 * c / 25,   -- min 2nd
      a / 2,       -- Maj 2nd
      4 * b / 5,   -- min 3rd
      5 / 4,       -- Maj 3rd
      2 * c / 5,   -- p 4th
      --16 * a/25, -- dim 5th
      5 * a / 8,   -- aug 4th
      b,           -- p 5th
      8 / 5,       -- min 6th
      c / 2,       -- Maj 6th
      4 * a / 5,   -- min 7th
      5 * b / 4    -- Maj 7th
   }
end

tunings['meantone'] = Tuning.new { ratios = qmt() }

-- werckmeister III
local werck3 = function()
   local a = 2 ^ 0.5
   local a2 = 2 ^ 0.25
   return {
      1,
      256 / 243,
      64 / 81 * a,
      32 / 27,
      256 / 243 * a2,
      4 / 3,
      1024 / 729,
      8 / 9 * (8 ^ 0.25),
      128 / 81,
      1024 / 729 * a2,
      16 / 9,
      128 / 81 * a2
   }
end
tunings['werck3'] = Tuning.new { ratios = werck3() }


return tunings
