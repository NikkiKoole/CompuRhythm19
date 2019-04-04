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
      pattern[i].falloff = read[i].falloff or 0
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



function makePatternFromKit(kit, path)
   local result = {}
   for k,v in ipairs(kit) do
      table.insert(result, {name=v.name, url=path..v.file})

   end
   return result
end


function love.load()
   love.window.setMode(1024, 768)
   font = love.graphics.newFont("futura.ttf", 20)
   love.graphics.setFont(font)
   love.audio.setPosition(0, 1, 0)

   drumkits = {
      ['cr78'] = {
      	 {name="Bongo High", file="Bongo High.wav"},
      	 {name="Bongo Low", file="Bongo Low.wav"},
      	 {name="Conga Low", file="Conga Low.wav"},
      	 {name="Cowbell", file="Cowbell.wav"},
      	 {name="Cymbal", file="Cymbal.wav"},
      	 {name="Guiro 1", file="Guiro 1.wav"},
      	 {name="Guiro 2", file="Guiro 2.wav"},
      	 {name="HiHat Accent", file="HiHat Accent.wav"},
      	 {name="HiHat Metal", file="HiHat Metal.wav"},
      	 {name="HiHat", file="HiHat.wav"},
         {name="Kick Accent", file="Kick Accent.wav"},
         {name="Kick", file="Kick.wav"},
      	 {name="Rim Shot", file="Rim Shot.wav"},
      	 {name="Snare Accent", file="Snare Accent.wav"},
      	 {name="Snare", file="Snare.wav"},
      	 {name="Tamb 1", file="Tamb 1.wav"},
      	 {name="Tamb 2", file="Tamb 2.wav"},
      }
   }

   pattern =  makePatternFromKit(drumkits['cr78'], 'samples/cr78/' )

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


   drawingValue = 1
   cellWidth = 22
   cellHeight = 32
   gridMarginTop = 80
   gridMarginLeft = 1024 - cellWidth * 32 - 10
   openedInstrument = 0
   openedNotePanel = nil

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
      pattern[i].accented = false
      for j = 0, count do
         table.insert(pattern[i].values, {on=false, volume=1, pitch=1, pan=0})
      end
   end
end

function handlePressInGrid(x,y, value)
   local row, index = getRowAndIndex(x,y)
   if row > -1 and index > -1 then
      if value ~= nil then
         pattern[row].values[index].on = value
      else
         pattern[row].values[index].on = not pattern[row].values[index].on
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
   if lastDraggedElement then return end

   local row, index = getRowAndIndex(x,y)
   if not openedNotePanel then
      if row > -1 and index > -1 then
         local value = pattern[row].values[index].on
         drawingValue = not value
         handlePressInGrid(x,y, drawingValue)
      end
   end
end

