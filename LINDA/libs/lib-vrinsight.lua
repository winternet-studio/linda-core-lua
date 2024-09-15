-- VRInsight
-- Updated for LINDA 4.0.0
-- Aug 2020

-- ## VRI EFIS mode switching ##############

function VRI_EFIS_MODE_toggle ()
	EFIS_MODE_toggle ()
end

function VRI_EFIS_MODE_one ()
	EFIS_MODE_one ()
end

function VRI_EFIS_MODE_two ()
	EFIS_MODE_two ()
end

function VRI_EFIS_MODE_three ()
	EFIS_MODE_three ()
end

-- ## VRI MCP mode switching ##############

function VRI_MCP_MODE_toggle ()
	MCP_MODE_toggle ()
end

function VRI_MCP_MODE_one ()
	MCP_MODE_one ()
end

function VRI_MCP_MODE_two ()
	MCP_MODE_two ()
end

function VRI_MCP_MODE_three ()
	MCP_MODE_three ()
end

-- ## VRI FCU mode switching ##############
-- retained for compatibility with v2.0

function VRI_FCU_MODE_toggle ()
	MCP_MODE_toggle ()
end

function VRI_FCU_MODE_one ()
	MCP_MODE_one ()
end

function VRI_FCU_MODE_two ()
	MCP_MODE_two ()
end

function VRI_FCU_MODE_three ()
	MCP_MODE_three ()
end

-- ## VRI USER mode switching ##############

function VRI_USER_MODE_toggle ()
    USER_MODE_toggle ()
end

function VRI_USER_MODE_one ()
	USER_MODE_one ()
end

function VRI_USER_MODE_two ()
	USER_MODE_two ()
end

function VRI_USER_MODE_three ()
	USER_MODE_three ()
end


-- ## VRI DISPLAY mode switching ##############

function VRI_DSP_MODE_toggle ()
	DSP_MODE_toggle ()
end

function VRI_DSP_MODE_flight_info ()
	DSP_MODE_one ()
end

function VRI_DSP_MODE_autopilot ()
	DSP_MODE_two ()
end

-- ## VRI KNOB mode switching ###############

function VRI_KNOB_MODE_toggle (a, b, c)
    KNOB_MODE_toggle (a, b)
end

-- ## VRI Light Panel switching ###############

function VRI_Light_PANEL_toggle ()
    Default_LAMP_toggle()
end

_log("[LIB]  VRInsight Function Library loaded...")
