-- This software is provided 'as-is', without any express or implied warranty. In no event will the authors be held liable for any damages arising from the use of this software.
-- Permission is granted to anyone to use this software for any purpose, including commercial applications, and to alter it and redistribute it freely, subject to the following restrictions:
-- 1. The origin of this software must not be misrepresented; you must not claim that you wrote the original software. If you use this software in a product, an acknowledgment in the product documentation would be appreciated but is not required.
-- 2. Altered source versions must be plainly marked as such, and must not be misrepresented as being the original software.
-- 3. This notice may not be removed or altered from any source distribution.

-- Copyright (c) 2014 Florian Fischer (richtext integration)

local rich = require("lib/richtext")
local Gspot = {}

Gspot.style = {
	unit = 16,
	font = love.graphics.newFont(10),
	imagemode = 'alpha',
	fg = {255, 255, 255, 255},
	bg = {64, 64, 64, 255},
	default = {60, 60, 60, 255}, --{96, 96, 96, 255},
	hilite = {90, 90, 96, 255}, --{128, 128, 128, 255},
	focus = {128, 128, 128, 255}, --{160, 160, 160, 255},
}

Gspot.load = function(this)
	local def = {
		style = {
			unit = this.style.unit,
			font = this.style.font,
			imagemode = this.style.imagemode,
			fg = this.style.fg,
			bg = this.style.bg,
			default = this.style.default,
			hilite = this.style.hilite,
			focus = this.style.focus,
		},
		dblclickinterval = 0.25,
		-- no messin' past here
		maxid = 0, -- legacy
		mem = {},
		elements = {},
		mousein = nil,
		focus = nil,
		drag = nil,
		mousedt = 0,
		orepeat = {},
	}
	return setmetatable(def, {__index = this, __call = this.load})
end

Gspot.update = function(this, dt)
	this.mousedt = this.mousedt + dt
	local mouse = {}
	mouse.x, mouse.y = this:getmouse()
	local mousein = this.mousein
	this.mousein = false
	this.mouseover = false
	if this.drag then
		local element = this.drag
		if love.mouse.isDown('l') then
			if type(element.drag) == 'function' then element:drag(mouse.x, mouse.y)
			else
				element.pos.y = mouse.y - element.offset.y
				element.pos.x = mouse.x - element.offset.x
			end
		-- new:code
		--elseif love.mouse.isDown('r') then
		--	if type(element.rdrag) == 'function' then element:rdrag(mouse.x, mouse.y)
		--	else
		--		element.pos.y = mouse.y - element.offset.y
		--		element.pos.x = mouse.x - element.offset.x
		--	end
		-- new:end
		end
		for i, bucket in ipairs(this.elements) do
			if bucket.display ~= false then			-- flo: added to avoid that invisible (hided) elements can receive mouse events
				if bucket ~= element and bucket:containspoint(mouse) then
					--print(bucket.label, bucket.display)
					this.mouseover = bucket end
			end
		end
	end
	for i, element in ipairs(this.elements) do
		--if element.display then			-- flo: old code position, this does not allow updating invisible widgets
			if element.update then
				if element.updateinterval then
					element.dt = element.dt + dt
					if element.dt >= element.updateinterval then
						element.dt = 0
						element:update(dt)
					end
				else element:update(dt) end
			end
		if element.display then			-- flo: new code position, we also want to update invisible itemwidgets
			if element:containspoint(mouse) then
				if element.parent and element.parent:type() == 'Gspot.element.scrollgroup' and element ~= element.parent.scrollv and element ~= element.parent.scrollh then
					if element.parent:containspoint(mouse) then this.mousein = element end
				else this.mousein = element end
			end
		end
	end
	if this.mousein ~= mousein then
		if this.mousein and this.mousein.enter then this.mousein:enter() end
		if mousein and mousein.leave then mousein:leave() end
	end
end

Gspot.draw = function(this)
	local ostyle = {}
	--ostyle.colormode = love.graphics.getColorMode()
	ostyle.colormode = love.graphics.getBlendMode()
	ostyle.font = love.graphics.getFont()
	ostyle.r, ostyle.g, ostyle.b, ostyle.a = love.graphics.getColor()
	ostyle.scissor = {}
	ostyle.scissor.x, ostyle.scissor.y, ostyle.scissor.w, ostyle.scissor.h = love.graphics.getScissor()
	love.graphics.setBlendMode('alpha')
	for i, element in ipairs(this.elements) do
		if element.display then
			local pos, scissor = element:getpos()
			--if scissor and _globalScale_ then	-- SiENcE: new
			--	love.graphics.setScissor(scissor.x*_globalScale_.x, scissor.y*_globalScale_.y, scissor.w*_globalScale_.x, scissor.h*_globalScale_.y)	-- SiENcE: new
			--else
			if scissor then	-- SiENcE: new
				love.graphics.setScissor(scissor.x, scissor.y, scissor.w, scissor.h)
			end	-- SiENcE: new
			love.graphics.setFont(element.style.font)
			element:draw(pos)
			if ostyle.scissor.x then love.graphics.setScissor(ostyle.scissor.x, ostyle.scissor.y, ostyle.scissor.w, ostyle.scissor.h)
			else love.graphics.setScissor() end
		end
	end
	if this.mousein and this.mousein.tip then
		local element = this.mousein
		local pos = element:getpos()
		local tippos = {x = pos.x + (this.style.unit / 2), y = pos.y + (this.style.unit / 2), w = element.style.font:getWidth(element.tip) + this.style.unit, h = this.style.unit}
		love.graphics.setColor(this.style.bg)
		this.mousein:rect({x = math.max(0, math.min(tippos.x, love.graphics.getWidth() - (element.style.font:getWidth(element.tip) + this.style.unit))), y = math.max(0, math.min(tippos.y, love.graphics.getHeight() - this.style.unit)), w = tippos.w, h = tippos.h})
		--love.graphics.setColor(this.style.fg)		-- old
		love.graphics.setColor(element.style.focus)	-- SiENcE: new
		love.graphics.setFont(element.style.font)	-- SiENcE: new
		love.graphics.print(element.tip, math.max(this.style.unit / 2, math.min(tippos.x + (this.style.unit / 2), love.graphics.getWidth() - (element.style.font:getWidth(element.tip) + (this.style.unit / 2)))), math.max((this.style.unit - element.style.font:getHeight(element.tip)) / 2, math.min(tippos.y + ((this.style.unit - element.style.font:getHeight('dp')) / 2), (love.graphics.getHeight() - this.style.unit) + ((this.style.unit - element.style.font:getHeight('dp')) / 2))))
	end
	love.graphics.setFont(ostyle.font)
	love.graphics.setColor(ostyle.r, ostyle.g, ostyle.b, ostyle.a)
	love.graphics.setBlendMode(ostyle.colormode)
	if ostyle.scissor.x then love.graphics.setScissor(ostyle.scissor.x, ostyle.scissor.y, ostyle.scissor.w, ostyle.scissor.h)
	else love.graphics.setScissor() end
