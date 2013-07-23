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

local function fb_spec_new(name, inputs, outputs, state_vars, algorithm, reset)
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
      else
         fb_spec.name = t.name
         fb_spec.input_specs = t.inputs or {}
         fb_spec.output_specs = t.outputs or {}
         fb_spec.state_var_specs = t.state_vars or {}
         fb_spec.algorithm = t.algorithm or function() return true end
         fb_spec.reset = t.reset
      end
   else
      fb_spec.name = name or '<noname>'
      fb_spec.input_specs = inputs or {}
      fb_spec.output_specs = outputs or {}
      fb_spec.state_var_specs = state_vars or {}
      fb_spec.algorithm = algorithm or function() return true end
      fb_spec.reset = reset
   end

   -- TODO: Must provide a name
   -- TODO: Must provide an algorithm
   -- TODO: Must provide either inputs or outputs or both
   -- State variables are optional

   if type(fb_spec.reset) ~= 'function' then
      -- TODO: Log that we are using default reset function
      fb_spec.reset = fb_reset_default
   end

   for _, i in ipairs(fb_spec.input_specs) do
      fb_spec.input_specs[i.name] = i
   end
   
   for _, o in ipairs(fb_spec.output_specs) do
      fb_spec.output_specs[o.name] = o
   end
   
   for _, v in ipairs(fb_spec.state_var_specs) do
      fb_spec.state_var_specs[v.name] = v
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

local function data_spec_new(name, datatype, default_value)
   local data_spec = {}
   
   if type(name) == 'table' then
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

   -- TODO: Must provide a name
   -- TODO: Must provide an algorithm

   return data_spec
end



-- Data items

local function data_item_reset(data_item)
   data_item.default_value = data_item.data_spec.default_value
   data_item.has_changed = false
end

-- Data item factory
-- Given a data item specification, create a new data item

local function data_item_new(data_spec)
   local data_item = {}
   data_item.spec = data_spec
   data_item_reset(self)
   
   return data_item
end



-- Specification for a new function chart
-- --------------------------------------

function fc_spec_new(name, inputs, outputs, function_blocks, links)
   local fc_spec = {}

   if type(name) == 'table' then
      local t = name
      if #t ~= 0 then
         fc_spec.name = t[1]
         fc_spec.inputs = t[2] or {}
         fc_spec.outputs = t[3] or {}
         fc_spec.function_blocks = t[4] or {}
         fc_spec.links = t[5] or {}
      else
         fc_spec.name = t.name
         fc_spec.inputs = t.inputs or {}
         fc_spec.outputs = t.outputs or {}
         fc_spec.function_blocks = t.function_blocks or {}
         fc_spec.links = t.links or {}
      end
   else
      fc_spec.name = name
      fc_spec.inputs = inputs or {}
      fc_spec.outputs = outputs or {}
      fc_spec.function_blocks = function_blocks or {}
      fc_spec.links = links or {}
   end
   
   -- TODO: Name is mandatory
   -- TODO: Inputs, outputs, function blocks and links are mandatory
   -- TODO: Verify that links are valid
   --       * Input and output names exist
   --       * Datatypes match

   -- Ensure that the names of inputs, outputs and function blocks are unique
   local blocks = {}
   for _, b in ipairs(fc_spec.inputs) do
      local name=b[1]
      if blocks[name] ~= nil then
         print(name .. ' is not unique.')
      else
         blocks[name] = b
      end
   end
   for _, b in ipairs(fc_spec.outputs) do
      local name=b[1]
      if blocks[name] ~= nil then
         print(name .. ' is not unique.')
      else
         blocks[name] = b
      end
   end
   for _, b in ipairs(fc_spec.function_blocks) do
      local name=b[1]
      if blocks[name] ~= nil then
         print(name .. ' is not unique.')
      else
         blocks[name] = b
      end
   end

   -- Verify that all of the links are valid, 
   -- TODO: Do something with the links...
   for _, l in ipairs(fc_spec.links) do
      local source=l[1]
      local dest=l[2]

      local source_name=source[1]
      local source_port=source[2]
      local b = blocks[source_name]
      if b == nil then
         print(source_name .. ' does not exist.')
      else
         local specs = b[2].output_specs
         local p = specs[source_port]
         if p == nil then
            print(source_name .. ' has no output port named ' .. source_port .. '.')
         end
      end

      local dest_name=dest[1]
      local dest_port=dest[2]
      local b = blocks[dest_name]
      if b == nil then
         print(dest_name .. ' does not exist.')
      else
         local specs = b[2].input_specs
         local p = specs[dest_port]
         if p == nil then
            print(source_name .. ' has no input port named ' .. source_port .. '.')
         end
      end
   end

   return fc_spec
end



function fc_step(self)
   fbs_to_run = {}
   for _, fb in ipairs(self.fblocks) do
      fb.has_run = false
      fbs_to_run[#fbs_to_run+1] = fb
   end

   for _, input in ipairs(self.inputs) do
   end
   
   self.something_has_changed = true
   while self.something_has_changed do
      for _, fb in ipairs(fbs_to_run) do
      end
   end

   for _, output in ipairs(self.outputs) do
   end
end

function fc_reset(self)

end



local fb = 
{
   data_spec_new = data_spec_new,
   fb_spec_new = fb_spec_new,
   fc_spec_new = fc_spec_new,
}

return fb

