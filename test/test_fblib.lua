#! /usr/bin/lua

package.path = './?/?.lua;' .. package.path
require('luaunit')
local serpent = require('serpent')

local fblib = require('fblib')
local fb = require('fc')



Test_fblib_generator = {}

function Test_fblib_generator:test_ramp()
   local fc_spec_ramp = fb.fc_spec_new{
      name='Chart_Ramp',
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

   fc_ramp:reset()
   assertEquals(fc_ramp.data_items['test_ramp.R1.q'].value, nil)

   for i = 0, 10 do
      fc_ramp:step()
      assertEquals(fc_ramp.data_items['test_ramp.R1.q'].value, i)
   end
end


Test_fblib_real = {}

function Test_fblib_real:test_add()
   local fc_spec_add, err = fb.fc_spec_new{
      name='Chart_add',
      inputs={
         { 'R1', fblib.ramp },
      },
      outputs={
         { 'S1', fblib.sink },
      },
      function_blocks={
         { 'ADD1', fblib.add },
      },
      links={
         { { 'R1', 'q' },   { 'ADD1', 'a' } },
         { { 'R1', 'q' },   { 'ADD1', 'b'  }},
         { { 'ADD1', 'q' }, { 'S1', 'a' } },
      },
   }

   local fc_add = fb.fc_instance_new('test_add', fc_spec_add)
   
   fc_add:reset()
   assertEquals(fc_add.data_items['test_add.S1.a'].value, nil)

   for i = 0, 10 do
      fc_add:step()
      assertEquals(fc_add.data_items['test_add.S1.a'].value, 2*i)
   end
end


function Test_fblib_real:test_multiply()
   local fc_spec_add, err = fb.fc_spec_new{
      name='Chart_multiply',
      inputs={
         { 'R1', fblib.ramp },
      },
      outputs={
         { 'S1', fblib.sink },
      },
      function_blocks={
         { 'ADD1', fblib.add },
         { 'MULT1', fblib.multiply },
      },
      links={
         { { 'R1', 'q' },    { 'ADD1', 'a' } },
         { { 'R1', 'q' },    { 'ADD1', 'b' } },
         { { 'R1', 'q' },    { 'MULT1', 'a'  }},
         { { 'ADD1', 'q' },  { 'MULT1', 'b' } },
         { { 'MULT1', 'q' }, { 'S1', 'a' } },
      },
   }

   local fc_mult = fb.fc_instance_new('test_mult', fc_spec_add)
   
   fc_mult:reset()
   assertEquals(fc_mult.data_items['test_mult.S1.a'].value, nil)

   for i = 0, 10 do
      fc_mult:step()
      assertEquals(fc_mult.data_items['test_mult.S1.a'].value, 2*i*i)
   end
end


local code = LuaUnit:run()
os.exit(code)

