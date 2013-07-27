-- Data items
-- 
local function data_item_reset(data_item)
   data_item.value = data_item.reset_value
   data_item.has_changed = false
end

local function data_item_set(self, value)
   self.value = value
   self.has_changed = true
   for _, item in ipairs(self.drives) do
      item.value = self.value
      item.has_changed = true
      item.fblock.has_changed = true
   end
end


-- Given a data item specification, create a new data item

local function data_item_new(data_spec, name, reset_value, fblock)
   local data_item = {}
   
   data_item.name = name
   data_item.fblock = fblock
   data_item.reset_value = reset_value or data_spec.default_value
   data_item.data_spec = data_spec
   data_item.drives = {}
   data_item.reset = data_item_reset
   data_item.set = data_item_set
   
   return data_item
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

   data_spec.new_item = data_item_new
   data_spec.is_connected = false

   return data_spec
end


local data = 
{
   spec_new = data_spec_new
}

return data

