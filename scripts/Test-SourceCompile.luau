local fs = require("@lune/fs")
local luau = require("@lune/luau")
local count = 0
local function visit(path)
	local names = fs.readDir(path)
	table.sort(names)
	for _, name in names do
		local child = path .. "/" .. name
		if fs.isDir(child) then
			visit(child)
		elseif name:match("%.luau$") then
			local ok, message = pcall(luau.compile, fs.readFile(child))
			assert(ok, child .. ": " .. tostring(message))
			count += 1
		end
	end
end
visit("src")
assert(count > 0, "No source modules compiled")
print(string.format("PASS: compiled %d actual source files with the Luau compiler", count))