end

Gspot.mousepress = function(this, x, y, button)
	this:unfocus()
	if this.mousein then
		local element = this.mousein
		if element.elementtype ~= 'hidden' then element:getparent():setlevel() end
    -- drag only possible with left - drag
		if button == 'l' then
			if element.drag then
				this.drag = element
				element.offset = {x = x - element:getpos().x, y = y - element:getpos().y}
			end
			if this.mousedt < this.dblclickinterval and element.dblclick then
				element:dblclick(x, y, button)
			elseif element.click then
				element:click(x, y)
			end
		elseif button == 'r' and element.rclick then element:rclick(x, y)
		elseif button == 'wu' and element.wheelup then element:wheelup(x, y)
		elseif button == 'wd' and element.wheeldown then element:wheeldown(x, y)
		end
	end
	this.mousedt = 0
end

Gspot.mouserelease = function(this, x, y, button)
	-- old:code
	--[[
	if this.drag then
		local element = this.drag
		if button == 'r' then
			if element.rdrop then element:rdrop(this.mouseover) end
			if this.mouseover and this.mouseover.rcatch then this.mouseover:rcatch(element.id) end
		else
			if element.drop then element:drop(this.mouseover) end
			if this.mouseover and this.mouseover.catch then this.mouseover:catch(element) end
		end
	end
	this.drag = nil
	]]--
	-- new:code
	if this.drag then
		local element = this.drag
		if button == 'l' then
			local skipdrop = false
			if this.mouseover and this.mouseover.catch then skipdrop = this.mouseover:catch(element) end
			if not skipdrop then
				if element.drop then element:drop(this.mouseover) end
			end
			this.drag = nil
		end
	elseif this.mousein then
		local element = this.mousein
		if button == 'l' then
			if element.release then element:release(x, y)	end
		elseif button == 'r' then
			if element.rrelease then element:rrelease(x, y) end
		end
	end
	-- new:end
end

Gspot.keypress = function(this, key, code)
	if this.focus then
		if (key == 'return' or key == 'kpenter') and this.focus.done then this.focus:done() end
		if this.focus and this.focus.keypress then this.focus:keypress(key, code) end
	end
end

Gspot.getmouse = function(this)
	return love.mouse.getPosition()
end

-- legacy
Gspot.newid = function(this)
	this.maxid = this.maxid + 1
	return this.maxid
end
-- /legacy

Gspot.clone = function(this, t)
	local c = {}
	for i, v in pairs(t) do
		if v then
			if type(v) == 'table' then c[i] = this:clone(v) else c[i] = v end
		end
	end
	return setmetatable(c, getmetatable(t))
end

Gspot.getindex = function(tab, val)
	for i, v in pairs(tab) do if v == val then return i end end
end

Gspot.add = function(this, element)
	element.id = this:newid() -- legacy
	table.insert(this.elements, element)
	if element.parent then element.parent:addchild(element) end
	return element
end

Gspot.rem = function(this, element)
	if element.parent then element.parent:remchild(element) end
	while #element.children > 0 do
		for i, child in ipairs(element.children) do this:rem(child) end
	end
	if element == this.mousein then this.mousein = nil end
	if element == this.drag then this.drag = nil end
	if element == this.focus then this:unfocus() end
	return table.remove(this.elements, this.getindex(this.elements, element))
end

Gspot.setfocus = function(this, element)
	if element then
		this.focus = element
		--if element.keyrepeat and element.keyrepeat > 0 then
		--	this.orepeat.delay, this.orepeat.interval = love.keyboard.hasKeyRepeat()
		--	if element.keydelay then love.keyboard.setKeyRepeat(element.keydelay, element.keyrepeat)
		--	else love.keyboard.setKeyRepeat(element.keyrepeat, element.keyrepeat) end
		--end
	end
end

Gspot.unfocus = function(this)
	this.focus = nil
	--if this.orepeat then love.keyboard.setKeyRepeat(this.orepeat.delay, this.orepeat.interval) end
end

