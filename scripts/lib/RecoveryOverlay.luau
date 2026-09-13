local roblox = require("@lune/roblox")
local luau = require("@lune/luau")

local SOURCE_CLASSES = { ModuleScript = true, Script = true, LocalScript = true }
local OWNED_ROOTS = {
	"ReplicatedStorage/Shared",
	"ServerScriptService/Server",
	"StarterPlayer/StarterPlayerScripts/Client",
}

local function owned(path)
	for _, root in OWNED_ROOTS do
		if path == root or path:sub(1, #root + 1) == root .. "/" then return true end
	end
	return false
end

local function instancePath(instance, dataModel)
	local names = {}
	while instance ~= dataModel do
		table.insert(names, 1, instance.Name)
		instance = instance.Parent
		assert(instance, "Instance is outside the recovery DataModel")
	end
	return table.concat(names, "/")
end

-- Derive the full module list from Rojo, then verify every current source file is
-- represented. Existing scripts must be explicitly mapped; no scripts are deleted.
return function(dataModel, sourceMap, readFile, readDir, isDir, verifyOnly)
	local desired = {}
	local mappedFiles = {}
	local nodes = {}
	local function collect(node, parentPath)
		local path = parentPath == "" and node.name or parentPath .. "/" .. node.name
		assert(not nodes[path], "Duplicate Rojo instance path: " .. path)
		nodes[path] = node
		if SOURCE_CLASSES[node.className] then
			assert(owned(path), "Source mapping is outside reviewed script roots: " .. path)
			local files = node.filePaths or {}
			local sourceFile
			for _, file in files do
				file = file:gsub("\\", "/")
				if file:match("%.luau$") then
					assert(not sourceFile, "Multiple source files map to " .. path)
					assert(file:match("^src/[A-Za-z0-9_./%-]+%.luau$") and not file:find("..", 1, true), "Unsafe source path")
					sourceFile = file
				end
			end
			assert(sourceFile, "No current source for " .. path)
			assert(not mappedFiles[sourceFile], "Source is mapped more than once: " .. sourceFile)
			local source = readFile(sourceFile)
			luau.compile(source)
			mappedFiles[sourceFile] = true
			desired[path] = { node = node, source = source }
		end
		for _, child in node.children or {} do collect(child, path) end
	end
	for _, node in sourceMap.children or {} do collect(node, "") end
	local sourceCount = 0
	local function visit(directory)
		for _, name in readDir(directory) do
			local path = directory .. "/" .. name
			if isDir(path) then visit(path)
			elseif name:match("%.luau$") then
				assert(mappedFiles[path], "Current source is missing from Rojo recovery mapping: " .. path)
				sourceCount += 1
			end
		end
	end
	visit("src")
	assert(sourceCount > 0, "Recovery mapping contains no current source")
	local existing = {}
	local ambiguous = {}
	for _, instance in dataModel:GetDescendants() do
		local path = instancePath(instance, dataModel)
		if existing[path] then ambiguous[path] = true end
		existing[path] = instance
		if instance:IsA("LuaSourceContainer") then
			assert(desired[path], "Unreviewed script in recovery input: " .. path)
			assert(desired[path].node.className == instance.ClassName, "Script class changed: " .. path)
		end
	end
	local function ensure(path)
		assert(not ambiguous[path], "Ambiguous mapped instance path in recovery input: " .. path)
		if existing[path] then
			assert(not nodes[path] or existing[path].ClassName == nodes[path].className, "Mapped ancestor class mismatch: " .. path)
			return existing[path]
		end
		assert(not verifyOnly, "Serialized artifact lacks required instance: " .. path)
		local node = assert(nodes[path], "Missing Rojo ancestor: " .. path)
		assert(owned(path), "Recovery may only add instances inside reviewed script roots: " .. path)
		assert(node.className == "Folder" or SOURCE_CLASSES[node.className], "Unsupported recovery source container: " .. path)
		local parentPath = path:match("^(.*)/[^/]+$")
		local parent = ensure(parentPath)
		local instance = roblox.Instance.new(node.className)
		instance.Name = node.name
		instance.Parent = parent
		existing[path] = instance
		return instance
	end
	local count = 0
	for path, spec in desired do
		local instance = ensure(path)
		assert(instance.ClassName == spec.node.className, "Source instance class mismatch: " .. path)
		if verifyOnly then
			assert(instance.Source == spec.source, "Serialized artifact source differs from current source: " .. path)
		else
			instance.Source = spec.source
		end
		count += 1
	end
	assert(count == sourceCount, "Recovery script inventory does not match all current source files")
	return count
end
