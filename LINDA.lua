-- LINDA LUA ACTIVATION AND SETUP
-- Updated for LINDA 4.1.5
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

----------------------------------------------------------------------

version = "4.1.5"

RESTART = 1
NEWAC = 0
RESTART_TIMER = ipc.elapsedtime()
ACNAME = ""
unloop = 0

ipc.set("RESTART", RESTART)

----------------------------------------------------------------------

-- errors
function _err (s)
	ipc.display(s, 8)
	ipc.log("LINDA:: ---> ERROR:: " .. s)
end

-- debug level 1 - standard
function _log (s)
	if ipc.get("DEBUG") > 0 then ipc.log("LINDA:: " .. s) end
end

-- debug level 2 - detailed
function _logg (s)
	if ipc.get("DEBUG") > 1 then ipc.log("LINDA:: " .. s) end
end

-- debug level 3 - verbose
function _loggg (s)
	if ipc.get("DEBUG") > 2 then ipc.log("LINDA:: " .. s) end
end

-- debug level 4 - DEBUG
function _logggg (s)
	if ipc.get("DEBUG") > 3 then ipc.log("LINDA:: " .. s) end
end

---------------------------------------------------------------------

-- check file exist
function file_exists(name)
   local f=io.open(name,"r")
   if f~=nil then
        ipc.log('[START] file_exists ' .. name)
        io.close(f)
        return true
   else
        ipc.log('[START] not file_exists ' .. name)
        return false
   end
end

---------------------------------------------------------------------

-- truncate string
function truncStr (str)
    x = string.len(str)
    s = ""
    i = 0
    while i < x and s ~= '\0' do
        i = i + 1
        s = string.sub(str, i, i)
    end
    s = string.sub(str, 1, i - 1)
    return s
end

---------------------------------------------------------------------

-- read aircrafts
function read_aircrafts ()
    _loggg('[START] Reading Available Aircraft Modules')

    dir = nil

    -- check for /modules installation and change to user
    pathname = ipc.get("PATH_USER") .. '/'
    dirPath = pathname .. ipc.get("PATH_ACFT")
    _loggg('[START] dir path = "' .. dirPath .. '"')
    dir_obj = lfs.dir (dirPath)
    dir = dir_obj ()

    if dir == nil then
        _loggg('[START] Error reading available aircraft modules')
    else
        while dir ~= nil do
            simfolder = ''
            ident = ipc.get("PATH_ACFT") .. dir .. "/ident.lua"
            _logggg('[START] Ident = ' .. dir .. "/ident.lua")
            if file_exists(ident) then
                _logg("[START] Aircraft found: " .. dir)
                dofile (ident)
                ACFT[simfolder] = dir
            end
            dir = dir_obj ()
        end
    end

    RESTART = 0
    ipc.set("RESTART", RESTART)

    _loggg('[START] Reading Available Aircraft Modules completed')
end

---------------------------------------------------------------------

-- read libs
function read_libs ()
    _loggg('[START] Reading Library Modules')

    local libreq = ""
    local i = 0
    dir = nil

    pathname = ipc.get("PATH_USER") .. "/"
    dirPath = pathname .. ipc.get("PATH_LIB")
    dir_obj = lfs.dir (dirPath)
    dir = dir_obj ()

    if dir == nil then
        _loggg('[START] Error reading library modules')
        return
    else

        while dir ~= nil do
            if string.find(dir, 'lib-') ~= nil then
                lib = ipc.get("PATH_LIB") .. dir
                _logg("[START] Library found: " .. dir)
                LIBS[i] = string.sub(dir,1,-5)
                i = i + 1
            end
            dir = dir_obj ()
        end

        -- load libraries
        for id, file in pairs(LIBS) do
            libreq = libreq .. ipc.get("PATH_LIB") .. file .. "#"
        end
        _logggg('[START] LibReq = ' .. libreq)
    end

	ipc.set("LIBREQ", libreq)
    _loggg('[START] Reading Library Modules completed')
end

---------------------------------------------------------------------------------

