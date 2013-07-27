#! /usr/bin/lua

package.path = './?/?.lua;' .. package.path
require('luaunit')
local serpent = require('serpent')

local data = require('data_item')



Test1_data_spec = {}

function Test1_data_spec:test1_create_positional()
   local ds1 = data.spec_new('x', 'real', 0)
   
   assertEquals(ds1.name, 'x')
   assertEquals(ds1.datatype, 'real')
   assertEquals(ds1.default_value, 0)
end


Test_data_item = {}

function Test_data_item:test_create_data_item_default()
   local ds1=data.spec_new('x', 'real', 0)
   assertNotEquals(ds1, nil)
   
   local s=ds1:new_item('S')
   assertNotEquals(s, nil)
   assertEquals(s.name, 'S')
end


function Test_data_item:test_set_value()
   local ds1=data.spec_new('x', 'real', 0)
   assertNotEquals(ds1, nil)
   
   local s=ds1:new_item('S')
   assertNotEquals(s, nil)
   assertEquals(s.name, 'S')
   
   assertNotEquals(s.value, 123)
   s:set(123)
   assertEquals(s.value, 123)
end

function Test_data_item:test_reset_data_item()
   local ds1=data.spec_new('x', 'real', 0)
   assertNotEquals(ds1, nil)
   
   local s=ds1:new_item('S')
   assertNotEquals(s, nil)
   assertEquals(s.name, 'S')
   
   s:set(123)
   assertEquals(s.value, 123)
   s:reset()
   assertEquals(s.value, 0)
end

function Test_data_item:test_create_2_data_items()
   local ds1=data.spec_new('x', 'real', 0)
   assertNotEquals(ds1, nil)
   
   local s=ds1:new_item('S')
   assertNotEquals(s, nil)
   assertEquals(s.name, 'S')
   
   local t=ds1:new_item('T')
   assertNotEquals(t, nil)
   assertEquals(t.name, 'T')
   
   s:set(111)
   t:set(222)
   
   assertEquals(s.value, 111)
   assertEquals(t.value, 222)
end


function Test_data_item:test_create_data_item_reset_value()
   local ds1=data.spec_new('x', 'real', 0)
   assertNotEquals(ds1, nil)
   
   local s=ds1:new_item('S', -1)
   assertNotEquals(s, nil)

   s:set(555)
   assertEquals(s.value, 555)
   s:reset()
   assertEquals(s.value, -1)
end


local code = LuaUnit:run()
return os.exit(code)

