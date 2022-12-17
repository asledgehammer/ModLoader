local DEBUG = true
_G['MOD_LOADER_READY'] = false
triggerEvent('OnModLoaderReady', false)
if isClient() then
  (function()
    local counter = 0
    local tick = nil
    tick = function()
      if counter >= 30 then
        if DEBUG then print('ModLoader: Attempting to establish connection..') end
        sendClientCommand('mod_loader','request_mod_loader_client_code',{})
        counter = 0
      else
        counter = counter + 1
      end
    end
    local a = nil
    a = function(b, c, d)
      if b ~= 'mod_loader' or c ~= 'receive_mod_loader_client_code' then return end
      if DEBUG then print('ModLoader: Established connection.') end
      local result, err = pcall(function() 
        local loaded_code = loadstring(d.code)
        loaded_code()
        if DEBUG then print('ModLoader: Loaded successfully.') end
      end)
      if not result then
        print('ModLoader: Failed to load.')
        print(err)
      end
      Events.OnServerCommand.Remove(a)
      Events.OnTickEvenPaused.Remove(tick)
    end
    Events.OnServerCommand.Add(a)
    Events.OnTickEvenPaused.Add(tick)
  end)()
  Events.OnModLoaderReady.Add(function()
    if DEBUG then print('ModLoader: Fully initialized.') end
  end)
end
