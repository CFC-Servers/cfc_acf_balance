local activeVehicles = {}
local IsValid = IsValid
local engine_TickCount = engine.TickCount
local next = next

local punishSpeed = CreateConVar( "dfa_punishspeed", 100, { FCVAR_ARCHIVE }, "The speed at which the driver should receive punishment.", 0 ):GetInt()
cvars.AddChangeCallback( "dfa_punishspeed", function( _, _, val )
    punishSpeed = tonumber( val )
end )

local damageMultiplier = CreateConVar( "dfa_damagemultiplier", 1, { FCVAR_ARCHIVE }, "The damage multiplier.", 0 ):GetInt()
cvars.AddChangeCallback( "dfa_damagemultiplier", function( _, _, val )
    damageMultiplier = tonumber( val )
end )

local checkInterval = CreateConVar( "dfa_interval", 5, { FCVAR_ARCHIVE }, "The amount of ticks between acceleration checks.", 0 ):GetInt()
cvars.AddChangeCallback( "dfa_interval", function( _, _, val )
    checkInterval = tonumber( val )
end )

local function damageVehicle( veh, ply, speed )
    ply:PrintMessage( HUD_PRINTCENTER, "You are accelerating too fast!" )
    local damage = math.floor( ( speed - punishSpeed ) / 10  * damageMultiplier )
    ply:ChatPrint( speed - punishSpeed .. " " .. damage )
    veh:TakeDamage( damage, game.GetWorld(), veh )
end

local function checkVehicle( veh, trackEnt )
    if not IsValid( veh ) or not IsValid( trackEnt ) then
        activeVehicles[veh] = nil
        return
    end

    local driver = veh:GetDriver()
    if not IsValid( driver ) then
        activeVehicles[veh] = nil
        return
    end

    local tickCount = engine_TickCount()
    local nextCheck = trackEnt.DFANextCheck

    if not nextCheck then
        trackEnt.DFANextCheck = tickCount + checkInterval
        return
    end

    if tickCount < nextCheck then
        return
    end
    trackEnt.DFANextCheck = tickCount + checkInterval

    local lastPos = trackEnt.DFALastPos
    trackEnt.DFALastPos = trackEnt:GetPos()
    if not lastPos then
        return
    end

    local speed = ( lastPos - trackEnt:GetPos() ):Length()
    if speed > punishSpeed then
        damageVehicle( veh, driver, speed )
    end
end

local function runCheck()
    if not next( activeVehicles ) then return end

    for veh, trackEnt in pairs( activeVehicles ) do
        checkVehicle( veh, trackEnt )
    end
end

hook.Add( "Think", "DFA_CheckSpeeds", runCheck )

hook.Add( "PlayerEnteredVehicle", "DFA_RegisterSeat", function( _, veh )
    local trackEnt = veh
    local parent = veh:GetParent()
    if IsValid( parent ) then
        trackEnt = parent
    end
    activeVehicles[veh] = trackEnt
end )

hook.Add( "PlayerLeaveVehicle", "DFA_UnregisterSeat", function( _, veh )
    local trackEnt = activeVehicles[veh]
    trackEnt.DFALastCheck = nil
    trackEnt.DFALastPos = nil
    veh.DFALastCheck = nil
    veh.DFALastPos = nil
    activeVehicles[veh] = nil
end )
