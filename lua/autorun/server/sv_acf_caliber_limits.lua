util.AddNetworkString( "ACFBalance_CaliberLimitAlert" )

local GREY = Color( 200, 200, 200 )
local WHITE = Color( 255, 255, 255 )
local LIGHT_RED = Color( 175, 25, 25 )

local maxCaliber = 280
local missileCaliberScale = 0.5

local caliberLimit
do
    local _caliberLimit = CreateConVar( "acf_caliber_limit", "900", FCVAR_ARCHIVE + FCVAR_NOTIFY, "The maximum ACF caliber a player can have" )
    caliberLimit = _caliberLimit:GetInt()

    cvars.AddChangeCallback( "acf_caliber_limit", function( _, _, new )
        caliberLimit = tonumber( new )
    end, "update_local" )
end

local function getCaliber( what, data )
    local caliber = data.Caliber or 40
    if what == "acf_missile" then
        caliber = caliber * missileCaliberScale
    end

    return caliber
end

local getPlyGuns
local getPlyCaliber, setPlyCaliber
local addPlyCaliber, subtractPlyCaliber

do
    -- Accesor keys
    local guns = "ACFBalance_Guns"
    local caliber = "ACFBalance_TotalCaliber"

    getPlyGuns = function( ply )
        return ply[guns]
    end

    getPlyCaliber = function( ply )
        return ply[caliber]
    end

    setPlyCaliber = function( ply, newCaliber )
        ply[caliber] = newCaliber
    end

    addPlyCaliber = function( ply, amount )
        local current = getPlyCaliber( ply )
        local new = current + amount
        setPlyCaliber( ply, new )

        return new
    end

    subtractPlyCaliber = function( ply, amount )
        local current = getPlyCaliber( ply )
        local new = current - amount
        setPlyCaliber( ply, new )

        return new
    end

    hook.Add( "PlayerInitialSpawn", "ACFBalance_CaliberLimit", function( ply )
        ply[guns] = {}
        setPlyCaliber( ply, 0 )
    end )
end

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
    local function getTimerName( ply )
        return "ACFBalance_CaliberLimitAlert_" .. ply:SteamID64()
    end

    local function sendCaliberMessage( ply, prefix )
        prefix = prefix or {}

        if not ply then return end
        if not ply:IsValid() then return end

        -- Just in case one was already queued somehow
        timer.Remove( getTimerName( ply ) )

        local current = getPlyCaliber( ply )
        local message = "Your current ACF Caliber usage: "
        local currentCol = getRangeColor( current, caliberLimit )

        local messageTable = table.Add( prefix, {
            GREY, message,
            currentCol, tostring( current ),
            GREY, " / ",
            WHITE, tostring( caliberLimit ),
            GREY, " (",
            currentCol, "∆ ", tostring( caliberLimit - current ),
            GREY, ")\n"
        } )

        for gun, caliber in pairs( getPlyGuns( ply ) ) do
            table.Add( messageTable, {
                GREY, "  - ",
                WHITE, gun.Name,
                GREY, " (", gun:GetClass(), "): ",
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

        timer.Create( getTimerName( ply ), delay, 1, function()
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

        local plyGuns = getPlyGuns( plyTable )

        plyGuns[ent] = gunCaliber
        ent:CallOnRemove( "ACFBalance_CaliberLimit", function()
            if not ply then return end
            if not ply:IsValid() then return end

            plyGuns[ent] = nil
            subtractPlyCaliber( plyTable, gunCaliber )
        end )

        local newCaliber = addPlyCaliber( plyTable, gunCaliber )

        if newCaliber > caliberLimit then
            queueCaliberMessage( ply, {
                LIGHT_RED, "WARNING: ",
                WHITE, "You have exceeded the ACF Caliber limit! Your ACF weapons will not work!\n"
            } )
        end
    end )
end

hook.Add( "ACF_FireShell", "ACFBalance_CaliberLimit", function( gun )
    local owner = gun.Owner
    if not owner or not owner:IsValid() then return end

    local currentCaliber = getPlyCaliber( owner )

    if currentCaliber > caliberLimit then
        return false
    end
end )
