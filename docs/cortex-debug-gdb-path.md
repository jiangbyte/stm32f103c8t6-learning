# Cortex-Debug：找不到 `arm-none-eabi-gdb`

## 现象

启动调试配置 **Cortex Debug (OpenOCD ST-Link)** 时弹出：

```text
GDB executable `arm-none-eabi-gdb` was not found.
Please configure `cortex-debug.armToolchainPath` or `cortex-debug.gdbPath` correctly.
```

## 原因

Cortex-Debug 默认在 `PATH` 中查找 `arm-none-eabi-gdb`。

在 Debian / Ubuntu 上，交叉工具链包通常是：

| 包名 | 提供的程序 |
|------|------------|
| `gcc-arm-none-eabi` | `arm-none-eabi-gcc` 等 |
| `binutils-arm-none-eabi` | `arm-none-eabi-objcopy` 等 |
| `gdb-multiarch` | `gdb-multiarch`（可调试 ARM 目标） |

发行版**往往不提供**名为 `arm-none-eabi-gdb` 的可执行文件，因此扩展报「找不到 GDB」，与工程是否编过、OpenOCD 是否可用无关。

可用下面命令确认本机情况：

```bash
which arm-none-eabi-gdb   # 常见：无输出
which gdb-multiarch       # 常见：/usr/bin/gdb-multiarch
```

## 解决办法

本模板已在 `.vscode/settings.json` 中指定：

```json
"cortex-debug.gdbPath": "gdb-multiarch"
```

若仍报错：

1. 安装 multiarch GDB：`sudo apt install gdb-multiarch`
2. 或把 `cortex-debug.gdbPath` 写成绝对路径，例如 `/usr/bin/gdb-multiarch`
3. 若自行安装了完整 Arm GNU Toolchain 且带有 `arm-none-eabi-gdb`，也可改回该路径，或设置 `cortex-debug.armToolchainPath` 为其 `bin` 目录

改完设置后重新启动调试即可。

## 相关配置

- 调试启动项：`.vscode/launch.json`
- 工作区设置：`.vscode/settings.json`（`cortex-debug.gdbPath`）
