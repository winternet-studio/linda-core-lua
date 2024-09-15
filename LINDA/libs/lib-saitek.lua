-- Saitek Panels
-- Updated for LINDA 4.0.0
-- Aug 2020

-- ## Saitek Radio Panel ##############

-- $$ Radio Panel Mode Knobs
function SAI_RADIO1_MODE_com1 ()
	if isAvionicsOn () then
        ipc.set('SRP_MODE_1', 0)
    end
end

function SAI_RADIO1_MODE_com2 ()
	if isAvionicsOn () then
        ipc.set('SRP_MODE_1', 1)
    end
end

function SAI_RADIO1_MODE_nav1 ()
	if isAvionicsOn () then
        ipc.set('SRP_MODE_1', 2)
    end
end

function SAI_RADIO1_MODE_nav2 ()
	if isAvionicsOn () then
        ipc.set('SRP_MODE_1', 3)
    end
end

function SAI_RADIO1_MODE_adf ()
    if isAvionicsOn () then
        ipc.set('SRP_MODE_1', 4)
    end
end

function SAI_RADIO1_MODE_dme ()
	if isAvionicsOn () then
    	ipc.set('SRP_MODE_1', 5)
    end
end

function SAI_RADIO1_MODE_xpdr ()
	if isAvionicsOn () then
    	ipc.set('SRP_MODE_1', 6)
    end
end

function SAI_RADIO2_MODE_com1 ()
	if isAvionicsOn () then
        ipc.set('SRP_MODE_2', 0)
    end
end

function SAI_RADIO2_MODE_com2 ()
    if isAvionicsOn () then
        ipc.set('SRP_MODE_2', 1)
    end
end

function SAI_RADIO2_MODE_nav1 ()
    if isAvionicsOn () then
	   ipc.set('SRP_MODE_2', 2)
    end
end

function SAI_RADIO2_MODE_nav2 ()
	if isAvionicsOn () then
        ipc.set('SRP_MODE_2', 3)
    end
end

function SAI_RADIO2_MODE_adf ()
	if isAvionicsOn () then
        ipc.set('SRP_MODE_2', 4)
    end
end

function SAI_RADIO2_MODE_dme ()
    if isAvionicsOn () then
	   ipc.set('SRP_MODE_2', 5)
    end
end

function SAI_RADIO2_MODE_xpdr ()
	if isAvionicsOn () then
        ipc.set('SRP_MODE_2', 6)
    end
end

-- $$ Radio Panel Mode Toggle

function SAI_RADIO1_toggle ()
	if isAvionicsOn () then
        SAI_RADIO_toggle (ipc.get('SRP_MODE_1'))
    end
end

function SAI_RADIO2_toggle ()
	if isAvionicsOn () then
    	SAI_RADIO_toggle (ipc.get('SRP_MODE_2'))
    end
end


-- $$ Baro Ref hPa/inHg

function SAI_BARO_hPa ()
    ipc.set('SRP_QNH_UNIT', 0)
end

function SAI_BARO_inHg ()
    ipc.set('SRP_QNH_UNIT', 1)
end

function SAI_BARO_toggle ()
    local QNH = ipc.get('SRP_QNH_UNIT')
    --_loggg("[SAIT] QNH = " .. QNH)
    if QNH == 1 then
        SAI_BARO_hPa()
    else
        SAI_BARO_inHg()
    end
end


-- $$ Radio Panel Freq Knobs

function SAI_RADIO1_kHz_inc ()
    if isAvionicsOn () then
        if ipc.get('SRP_RADIO1_SMALL_KNOB_SKIP_INCREASE') == 0 then
            ipc.set('SRP_RADIO1_SMALL_KNOB_SKIP_INCREASE', 1)
            ipc.set('SRP_RADIO1_SMALL_KNOB_SKIP_DECREASE', 0)
            ipc.set('SRP_RADIO1_LARGE_KNOB_SKIP_INCREASE', 0)
            ipc.set('SRP_RADIO1_LARGE_KNOB_SKIP_DECREASE', 0)

            SAI_RADIO_kHz_inc (ipc.get('SRP_MODE_1'))
        else
            ipc.set('SRP_RADIO1_SMALL_KNOB_SKIP_INCREASE', 0)
        end
    end
end

