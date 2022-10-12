local activeChairs = {}
local lastCheckedChair = 1

local IsValid = IsValid

local punishSpeed = CreateConVar( "dfa_punishspeed", 1000, { FCVAR_ARCHIVE }, "The speed at which the driver should receive punishment.", 0 ):GetInt()
cvars.AddChangeCallback( "dfa_punishspeed", function( _, _, val )
    punishSpeed = tonumber( val )
end )

local damageMultiplier = CreateConVar( "dfa_punishspeed", 1, { FCVAR_ARCHIVE }, "The damage multiplier.", 0 ):GetInt()
cvars.AddChangeCallback( "dfa_punishspeed", function( _, _, val )
    damageMultiplier = tonumber( val )
end )

local maxDamage = CreateConVar( "dfa_maxdamage", 10, { FCVAR_ARCHIVE }, "The max damage damage ticks can do.", 0 ):GetInt()
cvars.AddChangeCallback( "dfa_maxdamage", function( _, _, val )
    maxDamage = tonumber( val )
end )


local function punishSeat( ply, veh, speed )
    print( ply, veh, speed )
    ply:PrintMessage( HUD_PRINTCENTER, "You are going too fast!" )
    local damage = math.min( math.floor( ( ( speed / 1000 ) ^ 4 / 10000 ) * damageMultiplier ), maxDamage )
    ply:ChatPrint( speed .. " " .. damage )
    veh:TakeDamage( damage, game.GetWorld(), veh )
end

local function checkVehicle( veh, index )
    if not IsValid( veh ) then
        return table.remove( activeChairs, index )
    end

    local driver = veh:GetDriver()

    if not IsValid( driver ) then
        return table.remove( activeChairs, index )
    end
    local speed = veh:GetVelocity():Length()
    if speed > punishSpeed then
        punishSeat( driver, veh, speed )
    end
end

local function runCheck()
    if #activeChairs == 0 then return end

    local chair = activeChairs[lastCheckedChair]
    checkVehicle( chair, lastCheckedChair )

    lastCheckedChair = lastCheckedChair + 1
    if lastCheckedChair > #activeChairs then lastCheckedChair = 1 end
end

hook.Add( "Think", "DFA_CheckSpeeds", runCheck )

hook.Add( "PlayerEnteredVehicle", "DFA_RegisterSeat", function( _, veh )
    table.insert( activeChairs, veh )
end )

hook.Add( "PlayerLeaveVehicle", "DFA_UnregisterSeat", function( _, veh )
    table.RemoveByValue( activeChairs, veh )
end )
