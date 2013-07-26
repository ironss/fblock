#! /usr/bin/lua

package.path = './?/?.lua;' .. package.path
require('luaunit')
local serpent = require('serpent')

local fb = require('fb')
local fblib = require('fblib')



Test_fblib_generator = {}

function Test_fblib_generator:test_ramp()
   local fc_spec_ramp = fb.fc_spec_new{
      name='Chart_Ramp_1',
      inputs={
         { 'R1', fblib.ramp },
      },
      outputs={
      },
      function_blocks={
      },
      links={
      },
   }
   
   local fc_ramp = fb.fc_instance_new('test_ramp', fc_spec_ramp)
   
   assertEquals(fc_ramp.name, 'test_ramp')

   fc_ramp:reset()
   assertEquals(fc_ramp.data_items['test_ramp.R1.q'].value, nil)

   for i = 0, 10 do
      fc_ramp:step()
      assertEquals(fc_ramp.data_items['test_ramp.R1.q'].value, i)
   end
end

--[[

Test_fblib_arithmetic = {}

function Test_fblib_arithmetic:test_add()
   local fc_spec_add = fb.fc_spec_new{
      name='Chart_1',
      inputs={
         { 'R1', fblib.ramp },
         { 'R2', fblib.ramp },
      },
      outputs={
         { 'S1', sink },
      },
      function_blocks={
         { 'ADD1', add },
      }
      links={
         { { 'R1', 'q' },   { 'ADD1', 'a' } },
         { { 'R2', 'q' },   { 'ADD1', 'b'  }},
         { { 'ADD1', 'q' }, { 'S1', 'x' } },
      },
   }
   
   local fc_test_add = fb.fc_instance_new('test_add', fc_spec_add)
   
   assertEquals(fc_inst_1.name, 'test_add')
   assertEquals(fc_inst_1.data_items['test_add.ADD1.a'].is_driven_by, fc_inst_1.data_items['Test_1.R1.q'])


   local fc_inst_1 = fb.fc_instance_new('test_add', fc_spec_add)
   
   assertEquals(fc_inst_1.name, 'Test_1')
   assertEquals(fc_inst_1.data_items['Test_1.ADD1.a'].is_driven_by, fc_inst_1.data_items['Test_1.R1.q'])

   fb.fc_reset(fc_inst_1)
   fb.fc_step(fc_inst_1)
   assertEquals(fc_inst_1.
   for s = 1, 10 do
      fb.fc_step(fc_inst_1)
   end
end
--]]

return LuaUnit:run()

