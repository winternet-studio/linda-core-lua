-- FUNCTION HUNTER AND LOADER
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

-- ## Initialization ###############
-- offsets
-- oCMD = x_QUEUE
-- oVAL = x_QUEUE - 2
-- oQUE = x_QUEUE - 3

-- pause / resume
LVARS_PAUSE = false

-- offsets to monitor
OFFS = {}

-- vars to monitor
LVARS = {}
HVARS = {}

WATCH_COUNT = 0

-- offset wrappers
function linda_readUB (p) return ipc.readUB(p) end
function linda_readUW (p) return ipc.readUW(p) end
function linda_readUD (p) return ipc.readUD(p) end
function linda_readDD (p) return ipc.readDD(p) end
function linda_readDB (p) return ipc.readDBL(p) end
function linda_readST (p, l) return string.format('%s',ipc.readSTR(p, l)) end
function linda_writeUB (p,v) ipc.writeUB(p,v) end
function linda_writeUW (p,v) ipc.writeUW(p,v) end
function linda_writeUD (p,v) ipc.writeUD(p,v) end
function linda_writeDD (p,v) ipc.writeDD(p,v) end
function linda_writeDB (p,v) ipc.writeDBL(p,v) end
function linda_writeST (p,v,l) ipc.writeSTR(p,v,l) end

-- switcher
OFS={}
OFS['UB'] = linda_readUB;
OFS['UW'] = linda_readUW;
OFS['UD'] = linda_readUD;
OFS['DD'] = linda_readDD;
OFS['DB'] = linda_readDB;
OFS['ST'] = linda_readST;
OFS['wUB'] = linda_writeUB;
OFS['wUW'] = linda_writeUW;
OFS['wUD'] = linda_writeUD;
OFS['wDD'] = linda_writeDD;
OFS['wDB'] = linda_writeDB;
OFS['wST'] = linda_writeST;

-- commands
cmdReady = 1
cmdListReady = 2

-- clear command offset
ipc.writeUB(x_QUEUE, 0)

-----------------------------------------------------------------

function _hnt (s, l)
	if (l == nil) or (l == '') then l = 'S' end
	ipc.log("LINDA:: [" .. l .. "] " .. s)
end

-----------------------------------------------------------------

-- ## Hunter functions ###############

-- FSUIPC loggings
function hunterFSUIPClogging (command)
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

-----------------------------------------------------------------

-- check/show LVar without watching
function hunterCheckLVar (name)
	local val = round2(tonumber(ipc.readLvar(name)), 2)
    _hnt ("LVar: " .. name .. " = " .. tostring(val), 'L')
end

-----------------------------------------------------------------

-- add Lvar monitor
function hunterGetLVar (name)
	if name == '_list_' then
		hunterListLVars ()
		return
	end
	if name == '_all_' then
		hunterAllLVars ()
		return
	end
	if name == '_clear_' then
		LVARS = {}
		_hnt ("LVars watching list cleared...")
		return
	end
	if name == '_pause_' then
		LVARS_PAUSE = true
		_hnt ("Watching paused...")
		return
	end
	if name == '_resume_' then
		LVARS_PAUSE = false
		_hnt ("Watching resumed...")
		return
	end
	local val = round2(tonumber(ipc.readLvar(name)), 2)
    LVARS[name] = val
    _hnt ("Watching new LVar: " .. name .. " = " .. tostring(val))
	-- log
end

-----------------------------------------------------------------

-- add Hvar monitor
function hunterGetHVar ()
    hunterListHVars ()
end

-----------------------------------------------------------------

