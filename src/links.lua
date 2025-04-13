--[[
Copyright (c) 2025 Ricardo Florentino

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

Except as contained in this notice, the name(s) of the above copyright holders
shall not be used in advertising or otherwise to promote the sale, use or
other dealings in this Software without prior written authorization.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
]]--

local Vec = require 'FermionPhysics.src.vec'
local Class = require 'FermionPhysics.src.class'

local sqrt, cos, sin, atan2 = math.sqrt, math.cos, math.sin, math.atan2

local Links = {}

Links.Acceleration = Class:extend()
function Links.Acceleration:init(acc)
  self.acc = acc
end
function Links.Acceleration:update(dt, body)
  body:addForce(self.acc/body.massInv)
end
function Links.Acceleration:draw(body) end

Links.Gravity = Class:extend()
function Links.Gravity:init(gravity)
  self.gravity = gravity
end
function Links.Gravity:update(dt, body1, body2)
  local r = body2.pos - body1.pos
  local force = self.gravity*r/(body1.massInv*body2.massInv*r:len()^3)
  body1:addForce(force)
  body2:addForce(-force)
end
function Links.Gravity:draw() end

Links.AngAcc = Class:extend()
function Links.AngAcc:init(angAcc)
  self.angAcc = angAcc
end
function Links.AngAcc:update(dt, body)
  body:addForce(Vec(0,1)*self.angAcc/body.inerInv, Vec(1,0))
end
function Links.AngAcc:draw(body) end

Links.RestoringTorque = Class:extend()
function Links.RestoringTorque:init(torque)
  self.torque = torque
end
function Links.RestoringTorque:update(dt, body)
  body:addLocalForce(self.torque*body.ori:perpendicular()*body.ori:cross(Vec(1,0)), Vec(1,0))
  body:addForce(-self.torque*body.ori:perpendicular()*body.ori:cross(Vec(1,0)))
end
function Links.RestoringTorque:draw(body) end

Links.Mouse = Class:extend()
function Links.Mouse:init(force)
  self.force = force
  self.mouse = Vec()
end
function Links.Mouse:update(dt, body)
  self.mouse = Vec(love.mouse.getPosition())
  local dif = self.mouse - body.pos
  body:addForce(self.force*dif)
end
function Links.Mouse:draw(body) end

Links.ArrowKeys = Class:extend()
function Links.ArrowKeys:init(force)
  self.force = force
  self.mouse = Vec()
end
function Links.ArrowKeys:update(dt, body)
  local dir = Vec()
  if love.keyboard.isDown('up') then dir = dir + Vec(0,-1) end
  if love.keyboard.isDown('down') then dir = dir + Vec(0,1) end
  if love.keyboard.isDown('left') then dir = dir + Vec(-1,0) end
  if love.keyboard.isDown('right') then dir = dir + Vec(1,0) end
  dir:normalize()
  body:addForce(self.force*dir)
end
function Links.ArrowKeys:draw(body) end

Links.Spring = Class:extend()
function Links.Spring:init(k, origin, length, pos)
  self.k = k
  self.origin = origin
  self.length = length
  self.pos = pos
end
function Links.Spring:update(dt, body)
  local dif = body:transform(self.pos) - self.origin
  local dist = dif:len()
  if dist == 0 then return end
  local n = dif/dist
  local force = - (dist - self.length) * self.k * n
  body:addLocalForce(force, self.pos)
end
function Links.Spring:draw(body)
  local p1 = self.origin
  local p2 = body:transform(self.pos)
  love.graphics.line(p1.x,p1.y, p2.x,p2.y)
end

Links.Spring2 = Class:extend()
function Links.Spring2:init(k, length, pos1, pos2)
  self.k = k
  self.length = length
  self.pos1 = pos1
  self.pos2 = pos2
