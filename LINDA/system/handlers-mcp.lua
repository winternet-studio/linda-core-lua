-- HANDLER FOR MCP1 (Original) PANELS
-- Updated for LINDA 4.1.3
-- Feb 2022

-- ****************************************************************
--
--      DO NOT EDIT OR CHANGE THE CONTENTS OF THIS FILE
--
--      CORE LINDA FUNCTIONALITY
--
--      PLACE USER FUNCTIONS IN USER.LUA (\linda\[aircraft]\)
--
-- ****************************************************************

-- reading VRI events
-- function MCPcontrols (h, s)
-- function MCPcontrols (handle, datastring, length)
function MCPcontrols (h, s)
    -- _logg(s)
--	if length < 8 then return end
--	local s = string.format('%s', datastring)
--	if s == '' then return end
	-- skip this command
	skip = false
	-- Getting first two chars of VRI-commad to group them into functions
	group = string.sub(s, 1, 3)
	-- Getting 4th and all next chars - it's an exact command in group
	command = string.sub(s, 4)
	-- Debug
	-- _logg("Handle :: [" .. group .. "] / [" .. command .. "] " .. tostring(length))
	-- Detecting knob-press commands
	if command == "SEL+" or command == "SEL-" then
		-- pause flight info updates
		ipc.set("FIP", ipc.elapsedtime() + 500)
		-- knob_press = true
		switch (group, KNOBPRESS, "_knob_press", group)
		return
	end
	-- Detecting if it is a knob-rotation
	fc = string.sub(command, 1, 1)
	if fc == "+" or fc == "-" or tonumber(fc) then
		-----------------------
		-- KNOB ROTATION detected !!!
		-----------------------
		-- pause flight info updates
		ipc.set("FIP", ipc.elapsedtime() + 500)
		if ipc.get("DSPmode") == 2 then
			if ipc.get("APlock") == 1 then
				if (group == "SPD" or
					group == "HDG" or
					group == "ALT" or
					group == "OBS" or
					group == "VVS" ) and mcp_tmp ~= 1 then
					DspALT(1)
					DspHDG(1)
					DspSPD(1)
					mcp_tmp = 1
					DspShow("DSP!", "LOCK", false)
				end
			end
			-- working with AP rotaries while in FLIGHT INFO MODE
			if (group == "ALT" or group == "SPD" or group == "HDG") and mcp_tmp ~= 1 then
				Dsp0("*ap*")
				InitDsp()
				Dsp0("*ap*")
				mcp_tmp = 1
				skip = true
			end
		end
		if not skip then switch (group, KNOBROTATE, "_knob_rotate", command) end
		return
	end
	-- Parsing MCP knob buttons (those under rotaries, which have the same
	-- as rotary command group HDG / SPD / ALT / VVS
	if switch(group, KNOBBUTTONS, "_knob_buttons", command) then
		-- Success! It was one of them. Finishing.
		return
	end
	-- Now checking and parsing any other groups left
	if switch(group, OTHER, "_other_controls", command) then
		-- Success! Found something. Exiting happy.
		return
	end
	-- Everything else. Never should happen.
	-- _err ("Error: Command group not assigned! " .. group .. " / " .. command )
end

function VRI_TIMER ()
	-- Updating DME data if DME is open on radio panel
	if dme_open == 1 then
		Default_DME_1_init ()
	elseif dme_open == 2 then
		Default_DME_2_init ()
	end
	-- Updating COM data if COM is open on radio panel
	if com_open == 1 then
		Default_COM_1_init ()
	elseif com_open == 2 then
		Default_COM_2_init ()
	end
	-- Updating NAV data if NAV is open on radio panel
	if nav_open == 1 then
		Default_NAV_1_init ()
	elseif nav_open == 2 then
		Default_NAV_2_init ()
	end
	-- Updating current flight info
	if ipc.get("DSPmode") == 2 then
		-- only if no rotaries where move in last second
		if ipc.elapsedtime() - ipc.get("FIP") > 1000 then
			DisplayFlightInfo ()
		end
	else
		-- only if no rotaries where move in last second
		if ipc.elapsedtime() - ipc.get("FIP") > 1000 then
            local info = "M" .. tostring(ipc.get("EFISmode")) ..
                tostring(ipc.get("MCPmode")) ..
                tostring(ipc.get("USERmode"))
            if info == "M111" then
                if FLIGHT_INFO1 ~= '' then
                    Dsp0 (FLIGHT_INFO1)
                else
                    Dsp0 ('    ')
                end
            else
                Dsp0(info)
            end
            if FLIGHT_INFO2 ~= '' then
                if info == "M111" then
                    Dsp1 (FLIGHT_INFO2)
                end
            else
        		if ipc.readUD(0x07BC) ~= AP_STATE then
                    AP_STATE = ipc.readUD(0x07BC)
                    if AP_STATE == 1 then
                        Dsp1("*AP*")
                    else
		          	    Dsp1("-ap-")
                    end
                end
            end
		end
	end

    VRI_DELAY = ipc.get("VRI_DELAY")

	-- clear dsp feature (dsp_count is the ipc.elapsedtime() from the moment of last DSP update)
	if dsp_count > 0 then
		if ipc.elapsedtime() - dsp_count > 1000 then
			DspShow(dsp0_prev, dsp1_prev)
			dsp_count = 0
		end
	end
	-- Return EFIS to mode 1
	if ipc.get("EFISmode") > 1 and ipc.get("EFISrestore") == 1 then
		-- only if no input in that mode
		if ipc.elapsedtime() - ipc.get("EFISalt") > VRI_DELAY then
            EFIS_MODE_one ()
            _log('[MCP1] EFIS Mode 1')
		end
	end
	-- Return MCP to mode 1
	if ipc.get("MCPmode") > 1 and ipc.get("MCPrestore") == 1 then
		-- only if no input in that mode
		if ipc.elapsedtime() - ipc.get("MCPalt") > VRI_DELAY then
            MCP_MODE_one ()
            _log('[MCP1] MCP Mode 1')
		end
	end
	-- Return USER to mode 1
	if ipc.get("USERmode") > 1 and ipc.get("USERrestore") == 1 then
		-- only if no input in that mode
		if ipc.elapsedtime() - ipc.get("USERalt") > VRI_DELAY then
            USER_MODE_one ()
            _log('[MCP1] USER Mode 1')
		end
	end
end

-- ## RADIO CONTROLS ########
function RADIO_DME (skip, skip, s)
	_loggg("[MCP1] DME :: " .. s)
	if s == "SEL1" then
		Default_DME_1_init ()
		switch ("DME1 Select", RADIOS, "RADIOS")
	elseif s == "SEL2" then
		Default_DME_2_init ()
		switch ("DME2 Select", RADIOS, "RADIOS")
	elseif s == "AUX" then
		switch ("DMEs Mode", RADIOS, "RADIOS")
	end
end

function RADIO_DME_rotate (skip, skip, s)
	_loggg("[MCP1] DME rotate :: " .. s)
	Default_DME_set (s)
end

function RADIO_ADF (skip, skip, s)
	_loggg("[MCP1] ADF :: " .. s)
	if s == "SEL1" then
		Default_ADF_1_init ()
		switch ("ADF1 Select", RADIOS, "RADIOS")
	elseif s == "SEL2" then
		Default_ADF_2_init ()
		switch ("ADF2 Select", RADIOS, "RADIOS")
	elseif s == "AUX" then
		switch ("ADFs Mode", RADIOS, "RADIOS")
	end
end

function RADIO_ADF_rotate (skip, skip, s)
	_loggg("[MCP1] ADF :: " .. s)
	Default_ADF_set (s)
end

function RADIO_NAV (skip, skip, s)
	_loggg("[MCP1] NAV :: " .. s)
	if s == "SEL1" then
		Default_NAV_1_init ()
		switch ("NAV1 Select", RADIOS, "RADIOS")
		return
	elseif s == "SEL2" then
		Default_NAV_2_init ()
		switch ("NAV2 Select", RADIOS, "RADIOS")
		return
	elseif s == "AUX" then
		switch ("NAVs Mode", RADIOS, "RADIOS")
		return
	end
	t = string.sub(s, 1, 1)
	if t == "s" then
		Default_NAV_1_set (string.sub(s, 2))
	elseif t == "S" then
		Default_NAV_2_set (string.sub(s, 2))
	elseif t == "x" then
		Default_NAV_1_swap ()
		switch ("NAV1 Swap", RADIOS, "RADIOS")
	elseif t == "X" then
		Default_NAV_2_swap ()
		switch ("NAV2 Swap", RADIOS, "RADIOS")
	end
end

function RADIO_COM (skip, skip, s)
	_loggg("[MCP1] COM :: " .. s)
	if s == "SEL1" then
		Default_COM_1_init ()
		switch ("COM1 Select", RADIOS, "RADIOS")
		return
	elseif s == "SEL2" then
		Default_COM_2_init ()
		switch ("COM2 Select", RADIOS, "RADIOS")
		return
	elseif s == "AUX" then
		switch ("COMs Mode", RADIOS, "RADIOS")
		return
	end
	t = string.sub(s, 1, 1)
	if t == "s" then
		Default_COM_1_set (string.sub(s, 2))
	elseif t == "S" then
		Default_COM_2_set (string.sub(s, 2))
	elseif t == "x" then
		Default_COM_1_swap ()
		switch ("COM1 Swap", RADIOS, "RADIOS")
	elseif t == "X" then
		Default_COM_2_swap ()
		switch ("COM2 Swap", RADIOS, "RADIOS")
	end
end

function RADIO_TRN (skip, skip, s)
	_loggg("[MCP1] TRN :: " .. s)
	if string.sub(s, 1, 1) == "X" then
		Default_XPND_set (string.sub(s, 2))
		switch ("XPND Swap", RADIOS, "RADIOS")
	elseif s == "SEL" then
		Default_XPND_init ()
		switch ("XPND Select", RADIOS, "RADIOS")
	elseif s == "AUX" then
		switch ("XPND Mode", RADIOS, "RADIOS")
	end
end

-- ############################################################## --
-- ############################################################## --

-- ## EFIS KNOBS ################

function EFIS_MINS_press ()
	if ipc.get("EFISmode") == 1 then
		switch ("PRESS", MINS1, "MINS")
	elseif ipc.get("EFISmode") == 2 then
		switch ("PRESS", MINS2, "MINS")
        ipc.set("EFISalt", ipc.elapsedtime())
	else
		switch ("PRESS", MINS3, "MINS")
        ipc.set("EFISalt", ipc.elapsedtime())
	end
end

function EFIS_MINS_rotate (skip, skip, command)
	if ipc.get("EFISmode") == 1 then
		switch (MINSmode .. " " .. command, MINS1, "MINS", command)
	elseif ipc.get("EFISmode") == 2 then
		switch (MINSmode .. " " .. command, MINS2, "MINS", command)
        ipc.set("EFISalt", ipc.elapsedtime())
	else
		switch (MINSmode .. " " .. command, MINS3, "MINS", command)
        ipc.set("EFISalt", ipc.elapsedtime())
	end
end

function EFIS_BARO_press ()
	if ipc.get("EFISmode") == 1 then
		switch ("PRESS", BARO1, "BARO")
	elseif ipc.get("EFISmode") == 2 then
		switch ("PRESS", BARO2, "BARO")
        ipc.set("EFISalt", ipc.elapsedtime())
	else
		switch ("PRESS", BARO3, "BARO")
        ipc.set("EFISalt", ipc.elapsedtime())
	end
end

function EFIS_BARO_rotate (skip, skip, command)
	if ipc.get("EFISmode") == 1 then
		switch (BAROmode .. " " .. command, BARO1, "BARO", command)
	elseif ipc.get("EFISmode") == 2 then
		switch (BAROmode .. " " .. command, BARO2, "BARO", command)
        ipc.set("EFISalt", ipc.elapsedtime())
	else
		switch (BAROmode .. " " .. command, BARO3, "BARO", command)
        ipc.set("EFISalt", ipc.elapsedtime())
	end
end

function EFIS_CTR_press ()
	if ipc.get("EFISmode") == 1 then
		switch ("PRESS", CTR1, "CTR")
	elseif ipc.get("EFISmode") == 2 then
		switch ("PRESS", CTR2, "CTR")
        ipc.set("EFISalt", ipc.elapsedtime())
	else
		switch ("PRESS", CTR3, "CTR")
        ipc.set("EFISalt", ipc.elapsedtime())
	end
end

function EFIS_CTR_rotate (skip, skip, command)
	if ipc.get("EFISmode") == 1 then
		switch (CTRmode .. " " .. command, CTR1, "CTR", command)
	elseif ipc.get("EFISmode") == 2 then
		switch (CTRmode .. " " .. command, CTR2, "CTR", command)
        ipc.set("EFISalt", ipc.elapsedtime())
	else
		switch (CTRmode .. " " .. command, CTR3, "CTR", command)
        ipc.set("EFISalt", ipc.elapsedtime())
	end
end

function EFIS_TFC_press ()
	if ipc.get("EFISmode") == 1 then
		switch ("PRESS", TFC1, "TFC")
	elseif ipc.get("EFISmode") == 2 then
		switch ("PRESS", TFC2, "TFC")
        ipc.set("EFISalt", ipc.elapsedtime())
	else
		switch ("PRESS", TFC3, "TFC")
        ipc.set("EFISalt", ipc.elapsedtime())
	end
end

function EFIS_TFC_rotate (skip, skip, command)
	if ipc.get("EFISmode") == 1 then
		switch (TFCmode .. " " .. command, TFC1, "TFC", command)
	elseif ipc.get("EFISmode") == 2 then
		switch (TFCmode .. " " .. command, TFC2, "TFC", command)
        ipc.set("EFISalt", ipc.elapsedtime())
	else
		switch (TFCmode .. " " .. command, TFC3, "TFC", command)
        ipc.set("EFISalt", ipc.elapsedtime())
	end
end

-- ## MCP KNOBS ################

function MCP_HDG_press ()
	switch ("PRESS", HDG1, "HDG")
end

function MCP_HDG_rotate (skip, skip, command)
	value = string.sub(command, 1, 3)
	command = string.sub(command, 4)
	switch (HDGmode .. " " .. command, HDG1, "HDG", value)
end

function MCP_HDG_buttons (skip, skip, command)
	if ipc.get("MCPmode") == 1 then
		if command == "HDG+" or command == "HDG-" then
			switch ("HDGSEL", MCP1, "MCP")
		elseif command == "HLD+" or command == "HLD-" then
			switch ("HDGHLD", MCP1, "MCP")
		end
	elseif ipc.get("MCPmode") == 2 then
		if command == "HDG+" or command == "HDG-" then
			switch ("HDGSEL", MCP2, "MCP")
		elseif command == "HLD+" or command == "HLD-" then
			switch ("HDGHLD", MCP2, "MCP")
		end
        ipc.set("MCPalt", ipc.elapsedtime())
	else
		if command == "HDG+" or command == "HDG-" then
			switch ("HDGSEL", MCP3, "MCP")
		elseif command == "HLD+" or command == "HLD-" then
			switch ("HDGHLD", MCP3, "MCP")
		end
        ipc.set("MCPalt", ipc.elapsedtime())
	end
end

function MCP_ALT_press ()
	switch ("PRESS", ALT1, "ALT")
end

function MCP_ALT_rotate (skip, skip, command)
	value = string.sub(command, 1, 3)
	command = string.sub(command, 4)
	switch (ALTmode .. " " .. command, ALT1, "ALT", value)
end

function MCP_ALT_buttons (skip, skip, command)
	if ipc.get("MCPmode") == 1 then
		switch ("ALTHLD", MCP1, "MCP")
	elseif ipc.get("MCPmode") == 2 then
		switch ("ALTHLD", MCP2, "MCP")
        ipc.set("MCPalt", ipc.elapsedtime())
	else
		switch ("ALTHLD", MCP3, "MCP")
        ipc.set("MCPalt", ipc.elapsedtime())
	end
end

function MCP_SPD_press ()
	switch ("PRESS", SPD1, "SPD")
end

function MCP_SPD_rotate (skip, skip, command)
	value = string.sub(command, 1, 3)
	command = string.sub(command, 4)
	switch (SPDmode .. " " .. command, SPD1, "SPD", value)
end

function MCP_SPD_buttons (skip, skip, command)
	if ipc.get("MCPmode") == 1 then
		if command == "N1+" or command == "N1-" then
			switch ("N1", MCP1, "MCP")
		elseif command == "SPD+" or command == "SPD-" then
			switch ("SPD", MCP1, "MCP")
		elseif command == "LVL+" or command == "LVL-" then
			switch ("FLCH", MCP1, "MCP")
		end
	elseif ipc.get("MCPmode") == 2 then
		if command == "N1+" or command == "N1-" then
			switch ("N1", MCP2, "MCP")
		elseif command == "SPD+" or command == "SPD-" then
			switch ("SPD", MCP2, "MCP")
		elseif command == "LVL+" or command == "LVL-" then
			switch ("FLCH", MCP2, "MCP")
		end
        ipc.set("MCPalt", ipc.elapsedtime())
	else
		if command == "N1+" or command == "N1-" then
			switch ("N1", MCP3, "MCP")
		elseif command == "SPD+" or command == "SPD-" then
			switch ("SPD", MCP3, "MCP")
		elseif command == "LVL+" or command == "LVL-" then
			switch ("FLCH", MCP3, "MCP")
		end
        ipc.set("MCPalt", ipc.elapsedtime())
	end
end

function MCP_VVS_press ()
	switch ("PRESS", VVS1, "VVS")
end

function MCP_VVS_rotate (skip, skip, command)
	switch (VVSmode .. " " .. command, VVS1, "VVS", command)
end

function MCP_VVS_buttons (skip, skip, command)
	if ipc.get("MCPmode") == 1 then
		switch ("V/S FPA", MCP1, "MCP")
	elseif ipc.get("MCPmode") == 2 then
		switch ("V/S FPA", MCP2, "MCP")
        ipc.set("MCPalt", ipc.elapsedtime())
	else
		switch ("V/S FPA", MCP3, "MCP")
        ipc.set("MCPalt", ipc.elapsedtime())
	end
end

function MCP_CRS_press ()
	switch ("PRESS", CRS1, "CRS")
end

function MCP_CRS_rotate (skip, skip, command)
	switch (CRSmode .. " " .. command, CRS1, "CRS", command)
end

function MCP_CRS_buttons (skip, skip, command)
	-- empty by purpose
	-- do not delete
end

-- ############################################################## --

-- ## BUTTONS ################

function MCP_buttons (skip, skip, s)
	if ipc.get("MCPmode") == 1 then
		-- Switches
		if s == "AT+" then
			switch ("A/T UP", MCP1, "MCP")
			return
		elseif s == "AT-" then
			switch ("A/T DN", MCP1, "MCP")
			return
		elseif s == "FD+" then
			switch ("F/D UP", MCP1, "MCP")
			return
		elseif s == "FD-" then
			switch ("F/D DN", MCP1, "MCP")
			return
		elseif s == "MAST+" then
			switch ("MASTER UP", MCP1, "MCP")
			return
		elseif s == "MAST-" then
			switch ("MASTER DN", MCP1, "MCP")
			return
		end
		s = string.sub(s, 1, string.len(s)-1)
		switch (s, MCP1, "MCP")
	elseif ipc.get("MCPmode") == 2 then
		-- Switches
		if s == "AT+" then
			switch ("A/T UP", MCP2, "MCP")
			return
		elseif s == "AT-" then
			switch ("A/T DN", MCP2, "MCP")
			return
		elseif s == "FD+" then
			switch ("F/D UP", MCP2, "MCP")
			return
		elseif s == "FD-" then
			switch ("F/D DN", MCP2, "MCP")
			return
		elseif s == "MAST+" then
			switch ("MASTER UP", MCP2, "MCP")
			return
		elseif s == "MAST-" then
			switch ("MASTER DN", MCP2, "MCP")
			return
		end
		s = string.sub(s, 1, string.len(s)-1)
		switch (s, MCP2, "MCP")
        ipc.set("MCPalt", ipc.elapsedtime())
	else
		-- Switches
		if s == "AT+" then
			switch ("A/T UP", MCP3, "MCP")
			return
		elseif s == "AT-" then
			switch ("A/T DN", MCP3, "MCP")
			return
		elseif s == "FD+" then
			switch ("F/D UP", MCP3, "MCP")
			return
		elseif s == "FD-" then
			switch ("F/D DN", MCP3, "MCP")
			return
		elseif s == "MAST+" then
			switch ("MASTER UP", MCP3, "MCP")
			return
		elseif s == "MAST-" then
			switch ("MASTER DN", MCP3, "MCP")
			return
		end
		s = string.sub(s, 1, string.len(s)-1)
		switch (s, MCP3, "MCP")
        ipc.set("MCPalt", ipc.elapsedtime())
	end
end

function EFIS_buttons (skip, skip, s)
	if ipc.get("EFISmode") == 1 then
		switch (s, EFIS1, "EFIS")
	elseif ipc.get("EFISmode") == 2 then
		switch (s, EFIS2, "EFIS")
        ipc.set("EFISalt", ipc.elapsedtime())
	else
		switch (s, EFIS3, "EFIS")
        ipc.set("EFISalt", ipc.elapsedtime())
	end
end

function USER_buttons (skip, skip, s)
	s = string.sub(s, 3, 3)
	local um = ipc.get("USERmode")
	if um == 1 then
		switch (s, USER1, "USER")
	elseif um == 2 then
		switch (s, USER2, "USER")
        ipc.set("USERalt", ipc.elapsedtime())
	else
		switch (s, USER3, "USER")
        ipc.set("USERalt", ipc.elapsedtime())
	end
end

-- ## Tables init ############################################################ --

OTHER = {
["APL"] = MCP_buttons ,
["EFI"] = EFIS_buttons ,
["CTL"] = USER_buttons ,
["COM"] = RADIO_COM ,
["NAV"] = RADIO_NAV ,
["TRN"] = RADIO_TRN ,
["DME"] = RADIO_DME ,
["ADF"] = RADIO_ADF ,
}

KNOBBUTTONS = {
["HDG"] = MCP_HDG_buttons ,
["ALT"] = MCP_ALT_buttons ,
["SPD"] = MCP_SPD_buttons ,
["VVS"] = MCP_VVS_buttons ,
}

KNOBPRESS = {
["HDG"] = MCP_HDG_press ,
["ALT"] = MCP_ALT_press ,
["SPD"] = MCP_SPD_press ,
["VVS"] = MCP_VVS_press ,
["OBS"] = MCP_CRS_press ,
["MIN"] = EFIS_MINS_press ,
["BAR"] = EFIS_BARO_press ,
["NDM"] = EFIS_CTR_press ,
["NDR"] = EFIS_TFC_press
}

KNOBROTATE = {
["HDG"] = MCP_HDG_rotate ,
["ALT"] = MCP_ALT_rotate ,
["SPD"] = MCP_SPD_rotate ,
["VVS"] = MCP_VVS_rotate ,
["OBS"] = MCP_CRS_rotate ,
["MIN"] = EFIS_MINS_rotate ,
["BAR"] = EFIS_BARO_rotate ,
["NDM"] = EFIS_CTR_rotate ,
["NDR"] = EFIS_TFC_rotate ,
["ADF"] = RADIO_ADF_rotate ,
["CRS"] = RADIO_DME_rotate ,
}
