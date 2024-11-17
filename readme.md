# ModLoader
The ModLoader library allows for mods that require it to request code from the server-side of a Project Zomboid game.
There are a lot of benefits to this framework:
- Hot reload - If you are in a dynamic environment with lots of players that requires active development support,
reloading code could be an option. Code that is designed to `load()` and `unload()` can reload in this environment.
- Anti-Cheat - If you are writing sensitive code that needs to be protected, serving it from the machine of the server
can act as a deterant for code being digested and countered by various hacks made to cheat in multiplayer servers.
- In-House mod protection - If you are writing home-brewed mods for a Project Zomboid server, uploading all of it to 
the Steam Workshop can put your mod at risk for theft. Sending over portions of the code from the server can add 
security where the code could otherwise not work if not served on another server attempting to use your mod.

## Basic Example
### Basic_Example.lua
```lua
-- Import the library as a module.
local ModLoader = require 'asledgehammer/modloader/ModLoader';

-- (To keep all prints clean and contextual)
local info = function(msg)
    print('[' .. module .. '] :: ' .. msg);
end

--- @param result 0 | 1 
        - ModLoader.RESULT_FILE_NOT_FOUND
        - ModLoader.RESULT_SUCCESS
--- @param data string | nil The data retrieved from the server.
local callback = function(result, data)
    
    -- Handle non-installed / missing result.
    if result == ModLoader.RESULT_FILE_NOT_FOUND then
        info('File not installed on server. Ignoring..');
        return;
    end

    -- Handle data here. (Example is Lua code)
    loadstring(data)();

end;

--- @type boolean
--- 
--- If true, the server will cache the file so when
--- called again it'll be ready.
local cache = true; 

-- Request the file:
--   ~/Zomboid/Lua/ModLoader/mods/FoobarExample/Foobar_Client.lua
ModLoader:requestServerFile('FoobarExample', 'Foobar_Client.lua', cache, cache);
```

## File Caching & Encryption
Additionally, ModLoader provides a template for sending code over encrypted. If you load your files and cache them, code
can be encrypted in a way where only handled by the client-side receiving the code.

# Support

![](https://i.imgur.com/ZLnfTK4.png)

## Discord Server

<https://discord.gg/u3vWvcPX8f>

If you like what I do and helped your community a lot, feel free to buy me a coffee!
<https://ko-fi.com/jabdoesthings>

<https://www.paypal.com/paypalme/JabJabJab>
