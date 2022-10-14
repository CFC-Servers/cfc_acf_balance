local activeVehicles = {}
local IsValid = IsValid
local engine_TickCount = engine.TickCount
local next = next

local punishSpeed = CreateConVar( "dfa_punishspeed", 400, { FCVAR_ARCHIVE }, "The speed at which the driver should receive punishment.", 0 ):GetInt()
cvars.AddChangeCallback( "dfa_punishspeed", function( _, _, val )
    punishSpeed = tonumber( val )
end )

local damageMultiplier = CreateConVar( "dfa_damagemultiplier", 0.4, { FCVAR_ARCHIVE }, "The damage multiplier.", 0 ):GetInt()
cvars.AddChangeCallback( "dfa_damagemultiplier", function( _, _, val )
    damageMultiplier = tonumber( val )
end )

local checkInterval = CreateConVar( "dfa_interval", 5, { FCVAR_ARCHIVE }, "The amount of ticks between acceleration checks.", 0 ):GetInt()
cvars.AddChangeCallback( "dfa_interval", function( _, _, val )
    checkInterval = tonumber( val )
end )

local function damageVehicle( veh, driver, speed )
    driver:PrintMessage( HUD_PRINTCENTER, "You're blacking out!" )
    local damage = math.floor( ( speed - punishSpeed ) / 10  * damageMultiplier )
    driver:SetNWBool( "DFA_BlackingOut", true )
    print( veh, driver, speed, damage )
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

    local lastVelocity = trackEnt.DFALastVelocity
    trackEnt.DFALastVelocity = trackEnt:GetVelocity()
    if not lastVelocity then
        return
    end

    local speed = ( lastVelocity - trackEnt:GetVelocity() ):Length()
    if speed > punishSpeed then
        damageVehicle( veh, driver, speed )
    else
        if driver:GetNWBool( "DFA_BlackingOut" ) then
            driver:SetNWBool( "DFA_BlackingOut", false )
        end
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

hook.Add( "PlayerLeaveVehicle", "DFA_UnregisterSeat", function( driver, veh )
    local trackEnt = activeVehicles[veh]
    driver:SetNWBool( "DFA_BlackingOut", false )
    trackEnt.DFALastCheck = nil
    trackEnt.DFALastVelocity = nil
    veh.DFALastCheck = nil
    veh.DFALastVelocity = nil
    activeVehicles[veh] = nil
end )
