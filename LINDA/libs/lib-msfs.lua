-- Default MSFS
-- Updated for LINDA 4.0.4
-- Nov 2020
-- V 1.21

--[[

-- Updated ---------
* ALL_FuelPumps_on ()
* ALL_FuelPumps_off ()
* COM/NAV/ADF/DME "ident on" indication changed on MCP2 to "*" on radios display
* DspShow() updated to support MCP2, new format: DspShow(mcp1_line1, mcp1_line2, mcp2_line1, mcp2_line2)
* repeated press of XPND button on radios block now toggles 1200 and previos squawk

-- New -------------
* Parameter to replace SPD indication with CRS indication for small planes without autothrust
     SPD_CRS_replace = true -- add this to module's InitVars ()
* Flight auto save - put the plane into cold and dark state and flight will be saved here
* SaveFlight(filename) - saves flight at current point, 'filename' is optional
* ShowMessage (text) - shows green scrollbar message

v1.20
* changed Auto_MASTER implementation

--]]

-- ## Autopilot controls #####################################

function Autopilot_MASTER_toggle ()
	_AP_MASTER ()
end

function Autopilot_MASTER_on ()
	_AUTOPILOT_ON ()
	--[[ipc.control("66701", 1)
	DspShow ("AVIO", "on")   --]]
end

function Autopilot_MASTER_off ()
	_AUTOPILOT_OFF ()
	--[[ipc.control("66701", 0)
	DspShow ("AVIO", "off ")--]]
end

function Autopilot_NAVGPS_toggle ()
	_TOGGLE_GPS_DRIVES_NAV1 ()
end

function Autopilot_NAV_hold ()
	_AP_NAV1_HOLD ()
end

function Autopilot_ATT_hold ()
	_AP_ATT_HOLD ()
end

function Autopilot_LOC_hold ()
	_AP_LOC_HOLD ()
end

function Autopilot_APR_hold ()
	_AP_APR_HOLD ()
end

function Autopilot_VS_hold ()
	_AP_VS_HOLD ()
end

function Autopilot_PANEL_VS_hold ()
	_AP_PANEL_VS_HOLD ()
end

function Autopilot_ALT_hold ()
	_AP_ALT_HOLD ()
end

function Autopilot_PANEL_ALT_hold ()
	_AP_PANEL_ALTITUDE_HOLD ()
end

function Autopilot_BC_hold ()
	_AP_BC_HOLD ()
end

function Autopilot_HDG_hold ()
	_AP_HDG_HOLD ()
end

function Autopilot_PANEL_HDG_hold ()
	_AP_PANEL_HEADING_HOLD ()
end

function Autopilot_HDG_BUG_align ()
	val = ipc.readDBL(0x2B00)
	ipc.writeUW("07cc", val/360*65536)
	DspHDG(val)
end

function Autopilot_AIRSPEED_hold ()
	_AP_AIRSPEED_HOLD ()
end

function Autopilot_N1_hold ()
	_AP_N1_HOLD ()
end

function Autopilot_FD_on ()
	ipc.writeSB("2EE0", 1)
end

function Autopilot_FD_off ()
	ipc.writeSB("2EE0", 0)
end

function Autopilot_ATHR_arm ()
	ipc.writeSB("0810", 1)
end

function Autopilot_ATHR_disarm ()
	ipc.writeSB("0810", 0)
end

function Autopilot_TOGA_on ()
	ipc.writeSB("080C", 1)
end

function Autopilot_TOGA_off ()
	ipc.writeSB("080C", 0)
end

-- ## Radios functions  #####################################

function isAvionicsOn ()
	return ipc.readUB(0x2E80) == 1
end

function Radios_DME_AUDIO_toggle ()
    if logic.And(ipc.readUB(0x3122), 2) ~= 2 then
        if _MCP1 () then
            DspShow("DME","AUD")
        else
            if RADIOS_MODE == 4 then -- DME display is open
                DspRadioIdent_on ()
            else
                DspShow("DME","AUD","DME","Ident On")
            end
        end
    	ipc.control(65839)
	else
        if _MCP1 () then
            DspShow("DME","off")
        else
            if RADIOS_MODE == 4 then -- DME display is open
                DspRadioIdent_off ()
            else
                DspShow("DME","aud","  DME","IdentOff")
            end
        end
    	ipc.control(65834)
	end
end

function Radios_ADF_AUDIO_toggle ()
	_logg("ADF_AUDIO_toggle adf"..adf_sel)
	if adf_sel == 1 then
		if _t("adf1") then
            if _MCP1 () then
                DspShow("ADF1","aud")
            else
                DspRadioIdent_on ()
            end
			ipc.control(65841)
		else
            if _MCP1 () then
                DspShow("ADF1","off")
            else
                DspRadioIdent_off ()
            end
			ipc.control(65836)
		end
	else
		if _t("adf2") then
            if _MCP1 () then
                DspShow("ADF2","aud")
            else
                DspRadioIdent_on ()
            end
			ipc.control(66558)
		else
            if _MCP1 () then
                DspShow("ADF2","off")
            else
                DspRadioIdent_off ()
            end
			ipc.control(66557)
		end
	end
end

function Radios_NAV_AUDIO_toggle ()
	_logg("NAV_AUDIO_toggle nav"..nav_sel)
	if nav_sel == 1 then
		if _t("nav1") then
            if _MCP1 () then
                DspShow("NAV1","aud")
            else
                DspRadioIdent_on ()
            end
			ipc.control(65837)
		else
            if _MCP1 () then
                DspShow("NAV1","off")
            else
                DspRadioIdent_off ()
            end
			ipc.control(65832)
		end
	else
		if _t("nav2") then
            if _MCP1 () then
                DspShow("NAV2","aud")
            else
                DspRadioIdent_on ()
            end
			ipc.control(65838)
		else
            if _MCP1 () then
                DspShow("NAV2","off")
            else
                DspRadioIdent_off ()
            end
			ipc.control(65833)
		end
	end
end

function Radios_COM_AUDIO_toggle ()
	if _t("camaud") then
		ipc.control(66464)
        if _MCP1 () then
    		DspShow("COM2","aud")
        else
            if RADIOS_SUBMODE == 1 then
                DspRadioIdent_off ()
            else
                DspRadioIdent_on ()
            end
        end
	else
		ipc.control(66463)
        if _MCP1 () then
    		DspShow("COM1","aud")
        else
            if RADIOS_SUBMODE == 2 then
                DspRadioIdent_off ()
            else
                DspRadioIdent_on ()
            end
        end
	end
end

function Radios_OMI_AUDIO_toggle ()
    -- _MARKER_SOUND_TOGGLE ()
	local n = ipc.readUB("3122")
	n = logic.Xor(n, 4)
	ipc.writeUB("3122", n)
    _logg(tonumber(logic.And(n, 4)))
    if logic.And(n, 4) == 4 then
        DspShow ("MKR", "on")
    else
        DspShow ("MKR", "off")
    end
