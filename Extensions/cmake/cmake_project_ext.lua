if _ACTION ~= "cmake" then
	return
end

local p = premake

if not p.extensions or not p.extensions.cmake or not p.extensions.cmake.project then
	return
end

local cmake = p.extensions.cmake
local m     = cmake.project

table.insert(m.props, 1, m.enableNASM)
table.insert(m.configProps, m.nasmFlags)

function m.enableNASM(prj)
	p.w("enable_language(ASM_NASM)")
end

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