function SAI_RADIO1_kHz_dec ()
	if isAvionicsOn () then
        if ipc.get('SRP_RADIO1_SMALL_KNOB_SKIP_DECREASE') == 0 then
            ipc.set('SRP_RADIO1_SMALL_KNOB_SKIP_DECREASE', 1)
            ipc.set('SRP_RADIO1_SMALL_KNOB_SKIP_INCREASE', 0)
            ipc.set('SRP_RADIO1_LARGE_KNOB_SKIP_DECREASE', 0)
            ipc.set('SRP_RADIO1_LARGE_KNOB_SKIP_INCREASE', 0)

            SAI_RADIO_kHz_dec (ipc.get('SRP_MODE_1'))
        else
            ipc.set('SRP_RADIO1_SMALL_KNOB_SKIP_DECREASE', 0)
        end
	end
end

function SAI_RADIO1_MHz_inc ()
	if isAvionicsOn () then
        if ipc.get('SRP_RADIO1_LARGE_KNOB_SKIP_INCREASE') == 0 then
            ipc.set('SRP_RADIO1_LARGE_KNOB_SKIP_INCREASE', 1)
            ipc.set('SRP_RADIO1_LARGE_KNOB_SKIP_DECREASE', 0)
            ipc.set('SRP_RADIO1_SMALL_KNOB_SKIP_INCREASE', 0)
            ipc.set('SRP_RADIO1_SMALL_KNOB_SKIP_DECREASE', 0)

            SAI_RADIO_MHz_inc (ipc.get('SRP_MODE_1'))
        else
            ipc.set('SRP_RADIO1_LARGE_KNOB_SKIP_INCREASE', 0)
        end
	end
end

function SAI_RADIO1_MHz_dec ()
    if isAvionicsOn () then
        if ipc.get('SRP_RADIO1_LARGE_KNOB_SKIP_DECREASE') == 0 then
            ipc.set('SRP_RADIO1_LARGE_KNOB_SKIP_DECREASE', 1)
            ipc.set('SRP_RADIO1_LARGE_KNOB_SKIP_INCREASE', 0)
            ipc.set('SRP_RADIO1_SMALL_KNOB_SKIP_DECREASE', 0)
            ipc.set('SRP_RADIO1_SMALL_KNOB_SKIP_INCREASE', 0)

            SAI_RADIO_MHz_dec (ipc.get('SRP_MODE_1'))
        else
            ipc.set('SRP_RADIO1_LARGE_KNOB_SKIP_DECREASE', 0)
        end
	end
end

function SAI_RADIO2_kHz_inc ()
	if isAvionicsOn () then
    	if ipc.get('SRP_RADIO2_SMALL_KNOB_SKIP_INCREASE') == 0 then
            ipc.set('SRP_RADIO2_SMALL_KNOB_SKIP_INCREASE', 1)
            ipc.set('SRP_RADIO2_SMALL_KNOB_SKIP_DECREASE', 0)
            ipc.set('SRP_RADIO2_LARGE_KNOB_SKIP_INCREASE', 0)
            ipc.set('SRP_RADIO2_LARGE_KNOB_SKIP_DECREASE', 0)

            SAI_RADIO_kHz_inc (ipc.get('SRP_MODE_2'))
        else
            ipc.set('SRP_RADIO2_SMALL_KNOB_SKIP_INCREASE', 0)
        end
	end
end

function SAI_RADIO2_kHz_dec ()
	if isAvionicsOn () then
        if ipc.get('SRP_RADIO2_SMALL_KNOB_SKIP_DECREASE') == 0 then
            ipc.set('SRP_RADIO2_SMALL_KNOB_SKIP_DECREASE', 1)
            ipc.set('SRP_RADIO2_SMALL_KNOB_SKIP_INCREASE', 0)
            ipc.set('SRP_RADIO2_LARGE_KNOB_SKIP_DECREASE', 0)
            ipc.set('SRP_RADIO2_LARGE_KNOB_SKIP_INCREASE', 0)

            SAI_RADIO_kHz_dec (ipc.get('SRP_MODE_2'))
        else
            ipc.set('SRP_RADIO2_SMALL_KNOB_SKIP_DECREASE', 0)
        end
	end
end

