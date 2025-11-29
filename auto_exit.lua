local input = manager.machine.input
local joy_class = input.device_classes["joystick"]

local watch_items = {}
local last_activity_time = os.time()
local TIMEOUT = 600  -- 10 minutes

-- collect only joystick button inputs
if joy_class then
    for _, device in ipairs(joy_class.devices) do
        for _, item in pairs(device.items) do
            if item.name and item.name:match("Button") then
                table.insert(watch_items, {
                    name = item.name,
                    code = item.code
                })
            end
        end
    end
end

-- poll once per frame
local function poll()
    local now = os.time()

    -- check for button press
    for _, w in ipairs(watch_items) do
        if input:code_pressed_once(w.code) then
            last_activity_time = now
        end
    end

    -- detect inactivity
    if now - last_activity_time >= TIMEOUT then
        emu.print_info("No activity for 10 minutes — exiting MAME.")
        emu.keypost("\x1b")  -- ESC
    end
end

emu.register_frame_done(poll, "inactivity_check")
