# TODO: Check for env or command line "ZMK_CONFIG" setting.
#  * That directory should load
#    * defconfigs,
#    * .conf file,
#    * single overlay,
#    * or per board/shield.

cmake_minimum_required(VERSION 3.15)

get_property(cached_user_config_value CACHE ZMK_CONFIG PROPERTY VALUE)

set(user_config_cli_argument ${cached_user_config_value}) # Either new or old
if(user_config_cli_argument STREQUAL CACHED_ZMK_CONFIG)
	# We already have a CACHED_ZMK_CONFIG so there is no new input on the CLI
  unset(user_config_cli_argument)
endif()

set(user_config_app_cmake_lists ${ZMK_CONFIG})
if(cached_user_config_value STREQUAL ZMK_CONFIG)
	# The app build scripts did not set a default, The ZMK_CONFIG we are
  # reading is the cached value from the CLI
  unset(user_config_app_cmake_lists)
endif()

if(CACHED_ZMK_CONFIG)
  # Warn the user if it looks like he is trying to change the user_config
  # without cleaning first
  if(user_config_cli_argument)
	  if(NOT (CACHED_ZMK_CONFIG STREQUAL user_config_cli_argument))
      message(WARNING "The build directory must be cleaned pristinely when changing user ZMK config")
    endif()
  endif()

  set(ZMK_CONFIG ${CACHED_ZMK_CONFIG})
elseif(user_config_cli_argument)
	set(ZMK_CONFIG ${user_config_cli_argument})

elseif(DEFINED ENV{ZMK_CONFIG})
	set(ZMK_CONFIG $ENV{ZMK_CONFIG})

elseif(user_config_app_cmake_lists)
	set(ZMK_CONFIG ${user_config_app_cmake_lists})
endif()

# Store the selected user_config in the cache
set(CACHED_ZMK_CONFIG ${ZMK_CONFIG} CACHE STRING "Selected user ZMK config")

if (ZMK_CONFIG)
	set(ENV{ZMK_CONFIG} "${ZMK_CONFIG}")
	if(EXISTS ${ZMK_CONFIG}/boards)
		message(STATUS "Adding ZMK config directory as board root: ${ZMK_CONFIG}")
		list(APPEND BOARD_ROOT ${ZMK_CONFIG})
	endif()
	if(EXISTS ${ZMK_CONFIG}/dts)
		message(STATUS "Adding ZMK config directory as DTS root: ${ZMK_CONFIG}")
		list(APPEND DTS_ROOT ${ZMK_CONFIG})
	endif()
endif()

foreach(root ${BOARD_ROOT})
	if (EXISTS "${root}/boards/${BOARD}.overlay")
		list(APPEND ZMK_DTC_FILES "${root}/boards/${BOARD}.overlay")
	endif()
	find_path(BOARD_DIR
	    NAMES ${BOARD}_defconfig
	    PATHS ${root}/boards/*/*
	    NO_DEFAULT_PATH
		)
	if(BOARD_DIR)
		list(APPEND KEYMAP_DIRS ${BOARD_DIR})
	endif()

	if(DEFINED SHIELD)
		find_path(shields_refs_list
		    NAMES ${SHIELD}.overlay
		    PATHS ${root}/boards/shields/*
		    NO_DEFAULT_PATH
		    )
		foreach(shield_path ${shields_refs_list})
			get_filename_component(SHIELD_DIR ${shield_path} NAME)
			list(APPEND KEYMAP_DIRS ${shield_path})
		endforeach()
	endif()
endforeach()

if (ZMK_CONFIG)
	if (EXISTS ${ZMK_CONFIG})
		message(STATUS "ZMK Config directory: ${ZMK_CONFIG}")
		list(APPEND DTS_ROOT ${ZMK_CONFIG})
		list(PREPEND KEYMAP_DIRS "${ZMK_CONFIG}")

		if (SHIELD)
			message(STATUS "Board: ${BOARD}, ${BOARD_DIR}, ${SHIELD}, ${SHIELD_DIR}")
			list(APPEND overlay_candidates "${ZMK_CONFIG}/${SHIELD_DIR}.overlay")
			list(APPEND overlay_candidates "${ZMK_CONFIG}/${SHIELD_DIR}_${BOARD}.overlay")
			list(APPEND overlay_candidates "${ZMK_CONFIG}/${SHIELD}_${BOARD}.overlay")
			list(APPEND overlay_candidates "${ZMK_CONFIG}/${SHIELD}.overlay")
			list(APPEND config_candidates "${ZMK_CONFIG}/${SHIELD_DIR}.conf")
			list(APPEND config_candidates "${ZMK_CONFIG}/${SHIELD_DIR}_${BOARD}.conf")
			list(APPEND config_candidates "${ZMK_CONFIG}/${SHIELD}_${BOARD}.conf")
			list(APPEND config_candidates "${ZMK_CONFIG}/${SHIELD}.conf")
		endif()

		# TODO: Board revisions?
		list(APPEND overlay_candidates "${ZMK_CONFIG}/${BOARD}.overlay")
		list(APPEND overlay_candidates "${ZMK_CONFIG}/default.overlay")
		list(APPEND config_candidates "${ZMK_CONFIG}/${BOARD}.conf")
		list(APPEND config_candidates "${ZMK_CONFIG}/default.conf")

		foreach(overlay ${overlay_candidates})
			if (EXISTS "${overlay}")
				message(STATUS "ZMK Config devicetree overlay: ${overlay}")
				list(APPEND ZMK_DTC_FILES "${overlay}")
				break()
			endif()
		endforeach()

		foreach(conf ${config_candidates})
			if (EXISTS "${conf}")
				message(STATUS "ZMK Config Kconfig: ${conf}")
				set(CONF_FILE "${conf}")
				break()
			endif()
		endforeach()
	else()
		message(WARNING "Unable to locate ZMK config at: ${ZMK_CONFIG}")
	endif()
endif()


if(NOT KEYMAP_FILE)
	foreach(keymap_dir ${KEYMAP_DIRS})
		foreach(keymap_prefix ${SHIELD} ${SHIELD_DIR} ${BOARD} ${BOARD_DIR})
			if (EXISTS ${keymap_dir}/${keymap_prefix}.keymap)
				set(KEYMAP_FILE "${keymap_dir}/${keymap_prefix}.keymap" CACHE STRING "Selected keymap file")
				message(STATUS "Using keymap file: ${KEYMAP_FILE}")
				break()
			endif()
		endforeach()
	endforeach()
endif()

if (NOT KEYMAP_FILE)
	message(FATAL_ERROR "Failed to locate keymap file!")
endif()

list(APPEND ZMK_DTC_FILES ${KEYMAP_FILE})

if (ZMK_DTC_FILES)
	string(REPLACE ";" " " DTC_OVERLAY_FILE "${ZMK_DTC_FILES}")
endif()

# 예시: 트랙볼 관련 파일 처리
if (DEFINED SHIELD)
    # 트랙볼 관련 파일 경로 설정 (예시)
    set(TRACKBALL_INCLUDE_DIR "${ZMK_CONFIG}/dt-bindings/zmk")

    # 트랙볼 관련 파일 포함 디렉토리 추가
    target_include_directories(app PRIVATE ${TRACKBALL_INCLUDE_DIR})

    # 트랙볼 관련 소스 파일 추가
    target_sources(app PRIVATE ${TRACKBALL_INCLUDE_DIR}/trackball_pim447.h)

    # 다른 필요한 설정 추가 가능
    # target_sources_ifdef(CONFIG_ZMK_TRACKBALL app PRIVATE ${TRACKBALL_INCLUDE_DIR}/trackball.c)
endif()
