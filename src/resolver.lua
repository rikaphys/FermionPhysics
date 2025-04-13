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
local Contact = require 'FermionPhysics.src.contact'

local Resolver = Class:extend()

function Resolver:init(iPos, iVel)
  self.iPos = iPos or 100
  self.iVel = iVel or self.iPos
  self.contacts = {}
end

function Resolver:addContact(body, point, delta, restitution, friction)
  local penetration = delta:len()
  local normal = delta/penetration
  table.insert(self.contacts, Contact(body, point, normal, penetration, restitution, friction))
end

function Resolver:update(dt)
  if #self.contacts==0 then return end
  self:updatePos(dt)
  self:updateVel(dt)
  self.contacts = {}
end

function Resolver:updatePos(dt)
  for i=1,self.iPos do
    local penetration = 0
    local contact = nil
    for _,c in ipairs(self.contacts) do
      if c.penetration>penetration then
        penetration = c.penetration
        contact = c
      end
    end
    if not contact then return end
    contact:matchAwake()
    contact:updatePos(dt, self.world.maxAng)
    for _,c in ipairs(self.contacts) do
      for j=1,2 do
        for k=1,2 do
          if contact.body[j]==c.body[k] then
            c:updateRelPos()
            local delPos = contact.delPos[j] + contact.delAng[j]*c.relPos[k]:perpendicular()
            if k==1 then delPos = -delPos end
            c.penetration = c.penetration + delPos*c.normal
          end
        end
      end
    end
  end
end

function Resolver:updateVel(dt)
  for i=1,self.iVel do
    local velocity = 0
    local contact = nil
    for j,c in ipairs(self.contacts) do
      if c.velocity > velocity then
        velocity = c.velocity
        contact = c
      end
    end
    if not contact then return end
    contact:matchAwake()
    contact:updateVel(dt, self.world.minVel)
    for _,c in ipairs(self.contacts) do
      for j=1,2 do
        for k=1,2 do
          if contact.body[j]==c.body[k] then
            c:updateRelVel()
          end
        end
      end
    end
  end
end

return Resolver