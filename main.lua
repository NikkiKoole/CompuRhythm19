inspect = require "inspect"

function love.keypressed(key)
   if key == "escape" then
      love.event.quit()
   end
   if key == "space" then
      playing = not playing
      
   end
   
   if key == '1' then
      local clone_sfx = cy:clone()
      clone_sfx:play()
   end
   if key == 'w' then
      bpm = bpm + 5
   end
   if key == 'q' then
      bpm = bpm - 5
   end

   -- if key == '2' then
   --    local clone_sfx = cb:clone()
   --    clone_sfx:play()
   -- end
   -- if key == '3' then
   --    local clone_sfx = bh:clone()
   --    clone_sfx:play()
   -- end
   -- if key == '4' then
   --    local clone_sfx = bl:clone()
   --    clone_sfx:play()
   -- end
   -- if key == '5' then
   --    local clone_sfx = ta:clone()
   --    clone_sfx:play()
   -- end
   -- if key == '6' then
   --    local clone_sfx = co:clone()
   --    clone_sfx:play()
   -- end
   -- if key == '7' then
   --    local clone_sfx = hm:clone()
   --    clone_sfx:play()
   -- end
   -- if key == '8' then
   --    local clone_sfx = gl:clone()
   --    clone_sfx:play()
   -- end
   -- if key == '9' then
   --    local clone_sfx = hh:clone()
   --    clone_sfx:play()
   -- end
   -- if key == '0' then
   --    local clone_sfx = gs:clone()
   --    clone_sfx:play()
   -- end
   
end


function love.load()
   love.window.setMode(1024, 768)

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
      --{name='DX7-E-Piano-C5', sound=love.audio.newSource('samples/DX7-E-Piano-C5.wav', 'static')}

   }
   
   
   
   addBars(pattern, 16)
   bpm = 300
   playing = false
   playhead = 1
   timeInBeat = 0
end



function addBars(pattern, count)
   pattern.length = count
   for i = 1, #pattern do
      pattern[i].values = {}
      for j = 0, count do
	 table.insert(pattern[i].values, false)
      end
   end
end
			       
function love.mousepressed(x, y)
   local x2 = x - 100
   if (y < 0 or y > #pattern * 32) then return end
   if (x2 < 0 or x2 > pattern.length * 32) then return end
   local index = math.floor(x2/32) + 1
   local row = math.floor(y/32) + 1
   pattern[row].values[index] = not pattern[row].values[index]
end

function love.update(dt)
   if (playing) then
      timeInBeat = timeInBeat +  dt
      if (timeInBeat > 60/bpm) then
	 playhead = playhead + 1
	 if (playhead > pattern.length) then playhead = 1 end
	 for i=1, #pattern do
	       if pattern[i].values[playhead] then
		  local sfx = pattern[i].sound:clone()
		  --sfx:setVolume(love.math.random()*2)
		  --sfx:setPitch(0.2 + 1.8 * love.math.random())

		  --sfx:setPitch(2)
		  --sfx:setPitch(love.math.random()/3)

		  sfx:play()
	       end
	 end
 
	 timeInBeat = timeInBeat - 60/bpm
      end
      

   end
   
end


function love.draw()
   love.graphics.clear(255/255, 198/255, 49/255)

   love.graphics.setColor(35/255,36/255,38/255)
   --love.graphics.circle("fill", 100, 600, 24)
   --love.graphics.setColor(255/255,255/255,255/255)
   love.graphics.circle("line", 100, 600, 24)

   
   love.graphics.setColor(35/255,36/255,38/255)
   love.graphics.setLineWidth( 1)
   love.graphics.print(bpm, 0, 700)

   
   
   for i =1, #pattern do

      love.graphics.print(pattern[i].name, 0, -32+ 32 * i)

      --we assume some width is enough to fit all the names say 100
      for j=1, #(pattern[i].values)-1 do
	 if (pattern[i].values[j]) then
    	    love.graphics.rectangle('fill',100 + -32 + j*32, -32 + i*32, 32, 32 )
    	 else
    	    love.graphics.rectangle('line',100 + -32 + j*32, -32 + i*32, 32, 32 )
    	 end
      end
      
   end
   
   if playing then
      love.graphics.setColor(255/255,255/255,255/255)
      love.graphics.setLineWidth(2)
      love.graphics.rectangle('line',100 + -32 + playhead*32, 0, 32, 32* #pattern )
   end


   
end
