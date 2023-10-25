-- Prevent ACF ammo crates from damaging other people's builds.
hook.Add( "ACF_PreDamageEntity", "ACFBalance_AmmoCrate_DontNukeBases", function( ent, _, dmgInfo )
    local attacker = dmgInfo:GetAttacker()

    if not attacker:IsValid() then
        attacker = dmgInfo:GetInflictor()
        if not attacker:IsValid() then return end
    end

    if attacker:GetClass() ~= "acf_ammo" then return end
    if ent:IsPlayer() then return end

    local victimOwner = ent:CPPIGetOwner()
    local attackerOwner = attacker:CPPIGetOwner()
    if victimOwner == attackerOwner then return end

    return false
end )

-- Prevent ACF ammo crates from damaging static, unmoving bases.
hook.Add( "ACF_PreDamageEntity", "ACFBalance_AmmoCrate_DontNukeBases", function( ent, _, dmgInfo )
    local attacker = dmgInfo:GetAttacker()

    if not attacker:IsValid() then
        attacker = dmgInfo:GetInflictor()
        if not attacker:IsValid() then return end
    end

    if attacker:GetClass() ~= "acf_ammo" then return end

    local parent = ent:GetParent()
    if parent:IsValid() then return end -- Allow parented ents to be damaged by crates.

    local physObj = ent:GetPhysicsObject()
    if physObj:IsValid() and physObj:IsMotionEnabled() then return end -- Allow unfrozen ents to be damaged by crates.

    return false
end )
