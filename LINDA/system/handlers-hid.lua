-- MAIN HID HANDLER
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

-- ## WORKING WITH HID DEVICES ############

-----------------------------------------------------------------

-- ## Shift Functions

function SHIFT_GLOBAL_SET ()
    if ipc.get('RUNAWAY') then buttonRepeatClearAll() end
	SHIFT_GLOB = 1
	Sounds("modechange")
	_log("[hHID] Global shift set...")
end

-----------------------------------------------------------------

function SHIFT_GLOBAL_UNSET ()
    if ipc.get('RUNAWAY') then buttonRepeatClear() end
	SHIFT_GLOB = 0
	Sounds("modereset")
	_log("[hHID] Global shift UNset...")
end

-----------------------------------------------------------------

function SHIFT_LOCAL_SET (jid)
    if ipc.get('RUNAWAY') then buttonRepeatClear(jid) end
	SHIFT_LOC[jid] = 1
	Sounds("modechange")
end

-----------------------------------------------------------------

function SHIFT_LOCAL_UNSET (jid)
    if ipc.get('RUNAWAY') then buttonRepeatClear(jid) end
	SHIFT_LOC[jid] = 0
	sound.play("modereset")
end

-----------------------------------------------------------------

function SHIFT_LIM_SET (jid, m)
    if ipc.get('RUNAWAY') then buttonRepeatClear(jid) end
	SHIFT_LIM[jid] = m
    if m == 0 then
    	sound.play("modereset")
    else
    	sound.play("modechange")
    end
	_log("[hHID] SHIFT LIM " .. tostring(jid) .. " Mode = " .. m)
end

-----------------------------------------------------------------

function SHIFT_MODE_SET (m)
    if ipc.get('RUNAWAY') then buttonRepeatClear(jid) end
	SHIFT_MODE = m
    if m == 0 then
    	sound.play("modereset")
    else
    	sound.play("modechange")
    end
	_log("[hHID] SHIFT MODE = " .. m)
end

-----------------------------------------------------------------

function SHIFT_CYCLE (jid)
local m
    if (GLOBAL == 1) then
        if ipc.get('RUNAWAY') then buttonRepeatClearAll() end
        m = SHIFT_MODE + 1
        if m > 2 then
            m = 0
           	sound.play("modereset")
        else
        	sound.play("modechange")
        end
        SHIFT_MODE = m
    	_log("[hHID] SHIFT CYCLE (GLOB) = " .. m)
    else
        if ipc.get('RUNAWAY') then buttonRepeatClear(jid) end
        if SHIFT_LIM[jid] == nil then
            SHIFT_LIM[jid] = 0
        end
        m = SHIFT_LIM[jid]
        m = m + 1
        if m > 2 then
            m = 0
            sound.play("modereset")
        else
        	sound.play("modechange")
        end
        SHIFT_LIM[jid] = m
    	_log("[hHID] SHIFT MODE (LIM) = " .. m)
    end
end

-----------------------------------------------------------------

-- ## Button functions

function buttonExecute (jid, func)
	if func == nil then return end
	_loggg("[hHID] Button Execute   " .. tostring(jid) .. "/"
        .. tostring(func))

    -- handle keys function
	if string.find(func, "Keys:") ~= nil then
		KeyPress (string.sub(func, 7))
		return
	end
    -- handle control function
	if string.find(func, "Control:") ~= nil then
		FSXcontrol (string.sub(func, 10))
		return
	end
    -- handle FSX function
	if string.find(func, "FSX:") ~= nil then
        _loggg('[hHID] FSX function = ' .. func)
		FSXcontrolName (string.sub(func, 6))
		return
	end
    -- handle macro function
	if string.sub(func, 1, 2) == "M:" then
		FSUIPCmacro (string.sub(func, 4))
		ipc.writeUB('66FF', 0)
		return
	end
    -- handle function call
	if type(_G[func]) == 'function' then _G[func] (jid) end
end

-----------------------------------------------------------------

