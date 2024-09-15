-- HANDLER FOR MCP2 (BOEING) PANELS
-- Updated for LINDA 4.1.3
-- Feb 2022

-- **************************************************************
--
--      DO NOT EDIT OR CHANGE THE CONTENTS OF THIS FILE
--
--      CORE LINDA FUNCTIONALITY
--
--      PLACE USER FUNCTIONS IN USER.LUA (\linda\[aircraft]\)
--
-- **************************************************************

-- ## MAIN ###############

-----------------------------------------------------------------
-- Handle all MCP controls (knobs, buttons and switches)
-- called from event set up in InitEvents (in events.lua)
function MCPcontrols (h, s)
	-- skip this command
	skip = false
	-- Getting first two chars of VRI-commad to group them into functions
	group = string.sub(s, 1, 3)
	-- Getting 4th and all next chars - it's an exact command in group
	command = string.sub(s, 4)
    -- move LAMP to USER group
    if command == 'LAMP.' then
        group = 'USR'
    end

	-- Debug
	_logggg("[MCP2] Handle :: [" .. group .. "] / [" .. command .. "] " .. tostring(length))

    -- Detecting knob-press commands
	if string.sub(command, 5) == "*" then
		-- pause flight info updates
		ipc.set("FIP", ipc.elapsedtime())
        group = string.sub(command, 1, 3)
		-- knob_press = true
		switch (group, KNOBPRESS, "_knob_press", group)
		return
	end
	-- Detecting if it is a knob-rotation
	fc = string.sub(command, 5)
	if fc == "+" or fc == "-" then
		-----------------------
		-- KNOB ROTATION detected !!!
		-----------------------
		-- pause flight info updates
		ipc.set("FIP", ipc.elapsedtime())
        group = string.sub(command, 1, 3)
        command = string.sub(command, 4)
		if not skip then switch (group, KNOBROTATE, "_knob_rotate", command) end
		return
	end
	-- Now checking and parsing any other groups left
	if switch(group, BUTTONS, "_buttons", command) then
		-- Success! Found something. Exiting happy.
		return
	end
	-- Everything else. Never should happen.
	-- _err ("Error: Command group not assigned! " .. group .. " / " .. command )
end

function VRI_TIMER ()
    -- auto revert timers
    if RADIOS_MSG and ipc.elapsedtime() - ipc.get("FIP2") > 1000 then
        if RADIOS_MSG_SHORT then
            DspRadiosShortClear ()
        else
            DspRadiosMedClear ()
        end
        RADIOS_MSG = false
        RADIOS_MSG_SHORT = false
    end
    -- clear display message fields
    if DSP_MSG1 and ipc.elapsedtime() - ipc.get("FIP") > 1000 then
        DspClearMed1 ()
        DSP_MSG1 = false
        AP_STATE = -1
    end
    if DSP_MSG2 and ipc.elapsedtime() - ipc.get("FIP") > 1000 then
        DspClearMed2 ()
        DSP_MSG2 = false
        AP_STATE = -1
    end
    if DSP_MSG and ipc.elapsedtime() - ipc.get("FIP") > 1000 then
        DspClearMed ()
        DSP_MSG = false
        AP_STATE = -1
    end
	-- Updating DME data if DME is open on radio panel
    dme_timer_skip = dme_timer_skip + 1
    if not RADIOS_MSG and dme_timer_skip > 3 then
    	if dme_open == 1 then
            Default_DME_1_init ()
	    elseif dme_open == 2 then
            Default_DME_2_init ()
    	end
        dme_timer_skip = 0
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
			DisplayAutopilotInfo ()
		end
    end

    VRI_DELAY = ipc.get("VRI_DELAY")
    --_loggg('[MCP2] VRI delay = ' .. VRI_DELAY)

	-- Return EFIS to mode 1
    if ipc.get("EFISmode") > 1 and ipc.get("EFISrestore") == 1 then
		-- only if no input in that mode
		if ipc.elapsedtime() - ipc.get("EFISalt") > VRI_DELAY then
            EFIS_MODE_one ()
		end
	end
	-- Return MCP to mode 1
	if ipc.get("MCPmode") > 1 and ipc.get("MCPrestore") == 1 then
		-- only if no input in that mode
		if ipc.elapsedtime() - ipc.get("MCPalt") > VRI_DELAY then
            MCP_MODE_one ()
		end
	end
	-- Return USER to mode 1
	if ipc.get("USERmode") > 1 and ipc.get("USERrestore") == 1 then
		-- only if no input in that mode
		if ipc.elapsedtime() - ipc.get("USERalt") > VRI_DELAY then
            USER_MODE_one ()
		end
	end   --]]
