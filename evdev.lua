local type, setmetatable, pairs = type, setmetatable, pairs
local sf = string.format
local evdev_core = require("evdev_core")
module("evdev")

local ev = { }
ev.__index = ev

local default_keymap = {
	-- n = normal, s = shift
	[2] = { str = "KEY_1",	n = "1",	s = "!" },
	[3] = { str = "KEY_2",	n = "2",	s = "@" },
	[4] = { str = "KEY_3",	n = "3",	s = "#" },
	[5] = { str = "KEY_4",	n = "4",	s = "$" },
	[6] = { str = "KEY_5",	n = "5",	s = "%" },
	[7] = { str = "KEY_6",	n = "6",	s = "^" },
	[8] = { str = "KEY_7",	n = "7",	s = "&" },
	[9] = { str = "KEY_8",	n = "8",	s = "*" },
	[10] = { str = "KEY_9",	n = "9",	s = "(" },
	[11] = { str = "KEY_0",	n = "0",	s = ")" },
	[12] = { str = "KEY_MINUS",	n = "-",	s = "_" },
	[13] = { str = "KEY_EQUAL",	n = "=",	s = "+" },
	[15] = { str = "KEY_TAB",	n = "\t",	s = "\t" },
	[16] = { str = "KEY_Q",	n = "q",	s = "Q" },
	[17] = { str = "KEY_W",	n = "w",	s = "W" },
	[18] = { str = "KEY_E",	n = "e",	s = "E" },
	[19] = { str = "KEY_R",	n = "r",	s = "R" },
	[20] = { str = "KEY_T",	n = "t",	s = "T" },
	[21] = { str = "KEY_Y",	n = "y",	s = "Y" },
	[22] = { str = "KEY_U",	n = "u",	s = "U" },
	[23] = { str = "KEY_I",	n = "i",	s = "I" },
	[24] = { str = "KEY_O",	n = "o",	s = "O" },
	[25] = { str = "KEY_P",	n = "p",	s = "P" },
	[26] = { str = "KEY_LEFTBRACE",	n = "[",	s = "{" },
	[27] = { str = "KEY_RIGHTBRACE",	n = "]",	s = "}" },
	[28] = { str = "KEY_ENTER",	n = "\n",	s = "\n" },
	[30] = { str = "KEY_A",	n = "a",	s = "A" },
	[31] = { str = "KEY_S",	n = "s",	s = "S" },
	[32] = { str = "KEY_D",	n = "d",	s = "D" },
	[33] = { str = "KEY_F",	n = "f",	s = "F" },
	[34] = { str = "KEY_G",	n = "g",	s = "G" },
	[35] = { str = "KEY_H",	n = "h",	s = "H" },
	[36] = { str = "KEY_J",	n = "j",	s = "J" },
	[37] = { str = "KEY_K",	n = "k",	s = "K" },
	[38] = { str = "KEY_L",	n = "l",	s = "L" },
	[39] = { str = "KEY_SEMICOLON",	n = ";",	s = ":" },
	[40] = { str = "KEY_APOSTROPHE",	n = "'",	s = "\"" },
	[41] = { str = "KEY_GRAVE",	n = "`",	s = "~" },
	[43] = { str = "KEY_BACKSLASH",	n = "\\",	s = "|" },
	[44] = { str = "KEY_Z",	n = "z",	s = "Z" },
	[45] = { str = "KEY_X",	n = "x",	s = "X" },
	[46] = { str = "KEY_C",	n = "c",	s = "C" },
	[47] = { str = "KEY_V",	n = "v",	s = "V" },
	[48] = { str = "KEY_B",	n = "b",	s = "B" },
	[49] = { str = "KEY_N",	n = "n",	s = "N" },
	[50] = { str = "KEY_M",	n = "m",	s = "M" },
	[51] = { str = "KEY_COMMA",	n = ",",	s = "<" },
	[52] = { str = "KEY_DOT",	n = ".",	s = ">" },
	[53] = { str = "KEY_SLASH",	n = "/",	s = "?" },
	[55] = { str = "KEY_KPASTERISK",	n = "*",	s = "*" },
	[57] = { str = "KEY_SPACE",	n = " ",	s = " " },
	[71] = { str = "KEY_KP7",	n = "7",	s = "7" },
	[72] = { str = "KEY_KP8",	n = "8",	s = "8" },
	[73] = { str = "KEY_KP9",	n = "9",	s = "9" },
	[74] = { str = "KEY_KPMINUS",	n = "-",	s = "-" },
	[75] = { str = "KEY_KP4",	n = "4",	s = "4" },
	[76] = { str = "KEY_KP5",	n = "5",	s = "5" },
	[77] = { str = "KEY_KP6",	n = "6",	s = "6" },
	[78] = { str = "KEY_KPPLUS",	n = "+",	s = "+" },
	[79] = { str = "KEY_KP1",	n = "1",	s = "1" },
	[80] = { str = "KEY_KP2",	n = "2",	s = "2" },
	[81] = { str = "KEY_KP3",	n = "3",	s = "3" },
	[82] = { str = "KEY_KP0",	n = "0",	s = "0" },
	[83] = { str = "KEY_KPDOT",	n = ".",	s = "." },
	[96] = { str = "KEY_KPENTER",	n = "\r",	s = "\r" },
	[117] = { str = "KEY_KPEQUAL",	n = "=",	s = "=" },
	[118] = { str = "KEY_KPPLUSMINUS",	n = "+-",	s = "+-" },
	[121] = { str = "KEY_KPCOMMA",	n = ",",	s = "," },
}

