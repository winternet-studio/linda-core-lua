-- DEFAULT MSFS Extra
-- May 2021

-- ## System - do not use ###############

function testread ()

    VSvar = round((ipc.readUD("07D4")/65536)*3.28084)
    DspShow ("test", VSvar)

end

function testwrite ()

    ipc.writeUB("0B49", 1)
    DspShow ("test")

end

function control ()
         --ipc.control(66058,1)
         DspShow ("test", dspm)
        DspVVS (0)
end

function DSPtestingDisp ()
    DspAPPR ()
end

function testbat ()

    vs = round(ipc.readSW(0x07F2))
    vs = round(vs * 3.2808399)

	ipc.writeSW(0x07F2, vs)

end

----------------------------

-- ## Display Functions  #####################

function InitVars ()

    if ipc.get("DSPmode") == 1 then
        HDGset = round(ipc.readUW("07CC")/182)
        DspHDG(HDGset)
    end

    MSAltPlane = ipc.readUW("3324")
    MSFS_Baro ()
end

function MSFS_Flaps ()

    flapVar = ipc.readUD("0BDC")
    flapVar = round((flapVar / 16383)*100)

    if flapVar == 0 then
        flapTxt = "up"
    elseif flapVar == 100 then
        flapTxt = "dn"
    else
    flapTxt = flapVar
    end
end

function MSFS_Baro ()

    MSAltPlane = ipc.readUW("3324")

    Baro = "QNH " .. round(ipc.readUW("0EC6")/16)
    BaroUS = "in " .. (ipc.readUW("0EC6")/16)/33.86530749

    if MSAltPlane > 18000 then
        Baro = "STD 1013"
        BaroUS = "STD 29.92"
    end
end

function MSFS_TrimCalc ()
    MSTrim = ipc.readUW(0x0BC0)
    if MSTrim > 20000 then
        MSTrimTxt1 = "v"
        --MSTrimTxt2 = 10-((round(((MSTrim-49153)/16384)*100))/10)
        MSTrimTxt2 = 10-((round(((MSTrim-49153)/16384)*1000))/100)

    else
        MSTrimTxt1 = "^"
        --MSTrimTxt2 = (round((MSTrim/16384)*100))/10
        MSTrimTxt2 = (round((MSTrim/16384)*1000))/100

    end
end

function MSFS_Trim ()
    MSFS_TrimCalc ()
    MSTrimTxt = "Trm" .. MSTrimTxt1 .. MSTrimTxt2
end

function MSFS_TrimShow ()
    MSFS_TrimCalc ()

    DspMed1 ("Trm" .. MSTrimTxt1 .. MSTrimTxt2)
end

function MSFS_ParkingBrake ()
    MSParkB = ipc.readUW(0x0BC8)
    if MSParkB ~= 0 then MSParkBvar = 1
    else MSParkBvar = 0
    end

end

function MSFS_showWP ()
    MSWPvar = 0
    MSWPquest = ipc.readSTR(0x60A4,6)

    if string.byte(MSWPquest, 1) == 0 then
    MSWPvar = ipc.readSTR(0x60A4,0)
    MSWPtxt = "no WP"

    elseif string.byte(MSWPquest, 2) == 0 then
    MSWPvar = ipc.readSTR(0x60A4,1)
    MSWPtxt = "to " .. MSWPvar

    elseif string.byte(MSWPquest, 3) == 0 then
    MSWPvar = ipc.readSTR(0x60A4,2)
    MSWPtxt = "to " .. MSWPvar

    elseif string.byte(MSWPquest, 4) == 0 then
    MSWPvar = ipc.readSTR(0x60A4,3)
    MSWPtxt = "to " .. MSWPvar

    elseif string.byte(MSWPquest, 5) == 0 then
    MSWPvar = ipc.readSTR(0x60A4,4)
    MSWPtxt = "to " .. MSWPvar

    elseif string.byte(MSWPquest, 6) == 0 then
    MSWPvar = ipc.readSTR(0x60A4,5)
    MSWPtxt = "to " .. MSWPvar

    else
        if MSWPvar ~= nil then
            MSWPtxt = MSWPvar .. "no WP"
        end
    end
