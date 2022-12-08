local lua_51 = [==[
lapi.c
lauxlib.c
lbaselib.c
lcode.c
ldblib.c
ldebug.c
ldo.c
ldump.c
lfunc.c
lgc.c
linit.c
liolib.c
llex.c
lmathlib.c
lmem.c
loadlib.c
lobject.c
lopcodes.c
loslib.c
lparser.c
lstate.c
lstring.c
lstrlib.c
ltable.c
ltablib.c
ltm.c
lundump.c
lvm.c
lzio.c
print.c
bitlib.c
]==]

local lua_52 = [==[
lapi.c
lcode.c
lctype.c
ldebug.c
ldo.c
ldump.c
lfunc.c
lgc.c
llex.c
lmem.c
lobject.c
lopcodes.c
lparser.c
lstate.c
lstring.c
ltable.c
ltm.c
lundump.c
lvm.c
lzio.c
lauxlib.c
lbaselib.c
lbitlib.c
lcorolib.c
ldblib.c
liolib.c
lmathlib.c
loslib.c
lstrlib.c
ltablib.c
loadlib.c
linit.c
]==]

local lua_53 = [==[
lapi.c
lcode.c
lctype.c
ldebug.c
ldo.c
ldump.c
lfunc.c
lgc.c
llex.c
lmem.c
lobject.c
lopcodes.c
lparser.c
lstate.c
lstring.c
ltable.c
ltm.c
lundump.c
lvm.c
lzio.c
lauxlib.c
lbaselib.c
lbitlib.c
lcorolib.c
ldblib.c
liolib.c
lmathlib.c
loslib.c
lstrlib.c
ltablib.c
lutf8lib.c
loadlib.c
linit.c
]==]

local lua_54 = [==[
lapi.c
lcode.c
lctype.c
ldebug.c
ldo.c
ldump.c
lfunc.c
lgc.c
llex.c
lmem.c
lobject.c
lopcodes.c
lparser.c
lstate.c
lstring.c
ltable.c
ltm.c
lundump.c
lvm.c
lzio.c
lauxlib.c
lbaselib.c
lcorolib.c
ldblib.c
liolib.c
lmathlib.c
loadlib.c
loslib.c
lstrlib.c
ltablib.c
lutf8lib.c
linit.c
]==]

local lpeglabel_prefix = "/home/mingo/dev/lua/lpeglabel/"
local lpeglabel = [==[
lplvm.c
lplcap.c
lpltree.c
lplcode.c
lplprint.c
]==]

local included = {}
local inc_sys = {}
local inc_sys_count = 0
local out = io.stdout

function CopyWithInline(prefix, filename)
	if included[filename] then return end
	included[filename] = true
	print('//--Start of', filename);
	--if(filename:match("luac?.c"))
	local inp = assert(io.open(prefix .. filename, "r"))
	for line in inp:lines() do
		if line:match('#define LUA_USE_READLINE') then
			out:write("//" .. line .. "\n")
		else
			local inc = line:match('#include%s+(["<].-)[">]')
			if inc  then
				out:write("//" .. line .. "\n")
				if inc:sub(1,1) == '"' then
					CopyWithInline(prefix, inc:sub(2))
				else
					local fn = inc:sub(2)
					if inc_sys[fn] == null then
						inc_sys_count = inc_sys_count +1
						inc_sys[fn] = inc_sys_count
					end
				end
			else
				out:write(line .. "\n")
			end
		end
      end
	print('//--End of', filename);
end

print([==[
#include "cosmopolitan.h"
#define loslib_c
#define lua_c
#define lobject_c
#define LUA_USE_MKSTEMP
#define LUA_USE_POSIX
]==])

--local prefix = '/home/mingo/dev/lua/lua-5.1.5/src/'; local lua_files = lua_51;
--local prefix = '/home/mingo/dev/lua/lua-5.2.4/src/'; local lua_files = lua_52;
--local prefix = '/home/mingo/dev/lua/lua-5.3.6/src/'; local lua_files = lua_53;
local prefix = '/home/mingo/dev/lua/lua-5.4.4/src/'; local lua_files = lua_54;
--for filename in lua_files:gmatch('#include "([^"]+)"') do
for filename in lua_files:gmatch('([^\n]+)') do
	CopyWithInline(prefix, filename);
end
print('#ifdef WITH_LPEGLABEL');
#define Instruction Instruction_lpeg
#define match match_lpeg
#define utf8_decode utf8_decode_lpeg
#define finaltarget finaltarget_lpeg
#define codenot codenot_lpeg
for filename in lpeglabel:gmatch('([^\n]+)') do
	CopyWithInline(lpeglabel_prefix, filename);
end
#undef codenot
#undef finaltarget
#undef utf8_decode
#undef match
#undef Instruction
print('#endif //WITH_LPEGLABEL');
print('#ifdef MAKE_LUA_CMD');
CopyWithInline(prefix, "lua.c");
print('#endif //MAKE_LUA_CMD');
print('#ifdef MAKE_LUAC_CMD');
CopyWithInline(prefix, "luac.c");
print('#endif //MAKE_LUAC_CMD');
print('#ifdef MAKE_LUA_WASM');
CopyWithInline("./", "lua-playground.c");
print('#endif //MAKE_LUA_WASM');
for k, v in pairs(inc_sys) do print("#include <" .. k .. "> //" .. v ) end