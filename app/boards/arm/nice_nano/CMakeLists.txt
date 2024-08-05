set_property(GLOBAL APPEND PROPERTY extra_post_build_commands
  COMMAND ${PYTHON_EXECUTABLE} ${ZEPHYR_BASE}/../tools/uf2/utils/uf2conv.py
  -c 
  -b 0x26000
  -f 0xADA52840
  -o ${PROJECT_BINARY_DIR}/${CONFIG_KERNEL_BIN_NAME}.uf2
  ${PROJECT_BINARY_DIR}/${CONFIG_KERNEL_BIN_NAME}.bin
)


cmake_minimum_required(VERSION 3.13.1)
project(my_project_name VERSION 1.0)
find_package(Zephyr REQUIRED HINTS $ENV{ZEPHYR_BASE})
set(BOARD nice_nano_v2)
include($ENV{ZEPHYR_BASE}/cmake/app/boilerplate.cmake NO_POLICY_SCOPE)
project(my_zephyr_project)
target_sources(app PRIVATE src/main.c)
set(CONFIG_GPIO y)
include_directories(${ZEPHYR_BASE}/include/generated)
add_executable(my_app src/main.c)
target_link_libraries(my_app PRIVATE zephyr_interface)
target_compile_options(app PRIVATE -Wall -Werror)