end

-- ## Altimeter baro functions  ###############################

function Altimeter_BARO_STD_toggle ()
	if baro_mode ~= 10 then
		baro_cur = ipc.readUW(0x330)
    	ipc.control(66846)
		DspShow("Baro", "Std")
		baro_mode = 10
	else
    	ipc.control(65584)
		baro_cur = ipc.readUW(0x330)
		-- ipc.writeUW(0x330, baro_cur)
		baro_cur = round(((baro_cur * 2992) / (1013.2 * 16)) + 0.5)
		DspShow("Baro", tostring(baro_cur))
		baro_mode = 0
	end
end

function Altimeter_BARO_MODE_hPa ()
	baro_mode = 1
	Altimeter_BARO_show ()
    --7 ipc.writeLvar("hPa Button", 1)
end

function Altimeter_BARO_MODE_inHg ()
	baro_mode = 0
	Altimeter_BARO_show ()
    --7 ipc.writeLvar("inHg Button", 0)
end

function Altimeter_BARO_MODE_mmHg ()
	baro_mode = 2
	Altimeter_BARO_show ()
    --7 ipc.writeLvar("mmHg Button", 0)
end

function Altimeter_BARO_MODE_toggle ()
	baro_mode = baro_mode + 1
    if baro_mode > 2 then baro_mode = 0 end
    if baro_mode == 0 then
		Altimeter_BARO_MODE_inHg ()
	elseif baro_mode == 1  then
		Altimeter_BARO_MODE_hPa ()
	else
		Altimeter_BARO_MODE_mmHg ()
	end
end

function Altimeter_BARO_plus ()
	if not baro_std then
		baro = ipc.readUW(0x330)
		baro = baro + 4
		ipc.writeUW(0x330, baro)
	end
	Altimeter_BARO_show ()
end

function Altimeter_BARO_plusfast ()
	if not baro_std then
		baro = ipc.readUW(0x330)
		baro = baro + fast_baro
		ipc.writeUW(0x330, baro)
	end
	Altimeter_BARO_show ()
end

function Altimeter_BARO_minus ()
	if not baro_std then
		baro = ipc.readUW(0x330)
		baro = baro - 4
		ipc.writeUW(0x330, baro)
	end
	Altimeter_BARO_show ()
end

function Altimeter_BARO_minusfast ()
	if not baro_std then
		baro = ipc.readUW(0x330)
		baro = baro - fast_baro
		ipc.writeUW(0x330, baro)
	end
	Altimeter_BARO_show ()
end

function Altimeter_BARO_show ()
	local baro = ipc.readUW(0x330)
	-- hPa mode
	if baro_mode == 0 then
		l1 = "inHg"
		baro = round(((baro * 2992) / (1013.2 * 16)) + 0.5)
	-- mbar mode
	elseif baro_mode == 1 then
		l1 = " hPa"
		baro = baro / 16
	-- mm/m mode
	elseif baro_mode == 2 then
		l1 = "mmHg"
		baro = ((baro * 760) / (1013.2 * 16)) + 0.5
	else
		DspShow("Baro", "Std")
		return
	end
	DspShow(l1, string.format("%4d", baro))
end

-- ## FSX GPS controls #####################################

function GPS_NRST_button ()
	_GPS_NEAREST_BUTTON ()
end

function GPS_OBS_button ()
	_GPS_OBS_BUTTON ()
end

function GPS_MSG_button ()
	_GPS_MSG_BUTTON ()
end

function GPS_FPL_button ()
	_GPS_FLIGHTPLAN_BUTTON ()
end

function GPS_TERR_button ()
	_GPS_TERRAIN_BUTTON ()
end

function GPS_PROC_button ()
	_GPS_PROCEDURE_BUTTON ()
end

function GPS_ZOOM_dec ()
	_GPS_ZOOMIN_BUTTON ()
end

function GPS_ZOOM_inc ()
	_GPS_ZOOMOUT_BUTTON ()
end

function GPS_DIRECTTO_button ()
	_GPS_DIRECTTO_BUTTON ()
end

function GPS_MENU_button ()
	_GPS_MENU_BUTTON ()
end

function GPS_CLR_button ()
	_GPS_CLEAR_BUTTON ()
end

function GPS_ENTER_button ()
	_GPS_ENTER_BUTTON ()
end

function GPS_CRSR_button ()
	_GPS_CURSOR_BUTTON ()
end

function GPS_GROUP_inc ()
	_GPS_GROUP_KNOB_INC ()
end

function GPS_GROUP_dec ()
	_GPS_GROUP_KNOB_DEC ()
end

function GPS_PAGE_inc ()
	_GPS_PAGE_KNOB_INC ()
end

function GPS_PAGE_dec ()
	_GPS_PAGE_KNOB_DEC ()
end

function GPS_GROUP_show ()
	DspShow("GPS", "Grp")
end

function GPS_PAGE_show ()
	DspShow("GPS", "Page")
end

-- ## EFIS #####################################

function EFIS_MINIMUMS_inc ()
	_INCREASE_DECISION_HEIGHT ()
end

function EFIS_MINIMUMS_dec ()
	_DECREASE_DECISION_HEIGHT ()
end

function EFIS_MINIMUMS_show ()
	DspShow("MINS", "--")
end

function EFIS_WPT ()
    --7 ipc.writeLvar("L:MapItem Shown", 0)
    DspShow("EFIS", "WPT")
end

function EFIS_VORD ()
    --7 ipc.writeLvar("L:MapItem Shown", 1)
    DspShow("EFIS", "VORD")
end

function EFIS_NDB ()
    --7 ipc.writeLvar("L:MapItem Shown", 2)
    DspShow("EFIS", "NDB")
end

function EFIS_ARPT ()
    --7 ipc.writeLvar("L:MapItem Shown", 3)
    DspShow("EFIS", "ARPT")
end

function EFIS_ADF1 ()
	LVarSet = "EFIS VORADF1"
	--7 ipc.writeLvar(LVarSet, 2)
    --7 ipc.writeLvar("L:VOR 1 Switch", 2)
    DspShow("ADF" , "1")
end

function EFIS_VOR1 ()
	LVarSet = "EFIS VORADF1"
	--7 ipc.writeLvar(LVarSet, 0)
    --7 ipc.writeLvar("L:VOR 1 Switch", 0)
    DspShow("VOR" , "1")
end

function EFIS_ADFVOR1_off ()
	LVarSet = "EFIS VORADF1"
	--7 ipc.writeLvar(LVarSet, 1)
    --7 ipc.writeLvar("L:VOR 1 Switch", 1)
    DspShow("VOR1" , "off")
end

function EFIS_ADF2 ()
	LVarSet = "EFIS VORADF2"
	--7 ipc.writeLvar(LVarSet, 2)
    --7 ipc.writeLvar("L:VOR 2 Switch", 2)
    DspShow("ADF" , "2")
end

