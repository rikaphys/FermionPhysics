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

local Class = {}
Class.__index = Class

function Class:init() end

function Class:__call(...)
  local class = setmetatable({}, self)
  class:init(...)
  return class
end

function Class:__tostring() return 'Class' end

function Class.__concat(a,b) return tostring(a)..tostring(b) end

function Class:is(T)
  local mt = getmetatable(self)
  while mt do
    if mt == T then return true end
    mt = getmetatable(mt)
  end
  return false
end

function Class:set(data)
  for k, v in pairs(data) do
    self[k] = v
  end
end

function Class:extend()
  local class = {}
  for k, v in pairs(self) do
    if k:find("__") == 1 then
      class[k] = v
    end
  end
  class.__index = class
  class.super = self
  setmetatable(class, self)
  return class
end

return Class