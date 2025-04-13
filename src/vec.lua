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
local Vec = Class:extend()
local sqrt, cos, sin, atan2 = math.sqrt, math.cos, math.sin, math.atan2
local function isvector(v)
	return type(v) == 'table' and type(v.x) == 'number' and type(v.y) == 'number'
end

function Vec:init(x,y)
  self.x = x or 0
  self.y = y or self.x
end

function Vec:__tostring() return "("..self.x..","..self.y..")" end
function Vec.__eq(a,b) return a.x==b.x and a.y==b.y end
function Vec.__lt(a,b) return a:len2() < b:len2() end
function Vec.__le(a,b) return a:len2() <= b:len2() end
function Vec:__unm() return Vec(-self.x,-self.y) end
function Vec:len() return sqrt(self:len2()) end
function Vec:len2() return self*self end

function Vec.__add(a,b)
  assert(isvector(a) and isvector(b), "Vec.__add: Wrong argument, <vector> expected.")
  return Vec(a.x+b.x,a.y+b.y)
end
function Vec.__sub(a,b)
  assert(isvector(a) and isvector(b), "Vec.__sub: Wrong argument, <vector> expected.")
  return Vec(a.x-b.x,a.y-b.y)
end
function Vec.__mul(a,b)
  if type(a)=='number' then return Vec(a*b.x,a*b.y) end
  if type(b)=='number' then return Vec(a.x*b,a.y*b) end
  assert(isvector(a) and isvector(b), "Vec.__mul: Wrong argument, <vector> or <number> expected.")
  return a.x*b.x + a.y*b.y
end
function Vec.__div(a,b)
  assert(isvector(a) and type(b)=='number', "Vec.__div: Wrong argument, <vector> / <number> expected.")
  return Vec(a.x/b,a.y/b)
end

function Vec:normalize()
  local len = self:len()
  if len~=0 then self = self/len end
  return self
end
function Vec:perpendicular()
  return Vec(-self.y,self.x)
end
function Vec:angle(v)
  if v then
    assert(isvector(v), "Vec:angle(): Wrong argument, <vector> expected.")
    return atan2(self.y, self.x) - atan2(v.y, v.x)
  end
	return atan2(self.y, self.x)
end
function Vec:cross(v)
  assert(isvector(v), "Vec:cross(): Wrong argument, <vector> expected.")
  return self.x*v.y-self.y*v.x
end
function Vec:spin(v)
  assert(isvector(v), "Vec:spin(): Wrong argument, <vector> expected.")
  return Vec(self.x*v.x-self.y*v.y,self.x*v.y+self.y*v.x)
end
function Vec:spinInv(v)
  assert(isvector(v), "Vec:spin(): Wrong argument, <vector> expected.")
  return Vec(self.x*v.x+self.y*v.y,self.x*v.y-self.y*v.x)
end
function Vec:rotate(phi)
  local c, s = cos(phi), sin(phi)
	self.x, self.y = c * self.x - s * self.y, s * self.x + c * self.y
	return self
end

return Vec