-- HANDLER FOR MCP2a (Airbus) PANELS
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

-----------------------------------------------------------------
-- ## MAIN ###############

-- reading VRI events
skip_fast = 0

-----------------------------------------------------------------
-- Handle all MCP controls (knobs, buttons and switches)
-- called from event set up in InitEvents (in events.lua)
function MCPcontrols (h, s)
    _loggg("[MCP2a] MCPcontrols MCP2a [h=" .. tostring(h) ..
        ", s=" .. tostring(s) .. "]")
	-- skip this command
	skip = false
	-- Getting first 3 chars of VRI-command to group them into functions
	group = string.sub(s, 1, 3)
	-- Getting 4th and all next chars - it's an exact command in group
	command = string.sub(s, 4)
    -- move LAMP to USER group
    if command == 'LAMP.' then
        group = 'USR'
    end
	-- Debug
	_logggg("[MCP2a] Handle :: [" .. group .. "] / [" .. command .. "] "
	.. tostring(length))

	-- Detecting knob-pull commands
	if string.sub(command, 5) == "^" then
		-- pause flight info updates
		ipc.set("FIP", ipc.elapsedtime())
        group = string.sub(command, 1, 3)
		-- knob_press = true
		switch (group, KNOBPULL, "_knob_pull", group)
		return
	end

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
        -- skipping first fast rotate signal to prevent occasional jumps
        -- _loggg("[MCP2a] in:" .. command)
        if command == "++" or command == "--" then
            skip_fast = skip_fast + 1
            if skip_fast < 2 then command = " " .. string.sub(command, 1, 1) end
        else
            skip_fast = 0
        end
        -- _loggg("[MCP2a] out:" .. command)
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

--------------------------------------------------------------------------------

-- handle interupt timer to handle all inputs and outputs
function VRI_TIMER ()
    --_loggg("[MCP2a] VRI Timer")
    if RADIOS_MSG and ipc.elapsedtime() - ipc.get("FIP2") > 5000 then
        if RADIOS_MSG_SHORT then
            DspRadiosShortClear ()
        else
            DspRadiosMedClear ()
        end
        RADIOS_MSG = false
        RADIOS_MSG_SHORT = false
    end
    -- clear display message fields (if not MCP2a Airbus)
    if not (_MCP2a() and Airbus) then
        if DSP_MSG1 and ipc.elapsedtime() - ipc.get("FIP") > 1500 then
            DspClearMed1 ()
            DSP_MSG1 = false
            AP_STATE = -1
        end
        if DSP_MSG2 and ipc.elapsedtime() - ipc.get("FIP") > 1500 then
            DspClearMed2 ()
            DSP_MSG2 = false
            AP_STATE = -1
        end
        if DSP_MSG and ipc.elapsedtime() - ipc.get("FIP") > 1500 then
            DspClearMed ()
            DSP_MSG = false
            AP_STATE = -1
        end
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
    if ipc.elapsedtime() - ipc.get("FIP") > 1000 then
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
    end
	-- Updating current AP or flight info
	if ipc.get("DSPmode") == 2 then
		-- only if no rotaries where move in last second
		if ipc.elapsedtime() - ipc.get("FIP") > 1000 then
			 DisplayFlightInfo ()
		end
	else
		if ipc.elapsedtime() - ipc.get("FIP") > 1000 then
			DisplayAutopilotInfo ()
		end
	end

    -- Handle panel mode time outs for auto return to first mode

    VRI_DELAY = ipc.get("VRI_DELAY")
    --_loggg('[awg] VRI_DELAY=' .. tostring(VRI_DELAY))

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
	end
end
----------- End of VRI Timer ----------------------------------

-- ########## DEFAULT CONTROL FUNCTIONS ####################

-- ## RADIO CONTROLS ########

function RADIOS_FRE_press ()
	switch ("PRESS", FRE1, "FRE")
end

function RADIOS_FRE_rotate (skip, skip, command)
    switch ("A " .. command, FRE1, "FRE", command)
end

-- ## EFIS KNOBS ################

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
	-- _loggg("[MCP2a] EFIS_BARO_rotate " .. command .. " / " .. BARO1_CFG_MODE)
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

function EFIS_NDM_press ()
	if ipc.get("EFISmode") == 1 then
		switch ("PRESS", NDM1, "NDM")
	elseif ipc.get("EFISmode") == 2 then
		switch ("PRESS", NDM2, "NDM")
        ipc.set("EFISalt", ipc.elapsedtime())
	else
		switch ("PRESS", NDM3, "NDM")
        ipc.set("EFISalt", ipc.elapsedtime())
	end
end

function EFIS_NDM_rotate (skip, skip, command)
	if ipc.get("EFISmode") == 1 then
		switch (NDMmode .. " " .. command, NDM1, "NDM", command)
	elseif ipc.get("EFISmode") == 2 then
		switch (NDMmode .. " " .. command, NDM2, "NDM", command)
        ipc.set("EFISalt", ipc.elapsedtime())
	else
		switch (NDMmode .. " " .. command, NDM3, "NDM", command)
        ipc.set("EFISalt", ipc.elapsedtime())
	end
