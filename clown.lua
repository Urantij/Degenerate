module = {}

module.listInv = function(component) for i = 0, 5, 1 do print(i, component.inventory_controller.getInventoryName(i)) end end

return module
