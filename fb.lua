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


local function data_item_reset(data_item)
   data_item.value = data_item.data_spec.default_value
   data_item.has_changed = false
end

local function fb_reset_default(fb)
   for _, item in pairs(fb.data_items) do
      data_item_reset(item)
   end
   fb.has_changed = false
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


-- Data items
-- Given a data item specification, create a new data item

local function data_item_new(name, fblock, data_spec)
   local data_item = {}
   
   data_item.name = name
   data_item.fblock = fblock
   data_item.data_spec = data_spec
   data_item.drives = {}
   
   return data_item
end


-- Data items

local function fb_new(name, fb_spec, fc_inst)
   local fb_inst = {}
   
   fb_inst.name = name
   fb_inst.fb_spec = fb_spec
   
   local data_items = {}
   local data = {}
   for _, data_spec in pairs(fb_spec.data_specs) do
      local data_item_name = name .. '.' .. data_spec.name
      data_item = data_item_new(data_item_name, fb_inst, data_spec)
      data_items[data_item_name] = data_item
      data[data_spec.name] = data_item
   end

   fb_inst.data_items = data_items
   fb_inst.data = data
   fb_inst.fc_inst = fc_inst
   return fb_inst
end


local function fb_reset(fb)
   if type(fb.reset) == 'function' then
      fb.reset(fb)
   elseif type (fb.reset) == 'table' then
      
   else
      fb_reset_default(fb)
   end
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

local function fc_instance_new(name, fc_spec)
   local fc_inst = {}
   local blocks = {}
   local data_items = {}
   
   local inputs = {}
   for _, i in ipairs(fc_spec.inputs) do
      local block_name = name .. '.' .. i[1]
      local fb = fb_new(block_name, i[2], fc_inst)
      inputs[#inputs+1] = fb
      blocks[block_name] = fb
      for data_item_name, data_item in pairs(fb.data_items) do
         data_items[data_item_name] = data_item
      end
   end
   
   local outputs = {}
   for _, o in ipairs(fc_spec.outputs) do
      local block_name = name .. '.' .. o[1]
      local fb = fb_new(block_name, o[2], fc_inst)
      outputs[#outputs+1] = fb
      blocks[block_name] = fb
      for data_item_name, data_item in pairs(fb.data_items) do
         data_items[data_item_name] = data_item
      end
   end
   
   local functions = {}
   for _, f in ipairs(fc_spec.function_blocks) do
      local block_name = name .. '.' .. f[1]
      local fb = fb_new(block_name, f[2], fc_inst)
      functions[#functions+1] = fb
      blocks[block_name] = fb
      for data_item_name, data_item in pairs(fb.data_items) do
         data_items[data_item_name] = data_item
      end
   end

   for _, l in ipairs(fc_spec.links) do
      local source=l[1]
      local dest=l[2]

      local source_name=source[1]
      local source_port=source[2]

      local dest_name=dest[1]
      local dest_port=dest[2]

      local source_full_name = name .. '.' .. source_name .. '.' .. source_port
      local dest_full_name = name .. '.' .. dest_name .. '.' .. dest_port
      
      local source_item = data_items[source_full_name]
      local dest_item   = data_items[dest_full_name]
      
      source_item.drives[#source_item.drives+1] = dest_item
      dest_item.is_driven_by = source_item
   end

   fc_inst.name = name
   fc_inst.inputs = inputs
   fc_inst.outputs = outputs
   fc_inst.functions = functions
   fc_inst.blocks = blocks
   fc_inst.data_items = data_items

   fc_inst.reset = function(fc)
         for _, fb in pairs(fc.blocks) do
         fb_reset(fb)
      end
      fc.has_changed = false
   end

   fc_inst.step = function(self)
      fbs_to_run = {}
      for _, fb in ipairs(self.functions) do
         fbs_to_run[#fbs_to_run+1] = fb
      end

      for _, fb  in ipairs(self.inputs) do
         if fb.has_changed or fb.fb_spec.time == 0 then
            fb.fb_spec.algorithm(fb.data)
            fb.has_changed = false
         end
      end

      for i, fb in ipairs(fbs_to_run) do
         if fb.has_changed or fb.fb_spec.time == 0 then
            fb.fb_spec.algorithm(fb.data)
            fb.has_changed = false
         end
      end

      for _, fb in ipairs(self.outputs) do
         if fb.has_changed or fb.fb_spec.time == 0 then
            fb.fb_spec.algorithm(fb.data)
            fb.has_changed = false
         end
      end
   end

   return fc_inst
end



   


local fb = 
{
   data_spec_new = data_spec_new,
   fb_spec_new = fb_spec_new,
   fc_spec_new = fc_spec_new,
   fc_instance_new = fc_instance_new,
}

return fb

