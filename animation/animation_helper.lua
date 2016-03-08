local _P=function()
	local _M={}
	local WAITING_ON_TIME = {}
	
	-- Keep track of how long the game has been running.
	local CURRENT_TIME = 0
	
	function _M.wait_seconds(seconds)
	    -- Grab a reference to the current running coroutine.
	    local co = coroutine.running()
	
	    -- If co is nil, that means we're on the main process, which isn't a coroutine and can't yield
	    assert(co ~= nil, "The main thread cannot wait!")
	
	    -- Store the coroutine and its wakeup time in the WAITING_ON_TIME table
	    local wakeupTime = CURRENT_TIME + seconds
	    WAITING_ON_TIME[co] = wakeupTime
	
	    -- And suspend the process
	    return coroutine.yield(co)
	end
	
	function _M.update(self, deltaTime)
		if self.ended then return end
	    -- This function should be called once per game logic update with the amount of time
	    -- that has passed since it was last called
	    CURRENT_TIME = CURRENT_TIME + deltaTime
	
	    -- First, grab a list of the threads that need to be woken up. They'll need to be removed
	    -- from the WAITING_ON_TIME table which we don't want to try and do while we're iterating
	    -- through that table, hence the list.
	    local threadsToWake = {}
	    for co, wakeupTime in pairs(WAITING_ON_TIME) do
	        if wakeupTime < CURRENT_TIME then
	            table.insert(threadsToWake, co)
	        end
	    end
	
	    -- Now wake them all up.
	    for _, co in ipairs(threadsToWake) do
	        WAITING_ON_TIME[co] = nil -- Setting a field to nil removes it from the table
	        coroutine.resume(co)
	    end
	end
	
	function _M.run_process(self, func)
	    -- This function is just a quick wrapper to start a coroutine.
	    local co = coroutine.create(func)
	    return coroutine.resume(co, self)
	end
	
	_M.easing={
		[hash("linear")]=go.EASING_LINEAR,
		[hash("inoutquad")]=go.EASING_INOUTQUAD,
		[hash("outbounce")]=go.EASING_OUTBOUNCE
	}
	
	function _M.get_easing(h)
		assert(_M.easing[h], "Easing not recognised: "..h)
		return _M.easing[h]
	end
	
	return _M
end

return _P