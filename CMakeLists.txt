cmake_minimum_required(VERSION 3.20)

project(firmware C ASM)

set(CMAKE_C_STANDARD 11)
set(CMAKE_C_STANDARD_REQUIRED ON)
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

set(MCU_DEVICE STM32F103xB)
set(LINKER_SCRIPT "${CMAKE_SOURCE_DIR}/STM32F103C8Tx_FLASH.ld")

set(CMSIS_CORE_INCLUDE
  "${CMAKE_SOURCE_DIR}/Drivers/CMSIS/Core/CMSIS/Core/Include")
set(CMSIS_DEVICE_INCLUDE
  "${CMAKE_SOURCE_DIR}/Drivers/CMSIS/Device/ST/STM32F1xx/Include")
set(HAL_INCLUDE
  "${CMAKE_SOURCE_DIR}/Drivers/STM32F1xx_HAL_Driver/Inc")
set(HAL_LEGACY_INCLUDE
  "${CMAKE_SOURCE_DIR}/Drivers/STM32F1xx_HAL_Driver/Inc/Legacy")

# HAL 最小模块集：工程内始终编译，main 随时可改用 HAL API
set(HAL_SOURCES
  Drivers/STM32F1xx_HAL_Driver/Src/stm32f1xx_hal.c
  Drivers/STM32F1xx_HAL_Driver/Src/stm32f1xx_hal_cortex.c
  Drivers/STM32F1xx_HAL_Driver/Src/stm32f1xx_hal_dma.c
  Drivers/STM32F1xx_HAL_Driver/Src/stm32f1xx_hal_flash.c
  Drivers/STM32F1xx_HAL_Driver/Src/stm32f1xx_hal_flash_ex.c
  Drivers/STM32F1xx_HAL_Driver/Src/stm32f1xx_hal_gpio.c
  Drivers/STM32F1xx_HAL_Driver/Src/stm32f1xx_hal_gpio_ex.c
  Drivers/STM32F1xx_HAL_Driver/Src/stm32f1xx_hal_pwr.c
  Drivers/STM32F1xx_HAL_Driver/Src/stm32f1xx_hal_rcc.c
  Drivers/STM32F1xx_HAL_Driver/Src/stm32f1xx_hal_rcc_ex.c
)

# 自写业务仅 main.c；其余为 ST 官方源码/模板
add_executable(${PROJECT_NAME}
  Core/Src/main.c
  Drivers/CMSIS/Device/ST/STM32F1xx/Source/Templates/system_stm32f1xx.c
  startup_stm32f103xb.s
  ${HAL_SOURCES}
)

target_include_directories(${PROJECT_NAME} PRIVATE
  Core/Inc
  ${CMSIS_CORE_INCLUDE}
  ${CMSIS_DEVICE_INCLUDE}
  ${HAL_INCLUDE}
  ${HAL_LEGACY_INCLUDE}
)

target_compile_definitions(${PROJECT_NAME} PRIVATE
  USE_HAL_DRIVER
  ${MCU_DEVICE}
)

target_compile_options(${PROJECT_NAME} PRIVATE
  -Wall
  -Wextra
  -ffunction-sections
  -fdata-sections
  -fno-common
  $<$<CONFIG:Debug>:-Og;-g3>
  $<$<CONFIG:Release>:-Os>
)

target_link_options(${PROJECT_NAME} PRIVATE
  -T${LINKER_SCRIPT}
  -Wl,--gc-sections
  -Wl,-Map=$<TARGET_FILE_DIR:${PROJECT_NAME}>/${PROJECT_NAME}.map
  --specs=nano.specs
  --specs=nosys.specs
)


set_target_properties(${PROJECT_NAME} PROPERTIES
  SUFFIX ".elf"
  LINK_DEPENDS "${LINKER_SCRIPT}"
)

find_program(CMAKE_OBJCOPY arm-none-eabi-objcopy REQUIRED)
find_program(CMAKE_SIZE arm-none-eabi-size REQUIRED)

add_custom_command(TARGET ${PROJECT_NAME} POST_BUILD
  COMMAND ${CMAKE_OBJCOPY} -O ihex $<TARGET_FILE:${PROJECT_NAME}>
          $<TARGET_FILE_DIR:${PROJECT_NAME}>/${PROJECT_NAME}.hex
  COMMAND ${CMAKE_OBJCOPY} -O binary $<TARGET_FILE:${PROJECT_NAME}>
          $<TARGET_FILE_DIR:${PROJECT_NAME}>/${PROJECT_NAME}.bin
  COMMAND ${CMAKE_SIZE} --format=berkeley $<TARGET_FILE:${PROJECT_NAME}>
  COMMENT "Generating HEX/BIN and printing size"
)