function EFIS_VOR2 ()
	LVarSet = "EFIS VORADF2"
	--7 ipc.writeLvar(LVarSet, 0)
    --7 ipc.writeLvar("L:VOR 2 Switch", 0)
    DspShow("VOR" , "2")
end

function EFIS_ADFVOR2_off ()
	LVarSet = "EFIS VORADF2"
	--7 ipc.writeLvar(LVarSet, 1)
    --7 ipc.writeLvar("L:VOR 2 Switch", 1)
    DspShow("VOR2" , "off")
end

function EFIS_MAPMODE_ils ()
    --7 ipc.writeLvar("L:Display Mode", 0)
    DspShow("MAP" , "ILS")
end

function EFIS_MAPMODE_vor ()
    --7 ipc.writeLvar("L:Display Mode", 1)
    DspShow("MAP" , "VOR")
end

function EFIS_MAPMODE_nav ()
    --7 ipc.writeLvar("L:Display Mode", 2)
    DspShow("MAP" , "NAV")
end

function EFIS_MAPMODE_arc ()
    --7 ipc.writeLvar("L:Display Mode", 3)
    DspShow("MAP" , "ARC")
end

function EFIS_MAPMODE_inc ()
    --7 MMvar = ipc.readLvar("L:Display Mode")
    if MMvar < 4 then
        MMvar = MMvar + 1
    end
    if MMvar == 0 then
        EFIS_MAPMODE_ils ()
    elseif MMvar == 1 then
        EFIS_MAPMODE_vor ()
    elseif MMvar == 2 then
        EFIS_MAPMODE_nav ()
    elseif MMvar == 3 then
        EFIS_MAPMODE_arc ()
    end
end

function EFIS_MAPMODE_dec ()
    --7 MMvar = ipc.readLvar("L:Display Mode")
    if MMvar > -1 then
        MMvar = MMvar - 1
    end
    if MMvar == 0 then
        EFIS_MAPMODE_ils ()
    elseif MMvar == 1 then
        EFIS_MAPMODE_vor ()
    elseif MMvar == 2 then
        EFIS_MAPMODE_nav ()
    elseif MMvar == 3 then
        EFIS_MAPMODE_arc ()
    end
end

-------------

function EFIS_BOEING_MAPMODE_app ()
    --7 ipc.writeLvar("L:EFIS Mode", 0)
    DspShow("EFIS" , "APP")
end

function EFIS_BOEING_MAPMODE_vor ()
    --7 ipc.writeLvar("L:EFIS Mode", 1)
    DspShow("EFIS" , "VOR")
end

function EFIS_BOEING_MAPMODE_map ()
    --7 ipc.writeLvar("L:EFIS Mode", 2)
    DspShow("EFIS" , "MAP")
end

function EFIS_BOEING_MAPMODE_inc ()
    --7 MMvar = ipc.readLvar("L:EFIS Mode")
    if MMvar < 3 then
        MMvar = MMvar + 1
    end
    if MMvar == 0 then
        EFIS_BOEING_MAPMODE_app ()
    elseif MMvar == 1 then
        EFIS_BOEING_MAPMODE_vor ()
    elseif MMvar == 2 then
        EFIS_BOEING_MAPMODE_map ()
    end
end

function EFIS_BOEING_MAPMODE_dec ()
    --7 MMvar = ipc.readLvar("L:EFIS Mode")
    if MMvar > -1 then
        MMvar = MMvar - 1
    end
    if MMvar == 0 then
        EFIS_BOEING_MAPMODE_app ()
    elseif MMvar == 1 then
        EFIS_BOEING_MAPMODE_vor ()
    elseif MMvar == 2 then
        EFIS_BOEING_MAPMODE_map ()
    end
end

function EFIS_BOEING_MODE_centered ()
    --7 ipc.writeLvar("L:MFD Centered", 1)
    DspShow("EFIS" , "Cent")
end

function EFIS_BOEING_MODE_uncentered ()
    --7 ipc.writeLvar("L:MFD Centered", 0)
    DspShow("EFIS" , "UnCt")
end

function EFIS_BOEING_center_toggle ()
	if _t("cent") then
        EFIS_BOEING_MODE_centered ()
	else
        EFIS_BOEING_MODE_uncentered ()
	end
end

-------------

function EFIS_MAPZOOM_10 ()
    --7 ipc.writeLvar("L:Display Scale", 0)
    DspShow("ZOOM" , "10")
end

function EFIS_MAPZOOM_20 ()
    --7 ipc.writeLvar("L:Display Scale", 1)
    DspShow("ZOOM" , "20")
end

function EFIS_MAPZOOM_40 ()
    --7 ipc.writeLvar("L:Display Scale", 2)
    DspShow("ZOOM" , "40")
end

function EFIS_MAPZOOM_80 ()
    --7 ipc.writeLvar("L:Display Scale", 3)
    DspShow("ZOOM" , "80")
end

function EFIS_MAPZOOM_160 ()
    --7 ipc.writeLvar("L:Display Scale", 4)
    DspShow("ZOOM" , "160")
end

function EFIS_MAPZOOM_320 ()
    --7 ipc.writeLvar("L:Display Scale", 5)
    DspShow("ZOOM" , "320")
end

function EFIS_MAPZOOM_inc ()
    --7 MZvar = ipc.readLvar("L:Display Scale")
    if MZvar < 6 then
        MZvar = MZvar + 1
    end
    if MZvar == 0 then
        EFIS_MAPZOOM_10 ()
    elseif MZvar == 1 then
        EFIS_MAPZOOM_20 ()
    elseif MZvar == 2 then
        EFIS_MAPZOOM_40 ()
    elseif MZvar == 3 then
        EFIS_MAPZOOM_80 ()
    elseif MZvar == 4 then
        EFIS_MAPZOOM_160 ()
    elseif MZvar == 5 then
        EFIS_MAPZOOM_320 ()
    end
end

function EFIS_MAPZOOM_dec ()
    --7 MZvar = ipc.readLvar("L:Display Scale")
    if MZvar > -1 then
        MZvar = MZvar - 1
    end
    if MZvar == 0 then
        EFIS_MAPZOOM_10 ()
    elseif MZvar == 1 then
        EFIS_MAPZOOM_20 ()
    elseif MZvar == 2 then
        EFIS_MAPZOOM_40 ()
    elseif MZvar == 3 then
        EFIS_MAPZOOM_80 ()
    elseif MZvar == 4 then
        EFIS_MAPZOOM_160 ()
    elseif MZvar == 5 then
        EFIS_MAPZOOM_320 ()
    end
end

-- ## Lights / Signs ###################################

function Lights_CABIN_on ()
    n = ipc.readUW("0D0C")
    n = logic.Or(n, 512)
    ipc.writeUW("0D0C", n)
	DspShow ("FLD", "on")
end

function Lights_CABIN_off ()
	ipc.clearbitsUW("0D0C", 512)
	DspShow ("FLD", "off")
end

