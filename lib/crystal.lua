-- utilities for working with pitch tuples
-- each element of a pitch tuple represents an exponent to be applied to a prime number
-- the list of primes ("crystallization axes") is arbitrary,
-- but the first prime is assumed to be 2.
tuple = {
    -- test if a tuple is an element of a table of tuples
    -- @param Y: tuple to test
    -- @param XX: table of tuples
    in_list = function(Y, XX)
        for _,X in ipairs(XX) do
            for i,y in ipairs(Y) do
                if X(i) ~= y then goto X_continue end
                return true
            end
            ::X_continue::
        end
        return false
    end,
    -- reduce a tuple to a ratio, and wrap to 1 octave
    -- @param X: tuple to be reduced
    -- @param P: array of primes
    reduce_8v = function(X, P)
        local y = 1
        for i,p in ipairs(P) do
            y = y * (p ^ X[i])
        end
        local shift = 0
        while y < 1 do shift = shift + 1; y = y * 2 end
        while y > 2 do shift = shift - 1; y = y / 2 end
        return {y, shift}
    end,
    -- check if two tuples are equal under octave transposition
    equal_8v = function(X, Y)
        local nd = #X
        for i=2,nd do
            if X[i] ~= Y[i] then return false end
        end
        return true
    end,
    -- test if a tuple is an element of a table of tuples, under octave transposition,
    -- and add it if it is not
    -- @param Y: tuple to test
    -- @param XX: table of tuples
    add_unique_8v = function(Y, XX)
        for _,X in ipairs(XX) do
            if equal_8v(Y, X) then
                return
            end
            table.insert(XX, Y)
        end
    end,
    -- make a hash string
    build_hash = function(X)
        local str = ""
        for _,x in ipairs(X) do str = str..x.."," end
        return str
    end

}

-- utility

-- @function crystal
-- @param n: the desired number of unique ratios to produce
-- @param seed (table): initial set of ratios. canonic value is {1}
-- @param axes: table with the ratios to act as growth axes. canonically, a list of the first N primes
-- @param axis_shift: a table with "shift" amounts. for ease of implementation, positive and negative shift amounts have different meanings:
--   - positive numbers denote an iteration count at which this axes _must_ be used (or "extended into" in tenney's parlance.)
--   - negative numbers denote a number of iterations by which the extension into a given axis is _delayed_.
--   - a zero, or any non-number type, represents no shift
-- @param choice_rule: determines the rule by which the algorithm chooses the axis to use for the next ratio,
--   when multiple axes would yield the same harmonic distance
--   the available choices are 'both' (the default), 'high', 'low', and 'random'
function crystal(n, axes, shifts, choice)
    local nd = #axes
    local ax_count = {} -- for shifts
    for _,v in ipairs(axes) do
        table.insert(ax_count, 0)
    end

    -- un-reduced ratios
    R = {}
    -- unique ratios under octave transposition
    Q = {}
    local m = #q
    while m < n do
        -- list of candidates
        local C = {}
        for _,X in R do
            -- FIXME: inefficient;
            -- we should keep track of the "perimeter" cells and only test those
        end
        local Y = {table.unpack(X)}

        for d=1,nd do
            local up = X[d]+1
            local down = X[d]-1
        end
    end


end
