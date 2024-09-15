-- HANDLER FOR CDU2 (Airbus) PANELS
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

-----------------------------------------------------------------
-- ## MAIN ###############

-- reading VRI events
skip_fast = 0

-----------------------------------------------------------------
-- Handle all CDU controls (buttons)
-- called from event set up in InitEvents (in events.lua)
function CDUcontrols (h, s)
    _loggg("[CDU2] CDUcontrols CDU2 [h=" .. tostring(h) ..
        ", s=" .. tostring(s) .. "]")
	-- skip this command
	skip = false
	-- Getting first 3 chars of VRI-command to group them into functions
	group = "CDU2KEYS" --string.sub(s, 1, 3)
	-- Getting 4th and all next chars - it's an exact command in group

    if s == 'KEY/' then
        s = 'KEYSL'
        _loggg('[CDU2] key changed to KEYSL')
    end

    command = s

	-- Debug
	_logggg("[CDU2] Handle :: [" .. group .. "] / [" .. command .. "] "
	.. tostring(length))

	-- Now checking and parsing any other groups left
	if switch(command, CDU2KEYS, group, "CDU2") then
		-- Success! Found something. Exiting happy.
		return
	end
	-- Everything else. Never should happen.
	-- _err ("Error: Command group not assigned! " .. group .. " / " .. command )
end

--------------------------------------------------------------------------------

-- handle interupt timer to handle all inputs and outputs
function CDU_TIMER ()
    --_loggg("[CDU2] VRI CDU Timer")
end
----------- End of VRI Timer ----------------------------------

-- ########## DEFAULT CONTROL FUNCTIONS ####################


-- ## Tables init ############################################################ --

-- CDUKEYS block buttons and switches
CDUKEYS = {
["LSKL1"]   = CDU_Button_Press  ,
["LSKL2"]   = CDU_Button_Press  ,
["LSKL3"]   = CDU_Button_Press  ,
["LSKL4"]   = CDU_Button_Press  ,
["LSKL5"]   = CDU_Button_Press  ,
["LSKL6"]   = CDU_Button_Press  ,
["LSKR1"]   = CDU_Button_Press  ,
["LSKR2"]   = CDU_Button_Press  ,
["LSKR3"]   = CDU_Button_Press  ,
["LSKR4"]   = CDU_Button_Press  ,
["LSKR5"]   = CDU_Button_Press  ,
["LSKR6"]   = CDU_Button_Press  ,

["FUN11"]   = CDU_Button_Press  ,
["FUN12"]   = CDU_Button_Press  ,
["FUN13"]   = CDU_Button_Press  ,
["FUN14"]   = CDU_Button_Press  ,
["FUN15"]   = CDU_Button_Press  ,
["FUN16"]   = CDU_Button_Press  ,

["FUN21"]   = CDU_Button_Press  ,
["FUN22"]   = CDU_Button_Press  ,
["FUN23"]   = CDU_Button_Press  ,
["FUN24"]   = CDU_Button_Press  ,
["FUN25"]   = CDU_Button_Press  ,
["FUN26"]   = CDU_Button_Pressy  ,

["FUN31"]   = CDU_Button_Press  ,
["FUN32"]   = CDU_Button_Press  ,

["FUN41"]   = CDU_Button_Press  ,
["FUN42"]   = CDU_Button_Press  ,

["KEY1"]   = CDU_Button_Press  ,
["KEY2"]   = CDU_Button_Press  ,
["KEY3"]   = CDU_Button_Press  ,
["KEY4"]   = CDU_Button_Press  ,
["KEY5"]   = CDU_Button_Press  ,
["KEY6"]   = CDU_Button_Press  ,
["KEY7"]   = CDU_Button_Press  ,
["KEY8"]   = CDU_Button_Press  ,
["KEY9"]   = CDU_Button_Press  ,
["KEY."]   = CDU_Button_Press  ,
["KEY0"]   = CDU_Button_Press  ,
["KEY+"]   = CDU_Button_Press  ,

["KEYA"]   = CDU_Button_Press  ,
["KEYB"]   = CDU_Button_Press  ,
["KEYC"]   = CDU_Button_Press  ,
["KEYD"]   = CDU_Button_Press  ,
["KEYE"]   = CDU_Button_Press  ,
["KEYF"]   = CDU_Button_Press  ,
["KEYG"]   = CDU_Button_Press  ,
["KEYH"]   = CDU_Button_Press  ,
["KEYI"]   = CDU_Button_Press  ,
["KEYJ"]   = CDU_Button_Press  ,
["KEYK"]   = CDU_Button_Press  ,
["KEYL"]   = CDU_Button_Press  ,
["KEYM"]   = CDU_Button_Press  ,
["KEYN"]   = CDU_Button_Press  ,
["KEYO"]   = CDU_Button_Press  ,
["KEYP"]   = CDU_Button_Press  ,
["KEYQ"]   = CDU_Button_Press  ,
["KEYR"]   = CDU_Button_Press  ,
["KEYS"]   = CDU_Button_Press  ,
["KEYT"]   = CDU_Button_Press  ,
["KEYU"]   = CDU_Button_Press  ,
["KEYV"]   = CDU_Button_Press  ,
["KEYW"]   = CDU_Button_Press  ,
["KEYX"]   = CDU_Button_Press  ,
["KEYY"]   = CDU_Button_Press  ,
["KEYZ"]   = CDU_Button_Press  ,
["KEYSP"]  = CDU_Button_Press  ,
["KEYDEL"] = CDU_Button_Press  ,
["KEY/"]   = CDU_Button_Press  ,
["KEYCLR"] = CDU_Button_Press  ,

}