end
function Links.Spring2:update(dt, body1, body2)
  local dif = body2:transform(self.pos2) - body1:transform(self.pos1)
  local dist = dif:len()
  if dist == 0 then return end
  local n = dif/dist
  local force = (dist - self.length) * self.k * n
  body1:addLocalForce(force, self.pos1)
  body2:addLocalForce(-force, self.pos2)
end
function Links.Spring2:draw(body1, body2)
  local p1 = body1:transform(self.pos1)
  local p2 = body2:transform(self.pos2)
  love.graphics.line(p1.x,p1.y, p2.x,p2.y)
end

Links.Joint = Class:extend()
function Links.Joint:init(origin, pos)
  self.origin = origin
  self.pos = pos
end
function Links.Joint:update(dt, b)
  local body = {b,nil}
  local delta = b:transform(self.pos) - self.origin
  local point = self.origin
  local penetration = delta:len()
  if penetration < 0 then return end
  local normal = -delta/penetration
  local restitution = 0
  local friction = 1
  b.parent.resolver:addContact(body, point, normal, penetration, restitution, friction)
end
function Links.Joint:draw(body)
  local p1 = self.origin
  local p2 = body:transform(self.pos)
  love.graphics.line(p1.x,p1.y, p2.x,p2.y)
end

Links.Joint2 = Class:extend()
function Links.Joint2:init(pos1, pos2)
  self.pos1 = pos1
  self.pos2 = pos2
end
function Links.Joint2:update(dt, b1, b2)
  local body = {nil,b2}
  local delta = b1:transform(self.pos1) - b2:transform(self.pos2)
  local point = b2:transform(self.pos2)
  local penetration = delta:len()
  if penetration < 0 then return end
  local normal = -delta/penetration
  local restitution = 0
  local friction = 1
  b1.parent.resolver:addContact(body, point, normal, penetration, restitution, friction)
end
function Links.Joint2:draw(body)
  local p1 = self.origin
  local p2 = body:transform(self.pos)
  love.graphics.line(p1.x,p1.y, p2.x,p2.y)
end

Links.StiffSpring = Class:extend()
function Links.StiffSpring:init(k, origin, length, pos)
  self.k = k
  self.origin = origin
  self.length = length
  self.pos = pos
end
function Links.StiffSpring:update(dt, body)
  local pi = body:transform(self.pos) - self.origin
  local vi = body.ori:spin(body.vel)
  local dist = pi:len()
  if dist == 0 then return end
  --local n = dif/dist
  local w = sqrt(self.k*body.massInv)
  local pf = cos(w*dt)*pi + sin(w*dt)*vi/w
  local acc = (pf-pi)/dt^2 - vi/dt
  local force = acc/body.massInv
  table.insert(text, tostring(vi))
  body:addLocalForce(force, self.pos)
end
function Links.StiffSpring:draw(body)
  local p1 = self.origin
  local p2 = body:transform(self.pos)
  love.graphics.line(p1.x,p1.y, p2.x,p2.y)
end

Links.StiffSpring2 = Class:extend()
function Links.StiffSpring2:init(k, length, pos1, pos2)
  self.k = k
  self.length = length
  self.pos1 = pos1
  self.pos2 = pos2
end
function Links.StiffSpring2:update(dt, body1, body2)
  local pi = body1:transform(self.pos1) - body2:transform(self.pos2)
  local vi = body1.ori:spin(body1.vel) - body2.ori:spin(body2.vel)
  local dist = pi:len()
  if dist == 0 then return end
  --local n = dif/dist
  local w = sqrt(self.k*body2.massInv)
  local pf = cos(w*dt)*pi + sin(w*dt)*vi/w
  local acc = (pf-pi)/dt^2 - vi/dt
  local force = acc/body2.massInv
  table.insert(text, tostring(vi))
  body2:addLocalForce(force, self.pos)
end
function Links.StiffSpring2:draw(body)
  local p1 = self.origin
  local p2 = body:transform(self.pos)
  love.graphics.line(p1.x,p1.y, p2.x,p2.y)
end

return Links