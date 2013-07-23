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

   assertEquals(type(fbs1), "table")
   assertEquals(fbs1.name, "RC LP filter")
   assertEquals(#fbs1.input_specs, 2)
   assertEquals(#fbs1.output_specs, 1)
   assertEquals(#fbs1.state_var_specs, 1)
   assertEquals(type(fbs1.algorithm), "function")

end

return LuaUnit:run()