function Lights_CABIN_toggle ()
    if logic.And(ipc.readUW("0D0C"), 512) == 512 then
		Lights_CABIN_off ()
	else
		Lights_CABIN_on ()
	end
end

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

function Lights_BEACON_on ()
    n = ipc.readUW("0D0C")
    n = logic.Or(n, 2)
    ipc.writeUW("0D0C", n)
	DspShow ("BCN", "on")
end

function Lights_BEACON_off ()
	ipc.clearbitsUW("0D0C", 2)
	DspShow ("BCN", "off")
end

function Lights_BEACON_toggle ()
    if logic.And(ipc.readUW("0D0C"), 2) == 2 then
		Lights_BEACON_off ()
	else
		Lights_BEACON_on ()
	end
end

function Lights_STROBE_on ()
    n = ipc.readUW("0D0C")
    n = logic.Or(n, 16)
    ipc.writeUW("0D0C", n)

	DspShow ("STRB", "on")
end

function Lights_STROBE_off ()
	ipc.clearbitsUW("0D0C", 16)
	DspShow ("STRB", "off")
end

function Lights_STROBE_toggle ()
    if logic.And(ipc.readUW("0D0C"), 16) == 16 then
		Lights_STROBE_off ()
	else
		Lights_STROBE_on ()
	end
end

function Lights_NAV_on ()
    n = ipc.readUW("0D0C")
    n = logic.Or(n, 1)
    ipc.writeUW("0D0C", n)
	DspShow ("NAV", "on")
end

function Lights_NAV_off ()
	ipc.clearbitsUW("0D0C", 1)
    DspShow ("NAV", "off")
end

function Lights_NAV_toggle ()
    if logic.And(ipc.readUW("0D0C"), 1) == 1 then
		Lights_NAV_off ()
	else
		Lights_NAV_on ()
	end
end

function Lights_LANDING_on ()
    n = ipc.readUW("0D0C")
    n = logic.Or(n, 4)
    ipc.writeUW("0D0C", n)
	DspShow ("LNDG", "on")
end

function Lights_LANDING_off ()
	ipc.clearbitsUW("0D0C", 4)
	DspShow ("LNDG", "off")
end

function Lights_LANDING_toggle ()
    if logic.And(ipc.readUW("0D0C"), 4) == 4 then
		Lights_LANDING_off ()
	else
		Lights_LANDING_on ()
	end
end

function Lights_TAXI_on ()
    n = ipc.readUW("0D0C")
    n = logic.Or(n, 8)
    ipc.writeUW("0D0C", n)
	DspShow ("TAXI", "on")
end

function Lights_TAXI_off ()
	ipc.clearbitsUW("0D0C", 8)
	DspShow ("TAXI", "off")
end

function Lights_TAXI_toggle ()
    if logic.And(ipc.readUW("0D0C"), 8) == 8 then
		Lights_TAXI_off ()
	else
		Lights_TAXI_on ()
	end
end

function Lights_RECOGN_toggle ()
	n = ipc.readUW("0D0C")
	n = logic.Xor(n, 64)
	ipc.writeUW("0D0C", n)
end

function Lights_WING_toggle ()
	n = ipc.readUW("0D0C")
	n = logic.Xor(n, 128)
	ipc.writeUW("0D0C", n)
end

function Lights_LOGO_toggle ()
	n = ipc.readUW("0D0C")
	n = logic.Xor(n, 256)
	ipc.writeUW("0D0C", n)
end

function Sign_SEATBELTS_toggle ()
	_CABIN_SEATBELTS_ALERT_SWITCH_TOGGLE ()
end

function Sign_NOSMOKING_toggle ()
	_CABIN_NO_SMOKING_ALERT_SWITCH_TOGGLE ()
end

-- ## Systems ###################################

function Gears_up ()
	_GEAR_UP ()
	DspShow ("GEAR", "up")
end

function Gears_down ()
	_GEAR_DOWN ()
	DspShow ("GEAR", "down")
end

function Gears_toggle ()
	_GEAR_TOGGLE ()
end

function Battery_on ()
	ipc.writeUD("281C", 1)
	DspShow ("BAT", "on")
end

function Battery_off ()
	ipc.writeUD("281C", 0)
	DspShow ("BAT", "off")
end

function Battery_toggle ()
    if ipc.readUD("281C") == 0 then
        Battery_on ()
    else
        Battery_off ()
    end
end

function Alternator_on ()
	ipc.writeUB("3101", 1)
	DspShow ("ALT", "on")
end

function Alternator_off ()
	ipc.writeUB("3101", 0)
	DspShow ("ALT", "off")
end

function Alternator_toggle ()
    if ipc.readUB("3101") == 0 then
        Alternator_on ()
    else
        Alternator_off ()
    end
end

function Avionics_MASTER_on ()
	--ipc.writeUD("2e80", 1)
    ipc.control("66701", 1)
	DspShow ("AVIO", "on")
end

function Avionics_MASTER_off ()
	--ipc.writeUD("2e80", 0)
    ipc.control("66701", 0)
	DspShow ("AVIO", "off ")
end

function Avionics_MASTER_toggle ()
    local avio = ipc.readUD("2e80")
    if avio == 1 then
        Avionics_MASTER_off ()
    else
        Avionics_MASTER_on ()
    end
end

function Generator1_on ()
	ipc.setbitsUW("3b78", 1)
end

function Generator2_on ()
	ipc.setbitsUW("3ab8", 1)
end

function Generator3_on ()
	ipc.setbitsUW("39f8", 1)
end

function Generator4_on ()
	ipc.setbitsUW("3938", 1)
end

function ALL_Generators_on ()
	ipc.setbitsUW("3b78", 1)
	ipc.setbitsUW("3ab8", 1)
	ipc.setbitsUW("39f8", 1)
	ipc.setbitsUW("3938", 1)
end

function Generator1_off ()
	ipc.clearbitsUW("3b78", 1)
end

function Generator2_off ()
	ipc.clearbitsUW("3ab8", 1)
end

function Generator3_off ()
	ipc.clearbitsUW("39f8", 1)
end

function Generator4_off ()
	ipc.clearbitsUW("3938", 1)
end

function ALL_Generators_off ()
	ipc.clearbitsUW("3b78", 1)
	ipc.clearbitsUW("3ab8", 1)
	ipc.clearbitsUW("39f8", 1)
	ipc.clearbitsUW("3938", 1)
end

function ALL_FuelPumps_on ()
    ipc.setbitsUB("3125", 0)
    ipc.setbitsUB("3125", 1)
    ipc.setbitsUB("3125", 2)
    ipc.setbitsUB("3125", 3)
    DspShow ("PUMP", "on")
end

function ALL_FuelPumps_off ()
    ipc.clearbitsUB("3125", 0)
    ipc.clearbitsUB("3125", 1)
    ipc.clearbitsUB("3125", 2)
    ipc.clearbitsUB("3125", 3)
    DspShow ("PUMP", "off")
end

