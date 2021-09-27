-- helper functions for octave ratio tables
-- note number is assumed to be an integer!
local midi_hz_from_table = function(midi, rats, root_note, root_hz, oct)
   oct = oct or 2
   local degree = midi - root_note
   local n = #rats
   return root_hz * rats[(degree%n)+1] * (oct^(math.floor(degree/n)))
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

Tuning.new = function(args)
   local x = setmetatable({}, Tuning)

   x.pseudo_octave = args.pseudo_octave or 2
   
   if args.midi_hz and args.interval_ratio then
      x.midi_hz = args.midi_hz
      x.interval_ratio = args.interval_ratio
   elseif args.ratios then
      x.midi_hz = function(midi, root_note, root_hz)
	 return midi_hz_from_table(midi, args.ratios, root_note, root_hz, x.pseudo_octave)
      end
      x.interval_ratio = function(interval)
	 return interval_ratio_from_table(interval, args.ratios, x.pseudo_octave)
      end
   else
      print("error; don't know how to construct tuning with these arguments: ")
      tab.print(args)
      return nil
   end

   return x
end

return Tuning
