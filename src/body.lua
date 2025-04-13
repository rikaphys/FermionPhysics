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

local Class = require 'FermionPhysics.src.class'
local Vec = require 'FermionPhysics.src.vec'
local Node = require 'FermionPhysics.src.node'
local Kinematics = require 'FermionPhysics.src.kinematics'

local Body = Kinematics:extend()

function Body:init(world, kinematics)
  self:setKinematics(kinematics)
  self.nodes = {}
  self.areas = {}
  self.primitives = {}
  
  self.acc = Vec()
  self.accAng = 0
  self.force = Vec()
  self.torque = 0
  self.massInv = 0
  self.inerInv = 0
  
  self.isAwake = true
  self.canSleep = true
  self.motion = 0
  
  self:setDefault(world)
end

function Body:setDefault(world)
  self.gravity = world.gravity
  self.dampLin = world.dampLin
  self.dampAng = world.dampAng
  self.maxVel = world.maxVel
  self.maxRot = world.maxRot
  self.minMotion = world.minMotion
  self.maxMotion = world.maxMotion
  self.resetMotion = world.resetMotion
  self.biasMotion = world.biasMotion
  self.biasIner = world.biasIner
end

function Body:setAwake()
  self.isAwake = true
  self.motion = self.resetMotion
end

function Body:setAsleep()
  self.isAwake = false
  self.vel = Vec()
  self.rot = 0
end

function Body:add(obj)
  local tab
  if obj.density then tab = self.primitives
  elseif obj.shapes then tab = self.areas
  else tab = self.nodes end
  table.insert(tab, obj)
  obj.parent = self
  return obj
end

function Body:calcMassIner()
  local mass = 0
  local iner = 0
  for _,p in ipairs(self.primitives) do
    p:calcIner()
    mass = mass + p.mass
    iner = iner + p.iner/self.parent.biasIner
  end
  self.massInv = self.parent.unit^2/mass
  self.inerInv = self.parent.unit^2/iner
end

function Body:addForce(force, point)
  self.force = self.force + force
  if point then self.torque = self.torque + force:cross(self.pos - point) end
end

function Body:addLocalForce(force, point)
  self:addForce(force, self:transform(point))
end

function Body:update(dt)
  if self.isAwake then self:updateMovement(dt) end
  self:updateKin(dt)
  self:clearForces()
  for _,n in ipairs(self.nodes) do n:update(dt) end
  for _,a in ipairs(self.areas) do a:update(dt) end
  for _,p in ipairs(self.primitives) do p:update(dt) end
end

function Body:updateMovement(dt)
  if self.massInv > 0 then self:updateVel(dt) end
  if self.inerInv > 0 then self:updateRot(dt) end
  self:updateMotion()
end
  
function Body:updateVel(dt)
  self.acc = self.massInv * self.force + self.gravity - self.dampLin * self.vel
  self.vel = self.vel + dt * self.acc
  if self.vel:len2() > self.maxVel^2 then self.vel = self.maxVel*self.vel/self.vel:len()end
end

function Body:updateRot(dt)
  self.accAng = self.inerInv * self.torque - self.dampAng * self.rot
  self.rot = self.rot + dt * self.accAng
  if math.abs(self.rot) > self.maxRot then self.rot = self.maxRot*self.rot/math.abs(self.rot) end
end

function Body:updateMotion()
  local motion = (self.vel:len2()/self.parent.unit^2 + self.rot^2)
  self.motion = self.motion*self.biasMotion + (1 - self.biasMotion)*motion
  if self.motion > self.maxMotion then self.motion = self.maxMotion end
  if self.motion < self.minMotion and self.canSleep then self:setAsleep() end
end

function Body:clearForces()
  self.force = Vec()
  self.torque = 0
end

function Body:draw(prim_mode, area_mode)
  for _,p in ipairs(self.primitives) do p:draw(prim_mode) end
  for _,a in ipairs(self.areas) do a:draw(area_mode) end
  love.graphics.setColor({0,1,0})
  --love.graphics.line(self.pos.x,self.pos.y, self.pos.x+10*self.ori.x,self.pos.y+10*self.ori.y)
  --love.graphics.line(self.pos.x,self.pos.y, self.pos.x+10*self.ori:perpendicular().x,self.pos.y+10*self.ori:perpendicular().y)
  love.graphics.setColor({1,1,1})
end

return Body