end

function MSFS_Magneto1_show ()
    Mag1Svar = ipc.readUW(0x0892)
    if Mag1Svar == 0 then Mag1Stxt = "off"
    elseif Mag1Svar == 1 then Mag1Stxt = "rght"
    elseif Mag1Svar == 2 then Mag1Stxt = "left"
    elseif Mag1Svar == 3 then Mag1Stxt = "both"
    elseif Mag1Svar == 4 then Mag1Stxt = "Strt"
    end
    DspShow ("MAG1", Mag1Stxt)
end

function MSFS_Magneto2_show ()
    Mag2Svar = ipc.readUW(0x092A)
    if Mag2Svar == 0 then Mag2Stxt = "off"
    elseif Mag2Svar == 1 then Mag2Stxt = "rght"
    elseif Mag2Svar == 2 then Mag2Stxt = "left"
    elseif Mag2Svar == 3 then Mag2Stxt = "both"
    elseif Mag2Svar == 4 then Mag2Stxt = "Strt"
    end
    DspShow ("MAG2", Mag2Stxt)
end

function Timer ()

    if ipc.get("DSPmode") == 1 then
        HDGset = round(ipc.readUW("07CC")/182)
        DspHDG(HDGset)
    end

    MSFS_Flaps ()
    MSFS_Baro ()
    MSFS_Trim ()
    MSFS_ParkingBrake ()
    MSFS_showWP ()

    -- show Flaps
        com.write(dev, "A/TFL", 8) -- AP stby
        com.write(dev, "F/D" .. flapTxt, 8) -- FD

    -- is AP enabled?
    MSAPon = ipc.readUB(0x07BC)

    -- FLCg?
    FLCgvar = ipc.readUB(0x0B49)
    if FLCgvar == 1 then DspSPD_FLCH_on ()
    elseif FLCgvar == 0 then DspSPD_FLCH_off ()
    end

    -- HDG?
    HDGgvar = ipc.readUB(0x07C8)
    if HDGgvar == 1 then DspHDG_AP_on ()
    elseif HDGgvar == 0 then DspHDG_AP_off ()
    end

    -- ALT?
    ALTgvar = ipc.readUB(0x07D0)
    if ALTgvar == 1 then DspALT_AP_on ()
    elseif ALTgvar == 0 then DspALT_AP_off ()
    end

    -- SPD?
    SPDgvar = ipc.readUB(0x07DC)
    if SPDgvar == 1 then DspSPD_AP_on ()
    elseif SPDgvar == 0 then DspSPD_AP_off ()
    end

    -- VS?
    VSgvar = ipc.readUB(0x07EC)
    if VSgvar == 1 then DspVVS_AP_on ()
    elseif VSgvar == 0 then DspVVS_AP_off ()
    end

    -- NAV?

    NAVgvar = ipc.readUB(0x07C4)
    if NAVgvar == 1 then DspLNAV_on ()
    elseif NAVgvar == 0 then DspLNAV_off ()
    end

    -- Ice building on struct in % ?
    MSIceBuild = round((100/16384)*ipc.readUW(0x0348))

    -- Waypoint active ?
    MSWpActive = ipc.readUW(0x6004)

    if MSParkBvar == 0 then

        if MSAPon == 0 then

            if MSIceBuild < 10 then
                UpperInfoLong = MSTrimTxt
                LowerInfoLong = Baro
            else
                UpperInfoLong = "Ice " .. MSIceBuild .. "%"
                LowerInfoLong = "Trm " .. MSTrimTxt1 .. MSTrimTxt2
            end

        elseif MSAPon == 1 then

            if MSIceBuild < 10 then
                UpperInfoLong = MSWPtxt
                LowerInfoLong = Baro
            else
                UpperInfoLong = "Ice " .. MSIceBuild .. "%"
                LowerInfoLong = MSWPtxt
            end
         end

    else
    UpperInfoLong = "PrkBrk! "
    LowerInfoLong = Baro
    end

    FLIGHT_INFO1 = UpperInfoLong
    FLIGHT_INFO2 = LowerInfoLong
