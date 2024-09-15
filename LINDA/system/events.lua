-- MAIN EVENT HANDLER
-- Updated for LINDA 4.1.4
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

-- initiallise hidPoll counters
count = 0
count10 = 0

-----------------------------------------------------------------

-- ## Main Event Timers ###############

-- main timer event - called from event.timer set up in init
-- called at 50Hz (1000/20 ms) from init.lua event.timer
function hidPoll ()
	count = count + 1

    RESTART = ipc.get("RESTART")

    if RESTART == 1 then return end

	-- once a second
	if count % 40 == 0 then
		TimerOneSec ()
        count = 0
        count10 = count10 + 1
	end

    -- once every half second
   	if count % 20 == 0 then
		TimerHalfSec ()
	end

	-- ten times a second
	if count % 5 == 0 then
		if ipc.get("HID_ENABLED") == 1 and
            EVENTS_INIT ~= 1
        then buttonRepeater () end
		if HUNTER then hunterGetLVarMonitor () end
        MainTimer10Hz()
	end

    -- every 10 secs
    if count10 % 10 == 0 then
        -- insert 10s tasks here
        count10 = 0
    end
end

-----------------------------------------------------------------

-- One Second timer (called from hidPoll)
function TimerOneSec ()
	if not init then return end
	--_loggg('[awg] TimerOneSec ' .. '=' .. tostring(ipc.elapsedtime()))
	-- call aircraft Timer (if implemented)
	if type(Timer) == "function" then Timer () end
	-- call connect VRI MCP panel timer in handers-mcp*.lua if present
    if ipc.get("VRI_ENABLED") == 1 then
        if type(VRI_TIMER) == "function" then VRI_TIMER () end
    end
   	-- call connect VRI CDU panel timer in handers-mcp*.lua if present
    if ipc.get("CDU_ENABLED") == 1 then
        if type(CDU_TIMER) == "function" then CDU_TIMER () end
    end
    -- call User Library timer (if implemented)
	if type(LibUserTimer1Hz) == "function" then LibUserTimer1Hz () end
    -- call Special Library timer (if implemented)
	if type(LibSpecTimer1Hz) == "function" then LibSpecTimer1Hz () end
end

-----------------------------------------------------------------

-- Half Second timer (called from hidPoll)
function TimerHalfSec ()
	if not init then return end
	if dev == 0 then return end
	--_loggg('[awg] TimerHalfSec ' .. '=' .. tostring(ipc.elapsedtime()))
	-- call aircraft Timer if implemented
	--if type(Timer2) == "function" then Timer2 () end
end

-----------------------------------------------------------------
-- 10Hz timer (called from hidPoll)
function MainTimer10Hz ()
	if not init then return end
    if type(AircraftTimer10Hz) == "function" then AircraftTimer10Hz () end
	if type(LibUserTimer10Hz) == "function" then LibUserTimer10Hz () end
	if type(LibSpecTimer10Hz) == "function" then LibSpecTimer10Hz () end
	-- call connect VRI MCP panel timer in handers-mcp*.lua if present
    if ipc.get("VRI_ENABLED") == 1 then
        if type(VRI_TIMER) == "function" then VRI_TIMER () end
    end
   	-- call connect VRI CDU panel timer in handers-mcp*.lua if present
    if ipc.get("CDU_ENABLED") == 1 then
        if type(CDU_TIMER) == "function" then CDU_TIMER () end
    end
    if SAI_DISPLAY == 1 then  -- Saitek Panel handled by LUA
    	RefreshSMP ()  -- refresh Saitek Multi-Panel
        RefreshSRP ()  -- refresh Saitek Radio Panel
    end
end

-----------------------------------------------------------------

-- ## GUI Interface Functions ###############

