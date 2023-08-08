util.AddNetworkString( "ACFBalance_CaliberLimitAlert" )

local WHITE = Color( 255, 255, 255 )
local LIGHTRED = Color( 175, 25, 25 )
local LIGHTGREY = Color( 200, 200, 200 )

local maxCaliber = 280
local caliberLimit = 900
local missileCaliberScale = 0.5

local function getCaliber( what, data )
    local caliber = data.Caliber or 40
    if what == "acf_missile" then
        caliber = caliber * missileCaliberScale
    end

    return caliber
end

local guns = "ACFBalance_Guns"
local calibers = "ACFBalance_TotalCaliber"
hook.Add( "PlayerInitialSpawn", "ACFBalance_CaliberLimit", function( ply )
    ply[guns] = {}
    ply[calibers] = 0
end )

local getRangeColor
do
    local LerpVector = LerpVector
    local math_Remap = math.Remap

    -- These are vectors so we can LerpVector them
    local RED = Vector( 1, 0, 0 )
    local YELLOW = Vector( 1, 1, 0 )
    local GREEN = Vector( 0, 1, 0 )

    getRangeColor = function( current, limit )
        local range = current / limit

        local start, finish
        if range <= 0.5 then
            range = math_Remap( range, 0, 0.5, 0, 1 )
            start, finish = GREEN, YELLOW
        else
            start, finish = YELLOW, RED
        end

        return LerpVector( range, start, finish ):ToColor()
    end
end

local queueCaliberMessage
do
    local timerPrefix = "ACFBalance_CaliberLimitAlert_"

    local function sendCaliberMessage( ply, prefix )
        prefix = prefix or {}

        if not ply and ply:IsValid() then return end

        -- Just in case one was already queued somehow
        timer.Remove( timerPrefix .. ply:SteamID64() )

        local current = ply[calibers]
        local message = "Your current ACF Caliber usage: "
        local currentCol = getRangeColor( current, caliberLimit )

        local messageTable = table.Add( prefix, {
            LIGHTGREY, message,
            currentCol, tostring( current ),
            LIGHTGREY, " / ",
            WHITE, tostring( caliberLimit ),
            LIGHTGREY, " (",
            currentCol, "∆ ", tostring( caliberLimit - current ),
            LIGHTGREY, ")\n"
        } )

        for gun, caliber in pairs( ply[guns] ) do
            table.Add( messageTable, {
                LIGHTGREY, "  - ",
                WHITE, gun.Name,
                LIGHTGREY, " (", gun:GetClass(), "): ",
                getRangeColor( caliber, maxCaliber ), tostring( caliber ),
                "\n"
            } )
        end

        net.Start( "ACFBalance_CaliberLimitAlert" )
        net.WriteTable( messageTable )
        net.Send( ply )
    end

    queueCaliberMessage = function( ply, prefix, delay )
        delay = delay or 0.15

        timer.Create( timerPrefix .. ply:SteamID64(), delay, 1, function()
            sendCaliberMessage( ply, prefix )
        end )
    end

    hook.Add( "PlayerSay", "ACFBalance_CaliberLimit", function( ply, text )
        if text ~= "!calibers" then return end

        queueCaliberMessage( ply )
        return ""
    end )
end

do
    local hasCalibers = {
        acf_gun = true,
        acf_missile = true
    }

    hook.Add( "ACF_OnEntitySpawn", "ACFBalance_CaliberLimit", function( what, ent, entData )
        if not hasCalibers[what] then return end

        local ply = ent.Owner
        local plyTable = ply:GetTable()
        local gunCaliber = getCaliber( what, entData )

        plyTable[guns][ent] = gunCaliber
        ent:CallOnRemove( "ACFBalance_CaliberLimit", function()
            if not ply and ply:IsValid() then return end

            plyTable[guns][ent] = nil
            plyTable[calibers] = plyTable[calibers] - gunCaliber
        end )

        local newCaliber = plyTable[calibers] + gunCaliber
        plyTable[calibers] = newCaliber

        if newCaliber > caliberLimit then
            queueCaliberMessage( ply, {
                LIGHTRED, "WARNING: ",
                WHITE, "You have exceeded the ACF Caliber limit! Your ACF weapons will not work!\n"
            } )
        end
    end )
end

hook.Add( "ACF_FireShell", "ACFBalance_CaliberLimit", function( gun )
    local owner = gun.Owner
    if not owner or not owner:IsValid() then return end

    local plyTable = owner:GetTable()
    local totalCaliber = plyTable[calibers]

    if totalCaliber > caliberLimit then
        return false
    end
end )
