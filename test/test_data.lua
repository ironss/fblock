#! /usr/bin/lua

package.path = './?/?.lua;' .. package.path
require('luaunit')
local serpent = require('serpent')

local data = require('data_item')



Test_data_spec = {}

function Test_data_spec:test_create_positional()
   local ds1 = data.spec_new('x', 'real', 0)
   
   assertEquals(ds1.name, 'x')
   assertEquals(ds1.datatype, 'real')
   assertEquals(ds1.default_value, 0)
end



return LuaUnit:run()

