local Tuning = require 'tuning/lib/tuning'

return {
   --- standard 12tet 
   edo12 = Tuning.new {
	 midi_hz = function(midi, root_note, root_freq)
	    local deg = midi - root_note
	    return root_freq * (2 ^ ((midi - root_note)/12))
	 end,
	 
	 interval_ratio = function(interval)
	    return math.pow(2, interval/12)
	 end
   },
   
   -- "chromaticized" version of ptolemy's intense diatonic
   -- (new intervals constructed from major thirds)
   ptolemaic = Tuning.new {
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
}
