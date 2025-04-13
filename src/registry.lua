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

local Registry = Class:extend()

function Registry:init()
  self.links = {}
end

function Registry:add(link, act1, act2)
  table.insert(self.links,{link = link, act1 = act1, act2 = act2})
end

function Registry:remove(link, act1, act2)
  for i,v in ipairs(self.links) do
    if v.link==link and v.act1==act1 and v.act2==act2 then
      table.remove(self.links,i)
    end
  end
end

function Registry:update(dt)
  for _,v in pairs(self.links) do
    v.link:update(dt, v.act1, v.act2)
  end
end

function Registry:draw()
  for _,v in pairs(self.links) do
    v.link:draw(v.act1, v.act2)
  end
end

return Registry
