-- INITIALISATION
-- Updated for LINDA 4.1.4
-- Feb 2022

-- #################################################### --
-- !!! NO USER SETTINGS IN THIS FILE  - DO NOT EDIT !!! --
-- #################################################### --

-- #################################################### --
-- !!! NO USER SETTINGS IN THIS FILE  - DO NOT EDIT !!! --
-- #################################################### --

-- #################################################### --
-- !!! NO USER SETTINGS IN THIS FILE  - DO NOT EDIT !!! --
-- #################################################### --

-- #################################################### --
-- !!! NO USER SETTINGS IN THIS FILE  - DO NOT EDIT !!! --
-- #################################################### --

-- ***************************************************************
--
--      DO NOT EDIT OR CHANGE THE CONTENTS OF THIS FILE
--
--      CORE LINDA FUNCTIONALITY
--
-- ****************************************************************

-----------------------------------------------------------------

-- debug level 1 - standard
function _log (s)
	if ipc.get("DEBUG") > 0 then ipc.log("LINDA:: " .. s) end
end

-- debug level 2 - detailed
function _logg (s)
	if ipc.get("DEBUG") > 1 then ipc.log("LINDA:: " .. s) end
end

-----------------------------------------------------------------

function InitEvents()
    EVENTS_INIT = true
    ipc.writeUB(x_LUAEVT, 1)

    -- Event to catch VRI commands from COM-port
    if dev ~= nil then
        if ipc.get("VRI_ENABLED") == 1 and dev > 0 then
	       -- main event
            _loggg('[INIT] VRI MCPcontrols event started - '.. dev)
            event.VRIread(dev, "MCPcontrols")

            -- sync back
            if not (ipc.get("VRI_TYPE") == 'mcp2a' and Airbus) then
	           event.offset(0x07E2, "UW", "SyncBackSPD")
	           event.offset(0x07CC, "UW", "SyncBackHDG")
	           event.offset(0x07D4, "UD", "SyncBackALT")
	           event.offset(0x07F2, "UW", "SyncBackVVS")
	           event.offset(0x0C4E, "UW", "SyncBackCRS")
	           event.offset(0x0C5E, "UW", "SyncBackCRS2")
            end
        end
    else
        _loggg('[INIT] VRI MCP returned nil for dev +++++')
    end

     -- Event to catch CDU commands from COM-port
    if dev2 ~= nil then
        if ipc.get("CDU_ENABLED") == 1 and dev2 > 0 then
            -- main event
            _loggg('[INIT] VRI CDUcontrols event started - '.. dev2)
            event.VRIread(dev2, "CDUcontrols")
        end
    else
        _loggg('[INIT] VRI CDU returned nil for dev2 +++++')
    end

    -- auto flight save
    _logg('[INIT] Initiating Autosave ' .. tostring(EVENTS_INIT))
    event.offset(0x0366, "UW", "AutoSaveArm") -- on ground
    if AUTOSAVE_ENGINE_CHECK == 1 then -- engines
        event.offset(0x0894, "UW", "AutoSaveEvent")
        event.offset(0x092C, "UW", "AutoSaveEvent")
        event.offset(0x09C4, "UW", "AutoSaveEvent")
        event.offset(0x0A5C, "UW", "AutoSaveEvent")
    end

    -- set up autosave events
    if AUTOSAVE_MAGNETO_CHECK == 1 then
        event.offset(0x0892, "UW", "AutoSaveEvent") end -- magneto
    if AUTOSAVE_BATTERY_CHECK == 1 then
        event.offset(0x281C, "UD", "AutoSaveEvent") end -- battery
    if AUTOSAVE_PARKING_CHECK == 1 then
        event.offset(0x0BC8, "UW", "AutoSaveEvent") end -- parking brake
    if AUTOSAVE_LIGHTS_CHECK == 1 then
        event.offset(0x0D0C, "UW", "AutoSaveEvent") end -- lights

    -- set up timer events
    event.offset(x_RELOAD, "UB", 1, 'offset_reloadConfigs')
    event.offset(x_EXEC, "STR", 60, 'offset_executeCommand')
    event.timer(20, "hidPoll") -- main timer event 50Hz

    ipc.writeUB(x_QUEUE, 0)
    ipc.writeUB(x_LUAEVT, 0) -- events ready

    EVENTS_INIT = false
end

-----------------------------------------------------------------