function buttonOnPress (jid, btn)
local glob, vid, pid
    if jid == nil then return end
    --_loggg('[hHID] buttonOnPress - sai_display = ' .. SAI_DISPLAY)
    -- ignore saitek radio and multi if disabled in LUA
    if SAI_DISPLAY == 0 then
        _logggg('[hHID] Checking Saitek button press ' .. jid)
        vid = string.sub(jid, 1, 4)
        pid = string.sub(jid, 5, 8)
        _logggg('[hHID] Checking Saitek vid/pid ' .. vid .. '/' .. pid)

        if vid == HexToStr(SAITEK_VID) then
            if pid == HexToStr(RADIO_PANEL_PID) then
                _loggg('[hHID] Ignore Radio button ' .. pid .. '/' .. btn)
                return
            end
            if pid == HexToStr(MULTI_PANEL_PID) then
                _loggg('[EVNT] Ignore Radio button ' .. pid .. '/' .. btn)
                return
            end
        end
    end

    if GLOBAL == 1 then glob = 1 else glob = 0 end
	_loggg("[hHID] Button OnPress   " .. tostring(jid) .. "_"
        .. tostring(btn) .. "/G: " .. glob)

    -- get HID global shift setting
    GLOBAL = ipc.get('GLOBAL')

    -- Local Shift selected
	if JSTK[jid][btn] == "LOCAL_SHIFT" then
		if SHIFT_LOC[jid] == 0 then
			SHIFT_LOCAL_SET (jid)
		else
			SHIFT_LOCAL_UNSET(jid)
            return
        end
	end
    -- Global Shift selected
	if JSTK[jid][btn] == "GLOBAL_SHIFT" then
        if 	SHIFT_GLOB == 0 then
            SHIFT_GLOBAL_SET ()
        else
            SHIFT_GLOBAL_UNSET ()
        end
		return
	end
    -- Limited Unshifted selected
	if JSTK[jid][btn] == "UNSHIFTED" and GLOBAL ~= 1 then
        _log('[hHID] Local Shift 0')
        SHIFT_LIM_SET (jid, 0)
		return
	end
    -- Limited Shifted One selected
	if JSTK[jid][btn] == "SHIFTED_ONE" and GLOBAL ~= 1 then
        _log('[hHID] Local Shift 1')
        SHIFT_LIM_SET (jid, 1)
		return
	end
    -- Limited Shifted Two selected
	if JSTK[jid][btn] == "SHIFTED_TWO" and GLOBAL ~= 1 then
        _log('[hHID] Local Shift 2')
        SHIFT_LIM_SET (jid, 2)
		return
	end

    -- Global Unshifted selected
	if JSTK[jid][btn] == "UNSHIFTED" and GLOBAL == 1 then
        SHIFT_MODE_SET (0)
		return
	end
    -- Global Shifted One selected
	if JSTK[jid][btn] == "SHIFTED_ONE" and GLOBAL == 1 then
        SHIFT_MODE_SET (1)
		return
	end
    -- Global Shifted Two selected
	if JSTK[jid][btn] == "SHIFTED_TWO" and GLOBAL == 1 then
        SHIFT_MODE_SET (2)
		return
	end
    -- Cycle Shift mode
    if JSTK[jid][btn] == "SHIFT_CYCLE" then
        SHIFT_CYCLE (jid)
        return
    end

    -- Action Button OnPress functions

    -- Remove all repeats for pressed buttons on device
    buttonRepeatRemove (jid, btn, JSTKrp[jid][btn])
    buttonRepeatRemove (jid, btn, JSTK2rp[jid][btn])
    buttonRepeatRemove (jid, btn, JSTK3rp[jid][btn])

	if (SHIFT_LOC[jid] == 1) or (SHIFT_GLOB == 1)
        or (SHIFT_LIM[jid] == 1) or (SHIFT_MODE == 1)  then
        -- shifted action
		_loggg("[hHID] Action shifted 1 " .. tostring(jid) .. '/' .. tostring(btn)
            .. " press call: " .. tostring(JSTK2[jid][btn]))
        --buttonRepeatRemove (jid, btn, JSTK2rp[jid][btn])
        buttonExecute (jid, JSTK2[jid][btn])
        -- set up shifted repeat action
        if (JSTK2rp[jid][btn] ~= nil) then
            buttonRepeatAdd (jid, btn, JSTK2rp[jid][btn])
        end
	elseif (SHIFT_MODE == 2) or (GLOBAL ~= 1 and SHIFT_LIM[jid] == 2) then
        -- double shifted action
		_loggg("[hHID] Action shifted 2 " .. tostring(jid) .. '/'
            .. tostring(btn) .. " press call: " .. tostring(JSTK3[jid][btn]))
        --buttonRepeatRemove (jid, btn, JSTK3rp[jid][btn])
		buttonExecute (jid, JSTK3[jid][btn])
        -- set up double shifted repeat action
        if (JSTK3rp[jid][btn] ~= nil) then
            buttonRepeatAdd (jid, btn, JSTK3rp[jid][btn])
        end
    else
        -- normal action
		_loggg("[hHID] Action unshifted " .. tostring(jid) .. '/'
            .. tostring(btn) .. " press call: " .. tostring(JSTK3[jid][btn]))
        --buttonRepeatRemove (jid, btn, JSTKrp[jid][btn])
		buttonExecute (jid, JSTK[jid][btn])
        -- set up repeat action
        if (JSTKrp[jid][btn] ~= nil) then
            buttonRepeatAdd (jid, btn, JSTKrp[jid][btn])
        end
	end

    -- special case of Saitek Multi Panel trim wheel
    if jid == '06A30D060' and (but == 19 or but == 20) then
        _loggg('[hHID] Saitek MP Trim cancel')
        if but == 19 then
            JREP[tostring(jid) .. '_20'] = nil
        elseif but == 20 then
            JREP[tostring(jid) .. '_19'] = nil
        end
    end
