---[[
--- ModLoader - Client Script.
---
--- @author asledgehammer, JabDoesThings, 2024
--]]

local Packet = require 'asledgehammer/network/Packet';

local IS_CLIENT = isClient();
local IS_SERVER = isServer();

-- This library is only used for multiplayer sessions.
if not IS_CLIENT and not IS_SERVER then return end

--- @alias ServerFileRequestCallback fun(module: string, path: string, result: 0 | 1, data: string | nil): string | void

--- @type table<string, string>
local CACHED_FILES = {};

--- @type table<string, table<string, ServerFileRequestCallback>>
local CALLBACKS = {};

local ModLoader = {
    --- The ID used to communicate with the client and server.
    --- @type 'ModLoader'
    MODULE_ID = 'ModLoader',

    --- The result passed when the file is found and sent to the client.
    --- @type 0
    RESULT_SUCCESS = 0,

    --- The result passed when the file is not found.
    --- @type 1
    RESULT_FILE_NOT_FOUND = 1
};

--- @param module string
--- @param path string
---
--- @return boolean
local function cacheExists(module, path)
    return CACHED_FILES[string.lower(module .. '/' .. path)] ~= nil;
end

--- @param module string
--- @param path string
---
--- @return string | nil
local function getCachedFile(module, path)
    return CACHED_FILES[string.lower(module .. '/' .. path)];
end

--- @param module string
--- @param path string
--- @param data string
---
--- @return void
local function cacheFile(module, path, data)
    CACHED_FILES[string.lower(module .. '/' .. path)] = data;
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
--- @param path string
--- @param cache boolean
---
--- @return void
local function onRequestServerFile(player, module, path, cache)
    -- If the file is requested cached and is in the cache, grab it & send it.
    if cache and cacheExists(module, path) then
        local cachedFile = getCachedFile(module, path);

        local packet = Packet(ModLoader.MODULE_ID, 'request_server_file', {
            module = module,
            path = path,
            data = cachedFile,
            result = ModLoader.RESULT_SUCCESS
        });

        packet:encrypt('ModLoader', function()
            packet:sendToPlayer(player);
        end);

        return;
    end

    local uri = 'mod_loader/mods/' .. module .. '/' .. path;
    local data = readFile(uri);

    -- A nil reader indicates a bad path or a missing file.
    if not data then
        local packet = Packet(ModLoader.MODULE_ID, 'request_server_file', {
            module = module,
            path = path,
            data = nil,
            result = ModLoader.RESULT_FILE_NOT_FOUND
        });

        packet:encrypt('ModLoader', function()
            packet:sendToPlayer(player);
        end);

        print('[ModLoader] :: File not found: ' .. uri);

        return;
    end

    local packet = Packet(ModLoader.MODULE_ID, 'request_server_file', {
        module = module,
        path = path,
        data = data,
        result = ModLoader.RESULT_SUCCESS
    });

    packet:encrypt('ModLoader', function()
        packet:sendToPlayer(player);
    end);

    ---------------------------------------
    -- Cache the file to be recalled later.
    if cache then
        cacheFile(module, path, data);
    end
    ---------------------------------------
end

--- @param module string
--- @param path string
--- @param result 0 | 1
--- @param data string
---
--- @return void
local function onReceiveServerFile(module, path, result, data)
    if CALLBACKS[module][path] then
        -- Pop callback function.
        local callback = CALLBACKS[module][path];
        CALLBACKS[module][path] = nil;

        if type(callback) == 'function' then
            pcall(function()
                callback(module, path, result, data);
            end);
        end
    end
end

--- @param module string
--- @param path string
--- @param cache boolean
--- @param callback ServerFileRequestCallback
---
--- @return void
function ModLoader.requestServerFile(module, path, cache, callback)
    if IS_CLIENT then
        -- Set the callback for the file requested.
        local callbacks = CALLBACKS[module];
        if not callbacks then
            callbacks = {};
            CALLBACKS[module] = callbacks;
        end
        callbacks[path] = callback;

        local packet = Packet(ModLoader.MODULE_ID, 'request_server_file', {
            module = module,
            path = path,
            cache = cache
        });

        packet:encrypt('ModLoader', function()
            packet:sendToServer();
        end);

    elseif IS_SERVER then
        local uri = 'mod_loader/mods/' .. module .. '/' .. path;

        -- If the file is requested cached and is in the cache, grab it & send it.
        if cache and cacheExists(module, path) then
            local data = getCachedFile(module, path);
            callback(module, path, ModLoader.RESULT_SUCCESS, data);
            return;
        end

        local file = readFile(uri);

        -- A nil reader indicates a bad path or a missing file.
        if not file then
            pcall(function()
                callback(module, path, ModLoader.RESULT_FILE_NOT_FOUND, nil);
            end);
            return;
        end

        local result = callback(module, path, ModLoader.RESULT_SUCCESS, file);
        if result ~= nil then
            file = result;
        end

        if cache then
            print('[ModLoader] :: Caching file: ' .. path);
            cacheFile(module, path, file);
        end
    end
end

Events.OnClientCommand.Add(function(module, command, player, data)
    if module ~= ModLoader.MODULE_ID then return end
    local packet = Packet(module, command, data);
    packet:decrypt('ModLoader', function()
        if packet.command == 'request_server_file' then
            local path = packet.data.path;
            local cache = packet.data.cache;
            onRequestServerFile(player, packet.data.module, path, cache);
        end
    end);
end);

Events.OnServerCommand.Add(function(module, command, data)
    if module ~= ModLoader.MODULE_ID then return end
    local packet = Packet(module, command, data);
    packet:decrypt('ModLoader', function()
        if packet.command == 'request_server_file' then
            local path = packet.data.path;
            local result = packet.data.result;
            onReceiveServerFile(packet.data.module, path, result, packet.data.data);
        end
    end);
end);

return ModLoader;
