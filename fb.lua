--[[

Function block processing
#########################

1. Built-in function block
2. Specify a function block
3. Specify a function chart
4. Use a function chart as a function block

5. Instantiate a function chart
6. Single-step a function chart

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

   if type(fb_spec.reset) ~= 'function' then
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



local function fb_new(name, fb_spec)
   local fb_inst = {}
   
   fb_inst.name = name

   return fb_inst
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

   data_spec.is_connected = false

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



local function fc_find_port(fc_spec, block_name, port_name)
   local b = fc_spec.blocks[block_name]
   if b == nil then
      return nil, block_name .. ' does not exist.'
   else
      local data_specs = b[2].data_specs
      local p = data_specs[port_name]
      if p == nil then
         return nil, block_name .. ' has no port named ' .. port_name .. '.'
      else
         return p
      end
   end
end

-- Specification for a new function chart
-- --------------------------------------

local function fc_spec_new(name, inputs, outputs, function_blocks, links)
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
   
   -- Validation
   local valid=true
   local msgs = {}

   if fc_spec.name == nil then
      valid = false
      msgs[#msgs+1] = "No name provided."
   end
   
   -- Ensure that the names of inputs, outputs and function blocks are unique
   local blocks = {}
   for _, b in ipairs(fc_spec.inputs) do
      local name=b[1]
      if blocks[name] ~= nil then
         valid = false
         msgs[#msgs+1] = name .. ' is not unique.'
      else
         blocks[name] = b
      end
   end
   for _, b in ipairs(fc_spec.outputs) do
      local name=b[1]
      if blocks[name] ~= nil then
         valid = false
         msgs[#msgs+1] = name .. ' is not unique.'
      else
         blocks[name] = b
      end
   end
   for _, b in ipairs(fc_spec.function_blocks) do
      local name=b[1]
      if blocks[name] ~= nil then
         valid = false
         msgs[#msgs+1] = name .. ' is not unique.'
      else
         blocks[name] = b
      end
   end
   fc_spec.blocks = blocks

   -- Verify that all of the links are valid, 
   for _, l in ipairs(fc_spec.links) do
      local source=l[1]
      local dest=l[2]

      local source_name=source[1]
      local source_port=source[2]
      local source_datatype = '?'

      local dest_name=dest[1]
      local dest_port=dest[2]
      local dest_datatype = '?'

      local link_description = fc_spec.name .. ': ' .. source_name .. '.' .. source_port .. '(' .. source_datatype ..  ') -> ' .. dest_name .. '.' .. dest_port .. '(' .. dest_datatype .. ')'

      local p, err = fc_find_port(fc_spec, source_name, source_port)
      if p == nil then
         valid = false
         msgs[#msgs+1] = link_description .. ': ' .. err
      else
         source_datatype = p.datatype
      end

      local link_description = fc_spec.name .. ': ' .. source_name .. '.' .. source_port .. '(' .. source_datatype ..  ') -> ' .. dest_name .. '.' .. dest_port .. '(' .. dest_datatype .. ')'
      
      local p, err = fc_find_port(fc_spec, dest_name, dest_port)
      local b = blocks[dest_name]
      if p == nil then
         valid = false
         msgs[#msgs+1] = link_description .. ': ' .. err
      else
         dest_datatype = p.datatype
      end

      local link_description = fc_spec.name .. ': ' .. source_name .. '.' .. source_port .. '(' .. source_datatype ..  ') -> ' .. dest_name .. '.' .. dest_port .. '(' .. dest_datatype .. ')'
      
      if source_datatype ~= dest_datatype then
         valid = false
         msgs[#msgs+1] = link_description .. ': ' .. 'Datatypes are different.'
      end
   end

   if valid then
      return fc_spec
   else
      return nil, table.concat(msgs, '\n')
   end
end


-- Create a function chart run-time instance
-- -----------------------------------------

function fc_instance_new(name, fc_spec)
   local fc_inst = {}
   
   fc_inst.name = name

   local inputs = {}
   for _, i in ipairs(fc_spec.inputs) do
      inputs[#inputs+1] = fb_new(i)
   end
   
   local outputs = {}
   for _, o in ipairs(fc_spec.outputs) do
      outputs[#outputs+1] = fb_new(o)
   end
   
   local blocks = {}
   for _, b in ipairs(fc_spec.function_blocks) do
      blocks[#blocks+1] = fb_new(b)
   end

   local links = {}
   for _, l in ipairs(fc_spec.links) do
--      links[#links+1] = link_new(l)
   end
   
   return fc_inst
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
   fc_instance_new = fc_instance_new,
}

return fb

