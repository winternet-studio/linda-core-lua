-- VATSIM Library
-- Updated for LINDA 4.0.0
-- Aug 2020

-- This Library provides access to stanard VATSIM functions

function VATSIM_SetStandard ()
    VATSIM_SetXPND()
    VATSIM_SetUnicom()
    Default_COM_select()
end

function VATSIM_SetUnicom()
    -- set COM1 to Unicom 122.80
    local freq
    freq = string.format("%4d", round(12280))
    Default_COM_1_set(freq)
    Default_COM_1_swap()
    DspShow("VATS","UniC")
end

function VATSIM_SetXPND()
    -- set Transponder to 2200
    ipc.sleep(50)
    Default_XPND_set (2200)
    ipc.sleep(50)
    Default_XPND_select ()
    DspShow("VATS","2200")
end

function VATSIM_Ident()
    ipc.writeSB(0x7b93,1)
    DspShow("VATS","ID")
end


_log("[LIB]  VATSIM library loaded...")