-- interacting with GUI
function offset_reloadConfigs (offset, value)
	if EVENTS_INIT then return end
	if value == 1 then
        _loggg('[EVNT] Reloading Configs for HIDs and initialising')
		-- reloading actions.lua
		dofile(ipc.get("PATH_ACFT") .. ipc.get("acft_handle") .. "/actions.lua")

		-- main joystick config
		local config_hid = ipc.get("PATH_SYS_CFG") .. "config-hid.lua"
		if file_exists(config_hid) then
			dofile(config_hid)
			ipc.set("HID_READY", 1)
			-- Initialize HID devices
			hidInit ()
			-- loading fallback assignments HID config
			local config_hid = ipc.get("PATH_ACFT_CFG") ..
                "FSX default/config-hid.lua"
			if file_exists(config_hid) then
				dofile(config_hid)
			end
			-- loading this aircraft assignments HID config
			local config_hid = ipc.get("PATH_ACFT_CFG")
                    .. ipc.get("acft_handle") .. "/config-hid.lua"
			if file_exists(config_hid) then
				dofile(config_hid)
			end
		else
			_err ("[EVNT] HID devices config not found, module disabled!")
			ipc.set("HID_READY", 0)
			hidinit = false
		end

		-- Loading aircraft module assignments
        local config_vri = ipc.get("PATH_ACFT_CFG") .. ipc.get("acft_handle")
            .. "/config-" .. ipc.get("VRI_TYPE") .. ".lua"
        if file_exists(config_vri) then
            dofile(config_vri)
        else
            if ipc.get("VRI_ENABLED") == 1 then
                _err ('[EVNT] VRI panel config not found, module disabled!')
            end
            ipc.set("VRI_READY", 0)
            cduinit = false
        end

        local config_cdu = ipc.get("PATH_ACFT_CFG") .. ipc.get("acft_handle")
            .. "/config-cdu2" .. ".lua"
        if file_exists(config_cdu) then
            dofile(config_cdu)
        else
            if ipc.get("CDU_ENABLED") == 1 then
                _err ('[EVNT] CDU panel config not found, module disabled!')
            end
            ipc.set("CDU_READY", 0)
            cduinit = false
        end

		-- drop reload flag
		ipc.writeUB(x_RELOAD, 0)

		_logg ('[EVNT] Configs reloaded!')
	end
end

-----------------------------------------------------------------