end

-- ## RADIO CONTROLS ########
function RADIOS_FRE_press ()
	switch ("PRESS", FRE1, "FRE")
end

function RADIOS_FRE_rotate (skip, skip, command)
    switch ("A " .. command, FRE1, "FRE", command)
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
    -- _loggg("[MCP2] MINS " .. command)
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
	-- _loggg("[MCP2] EFIS_BARO_rotate " .. command .. " / " .. BARO1_CFG_MODE)
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
	if ipc.get("MCPmode") == 1 then
        switch ("PRESS", HDG1, "HDG")
	elseif ipc.get("MCPmode") == 2 then
        switch ("PRESS", HDG2, "HDG")
        ipc.set("MCPalt", ipc.elapsedtime())
	else
        switch ("PRESS", HDG3, "HDG")
        ipc.set("MCPalt", ipc.elapsedtime())
	end
end

function MCP_HDG_rotate (skip, skip, command)
    -- fix for HDG error in display mode
    if HDG == nil then return end
    if command == '++' then
        HDGfast = HDGfast + 1
        if HDGfast > 2 then
            HDG = HDG + 10
        else
            command = ' +'
            HDG = HDG + 1
        end
    elseif command == '--' then
        HDGfast = HDGfast + 1
        if HDGfast > 2 then
            HDG = HDG - 10
        else
            command = ' -'
            HDG = HDG - 1
        end
    elseif command == ' +' then
        HDGfast = 0
        HDG = HDG + 1
    elseif command == ' -' then
        HDGfast = 0
        HDG = HDG - 1
    end
    if HDG > 359 then HDG = HDG - 360  end
    if HDG < 0 then HDG = 360 + HDG end
	if ipc.get("MCPmode") == 1 then
    	switch (HDGmode .. " " .. command, HDG1, "HDG", HDG)
	elseif ipc.get("MCPmode") == 2 then
    	switch (HDGmode .. " " .. command, HDG2, "HDG", HDG)
        ipc.set("MCPalt", ipc.elapsedtime())
	else
    	switch (HDGmode .. " " .. command, HDG3, "HDG", HDG)
        ipc.set("MCPalt", ipc.elapsedtime())
	end
    if AutoDisplay then DspHDG(HDG) end
end

function MCP_ALT_press ()
	if ipc.get("MCPmode") == 1 then
    	switch ("PRESS", ALT1, "ALT")
	elseif ipc.get("MCPmode") == 2 then
    	switch ("PRESS", ALT2, "ALT")
        ipc.set("MCPalt", ipc.elapsedtime())
	else
    	switch ("PRESS", ALT3, "ALT")
        ipc.set("MCPalt", ipc.elapsedtime())
	end
end

function MCP_ALT_rotate (skip, skip, command)
    if command == '++' then
        ALTfast = ALTfast + 1
        if ALTfast > 2 then
            ALT = ALT + 10
        else
            command = ' +'
            ALT = ALT + 1
        end
    elseif command == '--' then
        ALTfast = ALTfast + 1
        if ALTfast > 2 then
            ALT = ALT - 10
        else
            command = ' -'
            ALT = ALT - 1
        end
    elseif command == ' +' then
        ALTfast = 0
        ALT = ALT + 1
    elseif command == ' -' then
        ALTfast = 0
        ALT = ALT - 1
    end
    if ALT > 500 then ALT = 500 end
    if ALT < 0 then ALT = 0 end
	if ipc.get("MCPmode") == 1 then
    	switch (ALTmode .. " " .. command, ALT1, "ALT", ALT)
	elseif ipc.get("MCPmode") == 2 then
    	switch (ALTmode .. " " .. command, ALT2, "ALT", ALT)
        ipc.set("MCPalt", ipc.elapsedtime())
	else
    	switch (ALTmode .. " " .. command, ALT3, "ALT", ALT)
        ipc.set("MCPalt", ipc.elapsedtime())
	end
    if AutoDisplay then DspALT(ALT) end
end

function MCP_SPD_press ()
	if ipc.get("MCPmode") == 1 then
    	switch ("PRESS", SPD1, "SPD")
	elseif ipc.get("MCPmode") == 2 then
    	switch ("PRESS", SPD2, "SPD")
        ipc.set("MCPalt", ipc.elapsedtime())
	else
    	switch ("PRESS", SPD3, "SPD")
        ipc.set("MCPalt", ipc.elapsedtime())
	end
