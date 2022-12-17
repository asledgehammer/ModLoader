(function()
  local DEBUG = true
  Events.OnServerCommand.Add(function(c_mod_id, command, args)
    if c_mod_id ~= 'mod_loader' then return end
    if command == 'receive_mod_code' then
      if args.status == 'success' then
        -- Load the code for the mod.
        for path, code in pairs(args.file_data) do
          local status, err = pcall(function() 
            local loaded_code = loadstring(code)
            loaded_code()
          end)
          if DEBUG then
            if not status then
              print('ModLoader: Failed to load "Zomboid/Lua/ModLoader/'..args.mod_id..'/'..path..'"..')
              print(err)
            else
              print('ModLoader: Loaded file "Zomboid/Lua/ModLoader/'..args.mod_id..'/'..path..'"..')
            end
          end
        end
      end
    end
  end)
  _G['loadModFiles'] = function(mod_id, files)
    sendClientCommand('mod_loader', 'request_mod_code', { mod_id = mod_id, files = files})
  end
  _G['MOD_LOADER_READY'] = true
  triggerEvent('OnModLoaderReady', true)
end)()
