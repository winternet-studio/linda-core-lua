-- Weather functions
-- Updated for LINDA 4.0.0
-- v1.4 Jan 2015

function weather_OAT_inCelsius ()
	OATval = ipc.readUW("0E8C")/256
    if OATval > 100 then
    OATval = OATval-256
    end
	DspShow ("OAT", round(OATval) .. 'C')
end


function weather_OAT_inFahrenheit ()
	OATval = ipc.readUW("0E8C")/256
    if OATval > 100 then
        OATval = (((OATval-256)*9)/5)+32
    end
	DspShow ("OAT", round(OATval) .. 'F')
end

function MCP2weather_OAT_Wind_inCelsius ()
	OATval = ipc.readUW("0E8C")/256
    WINDval = ipc.readUW("0E90")
    WindDir = round(ipc.readUW("0E92")*360/65536)
    if OATval > 100 then
        OATval = OATval-256
    end
    DspMed1("OAT WIND")
	DspMed2 (round(OATval) .. 'C  ' .. WINDval ..'kt')

    ipc.sleep(1500)

    DspMed1("MAG WIND")
	DspMed2 (WindDir.. '  ' .. WINDval ..'kt')
end

function MCP2weather_OAT_Wind_inFahrenheit ()
	OATval = ipc.readUW("0E8C")/256
    WINDval = ipc.readUW("0E90")
    WindDir = round(ipc.readUW("0E92")*360/65536)

    if OATval > 100 then
        OATval = (((OATval-256)*9)/5)+32
    end
    DspMed1("OAT WIND")
	DspMed2 (round(OATval) .. 'F ' .. WINDval ..'kt')

    ipc.sleep(1500)

    DspMed1("MAG WIND")
	DspMed2 (WindDir.. '  ' .. WINDval ..'kt')
end

function MCP2_WIND_BARO_OAT ()
    TVar = 1000 ---- how long will one entry be shown

    Baro = ipc.readUW("0EC6")/16
    BaroUS = (ipc.readUW("0EC6")/16)/33.86530749

    OATval = round(ipc.readUW("0E8C")/256)
    OATvalUS = round(1.8*(ipc.readUW("0E8C")/256)+32)
    WINDval = ipc.readUW("0E90")
    WindDir = round(ipc.readUW("0E92")*360/65536)

    if OATval > 100 then
        OATval = OATval-256
        OATvalUS = round(1.8*((ipc.readUW("0E8C")/256)-256)+32)
    end

    DspMed1("WI " .. WindDir .. " @")
	DspMed2 ("ND " .. WINDval .. "kt")

    ipc.sleep(TVar)

    DspMed1("BA " .. round(Baro))
	DspMed2 ("RO " .. BaroUS)

    ipc.sleep(TVar)

    DspMed1("TE " .. OATval .. "'C")
	DspMed2 ("MP ".. OATvalUS .. "'F")

    ipc.sleep(TVar)
end

_log("[LIB]  Weather library loaded...")
