
--mode enumerations
local COPTER_MODES = {[0] = "STABILIZE", [4] = "GUIDED", [9] = "LAND"}
local COPTER_MODE_GUIDED = 4
local COPTER_MODE_LAND = 9
local ALT_FRAME_ABOVE_HOME = 1
local TAKEOFF_ALTITUDE = 30
local TAKEOFF_DECISION_ALTITUDE = 5
local ALTITUDE_DECISION_PRECISION = 1


-- helper variables
local takeoff_before = false


-- takeoff and land the vehicle
function takeoff_and_land()
    local current_location = ahrs:get_location()

    -- do not proceed if there is not a valid location estimation
    if not current_location then
        return takeoff_and_land, 1000
    end

    -- get altitude above home
    if not current_location:change_alt_frame(ALT_FRAME_ABOVE_HOME) then
        return takeoff_and_land, 1000
    end
    local current_altitude = current_location:alt() * 1e-2

    -- get armable, armed, mode and altitude
    local is_armable = arming:pre_arm_checks()
    local is_armed = arming:is_armed()
    local mode_number = vehicle:get_mode()
    local mode_name = COPTER_MODES[mode_number]

    -- dummy message
    gcs:send_text(7, string.format("Armable: %s, Armed: %s, Mode %s, Altitude%0.2f", is_armable, is_armed, mode_name, current_altitude))

    if not takeoff_before then
        --set mode to GUIDED
        if mode_number ~= COPTER_MODE_GUIDED then
            vehicle:set_mode(COPTER_MODE_GUIDED)
        end

        -- arm the vehicle
        if not is_armed and is_armable then
            arming:arm()
        end

        -- takeoff vehicle
        if current_altitude < TAKEOFF_DECISION_ALTITUDE then
            vehicle:start_takeoff(TAKEOFF_ALTITUDE)
        end

        -- check takeoff success
        if TAKEOFF_ALTITUDE - current_altitude < ALTITUDE_DECISION_PRECISION then
            takeoff_before = true
        end

    else
        -- takeof before
        if mode_number ~= COPTER_MODE_LAND then
            vehicle:set_mode(COPTER_MODE_LAND)
        end
    end
    -- schedule the next call for this function
    return takeoff_and_land, 1000
end

return takeoff_and_land()