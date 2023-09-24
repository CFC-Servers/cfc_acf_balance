-- Prevent ACF ammo crates from damaging static, unmoving bases.
hook.Add( "ACF_PreDamageEntity", "ACFBalance_AmmoCrate_DontNukeBases", function( ent, _, dmgInfo )
    local attacker = dmgInfo:GetAttacker()
    if attacker:GetClass() ~= "acf_ammo" then return end

    local parent = ent:GetParent()
    if parent and parent:IsValid() then return end -- Allow parented ents to be damaged by crates.

    local physObj = ent:GetPhysicsObject()
    if physObj and physObj:IsMotionEnabled() then return end -- Allow unfrozen ents to be damaged by crates.

    return false
end )