function ALL_FuelPumps_toggle ()
--	_FUEL_PUMP ()
	if ipc.readUB(0x3104) == 0 then
        ALL_FuelPumps_on ()
	else
        ALL_FuelPumps_off ()
	end
end

function ALL_FuelSelectors_on ()
	ipc.setbitsUW("3880", 1)
	ipc.setbitsUW("37c0", 1)
	ipc.setbitsUW("3700", 1)
	ipc.setbitsUW("3640", 1)
end

function ALL_FuelSelectors_off ()
	ipc.clearbitsUW("3880", 1)
	ipc.clearbitsUW("37c0", 1)
	ipc.clearbitsUW("3700", 1)
	ipc.clearbitsUW("3640", 1)
end

function Prop_SYNC_toggle ()
	_TOGGLE_PROPELLER_SYNC ()
end

function Brakes ()
	_BRAKES ()
end

function Brakes_PARKING ()
	_PARKING_BRAKES ()
end

function Brakes_ANTISKID_toggle ()
	_ANTISKID_BRAKES_TOGGLE ()
end

function Brakes_AUTOBRAKE_increase ()
	_INCREASE_AUTOBRAKE_CONTROL ()
end

function Brakes_AUTOBRAKE_decrease ()
	_DECREASE_AUTOBRAKE_CONTROL ()
end

function Brakes_AUTOBRAKE_off ()
	_SET_AUTOBRAKE_CONTROL (0)
end

-- ## DeIce ###################################

function DeIce_STRUCTURAL_toggle ()
	_TOGGLE_STRUCTURAL_DEICE ()
end

function DeIce_PITOT_on ()
	_PITOT_HEAT_ON ()
end

function DeIce_PITOT_off ()
	_PITOT_HEAT_OFF ()
end

function DeIce_PITOT_toggle ()
	_PITOT_HEAT_TOGGLE ()
end

function DeIce_PROP_toggle ()
	_TOGGLE_PROPELLER_DEICE ()
end

function CarbHeat_on ()
	ipc.setbitsUW("08b2", 1)
end

function CarbHeat_off ()
	ipc.clearbitsUW("08b2", 1)
end

-- ## Flight controls ############

function Flaps_up ()
	_FLAPS_UP ()
end

function Flaps_down ()
	_FLAPS_DOWN ()
end

function Flaps_incr ()
	_FLAPS_INCR ()
end

function Flaps_decr ()
	_FLAPS_DECR ()
end

function Trim_RUDDER_left ()
	_RUDDER_TRIM_LEFT ()
end

function Trim_RUDDER_right ()
	_RUDDER_TRIM_RIGHT ()
end

function Trim_RUDDER_center ()
	ipc.writeUW("0C04", 0)
end

function Trim_AILERON_left ()
	_AILERON_TRIM_LEFT ()
end

function Trim_AILERON_right ()
	_AILERON_TRIM_RIGHT ()
end

function Trim_AILERON_center ()
	ipc.writeUW("0C02", 0)
end

function Trim_ELEVATOR_up ()
	_ELEV_TRIM_UP ()
end

function Trim_ELEVATOR_down ()
	_ELEV_TRIM_DN ()
end

function Trim_ELEVATOR_center ()
	ipc.control (65706, 1)
	ipc.control (65706, 0)
end

-- ## ATC window ############

function ATC_WINDOW_toggle ()
	_ATC ()
end

function ATC_MENU_0 ()
	_ATC_MENU_0 ()
end

function ATC_MENU_1 ()
	_ATC_MENU_1 ()
end

function ATC_MENU_2 ()
	_ATC_MENU_2 ()
end

function ATC_MENU_3 ()
	_ATC_MENU_3 ()
end

function ATC_MENU_4 ()
	_ATC_MENU_4 ()
end

function ATC_MENU_5 ()
	_ATC_MENU_5 ()
end

function ATC_MENU_6 ()
	_ATC_MENU_6 ()
end

function ATC_MENU_7 ()
	_ATC_MENU_7 ()
end

function ATC_MENU_8 ()
	_ATC_MENU_8 ()
end

function ATC_MENU_9 ()
	_ATC_MENU_9 ()
end

-- ## Engines starting

function Engine_start ()
	_ENGINE_AUTO_START ()
end

function Engine_stop ()
	_ENGINE_AUTO_SHUTDOWN ()
end

function ALL_ENG_start ()
    ENG1_start()
    ENG2_start()
end

function ENG1_start ()
	val = ipc.readSB("0892")
	if val == 3 then
    	_MAGNETO1_START ()
	end
end

function ENG2_start ()
	val = ipc.readSB("092A")
	if val == 3 then
    	_MAGNETO2_START ()
	end
end

function ENG3_start ()
	val = ipc.readSB("09C2")
	if val == 3 then
    	_MAGNETO3_START ()
	end
end

function ENG4_start ()
	val = ipc.readSB("0A5A")
	if val == 3 then
    	_MAGNETO4_START ()
	end
end

----------- Magnetos toggle just from Off to BOTH

function ENG_magneto_show ()
    if FVar == "0892" then
        EngMV = "1"
    elseif FVar == "092A" then
        EngMV = "2"
    elseif FVar == "09C2" then
        EngMV = "3"
    elseif FVar == "0A5A" then
        EngMV = "4"
    end
    if val == 0 then
        MagPos = " off"
    elseif val == 1 then
        MagPos = "rght"
    elseif val == 2 then
        MagPos = "left"
    elseif val == 3 then
        MagPos = "both"
    end
    DspShow("Mag" .. EngMV, MagPos)
end

function ALL_ENG_magneto_R ()
    ENG1_magneto_R()
    ENG2_magneto_R()
end

function ALL_ENG_magneto_L ()
	ENG1_magneto_L()
    ENG2_magneto_L()
end

function ALL_ENG_magneto_Both ()
    ENG1_magneto_Both()
    ENG2_magneto_Both()
end

function ALL_ENG_magneto_inc ()
    ENG1_magneto_inc()
    ENG2_magneto_inc()
end

function ALL_ENG_magneto_dec ()
    ENG1_magneto_dec()
    ENG2_magneto_dec()
end

function ENG1_magneto_off ()
	FVar = "0892"
    val = 0
	ipc.writeUW(FVar, val)
    ENG_magneto_show ()
end

function ENG1_magneto_R ()
	FVar = "0892"
    val = 1
	ipc.writeUW(FVar, val)
    ENG_magneto_show ()
end

function ENG1_magneto_L ()
	FVar = "0892"
    val = 2
	ipc.writeUW(FVar, val)
    ENG_magneto_show ()
end

function ENG1_magneto_Both ()
	FVar = "0892"
    val = 3
	ipc.writeUW(FVar, val)
    ENG_magneto_show ()
end

function ENG1_magneto_inc ()
	FVar = "0892"
	val = ipc.readUW(FVar)
	if val <= 2 then
    	val = val + 1
	end
	ipc.writeUW(FVar, val)
    ENG_magneto_show ()
end

