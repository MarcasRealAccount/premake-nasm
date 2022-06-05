local p   = premake
local api = p.api

p.extensions.nasm = { _VERSION = "1.0.0" }

api.register({
	name    = "usenasm",
	scope   = "config",
	kind    = "boolean",
	default = false
})

return true