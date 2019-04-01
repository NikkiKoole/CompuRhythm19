inspect = require "inspect"
require 'ui'
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
end

function love.load()
   love.window.setMode(1024, 768)
   font = love.graphics.newFont("futura.ttf", 20)
   love.graphics.setFont(font)
   love.audio.setPosition(0, 1, 0)
   pattern = {
      -- {name='bd', url='samples/TR808WAV/BD/BD1010.wav'},
      -- {name='bd', url='samples/TR808WAV/BD/BD1050.wav'},
      -- {name='bd', url='samples/tr606/01bd.wav'},
      -- {name='sd', url='samples/tr606/02sd.wav'},
      -- {name='ch', url='samples/tr606/03ch.wav'},
      -- {name='CLAV', url='samples/kr55/KR55CLAV.wav'},
      -- {name='donk', url='samples/donk/Donk1.wav'},
      {name='donk', url='samples/donk/Donk2.wav'},
      {name='clarinet', url='samples/timbres/clarinet_loop_middle.wav'},
      {name='donk', url='samples/donk/Donk3.wav'},
      {name='CHaT', url='samples/kr55/KR55CHAT.wav'},
      {name='CNGA', url='samples/kr55/KR55CNGA.wav'},
      -- {name='bass', url='samples/cr8000/CR8KBASS.wav'},
      -- {name='CymbalR', url='samples/cr78/Cymbal_reversed.wav'},
      -- {name='Cymbal', url='samples/cr78/Cymbal.wav'},
      -- {name='Cowbell', url='samples/cr78/Cowbell.wav'},
      -- {name='Conga', url='samples/cr78/Conga Low.wav'},
      -- {name='HiHat accent', url='samples/cr78/HiHat Accent.wav'},
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

   time = 0
   soundList = {}

   lastMouseDown = nil
   lastDraggedElement = nil
end


function prepareTimers(pattern)
   local result = {}
   for i = 1, #pattern do
      result[i] = {playhead=1}
   end
   result.timeInBeat = 0
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
      pattern[i].falloff = 0
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

function love.mousereleased(x, y)
   lastDraggedElement = nil
end


function love.mousepressed(x, y)
   -- figure out if changing the cell under me means deleting r adding
   -- do that for all the cells touched by the subsequent move
   if lastDraggedElement then return end
   local row, index = getRowAndIndex(x,y)
   if openedInstrument == 0 then
      if row > -1 and index > -1 then
         local value = pattern[row].values[index]
         drawingValue = not value
         handlePressInGrid(x,y, drawingValue)
      end
   end

   if (x > 40 and x < gridMarginLeft) and (y > gridMarginTop and y < gridMarginTop  + cellHeight* #pattern) then
      local lx = x
      local ly = y - gridMarginTop
      local index = math.floor(ly / cellHeight) + 1
      if openedInstrument == index then
         openedInstrument = 0
      else
         openedInstrument = index
      end
   end
end

function love.mousemoved(x,y)
   local down = love.mouse.isDown( 1)
   if down and openedInstrument == 0 and not lastDraggedElement then
      handlePressInGrid(x,y, drawingValue)
   end
end

function love.update(dt)
   local multiplier = (60/(pattern.bpm*4))

   if (playing) then
      timers.timeInBeat = timers.timeInBeat + dt
      time = time + dt
      if timers.timeInBeat >= multiplier then
         timers.timeInBeat = 0
         for i=1, #pattern do
      	    timers[i].playhead = timers[i].playhead + 1

            if (timers[i].playhead > pattern.bars) then
      	       timers[i].playhead = 1
      	    end

            if pattern[i].values[timers[i].playhead] then
               local timeToAdd = 0
               if timers[i].playhead % 2 == 1 then
                  if pattern[i].swing ~= 50 then
                     timeToAdd = ((pattern[i].swing-50)/50.0) * multiplier
                  end
               end

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

               table.insert(soundList, {playTime=time+timeToAdd,
                                        channelIndex=i,
                                        pitch=pattern.pitch * pattern[i].pitch,
                                        volume=volume,
					falloff=pattern[i].falloff,
                                        pan=pattern[i].pan,
                                        sfx=pattern[i].sound})
            end
         end
      end

      for i,line in ipairs(soundList) do
         if time >= line.playTime and not line.isPlaying then
            line.sfx = line.sfx:clone()
            line.sfx:setPitch(math.max(line.pitch, 0.00001))
            line.sfx:setVolume(line.volume)
            line.sfx:setPosition(line.pan,0, 0 )
            line.sfx:play()
            line.isPlaying = true
         end
      end

      -- todo tween the volume  (fadeIn and fadeOut)
      for i,line in ipairs(soundList) do
	 local ratio =  line.sfx:tell("samples") / line.sfx:getDuration('samples')
	 if line.isPlaying then
	    if not line.sfx:isPlaying()  or ratio > (1.0 - line.falloff)then
	       line.sfx:stop()
	       table.remove(soundList, i)
	    end
	 end
      end

   end
end

function love.draw()
   local screenH = love.graphics.getHeight( )
   local screenW = love.graphics.getWidth( )
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
      local p = pattern[openedInstrument]
      local ty = gridMarginTop + (openedInstrument-1)*cellHeight
      love.graphics.setColor(255/colorDivider,218/colorDivider,69/colorDivider)
      local padding = 10
      love.graphics.rectangle('fill',
                              gridMarginLeft - 1,
                                 -1 + gridMarginTop + (openedInstrument-1)*cellHeight,
                              2 + cellWidth * totalLength , 2+ cellHeight )
      
      love.graphics.setColor(0,0,0)
      love.graphics.print('volume: '.. string.format("%.2f",p.volume), gridMarginLeft,  ty)
      local volumeknob = draw_knob('my-volume',  gridMarginLeft+ 120,  ty + 15,p.volume, 0 , 1.0, run)
      if volumeknob.value then
         p.volume = volumeknob.value
      end
    
      love.graphics.setColor(0,0,0)
      love.graphics.print('pan: '.. string.format("%.2f",p.pan), gridMarginLeft+ 120 + 20,  ty)
      local panslider = draw_knob('my-pan-slider', gridMarginLeft+ 240,  ty+15, p.pan, -1.0 , 1.0, run)
      if panslider.value then
         p.pan = panslider.value
      end

       love.graphics.setColor(0,0,0)
      love.graphics.print('pitch: '..string.format("%.4f",p.pitch), gridMarginLeft + 240 + 20, ty)
      local pitchknob =  draw_knob('my-pitch', gridMarginLeft + 360, ty + 15,p.pitch, 0.00001, 5, run )
      if pitchknob.value then
         p.pitch = pitchknob.value
      end
      
      love.graphics.setColor(0,0,0)
      love.graphics.print('swing: '.. string.format("%.2f",p.swing), gridMarginLeft+ 380,  ty)
      local swingslider = draw_knob('my-swing-slider', gridMarginLeft+ 480,  ty+15, p.swing, 50 , 100, run)
      if swingslider.value then
         p.swing = swingslider.value
      end

      love.graphics.setColor(0,0,0)
      love.graphics.print('falloff: '.. string.format("%.2f", p.falloff), gridMarginLeft+ 500,  ty)
      local falloffslider = draw_knob('my-falloff-slider', gridMarginLeft+ 600,  ty+15, p.falloff, 0 , 1.0, run)
      if falloffslider.value then
         p.falloff = falloffslider.value
      end
   end

   if playing then
      for i=1, #timers do
         local playhead = timers[i].playhead
         love.graphics.setColor(255/colorDivider,255/colorDivider,255/colorDivider)
         love.graphics.setLineWidth(2)
         love.graphics.rectangle('line',
                                 gridMarginLeft + (playhead-1)*cellWidth,
                                 gridMarginTop + ((i-1)*cellHeight), cellWidth, cellHeight )
      end
   end

   love.graphics.setColor(0, 0, 0)
   love.graphics.print('volume: '..string.format("%.2f",pattern.volume), 20 + 240, screenH - cellHeight*1)
   local vs = draw_knob('volume', 20 + 240 + 40 , 10 +  screenH - cellHeight*2, pattern.volume, 0, 1.0, run)
   if vs.value then
      pattern.volume =vs.value
   end

   love.graphics.print('measure: '.. pattern.measure, screenW-180,  screenH - cellHeight*2)
   local ms = draw_slider('measure', screenW-100 ,  screenH - cellHeight*2, 50, pattern.measure, 1, 4, run)
   if ms.value then
      pattern.measure =math.floor( ms.value)
   end

   love.graphics.print('bars: '.. pattern.bars, screenW - 180,  screenH - cellHeight*1)
   local bs = draw_slider('bars', screenW-100 ,  screenH - cellHeight*1, 50, pattern.bars, 1, 32, run)
   if bs.value then
      pattern.bars =math.floor( bs.value)
   end

   love.graphics.print('pitch: '..string.format("%.4f", pattern.pitch), 20 + 120, screenH - cellHeight*1)
   local pitchknob =  draw_knob('pitch', 180, -20 + screenH - cellHeight*1,pattern.pitch, 0, 1, run )
   if pitchknob.value then
      pattern.pitch = pitchknob.value
   end

   love.graphics.print('bpm: '..string.format("%.2f", pattern.bpm) , 20, screenH - cellHeight*1)
   local bpmknob =  draw_knob('bpm', 20 + 40,-20+ screenH - cellHeight*1,pattern.bpm, 0, 300, run )
   if bpmknob.value then
      pattern.bpm = bpmknob.value
   end

   count = love.audio.getActiveSourceCount( )
   love.graphics.print('sources: '..count, 0,0)
   love.graphics.print('time: '..string.format("%.2f",time), 0,20)
   love.graphics.print('soundList: '..#soundList, 0,40)
end