function ENG1_magneto_dec ()
	FVar = "0892"
	val = ipc.readUW(FVar)
	if val >= 1 then
    	val = val - 1
	end
 	ipc.writeUW(FVar, val)
    ENG_magneto_show ()
end

function ENG2_magneto_off ()
	FVar = "092A"
    val = 0
	ipc.writeUW(FVar, val)
    ENG_magneto_show ()
end

function ENG2_magneto_R ()
	FVar = "092A"
    val = 1
	ipc.writeSB(FVar, val)
    ENG_magneto_show ()
end

function ENG2_magneto_L ()
	FVar = "092A"
    val = 2
	ipc.writeSB(FVar, val)
    ENG_magneto_show ()
end

function ENG2_magneto_Both ()
	FVar = "092A"
    val = 3
	ipc.writeSB(FVar, val)
    ENG_magneto_show ()
end

function ENG2_magneto_inc ()
	FVar = "092A"
	val = ipc.readSB(FVar)
	if val <= 2 then
    	val = val + 1
	end
	ipc.writeSB(FVar, val)
    ENG_magneto_show ()
end

function ENG2_magneto_dec ()
	FVar = "092A"
	val = ipc.readSB(FVar)
	if val >= 1 then
    	val = val - 1
	end
	ipc.writeSB(FVar, val)
    ENG_magneto_show ()
end

function ENG3_magneto_off ()
	FVar = "09C2"
    val = 0
	ipc.writeSB(FVar, val)
    ENG_magneto_show ()
end

function ENG3_magneto_R ()
	FVar = "09C2"
    val = 1
	ipc.writeSB(FVar, val)
    ENG_magneto_show ()
end

function ENG3_magneto_L ()
	FVar = "09C2"
    val = 2
	ipc.writeSB(FVar, val)
    ENG_magneto_show ()
end

function ENG3_magneto_Both ()
	FVar = "09C2"
    val = 3
	ipc.writeSB(FVar, val)
    ENG_magneto_show ()
end

function ENG3_magneto_inc ()
	FVar = "09C2"
	val = ipc.readSB(FVar)
    if val <= 2 then
	   val = val + 1
	end
	ipc.writeSB(FVar, val)
    ENG_magneto_show ()
end

function ENG4_magneto_off ()
	FVar = "0A5A"
    val = 0
	ipc.writeSB(FVar, val)
    ENG_magneto_show ()
end

function ENG4_magneto_R ()
	FVar = "0A5A"
    val = 1
	ipc.writeSB(FVar, val)
    ENG_magneto_show ()
end

function ENG4_magneto_L ()
	FVar = "0A5A"
    val = 2
	ipc.writeSB(FVar, val)
    ENG_magneto_show ()
end

function ENG4_magneto_Both ()
	FVar = "0A5A"
    val = 3
	ipc.writeSB(FVar, val)
    ENG_magneto_show ()
end


function ENG3_magneto_dec ()
	FVar = "09C2"
	val = ipc.readSB(FVar)
	if val >= 1 then
    	val = val - 1
	end
	ipc.writeSB(FVar, val)
    ENG_magneto_show ()
end

function ENG4_magneto_inc ()
	FVar = "0A5A"
	val = ipc.readSB(FVar)
	if val <= 2 then
    	val = val + 1
	end
	ipc.writeSB(FVar, val)
    ENG_magneto_show ()
end

function ENG4_magneto_dec ()
	FVar = "0A5A"
	val = ipc.readSB(FVar)
	if val >= 1 then
    	val = val - 1
	end
	ipc.writeSB(FVar, val)
    ENG_magneto_show ()
end

-- ## Rotaries functions

function HDG_plus (a, b, c)
	if c == nil then
		_HEADING_BUG_INC ()
		return
	end
	sync_hdg = round(c / 360 * 65536)
	ipc.writeUW(0x07CC, sync_hdg)
end

function HDG_plusfast (a, b, c)
	if c == nil then
		for i = 1, fast_hdg do
			_HEADING_BUG_INC ()
		end
		return
	end
	sync_hdg = round(c / 360 * 65536)
	ipc.writeUW(0x07CC, sync_hdg)
end

function HDG_minus (a, b, c)
	if c == nil then
		_HEADING_BUG_DEC ()
		return
	end
	sync_hdg = round(c / 360 * 65536)
	ipc.writeUW(0x07CC, sync_hdg)
end

function HDG_minusfast (a, b, c)
	if c == nil then
		for i = 1, fast_hdg do
			_HEADING_BUG_DEC ()
		end
		return
	end
	sync_hdg = round(c / 360 * 65536)
	ipc.writeUW(0x07CC, sync_hdg)
end

function ALT_plus (a, b, c)
	if c == nil then
		_AP_ALT_VAR_INC ()
		return
	end
    sync_alt = c*100/3.28084*65536
	ipc.writeUD(0x07D4, sync_alt)
end

function ALT_plusfast (a, b, c)
	if c == nil then
		for i = 1, fast_alt do
			_AP_ALT_VAR_INC ()
		end
		return
	end
    sync_alt = c*100/3.28084*65536
	ipc.writeUD(0x07D4, sync_alt)
end

function ALT_minus (a, b, c)
	if c == nil then
		_AP_ALT_VAR_DEC ()
		return
	end
    sync_alt = c*100/3.28084*65536
	ipc.writeUD(0x07D4, sync_alt)
end

function ALT_minusfast (a, b, c)
	if c == nil then
		for i = 1, fast_alt do
			_AP_ALT_VAR_DEC ()
		end
		return
	end
    sync_alt = c*100/3.28084*65536
    ipc.writeUD(0x07D4, sync_alt)
end

function VVS_plus (a, b, c)
    if _MCP1() then
    	ipc.writeUW(0x07F2, ipc.readUW(0x07F2) + 100)
    	VVS_show ()
    else
        ipc.writeUW(0x07F2, c * 100)
    end
end

function VVS_minus (a, b, c)
    if _MCP1() then
        ipc.writeUW(0x07F2, ipc.readUW(0x07F2) - 100)
        VVS_show ()
    else
        ipc.writeUW(0x07F2, c * 100)
    end
end

function VVS_show ()
	local buffer = ipc.readUW(0x07F2)
	if buffer > 16384 then
		buffer = 65536 - buffer
		line2 = string.format("-%03d", buffer/10)
	else
		line2 = string.format("+%03d", buffer/10)
	end
	if buffer == 0 then line2 = "00" end
	DspShow("VS", line2)
end

function SPD_plus (a, b, c)
	if c == nil then
		_AP_SPD_VAR_INC ()
		return
	end
	ipc.writeUW(0x07E2, c)
    sync_spd = c
end

function SPD_plusfast (a, b, c)
	if c == nil then
		for i = 1, fast_spd do
			_AP_SPD_VAR_INC ()
		end
		return
	end
	ipc.writeUW(0x07E2, c)
    sync_spd = c
end

function SPD_minus (a, b, c)
	if c == nil then
		_AP_SPD_VAR_DEC ()
		return
	end
	ipc.writeUW(0x07E2, c)
    sync_spd = c
