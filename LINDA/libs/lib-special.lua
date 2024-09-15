-- Special functions
-- Updated for LINDA 4.0.0
-- Aug 2020

-- This library module contains special developer functions designed to extend LINDA operations
-- DO NOT DELETE OR CHANGE - RISK OF ERRORS

function logTestSet()
    cmd = 'S:' .. tostring(63)
    hunterFSUIPClogtest (cmd)
end

function logTestClear()
    cmd = 'C:' .. tostring(63)
    hunterFSUIPClogtest (cmd)
end

function logTestAllClear()
    cmd = 'C:' .. tostring(61)
    hunterFSUIPClogtest (cmd)
    ipc.sleep(50)
    cmd = 'C:' .. tostring(62)
    hunterFSUIPClogtest (cmd)
    ipc.sleep(50)
    cmd = 'C:' .. tostring(63)
    hunterFSUIPClogtest (cmd)
    ipc.sleep(50)
end

function hunterFSUIPClogtest (command)
	local param = string.sub(command, string.find(command, ':') + 1)
	command =  string.sub(command, 1, string.find(command, ':') - 1)
	if command == 'S' then
		ipc.setbitsUW('3400', 2^param)
		_hnt ("FSUIPC logging bit set: " .. param)
	else
		ipc.clearbitsUW('3400', 2^param)
		_hnt ("FSUIPC logging bit cleared: " .. param)
	end
end

function modechange()
    playsound("modechange")
end

function playsound(s)
    sound.play(s)
end

function ParkBrake_on ()
local b
    b = ipc.readUW("0BC8")
    _loggg('[USER] Park Brake = ' .. tostring(b))
    ipc.writeUW("0BC8", 16383)
    DspShow ("PARK", "on")
end

function ParkBrake_off ()
    b = ipc.readUW("0BC8")
    _loggg('[USER] Park Brake = ' .. tostring(b))
    ipc.writeUW("0BC8", 0)
    DspShow ("PARK", "off")
end

function FSVAS_on()
    VAS_DISPLAY = 1
    ipc.set('VAS_DISPLAY', VAS_DISPLAY)
    DspShow ("VAS", "on")
    RADIOS_MSG = true
    RADIOS_MSG_SHORT = true
    DspFSVAS()
end

function FSVAS_off()
    VAS_DISPLAY = 0
    ipc.set('VAS_DISPLAY', VAS_DISPLAY)
    DspShow ("VAS", "off")
    RADIOS_MSG = false
    RADIOS_MSG_SHORT = false
    DspRadiosMedClear()
end

function FSVAS_toggle()
    VAS_DISPLAY = 1 - VAS_DISPLAY
    ipc.set('VAS_DISPLAY', VAS_DISPLAY)
    if VAS_DISPLAY == 1 then
        FSVAS_on()
    else
        FSVAS_off()
    end
end

-- insert functions to be called at 1Hz here
function LibSpecTimer1Hz ()
    DspFSVAS()
end

_log("[LIB]  User Library loaded...")
