local a = 5 ^ 0.5
local b = 5 ^ 0.25
local c = a * b
return { ratios = {
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
} }