-- Library of standard function blocks

local fb = require('fb')


-- Sources
-- -------
-- Constant
-- Step
-- Ramp
-- Square
-- Sine
-- File
-- Socket

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


-- Sinks
-- -----
-- Null sink
-- File
-- Logger

local sink = fb.fb_spec_new{
   name='Sink',
   inputs={
      fb.data_spec_new{ 'a', 'real', nil },
   },
   outputs=nil, 
   state_vars=nil,
   algorithm=nil,
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
   algorithm=function(data)
      if data.a.value ~= nil and data.b.value ~= nil then
         data.q.value = data.a.value + data.b.value
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



local fblib = 
{
   ramp = ramp,
   sink = sink,
   add = add,
}

return fblib

