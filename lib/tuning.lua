local tu = require 'z_tuning/lib/tuning_util'

local note_freq_from_table = function(midi, rats, root_note, root_hz, oct)
   -- print('note_freq_from_table:')
   oct = oct or 2
   local degree = midi - root_note
   local n = #rats
   -- print(string.format('midi = %f, root = %f, n = %f, degree = %f', midi, root_note, n, degree))
   -- tab.print(rats)
   local mf = math.floor(midi)
   if midi == mf then
      local octpow = math.floor(degree / n)
      oct = oct ^ octpow
      local idx = (degree % n) + 1
      local rat = rats[idx]
      return root_hz * rat * oct
   else
      -- interpolate non-integer argument
      local mf = math.floor(midi)
      local f = math.abs(midi - mf)
      local deg1
      if (degree > 0) then
         deg1 = degree + 1
      else
         deg1 = degree - 1
      end
      local idxa = (degree % n) + 1
      local idxb = (deg1 % n) + 1
      -- print(string.format('idxa = %f, idxb = %f', idxa, idxb))
      local octa = (oct ^ (math.floor(degree / n)))
      local octb = (oct ^ (math.floor(deg1 / n)))
      -- print(string.format('octa = %f, octb = %f', octa, octb))
      local a = root_hz * rats[math.floor(idxa)] * octa
      local b = root_hz * rats[math.floor(idxb)] * octb
      return a * math.pow((b / a), f)
   end
end

local interval_ratio_from_table = function(interval, rats, oct)
   oct = oct or 2
   local n = #rats
   local rat = rats[(math.floor(interval) % n) + 1]
   return rat * (oct ^ (math.floor(interval / n)))
end

local bend_table_rats = function(rats)
   local t = {}
   for i,r in ipairs(rats) do
      table.insert(t, (tu.log2(r)*12) - (i-1))
   end
   return t
end

local bend_table_func = function(func)
   local t = {}
   for i=1,12 do
      table.insert(t, func(i) - (i-1))
   end
   return t
end

----------------------------------------------------
-- tuning class

local Tuning = {}
Tuning.__index = Tuning


Tuning.new = function(args)
   local x = setmetatable({}, Tuning)

   -- TODO: fallback value for pseudo-octave should always exceed highest ratio?
   x.pseudo_octave = args.pseudo_octave or 2

   if args.interval_ratio then
      x.interval_ratio = args.interval_ratio
      if args.note_freq then
         x.note_freq = args.note_freq
      else
         local rats = {}
         for i=0,11 do rats[i] = args.interval_ratio(i) end
         x.note_freq = function(midi, root_note, root_hz)
            return note_freq_from_table(midi, rats, root_note, root_hz, x.pseudo_octave)
         end
      end
      x.bend_table = bend_table_func(args.interval_ratio)
   elseif args.ratios then
      x.note_freq = function(midi, root_note, root_hz)
         return note_freq_from_table(midi, args.ratios, root_note, root_hz, x.pseudo_octave)
      end
      x.interval_ratio = function(interval)
         return interval_ratio_from_table(interval, args.ratios, x.pseudo_octave)
      end
      x.bend_table = bend_table_rats(args.ratios)
   elseif args.cents then
      local r = {}
      for i, v in ipairs(data.cents) do
         table.insert(r, 2 ^ v / 1200)
      end
      x.ratios = r
      return Tuning.new(x)
   else
      print("error; don't know how to construct tuning with these arguments: ")
      tab.print(args)
      return nil
   end
   --tab.print(x.bend_table)
   return x
end

return Tuning
