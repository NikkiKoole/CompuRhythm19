inspect = require "inspect"
require 'simple-slider'

colorDivider = 255


function copy(obj, seen, ignore)
  if type(obj) ~= 'table' then return obj end
  if seen and seen[obj] then return seen[obj] end
  local s = seen or {}
  local res = setmetatable({}, getmetatable(obj))
  s[obj] = res
  for k, v in pairs(obj) do
     if k ~= ignore then
        res[copy(k, s, ignore)] = copy(v, s, ignore)
     end
  end
  return res
end



function love.keypressed(key)
   if key == "escape" then
      love.event.quit()
   end
   if key == "space" then
      playing = not playing
   end
   if key == "l" then
      love.system.openURL("file://"..love.filesystem.getSaveDirectory( ))
   end
   if key == "s" then
      local c = copy(pattern, nil, 'sound')
      success, message = love.filesystem.write((math.floor(love.timer.getTime()*1000))..".txt", inspect(c, {indent=""}))
   end
end

function love.filedropped(file)
    --local data = file:read()
    local read = loadstring("return ".. file:read())()
    addBars(pattern, totalLength)
    timers = prepareTimers(pattern)

    pattern = {}
    for i=1, #read do
       pattern[i] = {}
       pattern[i].name = read[i].name
       pattern[i].url = read[i].url
    end
    addBars(pattern, read.length)
    timers = prepareTimers(pattern)
    for i=1, #read do
       pattern[i].muted = read[i].muted
       pattern[i].pitch = read[i].pitch
       pattern[i].randomPitch = read[i].randomPitch
       pattern[i].swing = read[i].swing
       pattern[i].pan = read[i].pan or 0
       pattern[i].volume = read[i].volume
       pattern[i].values = read[i].values
    end

    pattern.length = read.length
    pattern.bpm = read.bpm
    pattern.swing = read.swing
    pattern.pitch = read.pitch
    pattern.pitchRandom = read.pitchRandom
    pattern.bars = read.bars or 32
    pattern.volume = read.volume or 1
    pattern.measure = read.measure or 4

    updateSliders()
end

function love.load()
    love.window.setMode(1024, 868)
   font = love.graphics.newFont("futura.ttf", 20)
   love.graphics.setFont(font)
   love.audio.setPosition(0, 1, 0)
   pattern = {
      {name='CLAV', url='samples/kr55/KR55CLAV.wav'},
      {name='donk', url='samples/donk/Donk1.wav'},
      {name='donk', url='samples/donk/Donk2.wav'},
      {name='donk', url='samples/donk/Donk3.wav'},

      {name='CHaT', url='samples/kr55/KR55CHAT.wav'},
      {name='CNGA', url='samples/kr55/KR55CNGA.wav'},
      {name='bass', url='samples/cr8000/CR8KBASS.wav'},
      {name='CymbalR', url='samples/cr78/Cymbal_reversed.wav'},
      {name='Cymbal', url='samples/cr78/Cymbal.wav'},
      {name='Cowbell', url='samples/cr78/Cowbell.wav'},
      {name='Conga', url='samples/cr78/Conga Low.wav'},
      {name='HiHat accent', url='samples/cr78/HiHat Accent.wav'},
      {name='Bongo High', url='samples/cr78/Bongo High.wav'},
      {name='Bongo Low', url='samples/cr78/Bongo Low.wav'},
      {name='Tamb 1', url='samples/cr78/Tamb 1.wav'},
      {name='Tamb 2', url='samples/cr78/Tamb 2.wav'},
      {name='Conga Low', url='samples/cr78/Conga Low.wav'},
      {name='HiHat Metal', url='samples/cr78/HiHat Metal.wav'},
      {name='HiHat', url='samples/cr78/HiHat.wav'},
      --{name='Guiro 1', url='samples/cr78/Guiro 1.wav'},
      --{name='Guiro 2', url='samples/cr78/Guiro 2.wav'},
      {name='Snare accent', url='samples/cr78/Snare Accent.wav'},
      {name='Snare', url='samples/cr78/Snare.wav'},
      {name='Rim', url='samples/cr78/Rim Shot.wav'},
      {name='Kick', url='samples/cr78/Kick.wav'},
      {name='Kick accent', url='samples/cr78/Kick Accent.wav'},
      }
