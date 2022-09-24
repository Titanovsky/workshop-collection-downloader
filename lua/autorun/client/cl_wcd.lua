-- Данный скрипт делается ни только для воркшопа, но и для одного из уроков моего курса по GLua и разработки в Garry's Mod
-- >> https://vk.com/ambi_market
-- >> https://vk.com/ambi_market?w=product-204502364_7940440%2Fquery

print( '• [WCD] loaded CLIENT')

-- ---------------------------------------------------------------------------------------------------------------------------------------------------------------------
local wcd_panel = nil -- Мы делаем эту переменную под менюшку, она нужна, чтобы при синхронизаций удалять меню (если оно открыто) и заново открыть
local KEYS_REMOVE = {
    [ KEY_ENTER ] = true,
    [ KEY_SPACE ] = true,
    [ KEY_BACKSPACE ] = true,
    [ KEY_LSHIFT ] = true,
    [ KEY_ESCAPE ] = true
}
local CHAT_COMMANDS = {
    [ '/wcd' ] = true,
    [ '!wcd' ] = true,
    [ '.wcd' ] = true
}
local COLOR_WHITE, COLOR_BLACK = Color( 242, 242, 242), Color( 0, 0, 0 )
local COLOR_FRAME = Color( 51, 51, 51, 255 )
local COLOR_GREEN = Color( 42,197 ,71 )
local COLOR_TEXT = Color( 242, 210, 30)
local COLOR_RED = Color( 240, 61 ,61)
local COLOR_GRAY = Color( 107, 107, 107)
local W, H = ScrW(), ScrH()
local ICON = Material( 'icon16/page.png' )

surface.CreateFont( 'wcd_font1', {
    font = 'Tahoma',
    size = 46,
} )

surface.CreateFont( 'wcd_font2', {
    font = 'Tahoma',
    size = 32,
} )

-- ---------------------------------------------------------------------------------------------------------------------------------------------------------------------
local function SendError( sText )
    surface.PlaySound( 'buttons/button8.wav' )

    chat.AddText( COLOR_RED, '[WCD] '..sText )
end