end

function MCP_SPD_rotate (skip, skip, command)
    if command == '++' then
        SPDfast = SPDfast + 1
        if SPDfast > 2 then
            SPD = SPD + 10
        else
            command = ' +'
            SPD = SPD + 1
        end
    elseif command == '--' then
        SPDfast = SPDfast + 1
        if SPDfast > 2 then
            SPD = SPD - 10
        else
            command = ' -'
            SPD = SPD - 1
        end
    elseif command == ' +' then
        SPDfast = 0
        SPD = SPD + 1
    elseif command == ' -' then
        SPDfast = 0
        SPD = SPD - 1
    end
    if SPD > 900 then SPD = 900 end
    if SPD < 0 then SPD = 0 end
	if ipc.get("MCPmode") == 1 then
    	switch (SPDmode .. " " .. command, SPD1, "SPD", SPD)
	elseif ipc.get("MCPmode") == 2 then
    	switch (SPDmode .. " " .. command, SPD2, "SPD", SPD)
        ipc.set("MCPalt", ipc.elapsedtime())
	else
    	switch (SPDmode .. " " .. command, SPD3, "SPD", SPD)
        ipc.set("MCPalt", ipc.elapsedtime())
	end
    if AutoDisplay then DspSPD(SPD) end
end

function MCP_VVS_press ()
	if ipc.get("MCPmode") == 1 then
    	switch ("PRESS", VVS1, "VVS")
	elseif ipc.get("MCPmode") == 2 then
    	switch ("PRESS", VVS2, "VVS")
        ipc.set("MCPalt", ipc.elapsedtime())
	else
    	switch ("PRESS", VVS3, "VVS")
        ipc.set("MCPalt", ipc.elapsedtime())
	end
end

function MCP_VVS_rotate (skip, skip, command)
    if command == '++' then
        VVS = VVS + 5
    elseif command == '--' then
        VVS = VVS - 5
    elseif command == ' +' then
        VVS = VVS + 1
    elseif command == ' -' then
        VVS = VVS - 1
    end
    if VVS > 90 then VVS = 90 end
    if VVS < -90 then VVS = -90 end
	if ipc.get("MCPmode") == 1 then
    	switch (VVSmode .. " " .. command, VVS1, "VVS", VVS)
	elseif ipc.get("MCPmode") == 2 then
    	switch (VVSmode .. " " .. command, VVS2, "VVS", VVS)
        ipc.set("MCPalt", ipc.elapsedtime())
	else
    	switch (VVSmode .. " " .. command, VVS3, "VVS", VVS)
        ipc.set("MCPalt", ipc.elapsedtime())
	end
    if AutoDisplay then DspVVS(VVS) end
end

-- ############################################################## --

-- ## BUTTONS ################

function MCP_buttons (skip, skip, s)
	if ipc.get("MCPmode") == 1 then
		switch (s, MCP1, "MCP")
	elseif ipc.get("MCPmode") == 2 then
		switch (s, MCP2, "MCP")
        ipc.set("MCPalt", ipc.elapsedtime())
	else
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
	-- s = string.sub(s, 4, 4)
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

function RADIOS_buttons (skip, skip, s)
    -- _loggg("[MCP2] RAD: " .. s)
    switch (s, RADIOS, "RADIOS")
end

-- ## Tables init ############################################################ --

BUTTONS = {
["MCP"] = MCP_buttons ,
["EFI"] = EFIS_buttons ,
["USR"] = USER_buttons ,
["RAD"] = RADIOS_buttons
}

KNOBPRESS = {
["HDG"] = MCP_HDG_press ,
["ALT"] = MCP_ALT_press ,
["SPD"] = MCP_SPD_press ,
["VVS"] = MCP_VVS_press ,
["MIN"] = EFIS_MINS_press ,
["BAR"] = EFIS_BARO_press ,
["NDM"] = EFIS_CTR_press ,
["NDR"] = EFIS_TFC_press,
["FRE"] = RADIOS_FRE_press
}

KNOBROTATE = {
["HDG"] = MCP_HDG_rotate ,
["ALT"] = MCP_ALT_rotate ,
["SPD"] = MCP_SPD_rotate ,
["VVS"] = MCP_VVS_rotate ,
["MIN"] = EFIS_MINS_rotate ,
["BAR"] = EFIS_BARO_rotate ,
["NDM"] = EFIS_CTR_rotate ,
["NDR"] = EFIS_TFC_rotate ,
["FRE"] = RADIOS_FRE_rotate
}