function offset_executeCommand (offset, value)
local debug_level
local debug_level_prev

	if EVENTS_INIT then return end
	value = string.format("%s", value)
	if value ~= '' then
        _loggg('[EVNT] Execute Command = "' .. value ..'"')
		ipc.writeSTR(x_EXEC, '', 60)
		if type(_G[value]) == 'function' then
			_G[value] ()
		else
            -- action buttons
			if ipc.get("HID_ENABLED") == 1 then
                local jid, btn, vid, pid
                jid = string.sub(value, 4, 12)

                btn = tonumber(string.sub(value, 14))
				if string.find(value, "PR:") ~= nil then
                    _loggg('[EVNT] OnPress Button detected '.. value .. ' ++++++++')
					-- button press
					buttonOnPress (string.sub(value, 4, 12),
                        tonumber(string.sub(value, 14)) )
					ipc.writeUB(x_QUEUE, 0)
                    ipc.sleep(50)
					return
				end
				if string.find(value, "RL:") ~= nil then
                    _loggg('[EVNT] OnRelease Button detected ' .. value .. ' --------')
					-- button release
					buttonOnRelease (string.sub(value, 4, 12),
                        tonumber(string.sub(value, 14)) )
					ipc.writeUB(x_QUEUE, 0)
                    ipc.sleep(50)
					return
				end
			end

            -- action commands from GUI interface
			if string.find(value, "Control:") ~= nil then
                -- execute control
				FSXcontrol (string.sub(value, 10))
				ipc.writeUB(x_QUEUE, 0)
				return
			end
			if string.find(value, "FSX:") ~= nil then
                -- execute Fsx control
                _loggg('[EVNT] FSX Control ' .. value)
				FSXcontrolName (string.sub(value, 6))
				ipc.writeUB(x_QUEUE, 0)
				return
			end
			if string.sub(value, 1, 2) == "M:" then
                -- execute Macro
				FSUIPCmacro (string.sub(value, 4))
				ipc.writeUB(x_QUEUE, 0)
				return
			end

            -- LVar Watch Commands
			if string.sub(value, 1, 3) == "CL:" then
				-- check LVar value
				hunterCheckLVar (string.sub(value, 4))
				ipc.writeUB(x_QUEUE, 0)
				return
			end
            if string.sub(value, 1, 3) == "GL:" then
				-- get LVar value
				hunterGetLVar (string.sub(value, 4))
				ipc.writeUB(x_QUEUE, 0)
				return
			end
			if string.sub(value, 1, 3) == "SL:" then
				-- set LVar value
				hunterSetLVar (string.sub(value, 4))
				ipc.writeUB(x_QUEUE, 0)
				return
			end

            -- HVar Watch Commands
			if string.sub(value, 1, 3) == "GH:" then
				-- get HVar value
				hunterGetHVar ()
				ipc.writeUB(x_QUEUE, 0)
				return
			end
			if string.sub(value, 1, 3) == "HC:" then
				-- set HVar value
				hunterSetHVar (string.sub(value, 4))
				ipc.writeUB(x_QUEUE, 0)
				return
			end

            -- Offset Watch Commands
			if string.sub(value, 1, 3) == "OR:" then
				-- offset check
				hunterOffsetRead (string.sub(value, 4))
				ipc.writeUB(x_QUEUE, 0)
				return
			end
			if string.sub(value, 1, 3) == "OW:" then
				-- offset watch
				hunterOffsetAdd (string.sub(value, 4))
				ipc.writeUB(x_QUEUE, 0)
				return
			end
			if string.sub(value, 1, 3) == "OD:" then
				-- offset stop watch
				hunterOffsetRemove (string.sub(value, 4))
				ipc.writeUB(x_QUEUE, 0)
				return
			end
			if string.sub(value, 1, 3) == "OS:" then
				-- offset set
				hunterOffsetSet (string.sub(value, 4))
				ipc.writeUB(x_QUEUE, 0)
				return
			end
			if string.sub(value, 1, 3) == "FC:" then
				-- fsx control
				hunterFSXcontrol (string.sub(value, 4))
				ipc.writeUB(x_QUEUE, 0)
				return
			end
			if string.sub(value, 1, 3) == "LG:" then
				-- offset watch
                -- FSUIPC4 fix logging bits 4.962     [awg]
                hunterFSUIPClogging (string.sub(value, 4))
				ipc.writeUB(x_QUEUE, 0)
				return
			end

            -- special commands
            if string.sub(value, 1, 3) == "GB:" then
				-- offset GLOBAL Shift
                _loggg('[EVNT] GLOBAL = ' .. string.sub(value, 4))
                GLOBAL = tonumber(string.sub(value, 4))
				return
			end
            if string.sub(value, 1, 3) == "RY:" then
				-- Device Button Runaway fix
                _loggg('[EVNT] RUNAWAY = ' .. string.sub(value, 4))
                RUNAWAY = tonumber(string.sub(value, 4))
				return
			end
			if string.sub(value, 1, 3) == "VD:" then
				-- VRI display delay
                VRI_DELAY = tonumber(string.sub(value, 4))
                ipc.set("VRI_DELAY", VRI_DELAY)
                _loggg('[EVNT] VRI delay changed to ' ..
                    tostring(round(ipc.get("VRI_DELAY") / 1000)) .. 's')
				return
			end
			if string.sub(value, 1, 3) == "VM:" then
				-- VRI display mode
                VRI_MODE = tonumber(string.sub(value, 4))
                ipc.set("VRI_MODE", VRI_MODE)
                ipc.set("DSPmode", VRI_MODE)
                DSP_MODE_set()
                _loggg('[EVNT] VRI mode changed to ' ..
                    tostring(round(ipc.get("DSPmode"))))
				return
			end
			if string.sub(value, 1, 3) == "DV:" then
				-- display Sim VAS
                VAS_DISPLAY = tonumber(string.sub(value, 4))
                ipc.set("VAS_DISPLAY", VAS_DISPLAY)
                if VAS_DISPLAY == 1 then
                    _loggg('[EVNT] Display Available VAS ON')
                else
                    _loggg('[EVNT] Display Available VAS OFF')
                end
				return
			end

            -- SAITEK Panel Commands

            if string.sub(value, 1, 3) == "SC:" then
				-- blank Saitek panels
                SaitekRPStop = 1
                SaitekMPStop = 1
                ClearSRP()
                ClearSMP()
                _loggg('[EVNT] Saitek Displays Cleared')
				return
			end
            if string.sub(value, 1, 3) == "ST:" then
				-- test Saitek panels
                SaitekRPStop = 1
                SaitekMPStop = 1
                TestSRP()
                TestSMP()
                _loggg('[EVNT] Saitek Displays tested')
				return
			end
            if string.sub(value, 1, 3) == "SD:" then
				-- enable Saitek panels in LUA
                ipc.set("SAITEK", 0)
                SAI_DISPLAY = 1
                SaitekRPStop = 0
                SaitekMPStop = 0
                _loggg('[EVNT] Saitek Panels controlled by LUA')
				return
			end
            if string.sub(value, 1, 3) == "SE:" then
				-- enable Saitek panels in GUI
                ipc.set("SAITEK", 1)
                SAI_DISPLAY = 0
                SaitekRPStop = 1
                SaitekMPStop = 1
                _loggg('[EVNT] Saitek Panels controlled by GUI')
				return
			end
            if string.sub(value, 1, 3) == "SH:" then
                -- set Saitek Radio Baro to inHg
                ipc.set("SRP_QNH_UNIT", 0)
                _loggg('[EVNT] Saitek Radio Baro = inHg')
            end
            if string.sub(value, 1, 3) == "SP:" then
                -- set Saitek Radio Baro to hPa
                ipc.set("SRP_QNH_UNIT", 1)
                _loggg('[EVNT] Saitek Radio Baro = hPa')
            end

            -- Developer Mode

			if string.sub(value, 1, 3) == "DD:" then
				-- developer debug level
                debug_level_prev = ipc.get("DEBUG")
                debug_level = tonumber(string.sub(value,4))
                _loggg('[EVNT] DEBUG = ' .. tostring(debug_level))
                ipc.set("DEBUG", debug_level)
				ipc.writeUB(x_QUEUE, 0)
                if (debug_level == 0) and (debug_level_prev > 0) then
                    ipc.log('LINDA:: [EVNT] WARNING - ' ..
                        'All LUA logging switched off !!!')
                    ipc.log("LINDA:: [EVNT] Go to Setup LINDA to switch on (if required)")
                elseif (debug_level_prev == 0) and (debug_level > 0) then
                    ipc.log('LINDA:: [EVNT] LUA logging switched on' ..
                        ' - Level ' .. tostring(debug_level))
                elseif (debug_level_prev ~= debug_level) then
                    ipc.log('LINDA:: [EVNT] LUA logging level changed to ' ..
                        tostring(debug_level))
                end
				return
			end

            -- Custom Events
            if string.sub(value, 1, 3) == "EF:" then
                _logggg('[EVNT] Event Filename')
                event_index = tostring(string.sub(value, 4, 4))
                event_file = tostring(string.sub(value,5))
                _logggg('[EVNT] EvtFile = ' .. tostring(event_index) .. '>>'
                    .. tostring(event_file))
                if not (string.len(event_file) > 0) then
                    event_file = ''
                    _loggg('[EVNT] EVTFILE ' .. tostring(event_index)
                        .. ' is NULL ' .. value)
                else
                    ipc.set("EVTFILE" .. event_index, event_file)
                end
            end

            if string.sub(value, 1, 3) == "EN:" then
                _logggg('[EVNT] Event Total')
                cEvts = tonumber(string.sub(value,4))
                if cEvts == nil then
                    cEvts = 0
                end
                _loggg('[EVNT] EvtNo = ' .. tostring(cEvts))
                ipc.set("EVTNUM", cEvts)
            end

            if string.sub(value, 1, 3) == "EI:" then
                _loggg('[EVNT] Event Init')
                -- Initialise Custom Event pointers
                if type(InitCustomEvents) == 'function' then
                    InitCustomEvents()
                    if (ipc.readUB(x_LUARDY) == 0) and
                        (ipc.readUB(x_LUAEVT) == 0) then
                        ipc.writeUB(x_LUAEVT, 1)
                    end
                end
            end

            if string.sub(value, 1, 3) == "RS:" then
				-- prepare for Restart
                _loggg('[EVNT] Prepare to Restart')
                Shutdown()
                _loggg('[EVNT] Restart Ready')
				return
			end
		end
		-- if command is unrecognized then clear flag ANYWAY
		ipc.writeUB(x_QUEUE, 0)
	end
