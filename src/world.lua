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
local Node = require 'FermionPhysics.src.node'
local Kinematics = require 'FermionPhysics.src.kinematics'
local Resolver = require 'FermionPhysics.src.resolver'
local Collider = require 'FermionPhysics.HC'
local Registry = require 'FermionPhysics.src.registry'
local Body = require 'FermionPhysics.src.body'
local Area, Circle, Rectangle, Stadium, RoundRect, Polygon = unpack(require('FermionPhysics.src.area'))
local Primitive, Ball, Box, Capsule, RoundBox, PolyBox = unpack(require('FermionPhysics.src.primitive'))

local sqrt, cos, sin, atan2 = math.sqrt, math.cos, math.sin, math.atan2

local World = Kinematics:extend()

function World:init(unit, cellSize, iPos, iVel)
  self:setKinematics({})
  self.time = 0
  self.unit = unit or 120
  self.nodes = {}
  self.areas = {}
  self.primitives = {}
  self.bodies = {}
  self.forces = Registry()
  self.joints = Registry()
  self.collider = Collider(cellSize or self.unit)
  self.resolver = Resolver(iPos, iVel)
  self.resolver.world = self
  self:setDefault()
end

function World:setDefault()
  self.minFPS = 29
  self.iter = 1
  
  self.minMotion = 0.1
  self.maxMotion = 10
  self.resetMotion = 1
  self.biasMotion = 0.9
  self.biasIner = 1
  
  self.dampLin = 1
  self.dampAng = 1
  self.maxVel = 20*self.unit
  self.maxRot = 10
  self.gravity = Vec(0,10)*self.unit
  
  self.maxAng = 0.5/self.unit
  self.minVel = self.unit
  
  self.material = {
    friction = 1,
    restitution = 0,
    density = 1,
    color = {0.5,0.5,0.5,1}
  }
end

function World:add(obj,...)
  local arg = {...}
  local tab
  if obj.acc then tab = self.bodies
  elseif obj.density then tab = self.primitives
  elseif obj.shapes then tab = self.areas
  else tab = self.nodes end
  table.insert(tab, obj)
  obj.parent = self
  if obj.acc then
    for _,n in ipairs(arg) do
      obj:add(n)
    end
    obj:calcMassIner()
  end
  return obj
end

function World:addArea(size, rad, kinematics)
  local kin = Kinematics(kinematics.pos, kinematics.ori, kinematics.vel, kinematics.rot)
  kin:scale(self.unit)
  if rad==0 then return self:add(Rectangle(size*self.unit, kin)) end
  if size.x==size.y and size.x==2*rad then return self:add(Circle(rad*self.unit, kin)) end
  if size.x==2*rad or size.y==2*rad then return self:add(Stadium(size*self.unit, kin)) end
  return self:add(RoundRect(size*self.unit, rad*self.unit, kin))
end

function World:addPrim(size, rad, kinematics)
  local kin = Kinematics(kinematics.pos, kinematics.ori, kinematics.vel, kinematics.rot)
  kin:scale(self.unit)
  if rad==0 then return self:add(Box(size*self.unit, self.material, kin)) end
  if size.x==size.y and size.x==2*rad then return self:add(Ball(rad*self.unit, self.material, kin)) end
  if size.x==2*rad or size.y==2*rad then return self:add(Capsule(size*self.unit, self.material, kin)) end
  return self:add(RoundBox(size*self.unit, rad*self.unit, self.material, kin))
end

function World:addBody(size, rad, kinematics)
  local kin = Kinematics(kinematics.pos, kinematics.ori, kinematics.vel, kinematics.rot)
  kin:scale(self.unit)
  if rad==0 then return self:add(Body(self, kin), Box(size*self.unit, self.material)) end
  if size.x==size.y and size.x==2*rad then return self:add(Body(self, kin), Ball(rad*self.unit, self.material)) end
  if size.x==2*rad or size.y==2*rad then return self:add(Body(self, kin), Capsule(size*self.unit, self.material)) end
  return self:add(Body(self, kin), RoundBox(size*self.unit, rad*self.unit, self.material))
