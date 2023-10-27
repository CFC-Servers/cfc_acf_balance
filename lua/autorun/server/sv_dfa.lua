local activeVehicles = {}
local IsValid = IsValid
local math_abs = math.abs
local CurTime = CurTime

local punishAccel = CreateConVar( "dfa_punishaccel", 525, { FCVAR_ARCHIVE }, "The acceleration at which the driver should receive punishment.", nil ):GetInt()
local warningScale = 0.2
local warningStartOffset = punishAccel * warningScale
cvars.AddChangeCallback( "dfa_punishaccel", function( _, _, val )
    punishAccel = tonumber( val )
    warningStartOffset = punishAccel * warningScale
end )

local damageMultiplier = CreateConVar( "dfa_damagemultiplier", 1, { FCVAR_ARCHIVE }, "The damage multiplier.", nil ):GetFloat()
cvars.AddChangeCallback( "dfa_damagemultiplier", function( _, _, val )
    damageMultiplier = tonumber( val )
end )

local maxDamage = CreateConVar( "dfa_peakdamage", 10, { FCVAR_ARCHIVE }, "Peak damage for one 'check interval', can prevent instant death." ):GetFloat()
cvars.AddChangeCallback( "dfa_peakdamage", function( _, _, val )
    maxDamage = tonumber( val )
end )

local nextCheckTimeOffset = CreateConVar( "dfa_checkinterval", 0.1, { FCVAR_ARCHIVE }, "The amount of time between acceleration checks.", nil ):GetFloat()
cvars.AddChangeCallback( "dfa_checkinterval", function( _, _, val )
    nextCheckTimeOffset = tonumber( val )
end )


local function damageVehicle( veh, driver, accel )
    local accelDiff = accel - punishAccel
    local accelDiffDivided = accelDiff / 14 --magic number, 14 results in fair feeling damage
    local damage = math.Round( accelDiffDivided, 2 )
    damage = damage * damageMultiplier
    damage = math.Clamp( damage, 0, maxDamage )

    local world = game.GetWorld()

    if IsValid( driver ) then
        driver:TakeDamage( damage, world, world )
    else
        veh:TakeDamage( damage, world, world )
    end
end

local function getVelocityBulletproof( ent )
    local currPos = ent:GetPos()
    local currTime = CurTime()
    local oldPos = ent.DFAOldVelocityPos
    local oldTime = ent.DFALastVelCheckTime
    ent.DFAOldVelocityPos = currPos
    ent.DFALastVelCheckTime = currTime

    local deltaTime = math_abs( currTime - oldTime )

    local vel = currPos - oldPos
    vel = vel / deltaTime

    return vel
end

local function startTrackingVehicle( veh )
    activeVehicles[veh] = true
    veh.DFANextCheck = 0
    veh.DFALastVelocity = vector_origin
    veh.DFAOldVelocityPos = veh:GetPos()
    veh.DFALastVelCheckTime = CurTime()
end

local function stopTrackingVehicle( veh )
    activeVehicles[veh] = nil
    if not IsValid( veh ) then return end
    veh.DFANextCheck = nil
    veh.DFALastVelocity = nil
    veh.DFALastVelCheckTime = nil
    veh.DFAOldVelocityPos = nil
end

local blackoutScaleDivisor = 2 -- how quickly should blackout ramp up? 4 for 4x as fast, 2 for 2x as fast
local clampMagicNumber = 255 / blackoutScaleDivisor

local function checkVehicle( veh )
    if not IsValid( veh ) then
        stopTrackingVehicle( veh )
        return
    end

    local driver = veh:GetDriver()
    if not IsValid( driver ) then
        stopTrackingVehicle( veh )
        return
    end

    local curTime = CurTime()
    local nextCheck = veh.DFANextCheck

    if curTime < nextCheck then return end

    veh.DFANextCheck = curTime + nextCheckTimeOffset

    if CFCPvp and not driver:IsInPvp() then return end
    if veh.IsSimfphyscar then return end

    local currVelocity = getVelocityBulletproof( veh )

    local lastVelocity = veh.DFALastVelocity
    veh.DFALastVelocity = currVelocity

    if currVelocity == vector_origin and lastVelocity == vector_origin then
        veh.DFANextCheck = curTime + nextCheckTimeOffset * 5

    end

    local accel = ( lastVelocity - currVelocity ):Length()
    local oldAccel = veh.oldBlackoutAcceleration or accel

    veh.oldBlackoutAcceleration = accel

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
    for veh, _ in pairs( activeVehicles ) do
        checkVehicle( veh )
    end
end

hook.Add( "Think", "DFA_CheckAcceleration", runCheck )

hook.Add( "PlayerEnteredVehicle", "DFA_RegisterSeat", function( _, veh )
    startTrackingVehicle( veh )
end )

hook.Add( "PlayerLeaveVehicle", "DFA_UnregisterSeat", function( driver, veh )
    local isTracking = activeVehicles[veh]
    driver:SetNWInt( "DFA_BlackingOut", 0 )
    if not isTracking then return end
    stopTrackingVehicle( veh )
end )
