local activeVehicles = {}
local IsValid = IsValid
local engine_TickCount = engine.TickCount
local math_abs = math.abs

local warningScale = 0.2 -- when the blacking out starts happening

local defaultAccel = 625
local punishAccelVar = CreateConVar( "dfa_punishaccelbegin", -1, { FCVAR_ARCHIVE }, "The acceleration at which the driver should receive punishment. -1 for default, " .. defaultAccel, nil )
local punishAccel
local function doPunishAccel()
    local rawValue = punishAccelVar:GetInt()
    if rawValue == -1 then
        punishAccel = defaultAccel
    else
        punishAccel = rawValue
    end
    warningStartOffset = punishAccel * warningScale
end
doPunishAccel()
cvars.AddChangeCallback( "dfa_punishaccelbegin", function()
    doPunishAccel()

end )

local damageMultiplier = CreateConVar( "dfa_damagemultiplier", 1, { FCVAR_ARCHIVE }, "The damage multiplier.", nil ):GetFloat()
cvars.AddChangeCallback( "dfa_damagemultiplier", function( _, _, val )
    damageMultiplier = tonumber( val )
end )

local checkInterval = CreateConVar( "dfa_interval", 5, { FCVAR_ARCHIVE }, "The amount of ticks between acceleration checks.", nil ):GetInt()
cvars.AddChangeCallback( "dfa_interval", function( _, _, val )
    checkInterval = tonumber( val )
end )


local function damageVehicle( veh, driver, accel )
    local accelDiff = accel - punishAccel
    local accelDiffDivided = accelDiff / 14 --magic number, 14 results in fair feeling damage
    local damage = math.Clamp( accelDiffDivided, 0, 200 )
    damage = math.Round( damage, 2 )
    damage = damage * damageMultiplier

    local world = game.GetWorld()

    if IsValid( driver ) then
        driver:TakeDamage( damage, world, world )
    else
        veh:TakeDamage( damage, world, world )
    end
end

local function getVelocityDelta( ent, entTbl )
    local currPos = ent:WorldSpaceCenter()
    local currTime = CurTime()
    local oldPos = entTbl.DFAOldVelocityPos
    local oldTime = entTbl.DFALastVelCheckTime
    entTbl.DFAOldVelocityPos = currPos
    entTbl.DFALastVelCheckTime = currTime

    if not ( oldPos and oldTime ) then return end

    local deltaTime = math_abs( currTime - oldTime )

    local vel = currPos - oldPos
    vel = vel / deltaTime -- anchors vel to time, wont blow up when there's lag or anything

    return vel
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
    local trackEntTable = trackEnt:GetTable()
    local nextCheck = trackEntTable.DFANextCheck

    if not nextCheck then
        trackEntTable.DFANextCheck = tickCount + checkInterval
        return
    end

    if tickCount < nextCheck then
        return
    end
    trackEntTable.DFANextCheck = tickCount + checkInterval

    if CFCPvp and not driver:IsInPvp() then return end
    if trackEntTable.IsSimfphyscar then return end

    local currVelocity = getVelocityDelta( trackEnt, trackEntTable )
    if not currVelocity then return end -- setting up

    local lastVelocity = trackEntTable.DFALastVelocity
    trackEntTable.DFALastVelocity = currVelocity
    if not lastVelocity then
        return
    end

    local accel = ( lastVelocity - currVelocity ):Length()
    local oldAccel = trackEntTable.oldBlackoutAcceleration or accel

    trackEntTable.oldBlackoutAcceleration = accel

    local averageAccel = ( accel + oldAccel ) / 2 -- use average so random, insane 1 tick acceleration isnt as crazy

    local blackoutStart = warningStartOffset - punishAccel
    local blackoutScale = math.Clamp( averageAccel + blackoutStart, 0, clampMagicNumber ) -- makes it get blacker faster
    local blackoutAmount = blackoutScale * ( blackoutScaleDivisor * 1.1 )

    if averageAccel > blackoutStart then
        driver:SetNWInt( "DFA_BlackingOut", blackoutAmount )
    elseif driver:GetNWInt( "DFA_BlackingOut" ) ~= 0 then
        driver:SetNWInt( "DFA_BlackingOut", 0 )
    end

    if averageAccel > punishAccel then
        damageVehicle( veh, driver, averageAccel )
    end
end

local function runCheck()
    for veh, trackEnt in pairs( activeVehicles ) do
        checkVehicle( veh, trackEnt )
    end
end

hook.Add( "Think", "DFA_CheckAcceleration", runCheck )

hook.Add( "PlayerEnteredVehicle", "DFA_RegisterSeat", function( _, veh )
    activeVehicles[veh] = veh
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