end

function SPD_minusfast (a, b, c)
	if c == nil then
		for i = 1, fast_spd do
			_AP_SPD_VAR_DEC ()
		end
		return
	end
	ipc.writeUW(0x07E2, c)
    sync_spd = c
end

function SPD_show ()
    Dsp0("\\\\\\S")
    Dsp1("PD\\\\")
    SPD = ipc.readUW(0x07E2)
	DspSPD(SPD)
	ipc.sleep(40)
end

function CRS_plus ()
	crs_hdg = crs_hdg + 1
	if crs_hdg > 359 then crs_hdg = 0 end
	CRS_show ()
end

function CRS_plusfast ()
	crs_hdg = crs_hdg + fast_crs
	if crs_hdg > 359 then crs_hdg = 360 - crs_hdg end
	CRS_show ()
end

function CRS_minus ()
	crs_hdg = crs_hdg - 1
	if crs_hdg < 0 then crs_hdg = 359 end
	CRS_show ()
end

function CRS_minusfast ()
	crs_hdg = crs_hdg - fast_crs
	if crs_hdg < 0 then crs_hdg = 360 + crs_hdg end
	CRS_show ()
end

function CRS_show ()
    if crs_open == 1 then
        -- OBS1
        ipc.writeUD(0x0C4E, crs_hdg)
        sync_crs = crs_hdg
    elseif crs_open == 2 then
        -- OBS2
        ipc.writeUD(0x0C5E, crs_hdg)
        sync_crs2 = crs_hdg
    elseif crs_open == 3 then
        -- ADF1
        ipc.writeUD(0x0C6C, crs_hdg)
        sync_adf = crs_hdg
    end
	if ipc.get("APlock") ~= 1 then
        if SPD_CRS_replace then
            DspCRS(crs_hdg, crs_open)
        else
            DspShow("CRS", DspNum(crs_hdg))
        end
    end
end

function CRS_display_toggle ()
    crs_open = crs_open + 1
    if crs_open > 3 then crs_open = 1 end
    -- change label
    DspSPD2CRS ()
end

-- ## Pushback ##

function ReleaseBrake_warning ()
    for p = 1,3,1 do
        if _MCP1() then
            DspShow("Brke", "rel!")
        elseif _MCP2() then
            DspMed1("Release")
            DspMed2("Brake!")
        end
        ipc.sleep(500)
        if _MCP1() then
            DspShow("    ", "    ")
        elseif _MCP2() then
            DspMed1("        ")
            DspMed2("        ")
        end
        ipc.sleep(500)
    end
end

function Pushback_back ()
    PBStat = ipc.readUW("0BC8")
    if PBStat < 30000 then
    ipc.writeSB("31f4", 0)
        if _MCP1() then
        DspShow("Push", "back")
        elseif _MCP2() then
        DspMed1("Pushback")
        DspMed2("back")
        end
    elseif PBStat > 30000 then
        ReleaseBrake_warning ()
    end
end

function Pushback_left ()
    PBStat = ipc.readUW("0BC8")
    if PBStat < 30000 then
    ipc.writeSB("31f4", 2)
        if _MCP1() then
            DspShow("Push", "left")
        elseif _MCP2() then
            DspMed1("Pushback")
            DspMed2("left")
        end
    elseif PBStat > 30000 then
        ReleaseBrake_warning ()
    end
end

function Pushback_right ()
    PBStat = ipc.readUW("0BC8")
    if PBStat < 30000 then
        ipc.writeSB("31f4", 1)
        if _MCP1() then
            DspShow("Push", "rght")
        elseif _MCP2() then
            DspMed1("Pushback")
            DspMed2("right")
        end
    elseif PBStat > 30000 then
        ReleaseBrake_warning ()
    end
end

function Pushback_stop ()
    ipc.writeSB("31f4", 3)
    if _MCP1() then
        DspShow("Push", "stop")
    elseif _MCP2() then
        DspMed1("Pushback")
        DspMed2("stop")
    end
end

-- ## Trimmings ###############

function Elevator_Trim_show ()
    ElevVal = ipc.readUW(0x0BC2)
    if ElevVal >= 49000 then
        ElevVal = (ElevVal - 65487)
    end
    ElevTrimVar = string.format("%.1f",
        round2(ElevVal*0.00091552734375,1))
    DspShow("Elev", ElevTrimVar)
end

function Elevator_Trim_up ()
    ipc.control(65615)
    Elevator_Trim_show ()
end

function Elevator_Trim_dn ()
    ipc.control(65607)
    Elevator_Trim_show ()
end

function Elevator_Trim_upfast ()
    i = 0
    while i <= 4 do
        ipc.control(65615)
        i = i + 1
    end
    Elevator_Trim_show ()
end

function Elevator_Trim_dnfast ()
    i = 0
    while i <= 4 do
        ipc.control(65607)
        i = i + 1
    end
    Elevator_Trim_show ()
end

function Elevator_Trim_takeoff ()
    ipc.writeSB("0BC0", 5)
    ipc.sleep(50)
    Elevator_Trim_show ()
end

function Elevator_Trim_reset ()
    ipc.writeSB("0BC0", 0)
    ipc.sleep(50)
    Elevator_Trim_show ()
end

function Aileron_Trim_show ()
    AilVal = ipc.readUW(0x0C02)
    if AilVal >= 49000 then
        AilVal = (AilVal - 65487)
    end
    AilTrimVar = round(AilVal*0.006103515625)
    DspShow("Ail", AilTrimVar)
end

function Aileron_Trim_left ()
    ipc.control(66276)
    Aileron_Trim_show ()
end

function Aileron_Trim_right ()
    ipc.control(66277)
    Aileron_Trim_show ()
end

function Aileron_Trim_reset ()
    ipc.writeSB("0C02", 0)
    ipc.sleep(50)
    Aileron_Trim_show ()
end

function Rudder_Trim_show ()
    RuddVal = ipc.readUW(0x0C04)
    if RuddVal >= 49000 then
    RuddVal = (RuddVal - 65487)
    end
    RuddTrimVar = math.ceil(RuddVal*0.006103515625)
    DspShow("Rudd", RuddTrimVar)
end

function Rudder_Trim_left ()
    ipc.control(66278)
    Rudder_Trim_show ()
end

function Rudder_Trim_right ()
    ipc.control(66279)
    Rudder_Trim_show ()
end

function Rudder_Trim_reset ()
    ipc.writeSB("0C04", 0)
    ipc.sleep(50)
    Rudder_Trim_show ()
end

-- ## Reverser ###############

function ALL_Reversers_inc ()
      ipc.control(66634)
      DspShow("Rev", "on")
end

function ALL_Reversers_incfast ()
      ipc.control(65602)
      DspShow("Rev", "on")
end

