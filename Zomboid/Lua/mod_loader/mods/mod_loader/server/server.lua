(function()
  local loadFileAsString = function(c)
    local e = getFileReader(c, false)
    if e == nil then return nil end
     local d = e:readLine()
     local f = ''
     while d ~= nil do
        if string.len(f) ~= 0 then
            f = f .. '\n'
        end
        f = f .. d
        d = e:readLine()
    end
    e:close()
    return f 
  end
  local b = loadFileAsString('mod_loader/mods/mod_loader/client/client.lua')
  -- Human Code --
  Events.OnClientCommand.Add(function(c_mod_id, command, player, args)
    print('onClientCommand(mod_id='..tostring(c_mod_id)..', command='..tostring(command)..', player='..tostring(player)..', args='..tostring(args)..')')
    if c_mod_id ~= 'mod_loader' then return end

    -- Send the main client-side code. 
    if command == 'request_mod_loader_client_code' then 
      sendServerCommand(player, 'mod_loader', 'receive_mod_loader_client_code', {code = b})
    -- Handle request for a mod's code.
    elseif command == 'request_mod_code' then
      local mod_id = args.mod_id
          
      -- Make sure that the Mod ID is valid.
      if mod_id == nil or string.len(mod_id) == 0 then
        print('ModLoader: Invalid mod_id given. Ignoring request..');
        return
      end

      local files = args.files
      if files == nil or #files == 0 then
        print('ModLoader: The request for mod "'..mod_id..'" has no file(s). Ignoring request..');
        local payload = { mod_id = mod_id, file_data = {}, status = 'no_files' }
        sendServerCommand(player, 'mod_loader', 'receive_mod_code', payload)
        return
      end

      local status = 'success'
      local found_one_file = false
      local file_data = {}
      -- Grab code from: ../Zomboid/Lua/ModLoader/{mod_id}/{file}
      local folder = 'mod_loader/mods/'..mod_id..'/'
      for i = 1, #files, 1 do
        local path = files[i]
        file_data[path] = loadFileAsString(folder..path)
        found_one_file = true
      end

      if not found_one_file then status = 'no_files_found' end

      local payload = { mod_id = mod_id, file_data = file_data, status = status }
      sendServerCommand(player, 'mod_loader', 'receive_mod_code', payload)
    else
      print('ModLoader: Unknown command: '..tostring(command))
    end       
  end)

  _G['MOD_LOADER_READY'] = true
  triggerEvent('OnModLoaderReady', true)
  print('ModLoader: Server fully initialized.')
end)()
