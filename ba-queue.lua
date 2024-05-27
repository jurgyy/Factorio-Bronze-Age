local flib_queue = require("__flib__/queue")

--- Remove an element from the middle of the queue.
--- @generic T
--- @param self Queue<T>
--- @param index integer
--- @return T?
function flib_queue.remove_at(self, index)
    if index < self.first or index > self.last then
      return
    end
  
    local value = self[index]
  
    -- Shift elements to fill the gap
    for i = index, self.last - 1 do
      self[i] = self[i + 1]
    end
  
    self[self.last] = nil
    self.last = self.last - 1
  
    return value
end

return flib_queue