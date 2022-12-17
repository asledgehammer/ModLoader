if isServer() then
  (function()
    LuaEventManager.AddEvent('OnModLoaderReady')
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
    local a='mod_loader/mods/mod_loader/server/server.lua'
    local e=b(a)
    if e==nil then return end
    pcall(function()local g=loadstring(e);g()end)
  end)()
end
