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

read_test({ vendor=0x1447, product=0x8011 }, true) -- COGNEX DataMan 700
-- read_test({ topology='usb-0000:00:1a.0-1.6.4/input0' }, true)
-- read_test({ vendor=0x05e0, product=0x1200 }, true)  -- Symbol LS2208
-- read_test({ vendor=0x76d, product=0x1 })  -- Toyota Denso GT-10 (barcode reader)
