-- MAIN LINDA SYSTEM FUNCTIONS
-- Updated for LINDA 4.1.5
-- Mar 2022

-- **************************************************************
--
--      DO NOT EDIT OR CHANGE THE CONTENTS OF THIS FILE
--
--      CORE LINDA FUNCTIONALITY
--
--      PLACE USER FUNCTIONS IN USER.LUA (\linda\[aircraft]\)
--
-- **************************************************************

version = "4.1.5"

-- universal toggler storage
tgl = {}
ipcPARAM = 0

-- ## INITIALISATION ###############

function Init ()
--### Initialise LINDA set up
    _logg('[INIT] Starting LINDA LUA setup')

	-- fallback init vars
	if type(FallbackInitVars) == "function" then FallbackInitVars () end

	-- Init current module vars if defined in module
	if type(InitVars) == "function" then InitVars() end

    _log('[START] LINDA Ver  = ' .. version)

    fsuipc = ipc.readUD(0x3304)
    if fsuipc == nil then
        _log('[START] FSUIPC not found')
    else
        hex = string.format("%x", fsuipc) -- * 255)
        _log('[START] FSUIPC Ver = ' .. hex)
    end
    fs = ipc.readUB(0x3124)
    if fsuipc == nil then
        _log('[START] Flt Sim not found')
    else
        hex = string.format("%d", fs) -- * 255)
        _log('[START] MSFS Ver   = ' .. hex)
    end

    sim = ipc.readUW(0x3308)
    if sim == 13 then
        P3D = 1
        _log('[COMM] MSFS found')
    else
        P3D = 0
    end

    -- define P3D and A2A
    if string.find(tostring(ipc.get("acft_handle")), "A2A") ~= nil then
        A2A = 1
        _logg('[START] A2A detected')
    else
        A2A = 0
    end

	-- Connect to MCP
    _log('[COMM] Checking VRI')
	if ipc.get("VRI_ENABLED") == 1 then
        _logg('[COMM] Enabling VRI')

		config_mcp = ipc.get("PATH_ACFT_CFG") .. ipc.get("acft_handle")
			.. "/config-" .. ipc.get("VRI_TYPE")
		if file_exists(config_mcp .. ".lua") then
			-- COM-port connection
			ConnectMCP()
			if dev ~= 0 then
				-- Initialize MCP
                ipc.sleep(1000)
				InitMCP()
                ipc.sleep(1000)
				-- Init display
   	            if type(InitDsp) == "function" then InitDsp(true) end

				--InitDsp(true) -- true - for quiet mode
                ipc.sleep(1000)
				_logg("[COMM] MCP Started...")
			else
				_logg("[COMM] MCP Not Started - Config file missing...")
			end
		end
	end

	-- Connect to CDU
    _log('[COMM] Checking CDU')
	if ipc.get("CDU_ENABLED") == 1 then
        _logg('[COMM] Enabling CDU')

		config_cdu = ipc.get("PATH_ACFT_CFG") .. ipc.get("acft_handle") .. "/config-cdu2"

		if file_exists(config_cdu .. ".lua") then
			-- COM-port connection
            ipc.sleep(1000)
			ConnectCDU()
            ipc.sleep(1000)
			if dev2 ~= 0 then
				-- Initialize CDU
				InitCDU()
				-- Init display
   	            if type(InitDsp) == "function" then InitDsp(true) end

				--InitDsp(true) -- true - for quiet mode
                ipc.sleep(1000)
				_logg("[COMM] CDU Started...")
			else
				_logg("[COMM] CDU Not Started - Config file missing...")
			end
		end
	end

	-- Connect Saitek Panels
    _logg('[COMM] Starting Saitek Panels ..')
	if ipc.get("HID_READY") == 1 then
		for key, value in pairs(J) do
			if type(value) == "table" then
				if JVID[key] ~= nil and JPID[key] ~= nil then
                    if SAI_DISPLAY then
                       -- Multi Panel
					   if JVID[key] == SAITEK_VID
                            and JPID[key] == MULTI_PANEL_PID then
						  _logg("[COMM] Saitek Multi Panel available!")
						  ConnectSMP ()
						  InitSMP ()
					   end
                       -- Radio Panel
					   if JVID[key] == SAITEK_VID
                            and JPID[key] == RADIO_PANEL_PID then
						  _logg("[COMM] Saitek Radio Panel available!")
						  ConnectSRP ()
						  InitSRP ()
					   end
                    end
                    -- Switch Panel
					if JVID[key] == SAITEK_VID
                        and JPID[key] == SWITCH_PANEL_PID then
						_logg("[COMM] Saitek Switch Panel available!")
						ConnectSSP ()
						InitSSP ()
					end
 				end
			end
		end
    else
        _logg('[COMM] HID NOT Ready')
    end
    buttonRepeatClear()

    -- restart WASM for Lvars and Hvars
    ipc.reloadWASM()

	init = true
end

-- ## SHUTDOWN ###############

function Shutdown()
    -- close MCP
    if dev ~= nil then
        if dev ~= 0 then
            _logggg('[COMM] Closing VRI port Dev=' .. dev)
           --com.close(dev)
        end
    end
    hidClose()
end

-- ## MCP Combo Panels ----------------------------------------------------

-- connect to MCP COM-port
function ConnectMCP ()
--### Connects LINDA to VRi MCP
    _logg("[COMM] ConnectMCP - Connecting to MCP Panel...")
	-- COM port params
	speed = 115200
	handshake = 0
	-- Trying to make a persistent connection to VRI MCP
	dev = com.open(ipc.get("VRI_DEVICE"), speed, handshake)
	if dev == 0 then
		--_err("[COMM] Could not open MCP Combo port!")
		_loggg("[COMM] VRI MCP Combo is ENABLED but not found on "
			.. "port " .. string.upper(ipc.get("VRI_DEVICE")) , 10)
		ipc.sleep(4000)
	end
    _logg("[COMM] ConnectMCP completed - " .. dev)
end

function InitMCP ()
--### Initialise MCP
    _logg("[COMM] InitMCP - Initialising MCP...")
	if dev == 0 then return end
	-- initialize MCP Combo
	ipc.sleep(150)
    --_loggg('[COMM] MCP Reset Command sent')
	--com.write(dev, "CMDRST", 8)
	--ipc.sleep(150)
    _loggg('[COMM] MCP Connect Command sent')
	com.write(dev, "CMDCON", 8)
	ipc.sleep(250)
    _loggg('[COMM] MCP Reset and Connect completed')

	if _MCP2 () then
		_logg("[COMM] Initializing MCP2 (Boeing)...")
		-- radios display
		ipc.sleep(1500)
		DspRadioLong1(" Powered by ")
		DspRadioLong2(" LINDA v" .. version)
		DspLong1("LINDA init...")
		DspLong2(ipc.get("acft_handle"))
		DspClearLong3()
		DspClearLong4()
		ipc.sleep(1000)
		DspClearAll()
		ipc.sleep(50)
		-- initialise displays
		com.write(dev, "DSPI", 8)
		ipc.sleep(1000)
		com.write(dev, "F/DOFF", 8)
		ipc.sleep(50)
		com.write(dev, "A/TOFF", 8)
        ipc.sleep(50)
        Dsp1("\\\\\\ ")
		Dsp3(" \\\\ ")
		Dsp9("\\\\\\ ")
		DspB(" \\\\ ")
		DspC("--- ")
		-- redisplay shifted HDG labels
		Dsp4("HDG ")
		ipc.sleep(100)
        --if type(InitDsp) == "function" then InitDsp(true) end
        --InitDsp()
	elseif (_MCP2a () and Airbus) then
		_logg("[COMM] Initializing MCP2a (Airbus) - Airbus Aircraft...")
		-- radios display
		ipc.sleep(1500)
		DspRadioLong1(" Powered by ")
		DspRadioLong2(" LINDA v" .. version)
		DspLong1("LINDA init...")
		DspLong2(ipc.get("acft_handle"))
		DspClearLong3()
		DspClearLong4()
		ipc.sleep(1000)
		DspClearAll()
		ipc.sleep(50)
		com.write(dev, "DSPI", 8)
		ipc.sleep(100)
        --if type(InitDsp) == "function" then InitDsp(true) end
        --InitDsp()
	elseif _MCP2a () then -- MCP2a default
		_logg("[COMM] Initializing MCP2a (Airbus) - Default...")
		-- radios display
		ipc.sleep(1500)
		DspRadioLong1(" Powered by ")
		DspRadioLong2(" LINDA v" .. version)
		DspLong1("LINDA init...")
		DspLong2(ipc.get("acft_handle") .. "")
		DspClearLong3()
		DspClearLong4()
		ipc.sleep(1000)
		DspClearAll()
		ipc.sleep(50)
		com.write(dev, "DSPI", 8)
		-- prepare for default DspShow fields
		DspClearMed1()
		DspClearMed2()
		Dsp3('HDG ')
		--  call display initialisation
        --if type(InitDsp) == "function" then InitDsp(true) end
        --InitDsp()
	else  --MCP1
		DspClearAll()
		_log("[COMM] Initializing MCP1 (Original)")
		_log("[COMM] *****           NOTE              *****")
		_log("[COMM] ***** LINDA " .. version .. " may not work     *****")
		_log("[COMM] ***** correctly with MCP1 panel.  *****")
		_log("[COMM] ***** If you experience problems, *****")
		_log("[COMM] ***** try LINDA version 1.13      *****")
		com.write(dev, "CMDFR", 8)
		ipc.sleep(50)
	end
	-- Replace SPD indication with CRS
	if SPD_CRS_replace and not _MCP1 () then
		ipc.sleep(50)
		DspSPD2CRS ()
	end

	-- wrong COM freq read workaround
	-- swap frequences twice
	ipc.control(66372) -- com1
	ipc.sleep(50)
	ipc.control(66444) -- com2
	ipc.sleep(50)
	ipc.control(66372)
	ipc.sleep(50)
	ipc.control(66444)

	-- same for NAV
	ipc.control(66448) -- nav1
	ipc.sleep(50)
	ipc.control(66452) -- nav2
	ipc.sleep(50)
	ipc.control(66448)
	ipc.sleep(50)
	ipc.control(66452)

	Default_COM_select ()
    _logg("[COMM] InitMCP - completed")
end

-- ## CDU2 Panel ----------------------------------------------------

-- connect to CDU COM-port
function ConnectCDU ()
--### Connects LINDA to VRi CDU
    _logg("[COMM] ConnectCDU - Connecting to VRI CDU Panel...")
	-- COM port params
	speed = 115200
	handshake = 0
	-- Trying to make a persistent connection to VRI MCP
	dev2 = com.open(ipc.get("CDU_COMPORT"), speed, handshake)
	if dev2 == 0 then
		--_err("[COMM] Could not open CDU port!")
		_loggg("[COMM] VRI CDU is ENABLED but not found on "
			.. "port " .. string.upper(ipc.get("CDU_COMPORT")) , 10)
		ipc.sleep(4000)
	end
    _logg("[COMM] ConnectCDU completed - " .. dev2)
end

function InitCDU ()
--### Initialise MCP
    _logg("[COMM] InitCDU - Initialising VRI CDU...")
	if dev2 == 0 then return end
	-- initialize CDU
	ipc.sleep(150)
    _loggg('[COMM] VRI CDU Reset Command sent')
	com.write(dev2, "CMDRST", 8)
	ipc.sleep(250)
    _loggg('[COMM] VRI CDU Connect Command sent')
	com.write(dev2, "CMDCON", 8)
	ipc.sleep(250)
    _loggg('[COMM] VRI CDU Reset and Connect completed')
end

-- ## SAITEK PANELS -----------------------------------------------------

-- $$ Radio Panel -------------------------------------------------------

function ConnectSRP ()
	-- Connect to Saitek Radio Panel
	-- Trying to make a persistent connection to SRP
    _logg('[COMM] Connecting Saitek Radio Panel ..')
	SaitekRPanel, radio_rd, radio_rdf =
        com.openhid(SAITEK_VID, RADIO_PANEL_PID, 0, 0)
	if SaitekRPanel == 0 then
		_loggg("[COMM] Saitek Radio Panel is DETECTED " ..
            "but couldn't be opened" , 10)
        return
    end
    ClearSRP()
end

function WriteSRP(data)
    if SaitekRPLast ~= data then
        com.writefeature(SaitekRPanel, data, radio_rdf)
        SaitekRPLast = data
        ipc.sleep(200)
    end
end

function TestSRP ()
local data
    -- display sequence figure 8. across all windows
	_logg("[COMM] Testing Saitek Radio Panel ..")
    for i = 0, 19 do
        local displayedString =
            string.char(10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10,
            10, 10, 10, 10, 10, 10, 10, 10)
        data = string.sub(displayedString, 0, i - 1)
        .. string.char(216) .. string.sub(displayedString, i + 1)

        WriteSRP(string.char(0) .. data .. string.char(0, 0))
    end
    -- display 1.1111, 2.2222, 3.3333 and 4.4444 in windows
    data = string.char(0)
        .. string.char(209, 1, 1, 1, 1, 210, 2, 2, 2, 2)
        .. string.char(211, 3, 3, 3, 3, 212, 4, 4, 4, 4)
        .. string.char(0, 0)
    WriteSRP(data)
    ipc.sleep(1500)
    ClearSRP()
	_loggg("[COMM] Saitek Radio Panel test complete...")
end

function ClearSRP ()
    -- clear display
	local data = string.char(0) ..
        string.char(10, 10, 10, 10, 10) ..
        string.char(10, 10, 10, 10, 10) ..
        string.char(10, 10, 10, 10, 10) ..
        string.char(10, 10, 10, 10, 10) ..
        string.char(0, 0)
    --if SAI_DISPLAY == 1 and SaitekRPData ~= data then
        WriteSRP(data)
    --    SaitekRPData = data
    --end
    --ipc.sleep(1500)
end

function InitSRP ()
    _loggg('[COMM] SAI_DISPLAY=' .. tostring(SAI_DISPLAY)
        .. ' RP=' .. tostring(SaitekRP))
	if SAI_DISPLAY == 0 or SaitekRPanel == 0 then return end
	_logg("[COMM] Initializing Saitek Radio Panel...")
    SaitekRPStop = 0
    if SAI_TEST > 0 then
        TestSRP()
    end
    ClearSRP()
    RefreshSRP ()
end

function RefreshSRP ()
	if SAI_DISPLAY == 0 or SaitekRPanel == 0 then return end

    local data = string.char(0)
    if isAvionicsOn () and SaitekRPStop == 0 then
		data = data .. buildDataStringForSRP (ipc.get('SRP_MODE_1'))
		data = data .. buildDataStringForSRP (ipc.get('SRP_MODE_2'))
		data = data .. string.char(0, 0)
        WriteSRP(data)
	else
        --_loggg('[COMM] Saitek RP Clear = ' .. tostring(SaitekRPClear))
        ClearSRP()
	end
end

function buildDataStringForSRP (mode)
	local data = ""

	if mode == 0 or mode == 1 or mode == 2 or mode == 3 then
		data = formatFrequencyForSRP (getValueForSRP (mode, false))
			.. formatFrequencyForSRP (getValueForSRP (mode, true))
	elseif mode == 4 then -- ADF
		data = formatNumberForSRP (getValueForSRP (mode, false),
            string.char(0))
			.. formatNumberForSRP (getValueForSRP (mode, true),
            string.char(0))
	elseif mode == 5 then -- DME
		data = formatNumberForSRP (string.format("%03.1f",
            getValueForSRP (mode, false) / 10), string.char(10))
			.. formatNumberForSRP (string.format("%03.1f",
            getValueForSRP (mode, true) / 10), string.char(10))
	elseif mode == 6 then -- TXPR - Baro & Txpr Channel
        -- Get Baro Referemce
		local baroRef = getValueForSRP (mode, false)
        local baroUnit = ipc.get("SRP_QNH_UNIT")
		if baroUnit == 0 then
			baroRef = baroRef * 0.0295299830714
            --_loggg("BaroRef=" .. baroRef);
			baroRef = math.floor(baroRef * math.pow(10, 2) + 0.5) /
                math.pow(10, 2)
            if (baroRef - math.floor(baroRef) == 0) then
                baroRef = baroRef + 0.01
            end
		end
        --_loggg("BaroRef/Unit=" .. baroRef .. ' ' .. baroUnit);
        -- Get Sqwark Code and Cursor Position
        local squawk = getValueForSRP (mode, true)
		local cursorPosition = ipc.get('SRP_SQUAWK_CURSOR')
		squawk = string.sub(squawk, 0, cursorPosition + 1) .. "."
			.. string.sub(squawk, cursorPosition + 2)
        -- format for output
		data = formatNumberForSRP (baroRef, string.char(10))
			.. formatNumberForSRP (squawk, string.char(10))
	end

	if data ~= nil and string.len(data) > 0 then
		return data
	else
		return string.char(10, 10, 10, 10, 10, 10, 10, 10, 10, 10)
	end
end

function getValueForSRP (mode, stdby)
	local data = nil

	if mode == 0 then
		data = getCOMFrequency (1, stdby)
	elseif mode == 1 then
		data = getCOMFrequency (2, stdby)
	elseif mode == 2 then
		data = getNAVFrequency (1, stdby)
	elseif mode == 3 then
		data = getNAVFrequency (2, stdby)
	elseif mode == 4 then
		if not stdby then
			data = getADFFrequency (1)
		else data = getADFFrequency (2) end
	elseif mode == 5 then
		if not stdby then
			data = getDMEDistance (1)
		else data = getDMEDistance (2) end
	elseif mode == 6 then
		if not stdby then
			data = getBaroRef ()
		else data = getSquawk () end
	end

	return data
end

function setValueForSRP (mode, stdby, value)
	if mode == 0 and stdby then
		Default_COM_1_set (value)
	elseif mode == 1 and stdby then
		Default_COM_2_set (value)
	elseif mode == 2 and stdby then
		Default_NAV_1_set (value)
	elseif mode == 3 and stdby then
		Default_NAV_2_set (value)
	elseif mode == 4 then
		if stdby then adf_sel = 2 else adf_sel = 1 end
		Default_ADF_set (value)
	elseif mode == 6 then
		if not stdby then
            setBaroRef (value)
        else
            Default_XPND_set (value)
        end
	end
end

function formatFrequencyForSRP (freq)
	local strFreq = strFreq(freq)
	return formatNumberForSRP (strFreq, string.char(0))
end

function formatNumberForSRP (number, padWith)
	if padWith == nil then
		padWith = string.char(10)
	end

	local formatedNumber = ""
	number = tostring(number)

	for i = 0, string.len(number) do
		if string.sub(number, i, i) ~= '.' then
			local character = tonumber(string.sub(number, i, i))

			if character ~= nil then
				if string.sub(number, i + 1, i + 1) == '.' then
					character = 208 + character
				end
				formatedNumber = formatedNumber .. string.char(character)
			end
		end
	end

	if string.len(formatedNumber) < 5 then
		for j = 0, (5 - string.len(formatedNumber)) - 1 do
			formatedNumber = padWith .. formatedNumber
		end
	end

	return string.sub(formatedNumber, 0, 5)
end

-- $$ Multi Panel --------------------------------------------------------

function ConnectSMP ()
	-- Connect to Saitek Multi Panel
	-- Trying to make a persistent connection to SMP
    _logg('[COMM] Connecting Saitek Multi Panel')
    SaitekMPanel, multi_rd, multi_rdf =
        com.openhid(SAITEK_VID, MULTI_PANEL_PID, 0, 0)
	if SaitekMPanel == 0 then
		_loggg("[COMM] Saitek Multi Panel is DETECTED " ..
            "but couldn't be opened" , 10)
	end
end

function WriteSMP(data)
    if SaitekMPLast ~= data then
        com.writefeature(SaitekMPanel, data, multi_rdf)
        SaitekMPLast = data
        ipc.sleep(200)
    end
end

function TestSMP ()
	_logg("[COMM] Testing Saitek Multi Panel ..")
    for i = 1, 10 do
        -- sequence figure 8 and buttons
        displayedString = string.char(1, 2, 3, 4, 5,
            6, 7, 8, 9, 0)
        displayedString = string.sub(displayedString,
            0, (i - 1)) .. string.char(8)
            .. string.sub(displayedString, (i + 1))
        buttons = 2 ^ (i - 1)
        if i > 8 then
            buttons = 1
        end
        WriteSMP(string.char(0) ..
            displayedString
            .. string.char(buttons))
    end

    -- display 0 to 9 and all buttons
    WriteSMP(string.char(0)
        .. string.char(0, 1, 2, 3, 4, 5, 6, 7, 8, 9)
        .. string.char(255))
    ipc.sleep(1500)
    ClearSMP()
    _loggg("[COMM] Saitek Multi Panel test complete ..")
end

function ClearSMP ()
    -- clear display with blanks
	local data = string.char(0)
		.. string.char(10, 10, 10, 10, 10, 10, 10, 10, 10, 10)
		.. string.char(0)
    WriteSMP(data)
    --ipc.sleep(1500)
    --_loggg("[COMM] Saitek MP display cleared")
end

function InitSMP ()
local displayedString
local buttons
    _loggg('[COMM] SAI_DISPLAY=' .. tostring(SAI_DISPLAY)
        .. ' MP=' .. tostring(SaitekMP))
	if SAI_DISPLAY == 0 or SaitekMPanel == 0 then return end
	_logg("[COMM] Initializing Saitek Multi Panel")
    SaitekMPStop = 0
    if SAI_TEST > 0 then
        TestSMP()
    end
    ClearSMP()
    RefreshSMP ()
end