end

-----------------------------------------------------------------

-- ## HID functions ###############

-- reading HID devices
function hidInit ()
local hand, rd, rdf, wr, irep
	if ipc.get("HID_READY") ~= 1 then return end
	local Device = 0  -- Multiple devices of the same name need increasing Device numbers.
	local Report = 0
    local i

    -- initialise HID handle array
    JH={}
    for i = 1, 100 do
        JH[i] = 0
    end

    -- global shift mode flags
    SHIFT_GLOB = 0
    SHIFT_MODE = 0
    GLOBAL = ipc.get("GLOBAL")

    _loggg('[EVNT] InitHID...')
	for jid = 1, J[0] do
        --_loggg('[EVNT] jid = ' .. jid .. ' J[][4] = ' .. J[jid][4])
		if J[jid][4] == '1' then
			-- generating full dev id
			VID = tonumber(string.sub(J[jid][1],1,4), 16)
			PID = tonumber(string.sub(J[jid][1],5,8), 16)
			UID = tonumber(string.sub(J[jid][1],9))
			_logggg("[EVNT] Opening HID Dev=" .. VID .. '-' .. PID .. ' ' .. UID)
			-- jdev[jid], rd[jid], wrf[jid], wr[jid], init1[jid] =

            if not (CHY==-1 and (VID==0x068E and PID==0x00FF)) then
                hand, rd, rdf, wr, irep = com.openhid(VID, PID, UID, Report)
                _logggg("[EVNT] HID opened");
            else
                _logggg("[EVNT] CH Yoke not opened")
            end

            if hand ~= nil then
                JH[jid] = hand
                _logggg('[EVNT] HID handle ' .. tostring(jid) .. ' = ' .. tostring(hand))
            else
                _logggg('[EVNT] HID handle ' .. tostring(jid) .. ' is NIL = ' .. tostring(hand))
                JH[jid] = 0
            end

            prevbuttons[jid] = 0

            -- local shift mode flags
	       	SHIFT_LOC[jid] = 0
            SHIFT_LIM[jid] = 0

			-- init assignments tables
				JSTK[J[jid][1]]={}
			  JSTKrp[J[jid][1]]={}
			  JSTKrl[J[jid][1]]={}

			   JSTK2[J[jid][1]]={}
			 JSTK2rp[J[jid][1]]={}
			 JSTK2rl[J[jid][1]]={}

			   JSTK3[J[jid][1]]={}
			 JSTK3rp[J[jid][1]]={}
			 JSTK3rl[J[jid][1]]={}

			jdev[jid] = 1
			-- if dev found and active...
			if jdev[jid] ~= 0 then
				--_loggg("[EVNT] Joystick found: " .. J[jid][2] .. ' ['
                --    .. tostring(jdev[jid]) .. '|' .. tostring(PID) .. ']')
				-- saving jid ->> devid table
				JDEVID[jid] = J[jid][1]
				JPID[jid] = PID
				JVID[jid] = VID

				-- reading and parsing hats string
				if J[jid][7] ~= "" then
					-- init hat tables
					prevval[jid] = {}
					JHATS[jid] = {}

					JHATS[jid] = split(J[jid][7], ",")

					-- saving number of hats for this device
					J[jid][7] = tablelength(JHATS[jid])

					-- init tables for hats
					for ii = 1, J[jid][7] do
						prevval[jid][ii] = -1
						newval[jid] = {}
					end
					--_loggg("[EVNT] Hat:  " .. JHATS[jid][1])
					--_loggg("[EVNT] Hats: " .. tostring(J[jid][7]))
				else
					J[jid][7] = 0
				end
				jcount = jcount + 1
				hidinit = true
			end
		end -- if enabled
	end
    buttonRepeatClear()
