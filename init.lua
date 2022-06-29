local evt <const> = hs.eventtap.event
local isCmdPress = false
local stationaryCount = 0 -- 触摸板上静止不动的事件数量
local trackpadEventCount = 0 -- 触摸板上发生的事件数量
local cmdtapTimer = nil

function flagsListener(e)
	isCmdPress = false	
	stationaryCount = 0
	trackpadEventCount = 0
	local flags = e:getFlags()
  if flags.cmd and not (flags.alt or flags.shift or flags.ctrl or flags.fn) then
      local keyCode = e:getKeyCode()
      if keyCode == 0x37 then
          -- print("~~ left cmd key")
				isCmdPress = true
      end
  end
end

tapFlags = hs.eventtap.new({evt.types.flagsChanged}, flagsListener)  
tapFlags:start()

function resetTimer()
	if cmdtapTimer ~= nil then
		cmdtapTimer:stop()
		cmdtapTimer = nil
	end
end

function tapListener(e)
	if isCmdPress == false then
		trackpadEventCount = 0
		stationaryCount = 0
		return
	end

	local touches = e:getTouches()
	-- print(dump(touches))
	local touch = nil
	if touches ~= nil then
		touch = touches[1]
	end
	if touch == nil then
		return
	end

	if touch.phase == "stationary" then
		-- print(touch.phase)
		trackpadEventCount = trackpadEventCount + 1
		stationaryCount = stationaryCount + 1
	elseif touch.phase == "began" then
		stationaryCount = 0
		trackpadEventCount = 0
  elseif touch.phase == "ended" then
		-- print("trackpadEventCount: " .. trackpadEventCount)
		-- 一次 tap to click 总的事件一般不会超过 10 个，其中静止事件一般大于 2 个，按住 cmd 时，可能小于 2 个
		if isCmdPress and trackpadEventCount<10 and stationaryCount>=1 then
			-- print('tap to click fixing')
			resetTimer()
			cmdtapTimer = hs.timer.doAfter(0.1, function()
				-- print('timer complete')
				local pos = hs.mouse.absolutePosition()
				evt.newMouseEvent(evt.types.leftMouseDown, pos,{'cmd'}):post()
				evt.newMouseEvent(evt.types.leftMouseUp, pos,{'cmd'}):post()
			end)
		end
		stationaryCount = 0
		trackpadEventCount = 0
	else
		trackpadEventCount = trackpadEventCount + 1
	end

end

tapGesture = hs.eventtap.new({evt.types.gesture}, tapListener)  
tapGesture:start()

-- 正常触发时清空数据，避免程序触发
tapMouseDown = hs.eventtap.new({evt.types.leftMouseDown}, function(e)
	-- print("mouse down")
	trackpadEventCount = 0
	stationaryCount = 0
	resetTimer()
end)
tapMouseDown:start()
