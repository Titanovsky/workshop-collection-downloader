-- Данный скрипт делается ни только для воркшопа, но и для одного из уроков моего курса по GLua и разработки в Garry's Mod
-- >> https://vk.com/ambi_market
-- >> https://vk.com/ambi_market?w=product-204502364_7940440%2Fquery

print( '• [WCD] loaded SHARED')

-- ---------------------------------------------------------------------------------------------------------------------------------------------------------------------
WCD = WCD or {}
WCD.collectiones = WCD.collectiones or {}

-- ---------------------------------------------------------------------------------------------------------------------------------------------------------------------
function WCD.IsCollectionValid( sWID )
    if not sWID then return false end

    for _, collection in ipairs( WCD.collectiones ) do
        if ( collection.wid == sWID ) then return true end
    end
    
    return false
end

function string.IsValid( sString )
    -- from https://github.com/Titanovsky/ambi-eco/blob/master/ambi/lua/libs/general/sh_string.lua#L92
    if not sString or not isstring( sString ) then return false end

    for _, char in ipairs( string.Explode( '', sString ) ) do
        if ( char ~= ' ' ) then return true end
    end

    return false
end