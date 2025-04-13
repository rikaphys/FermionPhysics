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
local Node = Class:extend()

function Node:init(pos, ori)
  self:setNode({pos = pos, ori = ori})
end

function Node:setNode(node)
  self.pos = node.pos or Vec()
  self.ori = node.ori or Vec(1,0)
end

function Node:transform(obj)
  if obj.x then return self.ori:spin(obj) + self.pos end
  if obj.pos then return Node(self:transform(obj.pos), self.ori:spin(obj.ori)) end
end

function Node:scale(unit)
  self.pos = unit*self.pos
end

function Node:update() end

function Node:draw()
  love.graphics.line(self.pos.x,self.pos.y, self.pos.x+10,self.pos.y)
end

return Node