--love.audio.newSource('samples/Conga Low.wav', 'static')
   totalLength = 32
   addBars(pattern, totalLength)
   timers = prepareTimers(pattern)

   pattern.bpm = 80
   pattern.volume = 1.0
   pattern.swing = 50
   pattern.pitch = 1.0
   pattern.pan = 0.0
   pattern.bars = totalLength
   pattern.pitchRandom = 0
   pattern.measure = 4

   playing = false

   gridMarginTop = 40
   gridMarginLeft = 24*6
   drawingValue = 1
   cellWidth = 24
   cellHeight = 32

   openedInstrument = 0

   updateSliders()

   customPitchSlider = newSlider(0, 0 ,0, 0, 0, 0, nil, {track="line"})
   customVolumeSlider = newSlider(0, 0 ,0, 0, 0, 0, nil, {track="line"})
   customSwingSlider = newSlider(0, 0 ,0, 0, 0, 0, nil, {track="line"})
   customRandomPitchSlider = newSlider(0, 0 ,0, 0, 0, 0, nil, {track="line"})
   customPanSlider = newSlider(0, 0 ,0, 0, 0, 0, nil, {track="line"})

   time = love.timer.getTime( )
   resolutionTimer = 0


   lastMouseDown = nil
end

function updateSliders()
   local screenH = love.graphics.getHeight( )

    bpmSlider = newSlider(100+gridMarginLeft,  screenH - cellHeight*2 + cellHeight/2,
			 200, pattern.bpm, 0, 300,
			 function(v) pattern.bpm=v end,
			 {track="line"})

   swingSlider = newSlider(100+gridMarginLeft,  screenH - cellHeight*1 + cellHeight/2,
			 200, pattern.swing, 0, 100,
			 function(v) pattern.swing=v end,
			 {track="line"})

   pitchSlider = newSlider(100+gridMarginLeft + 320,  screenH - cellHeight*2 + cellHeight/2,
			 200, pattern.pitch, 0, 1.0,
			 function(v) pattern.pitch=v end,
			 {track="line"})

   volumeSlider = newSlider(100+gridMarginLeft + 320, screenH - cellHeight*1 + cellHeight/2,
			 200, pattern.volume, 0, 1.0,
			 function(v) pattern.volume=v end,
			 {track="line"})


   pitchRandomSlider = newSlider(100+gridMarginLeft + 320, screenH - cellHeight*2 + cellHeight/2,
			 200, pattern.pitchRandom, 0, 1.0,
			 function(v) pattern.pitchRandom=v end,
			 {track="line"})

   measureSlider = newSlider(gridMarginLeft + 320 + 320, screenH - cellHeight*2 + cellHeight/2,
			 60, pattern.measure, 1, 4,
			 function(v) pattern.measure=math.floor(v) end,
			 {track="line"})
    barsSlider = newSlider(gridMarginLeft + 320 + 320, screenH - cellHeight*1 + cellHeight/2,
			 60, pattern.bars, 1, 32,
			 function(v) pattern.bars=math.floor(v) end,
			 {track="line"})

end
function prepareTimers(pattern)
   local result = {}
   for i = 1, #pattern do
      result[i] = {timeInBeat=0, playhead=1}
   end
   return result
end


function addBars(pattern, count)
   pattern.length = count
   for i = 1, #pattern do
      pattern[i].sound = love.audio.newSource(pattern[i].url, 'static')
      pattern[i].values = {}
      pattern[i].volume = 1.0
      pattern[i].muted = false
      pattern[i].pitch = 1.0
      pattern[i].randomPitch = 0
      pattern[i].swing = 50
      pattern[i].pan = 0
      for j = 0, count do
         table.insert(pattern[i].values, false)
      end
   end
