(function()
  local loadFileAsString=function(b)local c=getFileReader(b,false)if c==nil then return nil end;local d=c:readLine()local e=''while d~=nil do if string.len(e)~=0 then e=e+'\n'end;e=e+d;d=c:readLine()end;c:close()return e end;local f='mod_loader/mods/mod_loader/client/client.lua'local b=a(f)if b==nil then print('ModLoader: File not found: '..f)return end

  -- Human Code --
  Events.OnClientCommand.Add(function(c_mod_id, command, player, args)
    if c_mod_id ~= 'mod_loader' then return end
    
    -- Send the main client-side code. 
    if command == 'request_modloader_client_code' then 
      sendServerCommand(player, 'mod_loader', 'receive_modloader_client_code', {code = b})
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
      local folder = 'ModLoader/'..mod_id..'/'
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
end)()
