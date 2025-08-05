local DEFAULT_INPUT_DEVICE = 'Scarlett Solo USB'
local APM_OUTPUT_DEVICE = '❤️☠️🤖 AirPods Max'
local AP_OUTPUT_DEVICE = '❤️☠️🤖 AirPods Pro'

local upKeyStroke = function()
  hs.eventtap.keyStroke({}, 'up')
end

local downKeyStroke = function()
  hs.eventtap.keyStroke({}, 'down')
end

local leftKeyStroke = function()
  hs.eventtap.keyStroke({}, 'left')
end

local rightKeyStroke = function()
  hs.eventtap.keyStroke({}, 'right')
end

local vimMotionUp =
  hs.hotkey.new({ 'ctrl' }, 'k', upKeyStroke, nil, upKeyStroke)
local vimMotionDown =
  hs.hotkey.new({ 'ctrl' }, 'j', downKeyStroke, nil, downKeyStroke)
local vimMotionRight =
  hs.hotkey.new({ 'ctrl' }, 'l', rightKeyStroke, nil, rightKeyStroke)
local vimMotionLeft =
  hs.hotkey.new({ 'ctrl' }, 'h', leftKeyStroke, nil, leftKeyStroke)

local enableVimNavigation = function()
  -- hs.alert.show('Enable VIM motion')
  --[[ vimMotionUp:enable()
  vimMotionDown:enable()
  vimMotionLeft:enable()
  vimMotionRight:enable() ]]
end

local disableVimNavigation = function()
  -- hs.alert.show('Disable VIM motion')
  --[[ vimMotionUp:disable()
  vimMotionDown:disable()
  vimMotionLeft:disable()
  vimMotionRight:disable() ]]
end

enableVimNavigation()
-- hs.application.enableSpotlightForNameSearches(true)

hs.hotkey.bind({ 'ctrl' }, 'escape', function()
  local app = hs.application.get('kitty')
  if app then
    if not app:mainWindow() then
      app:selectMenuItem({ 'kitty', 'New OS window' })
      disableVimNavigation()
    elseif app:isFrontmost() then
      enableVimNavigation()
      app:hide()
    else
      disableVimNavigation()
      app:activate()
    end
  else
    hs.application.launchOrFocus('kitty')
  end
end)

hs.hotkey.bind({ 'ctrl' }, 'f9', function()
  hs.shortcuts.run('toggle_desk_lamp')
end)

--[[ local eventsHr = {}

for key, _ in pairs(hs.application.watcher) do
  local value = hs.application.watcher[key]
  if type(value) == 'number' and value < 10 then
    eventsHr[tostring(value)] = key
  end
end ]]

--[[ local appWatcher = hs.application.watcher.new(function(name, event)
  -- hs.alert.show("Event: "..(eventsHr[tostring(event)] or '').."; App: "..name, 10)
  if event == hs.application.watcher.activated then
    if name == 'kitty' then
      disableVimNavigation()
    else
      enableVimNavigation()
    end
  end
end)

appWatcher:start() ]]

hs.audiodevice.watcher.setCallback(function(event)
  if event == 'dIn ' then
    local deviceName = hs.audiodevice.current(true).name

    if deviceName == DEFAULT_INPUT_DEVICE then
      return
    end

    local inputDevice = hs.audiodevice.findInputByName(DEFAULT_INPUT_DEVICE)

    if inputDevice == nil then
      print(
        'Unable to detect default inpu device. Current Device: ' .. deviceName
      )
      return
    end

    local isDeviceSelected = inputDevice:setDefaultInputDevice()

    if isDeviceSelected then
      inputDevice:setInputVolume(75)
      print(
        'Override input device: ' .. deviceName .. ' -> ' .. inputDevice:name()
      )
    end

    return
  end

  print(event)

  if event == 'dOut' then
    local deviceName = hs.audiodevice.current().name

    if deviceName == APM_OUTPUT_DEVICE then
      local outputDevice = hs.audiodevice.findOutputByName(APM_OUTPUT_DEVICE)
      if outputDevice == nil then
        return
      end
      outputDevice:setOutputVolume(65)

    elseif deviceName == AP_OUTPUT_DEVICE then
      local outputDevice = hs.audiodevice.findOutputByName(AP_OUTPUT_DEVICE)
      if outputDevice == nil then
        return
      end
      outputDevice:setOutputVolume(65)
    end

    local outputDevice = hs.audiodevice.findOutputByName(deviceName)

    outputDevice:setBalance(0.5)

    return
  end

end)

hs.audiodevice.watcher.start()