-- Detect aircraft
function Start()
local sim = 0
local path
    _loggg('[START] Detecting Aircraft')

    ACFT = {["MSFS Default"] = "MSFS Default"}
    _loggg('[START] Reading Aircraft ...')
    read_aircrafts()
    _loggg('[START] Reading Libraries ...')
    read_libs()

    RESTART = 1
    ipc.set("RESTART", RESTART)

    ipc.set("acft_handle", "MSFS Default")
	acft = truncStr(ipc.readSTR(0x3D00,255)) -- was 35
    ACNAME = acft
	airfile = ipc.readSTR(0x3C00, 255)
    pathfull = ipc.readSTR(0x3E00, 255)

    --_loggg('[START] path = ' .. pathfull)

    p1 = string.find(airfile:lower(), "simobjects", 0, true)
    ac = string.sub(airfile, p1 + 11, string.len(airfile))

    _loggg('[START] path = ' .. pathfull)
	_loggg("[START] Air file: " .. airfile)
    _loggg('[START] path = ' .. pathfull)

    _log("[START] *************************************************************")
	_log("[START] Current Aircraft: " .. acft)
	_logg("[START] Air file: " .. airfile)
    --_loggg('[START] ac = ' .. ac)
    _loggg('[START] path = ' .. pathfull)

    _loggg('[START] searching available aircraft modules..');

	for s, h in pairs(ACFT) do
        s1 = s
        s2 = ''
        s3 = ''
        f = false
        p1 = string.find(s, "*")
        p2 = string.find(s, "#")
        p3 = string.len(s)

        if p1 ~= nil then
            s1 = string.sub(s, 1, p1 - 1)
            if p2 ~= nil then
                p3 = p2 - 1
                s3 = string.sub(s, p2 + 1, string.len(s))
            end
            s2 = string.sub(s, p1 + 1, p3)
        elseif p2 ~= nil then
            s1 = string.sub(s, 1, p2 - 1)
            p3 = p2 - 1
            s3 = string.sub(s, p2 + 1, string.len(s))
        end

       if string.find(ac:upper(), s1:upper(), 0, true) and s1 ~= "" then
            m1 = true
        else
            m1 = false
        end
        if string.find(ac:upper(), s2:upper(), 0, true) and s2 ~= ""  then
            m2 = true
        else
            m2 = false
        end
        if string.find(ac:upper(), s3:upper(), 0, true) and s3 ~= ""  then
            m3 = true
        else
            m3 = false
        end

        if ((m1 and m2) or (m1 and (not m2 and s2 == ''))) and not m3 then
        	ipc.set("acft_handle", h)
            _loggg('[START] *** module found ****************************'
                .. '****************')
            f = true
		end

        _loggg('[START] s = ' .. s:upper() )
        _loggg('[START] h = ' .. h )

		if f then
			ipc.set("acft_handle", h)
            _loggg('[START] *** module found ****************************'
                .. '****************')
		end
 	end

	if ipc.get("acft_handle") == 1 then
		unloop = unloop + 1
		if unloop < 4 then
            _loggg('[START] Waiting for Aircraft Handle - retrying')
			Start()
		else
			_err("[START] Something is very wrong with aircraft detection!")
			return
		end
	end

    _log("[START] *************************************************************")
    _log("[START] Aircraft module detected: " .. ipc.get("acft_handle"))
    _log("[START] *************************************************************")

    path = ipc.get("PATH_SYS") .. "init"
    _log('[START] Calling Initialisation...')
    _loggg('[START] Path = ' .. path)

    if file_exists(path .. '.lua') then
        ipc.runlua(path .. '.lua')
    else
        _log('[START] Unable to find INIT.LUA - Try Restarting')
    end

    RESTART = 0
    ipc.set("RESTART", RESTART)

    _loggg('[START] Detecting Aircraft completed')
end

----------------------------------------------------------------------

function onFltLoad ()
	_log("[START] *************************************************************")
	_log("[START] New Flight Load - restarting...")
	_log("[START] *************************************************************")
	Start()
end

----------------------------------------------------------------------