end

-- ## Autopilot  ###############

-- $$ AP and FD

function MSFS_AP_Master_on ()
    ipc.writeUW(0x07BC, 1)
    DspShow ("AP", "on")
end

function MSFS_AP_Master_off ()
    ipc.writeUW(0x07BC, 0)
    DspShow ("AP", "off")
end

function MSFS_AP_Master_toggle ()
	if ipc.readUW(0x07BC) == 0 then
        MSFS_AP_Master_on ()
	else
        MSFS_AP_Master_off ()
	end
end

function MSFS_FD_on ()
    ipc.writeUW(0x2EE0, 1)
    DspShow ("FD", "on")
end

function MSFS_FD_off ()
    ipc.writeUW(0x2EE0, 0)
    DspShow ("FD", "off")
end

function MSFS_FD_toggle ()
	if ipc.readUW(0x2EE0) == 0 then
        MSFS_FD_on ()
	else
        MSFS_FD_off ()
	end
end

-- $$ YD

function MSFS_YD_toggle ()
    ipc.control(65793)
    DspShow ("YD", "hold")
end

-- $$ Airbus AP functions

function MSFS_Autopilot_SPD_SET ()
    ipc.control("68066", 1)
    DspShow ("SPD", "set")
end

function MSFS_Autopilot_SPD_MNGD ()
    ipc.control("68066", 2)
    DspShow ("SPD", "mngd")
end

function MSFS_Autopilot_HDG_SET ()
    ipc.control("68065", 1)
    DspShow ("HDG", "set")
end

function MSFS_Autopilot_HDG_MNGD ()
    ipc.control("68065", 2)
    DspShow ("HDG", "mngd")
end

function MSFS_Autopilot_ALT_SET ()
    ipc.control("68067", 1)
    DspShow ("ALT", "set")
end

function MSFS_Autopilot_ALT_MNGD ()
    ipc.control("68067", 2)
    DspShow ("ALT", "mngd")
end

-- $$ AP functions

function MSFS_HDG_hold_toggle ()
    ipc.control(65725)
    SyncBackHDG (0, ipc.readUW(0x07CC), true)
    DspShow ("HDG", "hold")
end

function MSFS_HDG_sel_toggle ()
    ipc.control(65798)
    SyncBackHDG (0, ipc.readUW(0x07CC), true)
    DspShow ("HDG", "sel")
end

function MSFS_ALT_hold_toggle ()
    ipc.control(65726)
    ipc.sleep(100)
    SyncBackALT (0, ipc.readUD(0x07D4), true)

    DspShow ("ALT", "hold")
end

function MSFS_ALT_managed ()
    ipc.control(68067, 2)
    ipc.sleep(100)
    SyncBackALT (0, ipc.readUD(0x07D4), true)

    DspShow ("ALT", "mngd")
end

function MSFS_VS_hold_toggle ()
    ipc.control(65890)
    SyncBackALT (0, ipc.readUD(0x07D4), true)
    DspShow ("VS", "hold")
end

function MSFS_NAV1_hold_toggle ()
    ipc.control(65729)
    DspShow ("NAV1", "hold")
end

function MSFS_APPR_hold_toggle ()
    ipc.control(65724)
    DspShow ("APPR", "hold")
end

-- ## Autopilot Rotaries ###############

-- $$ ALT

function MSFS_ALT_inc ()
    ipc.control(65892)
    SyncBackALT (0, ipc.readUD(0x07D4), true)

end

function MSFS_ALT_dec ()
    ipc.control(65893)
    SyncBackALT (0, ipc.readUD(0x07D4), true)

end

function MSFS_ALT_incfast ()
    ipc.control(1017)
    SyncBackALT (0, ipc.readUD(0x07D4), true)

end

