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

local Contact = Class:extend()

function Contact:init(body, point, normal, penetration, restitution, friction)
  self.body = body
  self.point = point
  self.normal = normal
  self.penetration = penetration
  self.restitution = restitution
  self.friction = friction
  self:updateRelPos()
  self:updateRelVel()
end

function Contact:matchAwake()
  if not (self.body[1] and self.body[2]) then return end
  if self.body[1].isAwake and not self.body[2].isAwake then self.body[2]:setAwake() end
  if self.body[2].isAwake and not self.body[1].isAwake then self.body[1]:setAwake() end
end

function Contact:updateRelPos()
  self.relPos = {Vec(),Vec()}
  for i=1,2 do if self.body[i] then self.relPos[i] = self.point - self.body[i].pos end end
end

function Contact:updateRelVel()
  self.relVel = {Vec(),Vec()}
  self.velocity = 0
  for i=1,2 do if self.body[i] then
    self.relVel[i] = self.body[i].vel + self.body[i].rot*self.relPos[i]:perpendicular()
    self.velocity = self.velocity + ((i==1) and -1 or 1 )*self.relVel[i]*self.normal
  end end
end

function Contact:updatePos(dt, maxAng)
  -- calculate inetias
  local inerLin = {0,0}
  local inerAng = {0,0}
  for i=1,2 do if self.body[i] then
    inerLin[i] = self.body[i].massInv
    inerAng[i] = self.body[i].inerInv*self.relPos[i]:cross(self.normal)*self.relPos[i]:perpendicular()*self.normal
  end end
  local inerTotal = inerLin[1] + inerLin[2] + inerAng[1] + inerAng[2]
  
  -- calculate movements
  local moveLin = {0,0}
  local moveAng = {0,0}
  for i=1,2 do if self.body[i] then
    moveLin[i] = ((i==1) and 1 or -1 )*self.penetration*inerLin[i]/inerTotal
    moveAng[i] = ((i==1) and 1 or -1 )*self.penetration*inerAng[i]/inerTotal
  end end
  
  -- correct large angular movement
  for i=1,2 do if self.body[i] then
    local limit = maxAng*self.relPos[i]:len()
    if math.abs(moveAng[i])>limit then
      local moveTot = moveLin[i] + moveAng[i]
      if moveAng[i] > 0 then moveAng[i] = limit else moveAng[i] = -limit end
      moveLin[i] = moveTot - moveAng[i]
    end
  end end
  
  -- calculate corrections
  local impulse = {}
  self.delPos = {Vec(),Vec()}
  self.delAng = {0,0}
  for i=1,2 do if self.body[i] then
    self.delPos[i] = moveLin[i]*self.normal
    impulse[i] = self.body[i].inerInv*self.relPos[i]:cross(self.normal)
    self.delAng[i] = moveAng[i] * impulse[i] / inerAng[i] 
  end end
  
  -- apply corrections
  for i=1,2 do if self.body[i] then
    if inerLin[i] > 0 then self.body[i].pos = self.body[i].pos + self.delPos[i] end
    if inerAng[i] > 0 then self.body[i].ori:rotate(self.delAng[i]) end
    for _,n in ipairs(self.body[i].nodes) do n:update(0) end
    for _,a in ipairs(self.body[i].areas) do a:update(0) end
    for _,p in ipairs(self.body[i].primitives) do p:update(0) end
  end end
end

function Contact:updateVel(dt, minVel)
  -- calculate velocity variation
  local accVel = 0
  for i=1,2 do if self.body[i] then
    accVel = accVel + ((i==1) and 1 or -1)*self.body[i].acc*self.normal*dt
  end end
  local restitution = self.restitution
  if self.velocity < minVel then restitution = restitution*self.velocity/minVel end
  local delVel = - self.velocity - restitution*(self.velocity - accVel)
  
  -- calculate perpendicular velocity variation
  local normalPerp = self.normal:perpendicular()
  local velPerp = 0
  for i=1,2 do if self.body[i] then
    velPerp = velPerp + ((i==1) and -1 or 1)*self.relVel[i]*normalPerp
  end end
  if velPerp < 0 then
    normalPerp = -normalPerp
    velPerp = -velPerp
  end
  local delVelPerp = -velPerp
  
  -- calculate nescessary impulses
  local velPerImp = 0
  for i=1,2 do if self.body[i] then
    local torque = self.relPos[i]:cross(self.normal)
    local rotation = torque*self.body[i].inerInv
    velPerImp = velPerImp + rotation*self.relPos[i]:perpendicular()*self.normal + self.body[i].massInv
  end end
  local velPerImpPerp = 0
  for i=1,2 do if self.body[i] then
    local torque = self.relPos[i]:cross(normalPerp)
    local rotation = torque*self.body[i].inerInv
    velPerImpPerp = velPerImpPerp + rotation*self.relPos[i]:perpendicular()*normalPerp + self.body[i].massInv
  end end
  local impulseNorm = delVel/velPerImp
  local impulsePerp = delVelPerp/velPerImpPerp
  
  -- check for dynamic friction
  if impulsePerp < self.friction*impulseNorm then
    impulsePerp = self.friction*impulseNorm
  end
  
  -- calculate final impulse
  local impulse = impulseNorm*self.normal + impulsePerp*normalPerp
  
  -- apply corrections
  for i=1,2 do if self.body[i] then
    if self.body[i].massInv > 0 then self.body[i].vel = self.body[i].vel + ((i==1) and -1 or 1)*impulse*self.body[i].massInv end
    if self.body[i].inerInv > 0 then self.body[i].rot = self.body[i].rot + ((i==1) and 1 or -1)*impulse:cross(self.relPos[i])*self.body[i].inerInv end
  end end
end

return Contact