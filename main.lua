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
   if key == '2' then
      local clone_sfx = cb:clone()
      clone_sfx:play()
   end
   if key == '3' then
      local clone_sfx = bh:clone()
      clone_sfx:play()
   end
   if key == '4' then
      local clone_sfx = bl:clone()
      clone_sfx:play()
   end
   if key == '5' then
      local clone_sfx = ta:clone()
      clone_sfx:play()
   end
   if key == '6' then
      local clone_sfx = co:clone()
      clone_sfx:play()
   end
   if key == '7' then
      local clone_sfx = hm:clone()
      clone_sfx:play()
   end
   if key == '8' then
      local clone_sfx = gl:clone()
      clone_sfx:play()
   end
   if key == '9' then
      local clone_sfx = hh:clone()
      clone_sfx:play()
   end
   if key == '0' then
      local clone_sfx = gs:clone()
      clone_sfx:play()
   end
   
end

--Bongo High
--Bongo Low
--Conga Low
--Cowbell
--Cymbal
--Guiro 1
--Guiro 2
-- x HiHat Accent
--HiHat Metal
--HiHat
--Kick Accent
--Kick
--Rim Shot
-- x Snare Accent
--Snare
--Tamb 1
-- x Tamb 2

function love.load()
   love.window.setMode(1024, 768)
   cy = love.audio.newSource('samples/Cymbal.wav', 'static')
   cb = love.audio.newSource('samples/Cowbell.wav', 'static')
   -- maracas?
   bh = love.audio.newSource('samples/Bongo High.wav', 'static')
   bl = love.audio.newSource('samples/Bongo Low.wav', 'static')
   
   ta = love.audio.newSource('samples/Tamb 1.wav', 'static')
   co = love.audio.newSource('samples/Conga Low.wav', 'static')
   -- metalic beat?
   hm = love.audio.newSource('samples/HiHat Metal.wav', 'static')
   -- guiro long
   gl = love.audio.newSource('samples/Guiro 2.wav', 'static')
   hh = love.audio.newSource('samples/HiHat.wav', 'static')
   gs = love.audio.newSource('samples/Guiro 1.wav', 'static')

   -- clave ?
   --xx = love.audio.newSource('samples/Guiro 1.wav', 'static')
   sr = love.audio.newSource('samples/Snare.wav', 'static')
   rm = love.audio.newSource('samples/Rim Shot.wav', 'static')
   kc = love.audio.newSource('samples/Kick.wav', 'static')
   ka = love.audio.newSource('samples/Kick Accent.wav', 'static')
   
   --cy:play()
   pattern = {
      
   }
   emptyPattern(pattern, 24)
   print(inspect(pattern))

   bpm = 200
   playing = false
   playhead = 1
   timeInBeat = 0
end



function emptyPattern(p, count)
   table.insert(p, {})
   table.insert(p, {})

   for i = 0, count do
      table.insert(p[1], false)
      table.insert(p[2], false)
   end
end
			       
function love.mousepressed(x, y)
   if (y < 0 or y > #pattern * 32) then return end
   if (x < 0 or x > ((#pattern[1]) * 32)) then return end
   local index = math.floor(x/32) + 1
   local row = math.floor(y/32) + 1
   print(row, index)
   pattern[row][index] = not pattern[row][index]
end

function love.update(dt)
   if (playing) then
      timeInBeat = timeInBeat +  dt
      if (timeInBeat > 60/bpm) then
	 playhead = playhead + 1
	 if (playhead > #pattern[1]) then playhead = 1 end
	 if pattern[1][playhead] then
	    local clone_sfx = rm:clone()
	    clone_sfx:setPitch(love.math.random()/2)
	    clone_sfx:play()
	 end
	 if pattern[2][playhead] then
	    local clone_sfx = cy:clone()
	    clone_sfx:setPitch(love.math.random()/2)
	    clone_sfx:play()
	 end
	 
	 timeInBeat = timeInBeat - 60/bpm
      end
      

   end
   
end


function love.draw()
   love.graphics.clear(255/255, 198/255, 49/255)
   love.graphics.setColor(35/255,36/255,38/255)
   love.graphics.setLineWidth( 1)

   for y = 1, 2 do
   for x = 1, #pattern[y] do
      if (pattern[y][x]) then
	 love.graphics.rectangle('fill',-32 + x*32, -32 + y*32, 32, 32 )
      else
	 love.graphics.rectangle('line',-32 + x*32, -32 + y*32, 32, 32 )
      end
   end
   end
   
   if playing then
      love.graphics.setColor(255/255,255/255,255/255)
      love.graphics.setLineWidth(2)
      love.graphics.rectangle('line',-32 + playhead*32, 0, 32, 32* #pattern )
   end
   
end
