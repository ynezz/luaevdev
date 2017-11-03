function push(t, k, c) t[#t+1] = { key = k, code = c }  end
function err(...) io.stderr:write(string.format(...)) end
function out(...) io.stdout:write(string.format(...)) end

function parse(filename)
	local t = {}
	t.keys = {}
	t.events = {}

	for line in io.lines(arg[1]) do
		key, code = line:match("#define%s*(EV_[%w_]*)%s*([x%x]*)%s*.*")
		if key and tonumber(code) then
			push(t.events, key, code)
		end

		key, code = line:match("#define%s*([KB][ET][YN]_[%w_]*)%s*([x%x]*)%s*.*")
		if key and tonumber(code) then
			push(t.keys, key, code)
		end
	end

	return t
end

function generate(t)
	out("/* designated riot area, keep away */\n\n")

	-- events
	out("struct event_t {\n\tchar *name;\n\tunsigned int code;\n} event_table[] = {\n")
	for _, v in pairs(t.events) do
		out('\t{ "%s", %s },\n', v.key, v.code)
	end
	out("\t{ NULL, 0\t},\n};\n\n")

	-- keys
	out("struct key_t {\n\tchar *name;\n\tunsigned int code;\n} key_table[] = {\n")
	for _, v in pairs(t.keys) do
		out('\t{ "%s", %s },\n', v.key, v.code)
	end
	out("\t{ NULL, 0\t},\n};\n")
end

function main()
	if #arg ~= 1 then
		err("usage: lua genheader.lua <path/to/linux/input.h>\n")
		os.exit(1)
	end

	generate(parse(arg[1]))
end

main()
os.exit(0)