end

-----------------------------------------------------------------

function buttonRepeatAdd (jid, btn, func)
local addJID = tostring(jid) .. '_' .. tostring(btn)
	if func == "Do nothing" then return end
	_loggg("[hHID] Button RepeatAdd " .. addJID .. "/" .. tostring(func))
	JREP[addJID] = func
    JREPc[addJID] = 0
end

-----------------------------------------------------------------

function buttonOnRelease (jid, btn)
local relJID = tostring(jid) .. '_' .. tostring(btn)
local relFunc
	_loggg("[hHID] Button OnRelease " .. tostring(jid) .. '/' .. tostring(btn))
    _logggg('[hHID] func = ' .. tostring(JSTKrl[jid][btn]))
    if JSTKrl[jid][btn] == nil then
        relFunc = 'nil'
    else
        relFunc = JSTKrl[jid][btn]
    end
	_loggg("[hHID] Button OnRelease " .. relJID .. '/' .. tostring(relFunc))

    -- Local Shift selected
	if JSTK[jid][btn] == "LOCAL_SHIFT" then
		SHIFT_LOCAL_UNSET (jid)
		return
	end
    -- Global Shift selected
	if JSTK[jid][btn] == "GLOBAL_SHIFT" then
		SHIFT_GLOBAL_UNSET () -- not required as it self cancels shift.
		return
	end
    -- Unshifted selected
	if JSTK[jid][btn] == "UNSHIFTED" then
        SHIFT_MODE_SET (0)
		return
	end
    -- Shifted One selected
	if JSTK[jid][btn] == "SHIFTED_ONE" then
        SHIFT_MODE_SET (1)
		return
	end
    -- Shifted Two selected
	if JSTK[jid][btn] == "SHIFTED_TWO" then
        SHIFT_MODE_SET (2)
		return
	end

	if (SHIFT_LOC[jid] == 1) or (SHIFT_GLOB == 1)
        or (SHIFT_LIM[jid] == 1) or (SHIFT_MODE == 1) then
	    -- shifted action
	    if JSTK2rp[jid][btn] ~= nil then
            buttonRepeatRemove (jid, btn, JSTK2rp[jid][btn])
        end
		-- execute
		buttonExecute (jid, JSTK2rl[jid][btn])
		_logggg("JSTK shifted " .. tostring(jid) .. '/' .. tostring(btn)
            .. " release call: " .. tostring(JSTK2rl[jid][btn]))
    elseif SHIFT_MODE == 2 or (GLOBAL ~= 1 and SHIFT_LIM[jid] == 2) then
	    -- double shifted action
	    if JSTK3rp[jid][btn] ~= nil then
            buttonRepeatRemove (jid, btn, JSTK3rp[jid][btn])
        end
		-- execute
		buttonExecute (jid, JSTK3rl[jid][btn])
		_logggg("JSTK double shifted " .. tostring(jid) .. '/' .. tostring(btn)
            .. " release call: " .. tostring(JSTK2rl[jid][btn]))
	else
        -- normal action
        -- stop repeating action
        if JSTKrp[jid][btn] ~= nil then --or btn >= 300 then
            --_loggg('[hHID] Repeat remove ') --.. JSTKrp[jid][btn])
            buttonRepeatRemove (jid, btn, JSTKrp[jid][btn])
        end
		-- execute release action
		buttonExecute (jid, JSTKrl[jid][btn])
		_logggg("[hHID] Button Released  " .. tostring(jid) .. '_'
            .. tostring(btn) .. "/" .. tostring(JSTKrl[jid][btn]))
	end