function SAI_RADIO2_MHz_inc ()
	if isAvionicsOn () then
        if ipc.get('SRP_RADIO2_LARGE_KNOB_SKIP_INCREASE') == 0 then
            ipc.set('SRP_RADIO2_LARGE_KNOB_SKIP_INCREASE', 1)
            ipc.set('SRP_RADIO2_LARGE_KNOB_SKIP_DECREASE', 0)
            ipc.set('SRP_RADIO2_SMALL_KNOB_SKIP_INCREASE', 0)
            ipc.set('SRP_RADIO2_SMALL_KNOB_SKIP_DECREASE', 0)

            SAI_RADIO_MHz_inc (ipc.get('SRP_MODE_2'))
        else
            ipc.set('SRP_RADIO2_LARGE_KNOB_SKIP_INCREASE', 0)
        end
	end
end

function SAI_RADIO2_MHz_dec ()
	if isAvionicsOn () then
        if ipc.get('SRP_RADIO2_LARGE_KNOB_SKIP_DECREASE') == 0 then
            ipc.set('SRP_RADIO2_LARGE_KNOB_SKIP_DECREASE', 1)
            ipc.set('SRP_RADIO2_LARGE_KNOB_SKIP_INCREASE', 0)
            ipc.set('SRP_RADIO2_SMALL_KNOB_SKIP_DECREASE', 0)
            ipc.set('SRP_RADIO2_SMALL_KNOB_SKIP_INCREASE', 0)

            SAI_RADIO_MHz_dec (ipc.get('SRP_MODE_2'))
        else
            ipc.set('SRP_RADIO2_LARGE_KNOB_SKIP_DECREASE', 0)
        end
	end
end

-- ## Saitek Multi Panel

function SAI_MULTI_MODE_alt ()
	if isAvionicsOn () then
    	ipc.set('SMP_MODE', 0)
        RefreshSMP()
    end
end

function SAI_MULTI_MODE_vs ()
    if isAvionicsOn () then
        ipc.set('SMP_MODE', 1)
        RefreshSMP()
    end
end

function SAI_MULTI_MODE_ias ()
	if isAvionicsOn () then
        ipc.set('SMP_MODE', 2)
        RefreshSMP()
    end
end

function SAI_MULTI_MODE_hdg ()
    if isAvionicsOn () then
        ipc.set('SMP_MODE', 3)
        RefreshSMP()
    end
end

function SAI_MULTI_MODE_crs ()
	if isAvionicsOn () then
    	ipc.set('SMP_MODE', 4)
        RefreshSMP()
    end
end

function SAI_MULTI_value_inc ()
    if isAvionicsOn () then
        if ipc.get('SMP_SKIP_INCREASE') == 0 then
            ipc.set('SMP_SKIP_INCREASE', 1)
            ipc.set('SMP_SKIP_DECREASE', 0)
    		SAI_MULTI_inc (ipc.get('SMP_MODE'))
        else
            ipc.set('SMP_SKIP_INCREASE', 0)
        end
	end
end

function SAI_MULTI_value_dec ()
	if isAvionicsOn () then
        if ipc.get('SMP_SKIP_DECREASE') == 0 then
            ipc.set('SMP_SKIP_DECREASE', 1)
            ipc.set('SMP_SKIP_INCREASE', 0)
            SAI_MULTI_dec (ipc.get('SMP_MODE'))
        else
            ipc.set('SMP_SKIP_DECREASE', 0)
        end
    end
end

-- ## General Functions

-- $$ Radio Panel - DO NOT ASSIGN
function SAI_RADIO_toggle (mode)
	if isAvionicsOn () then
    	if mode == nil or mode < 0 or mode > 6 then return end
        if mode == 0 then
            Default_COM_1_swap ()
        elseif mode == 1 then
            Default_COM_2_swap ()
        elseif mode == 2 then
            Default_NAV_1_swap ()
        elseif mode == 3 then
            Default_NAV_2_swap ()
        elseif mode == 4 then
            local active = getValueForSRP (mode, false)
            local stdby = getValueForSRP (mode, true)

            active = string.sub(active, 1, 4) .. string.sub(active, 6, 6)
            stdby = string.sub(stdby, 1, 4) .. string.sub(stdby, 6, 6)

            setValueForSRP (mode, true, active)
            setValueForSRP (mode, false, stdby)
        elseif mode == 5 then
            SAI_BARO_toggle ()
        elseif mode == 6 then
            SAI_RADIO_toggle_xpdr_cursor ()
        end
	end
