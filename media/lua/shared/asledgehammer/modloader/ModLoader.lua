---[[
--- ModLoader - Client Script.
---
--- @author asledgehammer, JabDoesThings, 2024
--]]

--- @alias FileRequestCallback fun(result: 0 | 1, data: string | nil): string | void

--- @alias ModLoaderWhitelist table<string, string>

local Packet = require 'asledgehammer/network/Packet';

local IS_CLIENT = isClient();
local IS_SERVER = isServer();

-- This library is only used for multiplayer sessions.
if not IS_CLIENT and not IS_SERVER then return end

--- @type table<string, string>
local CLIENT_CACHED_FILES = {};

--- @type table<string, ModLoaderWhitelist>
local CACHED_WHITELISTS = {};

--- @type table<string, table<string, FileRequestCallback>>
local CALLBACKS = {};

local info = function(message)
    print('[ModLoader] :: ' .. tostring(message));
end

local ModLoader = {
    --- The ID used to communicate with the client and server.
    --- @type 'ModLoader'
    MODULE_ID = 'ModLoader',

    --- The result passed when the file is found and sent to the client.
    --- @type 0
    RESULT_SUCCESS = 0,

    --- The result passed when the file is not found.
    --- @type 1
    RESULT_FILE_NOT_FOUND = 1,

    --- A simple key to encrypt packets. A server-specific mod can change this to add *some* security against templated
    --- interception hack for the client.
    ---
    --- NOTE: This is not a one-size-fits-all for security. Implementations of ModLoader API can handle security when
    --- processing files.
    SIMPLE_KEY = 'ModLoader'
};

--- @param module string
--- @param id string
---
--- @return boolean
local function cacheExists(module, id)
    local name = string.lower(module .. '/' .. id);
    return CLIENT_CACHED_FILES[name] ~= nil;
end

--- @param module string
--- @param id string
---
--- @return string | nil
local function getCachedFile(module, id)
    local name = string.lower(module .. '/' .. id);
    return CLIENT_CACHED_FILES[name];
end

--- @param module string
--- @param id string
--- @param data string
---
--- @return void
local function cacheFile(module, id, data)
    local name = string.lower(module .. '/' .. id);
    CLIENT_CACHED_FILES[name] = data;
end

--- @param uri string
---
--- @return string | nil
local function readFile(uri)
    local reader = getFileReader(uri, false);

    -- A nil reader indicates a bad path or a missing file.
    if not reader then
        return nil;
    end

    ---------------------------------
    -- Read the contents of the file.
    local data = '';
    local line = reader:readLine();
    while line ~= nil do
        data = data .. line .. '\n';
        line = reader:readLine();
    end
    reader:close();
    ---------------------------------

    return data;
end

--- @param player IsoPlayer
--- @param module string
--- @param id string
---
--- @return void
local function onRequestServerFile(player, module, id)
    local idRequested = id;

    local uri = 'ModLoader/mods/' .. module .. '/';

    --- @type ModLoaderWhitelist | nil
    local whitelist;
    if CACHED_WHITELISTS[uri] then
        whitelist = CACHED_WHITELISTS[uri];
    else
        local data = readFile(uri .. 'whitelist.lua');
        if data then
            whitelist = loadstring(data)();
            CACHED_WHITELISTS[uri] = whitelist;
        end
    end

    if whitelist then
        id = whitelist[id];
        if not id then
            local packet = Packet(ModLoader.MODULE_ID, 'request_server_file', {
                module = module,
                id = idRequested,
                data = nil,
                result = ModLoader.RESULT_FILE_NOT_FOUND
            });

            packet:encrypt(ModLoader.SIMPLE_KEY, function() packet:sendToPlayer(player) end);

            info("Requested item not found in whitelist: \"" .. id .. "\"");

            return;
        end
    end

    -- If the file is requested cached and is in the cache, grab it & send it.
    if cacheExists(module, id) then
        local cachedFile = getCachedFile(module, id);
        local packet = Packet(ModLoader.MODULE_ID, 'request_server_file', {
            module = module,
            id = idRequested,
            data = cachedFile,
            result = ModLoader.RESULT_SUCCESS
        });
        packet:encrypt(ModLoader.SIMPLE_KEY, function() packet:sendToPlayer(player) end);
        return;
    end

    local data = readFile(uri .. id);

    -- A nil reader indicates a bad path or a missing file.
    if not data then
        local packet = Packet(ModLoader.MODULE_ID, 'request_server_file', {
            module = module,
            id = idRequested,
            data = nil,
            result = ModLoader.RESULT_FILE_NOT_FOUND
        });
        packet:encrypt(ModLoader.SIMPLE_KEY, function() packet:sendToPlayer(player) end);
        info('File not found: ' .. uri);
        return;
    end

    local packet = Packet(ModLoader.MODULE_ID, 'request_server_file', {
        module = module,
        id = idRequested,
        data = data,
        result = ModLoader.RESULT_SUCCESS
    });

    packet:encrypt(ModLoader.SIMPLE_KEY, function() packet:sendToPlayer(player) end);
