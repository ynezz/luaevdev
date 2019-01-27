# luaevdev

Small library for comfortable access to Linux input subsystem(evdev particularly) from Lua.

## About

I've created this small library, because I somehow needed to process(and sometimes also modify) output of
barcode reader, which was connected to the system as USB/HID keyboard.

So according to this use case my aim wasn't to create fullblown library from day one, but instead
I've added everything necessary for my needs, particularly handling just of the key events. Anyway
I think, that it's generic enough to add support for other event types, so as always, patches are welcome :)

## Build instructions

1. `$ git://github.com/ynezz/luaevdev.git`
1. `$ cd luavdev`
1. `$ mkdir build && cd build`
1. `$ cmake ..` or `cmake-gui ..`
1. `$ cmake --build .`
1. `$ sudo cmake --build . --target install`

## Usage

`$ cat test.lua`

``` lua
require("evdev")

function pretty_white(s)
  return s:gsub('\r', '\\r'):gsub('\n', '\\n'):gsub('\t', '\\t')
end

function log(...) io.stdout:write(string.format(...), '\n') end

function read_test(device, debug)
	local p, e, r

	local p, e  = evdev.new()
	if e then log("evdev create error: %s", e) return end

	p:set_log_function(log)
	p:set_debug(debug)
	r, e = p:open(device)
	if e then log("open() barcode reader error: %s", e) return end

	repeat
		log("Please scan a barcode...")
		r, e = p:read_keys_until('KEY_ENTER')
		log("Read barcode: %s", pretty_white(r or 'nothing'))
	until e

	log("Barcode read error: %s", e)
	p:close()
end

read_test({ vendor=0x76d, product=0x1 })  -- Toyota Denso GT-10 (barcode reader)
```

## License

Copyright &copy; 2019 Petr Štetiar, Gaben spol. s r.o.

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.  IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
