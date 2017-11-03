/*
 * luaevdev - comfortable access to Linux input subsystem(evdev) from Lua
 *
 * Copyright (C) 2014 Petr Stetiar <ynezz@true.cz>, Gaben spol. s r.o.
 *
 * Permission is hereby granted, free of charge, to any person obtaining a
 * copy of this software and associated documentation files (the "Software"),
 * to deal in the Software without restriction, including without limitation
 * the rights to use, copy, modify, merge, publish, distribute, sublicense,
 * and/or sell copies of the Software, and to permit persons to whom the
 * Software is furnished to do so, subject to the following conditions:
 * 
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 * 
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 * FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
 * DEALINGS IN THE SOFTWARE.
 *
 */
#include <sys/ioctl.h>
#include <sys/types.h>
#include <linux/input.h>

#include <errno.h>
#include <dirent.h>
#include <fcntl.h>
#include <unistd.h>
#include <stdint.h>
#include <stdio.h>
#include <string.h>
#include <stdlib.h>

#include <lauxlib.h>

#include "evdev-generated.h"


#define MODNAME		"evdev_core"
#define METANAME	MODNAME ".meta"
#define MODVERSION	"0.0.1"

#define LUA_TPUSH_STR(L, s, v) do { \
	lua_pushstring(L, s); \
	lua_pushstring(L, v); \
	lua_rawset(L, -3); \
} while (0);

#define LUA_TPUSH_NUM(L, s, v) do { \
	lua_pushstring(L, s); \
	lua_pushnumber(L, v); \
	lua_rawset(L, -3); \
} while (0);

struct evdev_t {
	int fd;
	char *device;
};

static int err(lua_State *L, const char *where, int err)
{
	static char buf[2048] = {0};
	snprintf(buf, sizeof(buf), "%s error: %s (%d)", where, strerror(err), err);
	lua_pushnil(L);
	lua_pushstring(L, buf);
	return 2;
}

static const char* strkey(unsigned int code)
{
	struct key_t *k;

	for (k = key_table; k->name != NULL; k++)
		if (k->code == code)
			return k->name;

	return NULL;
}

static const char* strevent(unsigned int code)
{
	struct event_t *e;

	for (e = event_table; e->name != NULL; e++)
		if (e->code == code)
			return e->name;

	return NULL;
}

static int tv_diff(struct timeval *t1, struct timeval *t2)
{
	if (t1->tv_usec < t2->tv_usec)
		return (((t1->tv_usec + 1000000) - t2->tv_usec) / 1000) + ((t1->tv_sec - 1 - t2->tv_sec) * 1000);
	else
		return ((t1->tv_usec - t2->tv_usec) / 1000) + ((t1->tv_sec - t2->tv_sec) * 1000);
}

static void set_timeout(struct timeval *tv, unsigned int msec)
{
	tv->tv_sec = msec / 1000;
	tv->tv_usec = msec % 1000;
	if (tv->tv_usec > 1000000) {
		tv->tv_sec++;
		tv->tv_usec %= 100000;
	}
}

static int evdev_lua_strkey(lua_State *L)
{
	lua_pushstring(L, strkey(luaL_checkint(L, 1)));
	return 1;
}

static int evdev_lua_strevent(lua_State *L)
{
	lua_pushstring(L, strevent(luaL_checkint(L, 1)));
	return 1;
}

static int evdev_lua_open(lua_State *L)
{
	int _errno;
	struct evdev_t *e;
	const char *device = luaL_checkstring(L, 1);

	if ((e = lua_newuserdata(L, sizeof(*e))) != NULL) {
		e->device = strdup(device);
		if ((e->fd = open(e->device, O_RDONLY)) == -1) {
			_errno = errno;
			return err(L, "open", _errno);
		}

		luaL_getmetatable(L, METANAME);
		lua_setmetatable(L, -2);
		return 1;
	}

	lua_pushnil(L);
	lua_pushstring(L, "lua_newuserdata() failed");
	return 2;
}

static int evdev_lua_read(lua_State *L)
{
	int ret;
	int _errno;
	fd_set set;
	unsigned int i;
	struct timeval tv;
	struct timeval tv_end;
	struct timeval tv_start;
	struct input_event *ev;

	struct evdev_t *e = luaL_checkudata(L, 1, METANAME);
	int count = luaL_optint(L, 2, 64);
	unsigned int timeout = (unsigned int) luaL_optnumber(L, 3, 0);

	ev = (struct input_event *) malloc(sizeof(*ev) * count);
	if (!ev) {
		_errno = errno;
		return err(L, "malloc", _errno);
	}

	FD_ZERO(&set);
	FD_SET(e->fd, &set);
	gettimeofday(&tv_start, NULL);

	if (timeout > 0) {
		set_timeout(&tv, timeout);
		ret = select(e->fd+1, &set, NULL, NULL, &tv);
		if (ret < 0) {
			_errno = errno;
			return err(L, "select", _errno);
		}

		if (!FD_ISSET(e->fd, &set)) {
			lua_pushnil(L);
			lua_pushstring(L, "timeout");
			return 2;
		}
	}

	ret = read(e->fd, ev, sizeof(*ev) * count);
	if (ret < (int) sizeof(*ev)) {
		lua_pushnil(L);
		lua_pushstring(L, "short read error");
		return 2;
	}

	gettimeofday(&tv_end, NULL);

	lua_newtable(L);
	LUA_TPUSH_NUM(L, "duration", tv_diff(&tv_end, &tv_start));
	lua_pushstring(L, "events");
	lua_newtable(L);

	for (i = 0; i < ret / sizeof(*ev); i++) {
		int msecs = (ev[i].time.tv_sec * 1000) + (ev[i].time.tv_usec / 1000);
		lua_pushnumber(L, i+1);
		lua_newtable(L);

		LUA_TPUSH_NUM(L, "time", msecs);
		LUA_TPUSH_NUM(L, "type", ev[i].type);
		LUA_TPUSH_NUM(L, "code", ev[i].code);
		LUA_TPUSH_NUM(L, "value", ev[i].value);

		lua_rawset(L, -3);
	}
	lua_rawset(L, -3);

	return 1;
}

