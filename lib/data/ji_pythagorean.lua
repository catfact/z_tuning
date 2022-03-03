local function p5(a, b)
      return (3^a) / (2^b)
   end
   local function p4(a, b)
      return (2^a) / (3^b)
   end
   return { 
      ratios = {
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
}