cmake_minimum_required(VERSION 3.1)

PROJECT(evdev C)

SET(CMAKE_INSTALL_PREFIX /)

ADD_DEFINITIONS(-Os -Wall -Werror -Wextra --std=gnu99 -g3)

FIND_PACKAGE(Lua51 REQUIRED)
IF(NOT LUA_CPATH)
	EXECUTE_PROCESS(
		COMMAND  lua -e "for k in string.gmatch(package.cpath .. \";\", \"([^;]+)/..so;\") do if k:sub(1,1) == \"/\" then print(k) break end end"
		OUTPUT_VARIABLE LUA_CPATH
		RESULT_VARIABLE LUA_CHECK_RES
		OUTPUT_STRIP_TRAILING_WHITESPACE
	)

	IF(NOT ${LUA_CHECK_RES} EQUAL 0 OR ${LUA_CPATH} EQUAL "")
		MESSAGE(SEND_ERROR "Lua was not found on your system")
	ENDIF()
ENDIF()

IF(NOT LUA_PATH)
	EXECUTE_PROCESS(
		COMMAND  lua -e "for k in string.gmatch(package.path .. \";\", \"([^;]+)/..lua;\") do if k:sub(1,1) == \"/\" then print(k) break end end"
		OUTPUT_VARIABLE LUA_PATH
		RESULT_VARIABLE LUA_CHECK_RES
		OUTPUT_STRIP_TRAILING_WHITESPACE
	)

	IF(NOT ${LUA_CHECK_RES} EQUAL 0 OR ${LUA_PATH} EQUAL "")
		MESSAGE(SEND_ERROR "Lua was not found on your system")
	ENDIF()
ENDIF()


EXECUTE_PROCESS(
	COMMAND lua ${CMAKE_SOURCE_DIR}/genheader.lua /usr/include/linux/input.h
	OUTPUT_FILE ${CMAKE_CURRENT_SOURCE_DIR}/evdev-generated.h
	RESULT_VARIABLE LUA_GENHEADER_RES)

IF(NOT ${LUA_GENHEADER_RES} EQUAL 0)
	MESSAGE(SEND_ERROR "There was a problem generating header file evdev-generated.h from linux/input.h")
ENDIF()

INCLUDE_DIRECTORIES(${LUA_INCLUDE_DIR})
ADD_LIBRARY(evdev MODULE evdev_core.c)
SET_TARGET_PROPERTIES(evdev PROPERTIES
	OUTPUT_NAME evdev_core
	PREFIX ""
)
TARGET_LINK_LIBRARIES(evdev dl ${LUA_LIBRARIES})

INSTALL(TARGETS evdev
	LIBRARY DESTINATION ${LUA_CPATH}
)

INSTALL(FILES "${CMAKE_SOURCE_DIR}/evdev.lua"
         DESTINATION ${LUA_PATH})

