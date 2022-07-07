local obj = {}
obj.__index = obj

-- Metadata
obj.name = "Tapfix for mbp 14"
obj.version = "1.0"
obj.author = "lcomplete"
obj.homepage = "https://github.com/lcomplete/hammerspoon_mbp14_tap_to_click_fix"
obj.license = "MIT - https://opensource.org/licenses/MIT"

local isFlagsPress = false
local pressedFlag = nil
local stationaryCount = 0 -- 触摸板上静止不动的事件数量
local trackpadEventCount = 0 -- 触摸板上发生的事件数量
local cmdtapTimer = nil
local isTapFixing = false
local isTapAfterFlagsPress = false

function flagsListener(e)
    isFlagsPress = false
    pressedFlag = nil
    stationaryCount = 0
    trackpadEventCount = 0
    local flags = e:getFlags()
    if flags.cmd and not (flags.alt or flags.shift or flags.ctrl or flags.fn) then
        local keyCode = e:getKeyCode()
        if keyCode == 0x37 then
            -- print("~~ left cmd key")
            isFlagsPress = true
            pressedFlag = "cmd"
        end
    elseif flags.shift and not (flags.alt or flags.cmd or flags.ctrl or flags.fn) then
        local keyCode = e:getKeyCode()
        if keyCode == 0x38 then
            -- print("~~ left shift key")
            isFlagsPress = true
            pressedFlag = 'shift'
        end
    end
end

tapFlags = hs.eventtap.new({hs.eventtap.event.types.flagsChanged}, flagsListener)
tapFlags:start()

function resetTimer()
    if cmdtapTimer ~= nil then
        cmdtapTimer:stop()
        cmdtapTimer = nil
    end
end

function tapListener(e)
    if isFlagsPress == false then
        trackpadEventCount = 0
        stationaryCount = 0
        isTapAfterFlagsPress = false
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
        isTapAfterFlagsPress = true
    elseif touch.phase == "ended" then
        -- print("trackpadEventCount: " .. trackpadEventCount)
        -- 一次 tap to click 总的事件一般不会超过 10 个，其中静止事件一般大于 2 个，按住 cmd 时，可能小于 2 个
        if isFlagsPress and isTapAfterFlagsPress and isTapFixing == false and trackpadEventCount < 10 and
            stationaryCount >= 1 then
            -- print('tap to click fixing')
            resetTimer()
            cmdtapTimer = hs.timer.doAfter(0.1, function()
                -- print('timer complete')
                local pos = hs.mouse.absolutePosition()
                hs.eventtap.event.newMouseEvent(hs.eventtap.event.types.leftMouseDown, pos, {pressedFlag}):post()
                hs.eventtap.event.newMouseEvent(hs.eventtap.event.types.leftMouseUp, pos, {pressedFlag}):post()
            end)

            isTapAfterFlagsPress = false
            -- 控制间隔时间 避免重复触发
            isTapFixing = true
            hs.timer.doAfter(0.35, function()
                isTapFixing = false
            end)
        end
        stationaryCount = 0
        trackpadEventCount = 0
    else
        trackpadEventCount = trackpadEventCount + 1
    end

end

tapGesture = hs.eventtap.new({hs.eventtap.event.types.gesture}, tapListener)
tapGesture:start()

-- 正常触发时清空数据，避免程序触发
tapMouseDown = hs.eventtap.new({hs.eventtap.event.types.leftMouseDown}, function(e)
    -- print("mouse down")
    trackpadEventCount = 0
    stationaryCount = 0
    resetTimer()
end)
tapMouseDown:start()

return obj