function onPlaneSet ()
local acname = truncStr(ipc.readSTR(0x3D00, 35))
    if ACNAME ~= acname then
        _loggg('[START] ACNAME = "' .. ACNAME .. '"')
        _loggg('[START] 3D00   = "' .. acname .. '"')

        _log("[START] *************************************************************")
        _log("[START] New Aircraft Selected - restarting...")
        _log("[START] *************************************************************")
        Start()
    else
        _loggg('[START] Airplane event for same aircraft - exit')
    end
end

----------------------------------------------------------------------

function paramHandler(param)
    _log('[START] param ' .. param)
end

----------------------------------------------------------------------

-- main code starts here --------
-- LUA not ready
ipc.writeUB(0x735D, 1)

-- Starting
ipc.log("LINDA:: [START] *********************** STARTING LINDA "
    .. "***********************")

ipc.log('[START] LINDA Ver  = ' .. version)

fsuipc = ipc.readUD(0x3304)

if fsuipc == nil then
    ipc.log('[START] FSUIPC not found')
else
    hex = string.format("%x", fsuipc) -- * 255)
    ipc.log('[START] FSUIPC Ver = ' .. hex)
end
fs = ipc.readUB(0x3124)
if fsuipc == nil then
    ipc.log('[START] Flt Sim not found')
else
    hex = string.format("%d", fs) -- * 255)
    ipc.log('[START] MSFS Ver   = ' .. hex)
end

-- System paths
ipc.set("PATH_LIB", "linda/libs/")
ipc.set("PATH_ACFT", "linda/aircrafts/")
ipc.set("PATH_SYS", "linda/system/")
ipc.set("PATH_ACFT_CFG", "linda-cfg/aircrafts/")
ipc.set("PATH_SYS_CFG", "linda-cfg/system/")
--ipc.set("PATH_USER", "c:/users/andre/documents/prepar3d v5 add-ons/FSUIPC6")

-- set default flags
ipc.set("HID_ENABLED", 0)
ipc.set("VRI_ENABLED", 0)
ipc.set("VRI_DELAY", 10000)
ipc.set("VRI_MODE", 1)
ipc.set("FIP", 0)
ipc.set("GLOBAL", 0)
ipc.set("RUNAWAY", 0)
ipc.set("HID_READY", 0)
ipc.set("DEBUG", 0)
ipc.set("SAITEK", 0)
ipc.set("VAS_DISPLAY", 0)
ipc.set("FAULT", 0)
ipc.set("PATH_USER", "")

-- not a mapper
MAPPER = false
ACFT = {["FSX Default"] = "FSX Default"}
LIBS = {}
CFG = {}
VRI = {}
HID = {}

JSTK={}
JSTKrp={}
JSTKrl={}

JSTK2={}
JSTK2rp={}
JSTK2rl={}

JSTK3={}
JSTK3rp={}
JSTK3rl={}

-------------------------------------------------------------------------------

ipc.log('LINDA:: [START] Loading System Configuration files')

config = ipc.get("PATH_SYS_CFG") .. "config-sys"

if file_exists(config .. ".lua") then
    ipc.log('LINDA:: [START] Loading ' .. config)
    ipc.sleep(100)
    if file_exists(config .. '.lua') then
        ipc.log('[START] Accessing ' .. config)
        require (config)
    else
        ipc.log('[START] Error accessing ' .. config)
        return
    end
    ipc.log('LINDA:: [START] ' .. config .. ' loaded')
    ipc.set("GLOBAL", CFG["GLOBAL"])
    ipc.set("DEBUG", CFG["DEBUG"])
    ipc.set("SAITEK", CFG["SAITEK"])
    ipc.set("VAS_DISPLAY", CFG["VAS"])
    ipc.set("RUNAWAY", CFG["RUNAWAY"])
    ipc.set("FAULT", CFG["FAULT"])
    ipc.set("PATH_USER", CFG["PATH_USER"])
    _loggg('[START] path_user = ' .. ipc.get("PATH_USER") )
else
    _err ("[START] Main system config not found! Run GUI and check configs!")
    return
end

if ipc.get("DEBUG") == 0 then
    ipc.log("LINDA:: *********************************************************************")
    ipc.log("LINDA:: [START] WARNING - All LUA logging switched off !!!")
    ipc.log("LINDA:: [START] Go to Setup LINDA to switch on (if required)")
    ipc.log("LINDA:: *********************************************************************")