function MSFS_ALT_decfast ()
    ipc.control(1016)
    SyncBackALT (0, ipc.readUD(0x07D4), true)

end

-- $$ HDG

function MSFS_Align_HDG ()
    CurrHDG = round(ipc.readDBL("2B00"))
    ipc.control(66042, CurrHDG)

    DspShow ("HDG", CurrHDG, "HDG set", CurrHDG)
end

function MSFS_HDG_inc ()
    ipc.control(65879)
    SyncBackHDG (0, ipc.readUW(0x07CC), true)
end

function MSFS_HDG_dec ()
    ipc.control(65880)
    SyncBackHDG (0, ipc.readUW(0x07CC), true)
end

function MSFS_HDG_incfast ()
    ipc.control(1025)
    SyncBackHDG (0, ipc.readUW(0x07CC), true)
end

function MSFS_HDG_decfast ()
    ipc.control(1024)
    SyncBackHDG (0, ipc.readUW(0x07CC), true)
end

-- $$ SPD

function MSFS_SPD_inc ()
    ipc.control(65896)
end

function MSFS_SPD_dec ()
    ipc.control(65897)
end

function MSFS_SPD_incfast ()
    ipc.control(1021)
end

function MSFS_SPD_decfast ()
    ipc.control(1020)
end

-- $$ VS

function MSFS_VS_inc ()
    ipc.control(65894)
    SyncBackVVS (0, ipc.readUW(0x07F2), true)
end

function MSFS_VS_dec ()
    ipc.control(65895)
    SyncBackVVS (0, ipc.readUW(0x07F2), true)
end

function MSFS_VS_incfast ()
    ipc.control(1023)
    SyncBackVVS (0, ipc.readUW(0x07F2), true)
end

function MSFS_VS_decfast ()
    ipc.control(1022)
    SyncBackVVS (0, ipc.readUW(0x07F2), true)
end

function MSFS_VS_setZero ()
    ipc.writeUW(0x07F2, 0)
    DspVVS (0)
    DspShow ("Rset", "VS", "Reset", "VS")
end

-- ## Electrics ###############

function MSFS_MasterBatt_on ()
    if ipc.readUB(0x3102) == 0 then
        ipc.control(66241, 1)
        _sleep(100,200)
        ipc.control(66241, 2)
    end
    DspShow ("Batt", "on", "Battery", "all on")
end

function MSFS_MasterBatt_off ()
    if ipc.readUB(0x3102) == 1 then
        ipc.control(66241, 1)
        _sleep(100,200)
        ipc.control(66241, 2)
    end
    DspShow ("Batt", "off", "Battery", "all off")
end

function MSFS_MasterBatt_toggle ()
	if ipc.readUB(0x3102) == 0 then
       MSFS_MasterBatt_on ()
	else
       MSFS_MasterBatt_off ()
	end
end

function MSFS_AlternatorAll_on ()
    ipc.writeUB(0x3101, 1)
    DspShow ("ALTR", "on", "Altern.", "on")
end

function MSFS_AlternatorAll_off ()
    ipc.writeUB(0x3101, 0)
    DspShow ("ALTR", "off", "Altern.", "off")
end

function MSFS_AlternatorAll_toggle ()
	if ipc.readUB(0x3101) == 0 then
       MSFS_AlternatorAll_on ()
	else
       MSFS_AlternatorAll_off ()
	end
end

-- ## Avionics ###############

function MSFS_Avionics_on ()
    ipc.writeUB(0x3103, 1)
    DspShow ("AVIO", "on", "Avionics", "on")
end

function MSFS_Avionics_off ()
    ipc.writeUB(0x3103, 0)
    DspShow ("AVIO", "off", "Avionics", "off")
end

function MSFS_Avionics_toggle ()
	if ipc.readUB(0x3103) == 0 then
       MSFS_Avionics_on ()
	else
       MSFS_Avionics_off ()
	end
end

-- $$ --

function MSFS_NAV_GPS_nav ()
    ipc.writeUB(0x132C, 0)
    DspShow ("NAV", "on", "NAV GPS", "nav")
