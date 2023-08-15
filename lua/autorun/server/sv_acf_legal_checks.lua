local parentClassesToBlock = {
    gmod_wire_hologram = true,
    starfall_hologram = true
}

local legalChecks = {
    acf_ammo = function( ent )
        local parent = ent:GetParent()

        if IsValid( parent ) and parentClassesToBlock[parent:GetClass()] then
            return false, "Hologram parent", "Your ammo crate is parented to a hologram and has been disabled."
        end

        if not ent.IsRefill then return end

        if IsValid( parent ) then
            return false, "Refill parented", "Your refill crate is parented and has been disabled."
        end

        local constraints = constraint.GetTable( ent )
        if #constraints > 0 then
            return false, "Refill constrainted", "Your refill crate has constraints and has been disabled."
        end

        local phys = ent:GetPhysicsObject()
        if IsValid( phys ) and phys:IsMoveable() then
            return false, "Refill unfrozen", "Your refill crate is unfrozen and has been disabled."
        end
    end
}

local function checkLegal( ent )
    local entClass = ent:GetClass()
    -- Specific class checks
    local check = legalChecks[entClass]
    if check then
        local legal, reason, message = check( ent )
        if legal == false then
            return false, reason, message
        end
    end
end

hook.Add( "ACF_IsLegal", "ACFBalance_CheckLegality", checkLegal )

hook.Add( "ACF_AmmoCanCookOff", "ACFBalance_CheckCookOff", function( ent )
    local hasWeapons = ent.Weapons and next( ent.Weapons )
    if hasWeapons then return end

    return false
end )

hook.Add( "ACF_AmmoExplode", "ACFBalance_CheckExplosion", function( ent )
    local hasWeapons = ent.Weapons and next( ent.Weapons )
    if hasWeapons then return end

    return false
end )