end

-----------------------------------------------------------------

function hidClose()
local i, ii, hand
    i = J[0]
    _logggg('[EVNT] Closing HID ' .. i .. ' handles')
	for ii = 1, i do
        hand = JH[ii]
        _logggg('[EVNT] Closing HID handle ' .. tostring(ii) .. ' = ' .. hand)
        if hand ~= 0 then
            --com.close(hand)
        end
    end
end

-----------------------------------------------------------------

function hidHandle (jid, prev, curr)
	local b = 0
	-- bprev = Hex2Bin(string.format("%08x", prev))
	bcurr = Hex2Bin(string.format("%08x", curr))
	bxor = Hex2Bin(string.format("%08x", logic.Xor(prev, curr)))
	_logggg("[EVNT] HID Handle " .. JDEVID[jid] .. ' : ' .. bcurr)

    -- check for change in GLOBAL shift
    ipc.set("GLOBAL", CFG["GLOBAL"])

	-- scan for what is changed
	for i = 1, 32 do
		b = 33 - i
		if string.sub(bxor, i, i) == '1' then
			if string.sub(bcurr, i, i) == '1' then
			-- pressed
				--_loggg(JDEVID[jid] .. ' press : ' .. bcurr .. ' / ' .. tostring(b))
				buttonOnPress (JDEVID[jid], b)
			else
			-- released
				--_loggg(JDEVID[jid] .. ' release : ' .. bcurr .. ' / ' .. tostring(b))
				buttonOnRelease (JDEVID[jid], b)
			end
		end
	end
