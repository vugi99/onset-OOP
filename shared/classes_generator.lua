OOP_loader = [[OOP_Auto_Classes = nil
OOP_Auto_Blacklist = nil
OOP_Auto_Destroy_Events = nil

if IsServer() then
    OOP_Auto_Classes = {
        "Player",
        "Door",
        "NPC",
        "Object",
        "Pickup",
        "Text3D",
        "Vehicle",
    }

    OOP_Auto_Blacklist = {
        Vehicle = {
            "SetPlayerInVehicle",
            "RemovePlayerFromVehicle"
        }
    }

    OOP_Auto_Destroy_Events = {
        Player = "Quit",
        Door = "Destroyed",
        NPC = "Destroyed",
        Object = "Destroyed",
        Pickup = "Destroyed",
        Text3D = "Destroyed",
        Vehicle = "Destroyed",
    }
else

    OOP_Auto_Classes = {
        "Player",
        "Door",
        "NPC",
        "Object",
        "Pickup",
        "Text3D",
        "Vehicle",
        "Sound",
        "Waypoint",
    }

    OOP_Auto_Destroy_Events = {
        Player = "StreamOut",
        Door = "StreamOut",
        NPC = "StreamOut",
        Object = "StreamOut",
        Pickup = "StreamOut",
        Text3D = "StreamOut",
        Vehicle = "StreamOut",
        Sound = "Finished",
    }
end

OOP_CACHE = {}
OOP_Gen_Classes = {}
for _, classname in ipairs(OOP_Auto_Classes) do
    OOP_CACHE[classname] = {}
    OOP_Gen_Classes[classname] = {}
    OOP_Gen_Classes[classname].__index = OOP_Gen_Classes[classname]
    OOP_Gen_Classes[classname].prototype = {}
    OOP_Gen_Classes[classname].prototype.__index = OOP_Gen_Classes[classname].prototype
    OOP_Gen_Classes[classname].prototype.constructor = OOP_Gen_Classes[classname]
end

function IsFuncGood(k)
    local wo_all, is_all = k:gsub("All", "")
    if is_all == 1 then
        return false
    end
    local wo_cr, is_cr = k:gsub("Create", "")
    if is_cr == 1 then
        return false
    end
    return true
end

function CheckBlacklist(classname, func_name)
    if OOP_Auto_Blacklist then
        if OOP_Auto_Blacklist[classname] then
            for i, v in ipairs(OOP_Auto_Blacklist[classname]) do
                if v == func_name then
                    return false
                end
            end
        end
    end
    return true
end

function OOP_GenerateClass(classname)
    for k, v in pairs(_ENV) do
        if type(v) == "function" then
            if IsFuncGood(k) then
                if CheckBlacklist(classname, k) then
                    local wo_classname, is_classname = k:gsub(classname, "")
                    if is_classname == 1 then
                        OOP_Gen_Classes[classname].prototype[wo_classname] = function(self, ...)
                            return _ENV[k](self.id, ...)
                        end
                    end
                end
            end
        end
    end
    if _ENV["Create" .. classname] then
        _ENV["_Create" .. classname] = _ENV["Create" .. classname]
        _ENV["Create" .. classname] = function(...)
            local id = _ENV["_Create" .. classname](...)
            if id then
                return _OOP_New(classname, id)
            end
        end
    end
    if OOP_Auto_Destroy_Events[classname] then
        AddEvent("On" .. classname .. OOP_Auto_Destroy_Events[classname], function(id)
            if OOP_CACHE[classname][id] then
                OOP_CACHE[classname][id] = nil
            end
        end)
    end
    return true
end

for _, classname in ipairs(OOP_Auto_Classes) do
    OOP_GenerateClass(classname)
end

function _OOP_New(classname, id)
    local thing
    if IsServer() then
        thing = setmetatable({}, OOP_Gen_Classes[classname].prototype)
    else
        thing = FTT_createtable_ex(OOP_Gen_Classes[classname].prototype)
    end
    thing.id = id
    OOP_CACHE[classname][id] = thing
    return OOP_CACHE[classname][id]
end

function OOP_IDToClass(id, classname)
    if (id and classname) then
        if OOP_CACHE[classname] then
            if OOP_CACHE[classname][id] then
                return OOP_CACHE[classname][id]
            elseif _ENV["IsValid" .. classname](id) then
                return _OOP_New(classname, id)
            end
        end
    end
    return false
end

]]

AddEvent("RequestCodeLoad", function(Import, p_name)
    for i, v in ipairs(Import) do
        if v == "OOP" then
            CallEvent("CodeLoaderLoad", "OOP", p_name, OOP_loader)
        end
    end
end)

AddEvent("OnPackageStart", function()
    for i, v in ipairs(GetAllPackages()) do
        local im = ImportPackage(v)
        if im then
            if im["CodeLoaderNeed"] then
                CallEvent("CodeLoaderLoad", "OOP", v, OOP_loader)
            end
        end
    end
end)