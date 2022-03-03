--- a chromatic scale constructed from EDO8/EDO16

-- EDO8 ratios are applied to chromatic degress closest in pythagorean tuning
-- intermediate degrees are interpolated with EDO16
local phi8 = math.pow(2, (1/8))
local phi16 = math.pow(2, (1/16))
local deg8 = {1, 3, 4, 6, 7, 9, 10, 12}
local deg16 = {2, 5, 8, 11}
local r = {}
local theta = 1
for _,deg in ipairs(deg8) do
    r[deg] = theta
    theta = theta * phi8
end
for _,deg in ipairs(deg16) do
    r[deg] = r[deg-1] * phi16
end

return { ratios = r }