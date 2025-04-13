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
local Area, Circle, Rectangle, Stadium, RoundRect, Polygon = unpack(require('FermionPhysics.src.area'))
local Primitive = Area:extend()

function Primitive:init(shapes, nodes, material, kinematics)
  self:setArea(shapes, nodes, kinematics)
  self:setMaterial(material)
  self:calcIner()
end

local Ball = Circle:extend()
function Ball:init(rad, material, kinematics)
  self:setCircle(rad, kinematics)
  self:setMaterial(material)
  self:calcIner()
end

local Box = Rectangle:extend()
function Box:init(size, material, kinematics)
  self:setRectangle(size, kinematics)
  self:setMaterial(material)
  self:calcIner()
end

local PolyBox = Polygon:extend()
function PolyBox:init(vertex, material, kinematics)
  self:setPolygon(vertex, kinematics)
  self:setMaterial(material)
  self:calcIner()
end

local Capsule = Stadium:extend()
function Capsule:init(size, material, kinematics)
  self:setStadium(size, kinematics)
  self:setMaterial(material)
  self:calcIner()
end

local RoundBox = RoundRect:extend()
function RoundBox:init(size, rad, material, kinematics)
  self:setRoundRect(size, rad, kinematics)
  self:setMaterial(material)
  self:calcIner()
end

return {Primitive, Ball, Box, Capsule, RoundBox, PolyBox}