local function OpenTextEntry()
    local frame = vgui.Create( 'DFrame' )
    frame:SetTitle( '' )
    frame:SetSize( 480, 100 )
    frame:Center()		
    frame:MakePopup()
    frame.Paint = function( self, w, h ) 
        draw.RoundedBox( 0, 0, 0, w, h, COLOR_FRAME ) 
    end

    local te = vgui.Create( 'DTextEntry', frame )
    te:SetSize( frame:GetWide() - 8, 28 )
    te:SetPos( 4, 28 )
    te:SetFont( 'wcd_font2' )
    te:SetTextColor( COLOR_BLACK )
    te:SetPlaceholderColor( COLOR_GRAY )
    te:SetPlaceholderText( 'Collection ID (ex. 2041976090)' )
    te:SetMultiline( false ) -- Нельзя расширять строку вниз
    te:SetNumeric( true ) -- Только числа, к сожалению, здесь работает плавающая запятая и минус :(

    local add = vgui.Create( 'DButton', frame )
    add:SetSize( 56, 34 )
    add:SetPos( frame:GetWide() / 2 - 56 / 2, frame:GetTall() - 34 - 4 )
    add:SetFont( 'wcd_font1' )
    add:SetTextColor( COLOR_GREEN )
    add:SetText( '+' )
    add.Paint = function( self, w, h )
        draw.RoundedBox( 8, 0, 0, w, h, COLOR_WHITE ) 
    end
    add.DoClick = function()
        if not LocalPlayer():IsSuperAdmin() then frame:Remove() return end 
        if ( #WCD.collectiones >= 15 ) then SendError( 'The limit reached (15 collectiones)' ) return end
        
        local wid = te:GetValue()
        if not string.IsValid( wid ) then SendError( 'Workshop ID is wrong, for example: 2041976090, 551691909' ) return end
        if WCD.IsCollectionValid( wid ) then SendError( 'This collection ('..wid..') is already exists!' ) return end

        net.Start( 'wcd_add' )
            net.WriteString( wid )
        net.SendToServer()

        surface.PlaySound( 'buttons/button15.wav' )

        frame:Remove()
    end
end

function WCD.OpenMenu()
    if ValidPanel( wcd_panel ) then wcd_panel:Remove() return end -- Даёт возможность нормального перебинда на команды (консольной) на любую клавишу, так как прошлая меню удалится

    surface.PlaySound( 'buttons/button15.wav' )

    local frame = vgui.Create( 'DFrame' )
    frame:SetAlpha( 0 )
    frame:SetTitle( 'Workshop Collection Download' )
    frame:SetSize( 480, 360 )
    frame:SetPos( W / 2 - frame:GetWide() / 2, H )			
    frame:MakePopup()
    frame:AlphaTo( 255, 0.25 )
    frame:MoveTo( W / 2 - frame:GetWide() / 2, H / 2 - frame:GetTall() / 2, 0.38 )
    frame.Paint = function( self, w, h ) 
        draw.RoundedBox( 0, 0, 0, w, h, COLOR_FRAME ) 
    end
    frame.OnKeyCodePressed = function( self, nKey ) 
        if KEYS_REMOVE[ nKey ] then self:Remove() return end
    end

    local list = vgui.Create( 'DScrollPanel', frame )
    list:SetSize( frame:GetWide() - 8, frame:GetTall() - 32 - 4 )
    list:SetPos( 4, 32 )
    list.Paint = function( self, w, h ) 
        draw.RoundedBox( 0, 0, 0, w, h, COLOR_WHITE ) 
    end

    for i, collection in ipairs( WCD.collectiones ) do
        local name = string.sub( collection.header, 1, 28 )

        local panel = vgui.Create( 'DPanel', list )
        panel:SetSize( list:GetWide(), 40 )
        panel:SetPos( 0, ( i - 1 ) * 40 )
        panel:SetTooltip( 'Header: '..collection.header..'\nWID: '..collection.wid )
        panel.Paint = function( self, w, h ) 
            draw.RoundedBox( 0, 0, h - 4, w, 4, COLOR_FRAME ) 

            draw.SimpleTextOutlined( name, 'wcd_font2', 28, h / 2 - 4, COLOR_TEXT, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER, 1, COLOR_BLACK )
        end

        local show = vgui.Create( 'DButton', panel )
        show:SetSize( 16, 16 )
        show:SetPos( 4, panel:GetTall() / 2 - 8 - 2 )
        show:SetFont( 'Default' )
        show:SetTextColor( COLOR_RED )
        show:SetText( '' )
        show:SetTooltip( 'Show page of collection in Workshop' )
        show.Paint = function( self, w, h )
            surface.SetMaterial( ICON )
            surface.SetDrawColor( 255, 255, 255, 255 )
            surface.DrawTexturedRect( 0, 0, 16, 16 )
        end
        show.DoClick = function()
            gui.OpenURL( 'https://steamcommunity.com/sharedfiles/filedetails/?id='..collection.wid )
        end

        if LocalPlayer():IsSuperAdmin() then
            local remove = vgui.Create( 'DButton', panel )
            remove:SetSize( 40, 40 )
            remove:SetPos( panel:GetWide() - 40 - 8, panel:GetTall() / 2 - 40 / 2 - 2 )
            remove:SetFont( 'wcd_font1' )
            remove:SetTextColor( COLOR_RED )
            remove:SetText( '✖' )
            remove:SetTooltip( 'Remove collection: '..collection.wid )
            remove.Paint = function() end
            remove.DoClick = function()
                if not LocalPlayer():IsSuperAdmin() then frame:Remove() return end
                if not WCD.IsCollectionValid( collection.wid ) then frame:Remove() return end -- then this is bag. 

                surface.PlaySound( 'buttons/button9.wav' )

                net.Start( 'wcd_remove' )
                    net.WriteUInt( i, 4 )
                net.SendToServer()

                chat.AddText( COLOR_TEXT, '[WCD] You need to restart server!' )

                frame:Remove()

                local frame = vgui.Create( 'DFrame' )
                frame:SetTitle( '' )
                frame:SetSize( 580, 50 )
                frame:SetPos( W / 2 - frame:GetWide() / 2, 12 )			
                frame:ShowCloseButton( false )
                frame:SetDraggable( false )
                frame.Paint = function( self, w, h ) 
                    draw.RoundedBox( 0, 0, 0, w, h, COLOR_FRAME ) 

                    draw.SimpleTextOutlined( 'You need to restart server!', 'wcd_font1', w / 2, h / 2, COLOR_TEXT, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, COLOR_BLACK )
                end

                timer.Simple( 4.12, function() frame:Remove() end)
            end
        end
    end

    if LocalPlayer():IsSuperAdmin() and ( #WCD.collectiones < 15 ) then
        local add = vgui.Create( 'DButton', list )
        add:SetSize( list:GetWide(), 40 )
        add:SetPos( 0, #WCD.collectiones * 40 )
        add:SetFont( 'wcd_font1' )
        add:SetTextColor( COLOR_GREEN )
        add:SetText( '+' )
        add.Paint = function() end
        add.DoClick = function()
            if not LocalPlayer():IsSuperAdmin() or ( #WCD.collectiones >= 15 ) then frame:Remove() return end

            surface.PlaySound( 'buttons/button15.wav' )

            frame:Remove()

            OpenTextEntry()
        end
    end

    wcd_panel = frame
end
concommand.Add( 'wcd', WCD.OpenMenu )

-- ---------------------------------------------------------------------------------------------------------------------------------------------------------------------
hook.Add( 'OnPlayerChat', 'WCD:chat_commands', function( ePly, sText ) 
    if IsValid( ePly ) and ( ePly == LocalPlayer() ) and CHAT_COMMANDS[ sText or '' ] then WCD.OpenMenu() end
end )

-- ---------------------------------------------------------------------------------------------------------------------------------------------------------------------
net.Receive( 'wcd_sync', function() 
    WCD.collectiones = nil
    WCD.collectiones = net.ReadTable()

    if ValidPanel( wcd_panel ) then -- Собственно вот вся реализация механизма, который уничтожит меню и откроет заново.
        wcd_panel:Remove()
        WCD.OpenMenu()
    end

    print( '[WCD] Synchronization' )
end )