-- check file exist
function file_exists(name)
   local f=io.open(name,"r")
   if f~=nil then io.close(f) return true else return false end
end

-----------------------------------------------------------------

-- MAIN CODE STARTS HERE

-- communication offsets
x_RELOAD = 0x7320  -- 1/0 reload configs
x_EXEC = 0x7321    -- action string max 60 bytes
x_LUARDY = 0x735D  -- LUA ready 1:busy, 0:ready
x_LUAEVT = 0x735E  -- LUA events initialised 1:busy, 0:done
x_QUEUE = 0x735F   -- queue flag - 1:busy, 0:ready to receive

-----------------------------------------------------------------

-- var hunter
path = ipc.get("PATH_SYS") .. "hunter"

if file_exists(path .. '.lua') then
    require(path)
else
    _log("[INIT] Can not find hunter.lua file - " .. path )
end

-- Loading common functions and actions
path =ipc.get("PATH_SYS") .. "common"

if file_exists(path .. '.lua') then
    require(path)
else
    _log("[INIT] Can not find common.lua file - " .. path)
end
-----------------------------------------------------------------

_log("[INIT] Starting Initialisation...")

ipc.writeUB(x_LUARDY, 1)

MSFS = 1 -- block showmessage

ShowMessage('PLEASE WAIT! Do not operate buttons', 60)

if ipc.get("acft_handle") == nil then
	_logg("[INIT] Check the loader enabled and started!")
	return
end

-- loading optional libraries
_log('[INIT] Loading Libraries...')
if ipc.get("LIBREQ") ~= "" then
	libs = split(ipc.get("LIBREQ"), "#")
    _logggg('[INIT] libs = ' .. ipc.get("LIBREQ"))
	for i, req in pairs(libs) do
        if req ~= nil and req ~= "nil" then
		  _logg("[INIT] loading optional library: " .. req)
		  require(req)
        end
	end
end

-- Initialize system variables (in common.lua)
_log('[INIT] Initializing Common Variables...')
CommonInitVars ()

-- main joystick config
config = ipc.get("PATH_SYS_CFG") .. "config-hid"
if ipc.get("HID_ENABLED") == 1 then
    if file_exists(config .. ".lua") then
        require(config)
    else
        ipc.set("HID-ENABLED", 0)
    end
end

-- Loading aircraft module
require(ipc.get("PATH_ACFT") .. ipc.get("acft_handle") .. "/actions")

-- user global settings
config = ipc.get("PATH_SYS_CFG") .. "config-user"
if file_exists(config .. ".lua") then
	require(config)
    _log("[INIT] User GLOBAL config loaded...")
end

-- user aircraft module overrides
config = ipc.get("PATH_ACFT") .. ipc.get("acft_handle") .. "/user"
if file_exists(config .. ".lua") then
	require(config)
    _log("[INIT] User FUNCTIONS loaded...")
end

-- Loading aircraft MCP asignments
if ipc.get("VRI_ENABLED") == 1 then
	config_mcp = ipc.get("PATH_ACFT_CFG") .. ipc.get("acft_handle")
        .. "/config-" .. ipc.get("VRI_TYPE")
	if file_exists(config_mcp .. ".lua") then
		require(config_mcp)
        _log("[INIT] VRI MCP config loaded...")
	else
		_err("[INIT] MCP configs not found for current aircraft! " .. config_mcp)
        _log("*************** USER ACTION REQUIRED ****************")
        _log("Open GUI and click on MCP Combo Button to create ")
        _log("configuration files from default or templates. ")
        _log("If no MCP connected then ensure it is disabled in ")
        _log("Setup MCP Combo, then click 'Reload Lua engine' ")
        _log("to restart.")
        _log("*************** USER ACTION REQUIRED ****************")
		ShowMessage("[INIT] MCP configs not found for current aircraft. Run GUI!" , 30)
        ipc.set("VRI_ENABLED", 0)
	end
end

-- Loading aircraft CDU asignments
_loggg('[INIT] Loading CDU assignment config')
if ipc.get("CDU_ENABLED") == 1 then
	config_cdu = ipc.get("PATH_ACFT_CFG") .. ipc.get("acft_handle")
        .. "/config-cdu2"
    _loggg('[INIT] CDU_config=' .. config_cdu)
	if file_exists(config_cdu .. ".lua") then
		require(config_cdu)
        _log("[INIT] VRI CDU config loaded...")
	else
		_err("[INIT] VRI CDU configs not found for current aircraft! " .. config_cdu)
		ShowMessage("[INIT] VRI CDU config not found for current aircraft. Run GUI!" , 30)
        ipc.set("CDU_ENABLED", 0)
	end