function ev:find_device(f)
	self:dbg("find_device() getting device list...")

	local t, e = evdev_core.list()
	if not t then
		self:dbg("find_device() ERROR: %s", e)
		return false, e
	end

	self:dbg("find_device() OK, got %d device(s)", #t)

	for _, d in pairs(t) do
		if f.vendor and f.product then
			if f.vendor == d.vendor and f.product == d.product then
				self:dbg("find_device() OK, found device '%s'", d.dev)
				return self:open(d.dev)
			else
				self:dbg("find_device() device didn't match, name: '%s' vendor: 0x%x (%d) product: 0x%x (%d)",
					  d.name, d.vendor, d.vendor, d.product, d.product)
			end
		elseif f.topology then
			if f.topology == d.topology then
				self:dbg("find_device() OK, found device '%s' (%s)", d.dev, d.topology)
				return self:open(d.dev)
			else
				self:dbg("find_device() device didn't match, name: '%s' topology: '%s'",
					  d.name, d.vendor, d.vendor, d.product, d.product)
			end
		end
	end

	self:dbg("find_device() ERROR: device not found")
	return false, 'device not found (permission denied?)'
end

function ev:open(f)
	if type(f) == "table" then return self:find_device(f) end
	self:dbg("open() using device: '%s'", f)
	self.handle, e = evdev_core.open(f)
	if not e then
		self:dbg("open() OK")
		return true, nil
	end
	self:dbg("open() ERROR: %s", e)
	return false, e
end

function ev:dump(cb)
	local r, e = self.handle:read()
	if not r then
		self:dbg("dump() read error: %s", e)
		return false
	end

	self:dbg("dump() read %d events", #r.events)

	for _, ex in pairs(r.events) do
		event = evdev_core.event_string(ex.type)
		self:dbg("dump() time: %d event: %s code: %d (0x%x) value: %d (0x%x)",
			  ex.time, event, ex.code, ex.code, ex.value, ex.value)
		if cb then
			if not cb(ex.time, event, ex.code, ex.value) then
				return false
			end
		end
	end

	return true
end

function ev:read(count, timeout)
	local r, e = self.handle:read(count, timeout)
	if not r then
		self:dbg("read() ERROR: %s", e)
		return nil, e
	end

	self:dbg("read() read %d events", #r.events)
	return r
end

function ev:read_keys_until(key, recursion)
	if not recursion then self.key_events = {} end
	if not self.handle then return nil, 'device not open' end

	local isnum = (type(key) ~= "string")
	local r, e = self.handle:read()
	if not r then
		self:dbg("read_keys_until() ERROR: %s", e)
		return nil, e
	end

	self:dbg("read_keys_until() read %d events", #r.events)

	for _, ex in pairs(r.events) do
		event = evdev_core.event_string(ex.type)
		if ex.type == evdev_core.EV_KEY then
			self:dbg("read_keys_until() time: %d event: %s key: %s state: %s (0x%x)", ex.time, event,
				  evdev_core.key_string(ex.code), self:key_is_pressed(ex) and 'pressed' or 'released', ex.value)

			self:push_key(ex)

			if not ev:key_is_pressed(ex) then
				if isnum then 
					if ex.code == key then
						self:dbg("read_keys_until() OK, got key")
						return self:key_events_string(self.key_events)
					end
				else
					if evdev_core.key_string(ex.code) == key then
						self:dbg("read_keys_until() OK, got key")
						return self:key_events_string(self.key_events)
					end
				end
			end
		else
			self:dbg("read_keys_until() time: %d event: %s code: 0x%x value: 0x%x", ex.time, event, ex.code, ex.value)
		end
	end

	return self:read_keys_until(key, true)
end

function ev:close()
	if not self.handle then return end
	self.handle:close()
end

function ev:key_is_pressed(k) return k.value == 1 and true or false end
function ev:key_is_shift(k)
	if k.code == evdev_core.KEY_LEFTSHIFT then return true end
	return false
end

function ev:char_from_event(e)
	if self:key_is_shift(e) then
		self.shift_pressed = self:key_is_pressed(e)
		return ''
	end

	local key = self.keymap[e.code]
	if key then
		if self:key_is_pressed(e) then
			if self:is_shift() then					
				return key.s or ''
			else
				return key.n or ''
			end
		end
	else
		self:dbg("char_from_event() unprocessed key: '%s'", evdev_core.key_string(e.code))
		return ''
	end

	return ''
end

function ev:key_events_string(events)
	local ret = ''
	for _, e in pairs(events) do
		ret = ret .. self:char_from_event(e)
	end
	return ret:len() > 0 and ret or nil
end

function ev:fd() return self.handle:fd() end
function ev:event_is_key(e) return e.type == evdev_core.EV_KEY end
function ev:key_string(code) return evdev_core.key_string(code) end
function ev:keymap() return self.keymap end
function ev:default_keymap() return default_keymap end
function ev:set_keymap(t) self.keymap = t end
function ev:push(t, v) t[#t+1] = v end
function ev:is_shift() return self.shift_pressed end
function ev:push_key(k) ev:push(self.key_events, k) end
function ev:set_debug(v) self.debug = v end
function ev:set_log_function(fn) self.log_fn = fn end
function ev:log(...) if self.log_fn then self.log_fn(sf(...)) end end
function ev:dbg(...) if not self.debug then return end self:log(...) end

function new()
	local p = {
		debug = false,
		log_fn = nil,
		handle = nil,
		key_events = {},
		shift_pressed = false,
		keymap = default_keymap,
	}

	setmetatable(p, ev)
	return p
end
