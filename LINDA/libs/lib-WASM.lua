-- WASM
-- Updated for LINDA 4.0.5
-- May 2021
-- V 1.21

-- WASM Library for use with NSFS2021 and FSUIPC 7.1

function WASM_Test()
    lvar = "A320_Neo_MFD_NAV_MODE"
    lvar2 = "A320_Neo_MFD_Range"

    hvar = "H:A320_Neo_PFD_BTN_LS_1"
    ipc.activateHvar(hvar)

    r = ipc.readLvar(lvar)

    r = r + 1

    if r > 4 then r = 0 end

    _log('mode = ' .. r)

    ipc.writeLvar(lvar, r)

    r = ipc.readLvar(lvar2)

    _log('rng = ' .. r)

    r = r + 1

    if r > 5 then r = 0 end

    _log('mode = ' .. r)

    ipc.writeLvar(lvar2, r)

    r = ipc.readLvar(hvar)

    if r == nil then
        _log('Hvar = NIL')
    else
        _log('Hvar = ' .. r)
    end

end

_log("[LIB]  WASM Test library loaded...")
