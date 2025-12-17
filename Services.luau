local Services = {};
local vim = getvirtualinputmanager and getvirtualinputmanager();

function Services:Get(...)
    local allServices = {}
    for _, service in next, {...} do
        table.insert(allServices, self[service]);
    end;
    return unpack(allServices);
end;

setmetatable(Services, {
    __index = function(self, p)
        if p == "VirtualInputManager" and vim then
            return vim
        elseif p == "CurrentCamera" then
            return workspace.CurrentCamera
        end
        local service = game:GetService(p);
        rawset(self, p, service);
        return service;
    end
})

return Services;
