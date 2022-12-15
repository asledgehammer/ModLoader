(function()
  
  local DEBUG = true

  Events.OnServerCommand.Add(function(c_mod_id, command, args)
  
    if c_mod_id ~= 'mod_loader' then return end
  
    if command == 'receive_mod_code' then
  
      if args.status == 'success' then
  
        -- Load the code for the mod.
        for path, code in pairs(args.file_data) do
  
          local status, err = pcall(function() loadstring(code)() end)
  
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
  sendClientCommand('mod_loader', 'request_modloader_client_code', {})
end)()
  