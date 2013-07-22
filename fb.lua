--[[

Function block processing
#########################

1. Built-in function block
2. Specify a function block
3. Specify a function chart
4. Use a function chart as a function block

5. Instantiate a function chart
6. Single-step a function chart




Specify a function block
========================

1. Name
2. Inputs
3. Outputs
4. State variables
5. Algorithm

--]]


local function fb_reset_default(state_vars)
   for _, v in state_vars do
      v.value = v.spec.default_value
      v.has_changed = false
   end
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

local function fb_spec_new(name, input_specs, output_specs, state_var_specs, algorithm, reset)
   local fb_spec = {}
   
   if type(name) == "table" then
      local t = name
      if #t ~= 0 then
         fb_spec.name = t[1]
         fb_spec.input_specs = t[2]
         fb_spec.output_specs = t[3]
         fb_spec.state_var_specs = t[4]
         fb_spec.algorithm = t[5]
      else
         fb_spec.name = t.name
         fb_spec.input_specs = t.input_specs
         fb_spec.output_specs = t.output_specs
         fb_spec.state_var_specs = t.state_var_specs
         fb_spec.algorithm = t.algorithm
      end
   else
      fb_spec.name = name
      fb_spec.input_specs = input_specs
      fb_spec.output_specs = output_specs
      fb_spec.state_var_specs = state_var_specs
      fb_spec.algorithm = algorithm
   end

   if type(reset) == "function" then
      fb_spec.reset = reset
   else
      fb_spec.reset = fb_reset_default
   end

   return fb_spec
end


-- Specification for a data item
-- -----------------------------

-- name: name of the data item
-- datatype: datatype of the data item
-- default_value: the default value of the data item used when the 
--    function block is restarted


-- There are three ways to create a new function block spec:
-- * call the function passing the inputs parameters as positional parameters
-- * call the function, passing a table as a parameter with positional parameters
-- * call the function, passing a table as a parameter with named parameters

local function fb_data_spec_new(name, datatype, default_value)
   local data_spec = {}
   
   if type(name) == "table" then
      local t = name
      if #t ~= 0 then
         data_spec.name = t[1]
         data_spec.datatype = t[2]
         data_spec.default_value = t[3]
      else
         data_spec.name = t.name
         data_spec.datatype = t.datatype
         data_spec.default_value = t.default_value
      end
   else
      data_spec.name = name
      data_spec.datatype = datatype
      data_spec.default_value = default_value
   end
   
   return data_spec
end


local function fb_data_item_new(data_spec)
   local data_item = {}
   data_item.spec = data_spec
   data_item.value = data_spec.default_value
   data_item.has_changed = false
end




function fc_spec_new(name, inputs, outputs, function_blocks, links)
   local fcs = {}
   
   return fcs
end


function fc_step(self)
   fbs_to_run = {}
   for _, fb in ipairs(self.fblocks) do
      fb.has_run = false
      fbs_to_run[#fbs_to_run+1] = fb
   end
   
   for _, fb in ipairs(self.inputs) do
   end
   
   for _, fp in ipairs(fbs_to_run) do
   end
   
   
end

function fc_reset(self)

end



local fb = 
{
   fb_spec_new = fb_spec_new,
   data_spec_new = fb_data_spec_new,
}

return fb