end

-----------------------------------------------------------------

function hidHandleHat (jid, hat, val, prev)
	local b = 280 + (20 * hat) + val + 1
	local bp = 280 + (20 * hat) + prev + 1
	-- _loggg(JDEVID[jid] .. ' : ' .. b)
	if val > -1 then
	-- pressed
		buttonOnPress (JDEVID[jid], b)
		buttonOnRelease (JDEVID[jid], bp)
	else
	-- released
		buttonOnRelease (JDEVID[jid], bp)
	end
end

-----------------------------------------------------------------

-- ## SYNC BACKS ###############
-- updates MCP displayed values every 500ms or immediately if
-- overriden

-- SYNC BACKS
function SyncBackSPD (offset, value, over)
	if ipc.elapsedtime() - ipc.get("FIP") > 500 or over == true then
		if value ~= sync_spd then
			sync_spd = value
            if not Airbus or _MCP1() then
                DspSPD(value)
            end
		end
	end
end

-----------------------------------------------------------------

function SyncBackHDG (offset, value, over)
	if ipc.elapsedtime() - ipc.get("FIP") > 500 or over == true then
		if value ~= sync_hdg then
			sync_hdg = value
			DspHDG(round(value/65536*360))
		end
	end
end

-----------------------------------------------------------------

function SyncBackALT (offset, value, over)
	if ipc.elapsedtime() - ipc.get("FIP") > 500 or over == true then
		if value ~= sync_alt then
			sync_alt = value
			DspALT(value/65536*3.28084/100)
		end
	end
