--[[

Function block processing
#########################

1. Built-in function block (/)
2. Specify a function block (/)
3. Specify a function chart (/)
4. Use a function chart as a function block

5. Instantiate a function chart (/)
6. Single-step a function chart (/)
--]]

local data = require('data_item')

local function fb_reset_default(fb)
   for _, item in pairs(fb.data_items) do
      item:reset()
   end
   fb.has_changed = false
end


local function fb_new(fb_spec, name, fc_inst)
   local fb_inst = {}
   
   fb_inst.name = name
   fb_inst.fb_spec = fb_spec
   fb_inst.reset = fb_spec.reset
   
   local data_items = {}
   local data = {}
   for _, data_spec in pairs(fb_spec.data_specs) do
      local data_item_name = name .. '.' .. data_spec.name
      data_item = data_spec:new_item(data_item_name, nil, fb_inst)
      data_items[data_item_name] = data_item
      data[data_spec.name] = data_item
   end

   fb_inst.data_items = data_items
   fb_inst.data = data
   fb_inst.fc_inst = fc_inst
   
   return fb_inst
end


-- Specification for a function block
-- ----------------------------------

-- name: A unique name for the function block
-- inputs: A list of the input variables
-- outputs: A list of the output variables
-- algorithm: A function that re-calculates the outputs
-- reset: One of
--        * nil: state_vars are reset to their default values
--        * function: the function sets each state var
--        * table: state vars are reset to values from the table

-- There are three ways to create a new function block spec:
-- * call the function passing the inputs parameters as positional parameters
-- * call the function, passing a table as a parameter with positional parameters
-- * call the function, passing a table as a parameter with named parameters

local function fb_spec_new(name, inputs, outputs, state_vars, algorithm, reset, time)
   local fb_spec = {}
   
   if type(name) == 'table' then
      local t = name
      if #t ~= 0 then
         fb_spec.name = t[1]
         fb_spec.input_specs = t[2] or {}
         fb_spec.output_specs = t[3] or {}
         fb_spec.state_var_specs = t[4] or {}
         fb_spec.algorithm = t[5] or function() return true end
         fb_spec.reset = t[6]
         fb_spec.time = t[7]
      else
         fb_spec.name = t.name
         fb_spec.input_specs = t.inputs or {}
         fb_spec.output_specs = t.outputs or {}
         fb_spec.state_var_specs = t.state_vars or {}
         fb_spec.algorithm = t.algorithm or function() return true end
         fb_spec.reset = t.reset
         fb_spec.time = t.time
      end
   else
      fb_spec.name = name or '<noname>'
      fb_spec.input_specs = inputs or {}
      fb_spec.output_specs = outputs or {}
      fb_spec.state_var_specs = state_vars or {}
      fb_spec.algorithm = algorithm or function() return true end
      fb_spec.reset = reset
      fb_spec.time = time
   end

   fb_spec.new_inst = fb_new
   
   if type(fb_spec.reset) == 'function' or type(fb_spec.reset) == 'table' then
      fb_spec.reset = reset
   else
      -- TODO: Log that we are using default reset function
      fb_spec.reset = fb_reset_default
   end

   local valid = true
   local msgs = {}
   
   if fb_spec.name == nil then
      valid = false
      msgs[#msgs+1] = "No name provided."
   end
   
   local data_specs = {}
   for _, s in ipairs(fb_spec.input_specs) do
      s.fb_spec = fb_spec
      fb_spec.input_specs[s.name] = s
      if data_specs[s.name] ~= nil then
         valid = false
         msgs[#msgs+1] = 'Duplicate name: ' .. s.name
      else
         data_specs[s.name] = s
      end
   end
   
   for _, s in ipairs(fb_spec.output_specs) do
      s.fb_spec = fb_spec
      fb_spec.output_specs[s.name] = s
      if data_specs[s.name] ~= nil then
         valid = false
         msgs[#msgs+1] = 'Duplicate name: ' .. s.name
      else
         data_specs[s.name] = s
      end
   end
   
   for _, s in ipairs(fb_spec.state_var_specs) do
      s.fb_spec = fb_spec
      fb_spec.state_var_specs[s.name] = s
      if data_specs[s.name] ~= nil then
         valid = false
         msgs[#msgs+1] = 'Duplicate name: ' .. s.name
      else
         data_specs[s.name] = s
      end
   end
   
   fb_spec.data_specs = data_specs
   
   if valid then
      return fb_spec
   else
      return err, table.concat(msgs, '\n')
   end
end


local function fb_reset(fb)
   if type(fb.reset) == 'function' then
      fb.reset(fb)
   elseif type (fb.reset) == 'table' then
      
   else
      fb_reset_default(fb)
   end
end


local fb = 
{
   spec_new = fb_spec_new,
}

return fb

