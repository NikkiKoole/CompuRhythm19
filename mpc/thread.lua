require('love.timer')
require('love.sound')
require('love.audio')

local min, max = ...
local now = love.timer.getTime()
local time = 0
local lastTick = 0

channel 	= {};
channel.a	= love.thread.getChannel ( "a" ); -- from thread
channel.b	= love.thread.getChannel ( "b" ); --from main
 
soundData = love.sound.newSoundData( 'instruments/marimba.wav' )
sound = love.audio.newSource(soundData, 'static')

--local mytick = 0
while(true) do
   --for i = min, max do
    -- The Channel is used to handle communication between our main thread and
    -- this thread. On each iteration of the loop will push a message to it which
   -- we can then pop / receive in the main thread.

   local v = channel.b:pop ();
   if v then
      --print ( tostring ( v ) );
      --channel.a:push ( "bar" )
   end
   
   
   local n = love.timer.getTime()
   local delta = n - now
   local result = ((delta * 1000))
   
   now = n
   time = time + delta
   local beat = time * (90 / 60)
   local tick = ((beat % 1) * (96))
   if math.floor(tick) - math.floor(lastTick) > 1 then
      print('thread: missed ticks:', math.floor(beat), math.floor(tick), math.floor(lastTick))

   end

   if math.floor(tick) ~= math.floor(lastTick) then
      if math.floor(tick)  % 32 == 0  then
	 --print(beat, tick)
	 local s = sound:clone()
	 --s:setPitch(math.random()*30)
	 love.thread.getChannel( 'a' ):push("note played")
	 --love.audio.play(s)
      end
      
      --print( math.floor(tick), math.floor(lastTick))
   end
   
   --love.thread.getChannel( 'info' ):push( result )

   lastTick = tick
   --love.timer.sleep(0.01)
   
end
