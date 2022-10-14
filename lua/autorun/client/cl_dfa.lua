local surface_SetDrawColor = surface.SetDrawColor
local surface_DrawRect = surface.DrawRect
local ScrW = ScrW
local ScrH = ScrH

local blackoutAlpha = 0

hook.Add( "HUDPaint", "HUDPaint_DrawABox", function()
    local blackingOut = LocalPlayer():GetNWInt( "DFA_BlackingOut", false )
    if not blackingOut then
        if blackoutAlpha == 0 then return end
        blackoutAlpha = blackoutAlpha - 1
    end

    if blackingOut and blackoutAlpha < 255 then
        blackoutAlpha = blackoutAlpha + 1
    end

    surface_SetDrawColor( 0, 0, 0, blackoutAlpha )
    surface_DrawRect( 0, 0, ScrW(), ScrH() )
end )
