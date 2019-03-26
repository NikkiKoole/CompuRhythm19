inspect = require "inspect"
require 'simple-slider'

colorDivider = 1.0


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
    local data = file:read()
    --print("Content of " .. file:getFilename() .. ' is')
    --print(data)
    local read = loadstring("return "..data)()
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
       pattern[i].volume = read[i].volume
       pattern[i].values = read[i].values
    end

    pattern.length = read.length
    pattern.bpm = read.bpm
    pattern.swing = read.swing
    pattern.pitch = read.pitch
    pattern.pitchRandom = read.pitchRandom

    updateSliders()
    print(pattern.bpm)

end

function love.load()
   love.window.setMode(1024, 768)
   font = love.graphics.newFont("futura.ttf", 20)
   love.graphics.setFont(font)

   pattern = {
      -- {name='Clarinet', sound=love.audio.newSource('samples/clarinet_loop_middle.wav', 'static')},
      --{name='Piano', sound=love.audio.newSource('samples/Yamaha-DX7-E-Piano-1-C5.wav', 'static')},
      {name='donk1', url='samples/donk/Donk1.wav'},
      {name='donk5', url='samples/donk/Donk5.wav'},
      {name='Cymbal', url='samples/Cymbal.wav'},
      {name='Cowbell', url='samples/Cowbell.wav'},
      {name='Conga', url='samples/Conga Low.wav'},
      {name='HiHat accent', url='samples/HiHat Accent.wav'},
      {name='Bongo High', url='samples/Bongo High.wav'},
      {name='Bongo Low', url='samples/Bongo Low.wav'},
      {name='Tamb 1', url='samples/Tamb 1.wav'},
      {name='Tamb 2', url='samples/Tamb 2.wav'},
      {name='Conga Low', url='samples/Conga Low.wav'},
      {name='HiHat Metal', url='samples/HiHat Metal.wav'},
      {name='HiHat', url='samples/HiHat.wav'},
      {name='Guiro 1', url='samples/Guiro 1.wav'},
      {name='Guiro 2', url='samples/Guiro 2.wav'},
      {name='Snare accent', url='samples/Snare Accent.wav'},
      {name='Snare', url='samples/Snare.wav'},
      {name='Rim', url='samples/Rim Shot.wav'},
      {name='Kick', url='samples/Kick.wav'},
      {name='Kick accent', url='samples/Kick Accent.wav'},
      }
--love.audio.newSource('samples/Conga Low.wav', 'static')
   totalLength = 32
   addBars(pattern, totalLength)
   timers = prepareTimers(pattern)

   pattern.bpm = 300
   pattern.swing = 50
   pattern.pitch = 1.0
   pattern.pitchRandom = 0

   playing = false

   gridMarginTop = 100
   gridMarginLeft = 110
   drawingValue = 1
   cellWidth = 24
   cellHeight = 32

   openedInstrument = 0
   customPitch = 0
   customSwing = 50
   customVolume = 1
   customRandomPitch = 1



   --path = love.filesystem.getAppdataDirectory( )
   --print(path)

   updateSliders()

   customPitchSlider = newSlider(gridMarginLeft, 50  ,
			 100, customPitch, 0, 3.0,
			 function(v)
			    if openedInstrument > 0 then
			       pattern[openedInstrument].pitch = v
			    end
			    customPitch = v

			 end,
			 {track="line"})

   customVolumeSlider = newSlider(gridMarginLeft, 50  ,
			 100, customVolume, 0, 1.0,
			 function(v)
			    if openedInstrument > 0 then
			       pattern[openedInstrument].volume = v
			    end
			    customVolume = v
			 end,
			 {track="line"})

    customSwingSlider = newSlider(300 + gridMarginLeft, 50  ,
			 100, customSwing, 50, 100,
			 function(v)
			    if openedInstrument > 0 then
			       pattern[openedInstrument].swing = v
			    end
			    customSwing = v

			 end,
			 {track="line"})
    customRandomPitchSlider = newSlider(300 + gridMarginLeft, 50  ,
			 100, customRandomPitch, 50, 100,
			 function(v)
			    if openedInstrument > 0 then
			       pattern[openedInstrument].randomPitch = v
			    end
			    customRandomPitch = v

			 end,
			 {track="line"})


end

