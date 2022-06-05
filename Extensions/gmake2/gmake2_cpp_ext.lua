if _ACTION ~= "gmake2" then
	return
end

require("gmake2")

local p   = premake
local m   = p.modules.gmake2
local cpp = m.cpp

---
-- Add nasm rule
---

rule("nasm")
	fileExtension(".asm")
	buildoutputs({ "$(OBJDIR)/%{file.objname}.o" })
	buildmessage("$(notdir $<)")
	buildcommands({ "nasm %{premake.modules.gmake2.cpp.asmFileFlags(cfg, file)} -o \"$@\" \"$<\"" })

global(nil)

p.override(cpp, "createRuleTable", function(base, prj)
	base(prj)

	prj._gmake.filesets[".asm"] = "SOURCES"
end)

p.override(cpp, "addRuleFile", function(base, cfg, node)
	local fcfg = fileconfig.getconfig(node, cfg)
	if (fcfg and fcfg.usenasm) or (not fcfg and cfg.usenasm) then
		local rule    = p.global.getRule("nasm")
		local filecfg = fileconfig.getconfig(node, cfg)
		local environ = table.shallowcopy(filecfg.environ)

		if rule.propertydefinition then
			p.rule.prepareEnvironment(rule, environ, cfg)
			p.rule.prepareEnvironment(rule, environ, filecfg)
		end

		local shadowContext = p.context.extent(rule, environ)

		local buildoutputs  = shadowContext.buildoutputs
		local buildmessage  = shadowContext.buildmessage
		local buildcommands = shadowContext.buildcommands
		local buildinputs   = shadowContext.buildinputs

		buildoutputs = p.project.getrelative(cfg.project, buildoutputs)
		if buildoutputs and #buildoutputs > 0 then
			local file = {
				buildoutputs  = buildoutputs,
				source        = node.relpath,
				buildmessage  = buildmessage,
				buildcommands = buildcommands,
				buildinputs   = buildinputs
			}
			table.insert(cfg._gmake.fileRules, file)

			for _, output in ipairs(buildoutputs) do
				cpp.addGeneratedFile(cfg, node, output)
			end
		end
	else
		base(cfg, node)
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

function cpp.asmFileFlags(cfg, file)
	local fcfg    = p.fileconfig.getconfig(file, cfg)
	cfg           = fcfg.config
	local command = "-X" .. errorReport() .. " -f " .. archToNASM(cfg.architecture)

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

	command = command .. " " .. cpp.nasmOptimizeFlags[cfg.optimize]
	return command
end