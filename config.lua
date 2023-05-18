Config = Config or {}

Config.Debug = false -- <----- Use this only if you need to troubleshooting

Config.rayCastingDistance = 50.0
Config.ObjectZOffset = - 0.5

-- Config.RandomWeapon = math.random(2, 4) 
-- Config.RandomAmmo = math.random(5, 15)

Config.HasCrateAccsess = {
    ["citizen id here"] = true, -- <----- character citizen id If set to true the citizen id have accsess
    ["citizen id here"] = true,
    ["citizen id here"] = false,-- <----- If set to false the citizen id do not have accsess
    
}

Config.Difficulty = {
    [1] = {
        name = 'Easy',
        circles = 1,
        seconds= 15,
    },
    [2] = {
        name = 'Medium',
        circles = 2,
        seconds= 10,
    },
    [3] = {
        name = 'Hard',
        circles = 3,
        seconds= 5,
    }
    
    

}

Config.Presets = {
    [1] = {
        name = 'Random stuffs',
        items = {
            ['water_bottle'] = {min = 1, max = 5},
            ['joint'] = {min = 1, max = 5},
            ['beer'] = {min = 1, max = 5},
        }
    },
    [2] = {
        name = 'Random stuffs 2',
        items = {
            ['water_bottle'] = {min = 1, max = 5},
            ['joint'] = {min = 1, max = 5},
            ['beer'] = {min = 1, max = 5},
        }
    },
    [3] = {
        name = 'Random stuffs 3',
        items = {
            ['water_bottle'] = {min = 1, max = 5},
            ['joint'] = {min = 1, max = 5},
            ['beer'] = {min = 1, max = 5},
        }
    },

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
    --['weapon_unarmed'] = true,
  
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