end

-- read HID configuration in system/config-hid.lua
config = ipc.get("PATH_SYS_CFG") .. "config-hid"
if file_exists(config .. ".lua") then
    ipc.log('LINDA:: [START] Loading ' .. config)
	require(config)
    ipc.log('LINDA:: [START] ' .. config .. ' loaded')
	ipc.set("HID_ENABLED", 1)
	ipc.set("HID_READY", 1)
else
	ipc.set("HID_ENABLED", 0)
	_err("[START] HID devices config not found. Joysticks disabled!")
	ipc.sleep(3000);
end

-- read MCP Combo configuration in system/config-vri.lua
config = ipc.get("PATH_SYS_CFG") .. "config-vri"
if file_exists(config .. ".lua") then
    local VRIEnabled, VRIType, VRIPort, VRIDelay
    ipc.log('LINDA:: [START] Loading ' .. config)
    require(config)
    ipc.log('LINDA:: [START] ' .. config .. ' loaded')

    VRIEnabled = VRI["ENABLED"]
    VRIType = VRI["TYPE"]
    VRIPort = VRI["COMPORT"]
    VRIDelay = VRI["DELAY"]
    CDUEnabled = VRI["CDU"]
    CDUPort = VRI["COMCDU"]

    if VRIEnabled == nil then VRIEnabled = 0 end
    if VRIType == nil then VRIType = 2 end
    if VRIPort == nil then VRIPort = 0 end
    if VRIDelay == nil then VRIDelay = 30 end
    if CDUEnabled == nil then CDUEnabled = 0 end
    if CDUPort == nil then CDUPort = 0 end

	ipc.set("VRI_ENABLED", VRIEnabled)
    ipc.set("VRI_DEVICE", "com" .. tostring(VRIPort))
    ipc.set("VRI_DELAY", tonumber(VRIDelay) * 1000)
    ipc.set("CDU_ENABLED", CDUEnabled)
    ipc.set("CDU_COMPORT", "com" .. tostring(CDUPort))

    -- test for VR type end
    if VRIType == 1 then
        ipc.set("VRI_TYPE", "mcp")
    elseif VRIType == 2 then
        ipc.set("VRI_TYPE", "mcp2")
    elseif VRIType == 3 then
        ipc.set("VRI_TYPE", "mcp2a")
    else
        ipc.set("VRI_TYPE", "mcp2")
    end

    _log("[START] VRInsight MCP Set = " .. tostring(ipc.get("VRI_TYPE")))
    _loggg('[START] VRI: Enabled=' .. tostring(ipc.get("VRI_ENABLED")) ..
        ' COMPort=' .. tostring(ipc.get("VRI_DEVICE") ..
        ' Delay=' .. tostring(ipc.get("VRI_DELAY"))))
else
    ipc.set("VRI_ENABLED", 0)
    _err ("[START] VRInsight config not found! MCP Combo disabled!")
    ipc.sleep(3000);
end

if (ipc.get("VRI_ENABLED") == 0) and (ipc.get("HID_ENABLED") == 0)
then
	_err ("[START] All hardware modules disabled... Exiting!")
	return
end

-------------------------------------------------------------------------------

-- Reading aircrafts folder for modules installed
--read_aircrafts ()

-- Reading _includes folder for libraries
--read_libs ()

unloop = 0

------------------------------------------------------------------------

ipc.log('LINDA:: [START] System Configuration files loaded')

------------------------------------------------------------------------------

while ((START == 1) and (ipc.elapsedtime() - TIMER < 1000)) do
   _loggg('[START] waiting for start to complete...')
end

START = 0

ipc.sleep(1000)

-- set up restart events
event.offset(0x3D00, "STR", 99, "onPlaneSet")    -- new aircraft loaded
--event.offset(0x32FC, "UW", "onPlaneSet")
event.sim(FLIGHTLOAD, "onFltLoad")               -- new scenerio loaded
event.param('paramHandler')

-------------------------------------------------------------------------------