function ALL_Reversers_off ()
    TH1 = ipc.readUW("088c")
    TH2 = ipc.readUW("0924")
    TH3 = ipc.readUW("09bc")
    TH4 = ipc.readUW("0a54")
    while TH1 > 16500 or TH2 > 16500 or TH3 > 16500 or TH4 > 16500 do
        ipc.control(65964)  --- throttle 1 inc
        ipc.control(65969)  --- throttle 2 inc
        ipc.control(65974)  --- throttle 3 inc
        ipc.control(65979)  --- throttle 4 inc
        ipc.sleep(50)
        TH1 = ipc.readUW("088c")
        TH2 = ipc.readUW("0924")
        TH3 = ipc.readUW("09bc")
        TH4 = ipc.readUW("0a54")
        DspShow("Rev", "off")
    end
    ipc.control(65967) --- throttle cut
    ipc.control(65972) --- throttle cut
    ipc.control(65977)  --- throttle cut
    ipc.control(65982)  --- throttle cut
end

-- ## Reverser as Axis forward ###############

function Reverser_Eng1 ()
    RevVar1 = ipc.readUW("3330")
    RevVal1 = math.floor(RevVar1/4)
    ipc.display("RevVar " .. RevVar1 .. "\n RevVal" .. -RevVal1 )
    ipc.writeUW("310A", 8)
    ipc.writeUW("088C", -RevVal1)
    DspShow ("Rev", RevVal1 * 0.024)
end

function Reverser_Eng2 ()
    RevVar2 = ipc.readUW("3332")
    RevVal2 = math.floor(RevVar2/4)
    ipc.display("RevVar " .. RevVar2 .. "\n RevVal" .. -RevVal2 )
    ipc.writeUW("310A", 8)
    ipc.writeUW("0924", -RevVal2)
    DspShow ("Rev", RevVal2 * 0.024)
end

function Reverser_Eng3 ()
    RevVar3 = ipc.readUW("3334")
    RevVal3 = math.floor(RevVar3/4)
    ipc.display("RevVar " .. RevVar3 .. "\n RevVal" .. -RevVal3 )
    ipc.writeUW("310A", 8)
    ipc.writeUW("09BC", -RevVal3)
    DspShow ("Rev", RevVal3 * 0.024)
end

function Reverser_Eng4 ()
    RevVar4 = ipc.readUW("3336")
    RevVal4 = math.floor(RevVar4/4)
    ipc.display("RevVar " .. RevVar4 .. "\n RevVal" .. -RevVal4 )
    ipc.writeUW("310A", 8)
    ipc.writeUW("0A54", -RevVal4)
    DspShow ("Rev", RevVal4 * 0.024)
end

function Reverser_AllEng ()
    RevVar1 = ipc.readUW("3330")
    RevVar2 = ipc.readUW("3332")
    RevVar3 = ipc.readUW("3334")
    RevVar4 = ipc.readUW("3336")
    RevVal1 = math.floor(RevVar1/4)
    RevVal2 = math.floor(RevVar2/4)
    RevVal3 = math.floor(RevVar3/4)
    RevVal4 = math.floor(RevVar4/4)
    -- ipc.display("RevVar " .. RevVar1 .. "\n RevVal" .. -RevVal1 )
    ipc.writeUW("310A", 8)
    ipc.writeUW("088C", -RevVal1)
    ipc.writeUW("0924", -RevVal1)
    ipc.writeUW("09BC", -RevVal1)
    ipc.writeUW("0A54", -RevVal1)
    DspShow ("Rev", math.floor(RevVal1 * 0.024) .."%")
end

function Reverser_End ()
    ipc.clearbitsUW("310A", 8)
end

-- ## Doors ###############

function DOOR_1_toggle ()
    ipc.control(66389)
    ipc.control(65538)
    DspShow ("Exit", "1")
end

function DOOR_2_toggle ()
    ipc.control(66389)
    ipc.control(65539)
    DspShow ("Exit", "2")
end

function DOOR_3_toggle ()
    ipc.control(66389)
    ipc.control(65540)
    DspShow ("Exit", "3")
end

function DOOR_4_toggle ()
    ipc.control(66389)
    ipc.control(65541)
    DspShow ("Exit", "4")
end

function Open_Door_When_Onground()
    -- open door when loading
    ipc.sleep(1000)
    OnGround = ipc.readUW("0366") -- plane on ground?
    Eng1Run = ipc.readUW("0894") -- Engine 1 running?
    Eng2Run = ipc.readUW("092C") -- Engine 2 running?
    Eng3Run = ipc.readUW("09C4") -- Engine 3 running?
    Eng4Run = ipc.readUW("0A5C") -- Engine 4 running?
    EngSumVar = Eng1Run + Eng2Run + Eng3Run +Eng4Run
    -- if on ground and engines off, open door
    if OnGround == 1 and EngSumVar == 0 then
        ipc.writeUW("3367", 1)
    end
end

function Close_Door()
    ipc.writeUW("3367", 0)
end

-- ## Save Flights ####################

function Save_Current_Flight()
    SaveFlight()
end

--function Save_Default_Flight()
--    SaveFlight("", 1)
--end

-- ## Other ###########################

function Set_UTC ()
    simHour = ipc.readUB("023B")
    simMinute = ipc.readUB("023c")
    Hour = os.date("!%H")
    Minute = os.date("!%M")
    questvar = ipc.ask("Setting current sim time (".. simHour..":"..simMinute..") to UTC (".. Hour..":"..Minute..")? [y / n]")
    if questvar == "y" then
        Hour = os.date("!%H")
        Minute = os.date("!%M")
        ipc.writeUB("023B", Hour)
        ipc.writeUB("023c", Minute)
    end
end

-- ## System functions ##

-- Initial info on MCP display
function InitDsp ()
    SPD = ipc.readUW(0x07E2)
	DspSPD(SPD)
	ipc.sleep(40)
    HDG = round(ipc.readUW(0x07CC)*360/65536)
	DspHDG(HDG)
	ipc.sleep(40) -- << waiting for FSX data update
    ALT = round(ipc.readUD(0x07D4)/65536*3.28084/100)
	DspALT(ALT)
	DspClear()
end

-- Initial variables
function FallbackInitVars ()
	-- Tuning fast rotation speeds
	fast_alt = 10 -- << increment value when rotary in fast mode
	fast_hdg = 10
	fast_crs = 5
	fast_ias = 10
	fast_baro = 10
    fast_spd = 10
	-- init CRS direction
    crs_hdg = ipc.readUW(0x0C4E)
    if _MCP1 () then
        -- don't need this on MCP2
	    ipc.writeUW(0x0C4E, 0)
    end
	-- Setting initial varibles values
	prev_mask = 0
	prev_num = 0
	tcas_mode = 0
	--ipc.writeUW("0D0C", 0)
    AUTO_SAVE_ENABLED = true
end

-- clears ALL OnRepeat queues
function ClearRepeatingButtons()
    _logg('[FlBk] Clear Repeating Buttons...')
    buttonRepeatClear()
end

_log("[LIB]  FSX standard library loaded...")