end

-----------------------------------------------------------------

function SyncBackVVS (offset, value, over)
	if ipc.elapsedtime() - ipc.get("FIP") > 500 or over == true then
		local l
		if value ~= sync_vvs then
			sync_vvs = value
			if value > 16384 then
				value = 0 - (65536 - value)
			end
			DspVVS(value/100)
		end
	end
end

-----------------------------------------------------------------

function SyncBackCRS (offset, value, over)
	if ipc.elapsedtime() - ipc.get("FIP") > 500 or over == true then
		if value ~= sync_crs then
			sync_crs = value
			DspCRS(value, 1)
		end
	end
end

-----------------------------------------------------------------

function SyncBackCRS2 (offset, value, over)
	if ipc.elapsedtime() - ipc.get("FIP") > 500 or over == true then
		if value ~= sync_crs2 then
			sync_crs2 = value
			DspCRS(value, 2)
		end
	end
end

-----------------------------------------------------------------

-- ## Auto Save ###############

function AutoSaveEvent (offset, value)
	if EVENTS_INIT then return end
	if AUTOSAVE_ENABLE == 0 then return end
	if FLIGHT_SAVED then return end

	-- todo: module specific checks
	--[[
	if type(ReadyToSave) == "function" then
		READY_TO_SAVE = ReadyToSave()
	else
		READY_TO_SAVE = false
	end

	if READY_TO_SAVE then
		SaveFlight()
		return
	end
	--]]

	-- engine off
	if offset == 0x0892 then
		_logg("[EVNT] Autosave 'Magneto' event occured...")
	-- battery off
	elseif offset == 0x281C then
		_logg("[EVNT] Autosave 'Battery' event occured...")
	-- parking brake
	elseif offset == 0x0BC8 then
		_logg("[EVNT] Autosave 'Parking brake' event occured...")
	-- lights
	elseif offset == 0x0D0C then
		_logg("[EVNT] Autosave 'Lights' event occured...")
	-- engines
	elseif offset == 0x0894 or offset == 0x092C or
                offset == 0x09C4 or offset == 0x0A5C then
		_logg("[EVNT] Autosave 'Engines' event occured...")
	end
	local test = 5
	if AUTOSAVE_ENGINE_CHECK == 0 then
		test = test - 1
	else
		if ipc.readUW(0x0894) + ipc.readUW(0x092C)
                + ipc.readUW(0x09C4) + ipc.readUW(0x0A5C) == 0 then
			test = test - 1
		end
	end
	if AUTOSAVE_MAGNETO_CHECK == 0 or ipc.readUD(0x0892) == 0 then
        test = test - 1
    end
	if AUTOSAVE_BATTERY_CHECK == 0 or ipc.readUD(0x281C) == 0 then
        test = test - 1
    end
	if AUTOSAVE_PARKING_CHECK == 0 or ipc.readUW(0x0BC8) == 32767 then
        test = test - 1
    end
	if AUTOSAVE_LIGHTS_CHECK == 0 or ipc.readUW(0x0D0C) == 0 then
        test = test - 1
    end
	if test == 0 and not FLIGHT_SAVED then
		SaveFlight('', 1)
	else
		_log("[EVNT] ... flight not saved!")
	end
end

-----------------------------------------------------------------

function AutoSaveArm (offset, value)
	if EVENTS_INIT then return end
	if value ~= AUTOSAVE_TOUCHDOWN then
		if value == 1 then
			_log("[EVNT] Touchdown ...")
		else
			_log("[EVNT] Airborne ...")
		end
		if (AUTOSAVE_ENABLE == 0) or (not FLIGHT_SAVED) then return end
		-- any 'on ground' state change arms autosave
		FLIGHT_SAVED = false
		_log("[EVNT] Autosave armed ...")
		AUTOSAVE_TOUCHDOWN = value
	end
end

-----------------------------------------------------------------
