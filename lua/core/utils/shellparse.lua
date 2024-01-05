local lpeg = require "lpeg"
local P = lpeg.P
local C = lpeg.C
local Ct = lpeg.Ct
local Cp = lpeg.Cp
local Cs = lpeg.Cs
local B = lpeg.B

local s = [[ a/b/c/d/f/e/f/\/\//g ]]
local Slash = C "/"
local Escaped = C(P "\\/" ^ 1)
local Elem = C(((1 - Escaped) + (1 - Slash)) ^ 1) * Slash ^ 0

pp(Elem:match(s))
