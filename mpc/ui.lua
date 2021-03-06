
function pointInRect(x,y, rx, ry, rw, rh)
   if x < rx or y < ry then return false end
   if x > rx+rw or y > ry+rh then return false end
   return true
end
function distance(x, y, x1, y1)
   local dx = x - x1
   local dy = y - y1
   local dist = math.sqrt(dx * dx + dy * dy)
   return dist
end

function pointInCircle(x,y, cx, cy, radius)

   if distance(x,y,cx,cy) < radius then
      return true
   else
      return false
   end
end
function draw_button(x,y,p, run)
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
function draw_label_button(x,y, label, p, run)
   local buttonWidth = 90
   local result= false
   if p then
      local r,g,b,a = love.graphics.getColor()
      love.graphics.setColor(r,g,b,0.5)
      love.graphics.rectangle('fill',x,y,buttonWidth,cellHeight )
      love.graphics.setColor(r,g,b,a)

   else
      love.graphics.rectangle('line',x,y,buttonWidth,cellHeight )
   end
   love.graphics.print(label, x+5, y)

   if run then
      local mx, my = love.mouse.getPosition( )
      if pointInRect(mx,my, x,y,buttonWidth,cellHeight) then
         result = true
      end
   end

   return {
      clicked=result
   }
end


function angle(x1,y1, x2, y2)
   local dx = x2 - x1
   local dy = y2 - y1
   return math.atan2(dx,dy)
end
function angleAtDistance(x,y,angle, distance)
   local px = math.cos( angle ) * distance
   local py = math.sin( angle ) * distance
   return px, py
end
function lerp(a, b, t)
   return a + (b - a) * t
end


function mapInto(x, in_min, in_max, out_min, out_max)
   return (x - in_min) * (out_max - out_min) / (in_max - in_min) + out_min
end


function draw_horizontal_slider(id, x, y, width, v, min, max, mouseClicked)
   love.graphics.setColor(0.3, 0.3, 0.3)
   love.graphics.rectangle('fill',x,y+8,width,3 )
   love.graphics.setColor(0, 0, 0)
   local xOffset = mapInto(v, min, max, 0, width)
   love.graphics.rectangle('fill',xOffset + x,y,20,20 )

   local result= nil
   local draggedResult = false

   if mouseClicked then
      local mx, my = love.mouse.getPosition( )
      if pointInRect(mx,my, xOffset+x,y,20,20) then
         lastDraggedElement = {id=id}
      end
   end
   if love.mouse.isDown(1 ) then
      if lastDraggedElement and lastDraggedElement.id == id then
         local mx, my = love.mouse.getPosition( )
         result = mapInto(mx, x, x+width, min, max)
         result = math.max(result, min)
         result = math.min(result, max)
      end
   end
   return {
      value=result
   }
end

function draw_vertical_slider(id, x, y, height, v, min, max, mouseClicked)
   love.graphics.rectangle('fill',x+8,y,3,height )
   local yOffset = mapInto(v, min, max, 0, height)
   love.graphics.rectangle('fill',x,y +height - yOffset - 10,20,20 )

   local result= nil
   local draggedResult = false

   -- if mouseClicked then
   --    local mx, my = love.mouse.getPosition( )
   --    if pointInRect(mx,my, x,y+height-yOffset,20,20) then
   --       lastDraggedElement = {id=id}
   --    end
   -- end

   if love.mouse.isDown(1 ) then
      local mx, my = love.mouse.getPosition( )
      if (lastDraggedElement and lastDraggedElement.id == id) or
      (mx <= x+20 and mx >x) then

         result = mapInto(my, y+height+10, y, min, max)
         result = math.max(result, min)
         result = math.min(result, max)

      end
   end
   return {
      value=result
   }
end

function draw_knob(id, x,y, v, min, max, mouseClicked)
   local result = nil
   local r,g,b,a = love.graphics.getColor()
   love.graphics.setColor(0, 0, 0)
   love.graphics.circle("fill", x, y, cellHeight/2, 100) -- Draw white circle with 100 segments.

   love.graphics.setColor(1, 1, 1)
   local mx, my = love.mouse.getPosition( )

   a = -math.pi/2
   ax, ay = angleAtDistance(x,y,-a, cellHeight/2)
   bx, by = angleAtDistance(x,y,-a, cellHeight/4)
   love.graphics.setColor(1, 1, 1, 0.5)
   love.graphics.line(x+ax,y+ay,x+bx,y+by)
   love.graphics.setColor(1, 1, 1, 1)

   a = mapInto(v, min, max, 0 + math.pi/2, math.pi*2 + math.pi/2)
   ax, ay = angleAtDistance(x,y,a, cellHeight/2)
   bx, by = angleAtDistance(x,y,a, cellHeight/4)
   love.graphics.setColor(1, 1, 1)
   love.graphics.line(x+ax,y+ay,x+bx,y+by)
   love.graphics.setColor(r,g,b,a)
   if mouseClicked then
      local mx, my = love.mouse.getPosition( )
      -- click to start dragging
      if pointInCircle(mx,my, x,y,cellHeight/2) then
         lastDraggedElement = {id=id, initialAngle=angle(mx, my, x, y), rolling=0}
      end
   end

   if love.mouse.isDown(1 ) then
      if lastDraggedElement and lastDraggedElement.id == id then
         local mx, my = love.mouse.getPosition( )
         local a = angle(mx, my, x, y)

         result = mapInto(a, math.pi, -math.pi, min, max)

         if a ~= lastDraggedElement.rolling then
            lastDraggedElement.rolling = a
         else

            result = nil
         end
         love.graphics.line(mx,my,x,y)

      end
   end

   return {
      value=result
   }
end
