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
local Area = Kinematics:extend()

function Area:init(shapes, nodes, kinematics)
  self:setArea(shapes, nodes, kinematics)
end

function Area:setArea(shapes, nodes, kinematics)
  self:setKinematics(kinematics or {})
  self.shapes = shapes
  self.nodes = nodes
  self:calcArea()
end

function Area:calcArea()
  if self.size then
    self.area = self.size.x*self.size.y
    self.areaIner = (self.size.x^2+self.size.y^2)*self.size.x*self.size.y/12
  else
    self.area = 0
    self.areaIner = 0
  end
end

function Area:calcIner()
  if not (self.area and self.areaIner) then self:calcArea() end
  if self.density then
    self.mass = self.density*self.area
    self.iner = self.density*self.areaIner + self.mass*self.pos:len2()
  else
    self.mass = 0
    self.iner = 0
  end
end

function Area:setMaterial(material)
  self.density = material.density or 1
  self.restitution = material.restitution or 0
  self.friction = material.friction or 1
  self.color = material.color or {1,1,1,1}
end

function Area:update(dt)
  self:updateKin(dt)
  for i,s in ipairs(self.shapes) do
    local node = 0
    if self.nodes[i] then node = self.parent:transform(self:transform(self.nodes[i]))
    else node = self.parent:transform(self) end
    s:setRotation(node.ori:angle())
    s:moveTo(node.pos.x,node.pos.y)
  end
end

function Area:draw(mode)
  love.graphics.setColor(self.color or {1,1,1})
  for _,s in ipairs(self.shapes) do s:draw(mode) end
  love.graphics.setColor({1,1,1})
end

function Area:collide(area)
  local collide = false
  for _,s1 in ipairs(self.shapes) do
    for _,s2 in ipairs(area.shapes) do
      if not collide then
        collide = s1:collidesWith(s2)
      end
    end
  end
  return collide
end

local Circle = Area:extend()
function Circle:init(rad, kinematics)
  self:setCircle(rad, kinematics)
end
function Circle:setCircle(rad, kinematics)
  self.rad = rad
  self.size = 2*Vec(rad,rad)
  self:setArea({world.collider:circle(0,0, rad)}, {}, kinematics)
end
function Circle:calcArea()
  self.area = math.pi*self.rad^2
  self.areaIner = math.pi*self.rad^4/2
end
function Circle:draw(mode)
  love.graphics.setColor(self.color or {1,1,1})
  for _,s in ipairs(self.shapes) do s:draw(mode) end
  love.graphics.setColor({1,1,1})
  local c = Vec(self.shapes[1]:center())
  local o = self.parent.ori:spin(self.ori)
  local p = c + self.rad*o
  love.graphics.line(c.x,c.y, p.x,p.y)
  p = c - self.rad*o
  love.graphics.line(c.x,c.y, p.x,p.y)
  p = c + self.rad*o:perpendicular()
  love.graphics.line(c.x,c.y, p.x,p.y)
  p = c - self.rad*o:perpendicular()
  love.graphics.line(c.x,c.y, p.x,p.y)
  love.graphics.setColor({1,1,1})
end

local Rectangle = Area:extend()
function Rectangle:init(size, kinematics)
  self:setRectangle(size, kinematics)
end
function Rectangle:setRectangle(size, kinematics)
  self.size = size
  self.rad = 0
  self:setArea({world.collider:polygon(0,0, size.x,0, size.x,size.y, 0,size.y)}, {}, kinematics)
end

local Stadium = Area:extend()
function Stadium:init(size, kinematics)
  self:setStadium(size, kinematics)
end
function Stadium:setStadium(size, kinematics)
  self.size = size
  self.rad = math.min(size.x,size.y)/2
  local shapes = {world.collider:circle(0,0, size.x/2)}
  local nodes = {}
  if size.x<size.y then
    shapes = {
      world.collider:polygon(0,0, size.x,0, size.x,size.y-size.x, 0,size.y-size.x),
      world.collider:circle(0,0, size.x/2),
      world.collider:circle(0,0, size.x/2)
    }
    nodes = {
      Node(Vec()),
      Node(Vec(0,-(size.y-size.x)/2)),
      Node(Vec(0,(size.y-size.x)/2))
    }
  elseif size.x>size.y then
    shapes = {
      world.collider:polygon(0,0, size.x-size.y,0, size.x-size.y,size.y, 0,size.y),
      world.collider:circle(0,0, size.y/2),
      world.collider:circle(0,0, size.y/2)
    }
    nodes = {
      Node(Vec()),
      Node(Vec(-(size.y-size.x)/2,0)),
      Node(Vec((size.y-size.x)/2,0))
    }
  end
  self:setArea(shapes, nodes, kinematics)
end

local RoundRect = Area:extend()
function RoundRect:init(size, kinematics)
  self:setRoundRect(size, kinematics)
end
function RoundRect:setRoundRect(size, rad, kinematics)
  self.size = size
  self.rad = rad
  local shapes = {
    world.collider:polygon(0,0, size.x-2*rad,0, size.x-2*rad,size.y, 0,size.y),
    world.collider:polygon(0,0, size.x,0, size.x,size.y-2*rad, 0,size.y-2*rad),
    world.collider:circle(0,0, rad),
    world.collider:circle(0,0, rad),
    world.collider:circle(0,0, rad),
    world.collider:circle(0,0, rad)
  }
  local nodes = {
    Node(Vec()),
    Node(Vec()),
    Node(Vec((size.x/2-rad),(size.y/2-rad))),
    Node(Vec((size.x/2-rad),-(size.y/2-rad))),
    Node(Vec(-(size.x/2-rad),(size.y/2-rad))),
    Node(Vec(-(size.x/2-rad),-(size.y/2-rad)))
  }
  self:setArea(shapes, nodes, kinematics)
end

local Polygon = Area:extend()
function Polygon:init(vertex, kinematics)
  self:setPolygon(vertex, kinematics)
end
function Polygon:setPolygon(vertex, kinematics)
  self.vertex = vertex
  local min_x,min_y,max_x,max_y = vertex[1].x,vertex[1].y,vertex[1].x,vertex[1].y
  for _,v in ipairs(vertex) do
    min_x = math.min(min_x,v.x)
    min_y = math.min(min_y,v.y)
    max_x = math.max(max_x,v.x)
    max_y = math.max(max_y,v.y)
  end
  self.size = Vec(max_x-min_x,max_y-min_y)
  self.rad = 0
  local data = {}
  for _,v in ipairs(vertex) do
    table.insert(data, v.x)
    table.insert(data, v.y)
  end
  self:setArea({world.collider:polygon(unpack(data))}, {}, kinematics)
end

return {Area, Circle, Rectangle, Stadium, RoundRect, Polygon}