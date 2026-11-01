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
├── scripts/new-project.sh        # 一键从模板创建新工程
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
| `gdb-multiarch`（或自带的 `arm-none-eabi-gdb`） | Cortex-Debug 客户端 |
| OpenOCD | 烧录 / GDB server |
| （可选）VS Code / Cursor + 推荐扩展 | 编辑、调试 |

Debian / Ubuntu 示例：

```bash
sudo apt update
sudo apt install -y git cmake ninja-build gcc-arm-none-eabi \
  binutils-arm-none-eabi gdb-multiarch openocd
```

> Debian/Ubuntu 通常没有 `arm-none-eabi-gdb`。本模板在 `.vscode/settings.json` 中将 `cortex-debug.gdbPath` 设为 `gdb-multiarch`；说明见 [docs/cortex-debug-gdb-path.md](docs/cortex-debug-gdb-path.md)。

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

## 烧录 / 直接运行（不调试）

接好 ST-Link，确认 `openocd.cfg` 中接口与目标匹配后：

```bash
openocd -f openocd.cfg -c "program build/firmware.elf verify reset exit"
```

烧录并复位后，固件在板子上独立跑（例如 PC13 闪灯），**不需要**开调试会话。  
在 IDE 里请运行任务 **Run on Target (Flash)**，不要按 F5（F5 会进入调试）。

## VS Code / Cursor

推荐扩展见 `.vscode/extensions.json`（CMake Tools、clangd、Cortex-Debug）。

| 操作 | 方式 |
|------|------|
| 配置 | 任务 **CMake Configure** |
| 编译 | 任务 **CMake Build**（默认构建任务） |
| 直接运行（不要调试框） | 命令面板 → `Tasks: Run Task` → **Run on Target (Flash)** |
| 调试（会出调试工具栏） | Run and Debug → **Cortex Debug (OpenOCD ST-Link)** → F5 |

从 Run and Debug / F5 启动**一定会**出现顶部调试框，这是 IDE 行为，不是没配好。只要烧录请用任务，不要用 F5。详见 [docs/run-vs-debug.md](docs/run-vs-debug.md)。

## 常见问题

- 改名/搬家后 clangd 报找不到 `stm32f1xx.h`，或 cmake 提示缓存路径不一致：见 [docs/rename-or-move-project.md](docs/rename-or-move-project.md)。
- Cortex-Debug 报找不到 `arm-none-eabi-gdb`：见 [docs/cortex-debug-gdb-path.md](docs/cortex-debug-gdb-path.md)。
- F5 后总是进入调试、想直接让板子跑：见 [docs/run-vs-debug.md](docs/run-vs-debug.md)。

## 从模板开新项目

推荐用脚本（默认创建到上一级，例如 `../my-app`），也支持手搓多种方式。

### 脚本（多种 `--mode`）

```bash
# 默认：本地复制（rsync；无 rsync 时自动改 tar/cp），离线可用
./scripts/new-project.sh my-app

./scripts/new-project.sh --mode cp my-app              # 强制 cp/tar
./scripts/new-project.sh --mode git-local my-app       # git clone 本地路径 + submodule --reference
./scripts/new-project.sh --mode git my-app             # 从 GitHub clone（需网络）
./scripts/new-project.sh --mode git --keep-origin my-app

cd ../my-app
```

| `--mode` | 说明 |
|----------|------|
| `copy` / `rsync`（默认） | 本地文件复制，含已检出 Drivers，不访问网络 |
| `cp` | 同上，用 `tar`/`cp` 流水线 |
| `git-local` | `git clone` 本仓库路径，submodule 尽量引用本地对象 |
| `git` / `clone` | `git clone --recurse-submodules` 远程（可用 `--remote <url>`） |

默认会删掉新工程的 `origin`（可用 `--keep-origin` 保留），并清掉 `build/`、`.cache`、`compile_commands.json`。

### 不经过脚本

```bash
# 远程直接用 git
git clone --recurse-submodules \
  git@github.com:jiangbyte/stm32f103c8t6-template.git my-app

# 本地已有模板时
cp -a stm32f103c8t6-template my-app
# 或: rsync -a --exclude build --exclude .cache stm32f103c8t6-template/ my-app/
rm -rf my-app/build my-app/.cache my-app/compile_commands.json
```

然后自行 cmake，在 `Core/Src/main.c` 写业务。需要更多 HAL 模块时：在 `Core/Inc/stm32f1xx_hal_conf.h` 打开对应宏，并在 `CMakeLists.txt` 的 `HAL_SOURCES` 中加入源文件。  
改名/搬家后勿复用旧 `build/`，见 [docs/rename-or-move-project.md](docs/rename-or-move-project.md)。

## 许可证

- **本仓库自有文件**（如 `Core/`、`cmake/`、`CMakeLists.txt`、启动与链接脚本、VS Code 配置、文档等）采用 [MIT License](LICENSE)，版权所有 © 2026 jiangbyte。
- **`Drivers/` 下官方组件** 仍遵循各自原许可，例如：
  - CMSIS Core / Device：Apache-2.0（见各子模块 `LICENSE` / `License.md`）
  - STM32F1xx HAL Driver：ST 提供的 BSD 风格条款（见 `Drivers/STM32F1xx_HAL_Driver/LICENSE.md`）

使用或再分发时请同时遵守上述第三方许可要求。