local pos = {
	load = function(this, Gspot, t)
		assert(type(t) == 'table' or not t, 'invalid pos constructor argument : must be of type table or nil')
		t = t or {}
		t = t.pos or t
		local circ = false
		local pos = {}
		if t.r or t[5] or (#t == 3 and not t.w) then
			pos.r = t.r or t[5] or t[3]
			circ = true
			pos.w = t.w or t[3] or pos.r * 2
			pos.h = t.h or t[4] or pos.r * 2
		else
			pos.w = t.w or t[3] or Gspot.style.unit
			pos.h = t.h or t[4] or Gspot.style.unit
		end
		pos.x = t.x or t[1] or 0
		pos.y = t.y or t[2] or 0
		return setmetatable(pos, this), circ
	end,
	__unm = function(a)
		local c = {x = a.x, y = a.y, w = a.w, h = a.h, r = a.r}
		c.x = 0 - a.x
		c.y = 0 - a.y
		return setmetatable(c, getmetatable(a))
	end,
	__add = function(a, b)
		local c = {x = a.x, y = a.y, w = a.w, h = a.h, r = a.r}
		local d
		local success, e = pcall(function(b) return b.x end, b)
		if success then d = e else d = b end
		c.x = a.x + d
		local success, e = pcall(function(b) return b.y end, b)
		if success then d = e else d = b end
		c.y = a.y + d
		return setmetatable(c, getmetatable(a))
	end,
	__sub = function(a, b)
		local c = {x = a.x, y = a.y, w = a.w, h = a.h, r = a.r}
		local d
		local success, e = pcall(function(b) return b.x end, b)
		if success then d = e else d = b end
		c.x = a.x - d
		local success, e = pcall(function(b) return b.y end, b)
		if success then d = e else d = b end
		c.y = a.y - d
		return setmetatable(c, getmetatable(a))
	end,
	__mul = function(a, b)
		local c = {x = a.x, y = a.y, w = a.w, h = a.h, r = a.r}
		local d
		local success, e = pcall(function(b) return b.x end, b)
		if success then d = e else d = b end
		c.x = a.x * d
		local success, e = pcall(function(b) return b.y end, b)
		if success then d = e else d = b end
		c.y = c.y * d
		return setmetatable(c, getmetatable(a))
	end,
	__div = function(a, b)
		local c = {x = a.x, y = a.y, w = a.w, h = a.h, r = a.r}
		local d
		local success, e = pcall(function(b) return b.x end, b)
		if success then d = e else d = b end
		c.x = a.x / d
		local success, e = pcall(function(b) return b.y end, b)
		if success then d = e else d = b end
		c.y = a.y / d
		return setmetatable(c, getmetatable(a))
	end,
	__pow = function(a, b)
		local c = {x = a.x, y = a.y, w = a.w, h = a.h, r = a.r}
		local d
		local success, e = pcall(function(b) return b.x end, b)
		if success then d = e else d = b end
		c.x = a.x ^ d
		local success, e = pcall(function(b) return b.y end, b)
		if success then d = e else d = b end
		c.y = a.y ^ d
		return setmetatable(c, getmetatable(a))
	end,
	__tostring = function(this) return this:type() .. ' : x = ' .. tostring(this.x) .. ', y = ' .. tostring(this.y) .. ', w = ' .. tostring(this.w) .. ', h = ' .. tostring(this.h) .. ', r = ' .. tostring(this.r) end,
	__index = {
		type = function(this) return 'Gspot.pos' end,
	},
}
Gspot.pos = setmetatable(pos, {__call = pos.load})

Gspot.util = {
	setshape = function(this, shape)
		assert(shape == 'circle' or shape == 'rect' or not shape, 'shape must be "rect" or "circle" or nil')
		this.shape = shape
		if this.shape == 'circle' and not this.pos.r then this.pos.r = this.pos.w / 2 end
	end,

	drawshape = function(this, pos)
		pos = pos or this:getpos()
		if this.shape == 'circle' then
			local segments = this.segments or math.max(pos.r, 8)
			love.graphics.circle('fill', pos.x + pos.r, pos.y + pos.r, pos.r, segments)
		else
			this:rect(pos)
		end
	end,

	rect = function(this, pos, mode)
		pos = this.Gspot:pos(pos.pos or pos or this.pos)
		assert(pos:type() == 'Gspot.pos')
		mode = mode or 'fill'
		love.graphics.rectangle(mode, pos.x, pos.y, pos.w, pos.h)
	end,

	setimage = function(this, img)
		if type(img) == 'string' and love.filesystem.exists(img) then
			img = love.graphics.newImage(img)
		end
		-- used for texture-atlas images, using my Quad class texture atlas implementation
		if img and pcall(function(img) return img:type() == 'Image' end, img.image) then
			this.img = img.image
			if this.img then
				this.pos.w = this.img:getWidth()
				this.pos.h = this.img:getHeight()
			end
			this:setquad(img.quad)
		-- used for normal image files
		elseif pcall(function(img) return img:type() == 'Image' end, img) then
			this.img = img
			if this.img then
				this.pos.w = this.img:getWidth()
				this.pos.h = this.img:getHeight()
			end
		else
			this.img = nil
		end
	end,

	-- new Quad support
	setquad = function(this, quad)
		if pcall(function(quad) return type(quad) == 'table' or quad:type() == 'userdata' end, quad) then
			this.quad = quad
			local x, y, w, h = quad:getViewport()
			-- update width and height to quad-size
			this.pos.w, this.pos.h = w, h
		else
			this.quad = nil
		end
	end,
	getquad = function(this)
		return this.quad
	end,

	drawimg = function(this, pos)
		love.graphics.setBlendMode(this.style.imagemode)
		love.graphics.setColor(this.style.fg)
		if this.quad then
			love.graphics.drawq(this.img, this.quad, pos.x, pos.y )
		else
			love.graphics.draw(this.img, (pos.x + (pos.w / 2)) - (this.img:getWidth()) / 2, (pos.y + (pos.h / 2)) - (this.img:getHeight() / 2))
		end
		love.graphics.setColor(255, 255, 255, 255)
		love.graphics.setBlendMode('alpha')
	end,

	setfont = function(this, font, size)
		if type(font) == 'string' and love.filesystem.exists(font) then
			font = love.graphics.newFont(font, size)
		elseif type(font) == 'number' then
			font = love.graphics.newFont(font)
		end
		if pcall(function(font) return font:type() == 'Font' end, font) then
			this.style.font = font
		else
			this.style.font = nil
			this.style = this.Gspot:clone(this.style)
		end
	end,

	getpos = function(this, scissor)
		local pos = this.Gspot:pos(this)
		if this.parent then
			local ppos = 0
			ppos, scissor = this.parent:getpos()
			pos = pos + ppos
			if this.parent:type() == 'Gspot.element.scrollgroup' and this ~= this.parent.scrollv and  this ~= this.parent.scrollh then
				scissor = this.Gspot:clone(this.parent:getpos())
				if this.parent.scrollv then pos.y = pos.y - this.parent.scrollv.values.current end
				if this.parent.scrollh then pos.x = pos.x - this.parent.scrollh.values.current end
			end
		end
		return pos, scissor
	end,

	containspoint = function(this, point)
		local pos = point.pos or point
		if this.shape == 'circle' and this.withinradius(pos, this:getpos() + this.pos.r) then return true
		elseif this.withinrect(pos, this:getpos()) then return true end
		return false
	end,

	withinrect = function(pos, rect)
		pos = pos.pos or pos
		rect = rect.pos or rect
		if pos.x >= rect.x and pos.x <= (rect.x + rect.w) and pos.y >= rect.y and pos.y < (rect.y + rect.h) then return true end
		return false
	end,

	getdist = function(pos, target)
		pos = pos.pos or pos
		target = target.pos or target
		return math.sqrt((pos.x-target.x) * (pos.x-target.x) + (pos.y-target.y) * (pos.y-target.y))
	end,

	withinradius = function(pos, circ)
		pos = pos.pos or pos
		circ = circ.pos or circ
		if math.sqrt((pos.x - circ.x) * (pos.x - circ.x) + (pos.y - circ.y) * (pos.y - circ.y)) < circ.r then return true end
		return false
	end,

	getparent = function(this)
		if this.parent then return this.parent:getparent()
		else return this end
	end,

	getmaxw = function(this)
		local maxw = 0
		for i, child in ipairs(this.children) do
			if (child ~= this.scrollv and child ~= this.scrollh) and child.pos.x + child.pos.w > maxw then maxw = child.pos.x + child.pos.w end
		end
		return maxw
	end,

	getmaxh = function(this)
		local maxh = 0
		for i, child in ipairs(this.children) do
			if (child ~= this.scrollv and child ~= this.scrollh) and child.pos.y + child.pos.h > maxh then maxh = child.pos.y + child.pos.h end
		end
		return maxh
	end,

	addchild = function(this, child, autostack)
		if autostack then
			if type(autostack) == 'number' or autostack == 'grid' then
				local limitx = (type(autostack) == 'number' and autostack) or this.pos.w
				local maxx, maxy = 0, 0
				for i, element in ipairs(this.children) do
					if element ~= this.scrollh and element ~= this.scrollv then
						if element.pos.y > maxy then maxy = element.pos.y end
						if element.pos.x + element.pos.w + child.pos.w <= limitx then maxx = element.pos.x + element.pos.w
						else maxx, maxy = 0, element.pos.y + element.pos.h end
					end
				end
				child.pos.x, child.pos.y = maxx, maxy
			elseif autostack == 'horizontal' then child.pos.x = this:getmaxw()
			elseif autostack == 'vertical' then child.pos.y = this:getmaxh() end
		end
		if this.scrollh then this.scrollh.values.max = math.max(this:getmaxw() - this.pos.w + child.pos.w, 0) end
		if this.scrollv then this.scrollv.values.max = math.max(this:getmaxh() - this.pos.h + child.pos.h, 0) end

		table.insert(this.children, child)
		child.parent = this
		child.style = this.Gspot:clone(child.style)
		setmetatable(child.style, {__index = this.style})
		return child
	end,

	remchild = function(this, child)
		child.pos = child:getpos()
		table.remove(this.children, this.Gspot.getindex(this.children, child))
		child.parent = nil
		setmetatable(child.style, {__index = this.Gspot.style})
	end,

	replace = function(this, replacement)
		this.Gspot.elements[this.Gspot.getindex(this.Gspot.elements, this)] = replacement
		return replacement
	end,

	getlevel = function(this)
		for i, element in pairs(this.Gspot.elements) do
			if element == this then return i end
		end
	end,

	setlevel = function(this, level)
		if level then
			table.insert(this.Gspot.elements, level, table.remove(this.Gspot.elements, this.Gspot.getindex(this.Gspot.elements, this)))
			for i, child in ipairs(this.children) do child:setlevel(level + i) end
		else
			table.insert(this.Gspot.elements, table.remove(this.Gspot.elements, this.Gspot.getindex(this.Gspot.elements, this)))
			for i, child in ipairs(this.children) do child:setlevel() end
		end
	end,

	show = function(this)
		this.display = true
		for i, child in pairs(this.children) do child:show() end
	end,

	hide = function(this)
		this.display = false
		for i, child in pairs(this.children) do child:hide() end
	end,

	focus = function(this)
		this.Gspot:setfocus(this)
	end,

	type = function(this)
		return 'Gspot.element.'..this.elementtype
	end,

	count = function(this, t)
	  local n = 0
	  for _ in pairs(t) do
		n = n + 1
	  end
	  return n
	end,
}

Gspot.element = {
	load = function(this, Gspot, elementtype, label, pos, parent)
		assert(Gspot[elementtype], 'invalid element constructor argument : element.elementtype must be an existing element type')
		assert(type(label) == 'string' or type(label) == 'number' or not label, 'invalid element constructor argument : element.label must be of type string or number')
		assert(type(pos) == 'table' or not pos, 'invalid element constructor argument : element.pos must be of type table or nil')
		assert((type(parent) == 'table' and parent:type():sub(1, 13) == 'Gspot.element') or not parent, 'invalid element constructor argument : element.parent must be of type element or nil')
		local pos, circ = Gspot:pos(pos)
		local element = {elementtype = elementtype, label = label, pos = pos, display = true, dt = 0, parent = parent, children = {}, Gspot = Gspot}
		if element.label == '' then element.label = element.label or ' ' end
		if circ then element.shape = 'circle' else element.shape = 'box' end
		if parent then element.style = setmetatable({}, {__index = parent.style})
		else element.style = setmetatable({}, {__index = Gspot.style}) end
		return setmetatable(element, {__index = Gspot[elementtype], __tostring = function(this) return this:type() .. ' (' .. this:getlevel() .. ')' end})
	end,
}
setmetatable(Gspot.element, {__call = Gspot.element.load})

Gspot.scrollvalues = function(this, values)
	local val = {}
	val.min = values.min or values[1] or 0
	val.max = values.max or values[2] or 0
	val.current = values.current or values[3] or val.min
	val.step = values.step or values[4] or this.style.unit
	val.axis = values.axis or values[5] or 'vertical'
	return val
end

-- elements

Gspot.group = {
	load = function(this, Gspot, label, pos, parent)
		return Gspot:add(Gspot:element('group', label, pos, parent))
	end,
	draw = function(this, pos)
		love.graphics.setColor(this.style.bg)
		this:drawshape(pos)
		if this.label then
			love.graphics.setColor(this.style.fg)
			love.graphics.print(this.label, pos.x + ((pos.w - this.style.font:getWidth(this.label)) / 2), pos.y + ((this.style.unit - this.style.font:getHeight('dp')) / 2))
		end
	end,
}
setmetatable(Gspot.group, {__index = Gspot.util, __call = Gspot.group.load})

Gspot.collapsegroup = {
	load = function(this, Gspot, label, pos, parent)
		local element = Gspot:group(label, pos, parent)
		element.view = true
		element.orig = Gspot:clone(element.pos)
		element.toggle = function(this)
			this.view = not element.view
			this.pos.h = (this.view and this.orig.h) or this.style.unit
			for i, child in ipairs(this.children) do
				if child ~= this.control then
					if this.view then child:show() else child:hide() end
				end
			end
			this.control.label = (this.view and '-') or '='
		end
		element.control = Gspot:button('-', {element.pos.w - element.style.unit}, element)
		element.control.click = function(this)
			this.parent:toggle()
		end
		return element
	end,
}
setmetatable(Gspot.collapsegroup, {__index = Gspot.util, __call = Gspot.collapsegroup.load})

Gspot.text = {
	load = function(this, Gspot, label, pos, parent, autosize)
		local element = Gspot:element('text', label, pos, parent)
		if autosize then
			element.pos.w = element.style.font:getWidth(label) + (element.style.unit / 2)
			element.autosize = autosize
		end
		element:setfont(element.style.font)
		return Gspot:add(element)
	end,
	setfont = function(this, font, size)
		this.Gspot.util.setfont(this, font, size)
		local width, lines = this.style.font:getWrap(this.label, this.pos.w)
    --if type(lines) == "table" then lines = #lines end -- love 0.10.0 support
		lines = math.max(lines, 1)
		this.pos.h = (this.style.font:getHeight('dp') * lines) + (this.style.unit - this.style.font:getHeight('dp'))
	end,
	draw = function(this, pos)
		love.graphics.setColor(this.style.fg)
		if this.autosize then love.graphics.print(this.label, pos.x + (this.style.unit / 4), pos.y + ((this.style.unit - this.style.font:getHeight('dp')) / 2))
		else love.graphics.printf(this.label, pos.x + (this.style.unit / 4), pos.y + ((this.style.unit - this.style.font:getHeight('dp')) / 2), (this.autosize and pos.w) or  pos.w - (this.style.unit / 2), 'left') end
	end,
}
setmetatable(Gspot.text, {__index = Gspot.util, __call = Gspot.text.load})

Gspot.typetext = {
	load = function(this, Gspot, label, pos, parent, autosize)
		local element = Gspot:text('', pos, parent, autosize)
		element.values = {text = label, cursor = 1, count = string.len(label), done=false }
		element.updateinterval = 0.1
		element.update = function(this, dt)
			if not this.values.done then
				this.values.cursor = this.values.cursor + 1
				this.label = this.values.text:sub(1, this.values.cursor)
				if this.values.count-this.values.cursor <= 0 then
					this.values.done = true
				end
			end
		end
		return Gspot:add(element)
	end,
}
setmetatable(Gspot.typetext, {__index = Gspot.util, __call = Gspot.typetext.load})

-- new: SiENcE richtext integration
Gspot.richtext = {
	load = function(this, Gspot, label, pos, parent, macros, defaultfont, debug)
		-- enable richtext debug grid
		if debug then rich.debug=true end
		local element = Gspot:element('richtext', label, pos, parent)
		element.richtext = rich:new( {label, element.pos.w, macros }, element.style.fg, defaultfont )
		element.pos.h = element.richtext.height
		return Gspot:add(element)
	end,
	-- re-render pre-rendered image (1st time it's already done on creation in rich:new)
	render = function(this)
		this.richtext:render()
		this.richtext:render(true)
	end,
	draw = function(this, pos)
		love.graphics.setBlendMode(this.style.imagemode)
		love.graphics.setColor(this.style.fg)			 -- SiENcE: new
		this.richtext:draw( pos.x, pos.y )
	end,
}
setmetatable(Gspot.richtext, {__index = Gspot.util, __call = Gspot.richtext.load})

-- new: SiENcE richtext typetext integration
Gspot.richtypetext = {
	load = function(this, Gspot, label, pos, parent, macros, defaultfont, updateinterval, debug)
		-- enable richtypetext debug grid
		if debug then rich.debug=true end
		local element = Gspot:element('richtypetext', label, pos, parent)
		element.richtypetext = rich:new( {label, element.pos.w, macros }, element.style.fg, defaultfont )
		element.pos.h = element.richtypetext.height
		element.lineheight = {}
		for i, line in ipairs(element.richtypetext.lines) do
			local height=nil
			for j, fragment in ipairs(line) do
				if fragment.type == 'string' then
					if not height or height < fragment.height then height=fragment.height end
				elseif fragment.type == 'img' then
					if not height or height < fragment[1].height then height=fragment[1].height end
				end
			end
			if height then
				table.insert(element.lineheight,#element.lineheight+1,height)
			end
		end
		local linecount = Gspot.util.count(this, element.richtypetext.textlines)
		local nothingtodo = false
		if linecount==0 then nothingtodo = true end
		element.values = {lines = linecount, height=element.richtypetext.height, width=0, updateinterval_linecursor=0, linecursor=1, done = nothingtodo, updateinterval = updateinterval or 0.5 }
		--element.updateinterval = updateinterval or 0.0042
		element.update = function(this, dt)
			if not this.values.done then
				this.values.width = this.values.width + dt*this.values.updateinterval*this.pos.w
				if this.values.width > this.pos.w then this.values.width = this.pos.w end
				this.values.updateinterval_linecursor = this.values.updateinterval_linecursor + dt*this.values.updateinterval
				if this.values.updateinterval_linecursor > 1 then
					this.values.updateinterval_linecursor = 0
					this.values.width = 0
					this.values.linecursor = this.values.linecursor + 1
					if this.values.lines-this.values.linecursor+1 <= 0 then
						this.values.done = true
					end
				end

			end
		end
		return Gspot:add(element)
	end,
	-- re-render pre-rendered image (1st time it's already done on creation in rich:new)
	render = function(this)
		this.richtypetext:render()
		this.richtypetext:render(true)
	end,
	draw = function(this, pos)
		love.graphics.setBlendMode(this.style.imagemode)
		love.graphics.setColor(this.style.fg)			 -- SiENcE: new
		this.richtypetext:draw( pos.x, pos.y )
		-- draw rectangle over canvas to hide canvas-text and slowly reveal line by line
		if not this.values.done then
			local r,g,b,a = love.graphics.getColor()
			love.graphics.setColor(21, 21, 21, 255)
			local lastheight=0
			for i, height in ipairs(this.lineheight) do
				if i == this.values.linecursor then
					love.graphics.rectangle("fill", pos.x+this.values.width, pos.y+lastheight, this.pos.w, height)
				elseif i > this.values.linecursor then
					love.graphics.rectangle("fill", pos.x, pos.y+lastheight, this.pos.w, height)
				end
				lastheight = lastheight+height
			end
			love.graphics.setColor(r,g,b,a)
		end
	end,
}
setmetatable(Gspot.richtypetext, {__index = Gspot.util, __call = Gspot.richtypetext.load})

Gspot.image = {
	load = function(this, Gspot, label, pos, parent, img)
		local element = Gspot:element('image', label, pos, parent)
		element:setimage(img)
		return Gspot:add(element)
	end,
	setimage = function(this, img)
		this.Gspot.util.setimage(this, img)
		-- disabled, now done in util.setimage
--		if this.img then
--			this.pos.w = this.img:getWidth()
--			this.pos.h = this.img:getHeight()
--		end
	end,
	draw = function(this, pos)
		if this.img then
			this:drawimg(pos)
		end
		if this.label then
			love.graphics.setColor(this.style.fg)
			love.graphics.print(this.label, pos.x + ((pos.w - this.style.font:getWidth(this.label)) / 2), (pos.y + pos.h) + ((this.style.unit - this.style.font:getHeight('dp')) / 2))
		end
	end,
}
setmetatable(Gspot.image, {__index = Gspot.util, __call = Gspot.image.load})

Gspot.button = {
	load = function(this, Gspot, label, pos, parent)
		return Gspot:add(Gspot:element('button', label, pos, parent))
	end,
	draw = function(this, pos)
		if this.parent and this.value == this.parent.value then
			if this == this.Gspot.mousein then love.graphics.setColor(this.style.focus)
			else love.graphics.setColor(this.style.hilite) end
		else
			if this == this.Gspot.mousein then love.graphics.setColor(this.style.hilite)
			else love.graphics.setColor(this.style.default) end
		end
		this:drawshape(pos)
		love.graphics.setColor(this.style.fg)
		if this.shape == 'circle' then
			if this.img then this:drawimg(pos) end
			if this.label and string.len(this.label) > 0 then love.graphics.print(this.label, (pos.x + pos.r) - (this.style.font:getWidth(this.label) / 2), (this.img and (pos.y + (pos.r * 2)) + ((this.style.unit - this.style.font:getHeight(this.label)) / 2)) or (pos.y + pos.r) - (this.style.font:getHeight(this.label) / 2)) end
		else
			if this.img then this:drawimg(pos) end
			if this.label and string.len(this.label) > 0 then love.graphics.print(this.label, (pos.x + (pos.w / 2)) - (this.style.font:getWidth(this.label) / 2), (this.img and pos.y + ((this.style.unit - this.style.font:getHeight(this.label)) / 2)) or (pos.y + (pos.h / 2)) - (this.style.font:getHeight(this.label) / 2)) end
		end
	end,
}
setmetatable(Gspot.button, {__index = Gspot.util, __call = Gspot.button.load})

Gspot.imgbutton = {
	load = function(this, Gspot, label, pos, parent, img)
		local element = Gspot:button(label, pos, parent)
		element:setimage(img)
		return Gspot:add(element)
	end,
}
setmetatable(Gspot.imgbutton, {__index = Gspot.util, __call = Gspot.imgbutton.load})

Gspot.option = {
	load = function(this, Gspot, label, pos, parent, value)
		local element = Gspot:button(label, pos, parent)
		element.value = value
		element.click = function(this) this.parent.value = this.value end
		return element
	end,
}
setmetatable(Gspot.option, {__index = Gspot.util, __call = Gspot.option.load})

Gspot.checkbox = {
	load = function(this, Gspot, label, pos, parent, value)
		local element = Gspot:element('checkbox', label, pos, parent)
		element.value = value
		return Gspot:add(element)
	end,
	click = function(this) this.value = not this.value end,
	draw = function(this, pos)
		if this == this.Gspot.mousein then love.graphics.setColor(this.style.hilite)
		else love.graphics.setColor(this.style.default) end
		this:drawshape(pos)
		if this.value then
			love.graphics.setColor(this.style.fg)
			this:drawshape(this.Gspot:pos({x = pos.x + (pos.w / 4), y = pos.y + (pos.h / 4), w = pos.w / 2, h = pos.h / 2, r = pos.r and pos.r / 2}))
		end
		if this.label then
			love.graphics.setColor(this.style.fg)
			love.graphics.print(this.label, pos.x + pos.w + (this.style.unit / 2), pos.y + ((this.pos.h - this.style.font:getHeight(this.label)) / 2))
		end
	end,
}
setmetatable(Gspot.checkbox, {__index = Gspot.util, __call = Gspot.checkbox.load})

Gspot.input = {
	load = function(this, Gspot, label, pos, parent, value)
		local element = Gspot:element('input', label, pos, parent)
		element.value = (value and tostring(value)) or ''
		element.cursor = element.value:len()
		element.cursorlife = 0
	--element.keyrepeat = 200
	--element.keydelay = 500
		return Gspot:add(element)
	end,
	update = function(this, dt)
		if this.Gspot.focus == this then
			if this.cursorlife >= 1 then this.cursorlife = 0
			else this.cursorlife = this.cursorlife + dt end
		end
	end,
	draw = function(this, pos)
		if this == this.Gspot.focus then love.graphics.setColor(this.style.bg)
		else
			if this == this.Gspot.mousein then love.graphics.setColor(this.style.hilite)
			else love.graphics.setColor(this.style.default) end
		end
		this:drawshape(pos)
		love.graphics.setColor(this.style.fg)
		local str = tostring(this.value)
		local offset = 0
		while this.style.font:getWidth(str) > pos.w - (this.style.unit / 2) do
			str = str:sub(2)
			offset = offset + 1
		end
		love.graphics.print(str, pos.x + (this.style.unit / 4), pos.y + ((pos.h - this.style.font:getHeight('dp')) / 2))
		if this == this.Gspot.focus and this.cursorlife < 0.5 then
			local cursorx = ((pos.x + (this.style.unit / 4)) + this.style.font:getWidth(str:sub(1, this.cursor - offset)))
			love.graphics.line(cursorx, pos.y + (this.style.unit / 8), cursorx, (pos.y + pos.h) - (this.style.unit / 8))
		end
		if this.label then
			love.graphics.setColor(this.style.fg)
			love.graphics.print(this.label, pos.x - ((this.style.unit / 2) + this.style.font:getWidth(this.label)), pos.y + ((this.pos.h - this.style.font:getHeight('dp')) / 2))
		end
	end,
	click = function(this) this:focus() end,
	done = function(this) this.Gspot:unfocus() end,
	keypress = function(this, key, isrepeat)						-- TODO: change to support love 0.9.0 API; unicode
		key = love.keyboard.getScancodeFromKey(key)
		-- fragments attributed to vrld's Quickie : https://github.com/vrld/Quickie
		if key == 'backspace' then
			this.value = this.value:sub(1, this.cursor - 1)..this.value:sub(this.cursor + 1)
			this.cursor = math.max(0, this.cursor - 1)
		elseif key == 'delete' then
			this.value = this.value:sub(1, this.cursor)..this.value:sub(this.cursor + 2)
			this.cursor = math.min(this.value:len(), this.cursor)
		elseif key == 'left' then
			this.cursor = math.max(0, this.cursor - 1)
		elseif key == 'right' then
			this.cursor = math.min(this.value:len(), this.cursor + 1)
		elseif key == 'home' then
			this.cursor = 0
		elseif key == 'end' then
			this.cursor = this.value:len()
	  --elseif key >= 32 and key < 127 then
	  --	this.value = this.value:sub(1, this.cursor)..string.char(key)..this.value:sub(this.cursor + 1)
	  --	this.cursor = this.cursor + 1
		elseif key and key:match( '%d' ) then		-- key:match( '^[%w%s]$' )
			this.value = this.value .. love.keyboard.getScancodeFromKey(key)
			this.cursor = this.cursor + 1
		elseif key == 'tab' and this.next and this.next.elementtype then
			this.next:focus()
		elseif key == 'escape' then
			this.Gspot:unfocus()
		end
		-- /fragments
	end,
}
setmetatable(Gspot.input, {__index = Gspot.util, __call = Gspot.input.load})

Gspot.scroll = {
	load = function(this, Gspot, label, pos, parent, values)
		local element = Gspot:element('scroll', label, pos, parent)
		element.values = Gspot:scrollvalues(values)
		return Gspot:add(element)
	end,
	update = function(this, dt)
		local mouse = {}
		mouse.x, mouse.y = this.Gspot:getmouse()
		if this.withinrect({x = mouse.x, y = mouse.y}, this:getpos()) then this.Gspot.mousein = this end
	end,
	step = function(this, step)
		if step > 0 then this.values.current = math.max(this.values.current - this.values.step, this.values.min)
		elseif step < 0 then this.values.current = math.min(this.values.current + this.values.step, this.values.max)
		end
	end,
	drag = function(this, x, y)
		local pos = this:getpos()
		this.values.current = this.values.min + ((this.values.max - this.values.min) * ((this.values.axis == 'vertical' and ((math.min(math.max(pos.y, y), (pos.y + pos.h)) - pos.y) / pos.h)) or ((math.min(math.max(pos.x, x), (pos.x + pos.w)) - pos.x) / pos.w)))
	end,
	rdrag = function(this, x, y)
		local pos = this:getpos()
		this.values.current = this.values.min + ((this.values.max - this.values.min) * ((this.values.axis == 'vertical' and ((math.min(math.max(pos.y, y), (pos.y + pos.h)) - pos.y) / pos.h)) or ((math.min(math.max(pos.x, x), (pos.x + pos.w)) - pos.x) / pos.w)))
	end,
	wheelup = function(this)
		if this.values.axis == 'horizontal' then this:step(-1) else this:step(1) end
	end,
	wheeldown = function(this)
		if this.values.axis == 'horizontal' then this:step(1) else this:step(-1) end
	end,
	keypress = function(this, key, code)
		if key == 'left' and this.values.axis == 'horizontal' then
			this:step(1)
		elseif key == 'right' and this.values.axis == 'horizontal' then
			this:step(-1)
		elseif key == 'up' and this.values.axis == 'vertical' then
			this:step(-1)
		elseif key == 'down' and this.values.axis == 'vertical' then
			this:step(1)
		elseif key == 'tab' and this.next and this.next.elementtype then
			this.next:focus()
		elseif key == 'escape' then
			this.Gspot:unfocus()
		end
	end,
	done = function(this) this.Gspot:unfocus() end,
	draw = function(this, pos)
		if this == this.Gspot.mousein or this == this.Gspot.drag or this == this.Gspot.focus then love.graphics.setColor(this.style.default)
		else love.graphics.setColor(this.style.bg) end
		this:rect(pos)
		if this == this.Gspot.mousein or this == this.Gspot.drag or this == this.Gspot.focus then love.graphics.setColor(this.style.fg)
		else love.graphics.setColor(this.style.hilite) end
		local handlepos = this.Gspot:pos({x = (this.values.axis == 'horizontal' and math.min(pos.x + (pos.w - this.style.unit), math.max(pos.x, pos.x + (pos.w * (this.values.current / (this.values.max - this.values.min))) - (this.style.unit / 2)))) or pos.x, y = (this.values.axis == 'vertical' and math.min(pos.y + (pos.h - this.style.unit), math.max(pos.y, pos.y + (pos.h * (this.values.current / (this.values.max - this.values.min))) - (this.style.unit / 2)))) or pos.y, w = this.style.unit, h = this.style.unit, r = pos.r})
		this:drawshape(handlepos)
		if this.label then
			love.graphics.setColor(this.style.fg)
			love.graphics.print(this.label, (this.values.axis == 'horizontal' and pos.x - ((this.style.unit / 2) + this.style.font:getWidth(this.label))) or pos.x + ((pos.w - this.style.font:getWidth(this.label)) / 2), (this.values.axis == 'vertical' and (pos.y + pos.h) + ((this.style.unit - this.style.font:getHeight('dp')) / 2)) or pos.y + ((this.style.unit - this.style.font:getHeight('dp')) / 2))
		end
	end,
}
setmetatable(Gspot.scroll, {__index = Gspot.util, __call = Gspot.scroll.load})

Gspot.scrollgroup = {
	load = function(this, Gspot, label, pos, parent, axis)
		axis = axis or 'both'
		local element = Gspot:element('scrollgroup', label, pos, parent)
		element.maxh = 0
		element = Gspot:add(element)
		if axis ~= 'horizontal' then element.scrollv = Gspot:scroll(nil, {x = element.pos.w, y = 0, w = element.style.unit, h = element.pos.h}, element, {0, 0, 0, element.style.unit, 'vertical'}) end
		if axis ~= 'vertical' then element.scrollh = Gspot:scroll(nil, {x = 0, y = element.pos.h, w = element.pos.w, h = element.style.unit}, element, {0, 0, 0, element.style.unit, 'horizontal'}) end
		return element
	end,
	draw = function(this, pos)
		love.graphics.setColor(this.style.bg)
		this:drawshape(pos)
		if this.label then
			love.graphics.setColor(this.style.fg)
			love.graphics.print(this.label, pos.x + ((pos.w - this.style.font:getWidth(this.label)) / 2), pos.y + ((this.style.unit - this.style.font:getHeight(this.label)) / 2))
		end
	end,
}
setmetatable(Gspot.scrollgroup, {__index = Gspot.util, __call = Gspot.scrollgroup.load})

Gspot.hidden = {
	load = function(this, Gspot, label, pos, parent)
		return Gspot:add(Gspot:element('hidden', label, pos, parent))
	end,
	draw = function(this, pos)
		--
	end,
}
setmetatable(Gspot.hidden, {__index = Gspot.util, __call = Gspot.hidden.load})

Gspot.radius = {
	load = function(this, Gspot, label, pos, parent)
		return Gspot:add(Gspot:element('radius', label, pos, parent))
	end,
	draw = function(this, pos)
		--
	end,
}
setmetatable(Gspot.radius, {__index = Gspot.util, __call = Gspot.radius.load})

Gspot.feedback = {
	load = function(this, Gspot, label, pos, parent, autopos)
		pos = pos or {}
		autopos = (autopos == nil and true) or autopos
		if autopos then
			for i, element in ipairs(Gspot.elements) do
				if element.elementtype == 'feedback' and element.autopos then element.pos.y = element.pos.y + element.style.unit end
			end
		end
		pos.x = pos.x or pos[1] or 0
		pos.y = pos.y or pos[2] or 0
		pos.w = 0
		pos.h = 0
		local element = Gspot:add(Gspot:element('feedback', label, pos, parent))
		element.style.fg = {255, 255, 255, 255}
		element.alpha = 255
		element.life = 5
		element.autopos = autopos
		return element
	end,
	update = function(this, dt)
		this.alpha = this.alpha - ((255 * dt) / this.life)
		if this.alpha < 0 then
			this.Gspot:rem(this)
			return
		end
		local color = this.style.fg
		this.style.fg = {color[1], color[2], color[3], this.alpha}
	end,
	draw = function(this, pos)
		love.graphics.setColor(this.style.fg)
		love.graphics.print(this.label, pos.x + (this.style.unit / 4), pos.y + ((this.style.unit - this.style.font:getHeight('dp')) / 2))
	end,
}
setmetatable(Gspot.feedback, {__index = Gspot.util, __call = Gspot.feedback.load})

Gspot.progress = {
	load = function(this, Gspot, label, pos, parent)
		local element = Gspot:add(Gspot:element('progress', label, pos, parent))
		element.loaders = {}
		element.values = Gspot.scrollvalues(element, {0, 0, 0, 1})
		return element
	end,
	update = function(this, dt)
		for i, loader in ipairs(this.loaders) do
			if loader.status == 'waiting' then
				local success, result = pcall(function(loader) return loader.func() end, loader)
				loader.status = (success and 'done') or error
				loader.result = result
				this.values.current = this.values.current + 1
				break
			end
			if i == #this.loaders then this:done() end
		end
	end,
	draw = function(this, pos)
		love.graphics.setColor(this.style.default)
		this:drawshape(pos)
		love.graphics.setColor(this.style.fg)
		this:rect({x = pos.x, y = pos.y, w = pos.w * (this.values.current / this.values.max), h = pos.h})
		if this.label then
			love.graphics.setColor(this.style.fg)
			love.graphics.print(this.label, pos.x - ((this.style.unit / 2) + this.style.font:getWidth(this.label)), pos.y + ((this.pos.h - this.style.font:getHeight('dp')) / 2))
		end
	end,
	done = function(this)
		this.Gspot:rem(this)
	end,
	add = function(this, loader)
		table.insert(this.loaders, {status = 'waiting', func = loader})
		this.values.max = this.values.max + 1
	end,
}
setmetatable(Gspot.progress, {__index = Gspot.util, __call = Gspot.progress.load})


return Gspot:load()
