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

local FP = {}

FP.color = {
	black = {0,0,0},
  dim = {0.25,0.25,0.25},
  gray = {0.5,0.5,0.5},
  silver = {0.75,0.75,0.75},
  white = {1,1,1},
  red = {1,0,0},
  vermilion = {1,0.25,0},
	orange = {1,0.5,0},
  amber = {1,0.75,0},
	yellow = {1,1,0},
  lime = {0.75,1,0},
	chartreuse = {0.5,1,0},
  harlequin = {0.25,1,0},
	green = {0,1,0},
  erin = {0,1,0.25},
	spring = {0,1,0.5},
  aquamarine = {0,1,0.75},
	cyan = {0,1,1},
  sky = {0,0.75,1},
	azure = {0,0.5,1},
  cerulean = {0,0.25,1},
	blue = {0,0,1},
  indigo = {0.25,0,1},
	violet = {0.5,0,1},
  purple = {0.75,0,1},
	magenta = {1,0,1},
  cerise = {1,0,0.75},
	rose = {1,0,0.5},
  crimson = {1,0,0.25}
}

function FP:Material(density,restitution,friction,color)
	return {
    density = density or 1,
    restitution = restitution or 0.9,
    friction = friction or 0.9,
    color = color or {1,1,1}
  }
end
FP.material = {
	stone = FP:Material(2.5,0.4,0.8,FP.gray),
	metal = FP:Material(3,0.4,0.3,FP.silver),
	glass = FP:Material(2.5,0.7,0.2,FP.cyan),
	wood = FP:Material(0.5,0.5,0.6,FP.amber),
	flesh = FP:Material(1,0.3,0.9,FP.rose),
	plastic = FP:Material(1,0.7,0.4,FP.violet),
	rubber = FP:Material(1.5,0.9,0.9,FP.magenta)
}

FP.Collider = require 'FermionPhysics.HC'
FP.Vec = require 'FermionPhysics.src.vec'
FP.Class = require 'FermionPhysics.src.class'
FP.Registry = require 'FermionPhysics.src.registry'
FP.Node = require 'FermionPhysics.src.node'
FP.Body = require 'FermionPhysics.src.body'
FP.Links = require 'FermionPhysics.src.links'
FP.World = require 'FermionPhysics.src.world'
FP.Area, FP.Circle, FP.Rectangle, FP.Stadium, FP.RoundBox, FP.Polygon = unpack(require('FermionPhysics.src.area'))
FP.Primitive, FP.Ball, FP.Box, FP.Capsule, FP.RoundRect, FP.PolyBox = unpack(require('FermionPhysics.src.primitive'))

return FP