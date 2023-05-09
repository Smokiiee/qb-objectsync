Config = Config or {}

Config.Debug = true

Config.rayCastingDistance = 50.0
Config.ObjectZOffset = - 0.5

Config.RandomWeapon = math.random(2, 4) 
Config.RandomAmmo = math.random(5, 15)

Config.HasCrateAccsess = {
    ["PYI31423"] = true, -- <----- character citizen id If set to false the citizen id do not have accsess
    ["EPJ48839"] = true,
    
}

Config.Objects = {
    ['prop_tool_box_06'] = 'Tool box 6',
    ['prop_tool_box_05'] = 'Tool box 5', 
}

Config.IgnoreItems = {
    ['id_card'] = true,
    ['driver_license'] = true,
    ['lawyerpass'] = true,
    ['weaponlicense'] = true,
    ['visa'] = true,
    ['mastercard'] = true,
  
}

-- function to handle debug prints
debugPrint = function(text)
    if Config.Debug then
        tPrint(text, 0)
    end
end

tPrint = function(tbl, indent)
    indent = indent or 0
    if type(tbl) == 'table' then
        for k, v in pairs(tbl) do
            local tblType = type(v)
            local formatting = ("%s ^3%s:^0"):format(string.rep("  ", indent), k)

            if tblType == "table" then
                print(formatting)
                tPrint(v, indent + 1)
            elseif tblType == 'boolean' then
                print(("%s^1 %s ^0"):format(formatting, v))
            elseif tblType == "function" then
                print(("%s^9 %s ^0"):format(formatting, v))
            elseif tblType == 'number' then
                print(("%s^5 %s ^0"):format(formatting, v))
            elseif tblType == 'string' then
                print(("%s ^2'%s' ^0"):format(formatting, v))
            else
                print(("%s^2 %s ^0"):format(formatting, v))
            end
        end
    else
        print(("%s ^0%s"):format(string.rep("  ", indent), tbl))
    end
end