function RefreshSMP ()
local data, n
    --_loggg("[COMM] SAI_DISPLAY=" .. tostring(SAI_DISPLAY) .. ' MP=' .. tostring(SaitekMPanel))
	if SAI_DISPLAY == 0 or SaitekMPanel == 0 then return end
    --_loggg("[COMM] Saitek MP refresh display")
	if isAvionicsOn () and SaitekMPStop == 0 then
		data = string.char(0)
        data = data .. buildDataStringForSMP (ipc.get('SMP_MODE'))
		data = data .. buildLightsStatusForSMP ()
        WriteSMP(data)
    else
        --_loggg('[COMM] Saitek MP Clear = ' .. tostring(SaitekRPClear))
        ClearSMP()
	end
end

function buildDataStringForSMP (mode)
	local data = nil
    --_logggg ('[COMM] SMP val = ' .. ipc.get('SMP_REAL_VALUE'))
	if mode == 0 or mode == 1 then
		if isAutopilotInVS () then
            -- prepare ALT & VS on top and bottom lines
			data = formatNumberForSMP(
                getValueForSMP (0, ipc.get('SMP_REAL_VALUE')))
                .. formatNumberForSMP(
                getValueForSMP (1, ipc.get('SMP_REAL_VALUE')))
		else
            -- prepare other modes on top line and blank below
			data = formatNumberForSMP(
                getValueForSMP (0, ipc.get('SMP_REAL_VALUE')))
                .. string.char(14, 14, 14, 14, 14)
		end
	else
        -- prepare value for top line and dashes for bottom line
		data = formatNumberForSMP(
            getValueForSMP (mode, ipc.get('SMP_REAL_VALUE')),
            true, string.char(0)) .. string.char(10, 10, 10, 10, 10)
	end

	if data ~= nil and string.len(data) > 0 then
		return data
	else
        -- return blank top line and dashes on bottom line
		return string.char(10, 10, 10, 10, 10, 14, 14, 14, 14, 14)
	end
end

function buildLightsStatusForSMP ()
	local data = 0
    local bits

	if isAutopilotEngaged () then
		bits = { isAutopilotEngaged (), isAutopilotInHDG (),
                isAutopilotInNAV (), isAutopilotInSPD (),
                isAutopilotInALT (), isAutopilotInVS (),
                isAutopilotInAPPR (), isAutopilotInLOC () }
		for i, value in pairs(bits) do
			if value then
				data = data + (2 ^ (i - 1))
			end
		end
	end
	return string.char(data)
end

function getValueForSMP (mode, real)
	local data = nil

	if mode == 0 then
		data = getALTValue ()
	elseif mode == 1 then
		data = getVSValue ()
	elseif mode == 2 then
		data = getSPDValue ()
	elseif mode == 3 then
		data = getHDGValue ()
	elseif mode == 4 then
		data = getCRSValue ()
	end

	return data
end

function setValueForSMP (mode, value)
	if mode == 0 then
		setALTValue (value)
	elseif mode == 1 then
		setVSValue (value)
	elseif mode == 2 then
		setSPDValue (value)
	elseif mode == 3 then
		setHDGValue (value)
	elseif mode == 4 then
		setCRSValue (value)
	end
end

function formatNumberForSMP (number, short, padWith)
    --_logggg('[COMM] SMP num=' .. number)
	if padWith == nil then
		padWith = string.char(10)
	end

	if short == nil then short = false end

	local formatedNumber = tostring(math.abs(number))
	if number < 0 then
		formatedNumber = string.char(14) .. formatedNumber
	end

	local length = 5

	if string.len(formatedNumber) < length then
		for j = 0, (length - string.len(formatedNumber)) - 1 do
			formatedNumber = tostring(padWith) .. formatedNumber
		end
	end

	return string.sub(formatedNumber, 0, length)
end

-- $$ Switch Panel -----------------------------------------------------

function ConnectSSP ()
	-- Connect to Saitek Multi Panel
	-- Trying to make a persistent connection to SMP
    _logg('[COMM] Connecting Saitek Switch Panel')
    SaitekSPanel, switch_rd, switch_rdf =
        com.openhid(SAITEK_VID, SWITCH_PANEL_PID, 0, 0)
	if SaitekSPanel == 0 then
		--_err("Could not open Saitek Switch Panel!")
		_loggg("[COMM] Saitek Multi Panel is DETECTED " ..
            "but couldn't be opened" , 10)
    end
end

function TestSSP ()
    _loggg("[COMM] Saitek Switch Test Not Implemented")
--[[	_logg("[COMM] Testing Saitek Switch Panel ..")
    -- not tested -
    for i = 1, 10 do
        -- sequence figure 8 and buttons
        displayedString = string.char(10, 10, 10, 10, 10,
            10, 10, 10, 10, 10)
        displayedString = string.sub(displayedString,
            0, (i - 1)) .. string.char(8)
            .. string.sub(displayedString, (i + 1))
        buttons = 2 ^ (i - 1)
        if i > 8 then
            buttons = 1
        end
        com.writefeature(SaitekSPanel, string.char(0) ..
            displayedString
            .. string.char(buttons), multi_rdf)
        ipc.sleep(100)
    end

    -- display 0 to 9 and all buttons
    com.writefeature(SaitekSPanel, string.char(0)
        .. string.char(0, 1, 2, 3, 4, 5, 6, 7, 8, 9)
        .. string.char(255), multi_rdf)
    ipc.sleep(500)
	_loggg("[COMM] Saitek Switch Panel test complete ..")
    --]]
end


function InitSSP ()
local displayedString
local buttons
local jid
    _loggg('[COMM] SAI_DISPLAY=' .. tostring(SAI_DISPLAY)
        .. ' SP=' .. tostring(SaitekSP))
	if SAI_DISPLAY == 0 or SaitekSPanel == 0 then return end

	_logg("[COMM] Initializing Saitek Switch Panel")
    jid = "06A30D670" --.. tohex(SAITEK_VID) .. tohex(SWITCH_PANEL_PID) .. "0"
    --_logg("[COMM] SSP jid = " .. jid)
    -- simulate Both Mags
    --buttonOnPress(jid, 17)
    if SAI_TEST > 0 then
        TestSSP()
    end
end

-- ## INIT COMMON VARS ##############