end

-----------------------------------------------------------------

function buttonRepeatRemove (jid, btn, func)
local removeJID
	if func == "Do nothing" then return end
    removeJID = tostring(jid) .. '_' .. tostring(btn)
    _loggg('[hHID] Button Repeat Cancel ' .. removeJID .. '/'
        .. tostring(func) .. ' *****')
    JREP[removeJID] = nil
    JREPc[removeJID] = 0
    Rcount = 0
end

-----------------------------------------------------------------

function buttonRepeater ()
	for jid, func in pairs(JREP) do
		-- execute
        --_loggg('[hHID] Button Repeat    ' .. tostring(jid)
        --    .. '/' .. tostring(func))
        buttonExecute (jid, func)
        JREPc[jid] = JREPc[jid] + 1

        if JREPc[jid] > 99 then
            JREP[jid] = nil
            JREPc[jid] = 0
            _loggg('[hHID] Repeat Reset')
        elseif(jid == '06A30D060_19' or jid == '06A30D060_20') then
            --Rcount = Rcount + 1
            if JREPc[jid] > 9 then --Rcount > 9 then
                JREP['06A30D060_19'] = nil
                JREP['06A30D060_20'] = nil
                JREPc[jid] = 0
                --Rcount = 0
                _loggg('[hHID] Rcount reset')
            end
        elseif (jid == '068E00570_18' or jid == '068E00570_19') or
            (jid == '068E00570_15' or jid == '068E00570_16') then
            --Rcount = Rcount + 1
            if JREPc[jid] > 9 then -- Rcount > 9 then
                JREP['068E00570_15'] = nil
                JREP['068E00570_16'] = nil
                JREP['068E00570_18'] = nil
                JREP['068E00570_19'] = nil
                JREPc[jid] = 0
                --Rcount = 0
                _loggg('[hHID] Rcount reset')
            end
        end
	end
end

-----------------------------------------------------------------

-- ## Repeat Clearing functions

function buttonRepeatClear (jid)
local removeJID
local i, ii, iii, btn
    for i = 1, J[0] do
        if J[i][1] == jid then
            btn = J[i][5] -- get no of buttons on device
            for ii = 1, btn do
                removeJID = tostring(jid) .. '_' .. tostring(ii)
                JREP[removeJID] = nil
            end
        end
    end
    Rcount = 0
    _loggg('[hHID] OnRepeats cleared for ' .. tostring(jid) .. '....')
end

-----------------------------------------------------------------

function buttonRepeatClearAll ()
local removeJID
local i, ii, jid, btn
    for i = 1, J[0] do
        jid = J[i][1] -- get Device ID
        btn = J[i][5] -- get no of buttons on device
        for ii = 1, btn do
            removeJID = tostring(jid) .. '_' .. tostring(ii)
            JREP[removeJID] = nil
        end
    end
    Rcount = 0
    _logg('[hHID] All OnRepeats cleared....')
end

-----------------------------------------------------------------