end

function EFIS_NDR_press ()
	if ipc.get("EFISmode") == 1 then
		switch ("PRESS", NDR1, "NDR")
	elseif ipc.get("EFISmode") == 2 then
		switch ("PRESS", NDR2, "NDR")
        ipc.set("EFISalt", ipc.elapsedtime())
	else
		switch ("PRESS", NDR3, "NDR")
        ipc.set("EFISalt", ipc.elapsedtime())
	end
end

function EFIS_NDR_rotate (skip, skip, command)
	if ipc.get("EFISmode") == 1 then
		switch (NDRmode .. " " .. command, NDR1, "NDR", command)
	elseif ipc.get("EFISmode") == 2 then
		switch (NDRmode .. " " .. command, NDR2, "NDR", command)
        ipc.set("EFISalt", ipc.elapsedtime())
	else
		switch (NDRmode .. " " .. command, NDR3, "NDR", command)
        ipc.set("EFISalt", ipc.elapsedtime())
	end
end

-- ## MCP KNOBS ################

function MCP_HDG_press ()
    -- _loggg('[MCP2a] HDG Pressed')
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

function MCP_HDG_pull ()
    --_loggg('[MCP2a] HDG Pulled')
	if ipc.get("MCPmode") == 1 then
        switch ("PULL", HDG1, "HDG")
	elseif ipc.get("MCPmode") == 2 then
        switch ("PULL", HDG2, "HDG")
        ipc.set("MCPalt", ipc.elapsedtime())
	else
        switch ("PULL", HDG3, "HDG")
        ipc.set("MCPalt", ipc.elapsedtime())
	end
end

function MCP_HDG_rotate (skip, skip, command)
    -- trap nil HDG value
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
    --_loggg('[MCP2a] ALT Pressed')
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

function MCP_ALT_pull ()
    --_loggg('[MCP2a] ALT Pulled')
	if ipc.get("MCPmode") == 1 then
    	switch ("PULL", ALT1, "ALT")
	elseif ipc.get("MCPmode") == 2 then
    	switch ("PULL", ALT2, "ALT")
        ipc.set("MCPalt", ipc.elapsedtime())
	else
    	switch ("PULL", ALT3, "ALT")
        ipc.set("MCPalt", ipc.elapsedtime())
	end
end

function MCP_ALT_rotate (skip, skip, command)
    --_loggg("[MCP2a] ALT Rotate")
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
    --_loggg('[MCP2a] SPD Pressed')
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

function MCP_SPD_pull ()
    --_loggg('[MCP2a] SPD Pulled')
	if ipc.get("MCPmode") == 1 then
    	switch ("PULL", SPD1, "SPD")
	elseif ipc.get("MCPmode") == 2 then
    	switch ("PULL", SPD2, "SPD")
        ipc.set("MCPalt", ipc.elapsedtime())
	else
    	switch ("PULL", SPD3, "SPD")
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
    --_loggg('[MCP2a] VVS Pressed')
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

function MCP_VVS_pull ()
    --_loggg('[MCP2a] VVS Pulled')
	if ipc.get("MCPmode") == 1 then
    	switch ("PULL", VVS1, "VVS")
	elseif ipc.get("MCPmode") == 2 then
    	switch ("PULL", VVS2, "VVS")
        ipc.set("MCPalt", ipc.elapsedtime())
	else
    	switch ("PULL", VVS3, "VVS")
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
		switch (s, MCP1, "FCU")
	elseif ipc.get("MCPmode") == 2 then
		switch (s, MCP2, "FCU")
        ipc.set("MCPalt", ipc.elapsedtime())
	else
    	switch (s, MCP3, "FCU")
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
    _logggg("[MCP2a] RAD: " .. s)
    switch (s, RADIOS, "RADIOS")
end

-- ## Tables init ############################################################ --

BUTTONS = {
["EFI"] = EFIS_buttons ,
["FCU"] = MCP_buttons ,
["USR"] = USER_buttons ,
["RAD"] = RADIOS_buttons
}

KNOBPRESS = {
["BAR"] = EFIS_BARO_press ,
["NDM"] = EFIS_NDM_press ,
["NDR"] = EFIS_NDR_press ,
["SPD"] = MCP_SPD_press ,
["HDG"] = MCP_HDG_press ,
["ALT"] = MCP_ALT_press ,
["VVS"] = MCP_VVS_press ,
["FRE"] = RADIOS_FRE_press
}

KNOBPULL = {
["SPD"] = MCP_SPD_pull ,
["HDG"] = MCP_HDG_pull ,
["ALT"] = MCP_ALT_pull ,
["VVS"] = MCP_VVS_pull
}

KNOBROTATE = {
["BAR"] = EFIS_BARO_rotate ,
["NDM"] = EFIS_NDM_rotate ,
["NDR"] = EFIS_NDR_rotate ,
["SPD"] = MCP_SPD_rotate ,
["HDG"] = MCP_HDG_rotate ,
["ALT"] = MCP_ALT_rotate ,
["VVS"] = MCP_VVS_rotate ,
["FRE"] = RADIOS_FRE_rotate
}
