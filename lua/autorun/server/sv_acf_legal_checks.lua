local legalChecks = {
    acf_ammo = function( ent )
        if not ent.IsRefill then return end

        if IsValid( ent:GetParent() ) then
            return false, "Refill parented", "Your refill crate is parented and has been disabled."
        end

        local constraints = constraint.GetTable( ent )
        if #constraints > 0 then
            return false, "Refill constrainted", "Your refill crate has constraints and has been disabled."
        end

        local phys = ent:GetPhysicsObject()
        print( phys )
        if IsValid( phys ) and phys:IsMoveable() then
            return false, "Refill moveable", "Your refill crate is unfrozen and has been disabled."
        end
    end
}

local function checkLegal( ent )
    local check = legalChecks[ent:GetClass()]
    if not check then return end

    local legal, reason, message = check( ent )
    if legal == false then
        return false, reason, message
    end
end

hook.Add( "ACF_IsLegal", "ACFBalance_CheckLegality", checkLegal )
