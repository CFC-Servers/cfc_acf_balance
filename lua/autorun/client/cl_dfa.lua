local surface_SetDrawColor = surface.SetDrawColor
local surface_DrawRect = surface.DrawRect
local ScrW = ScrW
local ScrH = ScrH

local currentRefractAmount = 0
local maxTheoreticalInputAlpha = 255
local maxComfortableRefraction = 0.05
local refractionRescaleMul = 0.006 -- best as a bit "more" than the above var. eg 0.05 > 0.006

function doBlackoutOverlayEffect( alpha )
    local alphaNormalized = alpha / maxTheoreticalInputAlpha
    local refractAmount = math.Clamp( alphaNormalized * refractionRescaleMul, 0, maxComfortableRefraction )
    local overlayMaterial = ""

    if refractAmount ~= currentRefractAmount then
        currentRefractAmount = refractAmount

        if refractAmount > 0 then
            overlayMaterial = "models/props_c17/fisheyelens"
        end
    end
    DrawMaterialOverlay( overlayMaterial, refractAmount )

end

local blackoutAlpha = 0
local maxAlpha = 254 -- if blackoutAlpha somehow ends up above 255 then it will be stuck blacked out for like seconds, so max
local LocalPlayer = LocalPlayer

hook.Add( "HUDPaint", "HUDPaint_DrawABox", function()

    local localPly = LocalPlayer()
    if not localPly:InVehicle() then blackoutAlpha = 0 return end

    local blackingOutTarget = localPly:GetNWInt( "DFA_BlackingOut", 0 )
    blackingOutTarget = math.Clamp( blackingOutTarget, 0, maxAlpha )

    if blackingOutTarget == 0 and blackoutAlpha < 1 then blackoutAlpha = 0 return end

    if blackoutAlpha ~= blackingOutTarget then
        if blackoutAlpha < blackingOutTarget then
            local toAdd = math.random( 8, 12 ) -- randomize this so it feel less jerky
            blackoutAlpha = math.Clamp( blackoutAlpha + toAdd, 0, blackingOutTarget ) -- fast ramp up

        elseif blackoutAlpha > blackingOutTarget then
            blackoutAlpha = math.Clamp( blackoutAlpha - 0.2, blackingOutTarget, 255 ) -- goes down slow tho

        end
    end

    doBlackoutOverlayEffect( blackoutAlpha )

    surface_SetDrawColor( 0, 0, 0, blackoutAlpha )
    surface_DrawRect( 0, 0, ScrW(), ScrH() )

end )

-- from https://github.com/Facepunch/garrysmod/blob/e189f14c088298ca800136fcfcfaf5d8535b6648/garrysmod/lua/includes/modules/killicon.lua#L202
local color_Icon = Color( 255, 80, 0, 255 )
killicon.Add( "dfa_acceleration", "vgui/hud/acceleration_kill", color_Icon )

net.Receive( "DFA_DoAKillCredit", function()
    local died = net.ReadEntity()
    if not IsValid( died ) then return end

    if died == LocalPlayer() then
        -- you died, make sounds even though serverside it was killsilent!
        EmitSentence( "HEV_DEAD" .. math.random( 0, 1 ), died:GetPos(), died:EntIndex(), CHAN_AUTO, 0.5 )

    end

    GAMEMODE:AddDeathNotice( "Acceleration", -1, "dfa_acceleration", died:Nick(), died:Team() )
end )