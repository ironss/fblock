#! /usr/bin/lua

package.path = './?/?.lua;' .. package.path
require('luaunit')
local serpent = require('serpent')

local fb = require('fb')

Test_fb = {}

function Test_fb:test_1()
end

return LuaUnit:run()