-- add monitor
function hunterOffsetRead (req, show)
	local OFSid = string.sub(req, 1, 4)
	local OFStype = string.sub(req, 6, 7)
	local OFSformat = string.sub(req, 9, 11)
	local OFSstrlen = string.sub(req, 9)
	local OFSeval = string.sub(req, 13)
	if show == nil then show = true end
    --_loggg ("[O] Offset: 0x" .. OFSid .. " " .. OFStype .. ' '
    --    .. OFSformat .. ' ' .. OFSeval )
	if OFStype == 'ST' then   -- offset string type
		local valstr = OFS[OFStype](OFSid, OFSstrlen)
		if show then
			if valstr == '' then valstr = '-- empty --' end
			_hnt ('Offset: ' .. OFStype .. ' 0x' .. OFSid ..
                ' = ' .. valstr, 'O')
		end
		return valstr
	else  -- offset numeric type
		local valnum = round2(OFS[OFStype](OFSid), 2)
		if show then
			if OFSeval ~= '' then
				local eval = 'local calc = (' .. tostring(valnum)
                    .. ')' .. OFSeval .. '  return round2(calc,2)'
				local err
				local res
				local newval
				res, err = loadstring(eval)
				if res ~= nil then
					newval = res()
					if newval ~= valnum then
						_hnt ('Offset: ' .. OFStype .. ' 0x' ..
                            OFSid ..  ' = ' .. tostring(newval)
                            .. ' (' .. tostring(valnum) ..
                            OFSeval .. ')' , 'O')
					else
						_hnt ('Offset: ' .. OFStype .. ' 0x'
                            .. OFSid ..  ' = ' ..
                            tostring(newval), 'O')
					end
				else
					_err ('[O] Wrong eval expression: 0x' ..
                        OFSid ..  ' = (' .. tostring(valnum)
                        .. ')' .. OFSeval)
				end
			else
				if OFSformat == 'DEC' then
					_hnt ('Offset: ' .. OFStype .. ' 0x' ..
                        OFSid ..  ' = ' .. tostring(valnum), 'O')
				elseif OFSformat == 'HEX' then
					_hnt ('Offset: ' .. OFStype .. ' 0x' ..
                        OFSid ..  ' = ' ..
                        string.format('0x%02X', valnum) , 'O')
				else
					_hnt ('Offset: ' .. OFStype .. ' 0x' ..
                         OFSid ..  ' = ' ..
                         Hex2Bin(string.format('%04X',valnum))
                         , 'O')
				end
			end
		end -- if show
		return valnum
	end
end

-----------------------------------------------------------------

function hunterRemoveLVar (name)
    LVARS[name] = nil
	_hnt ("Watching stopped for LVar: " .. name)
end

-----------------------------------------------------------------

function hunterOffsetSet (req)
	local OFSid = string.sub(req, 1, 4)
	local OFStype = string.sub(req, 6, 7)
	local OFSformat = string.sub(req, 9, 11)
	local OFSstrlen = string.sub(req, 9)
	local OFSval = string.sub(OFSstrlen,
        string.find(OFSstrlen, ':') + 1)
	local OFSstrlen = string.sub(OFSstrlen, 1,
        string.find(OFSstrlen, ':') - 1)

	if OFStype == 'ST' then
		OFS['w' .. OFStype](OFSid, tostring(OFSval),
            tonumber(OFSstrlen))
    	_loggg ("[O] Offset set: 0x" .. OFSid ..
            " type=STR strlen=" .. OFSstrlen .. ' val=' .. OFSval )
	else
		OFS['w' .. OFStype](OFSid, tonumber(OFSval))
  	    _loggg ("[O] Offset set: 0x" .. OFSid ..
            " type=" .. OFStype .. ' format=' .. OFSformat ..
            ' strlen=' .. OFSstrlen .. ' val=' .. OFSval )
	end
end

-----------------------------------------------------------------

function hunterOffsetAdd (req)
	OFFS[req] = hunterOffsetRead (req, false)
    if OFFS[req] == '' then OFFS[req] = '-- empty --' end
	_hnt ("Watching new offset: " .. req .. " = " ..
        tostring(OFFS[req]))
end

-----------------------------------------------------------------

function hunterOffsetRemove (req)
	if req == '_all_' then
		OFFS = {}
		_hnt ("Offsets watching list cleared!")
		return
	end
    OFFS[req] = nil
	_hnt ("Watching stopped for offset: " .. req)
end

-----------------------------------------------------------------

function hunterOffsetMonitor ()
	local val =  ''
	for req, prev_val in pairs(OFFS) do
		val = hunterOffsetRead (req, false)
		if prev_val ~= val then
			OFFS[req] = val
			hunterOffsetRead (req,  true)
		end
	end
end

-----------------------------------------------------------------

