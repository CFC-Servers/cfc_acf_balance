local activeVehicles = {}
local IsValid = IsValid
local engine_TickCount = engine.TickCount

local punishSpeed = CreateConVar( "dfa_punishspeed", 425, { FCVAR_ARCHIVE }, "The speed at which the driver should receive punishment.", nil ):GetInt()
local warningScale = 0.2
local warningStartOffset = punishSpeed * warningScale
cvars.AddChangeCallback( "dfa_punishspeed", function( _, _, val )
    punishSpeed = tonumber( val )
    warningStartOffset = punishSpeed * warningScale
end )

local damageMultiplier = CreateConVar( "dfa_damagemultiplier", 1, { FCVAR_ARCHIVE }, "The damage multiplier.", nil ):GetFloat()
cvars.AddChangeCallback( "dfa_damagemultiplier", function( _, _, val )
    damageMultiplier = tonumber( val )
end )

local checkInterval = CreateConVar( "dfa_interval", 5, { FCVAR_ARCHIVE }, "The amount of ticks between acceleration checks.", nil ):GetInt()
cvars.AddChangeCallback( "dfa_interval", function( _, _, val )
    checkInterval = tonumber( val )
end )

local function damageVehicle( veh, driver, speed )
    local speedDiff = speed - punishSpeed
    local damage = math.Clamp( speedDiff / 8, 0, 200 ) / 10
    damage = math.Round( damage, 2 )
    damage = damage * damageMultiplier
    if IsValid( driver ) then
        driver:TakeDamage( damage, game.GetWorld(), driver )
    else
        vec:TakeDamage( damage, game.GetWorld(), veh )
    end
end

local blackoutScaleDivisor = 2 -- how quickly should blackout ramp up? 4 for 4x as fast, 2 for 2x as fast
local clampMagicNumber = 255 / blackoutScaleDivisor

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

    if trackEnt.IsInPvp and not trackEnt:IsInPvp() then return end

    local lastVelocity = trackEnt.DFALastVelocity
    trackEnt.DFALastVelocity = trackEnt:GetVelocity()
    if not lastVelocity then
        return
    end

    local speed = ( lastVelocity - trackEnt:GetVelocity() ):Length()

    local blackoutStart = warningStartOffset - punishSpeed
    local blackoutScale = math.Clamp( speed + blackoutStart, 0, clampMagicNumber ) -- makes it get blacker faster
    local blackoutAmount = blackoutScale * ( blackoutScaleDivisor * 1.1 )

    if speed > blackoutStart then
        driver:SetNWInt( "DFA_BlackingOut", blackoutAmount )
    elseif driver:GetNWInt( "DFA_BlackingOut" ) ~= 0 then
        driver:SetNWInt( "DFA_BlackingOut", 0 )
    end

    if speed > punishSpeed then
        damageVehicle( veh, driver, speed )
    end
end

local function runCheck()
    for veh, trackEnt in pairs( activeVehicles ) do
        checkVehicle( veh, trackEnt )
    end
end

hook.Add( "Think", "DFA_CheckSpeeds", runCheck )

hook.Add( "PlayerEnteredVehicle", "DFA_RegisterSeat", function( _, veh )
    local trackEnt = veh
    for _ = 1, 20 do
        local parent = trackEnt:GetParent()
        if not IsValid( parent ) then
            break
        else
            trackEnt = parent
        end
    end
    activeVehicles[veh] = trackEnt
end )

hook.Add( "PlayerLeaveVehicle", "DFA_UnregisterSeat", function( driver, veh )
    local trackEnt = activeVehicles[veh]
    driver:SetNWInt( "DFA_BlackingOut", 0 )
    if not IsValid( trackEnt ) then return end
    trackEnt.DFALastCheck = nil
    trackEnt.DFALastVelocity = nil
    veh.DFALastCheck = nil
    veh.DFALastVelocity = nil
    activeVehicles[veh] = nil
end )