end

function SAI_RADIO_MHz_inc (mode)
	if isAvionicsOn () then
    	if mode == nil or mode < 0 or mode > 6 then return end
        if mode ~= 5 and mode ~= 6 then
            local frequency = "00000"
            local mhz, khz = 0
            if mode == 4 then
                frequency = getValueForSRP (mode, true)
                mhz = tonumber(string.sub(frequency, 1, 4))
                khz = tonumber(string.sub(frequency, 6, 6))

                mhz = mhz + 1
                if mhz > 1799 then mhz = 100 end

                frequency = string.format("%04d", mhz) .. khz
            else
                frequency = string.format("%04x", getValueForSRP (mode, true))
                mhz = tonumber(string.sub(frequency, 1, 2))
                khz = tonumber(string.sub(frequency, 3, 4))

                mhz = mhz + 1
                if (mode == 0 or mode == 1) and mhz > 36 then mhz = 18 end
                if (mode == 2 or mode == 3) and mhz > 17 then mhz = 8 end

                frequency = string.format("%04d", round(mhz * 100 + khz))
            end

            if frequency ~= nil then
                ipc.sleep(20)
                setValueForSRP (mode, true, frequency)
            end
        elseif mode == 6 then
            local baroRef = getValueForSRP(mode, false)

            baroRef = baroRef + 1

            ipc.sleep(20)
            setValueForSRP(mode, false, baroRef)
        end
	end
end

function SAI_RADIO_MHz_dec (mode)
	if isAvionicsOn () then
    	if mode == nil or mode < 0 or mode > 6 then return end
        if mode ~= 5 and mode ~= 6 then
            local frequency = "00000"
            local mhz, khz = 0
            if mode == 4 then
                frequency = getValueForSRP (mode, true)
                mhz = tonumber(string.sub(frequency, 1, 4))
                khz = tonumber(string.sub(frequency, 6, 6))
                mhz = mhz - 1
                if mhz < 100 then mhz = 1799 end
                frequency = string.format("%04d", mhz) .. khz
            else
                frequency = string.format("%04x", getValueForSRP (mode, true))
                mhz = tonumber(string.sub(frequency, 1, 2))
                khz = tonumber(string.sub(frequency, 3, 4))
                mhz = mhz - 1
                if (mode == 0 or mode == 1) and mhz < 18 then mhz = 36 end
                if (mode == 2 or mode == 3) and mhz < 8 then mhz = 17 end
                frequency = string.format("%04d", round(mhz * 100 + khz))
            end

            if frequency ~= nil then
                ipc.sleep(20)
                setValueForSRP (mode, true, frequency)
            end
        elseif mode == 6 then
            local baroRef = getValueForSRP(mode, false)
            baroRef = baroRef - 1

            setValueForSRP(mode, false, baroRef)
        end
	end
end

function SAI_RADIO_kHz_inc (mode)
	if isAvionicsOn () then
        if mode == nil or mode < 0 or mode > 6 then return end
        if mode ~= 5 and mode ~= 6 then
            local frequency = "00000"
            local mhz, khz = 0
            if mode == 4 then
                frequency = getValueForSRP (mode, true)
                mhz = tonumber(string.sub(frequency, 1, 4))
                khz = tonumber(string.sub(frequency, 6, 6))
                khz = khz + 1
                if khz > 9 then khz = 0 end
                frequency = string.format("%04d", mhz) .. khz
            else
                frequency = string.format("%04x", getValueForSRP (mode, true))
                mhz = tonumber(string.sub(frequency, 1, 2))
                khz = tonumber(string.sub(frequency, 3, 4))
                local m, mm
                m, mm = math.modf(khz / 5)
                if mm > 0 then
				    khz = khz + 3
                else
				    khz = khz + 2
                end
                if khz > 97 then khz = 0 end

                frequency = string.format("%04d", round(mhz * 100 + khz))
            end

            if frequency ~= nil then
                ipc.sleep(20)
                setValueForSRP (mode, true, frequency)
            end
        elseif mode == 6 then
            local squawk = getValueForSRP(mode, true)
            local cursorPosition = ipc.get('SRP_SQUAWK_CURSOR')

            valueAtCursor = tonumber(string.sub(squawk, (cursorPosition + 1), (cursorPosition + 1)))
            valueAtCursor = valueAtCursor + 1
            if valueAtCursor > 7 then valueAtCursor = 0 end

            if valueAtCursor ~= nil then
                squawk = string.sub(squawk, 0, cursorPosition) .. tostring(valueAtCursor) .. string.sub(squawk, cursorPosition + 2)

                ipc.sleep(20)
                setValueForSRP (mode, true, squawk)
            end
        end
	end