function updateSliders()
    bpmSlider = newSlider(100+gridMarginLeft, 710,
			 200, pattern.bpm, 0, 1000,
			 function(v) pattern.bpm=v end,
			 {track="line"})

   swingSlider = newSlider(100+gridMarginLeft, 710 + cellHeight,
			 200, pattern.swing, 0, 100,
			 function(v) pattern.swing=v end,
			 {track="line"})

   pitchSlider = newSlider(100+gridMarginLeft + 320, 710 ,
			 200, pattern.pitch, 0, 1.0,
			 function(v) pattern.pitch=v end,
			 {track="line"})

   pitchRandomSlider = newSlider(100+gridMarginLeft + 320, 710 + cellHeight ,
			 200, pattern.pitchRandom, 0, 1.0,
			 function(v) pattern.pitchRandom=v end,
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

	 customSwingSlider = newSlider(gridMarginLeft + 130 + 200,
				       index * cellHeight + gridMarginTop - 20  ,
			 100, (pattern[index]).swing, 0, 100,
			 function(v)
			    if openedInstrument > 0 then
			       pattern[openedInstrument].swing = v
			    end
			    customSwing = v

			 end,
			 {track="line"})

	 customVolumeSlider = newSlider(gridMarginLeft + 130 + 400,
				       index * cellHeight + gridMarginTop - 20  ,
			 100, (pattern[index]).volume, 0, 1,
			 function(v)
			    if openedInstrument > 0 then
			       pattern[openedInstrument].volume = v
			    end
			    customVolume = v

			 end,
			 {track="line"})

	 customRandomPitchSlider = newSlider(gridMarginLeft + 130 + 600,
				       index * cellHeight + gridMarginTop - 20  ,
			 100, (pattern[index]).randomPitch, 0, 1,
			 function(v)
			    if openedInstrument > 0 then
			       pattern[openedInstrument].randomPitch = v
			    end
			    customRandomPitch = v

			 end,
			 {track="line"})
   end

end
function love.mousemoved(x,y)
   local down = love.mouse.isDown( 1)
   if down and openedInstrument == 0 then
      handlePressInGrid(x,y, drawingValue)
   end
end


function love.update(dt)
   if (playing) then

      for i=1, #pattern do
	 timers[i].timeInBeat = timers[i].timeInBeat + dt

	 local timeToAdd = 0

	 if pattern.swing ~= 50 then
	    timeToAdd = ((pattern.swing-50)/100.0) * (60/pattern.bpm)

	    if timers[i].playhead % 2 == 0 then
	       -- these we add
	    elseif  timers[i].playhead % 2 == 1 then
	       timeToAdd = timeToAdd * -1
	    end
	 end

	 if pattern[i].swing ~= 50 then
	    timeToAdd = ((pattern[i].swing-50)/100.0) * (60/pattern.bpm)

	    if timers[i].playhead % 2 == 0 then
	       -- these we add
	    elseif  timers[i].playhead % 2 == 1 then
	       timeToAdd = timeToAdd * -1
	    end
	 end

	 if (timers[i].timeInBeat >= (60/pattern.bpm + timeToAdd)) then
	    timers[i].playhead = timers[i].playhead + 1
	    if (timers[i].playhead > pattern.length) then timers[i].playhead = 1 end

	    if pattern[i].values[timers[i].playhead] then
	       local sfx = pattern[i].sound:clone()

	       local tempPitch = 0.000001 -- math.max(pattern.pitch, 0.0000001)

	       if pitchRandom then
		  tempPitch = math.max((love.math.random() * pattern.pitchRandom), 0.0000001)
		  if (love.math.random() > 0.5 ) then
		     tempPitch = tempPitch * -1
		  end
	       end
	       if pattern[i].randomPitch > 0 then
		  -- tempPitch = math.max((love.math.random() * pattern[i].randomPitch), 0.0000001)
		  -- if (love.math.random() > 0.5 ) then
		  --    tempPitch = tempPitch * -1
		  -- end
		  local notes = {0, 4, 7}
		  local picked = math.floor(math.random()* #notes)
		  local p = notes[picked+1]
		  --local twelve = (math.floor(love.math.random()*12))
		  --twelve =  timers[i].playhead % 12
		  --local p = (1.0/12) * twelve
		  --print(twelve, p, pattern[i].randomPitch)
		  tempPitch = 1 + (1.0/12)*p
	       end


	       local p = math.max(pattern.pitch + (tempPitch*pattern.pitch), 0)
	       local layerPitch = pattern[i].pitch
	       sfx:setPitch(math.max(p*layerPitch, 0.00001) )

	       -- accents

	       local volume = 0.8

	       --love.audio.setVolume(1)
	       if timers[i].playhead % 4 == 0 then
		  volume = volume + 0.2
		  --love.audio.setVolume(1.2)
	       end

	       if pattern[i].randomPitch > 0 then
		  local sfx2 = pattern[i].sound:clone()
		  local sfx3 = pattern[i].sound:clone()

		  -- how to get the value for much higher and lower say +2 and -2 octaves ?
		  -- in 1 octave higher (+1) its 12 steps of pitch between 2.0 and 4.0
		  -- in 2 octave higher (+1) its 12 steps of pitch between 4.0 and 8.0
		  -- in 1 octave lower (+1) its 12 steps of pitch between 0 and 1
		  --0.5 == 1 octave lower
		  --0.25 is two
		  local octave = math.floor(love.math.random()*3) + 1
		  --print(octave)
		  octave = 1 --+ timers[i].playhead % 3
--		  local froms = {
--		     0.25, 0.5, 1.0, 2.0, 4.0
--		  }
--		  local froms = {
--		     0.5, 1.0, 2.0
--		  }
		  local froms = {
		     1.0
		  }

		  --print(octave)
		  --local chords = {
		  --   {0,4,7}, {}
		 -- }
		  --if timers[i].playhead % 2 == 0 then
		  sfx:setPitch(froms[octave] + 0 * (froms[octave]/12.0))
		  sfx:setPitch(froms[octave] + 4 * (froms[octave]/12.0))
		  sfx:setPitch(froms[octave] + 7 * (froms[octave]/12.0))

		  --else
		  -- sfx:setPitch(froms[octave] + 7 * (froms[octave]/12.0))
		  -- sfx:setPitch(froms[octave] + 11 * (froms[octave]/12.0))
		  -- sfx:setPitch(froms[octave] + 3 * (froms[octave]/12.0))
		  --end
		  sfx:play()
		  sfx2:play()
		  sfx3:play()
		  --print(inspect(sfx))
	       else
		  -- if i == 1 then -- clarinet is first
		  --    sfx:setLooping(true)
		  -- end

	       volume = volume * pattern[i].volume
	       sfx:setVolume(volume)
	       sfx:play()
	       --print(sfx:tell("samples"))
	       end
	    end
	    timers[i].timeInBeat = timers[i].timeInBeat - (60/pattern.bpm + timeToAdd)
	 end

      end

   end




   bpmSlider:update()
   swingSlider:update()
   pitchSlider:update()
   pitchRandomSlider:update()
   customPitchSlider:update()
   customSwingSlider:update()
   customVolumeSlider:update()
   customRandomPitchSlider:update()
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
      love.graphics.setColor(255/colorDivider,218/colorDivider,69/colorDivider)
      love.graphics.rectangle('fill',
				    gridMarginLeft - 1,
				    -1 + gridMarginTop + (openedInstrument-1)*cellHeight,
				    2 + cellWidth * totalLength , 2+ cellHeight )
      love.graphics.setColor(0/colorDivider,0/colorDivider,0/colorDivider)
      love.graphics.print('pitch: '.. pattern[openedInstrument].pitch, gridMarginLeft,  gridMarginTop + (openedInstrument-1)*cellHeight)
      customPitchSlider:draw()
      love.graphics.print('swing: '.. pattern[openedInstrument].swing, gridMarginLeft+ 200,  gridMarginTop + (openedInstrument-1)*cellHeight)
      customSwingSlider:draw()
      love.graphics.print('volume: '.. pattern[openedInstrument].volume, gridMarginLeft+ 400,  gridMarginTop + (openedInstrument-1)*cellHeight)
      customVolumeSlider:draw()
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
    love.graphics.print('bpm: '..pattern.bpm, 20, 700)
    bpmSlider:draw()
    love.graphics.print('swing: '..pattern.swing, 20, 700+cellHeight)
    swingSlider:draw()
    love.graphics.print('pitch: '..pattern.pitch, 20 + 320, 700)
    pitchSlider:draw()
    --love.graphics.print('pitch-rnd: '..pattern.pitchRandom, 20 + 320, 700 + cellHeight)
    --pitchRandomSlider:draw()
--    count = love.audio.getActiveSourceCount( )
--    love.graphics.print('sources: '..count, 0,0)

end
