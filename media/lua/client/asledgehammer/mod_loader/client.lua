if isClient() then
  (function()
    LuaEventManager.AddEvent('OnModLoaderReady')
    local counter = 5
    local tick = nil
    tick = function()
      if counter >= 5 then
        sendClientCommand('mod_loader','_',{})
        counter = 0
      else
        counter = counter + 1
      end
    end
    local a = nil
    a = function(b, c, d)
      if b ~= 'mod_loader' or c ~= '__' then return end
      local result, err = pcall(function() 
        local loaded_code = loadstring(d.code)
        loaded_code()
      end)
      if not result then print(err) end
      Events.OnServerCommand.Remove(a)
      Events.OnTickEvenPaused.Remove(tick)
    end
    Events.OnServerCommand.Add(a)
    Events.OnTickEvenPaused.Add(tick)
  end)()
end