end

function World:addPolyArea(vertex, kinematics)
  local kin = Kinematics(kinematics.pos, kinematics.ori, kinematics.vel, kinematics.rot)
  kin:scale(self.unit)
  local ver = {}
  for i,v in ipairs(vertex) do
    ver[i] = v*self.unit
  end
  return self:add(Polygon(ver, kin))
end

function World:addPolyPrim(vertex, kinematics)
  local kin = Kinematics(kinematics.pos, kinematics.ori, kinematics.vel, kinematics.rot)
  kin:scale(self.unit)
  local ver = {}
  for i,v in ipairs(vertex) do
    ver[i] = v*self.unit
  end
  return self:add(PolyBox(ver, self.material, kin))
end

function World:addPolyBody(vertex, kinematics)
  local kin = Kinematics(kinematics.pos, kinematics.ori, kinematics.vel, kinematics.rot)
  kin:scale(self.unit)
  local ver = {}
  for i,v in ipairs(vertex) do
    ver[i] = v*self.unit
  end
  return self:add(Body(self, kin), PolyBox(ver, self.material, {}))
end


function World:update(dt)
  assert(dt > 0)
  if dt > 1/self.minFPS then return end
  local DT = dt/self.iter
  for i=1,self.iter do
    self:addForces(DT)
    self:updateForces(DT)
    self:updateKin(DT)
    self:updateChildren(DT)
    self:updateJoints(DT)
    self:checkCollisions(DT)
    self:resolveCollisions(DT)
    self:updateTime(DT)
  end
end

function World:addForces(dt) end

function World:updateForces(dt) self.forces:update(dt) end

function World:updateChildren(dt)
  for _,n in ipairs(self.nodes) do n:update(dt) end
  for _,a in ipairs(self.areas) do a:update(dt) end
  for _,p in ipairs(self.primitives) do p:update(dt) end
  for _,b in ipairs(self.bodies) do b:update(dt) end
end

function World:updateJoints(dt) self.joints:update(dt) end

function World:checkCollisions(dt)
  for _,b1 in ipairs(self.bodies) do
    for _,p1 in ipairs(b1.primitives) do
      for _,p2 in ipairs(self.primitives) do
        for _,s1 in ipairs(p1.shapes) do
          for _,s2 in ipairs(p2.shapes) do
            local collide, dx,dy, px,py = s1:collidesWith(s2)
            if collide then
              self.resolver:addContact({b1,nil}, Vec(px,py), Vec(dx,dy), math.max(p1.restitution, p2.restitution), math.min(p1.friction, p2.friction))
            end
          end
        end
      end
    end
    for _,b2 in ipairs(self.bodies) do
      if b1 ~= b2 then
        for _,p1 in ipairs(b1.primitives) do
          for _,p2 in ipairs(b2.primitives) do
            for _,s1 in ipairs(p1.shapes) do
              for _,s2 in ipairs(p2.shapes) do
                local collide, dx,dy, px,py = s1:collidesWith(s2)
                if collide then
                  self.resolver:addContact({b1,b2}, Vec(px,py), Vec(dx,dy), math.max(p1.restitution, p2.restitution), math.min(p1.friction, p2.friction))
                end
              end
            end
          end
        end
      end
    end
  end
end

function World:resolveCollisions(dt) self.resolver:update(dt) end

function World:updateTime(dt) self.time = self.time + dt end

function World:draw()
  for _,p in ipairs(self.primitives) do p:draw('fill') end
  for _,b in ipairs(self.bodies) do b:draw('fill', 'line') end
  for _,a in ipairs(self.areas) do a:draw('line') end
  for _,n in ipairs(self.nodes) do n:draw() end
  self.forces:draw()
end

return World