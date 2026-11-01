# STM32F103C8T6 学习仓库

个人在 **STM32F103C8T6**（Blue Pill）上按案例练习底层的仓库。基于 [stm32f103c8t6-template](https://github.com/jiangbyte/stm32f103c8t6-template)：CMake + Ninja + `arm-none-eabi-gcc`，CMSIS / HAL 为 submodule。

## 案例

当前生效代码：`Core/Src/main.c`。做完后归档到 `cases/<编号-标题>/main.c`，再改 `main.c` 写下一个。`cases/` 不参与编译。

| 编号 | 目录 | 说明 |
|------|------|------|
| 01 | [cases/01-PA0软件PWM呼吸灯](cases/01-PA0软件PWM呼吸灯) | CMSIS 寄存器 · PA0 软件 PWM 呼吸灯 |

## 目录

```text
.
├── Core/Src/main.c               # 当前业务入口
├── cases/                        # 案例归档
├── Core/Inc/stm32f1xx_hal_conf.h
├── Drivers/                      # CMSIS / HAL submodule
├── cmake/gcc-arm-none-eabi.cmake
├── docs/
├── startup_stm32f103xb.s
├── STM32F103C8Tx_FLASH.ld
├── openocd.cfg
├── CMakeLists.txt
└── .vscode/
```

## 构建与烧录

```bash
sudo apt install -y git cmake ninja-build gcc-arm-none-eabi \
  binutils-arm-none-eabi gdb-multiarch openocd

git submodule update --init --recursive

cmake -S . -B build -G Ninja \
  -DCMAKE_BUILD_TYPE=Debug \
  -DCMAKE_TOOLCHAIN_FILE=cmake/gcc-arm-none-eabi.cmake
cmake --build build -j

ln -sf build/compile_commands.json compile_commands.json   # clangd

openocd -f openocd.cfg -c "program build/firmware.elf verify reset exit"
```

IDE：任务 **CMake Configure** / **CMake Build** / **Run on Target (Flash)**；调试用 F5（Cortex-Debug）。

- [docs/run-vs-debug.md](docs/run-vs-debug.md)
- [docs/cortex-debug-gdb-path.md](docs/cortex-debug-gdb-path.md)
- [docs/rename-or-move-project.md](docs/rename-or-move-project.md)

加 HAL 模块：改 `stm32f1xx_hal_conf.h` 与 `CMakeLists.txt` 中的 `HAL_SOURCES`。

## 许可证

自有代码 [MIT](LICENSE) © 2026 jiangbyte。`Drivers/` 遵循各自原许可。