function CommonInitVars ()
	-- ### Initialises common LINDA variables used by LINDA

    GLOBAL = 0

    Rcount = 0 -- button runaway count

    Tcount = 0

    -- flags for A2A and P3D products - changes some conversions
    A2A = 0
    P3D = 0

    -- initialise VRI devices
    dev = 0
    dev2 = 0

    -- force CH Yoke (068E00FF) to be ignored - stop FSUIPC6 crash
    CHY = -1

    -- display Sim VAS flag
    VAS_DISPLAY = ipc.get("VAS_DISPLAY")
    _loggg('[COMM] VAS Display set to ' .. tostring(VAS_DISPLAY))

    -- Saitek Panel display flags for LUA - SAITEK set by GUI
    -- SAI_DISPLAY = 0     -- 1 controls LUA output to panels
    SAI_DISPLAY = 1 - ipc.get("SAITEK") -- set 0 if GUI has control
    SAI_TEST = 0                       -- turns off self-test on reboot

    _loggg('[COMM] SAITEK_FLAG=' .. tostring(ipc.get('SAITEK'))
        .. ' SAI_DISPLAY=' .. tostring(SAI_DISPLAY)
        .. ' SAI_TEST=' .. tostring(SAI_TEST))

    if SAI_DISPLAY > 0 then
        _logg('[COMM] Saitek LUA in use ..')
    else
        _logg('[COMM] Saitek GUI in use ..')
    end

    -- saitek panel VID & PIDs
	SAITEK_VID = 0x06A3
	MULTI_PANEL_PID = 0x0D06
	RADIO_PANEL_PID = 0x0D05
    SWITCH_PANEL_PID = 0x0D67

	-- autosave flight
	AUTOSAVE_ENABLE = 0
	AUTOSAVE_TOUCHDOWN = 1
	AUTOSAVE_EACH_AIRFIELD = 0
	AUTOSAVE_DEFAULT_FLIGHT = 0
	AUTOSAVE_PLANE_FLIGHT = 0
	AUTOSAVE_MAGNETO_CHECK = 0
	AUTOSAVE_BATTERY_CHECK = 0
	AUTOSAVE_LIGHTS_CHECK = 0
	AUTOSAVE_PARKING_CHECK = 0
	FLIGHT_SAVED = true

	-- MCP 2 vars -------------------
	SPD = 100
	HDG = 0
	ALT = 100
	VVS = 0
	FPA = 0
	OBS1 = 999
	OBS2 = 999
	CRS1 = 0
	CRS2 = 0
	CRS3 = 0
	SPDfast = 0
	HDGfast = 0
	ALTfast = 0
	VVSfast = 0
	FREfast = 0

	-- Special Display control variables

	-- enable/disable default AP knob display functions
	AutoDisplay = true
	-- true outputs DspShow text to radio top line
	DspShowRadio = false
	-- enable/disable default AP knob RADIOS display functions
	RadiosAutoDisplay = true
	-- replace SPD indication with CRS indication for bush planes
	SPD_CRS_replace = false
	-- flag for Airbus aircraft on MCP2a panels
	Airbus = false

	RADIOS_MODE = 0 -- 1 com, 2 nav, 3 adf, 4 dme, 5 xpnd
	RADIOS_SUBMODE = 2 --
	RADIOS_MhzKhz = 1 -- 1 Mhz, 2 KHz
	RADIOS_MhzKhz_prev = 0
	RADIOS_CURSOR_POS = 3 -- adf cursor position
	RADIOS_ADF_FREQ1 = ''
	RADIOS_ADF_FREQ2 = ''
	RADIOS_DME_CRS1 = 0
	RADIOS_DME_CRS2 = 0
	RADIOS_XPND_CODE = ''
	RADIOS_MSG = false -- true on message show, used for auto-clear
	RADIOS_MSG_SHORT = false
	AP_STATE = -1
	DSP_MSG = false
	DSP_MSG1 = false
	DSP_MSG2 = false
	DSP_MSG_PREV1 = ''
	DSP_MSG_PREV2 = ''
	DSP_PREV1 = ''
	DSP_PREV2 = ''
	DSP_PREV3 = ''
	DSP_PREV4 = ''
	DSP_PREV5 = ''
	DSP_PREV6 = ''
	DSP_PREV7 = ''
	DSP_PREV8 = ''
	DSP_PREV9 = ''
	DSP_PREVA = ''
	DSP_PREVB = ''
	DSP_PREVC = ''
	DSP_PREVD = ''
	DSP_PREVE = ''
	DSP_PREVF = ''
	DSP_SPD_PREV = ''
	DSP_HDG_PREV = ''
	DSP_ALT_PREV = ''
	DSP_VVS_PREV = ''
	FLIGHT_INFO1 = ''
	FLIGHT_INFO2 = ''

	if _MCP1() then
		FLIGHT_INFO_TEXT = 'INFO'
	else
		FLIGHT_INFO_TEXT = ' INFO'
	end

	-- END OF MCP 2 vars -------------

	-- init or not yet
	init = false
	dev = 0

    -- Saitek Panels (Multi, Radio and Switch
    SaitekMPanel = 0
    SaitekRPanel = 0
    SaitekSPanel = 0
    SaitekRPStop = 1
    SaitekMPStop = 1
    SaitekRPLast = ""
    SaitekMPLast = ""

	multi_rd, multi_rdf, radio_rd, radio_rdf, switch_rd, switch_rdf = nil

	com_sel = 1
	com_open = 0
	com1_firstload = true
	com2_firstload = true
	com1x_freq = ipc.readUW(0x034E)
	com1s_freq = ipc.readUW(0x311A)
	com2x_freq = ipc.readUW(0x3118)
	com2s_freq = ipc.readUW(0x311C)
	com_audio = 1

	nav_sel = 1
	nav_open = 0
	nav1_firstload = true
	nav2_firstload = true
	nav1x_freq = ipc.readUW(0x0350)
	nav1s_freq = ipc.readUW(0x311E)
	nav2x_freq = ipc.readUW(0x0352)
	nav2s_freq = ipc.readUW(0x3120)
	nav_audio = 1

	adf_sel = 1
	adf1_firstload = true
	adf2_firstload = true

	trn_firstload = true
	trn_vfr_tmp = false -- used to switch 1200 vs current squawk

	dme_sel = 1
	dme_open = 0
	dme_ident_tmp = 0 -- used in Default_DME_init as temporary global storage
	dme_timer_skip = 0

	-- SPD2CRS vars
	-- crs_open - course shown on display in place of SPD
	-- 1 - OBS1
	-- 2 - OBS2
	-- 3 - ADF1
	-- 4 - ADF2
	crs_open = 1

	-- sync dsp
	sync_spd = 0
	sync_hdg = 0
	sync_alt = 0
	sync_crs = 0
	sync_crs2 = 0
	sync_adf = 0
	sync_adf2 = 0
	sync_vvs = 0

    -- Starting HID shift modes  ????
	ipc.set("GLOBmode", 1)
	ipc.set("SHFTmode", 0)

	-- Starting MCP modes
	ipc.set("EFISmode", 1)
	ipc.set("MCPmode", 1)
	ipc.set("USERmode", 1)

	ipc.set("EFISalt", 0)
	ipc.set("MCPalt", 0)
	ipc.set("USERalt", 0)

	ipc.set("EFISrestore", 1)
	ipc.set("MCPrestore", 1)
	ipc.set("USERrestore", 1)

	-- starting Saitek Radio Panel Mode
	ipc.set('SRP_MODE_1', 0) -- 0: COM1, 1: COM2, 2: NAV1, 3: NAV2, 4: ADF, 5: DME, 6: XPDR
	ipc.set('SRP_MODE_2', 0) -- 0: COM1, 1: COM2, 2: NAV1, 3: NAV2, 4: ADF, 5: DME, 6: XPDR
	ipc.set("SRP_DME_STDBY", 0) -- 0: Speed, 1: Time to Station
	
    local BARO = ipc.get("BARO")

    if BARO == nil then
	   ipc.set('SRP_QNH_UNIT', 0) -- 0: hPa, 1: inHg
	   BARO = 0
    else
        ipc.set('SRP_QNH_UNIT', BARO)
    end
    --_loggg('[COMM] Baro Ref = ' .. BARO)

	ipc.set('SRP_SQUAWK_CURSOR', 0) -- 0, 1, 2 or 3

	-- starting Saitek Multi Panel Mode
	ipc.set('SMP_MODE', 0) -- 0: ALT, 1: VS, 2: IAS, 3: HDG, 4: CRS
	ipc.set('SMP_REAL_VALUE', isAutopilotAvailable ())
            -- 0: ALT, 1: VS, 2: IAS, 3: HDG, 4: CRS

	-- Starting knob modes
	MINSmode = "A"
	BAROmode = "A"
	CTRmode = "A"
	TFCmode = "A"
	NDMmode = "A"
	NDRmode = "A"

	CRSmode = "A"
	SPDmode = "A"
	HDGmode = "A"
	ALTmode = "A"
	VVSmode = "A"

	baro_mode = 0 	-- initial borometer mode hPa
	baro_cur = 0		-- current baro
	fast_baro = 32 	-- fast rotation increment

	-- Display mode
	-- 1: autopilot
	-- 2: current flight information
	ipc.set("DSPmode", 1)

    ipc.set('DSPmode', ipc.get('VRI_MODE'))
    DSP_MODE_set()

	ipc.set("FIP", 0)

	-- counter for DSP auto-clear feature
	dsp_count = 0
	 -- vars to save previous DSP state for auto-clear feature
	dsp0_prev = ""
	dsp1_prev = ""

	math.randomseed( os.time() )

	ipc.set("APlock", 0)

	-- Joystick init
	hidinit = false
	jdev = {}
	rd = {}
	wrf = {}
	wr = {}
	init1 = {}
	CurrentData = {}
	n = {}
	jcount = 1
	buttons = {}
	prevbuttons = {}
	newval = {}
	prevval = {}

	--J={}  -- caused problem in Events

	JSTK={}
	JSTKrp={}
	JSTKrl={}

	JSTK2={}
	JSTK2rp={}
	JSTK2rl={}

	JSTK3={}
	JSTK3rp={}
	JSTK3rl={}

	JREP={} -- repeating functions
    JREPc={} -- repeat count limiter

	JDEVID={}

	JVID={} -- device vendor ID
	JPID={} -- device product ID

	JHATS={} -- hats HEX identifiers

	SHIFT_GLOB = 0
	SHIFT_MODE = 0
	SHIFT_LOC = {}
    SHIFT_LIM = {}

	-- keypress tables init
	KeyPressInit ()

	HUNTER = true
end

-----------------------------------------------------------------

-- ## SYSTEM FUNCTIONS ###############

-- functions switcher
function switch (command, actions, group, knob_command)
	if command == nil then return false end
	_logggg('[COMM] Cmd = ' .. tostring(command));

    local f = actions [command]

    _logggg('[COMM] SWITCH ' .. tostring(type(f)) ..
        ', C=' .. tostring(command) ..
        ', A=' .. tostring(actions) ..
        ', G=' .. tostring(group) ..
        ', K=' .. tostring(knob_command))

    if type (f) ~= "function" then
		if f == nil then return false end
		if string.find(f, "Keys:") ~= nil then
			KeyPress (string.sub(f, 7))
			return true
		end
		if string.find(f, "Control:") ~= nil then
			FSXcontrol (string.sub(f, 10))
			return
		end
		if string.find(f, "FSX:") ~= nil then
			FSXcontrolName (string.sub(f, 6))
			return
		end
		if string.sub(f, 1, 2) == "M:" then
			FSUIPCmacro (string.sub(f, 4))
			return
		end
		return false

	else -- handle functions
        _logggg('[COMM] Function cmd=' .. tostring(command) .. ' gp=' .. tostring(group) ..
            ' knob=' .. tostring(knob_command))
        f (command, group, knob_command)
		return true
	end -- if
end -- switch

-----------------------------------------------------------------

-- rounds the integer
function round(num)
	num = tonumber(num)
	if num == nil then return 0 end
	if num >= 0 then return math.floor(num+.5)
	else return math.ceil(num-.5) end
end

-----------------------------------------------------------------

-- rounds to n decimal places
function round2 (num, idp)
  num = tonumber(num)
  if num == nil then return 0 end
  local mult = 10^(idp or 0)
  return math.floor(num * mult + 0.5) / mult
end

-----------------------------------------------------------------

function ZeroString (s)
	if string.find(s, string.char(0)) == nil then
		return s
	else
		return string.sub(s, 1, string.find(s, string.char(0)) - 1)
	end
end

-----------------------------------------------------------------

function strFreq (frequency)
	return string.format("1%02X.%02X", math.floor(frequency / 256),
		math.mod(frequency, 256))
end

-----------------------------------------------------------------

-- error log
function _err (s)
	ipc.log("LINDA:: ---> ERROR:: " .. s)
end

-----------------------------------------------------------------

-- debug level 1 - standard
function _log (s)
	if ipc.get("DEBUG") > 0 then ipc.log("LINDA:: " .. s) end
end

-----------------------------------------------------------------

-- debug level 2 - detailed
function _logg (s)
	if ipc.get("DEBUG") > 1 then ipc.log("LINDA:: " .. s) end
end

-----------------------------------------------------------------

-- debug level 3 - verbose
function _loggg (s)
	if ipc.get("DEBUG") > 2 then ipc.log("LINDA:: " .. s) end
end

-----------------------------------------------------------------

-- debug level 4 - DEBUG
function _logggg (s)
	if ipc.get("DEBUG") > 3 then ipc.log("LINDA:: " .. s) end
end

-----------------------------------------------------------------

function _logf (func, command)
	if ipc.get("DEBUG") > 0 then
		ipc.log("[COMM] function call: " .. func .. "/" .. tostring(command))
	end
end

-----------------------------------------------------------------

function _logff (func, command)
	if ipc.get("DEBUG") > 1 then
		ipc.log("[COMM] function call: " .. func .. "/" .. tostring(command))
	end
end

-----------------------------------------------------------------

-- returns the 'basename' and the 'basedir'
function getBase(filename)
	return  string.gsub(filename, "(.*/)(.*)", "%2") or filename
end

-----------------------------------------------------------------

-- check file exist
function file_exists(name)
    if name == nil then
        _loggg('[COMM] Check File Exists NIL')
        return false
    end
    _loggg('[COMM] Check File Exists "' .. name .. '"')
    local f = io.open(name,"r")
    if f~=nil then
        io.close(f)
        _loggg('[COMM] File "' .. name .. '" found.')
        return true
    else
        _loggg('[COMM] File "' .. name .. '" not found.')
        return false
    end
end

-----------------------------------------------------------------

function Hex2Bin(s)
	local hex2bin = {
		["0"] = "0000",
		["1"] = "0001",
		["2"] = "0010",
		["3"] = "0011",
		["4"] = "0100",
		["5"] = "0101",
		["6"] = "0110",
		["7"] = "0111",
		["8"] = "1000",
		["9"] = "1001",
		["a"] = "1010",
		["b"] = "1011",
		["c"] = "1100",
		["d"] = "1101",
		["e"] = "1110",
		["f"] = "1111"
		}
	-- s	-> hexadecimal string
	local ret = ""
	local i = 0
	for i in string.gfind(s, ".") do
		i = string.lower(i)
		ret = ret..hex2bin[i]
	end
	return ret
end

-----------------------------------------------------------------

function HexToStr (s)
local ret = ""
    ret = string.format("%X", s)
    while string.len(ret) < 4 do
        ret = "0" .. ret
    end
    _logggg('[COMM] HexToStr ' .. ret)
    return ret
end

-----------------------------------------------------------------
-- not tested
function StrToHex (s)
local ret = ""
local n
    _loggg('[COMM] s = ' .. s)
    n = tonumber(s)
    _loggg('[COMM] n = ' .. n)
    ret = string.format("%X", n)
    _loggg('[COMM] StrToHex ' .. n .. ' ' .. ret)
    return ret
end

-----------------------------------------------------------------

-- string split
function split(str, pat)
   str = tostring(str)
   local t = {}  -- NOTE: use {n = 0} in Lua-5.0
   local fpat = "(.-)" .. pat
   local last_end = 1
   local s, e, cap = str:find(fpat, 1)
   while s do
	  if s ~= 1 or cap ~= "" then
	  table.insert(t,cap)
	  end
	  last_end = e+1
	  s, e, cap = str:find(fpat, last_end)
   end
   if last_end <= #str then
	  cap = str:sub(last_end)
	  table.insert(t, cap)
   end
   return t
end

-----------------------------------------------------------------

-- table entries counter
function tablelength(T)
  local count = 0
  for _ in pairs(T) do count = count + 1 end
  return count
end

-----------------------------------------------------------------

-- random sleep
function _sleep(from, to)
	if to ~= nil then
		ipc.sleep(math.random(from, to))
	else
		ipc.sleep(from)
	end
end

-----------------------------------------------------------------

-- universal toggler for any actions
function _t (command)
	if tgl[command] == nil then
		tgl[command] = true
		return true
	end
	tgl[command] = nil
	return false
end

-----------------------------------------------------------------

-- universal toggler by LVar
function _tt (lvar, compare)
	if compare == nil then compare = 0 end
	if ipc.readLvar(lvar) == compare then
		return true
	end
	return false
end

-----------------------------------------------------------------

-- universal toggler by LVar
function _tl (lvar, compare)
	return _tt (lvar, compare)
end

-----------------------------------------------------------------

-- universal toggler by value
function _tv (var, compare)
	if var == compare then
		return true
	end
	return false
end

-----------------------------------------------------------------

-- empty command handler -- DO NOT DELETE!
function empty (command, group)
	if group == "MCP" then
		_loggg("[COMM] MCP MODE " .. ipc.get("MCPmode") ..
            ": Empty command for :: " .. command)
	elseif group == "EFIS" then
		_loggg("[COMM] EFIS MODE " .. ipc.get("EFISmode") ..
            ": Empty command for :: " .. command)
	elseif group == "USER" then
		_loggg("[COMM] USER MODE " .. ipc.get("USERmode") ..
            ": Empty command for :: " .. command)
	elseif group == "RADIOS" then
		_loggg("[COMM] RADIOS : Empty command for :: " .. command)
	else
		_logggg("[COMM] Empty call for :: " .. command)
	end
end

-- $$ Sounds

function Sounds(fname, norm, vol)
-- norm = true - use LINDA sounds path
    local FSUIPCpath = ipc.get('PATH_USER')
    local ACpath = ipc.readSTR(0x3C00, 255)
    local FSpath = ipc.readSTR(0x3E00, 255)

    local soundpath = FSUIPCpath .. '\\linda\\data\\sounds\\'
    local soundvol = 100

    if FSUIPCPath ~= nil then
        if not file_exists(soundpath .. fname) then
            soundpath = FSpath .. 'sound\\'
        end

        _loggg('[COMM] sound=' .. soundpath .. ' f=' .. fname)
    end

    -- check and set volume
    if vol == false or vol == nil then
        soundvol = 100
    else
        if (vol >= 0 and vol <= 100) then
            soundvol = vol
        else
            soundvol = 100
        end
    end

    _loggg('[COMM] Sound Path = ' .. soundpath .. fname ..
        ' vol=' .. soundvol)

    sound.path (soundpath, 0, soundvol)
    ref = sound.play (fname)
end

-----------------------------------------------------------------

-- ## FlightSim functions ###############

function CurrentAirport ()
	local icao = ZeroString (ipc.readSTR(0x0658, 4))
	if icao == '' or icao == nil then icao = 'n/a' end
	return icao
end

function SaveFlight(filename)
	local plane = ZeroString (ipc.readSTR(0x3D00, 35))
	local airport = CurrentAirport ()
	-- flight save vars
	if filename == nil or filename == '' then
		filename = 'LINDA-' .. plane
	end
	_log('[COMM] AutoSave: ' .. filename)
	ShowMessage('' .. plane .. ' flight saved at/near ' .. airport)
	ipc.writeSTR(0x3F04, filename .. string.char(0))
	ipc.writeUW(0x3F00, 1)
	-- save the default flight also
	if AUTOSAVE_DEFAULT_FLIGHT == 1 then
		ipc.writeSTR(0x3F04, '_linda_default' .. string.char(0))
		ipc.writeUW(0x3F00, 1)
	end
	-- save the default flight also
	if AUTOSAVE_PLANE_FLIGHT == 1 then
		ipc.writeSTR(0x3F04, '_linda_lastpos_' .. plane .. string.char(0))
		ipc.writeUW(0x3F00, 1)
	end
	FLIGHT_SAVED = true
end

-----------------------------------------------------------------

function ShowMessage (text, cnt)
    if MSFS == 1 then return end
    if cnt == nil then cnt = 2 end
	if text == nil then text = 'Test message!' end
	ipc.writeSTR(0x3380, text .. string.char(0))
	ipc.writeUW(0x32FA, cnt)
end

-----------------------------------------------------------------

-- ## Device types ###############

-- Test for original MCP type
function _MCP1 ()
	if ipc.get("VRI_TYPE") == 'mcp' then
		return true
	else
		return false
	end
end

-----------------------------------------------------------------

-- Test for Boeing MCP type
function _MCP2 ()
	if ipc.get("VRI_TYPE") == 'mcp2' then
		return true
	else
		return false
	end
end

-----------------------------------------------------------------

-- Test for Airbus FCU type
function _MCP2a ()
	if ipc.get("VRI_TYPE") == 'mcp2a' then
		return true
	else
		return false
	end
end

-----------------------------------------------------------------

-- ## Special controls ##############

-- ### KeyPress sender ##############
function KeyPressInit ()
	MT = {}
	MT["-"] =                  0
	MT["Ctrl"] =               10
	MT["Alt"] =                16
	MT["Shift"] =              9
	MT["Ctrl+Alt"] =           18
	MT["Ctrl+Shift"] =         11
	MT["Shift+Alt"] =          17
	MT["Ctrl+Shift+Alt"] =     19

	KT = {}
	KT["Pause"] =              19
	KT["Escape"] =             27
	KT["PgUp"] =               33
	KT["PgDn"] =               34
	KT["End"] =                35
	KT["Home"] =               36
	KT["Left"] =               37
	KT["Up"] =                 38
	KT["Right"] =              39
	KT["Down"] =               40
	KT["PrintScreen"] =        44
	KT["Insert"] =             45
	KT["Delete"] =             46
	KT["0"] =                  48
	KT["1"] =                  49
	KT["2"] =                  50
	KT["3"] =                  51
	KT["4"] =                  52
	KT["5"] =                  53
	KT["6"] =                  54
	KT["7"] =                  55
	KT["8"] =                  56
	KT["9"] =                  57
	KT["A"] =                  65
	KT["B"] =                  66
	KT["C"] =                  67
	KT["D"] =                  68
	KT["E"] =                  69
	KT["F"] =                  70
	KT["G"] =                  71
	KT["H"] =                  72
	KT["I"] =                  73
	KT["J"] =                  74
	KT["K"] =                  75
	KT["L"] =                  76
	KT["M"] =                  77
	KT["N"] =                  78
	KT["O"] =                  79
	KT["P"] =                  80
	KT["Q"] =                  81
	KT["R"] =                  82
	KT["S"] =                  83
	KT["T"] =                  84
	KT["U"] =                  85
	KT["V"] =                  86
	KT["W"] =                  87
	KT["X"] =                  88
	KT["Y"] =                  89
	KT["Z"] =                  90
	KT["Num 0"] =              96
	KT["Num 1"] =              97
	KT["Num 2"] =              98
	KT["Num 3"] =              99
	KT["Num 4"] =             100
	KT["Num 5"] =             101
	KT["Num 6"] =             102
	KT["Num 7"] =             103
	KT["Num 8"] =             104
	KT["Num 9"] =             105
	KT["Num *"] =             106
	KT["Num +"] =             107
	KT["Num -"] =             109
	KT["Num ."] =             110
	KT["Num /"] =             111
	KT["F1"] =                112
	KT["F2"] =                113
	KT["F3"] =                114
	KT["F4"] =                115
	KT["F5"] =                116
	KT["F6"] =                117
	KT["F7"] =                118
	KT["F8"] =                119
	KT["F9"] =                120
	KT["F10"] =               121
	KT["F11"] =               122
	KT["F12"] =               123
	KT["F13"] =               124
	KT["F14"] =               125
	KT["F15"] =               126
	KT["F16"] =               127
	KT["F17"] =               128
	KT["F18"] =               129
	KT["F19"] =               130
	KT["F20"] =               131
	KT["F21"] =               132
	KT["F22"] =               133
	KT["F23"] =               134
	KT["Num Lock"] =          144
	KT["Scroll Lock"] =       145
	KT[";"] =                 186
	KT["="] =                 187
	KT[","] =                 188
	KT["-"] =                 189
	KT["."] =                 190
	KT["/"] =                 191
	KT["'"] =                 192
	KT["["] =                 219
	KT["\\"] =                220
	KT["]"] =                 221
	KT["#"] =                 222
	KT["`"] =                 223
end

-----------------------------------------------------------------

function KeyPress (shortcut)
	local modifiers = '-'
	local modcode = 0
	local kecode = 0
	if string.find(shortcut, '+') ~= nil then
		shortcut = string.reverse(shortcut)
		modifiers = string.sub(shortcut, string.find(shortcut, '+') + 1)
		modifiers = string.reverse(modifiers)
		shortcut = string.sub(shortcut, 1, string.find(shortcut, '+') - 1)
		shortcut = string.reverse(shortcut)
	end
	modcode = MT[modifiers]
	keycode = KT[shortcut]
	ipc.keypress(keycode, modcode)
	_loggg ("[COMM] Keypress: " .. modifiers .. " : " .. shortcut)
end

-----------------------------------------------------------------

function FSUIPCmacro (command)
--[[
	local param = 0
	if string.find(command, '#') then
		param = tonumber(string.sub(command, string.find(command, '#') + 2))
		command =  string.sub(command, 1, string.find(command, '#') - 1)
		if param == nil then param = 0 end
		ipc.macro(command, tonumber(param))
		return
	end
--]]

	ipc.macro(command)
	_loggg ('[COMM] FSUIPC Macro request: [' .. command .. ']')
end

-----------------------------------------------------------------


function FSXcontrol (control)
	_logggg("[COMM] FSX control: " .. tostring(control) .. "  param: "
		.. tostring(param))
	local param = string.sub(control, string.find(control, ':') + 1)
	control =  string.sub(control, 1, string.find(control, ':') - 1)
	param = tonumber(param)
	control = tonumber(control)
	if control > 0 then
		if control == 65733 then
			_err("FSX control 65733 (ABORT) called. Skipping...")
			return
		end
		ipc.control(control, param)
	end
end

-----------------------------------------------------------------

function FSXcontrolName (control)
	local param = string.sub(control, string.find(control, ':') + 1)
	control =  string.sub(control, 1, string.find(control, ':') - 1)
	_logggg("[COMM] FSX control by name: " .. control .. "  param: "
		.. tostring(param))
	param = tonumber(param)
	if type(_G['_' .. control]) == 'function' then
		_G['_' .. control](param)
	end
end

-----------------------------------------------------------------

-- ## COMMON FUNCTIONS ###############

function Default_LAMP_toggle()
	-- toggle panel lights
	ipc.control(65750,0)
end

-----------------------------------------------------------------

function Modes()
	local info = "M" .. tostring(ipc.get("EFISmode")) ..
	   tostring(ipc.get("MCPmode")) .. tostring(ipc.get("USERmode"))
	return info
end

-----------------------------------------------------------------
-- ## RADIOS COMMON ###############

-- awg saitek function start

function getCOMFrequency (which, stdby)
	if which == 1 then
		if stdby == false then
			return ipc.readUW(0x034E)
		else
			return ipc.readUW(0x311A)
		end
	else
		if stdby == false then
			return ipc.readUW(0x3118)
		else
			return ipc.readUW(0x311C)
		end
	end
end

-----------------------------------------------------------------

function getNAVFrequency (which, stdby)
	if which == 1 then
		if stdby == false then
			return ipc.readUW(0x0350)
		else
			return ipc.readUW(0x311E)
		end
	else
		if stdby == false then
			return ipc.readUW(0x0352)
		else
			return ipc.readUW(0x3120)
		end
	end
end

-- awg saitek function end

-----------------------------------------------------------------

function Default_RADIOS_press ()
	-- COM and NAV buttons
	if RADIOS_MODE == 1 or RADIOS_MODE == 2 then
		if RADIOS_MhzKhz == 1 then
			RADIOS_MhzKhz = 2
			ipc.sleep(50)
			com.write(dev, 'RADKhz', 8)
		else
			RADIOS_MhzKhz = 1
			ipc.sleep(50)
			com.write(dev, 'RADMhz', 8)
		end
	-- ADF button
	elseif RADIOS_MODE == 3 then
		RADIOS_CURSOR_POS = RADIOS_CURSOR_POS - 1
		if RADIOS_CURSOR_POS < 0 then RADIOS_CURSOR_POS = 3 end
		ipc.sleep(50)
		com.write(dev, 'RADA' .. tostring(RADIOS_CURSOR_POS), 8)
	-- DME button
	elseif RADIOS_MODE == 4 then
		-- Swap DME1 / DME2
		Default_DME_select ()
		-- Calling extended action
		switch ("PRESS", DME1, "RADIOS/DME")
		--[[
		if RADIOS_MODE == 1 then
			-- drop CRS1 to zero
			ipc.writeUW(0x0C4E, 0)
		else
			-- drop CRS2 to zero
			ipc.writeUW(0x0C5E, 0)
		end
		--]]
	-- TRN button
	elseif RADIOS_MODE == 5 then
		RADIOS_CURSOR_POS = RADIOS_CURSOR_POS - 1
		if RADIOS_CURSOR_POS < 0 then RADIOS_CURSOR_POS = 3 end
		ipc.sleep(50)
		com.write(dev, 'RADT' .. tostring(RADIOS_CURSOR_POS), 8)
	end
end

-----------------------------------------------------------------

function Default_RADIOS_swap ()
	local buffer_s, buffer_x, mhz, khz
	-- COM radio 8.33kHz
    if RADIOS_MODE == 0 then
		if RADIOS_SUBMODE == 1 then
			-- COM1
			Default_COM_1_swap ()
			buffer_x = string.format("%04x", ipc.readUW(0x034E))
			buffer_s = string.format("%04x", ipc.readUW(0x311A))
			ipc.sleep(20)
			com.write(dev, 'COMx' .. buffer_s, 8)
			ipc.sleep(20)
			com.write(dev, 'COMs' .. buffer_x, 8)
			switch ("COM1 Swap", RADIOS, "RADIOS")
		else
			-- COM2
			Default_COM_2_swap ()
			buffer_x = string.format("%04x", ipc.readUW(0x3118))
			buffer_s = string.format("%04x", ipc.readUW(0x311C))
			ipc.sleep(20)
			com.write(dev, 'COMX' .. buffer_s, 8)
			ipc.sleep(20)
			com.write(dev, 'COMS' .. buffer_x, 8)
			switch ("COM2 Swap", RADIOS, "RADIOS")
		end
		DspRadioMed('<->')
		com.write(dev, 'RADMhz', 8)
	elseif RADIOS_MODE == 1 then
		if RADIOS_SUBMODE == 1 then
			-- COM1
			Default_COM_1_swap ()
			buffer_x = string.format("%04x", ipc.readUW(0x034E))
			buffer_s = string.format("%04x", ipc.readUW(0x311A))
			ipc.sleep(20)
			com.write(dev, 'COMx' .. buffer_s, 8)
			ipc.sleep(20)
			com.write(dev, 'COMs' .. buffer_x, 8)
			switch ("COM1 Swap", RADIOS, "RADIOS")
		else
			-- COM2
			Default_COM_2_swap ()
			buffer_x = string.format("%04x", ipc.readUW(0x3118))
			buffer_s = string.format("%04x", ipc.readUW(0x311C))
			ipc.sleep(20)
			com.write(dev, 'COMX' .. buffer_s, 8)
			ipc.sleep(20)
			com.write(dev, 'COMS' .. buffer_x, 8)
			switch ("COM2 Swap", RADIOS, "RADIOS")
		end
		DspRadioMed('<->')
		com.write(dev, 'RADMhz', 8)
	-- NAV
	elseif RADIOS_MODE == 2 then
		if RADIOS_SUBMODE == 1 then
			-- NAV1
			Default_NAV_1_swap ()
			buffer_x = string.format("%04x", ipc.readUW(0x0350))
			buffer_s = string.format("%04x", ipc.readUW(0x311E))
			ipc.sleep(20)
			com.write(dev, 'NAVx' .. buffer_s, 8)
			ipc.sleep(20)
			com.write(dev, 'NAVs' .. buffer_x, 8)
			switch ("NAV1 Swap", RADIOS, "RADIOS")
		else
		   -- NAV2
			Default_NAV_2_swap ()
			buffer_x = string.format("%04x", ipc.readUW(0x0352))
			buffer_s = string.format("%04x", ipc.readUW(0x3120))
			ipc.sleep(20)
			com.write(dev, 'NAVX' .. buffer_s, 8)
			ipc.sleep(20)
			com.write(dev, 'NAVS' .. buffer_x, 8)
			switch ("NAV2 Swap", RADIOS, "RADIOS")
		end
		DspRadioMed('<->')
		com.write(dev, 'RADMhz', 8)
	-- ADF
	elseif RADIOS_MODE == 3 then
		if RADIOS_SUBMODE == 1 then
			-- ADF1
			switch ("ADF1 Swap", RADIOS, "RADIOS")
		else
		   -- ADF2
			switch ("ADF2 Swap", RADIOS, "RADIOS")
		end
		DspRadioMed('<->')
	-- DME
	elseif RADIOS_MODE == 4 then  -- do nothing
	-- TRN
	elseif RADIOS_MODE == 5 then
		Default_XPND_set (RADIOS_XPND_CODE)
		switch ("XPND Swap", RADIOS, "RADIOS")
	end
end

-----------------------------------------------------------------

function Default_RADIOS_mode ()
	if RADIOS_MODE == 0 or RADIOS_MODE == 1 then
		switch ("COMs Mode", RADIOS, "RADIOS")
	elseif RADIOS_MODE == 2 then
		switch ("NAVs Mode", RADIOS, "RADIOS")
	elseif RADIOS_MODE == 3 then
		switch ("ADFs Mode", RADIOS, "RADIOS")
	elseif RADIOS_MODE == 4 then
		switch ("DMEs Mode", RADIOS, "RADIOS")
	elseif RADIOS_MODE == 5 then
		switch ("XPND Mode", RADIOS, "RADIOS")
	end
end

-----------------------------------------------------------------

-- Default DME rotaty functons
function Default_RADIOS_plus (skip)
    _logggg('[COMM] Default Radios plus')
	if RADIOS_MODE == 0 or RADIOS_MODE == 1 then
		Default_NAVCOM_plus (0)
	elseif RADIOS_MODE == 2 then
		Default_NAVCOM_plus (1)
	elseif RADIOS_MODE == 3 then
		Default_ADF_plus ()
	elseif RADIOS_MODE == 4 then
		Default_DME_plus (false)
		-- Calling extended action
		switch ("A  +", DME1, "RADIOS/DME")
	elseif RADIOS_MODE == 5 then
		Default_XPND_plus ()
	end
	if skip ~= nil then FREfast = 0 end
end

-----------------------------------------------------------------

function Default_RADIOS_plusfast ()
    _logggg('[COMM] Default Radios plusfast')
	FREfast = FREfast + 1
	if FREfast > 2 then
		Default_RADIOS_plus (1)
		return
	end
	if RADIOS_MODE == 0 or RADIOS_MODE == 1 then
		Default_NAVCOM_plus (0)
	elseif RADIOS_MODE == 2 then
		Default_NAVCOM_plus (1)
	elseif RADIOS_MODE == 3 then
		Default_ADF_plus ()
	elseif RADIOS_MODE == 4 then
		Default_DME_plus (true)
		-- Calling extended action
		switch ("A ++", DME1, "RADIOS/DME")
	elseif RADIOS_MODE == 5 then
		Default_XPND_plus ()
	end
end

-----------------------------------------------------------------

function Default_RADIOS_minus (skip)
    _logggg('[COMM] Default Radios minus')
	if RADIOS_MODE == 0 or RADIOS_MODE == 1 then
		Default_NAVCOM_minus (0)
	elseif RADIOS_MODE == 2 then
		Default_NAVCOM_minus (1)
	elseif RADIOS_MODE == 3 then
		Default_ADF_minus ()
	elseif RADIOS_MODE == 4 then
		Default_DME_minus (false)
		-- Calling extended action
		switch ("A  -", DME1, "RADIOS/DME")
	elseif RADIOS_MODE == 5 then
		Default_XPND_minus ()
	end
	if skip ~= nil then FREfast = 0 end
end

-----------------------------------------------------------------

function Default_RADIOS_minusfast ()
    _logggg('[COMM] Default Radios minusfast')
	FREfast = FREfast + 1
	if FREfast > 2 then
		Default_RADIOS_minus (1)
		return
	end
	if RADIOS_MODE == 0 or RADIOS_MODE == 1 then
		Default_NAVCOM_minus (0)
	elseif RADIOS_MODE == 2 then
		Default_NAVCOM_minus (1)
	elseif RADIOS_MODE == 3 then
		Default_ADF_minus ()
	elseif RADIOS_MODE == 4 then
		Default_DME_minus (true)
		-- Calling extended action
		switch ("A --", DME1, "RADIOS/DME")
	elseif RADIOS_MODE == 5 then
		Default_XPND_minus ()
	end
end

-----------------------------------------------------------------

-- ## DME ##############

function getDMEDistance (which)
	if which == 1 then
		return ipc.readUW(0x0300)
	else
		if ipc.get("SRP_DME_STDBY") == 0 then
            return ipc.readUW(0x0302)
        else
            return ipc.readUW(0x0304) end
	end
end

-----------------------------------------------------------------

function Default_DME_select ()
	if RADIOS_MODE ~= 4 then   -- not DME mode
		RADIOS_SUBMODE = 2     -- temporarily set DME2
	end
	dme_ident_tmp = 0 -- re-check DME ident on|off
	RADIOS_MODE = 4 -- change to DME mode
    -- allow DME ID and range to display
    RADIOS_MSG = false
    RADIOS_MSG_SHORT = false
	if RADIOS_SUBMODE == 2 then-- swap to DME1
		ipc.sleep(50)
		com.write(dev, "DMExxxxx", 8)
		Default_DME_1_init (true)
		RADIOS_SUBMODE = 1
		switch ("DME1 Select", RADIOS, "RADIOS")
	else  -- swap to DME2
		ipc.sleep(50)
		com.write(dev, "DMEXXXXX", 8)
		Default_DME_2_init (true)
		RADIOS_SUBMODE = 2
		switch ("DME2 Select", RADIOS, "RADIOS")
	end
    _loggg('[COMM] Def_DME_select ' .. RADIOS_SUBMODE)
end

-----------------------------------------------------------------

function Default_DME_set (s)
	s = tonumber(string.sub(s, 1, 3))
	_loggg("[COMM] SetDME " .. dme_sel .. " : " .. s)
	if dme_sel == 1 then
		ipc.writeUW(0x0C4E, s)
	else
		ipc.writeUW(0x0C5E, s)
	end
end

-----------------------------------------------------------------

-- test function to test radio/ap status indicators
function Default_DME_ILS ()
	local val = ipc.readUW(0x3300)
end

-----------------------------------------------------------------

function Default_DME_1_init (timer)
	if dev == 0 then return end
	local vor_name1 = string.format("%s", ipc.readSTR(0x3000, 5))
	while string.len(vor_name1) < 5 do vor_name1 = ' ' .. vor_name1 end
	RADIOS_DME_CRS1 = ipc.readUW(0x0C4E)
	if not RADIOS_MSG_SHORT then
		com.write(dev, "dsp0DME\\", 8)
		ipc.sleep(20)
	end
	local vor_crs1 = string.format("%003d", RADIOS_DME_CRS1)
	if vor_name1 ~= "     " then
		local vor_distance1 = tonumber(ipc.readUW(0x0300))
		local vor_speed1 = tonumber(ipc.readUW(0x0302)) / 10
		vor_distance1 = string.format("DMEd%04d", vor_distance1)
		vor_speed1 = string.format("DMEs%03d", vor_speed1)
		if (_MCP2 () or _MCP2a()) then
			-- check if ident is on
			if logic.And(ipc.readUB(0x3122), 2) == 2 then
				DspRadioIdent_on ()
			else
				DspRadioIdent_off ()
			end
            if not RADIOS_MSG_SHORT then
                while string.len(vor_name1) < 8 do
                    vor_name1 = "\\" .. vor_name1
                end
                com.write(dev, "dsp1" .. string.sub(vor_name1, 1, 4), 8)
                ipc.sleep(50)
                com.write(dev, "dsp2" .. string.sub(vor_name1, 5, 8), 8)
                ipc.sleep(50)
                if OBS1 == 999 then
                    com.write(dev, "dsp3/" .. vor_crs1, 8)
                    ipc.sleep(50)
                elseif not timer then
                    if OBS1 ~= nil then
                        com.write(dev, "dsp3/" .. string.format("%003d", OBS1), 8)
                        ipc.sleep(50)
                    end
                end
			end
		else
			com.write(dev, "DMi" .. vor_name1 , 8)
		end
		com.write(dev, vor_distance1, 8)
		ipc.sleep(50)
		com.write(dev, vor_speed1, 8)
		ipc.sleep(50)
	else
		--_loggg('[COMM] DME1-OBS init: ' .. OBS1 .. '/' .. vor_crs1)
        if RADIOS_MSG_SHORT then
            if OBS1 == 999 then
                com.write(dev, "dsp2  --", 8)
                ipc.sleep(50)
                com.write(dev, "dsp3/" .. vor_crs1, 8)
                ipc.sleep(50)
            elseif not timer then
                com.write(dev, "dsp2  --", 8)
                ipc.sleep(50)
                if OBS1 ~= nil then
                    com.write(dev, "dsp3/" .. string.format("%003d", OBS1), 8)
                    ipc.sleep(50)
                end
            end
		end
	end
	-- audio ident check
	local n = ipc.readUB(0x3122)
	if logic.And(n, 2) == 2 and dme_ident_tmp ~= 2 then
		DspRadioIdent_on ()
		dme_ident_tmp = logic.And(n, 2)
	end
	dme_sel = 1
	dme_open = 1
	com_open = 0
	nav_open = 0
end

-----------------------------------------------------------------

function Default_DME_2_init (upd)
	if dev == 0 then return end
	local vor_name2 = string.format("%s", ipc.readSTR(0x301F, 5))
	while string.len(vor_name2) < 5 do vor_name2 = ' ' .. vor_name2 end
	RADIOS_DME_CRS2 = ipc.readUW(0x0C5E)
	if not RADIOS_MSG_SHORT then
		com.write(dev, "dsp0DME\\", 8)
		ipc.sleep(20)
	end
	local vor_crs2 = string.format("%003d", RADIOS_DME_CRS2)
	--_loggg("[COMM] VOR2 >" ..vor_name2 .. "< OBS2=" .. OBS2 ..
    --    ' CRS2=' .. vor_crs2)
	if vor_name2 ~= "     " then
		local vor_distance2 = tonumber(ipc.readUW(0x0306))
		local vor_speed2 = tonumber(ipc.readUW(0x0308)) / 10
		vor_distance2 = string.format("DMED%04d", vor_distance2)
		vor_speed2 = string.format("DMES%03d ", vor_speed2)
		if (_MCP2 () or _MCP2a()) then
			-- check if ident is on
			if logic.And(ipc.readUB(0x3122), 2) == 2 then
				DspRadioIdent_on ()
			else
				DspRadioIdent_off ()
			end
			while string.len(vor_name2) < 8 do
                vor_name2 = " " .. vor_name2 end
            if not RADIOS_MSG_SHORT then
                com.write(dev, "dsp1" .. string.sub(vor_name2, 1, 4), 8)
                ipc.sleep(50)
                com.write(dev, "dsp2" .. string.sub(vor_name2, 5, 8), 8)
                ipc.sleep(50)
                if OBS2 == 999 then
                    com.write(dev, "dsp3/" .. vor_crs2, 8)
                    ipc.sleep(50)
                elseif not timer then
                    com.write(dev, "dsp3/" .. string.format("%003d", OBS2), 8)
				    ipc.sleep(50)
                end
			end
		else
			com.write(dev, "DMI" .. vor_name2 , 8)
		end
		com.write(dev, vor_distance2, 8)
		ipc.sleep(50)
		com.write(dev, vor_speed2, 8)
		ipc.sleep(50)
	else
        if not RADIOS_MSG_SHORT then
            if OBS2 == 999 then
                com.write(dev, "dsp2  --", 8)
                ipc.sleep(50)
                com.write(dev, "dsp3/" .. vor_crs2, 8)
                ipc.sleep(50)
            elseif not timer then
                com.write(dev, "dsp2  --", 8)
                ipc.sleep(50)
                com.write(dev, "dsp3/" .. string.format("%003d", OBS2), 8)
                ipc.sleep(50)
            end
		end
	end
	-- audio ident check
	local n = ipc.readUB(0x3122)
	if logic.And(n, 2) == 2 and dme_ident_tmp ~= 2 then
		DspRadioIdent_on ()
		dme_ident_tmp = logic.And(n, 2)
	end
	dme_sel = 2
	dme_open = 2
	com_open = 0
	nav_open = 0
end

-----------------------------------------------------------------

function Default_DME_plus (fast)
	local crs
	if RADIOS_SUBMODE == 1 then
		crs = RADIOS_DME_CRS1
	else
		crs = RADIOS_DME_CRS2
	end
	if fast then
		crs = crs + 10
	else
		crs = crs + 1
	end
	if crs > 359 then crs = crs - 360  end
	local dme = string.format("%003d", crs)
	Default_DME_set (dme)
	-- com.write(dev, "dsp0CRS\\", 8)
	-- ipc.sleep(20)
	--RADIOS_MSG = true       -- need for restore "DME1" string with little pause
	--RADIOS_MSG_SHORT = true --
	--ipc.set("FIP2", ipc.elapsedtime())
	if RadiosAutoDisplay then DspDME(dme) end
	if RADIOS_SUBMODE == 1 then
		RADIOS_DME_CRS1 = crs
	else
		RADIOS_DME_CRS2 = crs
	end
end

-----------------------------------------------------------------

function Default_DME_minus (fast)
	local crs
	if RADIOS_SUBMODE == 1 then
		crs = RADIOS_DME_CRS1
	else
		crs = RADIOS_DME_CRS2
	end
	if fast then
		crs = crs - 10
	else
		crs = crs - 1
	end
	if crs < 0 then crs = 360 + crs end
	local dme = string.format("%003d", crs)
	Default_DME_set (dme)
	-- com.write(dev, "dsp0CRS\\", 8)
	-- ipc.sleep(20)
	--RADIOS_MSG = true         -- need for restore "DME1" string with little pause
	--RADIOS_MSG_SHORT = true   --
	--ipc.set("FIP2", ipc.elapsedtime())
	if RadiosAutoDisplay then DspDME(dme) end
	if RADIOS_SUBMODE == 1 then
		RADIOS_DME_CRS1 = crs
	else
		RADIOS_DME_CRS2 = crs
	end
end

-----------------------------------------------------------------

-- ## ADF ##############

function getADFFrequency (which)
	if which == 1 then
		buffer = ipc.readUW(0x034C)
		buffer2 = ipc.readUW(0x0356)
		-- _log(buffer .. " " .. buffer2 .. " | " .. string.format("%01x", (buffer2 / 256)) .. " | " .. string.format("%03x", buffer) .. " | " .. string.format("%01x", (buffer2 % 0x0100)))
		return string.format("%01x%03x.%01x", (buffer2 / 256),
            buffer, (buffer2 % 0x0100))
	else
		buffer = ipc.readUW(0x02D4)
		buffer2 = ipc.readUW(0x02D6)
		return string.format("%01x%03x.%01x", (buffer2 / 256),
            buffer, (buffer2 % 0x0100))
	end
end

-----------------------------------------------------------------

function Default_ADF_select ()
	if RADIOS_MODE ~= 3 then
		RADIOS_SUBMODE = 2
	end
	RADIOS_MODE = 3 -- ADF
	if RADIOS_SUBMODE == 2 then
		ipc.sleep(50)
		com.write(dev, "adfxxxxx", 8)
		Default_ADF_1_init (true)
		RADIOS_SUBMODE = 1
		switch ("ADF1 Select", RADIOS, "RADIOS")
	else
		ipc.sleep(50)
		com.write(dev, "ADFXXXXX", 8)
		Default_ADF_2_init (true)
		RADIOS_SUBMODE = 2
		switch ("ADF2 Select", RADIOS, "RADIOS")
	end
	ipc.sleep(50)
end

-----------------------------------------------------------------

function Default_ADF_set (s)
	freq1 = tonumber(string.sub(s, 2, 4), 16)
	freq2 = tonumber(string.sub(s, 1, 1) .. "0"
		.. string.sub(s, 5, 5), 16)
	if adf_sel == 1 then
		ipc.writeUW(0x034C, freq1)
		ipc.writeUW(0x0356, freq2)
	else
		ipc.writeUW(0x02D4, freq1)
		ipc.writeUW(0x02D6, freq2)
	end
end

-----------------------------------------------------------------

function Default_ADF_1_init (upd)
	if dev == 0 then return end
	if upd == nil then upd = false end
	if upd or adf1_firstload then
		ipc.sleep(100)
		buffer = ipc.readUW(0x034C)
		buffer2 = ipc.readUW(0x0356)
		RADIOS_ADF_FREQ1 = string.format("%01x%03x%01x",
			buffer2/256, buffer, buffer2 % 0x0100)
		com.write(dev, 'adf' .. RADIOS_ADF_FREQ1, 8)
		adf1_firstload = false
		-- audio ident check
		local n = ipc.readUB(0x3122)
		if logic.And(n, 1) == 1 then
			DspRadioIdent_on ()
		end
	end
	adf_sel = 1
	dme_open = 0
	com_open = 0
	nav_open = 0
end

-----------------------------------------------------------------

function Default_ADF_2_init (upd)
	if dev == 0 then return end
	if upd == nil then upd = false end
	if upd or adf2_firstload then
		ipc.sleep(100)
		buffer = ipc.readUW(0x02D4)
		buffer2 = ipc.readUW(0x02D6)
		RADIOS_ADF_FREQ2 = string.format("%01x%03x%01x",
			buffer2/256, buffer, buffer2 % 0x0100)
		com.write(dev, 'ADF' .. RADIOS_ADF_FREQ2, 8)
		adf2_firstload = false
		-- audio ident check
		if ipc.readUB(0x02FB) == 1 then
			DspRadioIdent_on ()
		end
	end
	adf_sel = 2
	dme_open = 0
	com_open = 0
	nav_open = 0
end

-----------------------------------------------------------------

function Default_ADF_plus ()
	local d, freq
	local first
	if RADIOS_SUBMODE == 1 then
		freq = RADIOS_ADF_FREQ1
	else
		freq = RADIOS_ADF_FREQ2
	end
	first = tonumber(string.sub(freq, 1, 1))
	if RADIOS_CURSOR_POS == 3 then
		d = tonumber(string.sub(freq, 2, 2)) + 1
		if first == 0 and d > 9 then
			first = 1
			d = 0
		end
		if first == 1 and d > 7 then
			first = 0
			d = 1
		end
		freq = tostring(first) .. tostring(d) .. string.sub(freq, 3)
	elseif RADIOS_CURSOR_POS == 2 then
		d = tonumber(string.sub(freq, 3, 3)) + 1
		if d > 9 then d = 0 end
		freq = string.sub(freq, 1, 2) .. tostring(d) .. string.sub(freq, 4)
	elseif RADIOS_CURSOR_POS == 1 then
		d = tonumber(string.sub(freq, 4, 4)) + 1
		if d > 9 then d = 0 end
		freq = string.sub(freq, 1, 3) .. tostring(d) .. string.sub(freq, 5)
	elseif RADIOS_CURSOR_POS == 0 then
		d = tonumber(string.sub(freq, 5, 5)) + 1
		if d > 9 then d = 0 end
		freq = string.sub(freq, 1, 4) .. tostring(d)
	end
	if RADIOS_SUBMODE == 1 then
		RADIOS_ADF_FREQ1 = freq
		ipc.sleep(50)
		com.write(dev, "adf" .. freq, 8)
	else
		RADIOS_ADF_FREQ2 = freq
		ipc.sleep(50)
		com.write(dev, "ADF" .. freq, 8)
	end
	ipc.sleep(50)
	com.write(dev, "RADA" .. RADIOS_CURSOR_POS, 8)
	Default_ADF_set (freq)
end

-----------------------------------------------------------------

function Default_ADF_minus ()
	local d, freq
	local first
	if RADIOS_SUBMODE == 1 then
		freq = RADIOS_ADF_FREQ1
	else
		freq = RADIOS_ADF_FREQ2
	end
	first = tonumber(string.sub(freq, 1, 1))
	if RADIOS_CURSOR_POS == 3 then
		d = tonumber(string.sub(freq, 2, 2)) - 1
		if first == 0 and d < 1 then
			first = 1
			d = 7
		end
		if first == 1 and d < 0 then
			first = 0
			d = 9
		end
		freq = tostring(first) .. tostring(d) .. string.sub(freq, 3)
	elseif RADIOS_CURSOR_POS == 2 then
		d = tonumber(string.sub(freq, 3, 3)) - 1
		if d < 0 then d = 9 end
		freq = string.sub(freq, 1, 2) .. tostring(d) .. string.sub(freq, 4)
	elseif RADIOS_CURSOR_POS == 1 then
		d = tonumber(string.sub(freq, 4, 4)) - 1
		if d < 0 then d = 9 end
		freq = string.sub(freq, 1, 3) .. tostring(d) .. string.sub(freq, 5)
	elseif RADIOS_CURSOR_POS == 0 then
		d = tonumber(string.sub(freq, 5, 5)) - 1
		if d < 0 then d = 9 end
		freq = string.sub(freq, 1, 4) .. tostring(d)
	end
	if RADIOS_SUBMODE == 1 then
		RADIOS_ADF_FREQ1 = freq
		ipc.sleep(50)
		com.write(dev, "adf" .. freq, 8)
	else
		RADIOS_ADF_FREQ2 = freq
		ipc.sleep(50)
		com.write(dev, "ADF" .. freq, 8)
	end
	ipc.sleep(50)
	com.write(dev, "RADA" .. RADIOS_CURSOR_POS, 8)
	Default_ADF_set (freq)
end

-----------------------------------------------------------------

-- ## NAV ##############

function Default_NAV_select ()
	if RADIOS_MODE ~= 2 then
		RADIOS_SUBMODE = 2
	end
	RADIOS_MODE = 2 -- COM
	RADIOS_MhzKhz = 1 -- Mhz
	ipc.sleep(50)
	com.write(dev, "NAVi", 8)
	if RADIOS_SUBMODE == 2 then
		Default_NAV_1_init (true)
		RADIOS_SUBMODE = 1
		switch ("NAV1 Select", RADIOS, "RADIOS")
	else
		Default_NAV_2_init (true)
		RADIOS_SUBMODE = 2
		switch ("NAV2 Select", RADIOS, "RADIOS")
	end
	ipc.sleep(50)
	com.write(dev, 'RADMhz', 8)
end

-----------------------------------------------------------------

function Default_NAV_1_set (s)
	nav1s_freq = tonumber(s,16)
	ipc.writeUD(0x311E, nav1s_freq)
end

-----------------------------------------------------------------

function Default_NAV_2_set (s)
	nav2s_freq = tonumber(s,16)
	ipc.writeUD(0x3120, nav2s_freq)
end

-----------------------------------------------------------------

function Default_NAV_1_swap (s)
	ipc.control(66448)
	local tmp = nav1s_freq
	nav1s_freq = nav1x_freq
	nav1x_freq = tmp
end

-----------------------------------------------------------------

function Default_NAV_2_swap (s)
	ipc.control(66452)
	local tmp = nav2s_freq
	nav2s_freq = nav2x_freq
	nav2x_freq = tmp
end

-----------------------------------------------------------------

function Default_NAV_1_init (upd)
	if dev == 0 then return end
	if upd == nil then upd = false end
	local buffer_x = ipc.readUW(0x0350)
	local buffer_s = ipc.readUW(0x311E)
	if upd or nav1_firstload or nav1s_freq ~= buffer_s
        or nav1x_freq ~= buffer_x then
		nav1x_freq = buffer_x
		nav1s_freq = buffer_s
		ipc.sleep(50)
		com.write(dev, string.format("NAVx%04x", buffer_x), 8)
		ipc.sleep(50)
		com.write(dev, string.format("NAVs%04x", buffer_s), 8)
		nav1_firstload = false
		-- audio ident check
		local n = ipc.readUB(0x3122)
		if logic.And(n, 16) == 16 then
			DspRadioIdent_on ()
		end
	end
	nav_sel = 1
	dme_open = 0
	com_open = 0
	nav_open = 1
	if RADIOS_MhzKhz ~= RADIOS_MhzKhz_prev then
		if RADIOS_MhzKhz == 1 then
			ipc.sleep(20)
			com.write(dev, 'RADMhz', 8)
		else
			ipc.sleep(20)
			com.write(dev, 'RADKhz', 8)
		end
	end
	RADIOS_MhzKhz_prev = RADIOS_MhzKhz
end

-----------------------------------------------------------------

function Default_NAV_2_init (upd)
	if dev == 0 then return end
	if upd == nil then upd = false end
	if nav2_firstload then ipc.sleep(200) end
	local buffer_x = ipc.readUW(0x0352)
	if nav2_firstload then ipc.sleep(200) end
	local buffer_s = ipc.readUW(0x3120)
	if buffer_s == 0 then buffer_s = 2048 end
	if upd or nav2_firstload or nav2s_freq ~= buffer_s
        or nav2x_freq ~= buffer_x then
		nav2x_freq = buffer_x
		nav2s_freq = buffer_s
		ipc.sleep(50)
		com.write(dev, string.format("NAVX%04x", buffer_x), 8)
		ipc.sleep(50)
		com.write(dev, string.format("NAVS%04x", buffer_s), 8)
		nav2_firstload = false
		-- audio ident check
		local n = ipc.readUB(0x3122)
		if logic.And(n, 8) == 8 then
			DspRadioIdent_on ()
		end
	end
	nav_sel = 2
	dme_open = 0
	com_open = 0
	nav_open = 2
	if RADIOS_MhzKhz ~= RADIOS_MhzKhz_prev then
		if RADIOS_MhzKhz == 1 then
			ipc.sleep(20)
			com.write(dev, 'RADMhz', 8)
		else
			ipc.sleep(20)
			com.write(dev, 'RADKhz', 8)
		end
	end
	RADIOS_MhzKhz_prev = RADIOS_MhzKhz
end

-----------------------------------------------------------------

function Default_NAVCOM_plus (nav)
	local buffer, cmd
	if nav == 0 then
		if RADIOS_SUBMODE == 1 then
			-- COM1
			buffer = string.format("%04x", ipc.readUW(0x311A))
			cmd = "COMs"
		else
			-- COM2
			buffer = string.format("%04x", ipc.readUW(0x311C))
			cmd = "COMS"
		end
	else
		if RADIOS_SUBMODE == 1 then
			-- NAV1
			buffer = string.format("%04x", ipc.readUW(0x311E))
			cmd = "NAVs"
		else
			-- NAV2
			buffer = string.format("%04x", ipc.readUW(0x3120))
			cmd = "NAVS"
		end
	end
	local mhz = tonumber(string.sub(buffer, 1, 2))
	local khz = tonumber(string.sub(buffer, 3, 4))
	if RADIOS_MhzKhz == 1 then
		mhz = mhz + 1
		if nav == 0 and mhz > 36 then mhz = 18 end
		if nav == 1 and mhz > 17 then mhz = 8 end
	else
		local m, mm
		m, mm = math.modf(khz / 5)
		if mm > 0 then
			khz = khz + 3
		else
			khz = khz + 2
		end
		if khz > 97 then khz = 0 end
	end
	local freq = string.format("%04d", round(mhz * 100 + khz))
    --_loggg('freq=' .. freq)
   	-- NAV/COM1
	ipc.sleep(20)
	com.write(dev, cmd .. freq, 8)
	if nav == 0 then
		if RADIOS_SUBMODE == 1 then
			Default_COM_1_set (freq)
		else
			Default_COM_2_set (freq)
		end
	else
		if RADIOS_SUBMODE == 1 then
			Default_NAV_1_set (freq)
		else
			Default_NAV_2_set (freq)
		end
	end
	ipc.set("FIP2", ipc.elapsedtime())
	RADIOS_MhzKhz_prev = -1
end

-----------------------------------------------------------------

function Default_NAVCOM_minus (nav)
	local buffer, cmd
	if nav == 0 then
		if RADIOS_SUBMODE == 1 then
			-- COM1
			buffer = string.format("%04x", ipc.readUW(0x311A))
			cmd = "COMs"
		else
			-- COM2
			buffer = string.format("%04x", ipc.readUW(0x311C))
			cmd = "COMS"
		end
	else
		if RADIOS_SUBMODE == 1 then
			-- NAV1
			buffer = string.format("%04x", ipc.readUW(0x311E))
			cmd = "NAVs"
		else
			-- NAV2
			buffer = string.format("%04x", ipc.readUW(0x3120))
			cmd = "NAVS"
		end
	end
	local mhz = tonumber(string.sub(buffer, 1, 2))
	local khz = tonumber(string.sub(buffer, 3, 4))
	if RADIOS_MhzKhz == 1 then
		mhz = mhz - 1
		if nav == 0 and mhz < 18 then mhz = 36 end
		if nav == 1 and mhz < 8 then mhz = 17 end
	else
		local m, mm
		m, mm = math.modf(khz / 5)
		if mm > 0 then
			khz = khz - 2
		else
			khz = khz - 3
		end
		if khz < 0 then khz = 97 end
	end
	local freq = string.format("%04d", round(mhz * 100 + khz))
	-- NAV/COM1
	ipc.sleep(20)
	com.write(dev, cmd .. freq, 8)
	if nav == 0 then
		if RADIOS_SUBMODE == 1 then
			Default_COM_1_set (freq)
		else
			Default_COM_2_set (freq)
		end
	else
		if RADIOS_SUBMODE == 1 then
			Default_NAV_1_set (freq)
		else
			Default_NAV_2_set (freq)
		end
	end
	ipc.set("FIP2", ipc.elapsedtime())
	RADIOS_MhzKhz_prev = -1
end

-----------------------------------------------------------------

-- ## COM ##############

function Default_COM_select ()
	if RADIOS_MODE ~= 1 then
		RADIOS_SUBMODE = 2
	end
	RADIOS_MODE = 1 -- COM
	RADIOS_MhzKhz = 1 -- Mhz
	ipc.sleep(50)
	com.write(dev, "COMi", 8)
	if RADIOS_SUBMODE == 2 then
		Default_COM_1_init (true)
		RADIOS_SUBMODE = 1
		switch ("COM1 Select", RADIOS, "RADIOS")
	else
		Default_COM_2_init (true)
		RADIOS_SUBMODE = 2
		switch ("COM2 Select", RADIOS, "RADIOS")
	end
	ipc.sleep(50)
	com.write(dev, 'RADMhz', 8)
end

-----------------------------------------------------------------

function Default_COM_1_set (s)
	com1s_freq = tonumber(s,16)
	ipc.control(66371, com1s_freq)
end

-----------------------------------------------------------------

function Default_COM_2_set (s)
	com2s_freq = tonumber(s,16)
	ipc.control(66443, com2s_freq)
end

-----------------------------------------------------------------

function Default_COM_1_swap ()
	ipc.control(66372)
	local tmp = com1s_freq
	com1s_freq = com1x_freq
	com1x_freq = tmp
end

-----------------------------------------------------------------

function Default_COM_2_swap ()
	ipc.control(66444)
	local tmp = com2s_freq
	com2s_freq = com2x_freq
	com2x_freq = tmp
end

-----------------------------------------------------------------

function Default_COM_1_init (upd)
	if dev == 0 then return end
	if upd == nil then upd = false end
	local buffer_x = ipc.readUW(0x034E)
	local buffer_s = ipc.readUW(0x311A)

    local buf_s = ipc.readUD(0x5CC)

    --_loggg('COM_s = ' .. string.format("%04x",buffer_s) ..
    --    ' <> ' .. string.format("%03.3f", buf_s/1000000))

	if upd or com1_firstload or com1s_freq ~= buffer_s
        or com1x_freq ~= buffer_x then
		com1x_freq = buffer_x
		com1s_freq = buffer_s
		-- _log(string.format("COMx%04x", buffer_x))
		ipc.sleep(50)
		com.write(dev, string.format("COMx%04x", buffer_x), 8)
		ipc.sleep(50)
		com.write(dev, string.format("COMs%04x", buffer_s), 8)
		com1_firstload = false
		-- audio ident check
		local n = ipc.readUB(0x3122)
		if logic.And(n, 128) == 128 then
			DspRadioIdent_on ()
		end
	end
	com_sel = 1
	dme_open = 0
	com_open = 1
	nav_open = 0
	if RADIOS_MhzKhz ~= RADIOS_MhzKhz_prev then
		if RADIOS_MhzKhz == 1 then
			ipc.sleep(20)
			com.write(dev, 'RADMhz', 8)
		else
			ipc.sleep(20)
			com.write(dev, 'RADKhz', 8)
		end
	end
	RADIOS_MhzKhz_prev = RADIOS_MhzKhz
end

-----------------------------------------------------------------

function Default_COM_2_init (upd)
	if dev == 0 then return end
	if upd == nil then upd = false end
	local buffer_x = ipc.readUW(0x3118)
	local buffer_s = ipc.readUW(0x311C)
	if upd or com2_firstload or com2s_freq ~= buffer_s
        or com2x_freq ~= buffer_x then
		com2x_freq = buffer_x
		com2s_freq = buffer_s
		ipc.sleep(50)
		com.write(dev, string.format("COMX%04x", buffer_x), 8)
		ipc.sleep(50)
		com.write(dev, string.format("COMS%04x", buffer_s), 8)
		com2_firstload = false
		-- audio ident check
		local n = ipc.readUB(0x3122)
		if logic.And(n, 64) == 64 then
			DspRadioIdent_on ()
		end
	end
	com_sel = 2
	dme_open = 0
	com_open = 2
	nav_open = 0
	if RADIOS_MhzKhz ~= RADIOS_MhzKhz_prev then
		if RADIOS_MhzKhz == 1 then
			ipc.sleep(20)
			com.write(dev, 'RADMhz', 8)
		else
			ipc.sleep(20)
			com.write(dev, 'RADKhz', 8)
		end
	end
	RADIOS_MhzKhz_prev = RADIOS_MhzKhz
end

-----------------------------------------------------------------

-- ## Transponder ##############

function getSquawk ()
	local buffer = ipc.readUW(0x0354)
	return string.format("%04x", buffer)
end

-----------------------------------------------------------------

function Default_XPND_select ()
	if dev == 0 then return end

	if RADIOS_MODE ~= 5 then
		RADIOS_MODE = 5 -- XPND
		ipc.sleep(50)
		com.write(dev, "TRNXXXXX", 8)
		Default_XPND_init (true)
		ipc.sleep(50)
		com.write(dev, "RADT3", 8)
		RADIOS_CURSOR_POS = 3
		switch ("XPND Select", RADIOS, "RADIOS")
	else
		if not trn_vfr_tmp then
			-- switch indication to 2200
			ipc.sleep(50)
			RADIOS_XPND_CODE = "2200"
			com.write(dev, "TRN2200", 8)
			trn_vfr_tmp = true
		else
			-- switch indication back to current squawk
			Default_XPND_init (true)
			trn_vfr_tmp = false
		end
	end
end

-----------------------------------------------------------------

function Default_XPND_set (s)
	ipc.control(65715, tonumber(s,16))
end

-----------------------------------------------------------------

function Default_XPND_init (upd)
	if dev == 0 then return end
	if upd == nil then upd = false end
	if upd or trn_firstload then
		ipc.sleep(50)
		local buffer = ipc.readUW(0x0354)
		RADIOS_XPND_CODE = string.format("%04x", buffer)
		com.write(dev, "TRN" .. RADIOS_XPND_CODE, 8)
		ipc.sleep(50)
		trn_firstload = false
	end
	dme_open = 0
	com_open = 0
	nav_open = 0
end

-----------------------------------------------------------------

function Default_XPND_plus ()
	local d, code
	code = RADIOS_XPND_CODE
	if RADIOS_CURSOR_POS == 3 then
		d = tonumber(string.sub(code, 1, 1)) + 1
		if d > 7 then d = 0 end
		code = tostring(d) .. string.sub(code, 2)
	elseif RADIOS_CURSOR_POS == 2 then
		d = tonumber(string.sub(code, 2, 2)) + 1
		if d > 7 then d = 0 end
		code = string.sub(code, 1, 1) .. tostring(d) .. string.sub(code, 3)
	elseif RADIOS_CURSOR_POS == 1 then
		d = tonumber(string.sub(code, 3, 3)) + 1
		if d > 7 then d = 0 end
		code = string.sub(code, 1, 2) .. tostring(d) .. string.sub(code, 4)
	elseif RADIOS_CURSOR_POS == 0 then
		d = tonumber(string.sub(code, 4, 4)) + 1
		if d > 7 then d = 0 end
		code = string.sub(code, 1, 3) .. tostring(d)
	end
	RADIOS_XPND_CODE = code
	ipc.sleep(50)
	com.write(dev, "TRN" .. code, 8)
	ipc.sleep(50)
	com.write(dev, "RADT" .. RADIOS_CURSOR_POS, 8)
end

-----------------------------------------------------------------

function Default_XPND_minus ()
	local d, code
	code = RADIOS_XPND_CODE
	if RADIOS_CURSOR_POS == 3 then
		d = tonumber(string.sub(code, 1, 1)) - 1
		if d < 0 then d = 7 end
		code = tostring(d) .. string.sub(code, 2)
	elseif RADIOS_CURSOR_POS == 2 then
		d = tonumber(string.sub(code, 2, 2)) - 1
		if d < 0 then d = 7 end
		code = string.sub(code, 1, 1) .. tostring(d) .. string.sub(code, 3)
	elseif RADIOS_CURSOR_POS == 1 then
		d = tonumber(string.sub(code, 3, 3)) - 1
		if d < 0 then d = 7 end
		code = string.sub(code, 1, 2) .. tostring(d) .. string.sub(code, 4)
	elseif RADIOS_CURSOR_POS == 0 then
		d = tonumber(string.sub(code, 4, 4)) - 1
		if d < 0 then d = 7 end
		code = string.sub(code, 1, 3) .. tostring(d)
	end
	RADIOS_XPND_CODE = code
	ipc.sleep(50)
	com.write(dev, "TRN" .. code, 8)
	ipc.sleep(50)
	com.write(dev, "RADT" .. RADIOS_CURSOR_POS, 8)
end

-----------------------------------------------------------------

-- ## Baro ref ##############

function getBaroRef ()
	return math.floor(ipc.readUW(0x0330) / 16)
end

function setBaroRef (baroRef)
	ipc.writeUW(0x0330, baroRef * 16)
end

-----------------------------------------------------------------

-- ## Knob mode toggle ###############

-- CURRENT KNOB MODE TOGGLE
function KNOB_MODE_toggle (skip, group)
	-- _log("KNOB MODE toggle: " .. group)
	if group == "MINS" then
		if MINSmode == "A" then
			MINSmode = "B"
		else
			MINSmode = "A"
		end
		if ipc.get("EFISmode") == 1 then
			-- updating display
			switch (MINSmode .. " SHOW", MINS1, "MINS")
		elseif ipc.get("EFISmode") == 2 then
			-- updating display
			switch (MINSmode .. " SHOW", MINS2, "MINS")
		else
			-- updating display
			switch (MINSmode .. " SHOW", MINS3, "MINS")
		end
		_log("[COMM] KNOB toggle :: MINS " .. MINSmode)
		return
	end
	if group == "BARO" then
		if BAROmode == "A" then
			BAROmode = "B"
		else
			BAROmode = "A"
		end
		if ipc.get("EFISmode") == 1 then
			-- updating display
			switch (BAROmode .. " SHOW", BARO1, "BARO")
		elseif ipc.get("EFISmode") == 2 then
			-- updating display
			switch (BAROmode .. " SHOW", BARO2, "BARO")
		else
			-- updating display
			switch (BAROmode .. " SHOW", BARO3, "BARO")
		end
		_log("[COMM] KNOB toggle :: BARO " .. BAROmode)
		return
	end
	if group == "CTR" then
		if CTRmode == "A" then
			CTRmode = "B"
		else
			CTRmode = "A"
		end
		if ipc.get("EFISmode") == 1 then
			-- updating display
			switch (CTRmode .. " SHOW", CTR1, "CTR")
		elseif ipc.get("EFISmode") == 2 then
			-- updating display
			switch (CTRmode .. " SHOW", CTR2, "CTR")
		else
			-- updating display
			switch (CTRmode .. " SHOW", CTR3, "CTR")
		end
		_log("[COMM] KNOB toggle :: CTR " .. CTRmode)
		return
	end
	if group == "TFC" then
		if TFCmode == "A" then
			TFCmode = "B"
		else
			TFCmode = "A"
		end
		if ipc.get("EFISmode") == 1 then
			-- updating display
			switch (TFCmode .. " SHOW", TFC1, "TFC")
		elseif ipc.get("EFISmode") == 2 then
			-- updating display
			switch (TFCmode .. " SHOW", TFC2, "TFC")
		else
			-- updating display
			switch (TFCmode .. " SHOW", TFC3, "TFC")
		end
		_log("[COMM] KNOB toggle :: TFC " .. TFCmode)
		return
	end

------------------------------------------------------------------------

	if group == "CRS" then
		if CRSmode == "A" then
			CRSmode = "B"
		else
			CRSmode = "A"
		end
		if ipc.get("MCPmode") == 1 then
			-- updating display
			switch (CRSmode .. " SHOW", CRS1, "CRS")
		elseif ipc.get("MCPmode") == 2 then
			-- updating display
			switch (CRSmode .. " SHOW", CRS2, "CRS")
		else
			-- updating display
			switch (CRSmode .. " SHOW", CRS3, "CRS")
		end
		_log("[COMM] KNOB toggle :: CRS " .. CRSmode)
		return
	end
	if group == "SPD" then
		if SPDmode == "A" then
			SPDmode = "B"
		else
			SPDmode = "A"
		end
		if ipc.get("MCPmode") == 1 then
			-- updating display
			switch (SPDmode .. " SHOW", SPD1, "SPD")
		elseif ipc.get("MCPmode") == 2 then
			-- updating display
			switch (SPDmode .. " SHOW", SPD2, "SPD")
		else
			-- updating display
			switch (SPDmode .. " SHOW", SPD3, "SPD")
		end
		_log("[COMM] KNOB toggle :: SPD " .. SPDmode)
		return
	end
	if group == "HDG" then
		if HDGmode == "A" then
			HDGmode = "B"
		else
			HDGmode = "A"
		end
		if ipc.get("MCPmode") == 1 then
			-- updating display
			switch (HDGmode .. " SHOW", HDG1, "HDG")
		elseif ipc.get("MCPmode") == 2 then
			-- updating display
			switch (HDGmode .. " SHOW", HDG2, "HDG")
		else
			-- updating display
			switch (HDGmode .. " SHOW", HDG3, "HDG")
		end
		_log("[COMM] KNOB toggle :: HDG " .. HDGmode)
		return
	end
	if group == "ALT" then
		if ALTmode == "A" then
			ALTmode = "B"
		else
			ALTmode = "A"
		end
		if ipc.get("MCPmode") == 1 then
			-- updating display
			switch (ALTmode .. " SHOW", ALT1, "ALT")
		elseif ipc.get("MCPmode") == 2 then
			-- updating display
			switch (ALTmode .. " SHOW", ALT2, "ALT")
		else
			-- updating display
			switch (ALTmode .. " SHOW", ALT3, "ALT")
		end
		_log("[COMM] KNOB toggle :: ALT " .. ALTmode)
		return
	end
	if group == "VVS" then
		if VVSmode == "A" then
			VVSmode = "B"
		else
			VVSmode = "A"
		end
		if ipc.get("MCPmode") == 1 then
			-- updating display
			switch (VVSmode .. " SHOW", VVS1, "VVS")
		elseif ipc.get("MCPmode") == 2 then
			-- updating display
			switch (VVSmode .. " SHOW", VVS2, "VVS")
		else
			-- updating display
			switch (VVSmode .. " SHOW", VVS3, "VVS")
		end
		_log("[COMM] KNOB toggle :: VVS " .. VVSmode)
		return
	end
end

-----------------------------------------------------------------

-- ## Block modes ##############

function EFIS_MODE_toggle ()
	local em = ipc.get("EFISmode") + 1
	if EFIS3["ENABLED"] then
		-- 3 modes enabled
		if em > 3 then em = 1 end
	else
		-- 2 modes only
		if em > 2 then em = 1 end
	end
	if em == 1 then
		EFIS_MODE_one ()
	elseif em == 2 then
		EFIS_MODE_two ()
	else
		EFIS_MODE_three ()
	end
end

-----------------------------------------------------------------

function EFIS_MODE_one ()
	ipc.set("EFISmode", 1)
	local ident = "mod1"
	if type (EFIS1["IDENT"]) == "string" and
        string.len(EFIS1["IDENT"]) > 0 then
		ident = string.sub(EFIS1["IDENT"], 1, 4)
	end
	Sounds("modereset", true)
	DspShow("EFIS", ident, true, true)
	ipc.sleep(500)
end

-----------------------------------------------------------------

function EFIS_MODE_two ()
	ipc.set("EFISmode", 2)
	local ident = "mod2"
	if type (EFIS2["IDENT"]) == "string" and
        string.len(EFIS2["IDENT"]) > 0
	then ident = string.sub(EFIS2["IDENT"], 1, 4) end
	Sounds("modechange", true)
	DspShow("EFIS", ident, true, true)
	ipc.sleep(500)
	ipc.set("EFISalt", ipc.elapsedtime())
end

-----------------------------------------------------------------

function EFIS_MODE_three ()
	ipc.set("EFISmode", 3)
	local ident = "mod3"
	if type (EFIS3["IDENT"]) == "string" and string.len(EFIS3["IDENT"]) > 0
	then ident = string.sub(EFIS3["IDENT"], 1, 4)  end
	Sounds("modechange", true)
	DspShow("EFIS", ident, true, true)
	ipc.sleep(500)
	ipc.set("EFISalt", ipc.elapsedtime())
end

-----------------------------------------------------------------

-- ### MCP MODE ##############

function MCP_MODE_toggle ()
	local mm = ipc.get("MCPmode") + 1
	if MCP3["ENABLED"] then
		-- 3 modes enabled
		if mm > 3 then mm = 1 end
	else
		-- 2 modes only
		if mm > 2 then mm = 1 end
	end
	if mm == 1 then
		MCP_MODE_one ()
	elseif mm == 2 then
		MCP_MODE_two ()
	else
		MCP_MODE_three ()
	end
end

-----------------------------------------------------------------

function MCP_MODE_one ()
	InitDsp(true) -- true - for quiet mode
	if not ipc.get("APlock") == 1 then
		ipc.set("DSPmode", 1)
	end
	ipc.set("MCPmode", 1)
	local ident = "mod1"
	if type (MCP1["IDENT"]) == "string" and string.len(MCP1["IDENT"]) > 0
	then ident = string.sub(MCP1["IDENT"], 1, 4) end
	Sounds("modereset", true)
	DspShow("MCP", ident, true, true)
	ipc.sleep(500)
end

-----------------------------------------------------------------

function MCP_MODE_two ()
	ipc.set("MCPmode", 2)
	local ident = "mod2"
	if type (MCP2["IDENT"]) == "string" and string.len(MCP2["IDENT"]) > 0
	then ident = string.sub(MCP2["IDENT"], 1, 4) end
	Sounds("modechange", true)
	DspShow("MCP", ident, true, true)
	ipc.sleep(500)
	if _MCP1 () then DSP_MODE_two () end
	ipc.set("MCPalt", ipc.elapsedtime())
end

-----------------------------------------------------------------

function MCP_MODE_three ()
	ipc.set("MCPmode", 3)
	local ident = "mod3"
	if type (MCP3["IDENT"]) == "string" and string.len(MCP3["IDENT"]) > 0
	then ident = string.sub(MCP3["IDENT"], 1, 4)  end
	Sounds("modechange", true)
	DspShow("MCP", ident, true, true)
	ipc.sleep(500)
	if _MCP1 () then DSP_MODE_two () end
	ipc.set("MCPalt", ipc.elapsedtime())
end

-----------------------------------------------------------------

-- ### USER MODE ##############

function USER_MODE_toggle ()
	local um = ipc.get("USERmode") + 1
	if USER3["ENABLED"] then
		-- 3 modes enabled
		if um > 3 then um = 1 end
	else
		-- 2 modes only
		if um > 2 then um = 1 end
	end
	if um == 1 then
		USER_MODE_one ()
	elseif um == 2 then
		USER_MODE_two ()
	else
		USER_MODE_three ()
	end
end

-----------------------------------------------------------------

function USER_MODE_one ()
	ipc.set("USERmode", 1)
	local ident = "mod1"
	if type (USER1["IDENT"]) == "string" and string.len(USER1["IDENT"]) > 0
	then ident = string.sub(USER1["IDENT"], 1, 4) end
	Sounds("modereset", true)
	DspShow("USER", ident, true, true)
	ipc.sleep(500)
end

-----------------------------------------------------------------

function USER_MODE_two ()
	ipc.set("USERmode", 2)
	local ident = "mod2"
	if type (USER2["IDENT"]) == "string" and string.len(USER2["IDENT"]) > 0
	then ident = string.sub(USER2["IDENT"], 1, 4) end
	Sounds("modechange", true)
	DspShow("USER", ident, true, true)
	ipc.set("USERalt", ipc.elapsedtime())
	ipc.sleep(500)
end

-----------------------------------------------------------------

function USER_MODE_three ()
	ipc.set("USERmode", 3)
	local ident = "mod3"
	if type (USER3["IDENT"]) == "string" and string.len(USER3["IDENT"]) > 0
	then ident = string.sub(USER3["IDENT"], 1, 4)  end
	sound.play("modechange")
	DspShow("USER", ident, true, true)
	ipc.set("USERalt", ipc.elapsedtime())
	ipc.sleep(500)
end

-----------------------------------------------------------------

-- ## DISPLAY MODEs ##############

function DSP_MODE_set ()
	if ipc.get("DSPmode") == 2 then
		DSP_MODE_two ()  -- Flight Info Mode
	else
		DSP_MODE_one ()  -- AP Info Mode
	end
end

-----------------------------------------------------------------

function DSP_MODE_toggle ()
	if ipc.get("DSPmode") == 1 then
		DSP_MODE_two ()  -- Flight Info Mode
	else
		DSP_MODE_one ()  -- AP Info Mode
	end
end

-----------------------------------------------------------------

function DSP_MODE_one ()
	_log('[COMM] DSP Mode 1')
    ipc.set('VRI_MODE', 1)
    if ipc.get("APlock") == 1 then return end
	ipc.set("DSPmode", 1)
	-- Replace SPD indication with CRS
	if SPD_CRS_replace and not _MCP1 () then
		ipc.sleep(50)
		DspSPD2CRS ()
	end
	InitDsp(true) -- true - for quiet mode
	if (_MCP2a() and Airbus) then
		DspShow ("AP MODE", "", true)
	else
		DspMed1("  AP  ")
		DspMed2(" MODE ")
	end
	DisplayAutopilotInfo()
end

-----------------------------------------------------------------

function DSP_MODE_two ()
	_log('[COMM] DSP Mode 2')
    ipc.set('VRI_MODE', 2)
	ipc.set("DSPmode", 2)
	if (_MCP2a() and Airbus) then
		DspShow ("INFO MODE", "")
	else
		DspMed1(" INFO  ")
		DspMed2(" MODE ")
	end
	ipc.sleep(500)
	DisplayFlightInfo ()
end

-----------------------------------------------------------------

-- ## Flight info ############

-- display standard autopilot information set in module using FLIGHT_INFO1 & 2
function DisplayAutopilotInfo ()
	-- check timing values not nil
    if ipc.elapsedtime == nil then
        _loggg('[COMM] Elapsed Time returns NIL')
        return
    end
    if ipc.get("FIP") == nil then
        _loggg('[COMM] FIP returns NIL')
        return
    end
	-- only if no rotaries where move in last second
	if ipc.elapsedtime() - ipc.get("FIP") > 1000 then
		-- get current modes
		local info = Modes()
		local val
		--_log('[awg] APinfo = ' .. info)

		-- handle Airbus on Airbus FCU (MCP2a)
		if (_MCP2a() and Airbus) then
			if info ~= "M111" then
				Dsp6(info, false)
			else
				Dsp6('    ')
			end
			if FLIGHT_INFO1 ~= '' and FLIGHT_INFO1 ~= nil then
				val = FLIGHT_INFO1
			else
				val = ''
			end
			if FLIGHT_INFO2 ~= '' and FLIGHT_INFO2 ~= nil then
				val = val .. " " .. FLIGHT_INFO2
			end
			DspShow(val, false)
		-- handle non-Airbus aircraft on Boeing and Airbus panels
		elseif (_MCP2() or _MCP2a()) then
			if info == "M111" then
				if FLIGHT_INFO1 ~= '' then
					DspMed1 (FLIGHT_INFO1, false)
				else
					if ipc.get("DSPmode") == 2 then
						DspMed1 (FLIGHT_INFO_TEXT, false)
					end
				end
			else  -- display MODEs
				DspMed1(' ' .. info, false)
				DspClearMed2()
			end
			mcp_tmp = 0
			if FLIGHT_INFO2 ~= '' then
				if info == "M111" then
					DspMed2 (FLIGHT_INFO2, false)
				end
			end
		else  -- MCP1
		  if ipc.readUD(0x07BC) ~= AP_STATE then
				AP_STATE = ipc.readUD(0x07BC)
				if AP_STATE == 1 then
					DspMed2("*AP*")
				else
					DspMed2("+ap+")
				end
			end
		end
	end
end

-----------------------------------------------------------------

-- display flight information as set by modules using FLIGHT_INFO1 & 2
function DisplayFlightInfo ()
	-- only if no rotaries where move in last second
    if ipc.elapsedtime == nil then
        _loggg('[COMM] Elapsed Time returns NIL')
        return
    end
    if ipc.get("FIP") == nil then
        _loggg('[COMM] FIP returns NIL')
        return
    end
    if ipc.elapsedtime() - ipc.get("FIP") > 1000 then
	-- get current modes
		local info = "M" .. tostring(ipc.get("EFISmode")) ..
			tostring(ipc.get("MCPmode")) .. tostring(ipc.get("USERmode"))
		--_logg('FLTinfo = ' .. info)

		if (_MCP2a() and Airbus) then
			local val
			if info ~= "M111" then
				Dsp6(info, false)
			else
				Dsp6('info')
			end
			if FLIGHT_INFO1 ~= '' and FLIGHT_INFO1 ~= nil then
				val = FLIGHT_INFO1
			else
				val = ''
			end
			if FLIGHT_INFO2 ~= '' and FLIGHT_INFO2 ~= nil then
				val = val .. " " .. FLIGHT_INFO2
			end
			DspShow (val, false)
		elseif (_MCP2() or _MCP2a()) then
			if info == "M111" then
				if FLIGHT_INFO1 ~= '' then
					DspMed1 (FLIGHT_INFO1, false)
				else
					if ipc.get("DSPmode") == 2 then
						DspMed1 (FLIGHT_INFO_TEXT, false)
					end
				end
			else
				DspMed1(' ' .. info, false)
				DspClearMed2()
			end
			mcp_tmp = 0
			if FLIGHT_INFO2 ~= '' then
				if info == "M111" then
					DspMed2 (FLIGHT_INFO2, false)
				end
			end
		else  -- MCP1
			if ipc.readUD(0x07BC) ~= AP_STATE then
				AP_STATE = ipc.readUD(0x07BC)
				if AP_STATE == 1 then
					DspMed2("*AP*")
				else
				 DspMed2("+ap+")
				end
			end
		end

		-- [[ Manual magnetic deviation counting

		local cur_hdg = ipc.readUD(0x0580)*360/(65536*65536)
		local cur_hdg_var = ipc.readUW(0x02A0)*360/65536

		if cur_hdg_var < 180 then
			cur_hdg = round(cur_hdg - cur_hdg_var)
		else
			cur_hdg = round(cur_hdg + (360 - cur_hdg_var))
		end

		if cur_hdg < 0 then cur_hdg = 360 - cur_hdg end
		if cur_hdg > 360 then cur_hdg = cur_hdg - 360 end

	--]]

	-- easier but gyro drift effected
	-- cur_hdg = ipc.readDBL(0x2B00)

		local cur_vs = ipc.readUW(0x0842) -- *3.28084

		if _MCP1 () then
			if cur_vs > 32766 then
				cur_vs = 65536 - cur_vs
				cur_vs = round(cur_vs * 3.28084 / 100)
				Dsp2(string.format("v+%02d", cur_vs))
			else
				cur_vs = round(cur_vs * 3.28084 / 100)
				Dsp2(string.format("v-%02d", cur_vs))
			end
		else
			if cur_vs > 32766 then
				cur_vs = 65536 - cur_vs
				cur_vs = round(cur_vs * 3.28084 / 100)
			else
				cur_vs = round(cur_vs * 3.28084 / 100) * (-1)
			end
			DspVVS(cur_vs)
		end

		local cur_spd = round(ipc.readUD(0x02BC) / 128)

		local cur_alt = round((ipc.readUD(0x3324) / 100))

		if cur_alt > 21474835 then
			cur_alt = 0
		end

		DspSPD(cur_spd)
		DspHDG(cur_hdg)
		DspALT(cur_alt)
		-- write in fixed zeros for ALT
		if _MCP2 () then
			DspE("00\\\\")
		elseif _MCP2a () then
			DspE("0\\\\\\")
		end
	end
end

-----------------------------------------------------------------

function DspLocked()
	if ipc.get("DSPmode") == 2 then
		DspRadioShort("****")
		ipc.sleep(250)
		DspRadioShort("Info")
		return true
	else
		return false
	end
end

-----------------------------------------------------------------

function AutopilotDisplayBlocked ()
	ipc.set("APlock", 1)
	DSP_MODE_two ()
end

-----------------------------------------------------------------

-- update stucked CRS/HDG/ALT/VS
-- because of working FLightInfo, sync back functions can skip some updates
function DisplayResync ()
	--_loggg('[COMM] Display Resync')
	SyncBackSPD (0, ipc.readUW(0x07E2), true)
	SyncBackHDG (0, ipc.readUW(0x07CC), true)
	SyncBackALT (0, ipc.readUD(0x07D4), true)
	SyncBackVVS (0, ipc.readUW(0x07F2), true)
	SyncBackCRS (0, ipc.readUW(0x0C4E), true)
	SyncBackCRS2 (0, ipc.readUW(0x0C5E), true)
end

-----------------------------------------------------------------

-- ## Display functions ###############

function DspShort1 (s)
	if dev == 0 then return end
	if _MCP1() then return end
	ipc.sleep(20)
	com.write(dev, "DSP0" .. string.sub(s, 1, 2) .. "\\\\", 8)
	DspHideCursor()
end

-----------------------------------------------------------------

function DspShort2 (s)
	if dev == 0 then return end
	if _MCP1() then return end
	ipc.sleep(20)
	com.write(dev, "DSP8" .. string.sub(s, 1, 2) .. "\\\\", 8)
	DspHideCursor()
end

-----------------------------------------------------------------

function DspMed1 (s, clear)
	if dev == 0 then return end
	if clear == nil then DSP_MSG_PREV1 = "" end
	if s == DSP_MSG_PREV1 then return end
	DSP_MSG_PREV1 = s
	if _MCP1() then
		Dsp0(s)
		return
	elseif _MCP2() then
		s = DspStrMed (s)
		ipc.sleep(10)
		com.write(dev, "DSP1" .. "\\\\\\" .. string.sub(s, 1, 1), 8)
		ipc.sleep(10)
		com.write(dev, "DSP2" .. string.sub(s, 2, 5), 8)
		ipc.sleep(10)
		com.write(dev, "DSP3" .. string.sub(s, 6, 8) .. "\\", 8)
		ipc.sleep(10)
		ipc.set("FIP", ipc.elapsedtime())
	elseif (_MCP2a() and Airbus) then
		DspRadioShow(s)
		ipc.set("FIP2", ipc.elapsedtime())
	elseif _MCP2a() then -- default
		s = DspStrMed (s)
		ipc.sleep(10)
		com.write(dev, "DSP1" .. string.sub(s, 1, 4), 8)
		ipc.sleep(10)
		com.write(dev, "DSP2" .. string.sub(s, 5, 8), 8)
		ipc.sleep(10)
		ipc.set("FIP", ipc.elapsedtime())
	end
	if clear == false then
		DSP_MSG1 = false
	else
		DSP_MSG1 = true
	end
	DspHideCursor()
end

-----------------------------------------------------------------

function DspMed2 (s, clear)
	if dev == 0 then return end
	if clear == nil then DSP_MSG_PREV2 = "" end
	if s == DSP_MSG_PREV2 then return end
	DSP_MSG_PREV2 = s
	if _MCP1() then
		Dsp1(s)
		return
	elseif _MCP2() then
		s = DspStrMed (s)
		ipc.sleep(10)
		com.write(dev, "DSP9" .. "\\\\\\" .. string.sub(s, 1, 1), 8)
		ipc.sleep(10)
		com.write(dev, "DSPA" .. string.sub(s, 2, 5), 8)
		ipc.sleep(10)
		com.write(dev, "DSPB" .. string.sub(s, 6, 8) .. "\\", 8)
		ipc.sleep(10)
		ipc.set("FIP", ipc.elapsedtime())
	elseif (_MCP2a() and Airbus) then
		s = DspStrMed (s)
		DspRadioMed(s)
		ipc.set("FIP", ipc.elapsedtime())
		ipc.set("FIP2", ipc.elapsedtime())
	elseif _MCP2a then -- default
		s = DspStrMed (s)
		ipc.sleep(10)
		com.write(dev, "DSP9" .. string.sub(s, 1, 4), 8)
		ipc.sleep(10)
		com.write(dev, "DSPA" .. string.sub(s, 5, 8), 8)
		ipc.sleep(10)
		ipc.set("FIP", ipc.elapsedtime())
	end
	if clear == false then
		DSP_MSG2 = false
	else
		DSP_MSG2 = true
	end
	DspHideCursor()
end

-----------------------------------------------------------------

function DspClearAll()
	DspClearLong1()
	DspClearLong2()
	DspClearLong3()
	DspClearLong4()
end

-----------------------------------------------------------------

function DspClearLong1(s)
	svar = " "
	DspLong1 (svar)
end

-----------------------------------------------------------------

function DspClearLong2(s)
	svar = " "
	DspLong2 (svar)
end

-----------------------------------------------------------------

function DspClearLong3(s)
	svar = " "
	DspLong3 (svar)
end

-----------------------------------------------------------------

function DspClearLong4(s)
	svar = " "
	DspLong4 (svar)
end

-----------------------------------------------------------------

function DspLong1 (s)
	if dev == 0 then return end
	--if _MCP1() then return end
	s = DspStrLong (s)
	ipc.sleep(20)
	com.write(dev, "DSP0" .. string.sub(s, 1, 4), 8)
	ipc.sleep(20)
	com.write(dev, "DSP1" .. string.sub(s, 5, 8), 8)
	ipc.sleep(20)
	com.write(dev, "DSP2" .. string.sub(s, 9, 12), 8)
	ipc.sleep(20)
	com.write(dev, "DSP3" .. string.sub(s, 13, 16), 8)
	ipc.sleep(20)
	ipc.set("FIP", ipc.elapsedtime())
	DspHideCursor()
end

-----------------------------------------------------------------

function DspLong2 (s)
	if dev == 0 then return end
	--if _MCP1() then return end
	s = DspStrLong (s)
	ipc.sleep(20)
	com.write(dev, "DSP8" .. string.sub(s, 1, 4), 8)
	ipc.sleep(20)
	com.write(dev, "DSP9" .. string.sub(s, 5, 8), 8)
	ipc.sleep(20)
	com.write(dev, "DSPA" .. string.sub(s, 9, 12), 8)
	ipc.sleep(20)
	com.write(dev, "DSPB" .. string.sub(s, 13, 16), 8)
	ipc.sleep(20)
	ipc.set("FIP", ipc.elapsedtime())
	DspHideCursor()
end

-----------------------------------------------------------------

function DspLong3 (s)
	if dev == 0 then return end
	--if _MCP1() then return end
	s = DspStrLong (s)
	ipc.sleep(20)
	com.write(dev, "DSP4" .. string.sub(s, 1, 4), 8)
	ipc.sleep(20)
	com.write(dev, "DSP5" .. string.sub(s, 5, 8), 8)
	ipc.sleep(20)
	com.write(dev, "DSP6" .. string.sub(s, 9, 12), 8)
	ipc.sleep(20)
	com.write(dev, "DSP7" .. string.sub(s, 13, 16), 8)
	ipc.sleep(20)
	ipc.set("FIP", ipc.elapsedtime())
	DspHideCursor()
end

-----------------------------------------------------------------

function DspLong4 (s)
	if dev == 0 then return end
	--if  _MCP1() then return end
	s = DspStrLong (s)
	ipc.sleep(20)
	com.write(dev, "DSPC" .. string.sub(s, 1, 4), 8)
	ipc.sleep(20)
	com.write(dev, "DSPD" .. string.sub(s, 5, 8), 8)
	ipc.sleep(20)
	com.write(dev, "DSPE" .. string.sub(s, 9, 12), 8)
	ipc.sleep(20)
	com.write(dev, "DSPF" .. string.sub(s, 13, 16), 8)
	ipc.sleep(20)
	ipc.set("FIP", ipc.elapsedtime())
	DspHideCursor()
end

-----------------------------------------------------------------

-- MCP Display operations
function DspClear ()
	if dev == 0 then return end
	local cmd1, cmd2
	if _MCP1() then
		cmd1 = "DSP0"
		cmd2 = "DSP1"
	elseif _MCP2() then
		cmd1 = "DSP2"
		cmd2 = "DSP3"
	elseif (_MCP2a() and Airbus) then -- MCP2a
		cmd1 = "DSP1"
		cmd2 = "DSP9"
	else -- default MCP2a
		cmd1 = "DSP2"
		cmd2 = "DSPA"
	end
	ipc.sleep(20)
	com.write(dev, cmd1 .. "    ", 8)
	ipc.sleep(20)
	com.write(dev, cmd2 .. "    ", 8)
    -- ensure legacy clear using MSGx commands
    if _MCP1() then
        com.write(dev, "MSG0    ", 8)
        com.write(dev, "MSG1    ", 8)
    end
	DspHideCursor()
end

-----------------------------------------------------------------

function DspClearMed ()
	if dev == 0 then return end
	if _MCP1()  then return end
	if _MCP2() then
		local cmd1, cmd2
		ipc.sleep(20)
		com.write(dev, "DSP1\\\\\\ ", 8)
		ipc.sleep(20)
		com.write(dev, "DSP2    ", 8)
		ipc.sleep(20)
		com.write(dev, "DSP3   \\", 8)
		ipc.sleep(20)
		com.write(dev, "DSP9\\\\\\ ", 8)
		ipc.sleep(20)
		com.write(dev, "DSPA    ", 8)
		ipc.sleep(20)
		com.write(dev, "DSPB    ", 8)
		ipc.sleep(20)
	elseif (_MCP2a() and Airbus) then
		ipc.sleep(20)
		com.write (dev, "DSP1    ")
		ipc.sleep(20)
		com.write (dev, "DSP9    ")
	else -- MCP2a default
		ipc.sleep(20)
		com.write(dev, "DSP1    ", 8)
		ipc.sleep(20)
		com.write(dev, "DSP2    ", 8)
		ipc.sleep(20)
		com.write(dev, "DSP9    ", 8)
		ipc.sleep(20)
		com.write(dev, "DSPA    ", 8)
	end
	DspHideCursor()
	DSP_MSG = false
	DSP_MSG1 = false
	DSP_MSG2 = false
	DSP_MSG_PREV1 = ""
	DSP_MSG_PREV2 = ""
end

-----------------------------------------------------------------

function DspClearMed1 ()
	if dev == 0 then return end
	if _MCP1() then return end
	if _MCP2() then
		ipc.sleep(20)
		com.write(dev, "DSP1\\\\\\ ", 8)
		ipc.sleep(20)
		com.write(dev, "DSP2    ", 8)
		ipc.sleep(20)
		com.write(dev, "DSP3   \\", 8)
		ipc.sleep(20)
	elseif (_MCP2a() and Airbus) then
		ipc.sleep(20)
		com.write (dev, "DSP1\\   ")
		ipc.sleep(20)
		com.write (dev, "DSP2    ")
		ipc.sleep(20)
		com.write (dev, "DSP3    ")
	else -- MCP2a default
		ipc.sleep(20)
		com.write(dev, "DSP1    ", 8)
		ipc.sleep(20)
		com.write(dev, "DSP2    ", 8)
		ipc.sleep(20)
	end
	DspHideCursor()
	DSP_MSG1 = false
	DSP_MSG_PREV1 = ""
end

-----------------------------------------------------------------

function DspClearMed2 ()
	if dev == 0 then return end
	if _MCP1() then return end
	local cmd1, cmd2
	if _MCP2() then
		ipc.sleep(20)
		com.write(dev, "DSP9\\\\\\ ", 8)
		ipc.sleep(20)
		com.write(dev, "DSPA    ", 8)
		ipc.sleep(20)
		com.write(dev, "DSPB   \\", 8)
		ipc.sleep(20)
	elseif (_MCP2a() and Airbus) then
		ipc.sleep(20)
		com.write (dev, "DSP2    ")
		ipc.sleep(20)
		com.write (dev, "DSP3    ")
	else -- MCP2a default
		ipc.sleep(20)
		com.write(dev, "DSP9    ", 8)
		ipc.sleep(20)
		com.write(dev, "DSPA    ", 8)
		ipc.sleep(20)
	end
	DspHideCursor()
	DSP_MSG2 = false
	DSP_MSG_PREV1 = ""
end

-----------------------------------------------------------------

function DspStr (s)
	s = tostring(s)
	while string.len(s) < 4 do s = s .. " " end
	return s
end

-----------------------------------------------------------------

function DspStrLong (s)
	s = tostring(s)
	while string.len(s) < 24 do s = s .. " " end
	return s
end

-----------------------------------------------------------------

function DspStrMed (s)
	s = tostring(s)
	while string.len(s) < 8 do s = s .. " " end
	return s
end

-----------------------------------------------------------------

function DspNum (i, digits)
	if digits == 2 then
		s = string.format("%02d", round(tonumber(i)))
	else
		s = string.format("%03d", round(tonumber(i)))
	end
	-- while string.len(s) < 3 do s = '0' .. s end
	if i == 0 then s = "000" end
	return s
end

-----------------------------------------------------------------

function DspShow (line1, line2, mline1, mline2)
	-- displays 2 lines of text (line1 & line2)
	-- if mline1/mline2 is nil or true then pack with spaces
	if dev == 0 then return end
	if line2 == nil or line2 == false or line2 == true then line2 = "" end
	if DSP_MSG_PREV1 == line1 and DSP_MSG_PREV2 == line2 then return end
	if (mline1 == nil or mline1 == true) then mline1 = '  ' .. line1 .. '  ' end
	if (mline2 == nil or mline2 == true) then mline2 = '  ' .. line2 .. '  ' end

	if (_MCP2a() and Airbus) or DspShowRadio then
		-- MCP2a uses Radio panel top line
		-- or flag DspShowRadio set to true
		if line2 ~= "" then
			DspRadioShow (line1 .. "=" .. line2)
		else
			DspRadioShow (line1)
		end
	elseif _MCP2a() then
		DspMed1 (' ' .. line1)
		DspMed2 (' ' .. line2)
	elseif _MCP2() then
		DspMed1 (mline1)
		DspMed2 (mline2)
	elseif _MCP1 () then
		Dsp0 (line1)
		Dsp1 (line2)
	else
	end
	DSP_MSG_PREV1 = line1 -- save last string sent to DSP
	DSP_MSG_PREV2 = line2 -- save last string sent to DSP
	DSP_MSG = true
end

-----------------------------------------------------------------

function Dsp0 (s, f)
	if dev == 0 then return end
    if s == nil then return end
    if f == nil then f = 0 end

	if DSP_PREV0 == s and f ~= true then return end
	DSP_PREV0 = s
	s = DspStr(s)
    --_loggg('[COMM] Dsp0=' .. s)
	local cmd
    cmd = "DSP0"
	ipc.sleep(20)
	com.write(dev, cmd .. s, 8)
    if _MCP1() then
        cmd = "MSG0"
        com.write(dev, cmd .. s, 8)
    end
    DspHideCursor ()
    dsp0_prev = s
end

-----------------------------------------------------------------

function Dsp1 (s, f)
	if dev == 0 then return end
    if s == nil then return end
    if f == nil then f = 0 end

	if DSP_PREV1 == s and f ~= true then return end
	DSP_PREV1 = s
	s = DspStr(s)
	local cmd
    --_loggg('[COMM] Dsp1=' .. s)
    cmd = "DSP1"
	ipc.sleep(20)
	com.write(dev, cmd .. s, 8)
    if _MCP1() then
        cmd = "MSG1"
        ipc.sleep(20)
        com.write(dev, cmd .. s, 8)
    end
	DspHideCursor ()
    dsp1_prev = s
end

-----------------------------------------------------------------

function Dsp2 (s, f)
	if dev == 0 then return end
    if s == nil then return end
    if f == nil then f = 0 end

	if DSP_PREV2 == s and f ~= true then return end
	DSP_PREV2 = s
	s = DspStr(s)
	local cmd
	if (_MCP2 () or _MCP2a ()) then
		cmd = "DSP2"
    	ipc.sleep(20)
        com.write(dev, cmd .. s, 8)
        DspHideCursor ()
    end
end

-----------------------------------------------------------------

function Dsp3 (s, f)
	if dev == 0 then return end
    if s == nil then return end
    if f == nil then f = 0 end

	if DSP_PREV3 == s and f ~= true then return end
	DSP_PREV3 = s
	s = DspStr(s)
	local cmd
	if (_MCP2 () or _MCP2a ()) then
		cmd = "DSP3"
		ipc.sleep(20)
		com.write(dev, cmd .. s, 8)
		DspHideCursor ()
	end
end

-----------------------------------------------------------------

function Dsp4 (s, f)
	if dev == 0 then return end
    if s == nil then return end
    if f == nil then f = 0 end

	if DSP_PREV4 == s and f ~= true then return end
	DSP_PREV4 = s
	s = DspStr(s)
	local cmd
	if (_MCP2 () or _MCP2a ()) then
		cmd = "DSP4"
		ipc.sleep(20)
		com.write(dev, cmd .. s, 8)
		DspHideCursor ()
	end
end

-----------------------------------------------------------------

function Dsp5 (s, f)
	if dev == 0 then return end
    if s == nil then return end
    if f == nil then f = 0 end

	if DSP_PREV5 == s and f ~= true then return end
	DSP_PREV5 = s
	s = DspStr(s)
	local cmd
	if (_MCP2 () or _MCP2a ()) then
		cmd = "DSP5"
		ipc.sleep(20)
		com.write(dev, cmd .. s, 8)
		DspHideCursor ()
	end
end

-----------------------------------------------------------------

function Dsp6 (s, f)
	if dev == 0 then return end
    if s == nil then return end
    if f == nil then f = 0 end

	if DSP_PREV6 == s and f ~= true then return end
	DSP_PREV6 = s
	s = DspStr(s)
	local cmd
	if (_MCP2 () or _MCP2a ()) then
		cmd = "DSP6"
		ipc.sleep(20)
		com.write(dev, cmd .. s, 8)
		DspHideCursor ()
	end
end

-----------------------------------------------------------------

function Dsp7 (s, f)
	if dev == 0 then return end
    if s == nil then return end
    if f == nil then f = 0 end

	if DSP_PREV7 == s and f ~= true then return end
	DSP_PREV7 = s
	s = DspStr(s)
	local cmd
	if (_MCP2 () or _MCP2a ()) then
		cmd = "DSP7"
		ipc.sleep(20)
		com.write(dev, cmd .. s, 8)
		DspHideCursor ()
	end
end

-----------------------------------------------------------------

function Dsp8 (s, f)
	if dev == 0 then return end
    if s == nil then return end
    if f == nil then f = 0 end
    --_loggg('Dsp8=' .. s .. ' - ' .. DSP_PREV8)
	if DSP_PREV8 == s and f ~= true then return end
    --_loggg('Dsp8 ' .. tostring(f))
	DSP_PREV8 = s
	s = DspStr(s)
	local cmd
	if (_MCP2 () or _MCP2a ()) then
		cmd = "DSP8"
		ipc.sleep(20)
		com.write(dev, cmd .. s, 8)
		DspHideCursor ()
	end
end

-----------------------------------------------------------------

function Dsp9 (s, f)
	if dev == 0 then return end
    if s == nil then return end
    if f == nil then f = 0 end

	if DSP_PREV9 == s and f ~= true then return end
	DSP_PREV9 = s
	s = DspStr(s)
	local cmd
	if (_MCP2 () or _MCP2a ()) then
		cmd = "DSP9"
		ipc.sleep(20)
		com.write(dev, cmd .. s, 8)
		DspHideCursor ()
	end
end

-----------------------------------------------------------------

function DspA (s, f)
	if dev == 0 then return end
    if s == nil then return end
    if f == nil then f = 0 end

	if DSP_PREVA == s and f ~= true then return end
	DSP_PREVA = s
	s = DspStr(s)
	local cmd
	if (_MCP2 () or _MCP2a ()) then
		cmd = "DSPA"
		ipc.sleep(20)
		com.write(dev, cmd .. s, 8)
		DspHideCursor ()
	end
end

-----------------------------------------------------------------

function DspB (s, f)
	if dev == 0 then return end
    if s == nil then return end
    if f == nil then f = 0 end

	if DSP_PREVB == s and f ~= true then return end
	DSP_PREVB = s
	s = DspStr(s)
	local cmd
	if (_MCP2 () or _MCP2a ()) then
		cmd = "DSPB"
		ipc.sleep(20)
		com.write(dev, cmd .. s, 8)
		DspHideCursor ()
	end
end

-----------------------------------------------------------------

function DspC (s, f)
	if dev == 0 then return end
    if s == nil then return end
    if f == nil then f = 0 end

	if DSP_PREVC == s and f ~= true then return end
	DSP_PREVC = s
	s = DspStr(s)
    --_loggg('DspC=' .. s)
	local cmd
	if (_MCP2 () or _MCP2a ()) then
		cmd = "DSPC"
		ipc.sleep(20)
		com.write(dev, cmd .. s, 8)
		DspHideCursor ()
	end
end

-----------------------------------------------------------------

function DspD (s)
	if dev == 0 then return end
    if s == nil then return end
	if DSP_PREVD == s and f ~= true then return end
	DSP_PREVD = s
	s = DspStr(s)
	local cmd
	if (_MCP2 () or _MCP2a ()) then
		cmd = "DSPD"
		ipc.sleep(20)
		com.write(dev, cmd .. s, 8)
		DspHideCursor ()
	end
end

-----------------------------------------------------------------

function DspE (s, f)
	if dev == 0 then return end
    if s == nil then return end
    if f == nil then f = 0 end

	if DSP_PREVE == s and f ~= true then return end
	DSP_PREVE = s
	s = DspStr(s)
	local cmd
	if (_MCP2 () or _MCP2a ()) then
		cmd = "DSPE"
		ipc.sleep(20)
		com.write(dev, cmd .. s, 8)
		DspHideCursor ()
	end
end

-----------------------------------------------------------------

function DspF (s, f)
	if dev == 0 then return end
    if s == nil then return end
    if f == nil then f = 0 end

	if DSP_PREVF == s and f ~= true then return end
	DSP_PREVF = s
	s = DspStr(s)
	local cmd
	if (_MCP2 () or _MCP2a ()) then
		cmd = "DSPF"
		ipc.sleep(20)
		com.write(dev, cmd .. s, 8)
		DspHideCursor ()
	end
end

-----------------------------------------------------------------

-- display available Simulator Virtual Address Space (VAS)n on MCP
function DspVAS ()
	if dev == 0 then return end
	if not (_MCP2 () or _MCP2a ()) then return end
    local VAS = getSimVAS()
    local FSVAS = tostring(VAS)
    _loggg('[COMM] DspVAS ' .. tostring(VAS) .. '=' ..
        FSVAS .. '-' .. tostring(VAS_DISPLAY))
    if RADIOS_MODE < 4 then
        if not RADIOS_MSG then
            if VAS_DISPLAY == 1 then
                _loggg('[COMM] VAS on')
                if VAS <= 300 then
                    FSVAS = tostring(VAS) .. '!'
                else
                    FSVAS = tostring(VAS)
                end
                while string.len(FSVAS) < 4 do
                    FSVAS = " " .. FSVAS
                end
                ipc.sleep(20)
                com.write(dev, "dsp3" .. FSVAS, 8)
                RADIOS_MSG_SHORT = true
            else
                _loggg('[COMM] VAS off')
                if RADIOS_MSG_SHORT then
                    DspRadiosMedClear()
                    RADIOS_MSG_SHORT = false
                end
            end
        end
    end
end

-----------------------------------------------------------------

-- display available Simulator Virtual Address Space (VAS)n on MCP
function DspFSVAS ()
	if dev == 0 then return end
	if not (_MCP2 () or _MCP2a ()) then return end
    local FPS = getSimFPS()
    local FSFPS = tostring(FPS)
    local VAS = getSimVAS()
    local FSVAS = tostring(VAS)
    local FS
    --_logggg('[COMM]  ' .. FSFPS .. '/' .. FSVAS .. '=' ..
    --    tostring(VAS_DISPLAY))
    if RADIOS_MODE < 4 then
        if not RADIOS_MSG then
            if VAS_DISPLAY == 1 then
                --_logggg('[COMM] FPS on')
                if VAS == 0 then -- P3dv4 64-bit who cares?
                    FSVAS = ''
                elseif VAS <= 300 then
                    FSVAS = tostring(VAS) .. '!'
                else
                    FSVAS = tostring(VAS)
                end
                FS = FSFPS .. '/' .. FSVAS
                while string.len(FS) < 8 do
                    FS = ' ' .. FS
                end
                --DspRadioMed(FS)
                ipc.sleep(20)
                FS1 = string.sub(FS, 1, 4)
                FS2 = string.sub(FS, 5, 8)
                if FS1 ~= "    " then
                    com.write(dev, "dsp2" ..FS1, 8)
                    ipc.sleep(20)
                end
                com.write(dev, "dsp3" .. FS2, 8)
                RADIOS_MSG = false
                RADIOS_MSG_SHORT = false
            else
                --_logggg('[COMM] FPS off')
                if RADIOS_MSG then
                    DspRadiosMedClear()
                    RADIOS_MSG = false
                    RADIOS_MSG_SHORT = false
                end
                --ipc.lineDisplay('')
            end
        end
    end
end

-----------------------------------------------------------------

function DspSPD (i)
	if dev == 0 then return end
    if i == nil then return end
	local strVal
	strVal = DspNum(i)
    if DSP_SPD_PREV ~= strVal then
		if _MCP2() then
			Dsp9("\\\\ \\")
		end
		ipc.sleep(20)
		com.write(dev, "SPD" .. DspNum(i) .. "__", 8)
		SPD = i
		DSP_SPD_PREV = strVal
		DspHideCursor()
	end
end

-----------------------------------------------------------------

function DspSPDs (s, f)
	if dev == 0 then return end
    if s == nil then return end
    if f == nil then f = 0 end

	local strVal
	strVal = s
    --_logggg('SPDs=' .. s)
	if DSP_SPD_PREV ~= strVal then
		if _MCP2() then
			Dsp8("\\\\\\" .. string.sub(s, 1, 1), false)
			Dsp9(string.sub(s, 2, 4) .. '\\\\')
		elseif _MCP2a () then
			strVal = string.sub(s, 1, 4)
			Dsp8(strVal, f)
		end
		DSP_SPD_PREV = strVal
		DspHideCursor()
	end
end

-----------------------------------------------------------------

function DspSPD2CRS ()
	if dev == 0 then return end
    if _MCP1() then return end
    if _MCP2() then
        if crs_open == 1 then
            -- OBS1
            Dsp0("\\\\\\O")
            Dsp1("BS\\\\")
            crs_hdg = ipc.readUW(0x0C4E)
            CRS1 = crs_hdg
        elseif crs_open == 2 then
            -- OBS2
            Dsp0("\\\\\\o")
            Dsp1("bs\\\\")
            crs_hdg = ipc.readUW(0x0C5E)
            CRS2 = crs_hdg
        elseif crs_open == 3 then
            -- ADF1
            Dsp0("\\\\\\A")
            Dsp1("DF\\\\")
            crs_hdg = ipc.readUW(0x0C6C)
            CRS3 = crs_hdg
        elseif crs_open == 4 then -- not actually used !!!
            -- ADF2
            Dsp0("\\\\\\A")
            Dsp1("DF2\\")
            crs_hdg = 0 -- unknown unused yet
        end
    else  -- MCP2a
        if crs_open == 1 then
            -- OBS1
            Dsp0("OBS\\")
            crs_hdg = ipc.readUW(0x0C4E)
            CRS1 = crs_hdg
        elseif crs_open == 2 then
            -- OBS2
            Dsp0("obs\\")
            crs_hdg = ipc.readUW(0x0C5E)
            CRS2 = crs_hdg
        elseif crs_open == 3 then
            -- ADF1
            Dsp0("ADF\\")
            crs_hdg = ipc.readUW(0x0C6C)
            CRS3 = crs_hdg
        elseif crs_open == 4 then -- not actually used !!!
            -- ADF2
            Dsp0("ADF2")
            crs_hdg = 0 -- unknown unused yet
        end
    end
    DspCRS(crs_hdg, crs_open)
	DspHideCursor()
end

-----------------------------------------------------------------

function DspHDG (i)
	if dev == 0 then return end
    if i == nil then return end
	local strVal
	strVal = DspNum(i)
	if DSP_HDG_PREV ~= strVal then
		if _MCP1() then
			ipc.sleep(30)
			com.write(dev, "HDG" .. DspNum(i), 8)
			DspHideCursor()
		elseif _MCP2() then
			DspC(DspNum(i) .. '\\')
		elseif (_MCP2a() and Airbus) then
			ipc.sleep(30)
			com.write(dev, "HDG" .. DspNum(i,3) .. '\\', 8)
		else -- MCP2a default
			DspB(DspNum(i) .. '\\')
		end
		HDG = i
		DSP_HDG_PREV = strVal
	end
end

-----------------------------------------------------------------

function DspHDGs (s)
	if dev == 0 then return end
    if s == nil then return end
	local strVal
	strVal = s
    --_logggg('HDGs=' .. s)
	if DSP_HDG_PREV ~= strVal then
		if _MCP1() or _MCP2() then
            DspC(s)
		elseif (_MCP2a() and Airbus) then
			DspA(s)
		else -- MCP2a default
			DspB(s)
		end
		DSP_HDG_PREV = strVal
	end
end

-----------------------------------------------------------------

function DspHDGn (s)
	if dev == 0 then return end
    if s == nil then return end
	local strVal
	strVal = s
	if DSP_HDG_PREV ~= strVal then
		Dsp4(s)
		DspHideCursorLeft()
		DSP_HDG_PREV = strVal
	end
end

-----------------------------------------------------------------

function DspALT (i)
	if dev == 0 then return end
    if i == nil then i = 0 end
	local strVal
	strVal = DspNum(i)
    --_loggg('[COMM] DspALT ' .. tostring(i) .. '=' .. strVal .. '=' .. DSP_ALT_PREV)
	if DSP_ALT_PREV ~= strVal then
		ipc.sleep(30)
		com.write(dev, "ALT" .. DspNum(i), 8)
		DspHideCursor()
		ALT = i
		DSP_ALT_PREV = strVal
	end
end

-----------------------------------------------------------------

function DspALTs (s)
	if dev == 0 then return end
    if s == nil then s = '' end
	local strVal
	strVal = s
	if DSP_ALT_PREV ~= strVal then
		DspD(string.sub(s, 1, 2))
		DspE(string.sub(s, 3, 4) .. '\\\\')
		DSP_ALT_PREV = strVal
	end
end

-----------------------------------------------------------------

function DspVVS (i, f)
	if dev == 0 or i == nil then return end
    if f == nil then f = 0 end

	local strVal
	strVal = DspNum(i)
	if (DSP_VVS_PREV ~= strVal) or f == 1 then
		local line = '000'
		local line2 = '00oo'
		local sign = '+'
		if i > 0 then
			line = string.format("+%003d", i*10)
			line2 = string.format("%002d", i)
			sign = '+'
		elseif i == 0 then
			line = ' ' .. line
			line2 = line2
			sign = '+'
		elseif i < 0 then
			line = string.format("-%003d", math.abs(i*10))
			line2 = string.format("%002d", math.abs(i))
			sign = '-'
		end
		if not _MCP2a() then
			ipc.sleep(20)
			com.write(dev, "VVS" .. line, 8)
		else -- add sign and trailing oo for Airbus
			DspE("\\\\\\" .. sign)
			DspF(line2 .. "oo")
		end
		VVS = i
		DSP_VVS_PREV = strVal
		DspHideCursor()
	end
end

-----------------------------------------------------------------

function DspVVSs (s, f)
	if dev == 0 then return end
    if s == nil then return end
    if f == nil then f = 0 end

	local strVal
	if DSP_VVS_PREV ~= strVal then
		if s ~= '----' then
			DspF(s)
		elseif _MCP2a() then
			DspF(s)
		else
			DspF("0000", f)
			DspVVS(0)
		end
		DSP_VVS_PREV = s
	end
end

-----------------------------------------------------------------

function DspFPA (i, f)
	if dev == 0 then return end
    if i == nil then return end
    if f == nil then f = 0 end

	local strVal
	strVal = DspNum(i * 10)
    _log('[awg] ' .. i .. "=" .. strVal .. '=' .. DSP_VVS_PREV)
	if (DSP_VVS_PREV ~= strVal) or f == 1 then
		if i >= 0 then
			line = string.format("+%.1f", i)
		elseif i < 0 then
			line = string.format("-%.1f", math.abs(i))
		end
		if not _MCP2a() then
			--ipc.sleep(20)
            DspE("\\\\\\ ")
			com.write(dev, "FPA" .. line, 8)
		else
			DspE("\\\\\\ ")
			DspF(line)
		end
		FPA = i
		DSP_VVS_PREV = strVal
		DspHideCursor()
	end
end

-----------------------------------------------------------------

function DspFD (i)
	if dev == 0 then return end
    if i == nil then return end

	if _MCP2() then
		if i == 1 then
		   ipc.sleep(20)
		   com.write(dev, "F/DON", 8)
		else
		   ipc.sleep(20)
		   com.write(dev, "F/DOFF", 8)
		end
	elseif _MCP2a() then
		-- [awg] test code for MCP2a FD display
		if i == 1 then
			val = "F/Dhld1_"
		else
			val = "F/Dhld0_"
		end
		ipc.sleep(20)
		com.write(dev, val, 8)
	end
	DspHideCursor()
end

-----------------------------------------------------------------

function DspAT (i)
	if dev == 0 then return end
    if i == nil then return end

	local val
	if _MCP2() then
		if i > 0 then
		   ipc.sleep(20)
		   com.write(dev, "A/TON", 8)
		else
		   ipc.sleep(20)
		   com.write(dev, "A/TOFF", 8)
		end
	elseif _MCP2a() then
		if i > 0 then
			val = string.char(0) .. string.char(1) .. '  '
		else
			val = '    '
		end
		Dsp4(val)
	end
end

-----------------------------------------------------------------

function DspSPD_AP_on ()
	if dev == 0 then return end
	if _MCP1 () or Airbus then return end
	if _MCP2() then
		Dsp1("\\\\*\\")
	else  -- MCP2a
		Dsp0("\\\\\\*")
	end
end

-----------------------------------------------------------------

function DspSPD_AP_off ()
	if dev == 0 then return end
	if _MCP1 () or Airbus then return end
	if _MCP2() then
		Dsp1("\\\\ \\")
	else
		Dsp0("\\\\\\ ")
	end
end

-----------------------------------------------------------------

function DspSPD_N1_on ()
	if dev == 0 then return end
	if _MCP1 () or _MCP2a() then return end
	Dsp0("\\\\\\ ")
	Dsp1("N1*\\")
end

-----------------------------------------------------------------

function DspSPD_N1_off ()
	if dev == 0 then return end
	if _MCP1 () or _MCP2a() then return end
	Dsp0("\\\\\\S")
	Dsp1("PD \\")
end

-----------------------------------------------------------------

function DspSPD_FLCH_on ()
	if dev == 0 then return end
	if _MCP1 () or _MCP2a() then return end
	Dsp0("\\\\\\F")
	Dsp1("LC*\\")
end

-----------------------------------------------------------------

function DspSPD_FLCH_off ()
	if dev == 0 then return end
	if _MCP1 () or _MCP2a() then return end
	Dsp0("\\\\\\S")
	Dsp1("PD \\")
end

-----------------------------------------------------------------

function DspLNAV_on ()
	if dev == 0 then return end
	if _MCP1 () or Airbus then return end
	if _MCP2() then
		Dsp4("LNAV")
	else
		Dsp3("LNAV")
	end
end

-----------------------------------------------------------------

function DspLNAV_off ()
	if dev == 0 then return end
	if _MCP1 () or Airbus then return end
	if _MCP2() then
		Dsp4("HDG ")
	else
		Dsp3("HDG ")
	end
end

-----------------------------------------------------------------

function DspVNAV_on ()
	if dev == 0 then return end
	if _MCP1 () or Airbus then return end
	if _MCP2() then
		Dsp5("  VN")
		Dsp6("AV  ")
	else
		Dsp5("VNAV")
	end
end

-----------------------------------------------------------------

function DspVNAV_off ()
	if dev == 0 then return end
	if _MCP1 () or Airbus then return end
	ipc.sleep(20)
	if _MCP2() then
		Dsp5("  AL")
		Dsp6("T   ")
	else
		Dsp5("ALT ")
	end
end

-----------------------------------------------------------------

function DspHDG_AP_on ()
	if dev == 0 then return end
	if _MCP1 () or Airbus then return end
	if _MCP2() then
		DspC("\\\\\\*")
	else
		DspB("\\\\\\*")
	end
end

-----------------------------------------------------------------

function DspHDG_AP_off ()
	if dev == 0 then return end
	if _MCP1 () or Airbus then return end
	if _MCP2() then
		DspC("\\\\\\ ")
	else
		DspB("\\\\\\ ")
	end
end

-----------------------------------------------------------------

function DspALT_AP_on ()
	if dev == 0 then return end
	if _MCP1 () or Airbus then return end
	if _MCP2() then
		Dsp6("\\*\\\\")
	else  -- MCP2a
		Dsp5("\\\\\\*")
	end
end

-----------------------------------------------------------------

function DspALT_AP_off ()
	if dev == 0 then return end
	if _MCP1 () or Airbus then return end
	if _MCP2() then
		Dsp6("\\ \\\\")
	else  -- MCP2a
		Dsp5("\\\\\\ ")
	end
end

-----------------------------------------------------------------

function DspAP1 (a)
	if dev == 0 then return end
	if _MCP1 () or _MCP2 () then return end
	local val
	-- define AP1 symbol
	val = '  '
	if a == 1 then
		val = val .. string.char(0)
	else
		val = val .. ' '
	end
	val = val .. '\\'
	Dsp3(val)
end

-----------------------------------------------------------------

function DspAP2 (a)
	if dev == 0 then return end
	if _MCP1 () or _MCP2 () then return end
	local val
	-- define AP2 symbol
	val = '  \\'
	if a == 1 then
		val = val .. string.char(0)
	else
		val = val .. ' '
	end
	Dsp3(val)
end

-----------------------------------------------------------------

function DspAPs (one, two)
	if dev == 0 then return end
	if _MCP1() or _MCP2() then return end
	local val
	val = '  '
	if one == 1 then
		val = val .. string.char(0)
	else
		val = val .. ' '
	end
	if two == 1 then
		val = val .. string.char(1)
	else
		val = val .. ' '
	end
	Dsp3(val)
end

-----------------------------------------------------------------

function DspILS (a)
	if dev == 0 then return end
	if _MCP1 () or _MCP2() then return end
	-- define ILS symbol
	local val
	if a == 1 then
		val = ' ' .. string.char(2) .. string.char(3) .. ' '
	else
		val = '    '
	end
	Dsp1(val)
end

-----------------------------------------------------------------

function DspLOC (a)
	if dev == 0 then return end
	if _MCP1 () or _MCP2() then return end
	-- define LOC symbol
	local val
	if a == 1 then
		val = ' ' .. string.char(4) .. string.char(5) .. ' '
	else
		val = '    '
	end
	Dsp9(val)
end

-----------------------------------------------------------------

function DspAPPR (a)
	if dev == 0 then return end
	if _MCP1 () or _MCP2() then return end
	-- define ILS symbol
	local val
	if a == 1 then
		val = ' ' .. string.char(4) .. string.char(5) .. ' '
	else
		val = '    '
	end
	Dsp6(val)
end

-----------------------------------------------------------------

function DspEXP (a)
	if dev == 0 then return end
	if _MCP1 () or _MCP2() then return end
	-- define Expedite symbol
	local val
	if a == 1 then
		val = ' ' .. string.char(2) .. string.char(3) .. ' '
	else
		val = "    "
	end
	Dsp6(val)
end

-----------------------------------------------------------------

function DspVVS_AP_on ()
	if dev == 0 then return end
	if _MCP1 () or Airbus then return end
	Dsp7("\\\\\\*")
end

-----------------------------------------------------------------

function DspVVS_AP_off ()
	if dev == 0 then return end
	if _MCP1 () or Airbus then return end
	Dsp7("\\\\\\ ")
end

-----------------------------------------------------------------

function DspCRS (i, crs_type)
	if dev == 0 then return end
    if i == nil then return end

    if _MCP1 () then return end
	if crs_type == nil then crs_type = dme_open end
	--_loggg("[COMM] DspCRS " .. tostring(crs_open) .. ' - ' ..
	--		tostring(dme_open) )
	-- if crs_type == 1 then sync_crs = i end
	-- if crs_type == 2 then sync_crs2 = i end
	if SPD_CRS_replace and crs_open == crs_type then
		DspSPD(i)
	end
    if not RADIOS_MSG_SHORT then
        if crs_open == dme_open or dme_open == crs_type then
            ipc.sleep(30)
            com.write(dev, "dsp3/" .. DspNum(i), 8)
        end
    end
end

-----------------------------------------------------------------

function DspDME (i)
	if dev == 0 then return end
    if s == nil then return end

	if _MCP1 () then return end
	_logggg("[COMM] DspDME " .. tostring(dme_open) .. ' - ' ..
			tostring(dme_open) )
	if SPD_CRS_replace and crs_open == dme_open then
		DspSPD(i)
	end
    if not RADIOS_MSG_SHORT then
	   ipc.sleep(30)
	   com.write(dev, "dsp3/" .. DspNum(i), 8)
    end
end

-----------------------------------------------------------------

function DspHideCursor ()
	--Dsp6('\\\\\\\\')
end

-----------------------------------------------------------------

-- ## Radios display functions ###############

function isAvionicsOn ()
	return ipc.readUB(0x3103) == 1
end

-----------------------------------------------------------------

function DspRadioHideCursor ()
	-- RADIOS_MODE = 0 -- 1 com, 2 nav, 3 adf, 4 dme, 5 xpnd
	if RADIOS_MODE == 1 or RADIOS_MODE == 2 then
		if RADIOS_MhzKhz == 1 then
			ipc.sleep(20)
			com.write(dev, 'RADMhz', 8)
		else
			ipc.sleep(20)
			com.write(dev, 'RADKhz', 8)
		end
	elseif RADIOS_MODE == 3 then
		ipc.sleep(20)
		com.write(dev, 'RADA' .. tostring(RADIOS_CURSOR_POS), 8)
	elseif RADIOS_MODE == 5 then
		ipc.sleep(20)
		com.write(dev, 'RADT' .. tostring(RADIOS_CURSOR_POS), 8)
	end
end

-----------------------------------------------------------------

function DspRadioIdent_on ()
	if dev == 0 then return end
	if not (_MCP2 () or _MCP2a ()) then return end
	ipc.sleep(20)
	com.write(dev, "dsp1*\\\\\\", 8)
end

-----------------------------------------------------------------

function DspRadioIdent_off ()
	if dev == 0 then return end
	if not (_MCP2 () or _MCP2a ()) then return end
	ipc.sleep(20)
	com.write(dev, "dsp1 \\\\\\", 8)
end

-----------------------------------------------------------------

function DspRadiosShortClear ()
	if dev == 0 then return end
	if not (_MCP2 () or _MCP2a ()) then return end
	ipc.sleep(20)
	com.write(dev, "dsp3    ", 8)
end

-----------------------------------------------------------------

function DspRadiosMedClear ()
	if dev == 0 then return end
	if not (_MCP2 () or _MCP2a ()) then return end
	ipc.sleep(20)
	com.write(dev, "dsp1\\   ", 8)
	ipc.sleep(20)
	com.write(dev, "dsp2    ", 8)
	ipc.sleep(20)
	com.write(dev, "dsp3    ", 8)
end

-----------------------------------------------------------------

function DspRadioShort (s)
	if dev == 0 then return end
	if not (_MCP2 () or _MCP2a ()) then return end
	while string.len(s) < 4 do s = " " .. s end
	ipc.sleep(20)
	com.write(dev, "dsp3" .. string.sub(s, 1, 4), 8)
	ipc.set("FIP2", ipc.elapsedtime())
	RADIOS_MSG = true
	RADIOS_MSG_SHORT = true
end

-----------------------------------------------------------------

function DspRadioMed (s)
	if dev == 0 then return end
	if _MCP1() then return end
	if _MCP2() then
		while string.len(s) < 12 do s = " " .. s end
		ipc.sleep(20)
		com.write(dev, "dsp1" .. string.sub(s, 1, 4), 8)
		ipc.sleep(20)
		com.write(dev, "dsp2" .. string.sub(s, 5, 8), 8)
		ipc.sleep(20)
		com.write(dev, "dsp3" .. string.sub(s, 9, 12), 8)
		ipc.sleep(20)
	elseif _MCP2a() then
		s = DspStrMed(s)
		ipc.sleep(20)
		com.write(dev, "dsp2" .. string.sub(s, 1, 4), 8)
		ipc.sleep(20)
		com.write(dev, "dsp3" .. string.sub(s, 5, 8), 8)
	end
	ipc.set("FIP2", ipc.elapsedtime())
	RADIOS_MSG = true
end

-----------------------------------------------------------------

function DspRadioShow (s)
	if dev == 0 then return end
	if _MCP1() then return end
	while string.len(s) < 12 do s = " " .. s end
	if _MCP2() then
		ipc.sleep(20)
		com.write(dev, "dsp1\\" .. string.sub(s, 2, 4), 8)
		ipc.sleep(20)
		com.write(dev, "dsp2" .. string.sub(s, 5, 8), 8)
		ipc.sleep(20)
		com.write(dev, "dsp3" .. string.sub(s, 9, 12), 8)
		ipc.sleep(20)
	elseif _MCP2a() then
		ipc.sleep(20)
		com.write(dev, "dsp1\\" .. string.sub(s, 2, 4), 8)
		ipc.sleep(20)
		com.write(dev, "dsp2" .. string.sub(s, 5, 8), 8)
		ipc.sleep(20)
		com.write(dev, "dsp3" .. string.sub(s, 9, 12), 8)
	end
	ipc.set("FIP2", ipc.elapsedtime())
	RADIOS_MSG = true
end

-----------------------------------------------------------------

function DspRadioLong1 (s)
	if dev == 0 then return end
	if not (_MCP2 () or _MCP2a ()) then return end
	s = DspStrLong (s)
	ipc.sleep(20)
	com.write(dev, "dsp0" .. string.sub(s, 1, 4), 8)
	ipc.sleep(20)
	com.write(dev, "dsp1" .. string.sub(s, 5, 8), 8)
	ipc.sleep(20)
	com.write(dev, "dsp2" .. string.sub(s, 9, 12), 8)
	ipc.sleep(20)
	com.write(dev, "dsp3" .. string.sub(s, 13, 16), 8)
	ipc.sleep(20)
	ipc.set("FIP2", ipc.elapsedtime())
end

-----------------------------------------------------------------

function DspRadioLong2 (s)
	if dev == 0 then return end
	if not (_MCP2 () or _MCP2a ()) then return end
	s = DspStrLong (s)
	ipc.sleep(20)
	com.write(dev, "dsp4" .. string.sub(s, 1, 4), 8)
	ipc.sleep(20)
	com.write(dev, "dsp5" .. string.sub(s, 5, 8), 8)
	ipc.sleep(20)
	com.write(dev, "dsp6" .. string.sub(s, 9, 12), 8)
	ipc.sleep(20)
	com.write(dev, "dsp7" .. string.sub(s, 13, 16), 8)
	ipc.sleep(20)
	ipc.set("FIP2", ipc.elapsedtime())
end

-----------------------------------------------------------------

function DspRadio (s)
	if dev == 0 then return end
	if not (_MCP2 () or _MCP2a ()) then return end
	--if DSP_PREV_RAD_0 == s and f ~= true then return end
	DSP_PREV_RAD_0 = s
	s = DspStr(s)
	ipc.sleep(20)
	com.write(dev, "dsp0" .. s, 8)
end

-----------------------------------------------------------------

function DspRadio1 (s)
	if dev == 0 then return end
	if not (_MCP2 () or _MCP2a ()) then return end
	--if DSP_PREV_RAD_1 == s and f ~= true then return end
	DSP_PREV_RAD_1 = s
	s = DspStr(s)
	ipc.sleep(20)
	com.write(dev, "dsp1" .. s, 8)
end

-----------------------------------------------------------------

function DspRadio2 (s)
	if dev == 0 then return end
	if not (_MCP2 () or _MCP2a ()) then return end
	--if DSP_PREV_RAD_2 == s and f ~= true then return end
	DSP_PREV_RAD_2 = s
	s = DspStr(s)
	ipc.sleep(20)
	com.write(dev, "dsp2" .. s, 8)
end

-----------------------------------------------------------------

function DspRadio3 (s)
	if dev == 0 then return end
	if not (_MCP2 () or _MCP2a ()) then return end
	--if DSP_PREV_RAD_3 == s and f ~= true then return end
	DSP_PREV_RAD_3 = s
	s = DspStr(s)
	ipc.sleep(20)
	com.write(dev, "dsp3" .. s, 8)
end

-----------------------------------------------------------------

function DspRadio4 (s)
	if dev == 0 then return end
	if not (_MCP2 () or _MCP2a ()) then return end
	--if DSP_PREV_RAD_4 == s and f ~= true then return end
	DSP_PREV_RAD_4 = s
	s = DspStr(s)
	ipc.sleep(20)
	com.write(dev, "dsp4" .. s, 8)
end

-----------------------------------------------------------------

function DspRadio5 (s)
	if dev == 0 then return end
	if not (_MCP2 () or _MCP2a ()) then return end
	--if DSP_PREV_RAD_5 == s and f ~= true then return end
	DSP_PREV_RAD_5 = s
	s = DspStr(s)
	ipc.sleep(20)
	com.write(dev, "dsp5" .. s, 8)
end

-----------------------------------------------------------------

function DspRadio6 (s)
	if dev == 0 then return end
	if not (_MCP2 () or _MCP2a ()) then return end
	--if DSP_PREV_RAD_6 == s and f ~= true then return end
	DSP_PREV_RAD_6 = s
	s = DspStr(s)
	ipc.sleep(20)
	com.write(dev, "dsp6" .. s, 8)
end

-----------------------------------------------------------------

function DspRadio7 (s)
	if dev == 0 then return end
	if not (_MCP2 () or _MCP2a ()) then return end
	--if DSP_PREV_RAD_7 == s and f ~= true then return end
	DSP_PREV_RAD_7 = s
	s = DspStr(s)
	ipc.sleep(20)
	com.write(dev, "dsp7" .. s, 8)
end

-----------------------------------------------------------------

-- ## MCP LED On and Off #######
function MCP_LED_On()
	com.write(dev, "LITON__", 8)
end

-----------------------------------------------------------------

function MCP_LED_Off()
	com.write(dev, "LITOFF__", 8)
end

-----------------------------------------------------------------

-- ## Autopilot functions ###############

-- $$ Autopilot Status

function isAutopilotAvailable ()
	return ipc.readUD(0x0764) == 1
end

-----------------------------------------------------------------

function isAutopilotEngaged ()
	return ipc.readUD(0x07BC) == 1
end

-----------------------------------------------------------------

function isAutopilotInNAV ()
	return ipc.readUD(0x07C4) == 1
end

-----------------------------------------------------------------

function isAutopilotInHDG ()
	return ipc.readUD(0x07C8) == 1
end
function isAutopilotInSPD ()
	return ipc.readUD(0x07DC) == 1
end

-----------------------------------------------------------------

function isAutopilotInALT ()
	return ipc.readUD(0x07D0) == 1
end

-----------------------------------------------------------------

function isAutopilotInLOC ()
	return ipc.readUD(0x0800) == 1
end

-----------------------------------------------------------------

function isAutopilotInAPPR ()
	return ipc.readUD(0x07FC) == 1
end

-----------------------------------------------------------------

function isAutopilotInVS ()
	return ipc.readUD(0x07EC) == 1
end

-----------------------------------------------------------------

-- $$ access values

-- read available VAS within flt sim
function getSimVAS ()
    return round2(ipc.readUD(0x024C)/1000)
end

-----------------------------------------------------------------

-- read frames per second
function getSimFPS ()
    return math.floor(32768/ipc.readUD(0x0274))
end

-----------------------------------------------------------------

function getCRSValue ()
local crs
    crs = round(ipc.readUW(0x0C4E))
    if crs > 359 then crs = 0 end
	return crs
end

-----------------------------------------------------------------

function setCRSValue (value)
	ipc.writeUW(0x0C4E, value)
end

-----------------------------------------------------------------

function getHDGValue ()
	return round(ipc.readUW(0x07CC) / 65536 * 360)
end

-----------------------------------------------------------------

function setHDGValue (value)
	ipc.writeUW(0x07CC, value / 360 * 65536)
end

-----------------------------------------------------------------

function getALTValue ()
local alt
	alt = round(ipc.readUD(0x07D4) / 65536)
    --_loggg('[COMM] P3D=' .. P3D .. ' A2A=' .. A2A)
    if P3D == 1 or A2A == 1 then
        alt = round(round(alt * 3.2808399)/10) * 10
    end
    --_logggg('[awg] getALTvalue = ' .. tostring(alt))
    return alt
end

-----------------------------------------------------------------

function setALTValue (value)
local alt
    --_logggg('[awg] setALTvalue = ' .. tostring(value))
    alt = value
    if P3D == 1 or A2A == 1 then
        alt = alt / 3.2808399
    end
	ipc.writeUD(0x07D4, alt * 65536)
end

-----------------------------------------------------------------

function getSPDValue ()
	return round(ipc.readUW(0x07E2))
end

-----------------------------------------------------------------

function setSPDValue (value)
	ipc.writeUW(0x07E2, value)
end

-----------------------------------------------------------------

function getVSValue ()
local vs
	vs =  round(ipc.readSW(0x07F2))
    if not (P3D ==1 or A2A == 1) then
        vs = round(vs / 3.2808399)
    end
    return vs
end

-----------------------------------------------------------------

function setVSValue (value)
local vs
    vs = value
    if not(P3D == 1 or A2A == 1) then
        vs = round(vs * 3.2808399)
    end
	ipc.writeSW(0x07F2, vs)
end

-----------------------------------------------------------------

function getIncrDecrAmount (mode)
	if mode == 0 then
        return 100
    elseif mode == 1 then
		return 100
	else
		return 1
	end
end

-----------------------------------------------------------------
