require("vstudio")

local p          = premake
local m          = p.vstudio.vc2010
local project    = p.project
local fileconfig = p.fileconfig

m.categories.Nasm = {
	name = "Nasm",
	extensions = ".asm",
	priority = 9,
	
	emitFiles = function(prj, group)
		local fileCfgFunc = function(fcfg, condition)
			if fcfg then
				return {
					m.excludedFromBuild,
					m.buildNASMCommand,
					m.buildNASMOutputs,
					m.linkNASMObjects
				}
			else
				return {
					m.excludedFromBuild
				}
			end
		end
		
		m.emitFiles(prj, group, "CustomBuild", nil, fileCfgFunc)
	end,
	
	emitFilter = function(prj, group)
		m.filterGroup(prj, group, "CustomBuild")
	end
}

p.override(m, "categorizeFile", function(base, prj, file)
	for cfg in project.eachconfig(prj) do
		local fcfg = fileconfig.getconfig(file, cfg)
		if fcfg then
			if fcfg.usenasm or (cfg.usenasm and fcfg.extension == ".asm") then
				return m.categories.Nasm
			end
		end
	end
	
	return base(prj, file)
end)

local function archToNASM(arch)
	if arch == "x86" then
		return "win32"
	else
		return "win64"
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

function m.buildNASMCommand(fcfg, condition)
	local cfg = fcfg.config
	local command = "nasm -Xvc -f " .. archToNASM(cfg.architecture)
	
	for _, inc in ipairs(cfg.includedirs) do
		command = command .. " -i \"" .. inc .. "\""
	end
	
	for _, def in ipairs(cfg.defines) do
		command = command .. " \"-d" .. def .. "\""
	end
	for _, udef in ipairs(cfg.undefines) do
		command = command .. " \"-u" .. udef .. "\""
	end
	
	if cfg.symbols == "On" then
		command = command .. " -g"
	end
	
	command = command .. " " .. m.nasmOptimizeFlags[cfg.optimize]
	
	m.element("Command", condition, "%s -o \"%s/%s.obj\" \"%s\"", command, cfg.objdir, fcfg.basename, fcfg.abspath)
end

function m.buildNASMOutputs(fcfg, condition)
	m.element("Outputs", condition, "%s/%s.obj", fcfg.config.objdir, fcfg.basename)
end

function m.linkNASMObjects(fcfg, condition)
	m.element("LinkObjects", condition, "true")
end