end

function MSFS_NAV_GPS_gps ()
    ipc.writeUB(0x132C, 1)
    DspShow ("GPS", "on", "NAV GPS", "gps")
end

function MSFS_NAV_GPS_toggle ()
	if ipc.readUB(0x132C) == 0 then
       MSFS_NAV_GPS_gps ()
	else
       MSFS_NAV_GPS_nav ()
	end
end

-- $$ --

function MSFS_ADF_RadioSwap ()
    ipc.control(66742)
    DspShow ("ADF", "swap")
end

-- ## Magnetos ###############

-- $$ Mag 1

function MSFS_Magneto1_inc ()
    Mag1HEX = 0x0892

    Mag1var = ipc.readUW(Mag1HEX)

    if Mag1var == 0 then ipc.writeUW(Mag1HEX, 1)
    elseif Mag1var == 1 then ipc.writeUW(Mag1HEX, 2)
    elseif Mag1var == 2 then ipc.writeUW(Mag1HEX, 3)
    elseif Mag1var == 3 then ipc.writeUW(Mag1HEX, 4)
    end

    ipc.sleep(50)
    MSFS_Magneto1_show ()
end

function MSFS_Magneto1_dec ()
    Mag1HEX = 0x0892

    Mag1var = ipc.readUW(Mag1HEX)

    if Mag1var == 4 then ipc.writeUW(Mag1HEX, 3)
    elseif Mag1var == 3 then ipc.writeUW(Mag1HEX, 2)
    elseif Mag1var == 2 then ipc.writeUW(Mag1HEX, 1)
    elseif Mag1var == 1 then ipc.writeUW(Mag1HEX, 0)
        ipc.sleep(100)
        ipc.writeUW(Mag1HEX, 0)
    end

    ipc.sleep(50)
    MSFS_Magneto1_show ()
end


function MSFS_Magneto1_off ()
    Mag1HEX = 0x0892
    ipc.writeUW(Mag1HEX, 0)
    ipc.sleep(100)
    ipc.writeUW(Mag1HEX, 0)
    ipc.sleep(50)
    MSFS_Magneto1_show ()
end

function MSFS_Magneto1_right ()
    Mag1HEX = 0x0892
    ipc.writeUW(Mag1HEX, 1)
    ipc.sleep(50)
    MSFS_Magneto1_show ()
end

function MSFS_Magneto1_left ()
    Mag1HEX = 0x0892
    ipc.writeUW(Mag1HEX, 2)
    ipc.sleep(50)
    MSFS_Magneto1_show ()
end

function MSFS_Magneto1_both ()
    Mag1HEX = 0x0892
    ipc.writeUW(Mag1HEX, 3)
    ipc.sleep(50)
    MSFS_Magneto1_show ()
end

function MSFS_Magneto1_start ()
    Mag1HEX = 0x0892
    ipc.writeUW(Mag1HEX, 4)
    ipc.sleep(50)
    MSFS_Magneto1_show ()
end

-- $$ Mag 2

function MSFS_Magneto2_inc ()
    Mag2HEX = 0x092A

    Mag2var = ipc.readUW(Mag2HEX)

    if Mag2var == 0 then ipc.writeUW(Mag2HEX, 1)
    elseif Mag2var == 1 then ipc.writeUW(Mag2HEX, 2)
    elseif Mag2var == 2 then ipc.writeUW(Mag2HEX, 3)
    elseif Mag2var == 3 then ipc.writeUW(Mag2HEX, 4)
    end

    ipc.sleep(50)
    MSFS_Magneto2_show ()
end

function MSFS_Magneto2_dec ()
    Mag2HEX = 0x092A

    Mag2var = ipc.readUW(Mag2HEX)

    if Mag2var == 4 then ipc.writeUW(Mag2HEX, 3)
    elseif Mag2var == 3 then ipc.writeUW(Mag2HEX, 2)
    elseif Mag2var == 2 then ipc.writeUW(Mag2HEX, 1)
    elseif Mag2var == 1 then ipc.writeUW(Mag2HEX, 0)
        ipc.sleep(100)
        ipc.writeUW(Mag2HEX, 0)
    end

    ipc.sleep(50)
    MSFS_Magneto2_show ()