end

function SAI_RADIO_kHz_dec (mode)
	if isAvionicsOn () then
        if mode == nil or mode < 0 or mode > 6 then return end
        if mode ~= 5 and mode ~= 6 then
            local frequency = nil
            local mhz, khz = 0
            if mode == 4 then
                frequency = getValueForSRP (mode, true)
                mhz = tonumber(string.sub(frequency, 1, 4))
                khz = tonumber(string.sub(frequency, 6, 6))

                khz = khz - 1
                if khz < 0 then khz = 9 end

                frequency = string.format("%04d", mhz) .. khz
            else
                frequency = string.format("%04x", getValueForSRP (mode, true))
                mhz = tonumber(string.sub(frequency, 1, 2))
                khz = tonumber(string.sub(frequency, 3, 4))

                local m, mm
                m, mm = math.modf(khz / 5)
                if mm > 0 then
                    khz = khz - 2
                else
                    khz = khz - 3
                end
                if khz < 0 then khz = 97 end

                frequency = string.format("%04d", round(mhz * 100 + khz))
            end

            if frequency ~= nil then
                ipc.sleep(20)
                setValueForSRP (mode, true, frequency)
            end
        elseif mode == 6 then
            local squawk = getValueForSRP(mode, true)
            local cursorPosition = ipc.get('SRP_SQUAWK_CURSOR')

            valueAtCursor = tonumber(string.sub(squawk, cursorPosition + 1, cursorPosition + 1))
            valueAtCursor = valueAtCursor - 1
            if valueAtCursor < 0 then valueAtCursor = 7 end

            if valueAtCursor ~= nil then
                squawk = string.sub(squawk, 0, cursorPosition) .. tostring(valueAtCursor) .. string.sub(squawk, cursorPosition + 2)

                ipc.sleep(20)
                setValueForSRP (mode, true, squawk)
            end
        end
	end
end

function SAI_RADIO_DME_display_speed ()
	if isAvionicsOn () then
        ipc.set('SRP_DME_STDBY', 0)
    end
end

function SAI_RADIO_DME_display_time ()
	if isAvionicsOn () then
        ipc.set('SRP_DME_STDBY', 1)
    end
end

function SAI_RADIO_toggle_DME_display ()
	if isAvionicsOn () then
        if ipc.get('SRP_DME_STDBY') == 0 then
            SAI_RADIO_DME_display_time ()
        else
            SAI_RADIO_DME_display_speed ()
        end
    end
end

function SAI_RADIO_baro_unit_hPa ()
	if isAvionicsOn () then
        ipc.set('SRP_QNH_UNIT', 0)
    end
end

function SAI_RADIO_baro_unit_inHg ()
	if isAvionicsOn () then
        ipc.set('SRP_QNH_UNIT', 1)
    end
end

function SAI_RADIO_toggle_baro_unit ()
	if isAvionicsOn () then
        if ipc.get('SRP_QNH_UNIT') == 0 then
            SAI_RADIO_pressure_unit_inHg ()
        else
            SAI_RADIO_pressure_unit_hPa ()
        end
    end
end

function SAI_RADIO_pressure_unit_hPa ()
	if isAvionicsOn () then
        ipc.set('SRP_QNH_UNIT', 0)
    end
end

function SAI_RADIO_pressure_unit_inHg ()
	if isAvionicsOn () then
        ipc.set('SRP_QNH_UNIT', 1)
    end
end

function SAI_RADIO_toggle_pressure_unit ()
	if isAvionicsOn () then
        if ipc.get('SRP_QNH_UNIT') == 0 then
            SAI_RADIO_pressure_unit_inHg ()
        else
            SAI_RADIO_pressure_unit_hPa ()
        end
    end
end

