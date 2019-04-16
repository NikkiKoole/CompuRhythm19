local denver = require 'denver'
inspect = require 'inspect'
require 'ui'


local thread -- Our thread object.
--local timer  -- A timer used to animate our circle.

function love.load()
   thread = love.thread.newThread( 'thread.lua' )
   thread:start( 99, 1000 )
   channel		= {};
   channel.a	= love.thread.getChannel ( "a" ); -- from thread
   channel.b	= love.thread.getChannel ( "b" ); -- from main
   
   font = love.graphics.newFont("digital-7 (mono italic).ttf", 64)
   love.graphics.setFont(font)
   soundData = love.sound.newSoundData( 'instruments/marimba.wav' )
   sound = love.audio.newSource(soundData, 'static')
   time = 0
   beat = 0
   tick = 0
   lastTick = 0

   waveData = {startPos=0, endPos=soundData:getSampleCount( )-1}
   canvas = love.graphics.newCanvas(600, 600)
   -- love.graphics.setCanvas(canvas)
   -- love.graphics.clear()
   -- renderWaveForm(soundData, 600, 600)
   love.graphics.setCanvas()
   lastMouseDown = nil
   lastDraggedElement = nil
   octave = 0 -- c4

   --lastSemiTone = 0
end
function love.mousereleased(x, y)
   lastDraggedElement = nil
end


function writeSoundData(toClone, startPos, endPos)
   local sound_data = love.sound.newSoundData((endPos - startPos)+1, 44100, 16, 1)
   for i = startPos, endPos do
      sound_data:setSample(i-startPos, toClone:getSample(i)  )
   end
   return sound_data
end


function renderWave(data, startPos, endPos, width, height)
   local count = data:getSampleCount( )

   if endPos == -1 then endPos = count-1 end
   assert(endPos <= count)
   assert(startPos >= 0)

   love.graphics.setColor(1,1,1)
   
   for i = startPos, endPos do
      local s = data:getSample(i)
      local x = ((i - startPos)/(endPos - startPos)) * width
      local y = s * (height/2)
      love.graphics.line(100+math.floor(x), math.floor(y)+ 300, 100+math.floor(x), 300)
   end
   
end

function mapInto(x, in_min, in_max, out_min, out_max)
   return (x - in_min) * (out_max - out_min) / (in_max - in_min) + out_min
end

function playNote(semitone)
--http://pages.mtu.edu/~suits/notefreqs.html
-- C4	        261.63	131.87
-- C#4/Db4 	277.18	124.47
-- D4	        293.66	117.48
-- D#4/Eb4 	311.13	110.89
-- E4	        329.63	104.66
-- F4	        349.23	98.79
-- F#4/Gb4 	369.99	93.24
-- G4	        392.00	88.01
-- G#4/Ab4 	415.30	83.07
-- A4	        440.00	78.41
-- A#4/Bb4 	466.16	74.01
-- B4	        493.88	69.85
-- C5	        523.25	65.93

   local plusoctave = 0
   if semitone > 11 then
      plusoctave = 1
      semitone = semitone % 12
   end
   
   local freqs = {261.63, 277.18, 293.66, 311.13, 329.63, 349.23, 369.99, 392.00, 415.30, 440.00, 466.16, 493.88, 523.25}
   local n = mapInto(freqs[semitone+1], 261.63, 523.25, 0, 1)
   
   clonedData = writeSoundData(soundData, waveData.startPos, waveData.endPos)
   local c = love.audio.newSource(clonedData, 'static')
   local s = c:clone()
   local o = octave + plusoctave

   if o == -5 then s:setPitch(0.0625 -(0.03125 -  n/32))
   elseif o == -4 then s:setPitch(0.125 -(0.0625 -  n/16))
   elseif o == -3 then s:setPitch(0.25 -(0.125 -  n/8))
   elseif o == -2 then s:setPitch(0.5 -(0.25 -  n/4))
   elseif o == -1 then s:setPitch(1 -(0.5 -  n/2))
   elseif o == 0 then s:setPitch(1 + n)
   elseif o == 1 then s:setPitch(2 + 2*n)
   elseif o == 2 then s:setPitch(4 + 4*n)
   elseif o == 3 then s:setPitch(8 + 8*n)
   elseif o == 4 then s:setPitch(16 + 16*n)
   elseif o == 5 then s:setPitch(32 + 32*n)
   end

   s:setVolume(0.25)
   love.audio.play(s)
