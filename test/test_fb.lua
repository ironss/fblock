#! /usr/bin/lua

package.path = './?/?.lua;' .. package.path
require('luaunit')
local serpent = require('serpent')

local fb = require('fb')



Test_data_spec = {}

function Test_data_spec:test_create_positional()
   local ds1 = fb.data_spec_new('x', 'real', 0)
   
   assertEquals(ds1.name, 'x')
   assertEquals(ds1.datatype, 'real')
   assertEquals(ds1.default_value, 0)
end



Test_fb_spec = {}

function Test_fb_spec:test_create_table_positional()
   local fbs1 = fb.fb_spec_new{
      "RC LP filter",
      { -- Inputs
         fb.data_spec_new("x", "real", 0),
         fb.data_spec_new("alpha", "real", 0),
      },
      { -- Outputs
         fb.data_spec_new("y", "real", 0),
      },
      { -- State variables
         fb.data_spec_new("S", "real", 0),
      },
      function(inputs, outputs, state_vars)
         state_vars.S = inputs.alpha * inputs.x + (1 - inputs.alpha) * state_vars.S
         outputs.y = state_vars.S
      end,
   }

   assertEquals(type(fbs1), "table")
   assertEquals(fbs1.name, "RC LP filter")
   assertEquals(#fbs1.input_specs, 2)
   assertEquals(#fbs1.output_specs, 1)
   assertEquals(#fbs1.state_var_specs, 1)
   assertEquals(type(fbs1.algorithm), "function")

end

function Test_fb_spec:test_create_table_named()
   local fbs1 = fb.fb_spec_new{
      name="RC LP filter",
      inputs = {
         fb.data_spec_new("x", "real", 0),
         fb.data_spec_new("alpha", "real", 0),
      },
      outputs = {
         fb.data_spec_new("y", "real", 0),
      },
      state_vars = {
         fb.data_spec_new("S", "real", 0),
      },
      algorithm = function(inputs, outputs, state_vars)
         state_vars.S = inputs.alpha * inputs.x + (1 - inputs.alpha) * state_vars.S
         outputs.y = state_vars.S
      end,
   }

   assertEquals(type(fbs1), 'table')
   assertEquals(fbs1.name, 'RC LP filter')
   assertEquals(#fbs1.input_specs, 2)
   assertEquals(#fbs1.output_specs, 1)
   assertEquals(#fbs1.state_var_specs, 1)
   assertEquals(type(fbs1.algorithm), 'function')

end




Test_fc_spec = {}

function Test_fc_spec:test_create_table_named()
   local ramp1 = fb.fb_spec_new{
      name='Ramp input 1',
      inputs=nil,
      outputs={
         fb.data_spec_new{ 'q', 'real', 0 },
      },
      state_vars={
         fb.data_spec_new{ 's', 'real', 0 },
      },
      algorithm=function(inputs, outputs, state_vars)
         state_vars.s = state_vars.s + 1
         outputs.q = state_vars.s
      end
   }
   
   local ramp2 = fb.fb_spec_new{
      name='Ramp input 2',
      inputs=nil,
      outputs={
         fb.data_spec_new{ 'q', 'real', 0 },
      },
      state_vars={
         fb.data_spec_new{ 's', 'real', 0 },
      },
      algorithm=function(inputs, outputs, state_vars)
         state_vars.s = state_vars.s + 2
         outputs.q = state_vars.s
      end
   }
   
   local add = fb.fb_spec_new{
      name="+",
      inputs={
         fb.data_spec_new{ "a", "real", 0 },
         fb.data_spec_new{ "b", "real", 0 },
      },
      outputs={
         fb.data_spec_new{ "q", "real", 0 },
      },
      state_vars=nil,
      algorithm=function(inputs, outputs, state_vars)
         outputs.q = inputs.a + inputs.b
      end,
   }

   local subtract = fb.fb_spec_new{
      name="-",
      inputs={
         fb.data_spec_new{ "a", "real", 0 },
         fb.data_spec_new{ "b", "real", 0 },
      },
      outputs={
         fb.data_spec_new{ "q", "real", 0 },
      },
      state_vars=nil,
      algorithm=function(inputs, outputs, state_vars)
         outputs.q = inputs.a - inputs.b
      end,
   }

   local printer = fb.fb_spec_new{
      name='Printing output',
      inputs={
         fb.data_spec_new{ 'x', 'real', 0 },
      },
      outputs=nil,
      state_vars=nil,
      algorithm=function(inputs, outputs, state_vars)
         print(inputs.x)
      end
   }
   
   local fcs1 = fb.fc_spec_new{
      name='FC Spec 1',
      inputs={
         { 'R1', ramp1 },
         { 'R2', ramp2 },
      },
      outputs={
         { 'P1', printer },
         { 'P2', printer },
      },
      function_blocks={
         { 'ADD1', add },
         { 'SUB1', subtract },
      },
      links={
         { { 'R1', 'q' },   { 'ADD1', 'a' } },
         { { 'R2', 'q' },   { 'ADD1', 'b'  }},
         { { 'R1', 'q' },   { 'SUB1', 'a' } },
         { { 'R2', 'q' },   { 'SUB1', 'b' } },
         { { 'ADD1', 'q' }, { 'P1', 'x' } },
         { { 'SUB1', 'q' }, { 'P2', 'x' } },
      },
   }
   
   assertEquals(type(fcs1), 'table')
   assertEquals(fcs1.name, 'FC Spec 1')
end

 
return LuaUnit:run()

