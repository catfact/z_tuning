-- helper function for octave ratio tables
local midi_hz_from_table = function(midi, rats, root_note, root_hz, oct)
   oct = oct or 2
   local degree = midi - root_note
   local n = #rats
   local octave = math.floor(degree / n)
   local rat = rats[(degree%n)+1]
   return root_hz * rat * (oct^octave)
end


local interval_ratio_from_table = function(interval, rats, oct)
   oct = oct or 2
   local n = #rats
   local rat = rats[(int % n)+1]
   return rat * (oct ^ (math.floor(interval/n)))
end

----------------------------------------------------
-- tuning class

local Tuning = {}
Tuning.__index = Tuning

Tuning.new = function(...)
   local x = setmetatable({},Tuning)

   x.pseudo_octave = arg.pseudo_octave or 2
   
   if arg.midi_hz and arg.interval_ratio then
      x.midi_hz = midi_hz
      x.interval_ratio = interval_ratio
   elseif arg.ratios then
      x.midi_hz = function(midi, root_note, root_hz)
	 return midi_hz_from_table(ratios, x.pseudo_octave, root_note, root_hz)
      end
      x.interval_ratio = function(int) return interval_ratio_from_table(ratios, x.pseudo_octave) end
   else
      print("error; don't know how to construct tuning with these arguments: ")
      tab.print(arg)
      return nil
   end

   
   return x
end

return Tuning
