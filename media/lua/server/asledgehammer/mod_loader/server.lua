if isServer() then
  (function()
    _G['MOD_LOADER_READY'] = false
    triggerEvent('OnModLoaderReady', false)
    local b = function(c)
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
    local a = 'mod_loader/mods/mod_loader/server/server.lua'
    local e = b(a)
    if e == nil then 
      print('ModLoader: File not found: '..tostring(a))
      return 
    end
    if not pcall(
      function() 
        local g = loadstring(e, 'server-2')
        g() 
      end) then
      print('ModLoader: Failed to load file: '..tostring(a))
    end
  end)()
end
