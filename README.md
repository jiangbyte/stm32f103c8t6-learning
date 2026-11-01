# STM32F103C8T6 工程模板

面向 **STM32F103C8T6**（Blue Pill / 同类板）的最小化 CMake 模板：官方 CMSIS + HAL 以 git submodule 引入，业务代码从 `Core/Src/main.c` 起步，支持命令行与 VS Code / Cursor 一键配置、编译、烧录与调试。

## 特性

- 目标器件：`STM32F103xB`（Cortex-M3，64KB Flash / 20KB RAM）
- 构建：CMake + Ninja + `arm-none-eabi-gcc`
- 驱动：ST 官方 CMSIS Core / Device F1、STM32F1xx HAL（子模块）
- 示例：CMSIS 寄存器翻转 PC13 LED（可按注释切换到 HAL）
- 调试：OpenOCD + ST-Link（SWD），附带 Cortex-Debug 配置
- 语言服务：导出 `compile_commands.json`，配合 clangd

## 目录结构

```text
.
├── Core/
│   ├── Inc/stm32f1xx_hal_conf.h   # HAL 裁剪配置
│   └── Src/main.c                # 唯一自写业务入口
├── Drivers/                      # git submodule（CMSIS / HAL）
├── cmake/gcc-arm-none-eabi.cmake # 交叉编译工具链
├── docs/                         # 补充说明
├── startup_stm32f103xb.s         # 启动文件
├── STM32F103C8Tx_FLASH.ld        # 链接脚本
├── openocd.cfg                   # ST-Link + stm32f1x
├── CMakeLists.txt
├── LICENSE                       # 本模板 MIT
└── README.md
```

## 依赖

| 工具 | 用途 |
|------|------|
| Git | 克隆仓库与初始化 submodule |
| CMake ≥ 3.20、Ninja | 配置与构建 |
| Arm GNU Toolchain (`arm-none-eabi-gcc` 等) | 交叉编译 |
| OpenOCD | 烧录 / GDB server |
| （可选）VS Code / Cursor + 推荐扩展 | 编辑、调试 |

Debian / Ubuntu 示例：

```bash
sudo apt update
sudo apt install -y git cmake ninja-build gcc-arm-none-eabi \
  binutils-arm-none-eabi gdb-multiarch openocd
```

## 快速开始

```bash
git clone --recurse-submodules git@github.com:jiangbyte/stm32f103c8t6-template.git
cd stm32f103c8t6-template

# 若克隆时未拉子模块
git submodule update --init --recursive

cmake -S . -B build -G Ninja \
  -DCMAKE_BUILD_TYPE=Debug \
  -DCMAKE_TOOLCHAIN_FILE=cmake/gcc-arm-none-eabi.cmake

cmake --build build -j
```

产物位于 `build/`：`firmware.elf` / `firmware.hex` / `firmware.bin`。

为方便 clangd，可将编译数据库链到仓库根目录（若尚未存在）：

```bash
ln -sf build/compile_commands.json compile_commands.json
```

## 烧录

接好 ST-Link，确认 `openocd.cfg` 中接口与目标匹配后：

```bash
openocd -f openocd.cfg -c "program build/firmware.elf verify reset exit"
```

## VS Code / Cursor

推荐扩展见 `.vscode/extensions.json`（CMake Tools、clangd、Cortex-Debug）。

| 操作 | 方式 |
|------|------|
| 配置 | 任务 **CMake Configure** |
| 编译 | 任务 **CMake Build**（默认构建任务） |
| 烧录 | 任务 **Flash (OpenOCD)** |
| 调试 | 启动配置 **Cortex Debug (OpenOCD ST-Link)** |

## 从模板开新项目

1. 复制或 fork 本仓库，按需改仓库名与目录名。
2. 改名 / 搬家后务必删除旧 `build/` 再重新 cmake，否则会出现头文件红线或 CMake 缓存路径错误。详见 [docs/rename-or-move-project.md](docs/rename-or-move-project.md)。
3. 在 `Core/Src/main.c` 中编写业务；需要更多 HAL 模块时，在 `Core/Inc/stm32f1xx_hal_conf.h` 打开对应宏，并在 `CMakeLists.txt` 的 `HAL_SOURCES` 中加入源文件。

## 许可证

- **本仓库自有文件**（如 `Core/`、`cmake/`、`CMakeLists.txt`、启动与链接脚本、VS Code 配置、文档等）采用 [MIT License](LICENSE)，版权所有 © 2026 jiangbyte。
- **`Drivers/` 下官方组件** 仍遵循各自原许可，例如：
  - CMSIS Core / Device：Apache-2.0（见各子模块 `LICENSE` / `License.md`）
  - STM32F1xx HAL Driver：ST 提供的 BSD 风格条款（见 `Drivers/STM32F1xx_HAL_Driver/LICENSE.md`）

使用或再分发时请同时遵守上述第三方许可要求。
