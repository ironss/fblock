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
local fb = require('fb')

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



local function fc_reset(fc)
   for _, fb in pairs(fc.blocks) do
      fb:reset()
   end
   fc.has_changed = false
end

local function fc_step(self)
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

local function fc_dot_string(fc)
   local dot = {}
   
   local name = fc.name
   local fc_spec = fc.spec
   local data_items = fc.data_items
   
   dot[#dot+1] = 'digraph'
   dot[#dot+1] = '{'
   dot[#dot+1] = '   rankdir = LR'

   for _, fb in ipairs(fc.inputs) do
      dot[#dot+1] = '   subgraph cluster_i' .. _
      dot[#dot+1] = '   {'      
      dot[#dot+1] = '      label="' .. fb.name .. '"'
      for data_item_name, data_item in pairs(fb.data_items) do
         dot[#dot+1] = '      "' .. data_item_name .. '"'
                    .. ' [ label="' .. data_item.data_spec.name .. '" ]' 
       end
      dot[#dot+1] = '   }'
   end
   
   for _, fb in ipairs(fc.functions) do
      dot[#dot+1] = '   subgraph cluster_f' .. _
      dot[#dot+1] = '   {'
      dot[#dot+1] = '      label="' .. fb.name .. '"'
      for data_item_name, data_item in pairs(fb.data_items) do
         dot[#dot+1] = '      "' .. data_item_name .. '"'
                    .. ' [ label="' .. data_item.data_spec.name .. '" ]' 
       end
      dot[#dot+1] = '   }'
   end
   
   for _, fb in ipairs(fc.outputs) do
      dot[#dot+1] = '   subgraph cluster_o_' .. _
      dot[#dot+1] = '   {'
      dot[#dot+1] = '      label="' .. fb.name .. '"'
      for data_item_name, data_item in pairs(fb.data_items) do
         dot[#dot+1] = '      "' .. data_item_name .. '"'
                    .. ' [ label="' .. data_item.data_spec.name .. '" ]' 
       end
      dot[#dot+1] = '   }'
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
      
      dot[#dot+1] = '   "' .. source_full_name .. '" -> "' .. dest_full_name .. '"'
   end
   dot[#dot+1] = '}'
   
   return table.concat(dot, '\n')
end

local function fc_dot_file(fc, filename)
   local s = fc_dot_string(fc)
   local f = io.open(filename, "w")
   f:write(s)
   f:close()   
end

-- Create a function chart run-time instance
-- -----------------------------------------

local function fc_instance_new(name, fc_spec)
   local fc_inst = {}
   local blocks = {}
   local data_items = {}
   
   local inputs = {}
   for _, fb_def in ipairs(fc_spec.inputs) do
      local fb_name = fb_def[1]
      local fb_spec = fb_def[2]
      local block_name = name .. '.' .. fb_name
      local fb = fb_spec:new_inst(block_name, fc_inst)
      inputs[#inputs+1] = fb
      blocks[block_name] = fb
      for data_item_name, data_item in pairs(fb.data_items) do
         data_items[data_item_name] = data_item
      end
   end
   
   local outputs = {}
   for _, fb_def in ipairs(fc_spec.outputs) do
      local fb_name = fb_def[1]
      local fb_spec = fb_def[2]
      local block_name = name .. '.' .. fb_name
      local fb = fb_spec:new_inst(block_name, fc_inst)
      outputs[#outputs+1] = fb
      blocks[block_name] = fb
      for data_item_name, data_item in pairs(fb.data_items) do
         data_items[data_item_name] = data_item
      end
   end
   
   local functions = {}
   for _, fb_def in ipairs(fc_spec.function_blocks) do
      local fb_name = fb_def[1]
      local fb_spec = fb_def[2]
      local block_name = name .. '.' .. fb_name
      local fb = fb_spec:new_inst(block_name, fc_inst)
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
   fc_inst.spec = fc_spec
   fc_inst.inputs = inputs
   fc_inst.outputs = outputs
   fc_inst.functions = functions
   fc_inst.blocks = blocks
   fc_inst.data_items = data_items

   fc_inst.reset = fc_reset
   fc_inst.step = fc_step
   fc_inst.dot = fc_dot_file

   return fc_inst
end


local fc = 
{
   data_spec_new = data.spec_new,
   fb_spec_new = fb.spec_new,
   fc_spec_new = fc_spec_new,
   fc_instance_new = fc_instance_new,
}

return fc

