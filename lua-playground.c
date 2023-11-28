#include <emscripten.h>
#include <stdio.h>
#include <string.h>

#include <lua.h>

EM_JS(void, switch_output, (const char* which), {
    output = UTF8ToString(which);
})

EM_JS(void, set_result, (const char* which, int value), {
    result_name = UTF8ToString(which);
    result[result_name] = value;
})

/*
** Message handler used to run all chunks
*/
static int msghandler (lua_State *L) {
  const char *msg = lua_tostring(L, 1);
  if (msg == NULL) {  /* is error object not a string? */
    if (luaL_callmeta(L, 1, "__tostring") &&  /* does it have a metamethod */
        lua_type(L, -1) == LUA_TSTRING)  /* that produces a string? */
      return 1;  /* that is the message */
    else
      msg = lua_pushfstring(L, "(error object is a %s value)",
                               luaL_typename(L, 1));
  }
  luaL_traceback(L, L, msg, 1);  /* append a standard traceback */
  return 1;  /* return the traceback */
}

int run_lua(const char *script, const char *input)
{
	//use of Javascript string.length can't be used for utf8
	size_t script_size = strlen(script);
	size_t input_size = strlen(input);
	int err = 0; // currently, zero is always returned; result codes for each part
		 // are sent to JS via set_result()

	// default result values (-1 indicates we didn't reach a part)
	int compile_result = -1;
	int run_result = -1;
	int ast_result = -1;
	int profile_result = -1;

	lua_State* lua = luaL_newstate();
	luaL_openlibs(lua);
#ifdef WITH_LPEGLABEL
	luaL_requiref(lua, "lpeglabel", luaopen_lpeglabel, 1);
	lua_pop(lua, 1);  /* remove lib */
#endif
	lua_pushcfunction(lua, msghandler);

	switch_output("compile_status");

	lua_newtable(lua);
	lua_pushlstring(lua, input, input_size);
	lua_rawseti (lua, -2, 1);
	lua_setglobal(lua, "arg");

	compile_result = luaL_loadbuffer(lua, script, script_size, "@source.lua");

	if(compile_result == LUA_OK) {
		switch_output("run_status");
		run_result = lua_pcall(lua, 0, LUA_MULTRET, lua_gettop(lua) - 1);
		if(run_result != LUA_OK) {
			switch_output("compile_status");
			printf("%s\n", lua_tostring(lua, -1));
		}
	}
	else {
		printf("%s\n", lua_tostring(lua, -1));
	}

	lua_close(lua);
	set_result("compile", compile_result);
	set_result("run", run_result);
	set_result("ast", ast_result);
	set_result("profile", profile_result);
	return err;
}
