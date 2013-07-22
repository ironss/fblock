#! /usr/bin/lua

package.path = './?/?.lua;' .. package.path
require('luaunit')
local serpent = require('serpent')

local fb = require('fb')

Test_fb = {}

function Test_fb:test_create_fb_spec_table()
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
   assertEquals(#fbs1.input_specs, 2)
   assertEquals(#fbs1.output_specs, 1)
   assertEquals(#fbs1.state_var_specs, 1)
   assertEquals(type(fbs1.algorithm), "function")

end

return LuaUnit:run()

