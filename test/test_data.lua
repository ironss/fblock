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


function Test_data_spec:test_create_new_item()
end


Test_data_item = {}

function Test_data_item:test_reset()
end

function Test_data_item:test_set()
end

local code = LuaUnit:run()
return os.exit(code)