end



function love.keypressed(key)
   if key == "escape" then
      love.event.quit()
   end
   
   if key == "q" then
      print(math.floor(beat), math.floor(tick))
      love.thread.getChannel( 'info' ):push( "poep" )
   end

   if key == 'z' then
      octave = octave -1
   end
   if key == 'x' then
      octave = octave +1
   end
   if key == 'a' then
      playNote(0)
   end
   if key == 'w' then
      playNote(1)
   end
   if key == 's' then
      playNote(2)
   end
   if key == 'e' then
      playNote(3)
   end
   if key == 'd' then
      playNote(4)
   end
   if key == 'f' then
      playNote(5)
   end
   if key == 't' then
      playNote(6)
   end
   if key == 'g' then
      playNote(7)
   end
   if key == 'y' then
      playNote(8)
   end
   if key == 'h' then
      playNote(9)
   end
   if key == 'u' then
      playNote(10)
   end
   if key == 'j' then
      playNote(11)
   end
   if key == 'k' then
      playNote(12)
   end
   if key == 'o' then
      playNote(13)
   end
   if key == 'l' then
      playNote(14)
   end
   if key == 'p' then
      playNote(15)
   end
   if key == ';' then
      playNote(16)
   end
   if key == "'" then
      playNote(17)
   end
   
end


function love.update(dt)
   local bpm = 90 -- beats per minute
   local tpb = 96 -- ticks per beat
   
   time = time + dt
   beat = time * (bpm / 60)
   tick = ((beat % 1) * (tpb))

   if math.floor(tick) - math.floor(lastTick) > 1 then
      --print('main thread: missed a  tick:', math.floor(tick), 'last:',math.floor(lastTick))
   end

   lastTick = tick

   local error = thread:getError()
   assert( not error, error )

   local v = channel.a:pop ();
   --print(channel.a:getCount())
   if v then
      --print ( tostring ( v ) );
      channel.b:push ( "foo" );
   end
end

function love.draw()
      love.graphics.clear(255/255, 198/255, 49/255)

   local mouseDown = love.mouse.isDown(1 )
   local run = false

   if mouseDown ~= lastMouseDown then
      if mouseDown then
         run = true
      end
   end
   lastMouseDown = mouseDown
   
   love.graphics.setColor(0.5, 0.5, 0.5)
   love.graphics.print(string.format("%02d", 1+math.floor(beat) % 4) ..':'..string.format("%02d", 1+math.floor(tick) ) )
   love.graphics.setColor(1,1,1)
   love.graphics.draw(canvas, 100, 0)
   --renderWaveForm(soundData, 600, 600)
   renderWave(soundData, waveData.startPos, waveData.endPos, 500, 300)

   local sp = draw_horizontal_slider('startPos', 100 , 100, 500, waveData.startPos, 0, soundData:getSampleCount( ), run)
   if sp.value then
      waveData.startPos = sp.value
      if waveData.startPos > waveData.endPos then
	 waveData.startPos = waveData.endPos
      end
      
   end
   local ep = draw_horizontal_slider('endPos', 100 , 110, 500, waveData.endPos, 0, soundData:getSampleCount( )-1, run)
   if ep.value then
      waveData.endPos = ep.value
      if waveData.endPos < waveData.startPos then
	 waveData.endPos = waveData.startPos
      end
   end
   

   local info = love.thread.getChannel( 'info' ):pop()
    if info then
        love.graphics.print( info, 100, 100 )
    end
end