end

--- @param module string
--- @param id string
--- @param result 0 | 1
--- @param data string
---
--- @return void
local function onReceiveServerFile(module, id, result, data)
    if CALLBACKS[module][id] then
        -- Pop callback function.
        local callback = CALLBACKS[module][id];
        CALLBACKS[module][id] = nil;

        if type(callback) == 'function' then
            pcall(function()
                callback(result, data);
            end);
        end
    end
end

--- @param module string
--- @param id string
--- @param callback FileRequestCallback
---
--- @return void
function ModLoader.requestServerFile(module, id, callback)
    if IS_CLIENT then
        -- Set the callback for the file requested.
        local callbacks = CALLBACKS[module];
        if not callbacks then
            callbacks = {};
            CALLBACKS[module] = callbacks;
        end
        callbacks[id] = callback;

        local packet = Packet(ModLoader.MODULE_ID, 'request_server_file', {
            module = module,
            id = id,
        });

        packet:encrypt(ModLoader.SIMPLE_KEY, function() packet:sendToServer() end);
    elseif IS_SERVER then
        local uri = 'ModLoader/mods/' .. module .. '/' .. id;
        local result;
        -- If the file is requested cached and is in the cache, grab it & send it.
        if cacheExists(module, id) then
            local data = getCachedFile(module, id);
            result = callback(ModLoader.RESULT_SUCCESS, data);
            if result then
                info('Caching file: ' .. id);
                cacheFile(module, id, result);
            end
            return;
        end

        local file = readFile(uri);

        -- A nil reader indicates a bad path or a missing file.
        if not file then
            pcall(function()
                result = callback(ModLoader.RESULT_FILE_NOT_FOUND, nil);
                if result then
                    info('Caching file: ' .. id);
                    cacheFile(module, id, result);
                end
            end);
            return;
        end

        result = callback(ModLoader.RESULT_SUCCESS, file);
        if result then
            info('Caching file: ' .. id);
            cacheFile(module, id, result);
        end
    end
end

Events.OnClientCommand.Add(function(module, command, player, data)
    -- ZedUtils.printLuaCommand(module, command, nil, data);

    if module ~= ModLoader.MODULE_ID then return end

    local packet = Packet(module, command, data);
    packet:decrypt(ModLoader.SIMPLE_KEY, function()
        if packet.command == 'request_server_file' then
            local id = packet.data.id;
            onRequestServerFile(player, packet.data.module, id);
        end
    end);
end);

Events.OnServerCommand.Add(function(module, command, data)
    -- ZedUtils.printLuaCommand(module, command, nil, data);

    if module ~= ModLoader.MODULE_ID then return end

    local packet = Packet(module, command, data);
    packet:decrypt(ModLoader.SIMPLE_KEY, function()
        -- print(packet:toJSON());
        if packet.command == 'request_server_file' then
            local id = packet.data.id;
            local result = packet.data.result;
            onReceiveServerFile(packet.data.module, id, result, packet.data.data);
        end
    end);
end);

return ModLoader;
