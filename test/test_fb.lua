#! /usr/bin/lua

package.path = './?/?.lua;' .. package.path
require('luaunit')
local serpent = require('serpent')

local fb = require('fc')


Test_fb_spec = {}

function Test_fb_spec:test_create_positional1()
   local fbs1 = fb.fb_spec_new(
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
      end
   )

   assertEquals(type(fbs1), "table")
   assertEquals(fbs1.name, "RC LP filter")
   assertEquals(#fbs1.input_specs, 2)
   assertEquals(#fbs1.output_specs, 1)
   assertEquals(#fbs1.state_var_specs, 1)
   assertEquals(type(fbs1.algorithm), "function")

end

function Test_fb_spec:test_create_positional2()
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



function Test_fb_spec:test_create_named()
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

function Test_fc_spec:test_create_named()
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
         if state_vars.s >= 51 then
            state_vars.s = 0
         end
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
         if state_vars.s >= 79 then
            state_vars.s = 0
         end
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

 


function Test_fc_spec:test_cannot_create_link_with_invalid_source_port()
   local const1 = fb.fb_spec_new{
      name='Constant input 1',
      inputs=nil,
      outputs={
         fb.data_spec_new{ 'q', 'real', 0 },
      },
      state_vars=nil,
      algorithm=nil,
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

   local fcs1, err = fb.fc_spec_new{
      name='Invalid datatype',
      inputs={
         { 'C1', const1 },
      },
      outputs={
         { 'P1', printer },
      },
      function_blocks=nil,
      links={
         { { 'C1', 'qqq' },   { 'P1', 'x' } },
      },
   }

   assertEquals(type(fcs1), 'nil')
   assertIsNumber(string.find(err, 'no port named'))
end


 
function Test_fc_spec:test_cannot_create_link_with_invalid_destination_port()
   local const1 = fb.fb_spec_new{
      name='Constant input 1',
      inputs=nil,
      outputs={
         fb.data_spec_new{ 'q', 'real', 0 },
      },
      state_vars=nil,
      algorithm=nil,
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

   local fcs1, err = fb.fc_spec_new{
      name='Invalid datatype',
      inputs={
         { 'C1', const1 },
      },
      outputs={
         { 'P1', printer },
      },
      function_blocks=nil,
      links={
         { { 'C1', 'q' },   { 'P1', 'xxx' } },
      },
   }

   assertEquals(type(fcs1), 'nil')
   assertIsNumber(string.find(err, 'no port named'))
end


function Test_fc_spec:test_cannot_create_link_with_different_data_types()
   local const1 = fb.fb_spec_new{
      name='Constant input 1',
      inputs=nil,
      outputs={
         fb.data_spec_new{ 'q', 'real', 0 },
      },
      state_vars=nil,
      algorithm=nil,
   }
   
   local printer = fb.fb_spec_new{
      name='Printing output',
      inputs={
         fb.data_spec_new{ 'x', 'int', 0 },
      },
      outputs=nil,
      state_vars=nil,
      algorithm=function(inputs, outputs, state_vars)
         print(inputs.x)
      end
   }

   local fcs1, err = fb.fc_spec_new{
      name='Invalid datatype',
      inputs={
         { 'C1', const1 },
      },
      outputs={
         { 'P1', printer },
      },
      function_blocks=nil,
      links={
         { { 'C1', 'q' },   { 'P1', 'x' } },
      },
   }

   assertEquals(type(fcs1), 'nil')
   assertIsNumber(string.find(err, 'different'))
end

function Test_fc_spec:test_cannot_create_two_blocks_with_the_same_name()
   local const1 = fb.fb_spec_new{
      name='Constant input 1',
      inputs=nil,
      outputs={
         fb.data_spec_new{ 'q', 'real', 0 },
      },
      state_vars=nil,
      algorithm=nil,
   }
   
   local printer = fb.fb_spec_new{
      name='Printing output',
      inputs={
         fb.data_spec_new{ 'x', 'int', 0 },
      },
      outputs=nil,
      state_vars=nil,
      algorithm=function(inputs, outputs, state_vars)
         print(inputs.x)
      end
   }

   local fcs1, err = fb.fc_spec_new{
      name='Invalid datatype',
      inputs={
         { 'C1', const1 },
      },
      outputs={
         { 'C1', printer },
      },
      function_blocks=nil,
      links={
         { { 'C1', 'q' },   { 'P1', 'x' } },
      },
   }

   assertEquals(type(fcs1), 'nil')
   assertIsNumber(string.find(err, 'is not unique'))
end



Test_fc_instance = {}

function Test_fc_instance:test_create()
   local ramp1 = fb.fb_spec_new{
      name='Ramp 1',
      inputs=nil,
      outputs={
         fb.data_spec_new{ 'q', 'real', nil },
      },
      state_vars={
         fb.data_spec_new{ 's', 'real', 0 },
      },
      algorithm=function(data)
         data.q:set(data.s.value)

         data.s.value = data.s.value + 1
         if data.s.value >= 103 then
            data.s.value = data.s.value - 103
         end
      end,
      time = 0,
   }
   
   local ramp2 = fb.fb_spec_new{
      name='Ramp 2',
      inputs=nil,
      outputs={
         fb.data_spec_new{ 'q', 'real', nil },
      },
      state_vars={
         fb.data_spec_new{ 's', 'real', 0 },
      },
      algorithm=function(data)
         data.q:set(data.s.value)

         data.s.value = data.s.value + 1.5
         if data.s.value >= 79 then
            data.s.value = data.s.value - 79
         end
      end,
      time = 0,
   }

   local add = fb.fb_spec_new{
      name="Add",
      inputs={
         fb.data_spec_new{ "a", "real", nil },
         fb.data_spec_new{ "b", "real", nil },
      },
      outputs={
         fb.data_spec_new{ "q", "real", nil },
      },
      state_vars=nil,
      algorithm=function(data)
         if data.a.value ~= nil and data.b.value ~= nil then
            data.q:set(data.a.value + data.b.value)
            
            data.a.has_changed = false
            data.b.has_changed = false
         end
      end,
   }

   local subtract = fb.fb_spec_new{
      name="Sub",
      inputs={
         fb.data_spec_new{ "a", "real", nil },
         fb.data_spec_new{ "b", "real", nil },
      },
      outputs={
         fb.data_spec_new{ "q", "real", nil },
      },
      state_vars=nil,
      algorithm=function(data)
         if data.a.value ~= nil and data.b.value ~= nil then
            data.q.value = data.a.value - data.b.value
            data.q.has_changed = true
            
            data.a.has_changed = false
            data.b.has_changed = false
            for _, item in ipairs(data.q.drives) do
               item.value = data.q.value
               item.has_changed = true
               item.fblock.has_changed = true
            end
            
         end
      end,
   }

   local printer = fb.fb_spec_new{
      name='Printer',
      inputs={
         fb.data_spec_new{ 'x', 'real', 0 },
      },
      outputs=nil,
      state_vars=nil,
      algorithm=function(data)
--         print(data.x.value)
         data.x.has_changed = false
      end
   }

   local fc_spec_1 = fb.fc_spec_new{
      name='Chart_1',
      inputs={
         { 'R1', ramp1 },
         { 'R2', ramp2 },
      },
      outputs={
         { 'P1', printer },
         { 'P2', printer },
         { 'P3', printer },
         { 'P4', printer },
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
         { { 'R1', 'q' },   { 'P1', 'x' } },
         { { 'R2', 'q' },   { 'P2', 'x' } },
         { { 'ADD1', 'q' }, { 'P3', 'x' } },
         { { 'SUB1', 'q' }, { 'P4', 'x' } },
      },
   }

   local fc_inst_1 = fb.fc_instance_new('Test_1', fc_spec_1)
   
   assertEquals(fc_inst_1.name, 'Test_1')
   assertRefEquals(fc_inst_1.data_items['Test_1.ADD1.a'].is_driven_by, fc_inst_1.data_items['Test_1.R1.q'])
   assertRefEquals(fc_inst_1.data_items['Test_1.ADD1.b'].is_driven_by, fc_inst_1.data_items['Test_1.R2.q'])
   assertRefEquals(fc_inst_1.data_items['Test_1.SUB1.a'].is_driven_by, fc_inst_1.data_items['Test_1.R1.q'])
   assertRefEquals(fc_inst_1.data_items['Test_1.SUB1.b'].is_driven_by, fc_inst_1.data_items['Test_1.R2.q'])
   assertRefEquals(fc_inst_1.data_items['Test_1.P1.x'].is_driven_by, fc_inst_1.data_items['Test_1.R1.q'])
   assertRefEquals(fc_inst_1.data_items['Test_1.P2.x'].is_driven_by, fc_inst_1.data_items['Test_1.R2.q'])
   assertRefEquals(fc_inst_1.data_items['Test_1.P3.x'].is_driven_by, fc_inst_1.data_items['Test_1.ADD1.q'])
   assertRefEquals(fc_inst_1.data_items['Test_1.P4.x'].is_driven_by, fc_inst_1.data_items['Test_1.SUB1.q'])

   fc_inst_1:reset()

   fc_inst_1:step()
   assertEquals(fc_inst_1.data_items['Test_1.P3.x'].value, 0)
   assertEquals(fc_inst_1.data_items['Test_1.P4.x'].value, 0)

   fc_inst_1:step()
   assertEquals(fc_inst_1.data_items['Test_1.P3.x'].value, 2.5)
   assertEquals(fc_inst_1.data_items['Test_1.P4.x'].value, -0.5)

   fc_inst_1:step()
   assertEquals(fc_inst_1.data_items['Test_1.P3.x'].value, 5)
   assertEquals(fc_inst_1.data_items['Test_1.P4.x'].value, -1)

   fc_inst_1:step()
   assertEquals(fc_inst_1.data_items['Test_1.P3.x'].value, 7.5)
   assertEquals(fc_inst_1.data_items['Test_1.P4.x'].value, -1.5)

   fc_inst_1:step()
   assertEquals(fc_inst_1.data_items['Test_1.P3.x'].value, 10)
   assertEquals(fc_inst_1.data_items['Test_1.P4.x'].value, -2)
   
   fc_inst_1:dot(fc_inst_1.name .. '.dot')
end

return LuaUnit:run()