end


function MSFS_Magneto2_off ()
    Mag2HEX = 0x092A
    ipc.writeUW(Mag2HEX, 0)
    ipc.sleep(100)
    ipc.writeUW(Mag2HEX, 0)
    ipc.sleep(50)
    MSFS_Magneto2_show ()
end

function MSFS_Magneto2_right ()
    Mag2HEX = 0x092A
    ipc.writeUW(Mag2HEX, 1)
    ipc.sleep(50)
    MSFS_Magneto2_show ()
end

function MSFS_Magneto2_left ()
    Mag2HEX = 0x092A
    ipc.writeUW(Mag2HEX, 2)
    ipc.sleep(50)
    MSFS_Magneto2_show ()
end

function MSFS_Magneto2_both ()
    Mag2HEX = 0x092A
    ipc.writeUW(Mag2HEX, 3)
    ipc.sleep(50)
    MSFS_Magneto2_show ()
end

function MSFS_Magneto2_start ()
    Mag2HEX = 0x092A
    ipc.writeUW(Mag2HEX, 4)
    ipc.sleep(50)
    MSFS_Magneto2_show ()
end

-- ## Internal Lights ###############

function Lights_PANEL_on ()
    n = ipc.readUW("0D0C")
    n = logic.Or(n, 32)
    ipc.writeUW("0D0C", n)
	DspShow ("PANL", "on")
end

function Lights_PANEL_off ()
    ipc.clearbitsUW("0D0C", 32)
	DspShow ("PANL", "off ")
end

function Lights_PANEL_toggle ()
    if logic.And(ipc.readUW("0D0C"), 32) == 32 then
		Lights_PANEL_off ()
	else
		Lights_PANEL_on ()
	end
end

-- ## External Lights ###############

function MSFS_Lights_LANDING_on ()
    n = ipc.readUW("0D0C")
    n = logic.Or(n, 4)
    ipc.writeUW("0D0C", n)
	DspShow ("LNDG", "on")
end

function MSFS_Lights_LANDING_off ()
	ipc.clearbitsUW("0D0C", 4)
	DspShow ("LNDG", "off")
end

function MSFS_Lights_LANDING_toggle ()
    if logic.And(ipc.readUW("0D0C"), 4) == 4 then
		MSFS_Lights_LANDING_off ()
	else
		MSFS_Lights_LANDING_on ()
	end
end

function MSFS_Lights_TAXI_on ()
    n = ipc.readUW("0D0C")
    n = logic.Or(n, 8)
    ipc.writeUW("0D0C", n)
	DspShow ("TAXI", "on")
end

function MSFS_Lights_TAXI_off ()
	ipc.clearbitsUW("0D0C", 8)
	DspShow ("TAXI", "off")
end

function MSFS_Lights_TAXI_toggle ()
    if logic.And(ipc.readUW("0D0C"), 8) == 8 then
		MSFS_Lights_TAXI_off ()
	else
		MSFS_Lights_TAXI_on ()
	end
end

-- $$ --

function MSFS_Lights_BEACON_on ()
    n = ipc.readUW("0D0C")
    n = logic.Or(n, 2)
    ipc.writeUW("0D0C", n)
	DspShow ("BCN", "on")
end

function MSFS_Lights_BEACON_off ()
	ipc.clearbitsUW("0D0C", 2)
	DspShow ("BCN", "off")
end

function MSFS_Lights_BEACON_toggle ()
    if logic.And(ipc.readUW("0D0C"), 2) == 2 then
		MSFS_Lights_BEACON_off ()
	else
		MSFS_Lights_BEACON_on ()
	end
end

function MSFS_Lights_STROBE_on ()
    n = ipc.readUW("0D0C")
    n = logic.Or(n, 16)
    ipc.writeUW("0D0C", n)

	DspShow ("STRB", "on")