function SAI_RADIO_increase_xpdr_cursor ()
	if isAvionicsOn () then
        local newCursorPosition = ipc.get('SRP_SQUAWK_CURSOR') + 1
        if newCursorPosition > 3 then newCursorPosition = 0 end
        ipc.set('SRP_SQUAWK_CURSOR', newCursorPosition)
    end
end

function SAI_RADIO_decrease_xpdr_cursor ()
	if isAvionicsOn () then
        local newCursorPosition = ipc.get('SRP_SQUAWK_CURSOR') - 1
        if newCursorPosition < 0 then newCursorPosition = 3 end
        ipc.set('SRP_SQUAWK_CURSOR', newCursorPosition)
    end
end

function SAI_RADIO_toggle_xpdr_cursor ()
	if isAvionicsOn () then
        SAI_RADIO_increase_xpdr_cursor ()
    end
end

-- $$ Multi Panel - DO NOT ASSIGN

function SAI_MULTI_inc (mode)
    if isAvionicsOn () then
        if mode == nil or mode < 0 or mode > 4 then return end

        local value = getValueForSMP(mode, false)
        value = value + getIncrDecrAmount (mode)

        _loggg('[SAITEK] Multi-Inc value = ' .. tostring(value)
            .. '/' .. tostring(mode))

        if (mode == 3 or mode == 4) then -- HDG or CRS
            if value > 359 then
                value = 0
            end
        end

        if (mode == 0) then  -- ALT
            value = value
            if value > 50000 then
                value = 50000
            end
        end

        if value ~= nil then
            ipc.sleep(20)
            setValueForSMP (mode, value)
        end

        RefreshSMP()

        -- update MCP displays
        if (_MCP2() or _MCP2a()) then
            value = value / getIncrDecrAmount(mode)
            if mode == 0 then -- ALT
                DspALT(value)
            elseif mode == 1 then -- VVS
                DspVVS(value)
            elseif mode == 2 then -- SPD
                DspSPD(value)
            elseif mode == 3 then -- HDG
                DspHDG(value)
            elseif mode == 4 then -- CRS
                DspCRS(value)
                DspSPD2CRS()
            end
        end
    end
end

function SAI_MULTI_dec (mode)
    if isAvionicsOn () then
        if mode == nil or mode < 0 or mode > 4 then return end

        local value = getValueForSMP(mode, false)
        value = value - getIncrDecrAmount (mode)

        if (mode == 3 or mode == 4) then -- HDG or CRS
            if value < 0 then
                value = 359
            end
        end

        if (mode == 0) then  -- ALT
            _loggg('[SAI] Alt = ' .. value)
            value = value
            if value < 0 then
                value = 0
            end
        end

        if value ~= nil then
            ipc.sleep(20)
            setValueForSMP (mode, value)
        end

        RefreshSMP()

        -- update MCP displays
        if (_MCP2() or _MCP2a()) then
            if mode == 0 then
                DspALT(value/100)
            elseif mode == 1 then
                DspVVS(value/100)
            elseif mode == 2 then
                DspSPD(value)
            elseif mode == 3 then
                DspHDG(value)
            elseif mode == 4 then
                DspCRS(value)
                DspSPD2CRS()
            end
        end
    end
end

-- ## legacy function call

-- $$ Radio Panel - DO NOT ASSIGN
function SAI_RADIO1_increase_MHz ()
    SAI_RADIO1_MHz_inc()
end
function SAI_RADIO1_increase_KHz ()
    SAI_RADIO1_kHz_inc()
end
function SAI_RADIO1_decrease_MHz ()
    SAI_RADIO1_MHz_dec()
end
function SAI_RADIO1_decrease_KHz ()
    SAI_RADIO1_kHz_dec()
end
function SAI_RADIO2_increase_MHz ()
    SAI_RADIO2_MHz_inc()
end
function SAI_RADIO2_increase_KHz ()
    SAI_RADIO2_kHz_inc()
end
function SAI_RADIO2_decrease_MHz ()
    SAI_RADIO2_MHz_dec()
end
function SAI_RADIO2_decrease_KHz ()
    SAI_RADIO2_kHz_dec()
end

-- $$ Multi Panel - DO NOT ASSIGN
function SAI_MULTI_increase_value()
    SAI_MULTI_value_inc()
end

function SAI_MULTI_decrease_value()
    SAI_MULTI_value_dec()
end

_log("[LIB]  Saitek Functions loaded...")