function hunterGetLVarMonitor ()
	if LVARS_PAUSE then return end
	hunterOffsetMonitor ()
	HUNTER = false
	local irr = 0
	local val =  ''
	for name, prev_val in pairs(LVARS) do
		irr = irr + 1
		if irr > 10 then
			hunterOffsetMonitor ()
			irr = 0
		end
		val = round2(tonumber(ipc.readLvar(name)), 2)
		if prev_val ~= val then
			LVARS[name] = val
			_hnt ('LVar: ' .. name .. ' = ' .. tostring(val), 'L')
		end
	end
	HUNTER = true
end

-----------------------------------------------------------------

function hunterAllLVars ()
	-- log
	_loggg ("[HUNT] All LVars watching request. Preparing...")
	-- generate list
	i = 0
	while i < 65536 do
		name = ipc.getLvarName(i)
		if name == nil then
			break
		end

        _logg('[HUNT] Lvars found = ' .. tostring(i))

        local val = round2(tonumber(ipc.readLvar(name)), 2)
		LVARS[name] = val
		i = i + 1
		_loggg ("[HUNT] LVars new watch: " .. name .. " = "
            .. tostring(val))
	end
	_loggg ("[HUNT] All LVars watching started...")
end

-----------------------------------------------------------------

function hunterListLVars ()
	-- log
	_loggg ("[HUNT] LVars list requested. Preparing...")

    ipc.reloadWASM()
    ipc.sleep(1000)

	local vars = {}
	-- generate list
	i = 0
	while i < 65536 do
		name = ipc.getLvarName(i)
		if name == nil then
			break
		end
		i = i + 1
		if name ~= '' then vars[i] = name end
	end

    _logg('[HUNT] Lvars found = ' .. tostring(i))

	-- write file
	local file = assert(io.open("lvars.lst", "w"))
	for i, l in ipairs(vars) do file:write(l, "\n") end
	file:close()
	-- log
	_loggg ("[HUNT] LVars list done...")
end

-----------------------------------------------------------------

-- set var
function hunterSetLVar (name)
	local lvar = string.sub(name, 1, string.find(name, '=') - 1)
	local val = tonumber(string.sub(name, string.find(name, '=') + 1))
	ipc.writeLvar(lvar, val)
	if LVARS[lvar] == nil then
        _hnt ("LVar toggle: " .. lvar .. " = " .. tostring(val), 'L') end
end

-----------------------------------------------------------------

function hunterListHVars ()
	-- log
	_loggg ("[HUNT] HVars list requested. Preparing...")

    ipc.reloadWASM()
    ipc.sleep(1000)

	local vars = {}
	-- generate list
	i = 0
	while i < 65536 do
		name = ipc.getHvarName(i)
		if name == nil or name == '' then
			break
        else
            _logggg('[HUNT] HvarsList = ' .. tostring(i) .. '=' .. name)
		end
		i = i + 1
		if name ~= '' then vars[i] = name end
	end

    _logg ('[HUNT] Hvars found = ' .. tostring(i))

    -- write file
	local file = assert(io.open("hvars.lst", "w"))
	for i, l in pairs(vars) do --ipairs(vars) do
        _logggg('[HUNT] i = ' .. i .. '-' .. l)
        file:write(l, "\n")
    end
	file:close()
	-- log
	_loggg ("[HUNT] HVars list done...")
end

-----------------------------------------------------------------

-- set var
function hunterSetHVar (name)
    _loggg('[HUNT] hunterSetHvar = ' .. name)
    -- find 2nd ':' as divider between hvar and param
    local ptr = string.find(name, ':')
    local str = string.sub(name, ptr + 1, string.len(name))
    ptr = ptr + string.find(str, ':')
    --_loggg('[HUNT] str=' .. str .. ' p=' .. ptr)
	local hvar = string.sub(name, 1, ptr - 1)
	local param = tonumber(string.sub(name, ptr + 1))
	ipc.activateHvar(hvar, param)
	if HVARS[hvar] == nil then	_hnt ("HVar toggle: " .. hvar .. " = "
        .. tostring(param), 'L') end
end

-----------------------------------------------------------------

function hunterFSXcontrol (control)
	FSXcontrol (control)
	local param = string.sub(control, string.find(control, ':') + 1)
	control =  string.sub(control, 1, string.find(control, ':') - 1)
    --_loggg('c=' .. control)	control = tonumber(control)
	_hnt ("FSX control: " .. tostring(control) .. "  param: " .. tostring(param), 'F')
    ipc.sleep(300);
end

-----------------------------------------------------------------