end
-----------------------------------------------------------------

-- define P3D and A2A
if string.find(tostring(ipc.get("acft_handle")), "A2A") ~= nil then
    A2A = 1
    _logg('[START] A2A detected')
else
    A2A = 0
end

sim = ipc.readUW(0x3308)
if sim == 13 then
    P3D = 1
    _logg('[START] MSFS2020 found')
else
    P3D = 0
end

-----------------------------------------------------------------

-- Loading main engine
if ipc.get("HID_ENABLED") == 1 then
    require(ipc.get("PATH_SYS") .. "handlers-hid")
end

if ipc.get("VRI_ENABLED") == 1 then
    require(ipc.get("PATH_SYS") .. "handlers-"
        .. ipc.get("VRI_TYPE"))
end

if ipc.get("CDU_ENABLED") == 1 then
    require(ipc.get("PATH_SYS") .. "handlers-CDU2")
end

require(ipc.get("PATH_SYS") .. "events")

-- Initialize finally
_log("[INIT] Finalising Initialisation...")

-- Loading default aircraft HID assignments
if ipc.get("HID_ENABLED") == 1 then
	-- Initialise HID devices
	_logg("[INIT] Initialising HID devices...")
	hidInit()
	
	local config_hid = ipc.get("PATH_ACFT_CFG") .. 'MSFS Default'
        .. "/config-hid"
	if file_exists(config_hid .. ".lua") then
		require(config_hid)
        _log("[INIT] Default HID config loaded...")
	else
		_err("[INIT] HID configs not found for default aircraft! " .. config_hid)
        _log("[INIT] *************** USER ACTION REQUIRED ******************")
        _log("[INIT] Open GUI, select MSFS Default and click on Joystick ")
        _log("[INIT] Button to create configuration files from default")
        _log("[INIT] or templates. Then click 'Reload Lua engine' to restart.")
        _log("[INIT] *************** USER ACTION REQUIRED ******************")
		ShowMessage("HID configs not found for default aircraft. Run GUI!" , 60)
        ipc.set("HID_ENABLED", 0)
	end
end

-- Loading current aircraft HID assignments
if ipc.get("HID_ENABLED") == 1 then
	local config_hid = ipc.get("PATH_ACFT_CFG") .. ipc.get("acft_handle")
        .. "/config-hid"
	if file_exists(config_hid .. ".lua") then
		require(config_hid)
        _log("[INIT] Current aircraft (" .. ipc.get("acft_handle") .. ") HID config loaded...") --.. ipc.get("acft_handle"))
	else
		_err("[INIT] HID configs not found for current aircraft! " .. config_hid)
        _log("[INIT] *************** USER ACTION REQUIRED ******************")
        _log("[INIT] Open GUI, select current aircraft and click on Joystick ")
        _log("[INIT] Button to create configuration files from default")
        _log("[INIT] or templates. Then click 'Reload Lua engine' to restart.")
        _log("[INIT] *************** USER ACTION REQUIRED ******************")
		ShowMessage("HID configs not found for current aircraft. Run GUI!" , 60)
        ipc.set("HID_ENABLED", 0)
	end
end

-----------------------------------------------------------------

Init () -- calls Init() function in common.lua

-----------------------------------------------------------------

_log("[INIT] Module: " .. ipc.get("acft_handle") .. " Started...")

InitEvents()

if _MCP1() then Default_COM_1_init () end

-- drop commands queue flag
ipc.writeUB(x_QUEUE, 0)
buttonRepeatClear ()

-- report ready to go
if ipc.get("VRI_ENABLED") == 1 then
    if not _MCP1() then
        DspShow("Ready!", "")
    else
        DspShow("Rdy!", "    ")
    end
    ipc.sleep(1000)
end

ipc.writeUB(x_LUARDY, 0) -- LUA ready and running

-- Initialise Custom Event pointers
if type(InitCustomEvents) == 'function' then
    InitCustomEvents()
end

ShowMessage("LINDA READY...", 5) -- clear display

_log("[INIT] Ready to go, Captain!")
_log("[INIT] ***************************************************************")

-----------------------------------------------------------------
