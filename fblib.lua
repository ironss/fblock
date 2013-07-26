-- Library of standard function blocks

local fb = require('fb')


-- Generators
-- ----------
-- Constant
-- Ramp
-- Sine

local ramp = fb.fb_spec_new{
   name='Ramp',
   inputs=nil,
   outputs={
      fb.data_spec_new{ 'q', 'real', nil },
   },
   state_vars={
      fb.data_spec_new{ 'min', 'real', 0 },
      fb.data_spec_new{ 'max', 'real', 103 },
      fb.data_spec_new{ 'inc', 'real', 1 },
      fb.data_spec_new{ 's', 'real', 0 },
      
   },
   algorithm=function(data)
      data.q.value = data.s.value
      data.q.has_changed = true

      data.s.value = data.s.value + data.inc.value
      if data.s.value >= data.max.value then
         data.s.value = data.s.value - (data.max.value - data.min.value)
      end
      
      for _, item in ipairs(data.q.drives) do
         item.value = data.q.value
         item.has_changed = true
         item.fblock.has_changed = true
         item.fblock.fc_inst.has_changed = true
      end
   end,
   time = 0,
}


-- Arithmetic

local add = fb.fb_spec_new{
   name="add",
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
   name="subtract",
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

local multiply = fb.fb_spec_new{
   name="multiply",
   inputs={
      fb.data_spec_new{ "a", "real", 0 },
      fb.data_spec_new{ "b", "real", 0 },
   },
   outputs={
      fb.data_spec_new{ "q", "real", 0 },
   },
   state_vars=nil,
   algorithm=function(inputs, outputs, state_vars)
      outputs.q = inputs.a * inputs.b
   end,
}

local divide = fb.fb_spec_new{
   name="divide",
   inputs={
      fb.data_spec_new{ "a", "real", 0 },
      fb.data_spec_new{ "b", "real", 0 },
   },
   outputs={
      fb.data_spec_new{ "q", "real", 0 },
   },
   state_vars=nil,
   algorithm=function(inputs, outputs, state_vars)
      outputs.q = inputs.a / inputs.b
   end,
}


local fblib = 
{
   ramp = ramp,
   add = add,
   subtract = subtract,
   multiply = multiply,
   divide = divide,
}

return fblib