end

function MSFS_Lights_STROBE_off ()
	ipc.clearbitsUW("0D0C", 16)
	DspShow ("STRB", "off")
end

function MSFS_Lights_STROBE_toggle ()
    if logic.And(ipc.readUW("0D0C"), 16) == 16 then
		MSFS_Lights_STROBE_off ()
	else
		MSFS_Lights_STROBE_on ()
	end
end

function MSFS_Lights_NAV_on ()
    n = ipc.readUW("0D0C")
    n = logic.Or(n, 1)
    ipc.writeUW("0D0C", n)
	DspShow ("NAV", "on")
end

function MSFS_Lights_NAV_off ()
	ipc.clearbitsUW("0D0C", 1)
    DspShow ("NAV", "off")
end

function MSFS_Lights_NAV_toggle ()
    if logic.And(ipc.readUW("0D0C"), 1) == 1 then
		MSFS_Lights_NAV_off ()
	else
		MSFS_Lights_NAV_on ()
	end
end

-- $$ --

function MSFS_Lights_WING_on ()
    n = ipc.readUW("0D0C")
    n = logic.Or(n, 128)
    ipc.writeUW("0D0C", n)
	DspShow ("WING", "on")
end

function MSFS_Lights_WING_off ()
	ipc.clearbitsUW("0D0C", 128)
    DspShow ("WING", "off")
end

function MSFS_Lights_WING_toggle ()
    if logic.And(ipc.readUW("0D0C"), 128) == 128 then
		MSFS_Lights_WING_off ()
	else
		MSFS_Lights_WING_on ()
	end
end

-- ## Fuel Valves ###############

function MSFS_FuelValve1_on ()
    ipc.writeUB("3590", 1)
    DspShow ("Fuel", "1 on", "FuelValv", "1 on")
end

function MSFS_FuelValve1_off ()
    ipc.writeUB("3590", 0)
    DspShow ("Fuel", "1off", "FuelValv", "1 off")
end

function MSFS_FuelValve1_toggle ()
    if ipc.readUB(0x3590) == 0 then
       MSFS_FuelValve1_on ()
	else
       MSFS_FuelValve1_off ()
	end
end

-- $$ --

function MSFS_FuelValve2_on ()
    ipc.writeUB("3594", 1)
    DspShow ("Fuel", "2 on", "FuelValv", "2 on")
end

function MSFS_FuelValve2_off ()
    ipc.writeUB("3594", 0)
    DspShow ("Fuel", "2off", "FuelValv", "2 off")
end

function MSFS_FuelValve2_toggle ()
    if ipc.readUB(0x3594) == 0 then
       MSFS_FuelValve2_on ()
	else
       MSFS_FuelValve2_off ()
	end
end

-- $$ --

function MSFS_FuelValve3_on ()
    ipc.writeUB("3598", 1)
    DspShow ("Fuel", "3 on", "FuelValv", "3 on")
end

function MSFS_FuelValve3_off ()
    ipc.writeUB("3598", 0)
    DspShow ("Fuel", "3off", "FuelValv", "3 off")
end

function MSFS_FuelValve3_toggle ()
    if ipc.readUB(0x3598) == 0 then
       MSFS_FuelValve3_on ()
	else
       MSFS_FuelValve3_off ()
	end
end

-- $$ --

function MSFS_FuelValve4_on ()
    ipc.writeUB("359C", 1)
    DspShow ("Fuel", "4 on", "FuelValv", "4 on")
end

function MSFS_FuelValve4_off ()
    ipc.writeUB("359C", 0)
    DspShow ("Fuel", "4off", "FuelValv", "4 off")
end

function MSFS_FuelValve4_toggle ()
    if ipc.readUB(0x359C) == 0 then
       MSFS_FuelValve4_on ()
	else
       MSFS_FuelValve4_off ()
	end
end

-- ## De Ice ###############

function MSFS_Pitot_Heat_on ()
    ipc.writeUB("029C", 1)
    DspShow ("Ptot", "on", "Pitot", "Heat on")
