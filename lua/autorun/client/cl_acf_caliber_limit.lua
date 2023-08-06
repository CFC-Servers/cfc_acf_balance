net.Receive( "ACFBalance_CaliberLimitAlert", function()
    local messageTable = net.ReadTable()
    chat.AddText( unpack( messageTable ) )
end )
