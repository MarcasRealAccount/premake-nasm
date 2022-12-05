if _ACTION ~= "cmake" then
	return
end

local p = premake

if not p.extensions or not p.extensions.cmake or not p.extensions.cmake.project then
	return
end

local cmake = p.extensions.cmake
local m     = cmake.project

p.override(m, "configProps", function(base, prj)
	local props = base(prj)
	table.insert(props, m.nasmFlags)
	return props
end)

p.override(cmake.workspace, "enableLanguages", function(base, wks)
	base(wks)
	local enabledLanguages = {}
	for prj in p.workspace.eachproject(wks) do
		for cfg in p.project.eachconfig(prj) do
			if cfg.usenasm then
				enabledLanguages["ASM_NASM"] = true
			end
		end
	end
	for lang, _ in pairs(enabledLanguages) do
		p.w("enable_language(%s", lang)
	end
end)

local target = os.target()

local function archToNASM(arch)
	if target == "windows" then
		if arch == "x86" then
			return "win32"
		else
			return "win64"
		end
	elseif target == "macosx" then
		if arch == "x86" then
			return "macho32"
		else
			return "macho64"
		end
	else
		if arch == "x86" then
			return "elf32"
		else
			return "elf64"
		end
	end
end

local function errorReport()
	if target == "windows" then
		return "vc"
	else
		return "gnu"
	end
end

m.nasmOptimizeFlags = {
	["Off"]   = "-O0",
	["On"]    = "-O1",
	["Debug"] = "-O1",
	["Size"]  = "-Ox",
	["Speed"] = "-Ox",
	["Full"]  = "-Ox"
}

function m.nasmFlags(prj, cfg)
	if not cfg.usenasm then
		return
	end

	local flags = "-X" .. errorReport()
	for _, def in ipairs(cfg.defines) do
		flags = flags .. " \"-d" .. def .. "\""
	end
	for _, udef in ipairs(cfg.undefines) do
		flags = flags .. " \"-u" .. udef .. "\""
	end

	if cfg.symbols == "On" then
		flags = flags .. " -g"
	end

	flags = flags .. " " .. m.nasmOptimizeFlags[cfg.optimize]

	p.push("set(CMAKE_ASM_NASM_FLAGS_%s", cmake.common.configName(cfg, #prj.workspace.platforms > 1):upper())
	p.w("\"%s\"", cmake.common.escapeStrings(flags))
	p.pop(")")
end