static int evdev_lua_list(lua_State *L)
{
	int fd;
	DIR *dir;
	int _errno;
	char dev[32];
	char name[32];
	int count = 0;
	struct dirent *dp;
	char topology[256];
	unsigned short id[4];

	dir = opendir("/dev/input");
	_errno = errno;
	if (!dir) {
		_errno = errno;
		return err(L, "opendir", _errno);
	}

	lua_newtable(L);
	while ((dp = readdir(dir)) != NULL) {
		if (dp->d_name && !strncmp(dp->d_name, "event", 5)) {
			snprintf(dev, sizeof(dev), "/dev/input/%s", dp->d_name);
			fd = open(dev, O_RDONLY);
			if (fd == -1)
				continue;

			if (ioctl(fd, EVIOCGNAME(32), name) < 0) {
				close(fd);
				continue;
			}

			if (ioctl(fd, EVIOCGID, id) < 0) {
				close(fd);
				continue;
			}

			lua_pushnumber(L, ++count);
			lua_newtable(L);

			if (ioctl(fd, EVIOCGPHYS(sizeof(topology)), topology) < 0) {
				LUA_TPUSH_STR(L, "topology", "");
			} else {
				LUA_TPUSH_STR(L, "topology", topology);
			}

			LUA_TPUSH_STR(L, "dev", dev);
			LUA_TPUSH_STR(L, "name", name);
			LUA_TPUSH_NUM(L, "vendor", id[ID_VENDOR]);
			LUA_TPUSH_NUM(L, "product", id[ID_PRODUCT]);

			lua_rawset(L, -3);
		}
	}

	closedir(dir);
	return 1;
}

static int evdev_lua_gc(lua_State *L)
{
	struct evdev_t *e = luaL_checkudata(L, 1, METANAME);
	if (!e->device)
		return 0;

	close(e->fd);
	free(e->device);
	e->device = NULL;
	return 0;
}

static int evdev_lua_fd(lua_State *L)
{
	struct evdev_t *e = luaL_checkudata(L, 1, METANAME);
	lua_pushinteger(L, e->fd);
	return 1;
}

static void push_constants(lua_State *L)
{
	struct key_t *k;
	struct event_t *e;

	for (k = key_table; k->name != NULL; k++)
		LUA_TPUSH_NUM(L, k->name, k->code);

	for (e = event_table; e->name != NULL; e++)
		LUA_TPUSH_NUM(L, e->name, e->code);
}

static int evdev_lua_key_state(lua_State *L)
{
	int mask = 0;
	int key_bit = 0;
	uint8_t buf[KEY_MAX/8 + 1] = {0};
	int key = luaL_checkint(L, 2);
	struct evdev_t *e = luaL_checkudata(L, 1, METANAME);

	ioctl(e->fd, EVIOCGKEY(sizeof(buf)), buf);
	key_bit = buf[key/8];
	mask = 1 << (key % 8);
	lua_pushinteger(L, (key_bit & mask) ? 1 : 0);
	return 1;
}

static const luaL_Reg evdev[] = {
	{ "open", evdev_lua_open },
	{ "list", evdev_lua_list },
	{ "read", evdev_lua_read },
	{ "key_string", evdev_lua_strkey },
	{ "key_state", evdev_lua_key_state },
	{ "event_string", evdev_lua_strevent },
	{ "fd", evdev_lua_fd },
	{ "close", evdev_lua_gc },
	{ "__gc", evdev_lua_gc },
	{ NULL, NULL },
};

int luaopen_evdev_core(lua_State *L)
{
	/* create metatable */
	luaL_newmetatable(L, METANAME);

	/* metatable.__index = metatable */
	lua_pushvalue(L, -1);
	lua_setfield(L, -2, "__index");

	/* fill metatable */
	luaL_register(L, NULL, evdev);
	lua_pop(L, 1);

	/* create module */
	luaL_register(L, MODNAME, evdev);
	push_constants(L);
	LUA_TPUSH_STR(L, "_VERSION", MODVERSION);

	return 0;
}