function love.mousemoved(x,y)
   local down = love.mouse.isDown( 1)
   if down and not lastDraggedElement then
      if not openedNotePanel then
         handlePressInGrid(x,y, drawingValue)
      else
        -- print(openedNotePanel)
      end

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

            if pattern[i].values[timers[i].playhead].on then
               local timeToAdd = 0
               if timers[i].playhead % 2 == 1 then
                  if pattern[i].swing ~= 50 then
                     timeToAdd = ((pattern[i].swing-50)/50.0) * multiplier
                  end
               end

               -- accents
               local volume = 0.6
               if (pattern[i].accented) then
                  if (timers[i].playhead-1) % pattern.measure == 0 then
                     volume = volume + 0.4
                  end
               end

               volume = volume * pattern[i].volume
               volume = volume * pattern.volume

               if (pattern[i].values[timers[i].playhead].volume) then
                  volume = volume * pattern[i].values[timers[i].playhead].volume
               end

               if pattern[i].muted then
                  volume = volume * 0
               end

               table.insert(soundList, {playTime=time+timeToAdd,
                                        channelIndex=i,
                                        pitch=pattern.pitch * pattern[i].pitch * (pattern[i].values[timers[i].playhead].pitch or 1),
                                        volume=volume,
                                        falloff=pattern[i].falloff,
                                        pan=pattern[i].values[timers[i].playhead].pan or pattern[i].pan,
                                        sfx=pattern[i].sound})
            end
         end
      end

      for i,line in ipairs(soundList) do
         if time >= line.playTime and not line.isPlaying then
            line.sfx = line.sfx:clone()
            local pitch = math.max(line.pitch, 0.00001)
            line.sfx:setPitch(pitch)
            line.sfx:setVolume(line.volume)

            line.sfx:setPosition(line.pan,0, 0 )
            line.sfx:play()
            line.isPlaying = true
         end
      end

      -- todo tween the volume  (fadeIn and fadeOut)
      for i,line in ipairs(soundList) do
         local ratio =  line.sfx:tell("samples") / line.sfx:getDuration('samples')
         local vibratoPitch = (((ratio * 64 ) % 16) - 8)/ 24
         local result = math.max(line.pitch + vibratoPitch/2, 0.00001)
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

      if draw_button(gridMarginLeft - 30 , gridMarginTop + (i-1) * cellHeight,pattern[i].muted,run ).clicked then
         pattern[i].muted = not pattern[i].muted
      end

      if draw_label_button(gridMarginLeft - 126, gridMarginTop + (i-1) * cellHeight, pattern[i].name, pattern[i].selected, run).clicked then
         if openedInstrument == i then
            openedInstrument = 0
            pattern[i].selected = false
         else
            openedInstrument = i
            -- clear all others
            for j=1, #pattern do
               pattern[j].selected = false
            end
            pattern[i].selected = true
         end
      end

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
         if (pattern[i].values[j].on) then
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
      local ty = gridMarginTop + 100-- gridMarginTop + (openedInstrument-1)*cellHeight
      --love.graphics.setColor(255/colorDivider,218/colorDivider,69/colorDivider)
      local padding = 10

      --love.graphics.setColor(0,0,0)
      --draw_label_button(20, gridMarginTop, p.name)



      love.graphics.setColor(0,0,0)
      love.graphics.print('volume: '.. string.format("%.2f",p.volume), 20,  ty + 30)
      local volumeknob = draw_knob('my-volume',  150,  ty + 40,p.volume, 0 , 1.0, run)
      if volumeknob.value then
         p.volume = volumeknob.value
      end

      love.graphics.setColor(0,0,0)
      love.graphics.print('pan: '.. string.format("%.2f",p.pan), 20,  ty+80)
      local panslider = draw_knob('my-pan-slider', 150,  ty+90, p.pan, -1.0 , 1.0, run)
      if panslider.value then
         p.pan = panslider.value
      end

      love.graphics.setColor(0,0,0)
      love.graphics.print('pitch: '..string.format("%.4f",p.pitch), 20, ty+130)
      local pitchknob =  draw_knob('my-pitch',150, ty + 140,p.pitch, 0.00001, 5, run )
      if pitchknob.value then
         p.pitch = pitchknob.value
      end

      love.graphics.setColor(0,0,0)
      love.graphics.print('swing: '.. string.format("%.2f",p.swing), 20,  ty+180)
      local swingslider = draw_knob('my-swing-slider', 150,  ty+190, p.swing, 50 , 100, run)
      if swingslider.value then
         p.swing = swingslider.value
      end

      love.graphics.setColor(0,0,0)
      love.graphics.print('falloff: '.. string.format("%.2f", p.falloff), 20,  ty+230)
      local falloffslider = draw_knob('my-falloff-slider', 150,  ty+240, p.falloff, 0 , 1.0, run)
      if falloffslider.value then
         p.falloff = falloffslider.value
      end


      if draw_label_button(20, ty+280, 'accented', p.accented, run).clicked then
         p.accented = not p.accented
      end

      local panels = {'volume', 'pitch', 'pan'}
      for i=1, #panels do
         local p = panels[i]

         if draw_label_button(20, ty+280+i*50, p, openedNotePanel == p, run).clicked then
            if openedNotePanel ~= p then
               openedNotePanel = p
            else
               openedNotePanel = nil
            end

         end
      end




      if openedNotePanel then
         love.graphics.setColor(255/colorDivider, 198/colorDivider, 49/colorDivider, 0.9)
         love.graphics.rectangle('fill', gridMarginLeft, gridMarginTop, cellWidth * totalLength, cellHeight* #pattern )
         love.graphics.setColor(1,1,1)
         for i=1, totalLength do
            if (p.values[i].on) then
               love.graphics.setColor(0,0,0,1)
            else
               love.graphics.setColor(0,0,0,.1)
            end
            local minmax = {['volume']={0,1} ,['pan']={-1,1},['pitch']={0,1}}
            local mydeeper = draw_vertical_slider('my-'..openedNotePanel..'slider-'..i,
                                                  gridMarginLeft + i*cellWidth -cellWidth,
                                                  gridMarginTop,
                                                  cellHeight* #pattern,
                                                  p.values[i][openedNotePanel], minmax[openedNotePanel][1], minmax[openedNotePanel][2], run)
            if mydeeper.value then
               p.values[i][openedNotePanel] = mydeeper.value
            end

         end
      end

   end

   if playing then
      for i=1, #timers do
         local playhead = timers[i].playhead
         love.graphics.setColor(255/colorDivider,255/colorDivider,255/colorDivider, 0.5)
         love.graphics.setLineWidth(2)
         love.graphics.rectangle('fill',
                                 gridMarginLeft + (playhead-1)*cellWidth,
                                 gridMarginTop + ((i-1)*cellHeight), cellWidth, cellHeight)
      end
   end

   love.graphics.setColor(0, 0, 0)
   love.graphics.print('volume: '..string.format("%.2f",pattern.volume), 20 + 240, screenH - cellHeight*1)
   local vs = draw_knob('volume', 20 + 240 + 40 , 10 +  screenH - cellHeight*2, pattern.volume, 0, 1.0, run)
   if vs.value then
      pattern.volume =vs.value
   end

   love.graphics.print('measure: '.. pattern.measure, screenW-180,  screenH - cellHeight*2)
   local ms = draw_horizontal_slider('measure', screenW-100 ,  screenH - cellHeight*2, 50, pattern.measure, 1, 4, run)
   if ms.value then
      pattern.measure =math.floor( ms.value)
   end

   love.graphics.print('bars: '.. pattern.bars, screenW - 180,  screenH - cellHeight*1)
   local bs = draw_horizontal_slider('bars', screenW-100 ,  screenH - cellHeight*1, 50, pattern.bars, 1, 32, run)
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
   love.graphics.setColor(1,1,1)
   love.graphics.print('sources: '..count, 0,0)
   love.graphics.print('time: '..string.format("%.2f",time), 0,20)
   love.graphics.print('soundList: '..#soundList, 0,40)
end
