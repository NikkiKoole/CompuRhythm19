inspect = require "inspect"
require 'simple-slider'

colorDivider = 255

function love.keypressed(key)
   if key == "escape" then
      love.event.quit()
   end
   if key == "space" then
      playing = not playing

   end
end


function love.load()


   love.window.setMode(1024, 768)
   font = love.graphics.newFont("futura.ttf", 20)
   love.graphics.setFont(font)


   pattern = {
      {name='Cymbal', sound=love.audio.newSource('samples/Cymbal.wav', 'static')},
      {name='Cowbell', sound=love.audio.newSource('samples/Cowbell.wav', 'static')},
      {name='Conga', sound=love.audio.newSource('samples/Conga Low.wav', 'static')},
      {name='HiHat accent', sound=love.audio.newSource('samples/HiHat Accent.wav', 'static')},
      {name='Bongo High', sound=love.audio.newSource('samples/Bongo High.wav', 'static')},
      {name='Bongo Low', sound=love.audio.newSource('samples/Bongo Low.wav', 'static')},
      {name='Tamb 1', sound=love.audio.newSource('samples/Tamb 1.wav', 'static')},
      {name='Tamb 2', sound=love.audio.newSource('samples/Tamb 2.wav', 'static')},
      {name='Conga Low', sound=love.audio.newSource('samples/Conga Low.wav', 'static')},
      {name='HiHat Metal', sound=love.audio.newSource('samples/HiHat Metal.wav', 'static')},
      {name='HiHat', sound=love.audio.newSource('samples/HiHat.wav', 'static')},
      {name='Guiro 1', sound=love.audio.newSource('samples/Guiro 1.wav', 'static')},
      {name='Guiro 2', sound=love.audio.newSource('samples/Guiro 2.wav', 'static')},
      {name='Snare accent', sound=love.audio.newSource('samples/Snare Accent.wav', 'static')},
      {name='Snare', sound=love.audio.newSource('samples/Snare.wav', 'static')},
      {name='Rim', sound=love.audio.newSource('samples/Rim Shot.wav', 'static')},
      {name='Kick', sound=love.audio.newSource('samples/Kick.wav', 'static')},
      {name='Kick accent', sound=love.audio.newSource('samples/Kick Accent.wav', 'static')},
   }
   totalLength = 32
   addBars(pattern, totalLength)
   bpm = 300
   swing = 50 -- percentage of swing, 50 == 0 (robert linn's way of doing swing)
   pitch = 1.0
   pitchRandom = 0
   playing = false
   playhead = 1
   timeInBeat = 0
   gridMarginTop = 100
   gridMarginLeft = 110
   drawingValue = 1
   cellWidth = 24
   cellHeight = 32
   openedInstrument = 0


   customPitch = 0
   customSwing = 50
   --success, message = love.filesystem.write("wrote_this.txt", inspect(pattern, {indent=""}))
   --path = love.filesystem.getAppdataDirectory( )
   --print(path)

   bpmSlider = newSlider(100+gridMarginLeft, 710,
			 200, bpm, 0, 1000,
			 function(v) bpm=v end,
			 {track="line"})

   swingSlider = newSlider(100+gridMarginLeft, 710 + cellHeight,
			 200, swing, 50, 100,
			 function(v) swing=v end,
			 {track="line"})

   pitchSlider = newSlider(100+gridMarginLeft + 320, 710 ,
			 200, pitch, 0, 1.0,
			 function(v) pitch=v end,
			 {track="line"})

   pitchRandomSlider = newSlider(100+gridMarginLeft + 320, 710 + cellHeight ,
			 200, pitchRandom, 0, 1.0,
			 function(v) pitchRandom=v end,
			 {track="line"})

   customPitchSlider = newSlider(gridMarginLeft, 50  ,
			 100, customPitch, 0, 3.0,
			 function(v)
			    if openedInstrument > 0 then
			       pattern[openedInstrument].pitch = v
			       --print("wanna do stuff!", v)
			       --customPitch=pattern[openedInstrument].pitch
			    end
			    customPitch = v
			    
			 end,
			 {track="line"})

    customSwingSlider = newSlider(200 + gridMarginLeft, 50  ,
			 100, customSwing, 50, 100,
			 function(v)
			    if openedInstrument > 0 then
			       pattern[openedInstrument].swing = v
			       --print("wanna do stuff!", v)
			       --customPitch=pattern[openedInstrument].pitch
			    end
			    customSwing = v
			    
			 end,
			 {track="line"})
    
   --print(inspect(customPitchSlider))
end



function addBars(pattern, count)
   pattern.length = count
   for i = 1, #pattern do
      pattern[i].values = {}
      pattern[i].volume = 1.0
      pattern[i].muted = false
      pattern[i].pitch = 1.0
       pattern[i].swing = 50
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

	 customPitchSlider = newSlider(gridMarginLeft + 130,
				       index * cellHeight + gridMarginTop - 20  ,
			 100, (pattern[index]).pitch, 0, 3.0,
			 function(v)
			    if openedInstrument > 0 then
			       pattern[openedInstrument].pitch = v
			    end
			    customPitch = v
			    
			 end,
			 {track="line"})

	 customSwingSlider = newSlider(gridMarginLeft + 130 + 130,
				       index * cellHeight + gridMarginTop - 20  ,
			 100, (pattern[index]).swing, 50, 100,
			 function(v)
			    if openedInstrument > 0 then
			       pattern[openedInstrument].swing = v
			    end
			    customSwing = v
			    
			 end,
			 {track="line"})
   end
   

   -- check if you click an instrument to open its panel
   --love.graphics.rectangle('line',20,  gridMarginTop + (i-1)*cellHeight, gridMarginLeft-20, cellHeight )
end
function love.mousemoved(x,y)
   local down = love.mouse.isDown( 1)
   if down and openedInstrument == 0 then 
      handlePressInGrid(x,y, drawingValue)
   end
end


function love.update(dt)
   if (playing) then
      timeInBeat = timeInBeat +  dt

      local timeToAdd = 0 -- can also be negative
      if swing ~= 50 then
	 timeToAdd = ((swing-50)/100.0) * (60/bpm)

	 if playhead % 2 == 0 then
	    -- these we add
	 elseif  playhead % 2 == 1 then
	    timeToAdd = timeToAdd * -1
	 end
      end
      

      if (timeInBeat >= (60/bpm + timeToAdd)) then
	 playhead = playhead + 1
	 if (playhead > pattern.length) then playhead = 1 end
	 for i=1, #pattern do
	    if pattern[i].values[playhead] then
	       --print(inspect(pattern[i]))
	       local sfx = pattern[i].sound:clone()

	       --sfx:setVolume(love.math.random()*2)
	       --sfx:setPitch(0.2 + 1.8 * love.math.random())

	       --if not tostring(pitch) == "nan" then
	       local tempPitch = 0.000001 -- math.max(pitch, 0.0000001)
	       if pitchRandom then
		  tempPitch = math.max((love.math.random() * pitchRandom), 0.0000001)
		  if (love.math.random() > 0.5 ) then
		     tempPitch = tempPitch * -1
		  end

	       end
	       local p = math.max(pitch + (tempPitch*pitch), 0)
	       local step
	       if p < 1.0 then
		  step = 1.0 - p
	       else
		  if p > 0 then
		     step = p - 1.0
		  end
	       end
	       --print(p, 1.0/12, step, step * (1.0/12))
	       local getRandomNotePitch = function()
		  local r = love.math.random() * 12
		  return math.floor(r) * (1.0/12)
	       end

	       local layerPitch = pattern[i].pitch
	       print(layerPitch)
	       sfx:setPitch(math.max(p*layerPitch, 0.00001) )

	       --sfx:setPitch(math.max(getRandomNotePitch(), 0.000001))

	       --end
	       --sfx:setPitch(love.math.random())
	       
	       --love.audio.setPosition( 1 - love.math.random() * 2, 0, 0 )
	       love.audio.setVolume(1)
	       if playhead % 4 == 0 then
		  love.audio.setVolume(1.2)
	       end
	       
	       sfx:play()
	       end
	 end

	 timeInBeat = timeInBeat - (60/bpm + timeToAdd)
      end


   end
   bpmSlider:update()
   swingSlider:update()
   pitchSlider:update()
   pitchRandomSlider:update()
   customPitchSlider:update()
   customSwingSlider:update()
   
end


function love.draw()

   love.graphics.clear(255/colorDivider, 198/colorDivider, 49/colorDivider)
   love.graphics.setColor(35/colorDivider,36/colorDivider,38/colorDivider)
   love.graphics.setLineWidth( 2)

   
   for i =1, #pattern do
     
      
      love.graphics.print(pattern[i].name,  20, gridMarginTop + (i-1) * cellHeight)
      love.graphics.rectangle('line',20,  gridMarginTop + (i-1)*cellHeight, gridMarginLeft-20, cellHeight )
      --we assume some width is enough to fit all the names say 100
      for j=1, #(pattern[i].values)-1 do
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

   end

   if openedInstrument > 0 then
      --print(openedInstrument)
      love.graphics.setColor(255/colorDivider,0/colorDivider,0/colorDivider)
      love.graphics.rectangle('fill',
				    gridMarginLeft,
				    gridMarginTop + (openedInstrument-1)*cellHeight,
				    cellWidth * totalLength , cellHeight )
      love.graphics.setColor(0/colorDivider,0/colorDivider,0/colorDivider)
      love.graphics.print('pitch: '.. pattern[openedInstrument].pitch, gridMarginLeft,  gridMarginTop + (openedInstrument-1)*cellHeight)
      customPitchSlider:draw()

      customSwingSlider:draw()
   end
   

   if playing then
      love.graphics.setColor(255/colorDivider,255/colorDivider,255/colorDivider)
      love.graphics.setLineWidth(2)
      love.graphics.rectangle('line',
			      gridMarginLeft + (playhead-1)*24,
			      gridMarginTop, 24, cellHeight* #pattern )
   end

   love.graphics.setColor(0, 0, 0)

   -- draw slider, set color and line style before calling
    love.graphics.print('bpm: '..bpm, 20, 700)
    bpmSlider:draw()
    love.graphics.print('swing: '..swing, 20, 700+cellHeight)
    swingSlider:draw()
    love.graphics.print('pitch: '..pitch, 20 + 320, 700)
    pitchSlider:draw()
    love.graphics.print('pitch-rnd: '..pitchRandom, 20 + 320, 700 + cellHeight)
    pitchRandomSlider:draw()
end
