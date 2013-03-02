require('Motion_state')

--------------------------------------------------------------------------
-- Climb On Controller
--------------------------------------------------------------------------

climb_on = Motion_state.new('climb_on')
climb_on:set_joint_access(0, 'all')
climb_on:set_joint_access(1, 'lowerbody')
local dcm = climb_on.dcm

-- default parameters
climb_on.parameters = {
}

function climb_on:entry()
end

function climb_on:update()
end

function climb_on:exit()
end

return climb_on
