local surface_SetDrawColor = surface.SetDrawColor
local surface_DrawRect = surface.DrawRect
local ScrW = ScrW
local ScrH = ScrH

local currentRefractAmount = 0
local maxTheoreticalInputAlpha = 255
local maxComfortableRefraction = 0.05
local refractionRescaleMul = 0.006

function doBlackoutOverlayEffect( alpha )
    local alphaNormalized = alpha / maxTheoreticalInputAlpha
    local refractAmount = math.Clamp( alphaNormalized * refractionRescaleMul, 0, maxComfortableRefraction )

    if refractAmount == currentRefractAmount then return end
    currentRefractAmount = refractAmount

    local refractAmountConVar = GetConVar( "pp_mat_overlay_refractamount" )
    local materialConVar = GetConVar( "pp_mat_overlay" )
    local overlayMaterial = ""

    if refractAmount > 0 then
        overlayMaterial = "models/props_c17/fisheyelens"
    end

    materialConVar:SetString( overlayMaterial )
    refractAmountConVar:SetFloat( refractAmount )
end

local blackoutAlpha = 0
local maxAlpha = 235 -- if higher than 255 will stay dark for long time

hook.Add( "HUDPaint", "HUDPaint_DrawABox", function()
    local blackingOutTarget = LocalPlayer():GetNWInt( "DFA_BlackingOut", 0 )

    if blackoutAlpha ~= blackingOutTarget then

        if blackoutAlpha < 1 and blackingOutTarget == 0 then -- never get stuck on near zero values
            blackoutAlpha = 0

        elseif blackoutAlpha < blackingOutTarget then
            local toAdd = math.random( 18, 25 ) -- randomize this so it feel less jerky
            blackoutAlpha = math.Clamp( blackoutAlpha + toAdd, 0, blackingOutTarget ) -- fast ramp up

        elseif blackoutAlpha > blackingOutTarget then
            blackoutAlpha = math.Clamp( blackoutAlpha - 0.45, blackingOutTarget, maxAlpha ) -- goes down slow tho
        end
    end

    doBlackoutOverlayEffect( blackoutAlpha )

    local finalAlphaClamped = math.Clamp( blackoutAlpha, 0, 250 ) -- players can always see a bit

    surface_SetDrawColor( 0, 0, 0, finalAlphaClamped )
    surface_DrawRect( 0, 0, ScrW(), ScrH() )
end )