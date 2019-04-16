local pi2 = math.pi*2
local sin = math.sin

local Oscillator = function(freq)
	local phase = 0
	return function()
		phase = phase + pi2/rate
		if phase >= pi2 then
			phase = phase - pi2
		end
		return math.sin(freq*phase)
	end
end

function love.load()
    len = 1
    rate = 44100
    bits = 16
    channel = 1

    soundData = love.sound.newSoundData(len*rate,rate,bits,channel)
	height= love.window.getHeight()
	width = love.window.getWidth()
	hertz = math.random(440,880)
    osc = Oscillator(hertz)
    amplitude = 0.2
	
	waveY = {}

    for i=0,len*rate-1 do
        sample = osc() * amplitude
        soundData:setSample(i, sample)
		waveY[#waveY+1] = height/2 - sample*50
    end

    source = love.audio.newSource(soundData)
    love.audio.play(source)
	
end

function love.draw()
	for i = 1, width, 2 do
		love.graphics.line(i-2,table.remove(waveY,1),i,table.remove(waveY,2))
		
	end
end

function love.update(dt)
	math.randomseed(love.timer.getTime())
	if source:isStopped() then
		waveY = {}
		hertz = math.random(220,440)
		osc = Oscillator(hertz)
		len = math.random(0,100)
		if len%2 == 0 then
			len = 0.5
		else
			len = 1
		end
		soundData = love.sound.newSoundData(len*rate,rate,bits,channel)
		for i= 0,len*rate-1 do
			sample = osc() * amplitude
			soundData:setSample(i, sample)
			waveY[#waveY+1] = height/2 - sample*50
		end
		source = love.audio.newSource(soundData)
		source:play()
	end
end