end

function MSFS_Pitot_Heat_off ()
    ipc.writeUB("029C", 0)
    DspShow ("Ptot", "off", "Pitot", "Heat off")
end

function MSFS_Pitot_Heat_toggle ()
    if ipc.readUB(0x029C) == 0 then
       MSFS_Pitot_Heat_on ()
	else
       MSFS_Pitot_Heat_off ()
	end
end

-- $$ --

function MSFS_StructDeIce_on ()
    ipc.writeUB("337D", 1)
    DspShow ("SIce", "on", "Struct", "Ice on")
end

function MSFS_StructDeIce_off ()
    ipc.writeUB("337D", 0)
    DspShow ("SIce", "off", "Struct", "Ice off")
end

function MSFS_StructDeIce_toggle ()
    if ipc.readUB(0x337D) == 0 then
       MSFS_StructDeIce_on ()
	else
       MSFS_StructDeIce_off ()
	end

end

-- $$ --


function MSFS_Prop_DeIce_on ()
    ipc.writeUB("2440", 1)
    DspShow ("PIce", "on", "Prop", "Ice on")
end

function MSFS_Prop_DeIce_off ()
    ipc.writeUB("2440", 0)
    DspShow ("PIce", "off", "Prop", "Ice off")
end

function MSFS_Prop_DeIce_toggle ()
    if ipc.readUB(0x2440) == 0 then
       MSFS_Prop_DeIce_on ()
	else
       MSFS_Prop_DeIce_off ()
	end
end

-- ## Flight Controls ###############

-- $$ Flaps

function MSFS_Flaps_inc ()
    ipc.control(65758)
    DspShow ("Flap", "inc", "Flaps", "inc")
end

function MSFS_Flaps_dec ()
    ipc.control(65759)
    DspShow ("Flap", "dec", "Flaps", "inc")
end

-- $$ Elev Trim

function MSFS_Elev_Trim_dn ()
    --MSFS_TrimShow ()
    ipc.control(65607)
    MSFS_TrimShow ()
end

function MSFS_Elev_Trim_up ()
    --MSFS_TrimShow ()
    ipc.control(65615)
    MSFS_TrimShow ()
end

-- ## Transponder ###############

function MSFS_XPDR_off ()
    ipc.writeUB(0x0B46, 0)
    DspShow ("XPDR", "off")
end

function MSFS_XPDR_stby ()
    ipc.writeUB(0x0B46, 1)
    DspShow ("XPDR", "stby")
end

function MSFS_XPDR_on ()
    ipc.writeUB(0x0B46, 3)
    DspShow ("XPDR", "on")
end

function MSFS_XPDR_alt ()
    ipc.writeUB(0x0B46, 4)
    DspShow ("XPDR", "alt")
end

function MSFS_XPDR_test ()
    ipc.writeUB(0x0B46, 2)
    DspShow ("XPDR", "test")
end

-- ## Parking Brake ###############

function MSFS_ParkingBrake_on ()
    ipc.writeUW(0x0BC8, 1)
    DspShow ("PBrk", "on", "Parking", "Brake on")
end

function MSFS_ParkingBrake_off ()
    ipc.writeUW(0x0BC8, 0)
    DspShow ("PBrk", "off", "Parking", "Brke off")
end

function MSFS_ParkingBrake_toggle ()
	if ipc.readUW(0x0BC8) == 0 then
       MSFS_ParkingBrake_on ()
	else
       MSFS_ParkingBrake_off ()
	end
end

-- ## Gear ###############

function MSFS_Gear_up ()
    ipc.writeUW(0x0BE8, 0)
    DspShow ("Gear", "up")
end

function MSFS_Gear_down ()
    ipc.writeUW(0x0BE8, 16383)
    DspShow ("Gear", "down")
end

function MSFS_Gear_toggle ()
	if ipc.readUW(0x0BE8) ~= 0 then
       MSFS_Gear_up ()
	else
       MSFS_Gear_down ()
	end
end
