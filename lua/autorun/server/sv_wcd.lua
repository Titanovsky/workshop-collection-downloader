-- Данный скрипт делается ни только для воркшопа, но и для одного из уроков моего курса по GLua и разработки в Garry's Mod
-- >> https://vk.com/ambi_market
-- >> https://vk.com/ambi_market?w=product-204502364_7940440%2Fquery

print( '• [WCD] loaded SERVER')
sql.Query( 'CREATE TABLE IF NOT EXISTS wcd(WorkshopID PRIMARY KEY);' )

-- ---------------------------------------------------------------------------------------------------------------------------------------------------------------------
local http_fetch, string_gmatch, tostring, ipairs = http.Fetch, string.gmatch, tostring, ipairs

-- ---------------------------------------------------------------------------------------------------------------------------------------------------------------------
function WCD.GetCollection( sWID, fAction )
    if ( sWID == nil ) then return end

    sWID = tostring( sWID )

    http_fetch( 'https://steamcommunity.com/sharedfiles/filedetails/?id='..sWID, function( sBody )
        if not sBody then return end

        -- --------------------------------------------------------------------------
        local header
        for v in string_gmatch( sBody, 'workshopItemTitle\">.-<' ) do
            header = v

            break
        end

        for str in string_gmatch( header, '>.-<' ) do
            str = string.Replace( str, '>', '' )
            str = string.Replace( str, '<', '' )

            header = str

            break
        end
        -- --------------------------------------------------------------------------
        
        local tab = {}
        local final = {}

        for v in string_gmatch( sBody, 'SharedFileBindMouseHover%(.-%)' ) do
            tab[ #tab + 1 ] = v
        end

        for i, v in ipairs( tab ) do
            final[ i ] = {}

            local subtab = final[ i ]

            for str in string_gmatch( v, '".-"' ) do
                subtab[ #subtab + 1 ] = str
            end
        end

        local tab = {}

        tab.header = header or sWID
        tab.addons = {}

        for i, v in ipairs( final ) do
            tab.addons[ i ] = { title = string.IsValid( v[ 5 ] ) and string.Replace( v[ 5 ], '"', '' ) or 'No Title', id = tonumber( string.Replace( v[ 3 ], '"', '' ) ) }
        end

        if fAction then fAction( tab, sBody ) end
    end, function( sCode ) 
        print( '[WCD] Error: '..sCode ) 
    end )
end

function WCD.AddCollection( sWID )
    if WCD.IsCollectionValid( sWID ) then return end

    sWID = tostring( sWID )

    WCD.GetCollection( sWID, function( tCollection ) 
        local addons = tCollection.addons
        if not addons or ( #addons == 0 ) then return end

        print( '\n--------------------------------------------------------------------------------\n[WCD] Collection: '..tCollection.header..'\n' )
        for _, addon in ipairs( addons ) do
            local title, id = addon.title, addon.id
    
            resource.AddWorkshop( id )

            print( '[WCD] Added ['..title..'] ['..id..']' )
        end
        print( '--------------------------------------------------------------------------------\n' )

        WCD.collectiones[ #WCD.collectiones + 1 ] = {
            wid = sWID,
            header = tCollection.header
        }

        WCD.SyncAll()

        sql.QueryValue( 'INSERT INTO wcd(WorkshopID) VALUES('..sql.SQLStr( sWID )..');' )
    end )
end

function WCD.RemoveCollection( sWID )
    if not WCD.IsCollectionValid( sWID ) then return end

    for k, v in ipairs( WCD.collectiones ) do
        if ( v.wid == sWID ) then 
            print( '[WCD] Remove collection: '..v.header..' ['..sWID..']' )

            table.remove( WCD.collectiones, k )

            WCD.SyncAll()

            WCD.collectiones = WCD.collectiones or {} -- На всякий случай

            sql.QueryValue( 'DELETE FROM wcd WHERE WorkshopID = '..sql.SQLStr( sWID ) )

            return
        end
    end
end

function WCD.SyncPlayer( ePly )
    if not ePly then return end

    net.Start( 'wcd_sync' )
        net.WriteTable( WCD.collectiones )
    net.Send( ePly )
end

function WCD.SyncAll()
    net.Start( 'wcd_sync' )
        net.WriteTable( WCD.collectiones )
    net.Broadcast()
end

-- ---------------------------------------------------------------------------------------------------------------------------------------------------------------------
hook.Add( 'PlayerInitialSpawn', 'WCD:synchronization', WCD.SyncPlayer )

hook.Add( 'InitPostEntity', 'WCD:set_saved_collectiones', function() 
    timer.Simple( 2, function() -- На всякий случай
        local collectiones = sql.Query( 'SELECT * FROM wcd;' )
        if not collectiones then return end

        for _, collection in ipairs( collectiones ) do
            WCD.AddCollection( collection.WorkshopID )
        end
    end )
end )

-- ---------------------------------------------------------------------------------------------------------------------------------------------------------------------
util.AddNetworkString( 'wcd_sync' )

util.AddNetworkString( 'wcd_add' )
net.Receive( 'wcd_add', function( _, ePly ) 
    if not ePly:IsSuperAdmin() then return end
    if ( #WCD.collectiones > 15 ) then return end

    local wid = net.ReadString()
    if ( #wid > 14 ) then return end

    WCD.AddCollection( wid )
    
    timer.Simple( 2, function() 
        if not IsValid( ePly ) then return end

        local last_collection = WCD.collectiones[ #WCD.collectiones ]
        if last_collection and ( last_collection.wid == wid ) then
            ePly:ChatPrint( '[WCD] Added collection: '..last_collection.header )
        else
            ePly:ChatPrint( '[WCD] Error, the collection is not added ['..wid..']' )
        end
    end )
end )

util.AddNetworkString( 'wcd_remove' )
net.Receive( 'wcd_remove', function( _, ePly ) 
    if not ePly:IsSuperAdmin() then return end

    local key = net.ReadUInt( 4 ) -- Max 15
    if not WCD.collectiones[ key ] then error( '[WCD] Is not removed!' ) return end

    local header = WCD.collectiones[ key ].header

    sql.QueryValue( 'DELETE FROM wcd WHERE WorkshopID = '..sql.SQLStr( WCD.collectiones[ key ].wid ) )

    table.remove( WCD.collectiones, key )

    print( '[WCD] Remove collection: '..header )

    WCD.SyncAll()

    timer.Simple( 0.25, function() 
        if not IsValid( ePly ) then return end

        if not WCD.collectiones[ key ] or ( WCD.collectiones[ key ] and WCD.collectiones[ key ].header ~= header ) then
            ePly:ChatPrint( '[WCD] Remove collection: '..header )
        else
            ePly:ChatPrint( '[WCD] Error, the collection is not removed: '..header )
        end
    end )

    WCD.collectiones = WCD.collectiones or {} -- На всякий случай
end )