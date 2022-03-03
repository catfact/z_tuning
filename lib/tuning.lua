-- helper functions for octave ratio tables
local note_freq_from_table = function(midi, rats, root_note, root_hz, oct)
   -- FIXME [OPTIMIZE]: 
   -- in general, there can be more memoization and explicit use of integer types
   -- when oct==2^N (as is near-universal), can maybe use some bitwise ops
   -- fractional degrees are quite costly (x2, plus exponential intep)
   oct = oct or 2
   local degree = midi - root_note
   local n = #rats
   local mf = math.floor(midi)
   if midi == mf then
      return root_hz * rats[(degree%n)+1] * (oct^(math.floor(degree/n)))
   else
      local mf = math.floor(midi)
      local f = math.abs(midi - mf)
      local deg1
      if (degree > 0) then 
	      deg1 = deg + 1
      else
	      deg1 = deg - 1
      end
      local a = root_hz * rats[(degree%n)+1] * (oct^(math.floor(degree/n)))
      local b = root_hz * rats[(deg1%n)+1] * (oct^(math.floor(deg1/n)))      
      return a * math.pow((b/a), f)
   end
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
   
   if args.note_freq and args.interval_ratio then
      x.note_freq = args.note_freq
      x.interval_ratio = args.interval_ratio
   elseif args.ratios then
      x.note_freq = function(midi, root_note, root_hz)
	   return note_freq_from_table(midi, args.ratios, root_note, root_hz, x.pseudo_octave)
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
