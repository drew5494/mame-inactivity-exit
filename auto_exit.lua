local input = manager.machine.input
local joy_class = input.device_classes["joystick"]

local watch_items = {}
local last_activity_time = os.time()
local TIMEOUT = 600   -- 10 minutes (600 seconds)
local ANALOG_DEADZONE = 512 -- Threshold for axis movement

-- === 1. COLLECT ALL JOYSTICK INPUTS (Buttons, Axes, and Hats) ===
if joy_class then
    emu.print_info("[ Inactivity Monitor ] Collecting all joystick inputs...")
    for _, device in ipairs(joy_class.devices) do
        for _, item in pairs(device.items) do
            -- Identify if the item is an analog axis (XAXIS, YAXIS, etc.)
            local is_axis = item.token and string.find(item.token, "AXIS", 1, true)
            
            -- Only include items that are not null and have a code/token
            if item.code then
                table.insert(watch_items, {
                    name = item.name or "(noname)",
                    code = item.code,
                    is_axis = is_axis
                })
            end
        end
    end
end

-- === 2. FRAME POLLING FUNCTION ===
local function poll()
    local now = os.time()
    local activity_detected = false

    -- Check all watched items (Buttons, Axes, Hats)
    for _, w in ipairs(watch_items) do
        
        if w.is_axis then
            -- A. Check for ANALOG AXIS movement (e.g., XAXIS, YAXIS)
            local v = input:code_value(w.code)
            
            -- Check if the absolute value is outside the deadzone
            if math.abs(v) > ANALOG_DEADZONE then
                activity_detected = true
                -- Optionally, you can print activity:
                -- emu.print_info(string.format("Activity: %s axis moved (value=%d)", w.name, v))
                break -- Exit loop if activity is found
            end
        else
            -- B. Check for DIGITAL input (Buttons, Hat directions)
            -- code_pressed_once is best for detecting a single event
            if input:code_pressed_once(w.code) then
                activity_detected = true
                -- emu.print_info(string.format("Activity: %s pressed", w.name))
                break -- Exit loop if activity is found
            end
        end
    end

    -- Update last activity time if any input was detected
    if activity_detected then
        last_activity_time = now
    end

    -- Detect inactivity and take action
    if now - last_activity_time >= TIMEOUT then
        emu.print_info("--- NO ACTIVITY for 10 minutes ("..TIMEOUT.."s) ---")
        emu.print_info("Exiting MAME.")
        
        manager.machine:exit()
        
        -- Optionally, unregister the function to stop checking once action is taken
        emu.unregister_frame_done(poll) 
    end
end

-- register to run after each frame
emu.register_frame_done(poll, "inactivity_check")