end

function handlePressInGrid(x,y, value)
   local row, index = getRowAndIndex(x,y)
   if row > -1 and index > -1 then
      if value ~= nil then
	 pattern[row].values[index] = value
      else
	 pattern[row].values[index] = not pattern[row].values[index]
      end
   end
end




function getRowAndIndex(x,y)
   local x2 = x - gridMarginLeft
   local y2 = y - gridMarginTop
   if (y2 < 0 or y2 > #pattern * cellHeight) then return -1,-1 end
   if (x2 < 0 or x2 > pattern.length * cellWidth) then return -1,-1 end
   local index = math.floor(x2/cellWidth) + 1
   local row = math.floor(y2/cellHeight) + 1
   row = math.min(#pattern , row)
   index = math.min(pattern.length , index)
   return row, index
end


function love.mousepressed(x, y)
   -- figure out if changing the cell under me means deleting r adding
   -- do that for all the cells touched by the subsequent move
   local row, index = getRowAndIndex(x,y)

   if openedInstrument == 0 then
   if row > -1 and index > -1 then
      local value = pattern[row].values[index]
      drawingValue = not value
      handlePressInGrid(x,y, drawingValue)
   end
   end

   if (x > 20 and x < gridMarginLeft) and
      (y > gridMarginTop and y < gridMarginTop  + cellHeight* #pattern) then
	 local lx = x
	 local ly = y - gridMarginTop
	 local index = math.floor(ly / cellHeight) + 1

	 if openedInstrument == index then
	    openedInstrument = 0
	 else
	    openedInstrument = index
	 end

	 local uiY = index * cellHeight + gridMarginTop - 20
	 local uiX = gridMarginLeft + 130
	 local p = pattern[index]
	 local func = function(name)
	    return function(v)
	       if openedInstrument > 0 then
		  pattern[openedInstrument][name] = v
	       end
	       --prop=v
	    end
	 end

	 customPitchSlider =
	    newSlider(uiX, uiY, 100, p.pitch, 0, 1.0,func('pitch'), {track="line"})

	 customSwingSlider =
	    newSlider(uiX + 200,uiY , 100, p.swing, 0, 100,func('swing'),{track="line"})

	 customVolumeSlider =
	    newSlider(uiX + 400,uiY , 100, p.volume, 0, 1, func('volume'), {track="line"})

	 customRandomPitchSlider =
	    newSlider(uiX + 600,uiY  ,100, p.randomPitch, 0, 1, func('randomPitch'), {track="line"})

	  customPanSlider =
	     newSlider(uiX + 600,uiY  ,100, p.pan, -1, 1, func('pan'), {track="line"})
   end

end
function love.mousemoved(x,y)
   local down = love.mouse.isDown( 1)
   if down and openedInstrument == 0 then
      handlePressInGrid(x,y, drawingValue)
   end
end


function love.update(dt)


   -- to start out with i need an internal clock kinda thing
   -- let say we have a resolution of 1/32
   -- 1/32 of what though?


   -- all instruments use that resolution, things try to get triggered by it.


   resolutionTimer = resolutionTimer + dt
   --print(resolutionTimer, 1.0/32, dt)
--   print(60/pattern.bpm)

   local multiplier = (60/(pattern.bpm*4))
   if (playing) then

      for i=1, #pattern do
	 timers[i].timeInBeat = timers[i].timeInBeat + dt

	 local timeToAdd = 0

	 if pattern.swing ~= 50 then
	    timeToAdd = ((pattern.swing-50)/100.0) * multiplier

	    if timers[i].playhead % 2 == 0 then
	       -- these we add
	    elseif  timers[i].playhead % 2 == 1 then
	       timeToAdd = timeToAdd * -1
	    end
	 end

	 if pattern[i].swing ~= 50 then
	    timeToAdd = ((pattern[i].swing-50)/100.0) * multiplier

	    if timers[i].playhead % 2 == 0 then
	       -- these we add
	    elseif  timers[i].playhead % 2 == 1 then
	       timeToAdd = timeToAdd * -1
	    end
	 end

	 if (timers[i].timeInBeat >= (multiplier + timeToAdd)) then
	    timers[i].playhead = timers[i].playhead + 1
	    if (timers[i].playhead > pattern.bars) then timers[i].playhead = 1 end

	    if pattern[i].values[timers[i].playhead] then
	       local sfx = pattern[i].sound:clone()
	       local tempPitch = 0.000001

	       if pitchRandom then
		  tempPitch = math.max((love.math.random() * pattern.pitchRandom), 0.0000001)
		  if (love.math.random() > 0.5 ) then
		     tempPitch = tempPitch * -1
		  end
	       end

	       local p = math.max(pattern.pitch + (tempPitch*pattern.pitch), 0)
	       local layerPitch = pattern[i].pitch
	       sfx:setPitch(math.max(p*layerPitch, 0.00001) )

	       -- accents
	       local volume = 0.6
	       if (timers[i].playhead-1) % pattern.measure == 0 then
		  volume = volume + 0.4
	       end

	       volume = volume * pattern[i].volume
	       volume = volume * pattern.volume
	       if pattern[i].muted then
		  volume = volume * 0
	       end

	       sfx:setVolume(volume)
	       sfx:setPosition( pattern[i].pan,0, 0 )
	       sfx:play()
	    end
	    timers[i].timeInBeat = timers[i].timeInBeat - (multiplier + timeToAdd)
	 end

      end

   end




   bpmSlider:update()
   swingSlider:update()
   pitchSlider:update()
   volumeSlider:update()
   measureSlider:update()
   barsSlider:update()
   pitchRandomSlider:update()
   customPitchSlider:update()
   customSwingSlider:update()
   customVolumeSlider:update()
   customRandomPitchSlider:update()
   customPanSlider:update()
end

function pointInRect(x,y, rx, ry, rw, rh)
   if x < rx or y < ry then return false end
   if x > rx+rw or y > ry+rh then return false end
   return true
end
function draw_button(x,y,p, run)
   --print(inspect(p), inspect(p2))
   local result= false
   if not p then
      love.graphics.rectangle('fill',x,y,cellWidth,cellHeight )
   else
      love.graphics.rectangle('line',x,y,cellWidth,cellHeight )

   end

   if run then
      local mx, my = love.mouse.getPosition( )
      if pointInRect(mx,my, x,y,cellWidth,cellHeight) then
	 result = true
      end
   end

   return {
      clicked=result
   }
end

function love.draw()

   love.graphics.clear(255/colorDivider, 198/colorDivider, 49/colorDivider)
   love.graphics.setColor(35/colorDivider,36/colorDivider,38/colorDivider)
   love.graphics.setLineWidth( 2)

   local mouseDown = love.mouse.isDown(1 )
   local run = false
   if mouseDown ~= lastMouseDown then
      if mouseDown then
	 run = true
      end
   end
   lastMouseDown = mouseDown

   for i =1, #pattern do

      if draw_button(4,gridMarginTop + (i-1) * cellHeight,pattern[i].muted,run ).clicked then
	 pattern[i].muted = not pattern[i].muted
      end



      love.graphics.print(pattern[i].name,  40, gridMarginTop + (i-1) * cellHeight)
      love.graphics.rectangle('line',40,  gridMarginTop + (i-1)*cellHeight, 90, cellHeight )
      --we assume some width is enough to fit all the names say 100

      for j=1, #(pattern[i].values)-1 do


	 if (j %  pattern.measure == 0) then -- show a thicker line at measures
	    --print(j % 4, j)
	    love.graphics.line(gridMarginLeft + (j)*cellWidth,
			       gridMarginTop ,
			       gridMarginLeft + (j)*cellWidth,
			       gridMarginTop + (#pattern)*cellHeight

	    )
	 end
	 love.graphics.setColor(35/colorDivider,36/colorDivider,38/colorDivider, 1.0)
	 if (j>pattern.bars or pattern[i].muted) then
	    love.graphics.setColor(35/colorDivider,36/colorDivider,38/colorDivider, 0.5)
	 end
	 if (pattern[i].values[j]) then
    	    love.graphics.rectangle('fill',
				    gridMarginLeft + (j-1)*cellWidth,
				    gridMarginTop + (i-1)*cellHeight,
				    cellWidth, cellHeight )
    	 else
    	    love.graphics.rectangle('line',
				    gridMarginLeft + (j-1)*cellWidth,
				    gridMarginTop + (i-1)*cellHeight,
				    cellWidth, cellHeight )
    	 end
      end
      love.graphics.setColor(35/colorDivider,36/colorDivider,38/colorDivider, 1.0)

   end

   if openedInstrument > 0 then
      --print(openedInstrument)
      local p = pattern[openedInstrument]
      local ty = gridMarginTop + (openedInstrument-1)*cellHeight
      love.graphics.setColor(255/colorDivider,218/colorDivider,69/colorDivider)
      love.graphics.rectangle('fill',
				    gridMarginLeft - 1,
				    -1 + gridMarginTop + (openedInstrument-1)*cellHeight,
				    2 + cellWidth * totalLength , 2+ cellHeight )
      love.graphics.setColor(0/colorDivider,0/colorDivider,0/colorDivider)
      love.graphics.print('pitch: '.. p.pitch, gridMarginLeft,  ty)
      customPitchSlider:draw()
      love.graphics.print('swing: '.. p.swing, gridMarginLeft+ 200,  ty)
      customSwingSlider:draw()
      love.graphics.print('volume: '.. p.volume, gridMarginLeft+ 400,  ty)
      customVolumeSlider:draw()
      love.graphics.print('pan: '.. p.pan, gridMarginLeft+ 600,  ty)
      customPanSlider:draw()


      --love.graphics.print('rnd: '.. pattern[openedInstrument].randomPitch, gridMarginLeft+ 600,  gridMarginTop + (openedInstrument-1)*cellHeight)


      --customRandomPitchSlider:draw()
   end


   if playing then
      for i=1, #timers do
	 local playhead = timers[i].playhead
	 love.graphics.setColor(255/colorDivider,255/colorDivider,255/colorDivider)
	 love.graphics.setLineWidth(2)
	 love.graphics.rectangle('line',
				 gridMarginLeft + (playhead-1)*24,
				 gridMarginTop + ((i-1)*cellHeight), 24, cellHeight )
      end


   end

   love.graphics.setColor(0, 0, 0)

   -- draw slider, set color and line style before calling
   local screenH = love.graphics.getHeight( )

    love.graphics.print('bpm: '..pattern.bpm, 20, screenH - cellHeight*2)
    bpmSlider:draw()
    love.graphics.print('swing: '..pattern.swing, 20,screenH - cellHeight*1)
    swingSlider:draw()
    love.graphics.print('pitch: '..pattern.pitch, 20 + 320, screenH - cellHeight*2)
    pitchSlider:draw()
    love.graphics.print('volume: '..pattern.volume, 20 + 320, screenH - cellHeight*1)
    volumeSlider:draw()
    love.graphics.print('measure: '.. pattern.measure, 20 + 320 + 320,  screenH - cellHeight*2)
    measureSlider:draw()
     love.graphics.print('bars: '.. pattern.bars, 20 + 320 + 320,  screenH - cellHeight*1)
      barsSlider:draw()

    --love.graphics.print('pitch-rnd: '..pattern.pitchRandom, 20 + 320, 700 + cellHeight)
    --pitchRandomSlider:draw()
    count = love.audio.getActiveSourceCount( )
    love.graphics.print('sources: '..count, 0,0)

end
