# 直接运行 vs 调试（F5）

## 现象

按 F5 或点绿色调试按钮后：

- 左侧 Call Stack 显示 `Running`
- Debug Console 里不断刷 GDB / MI 日志
- 感觉“一直停在调试里，不能直接执行”

## 说明

嵌入式工程里，**F5 = 启动调试会话**（OpenOCD + GDB 挂到 MCU），不是桌面程序那种“运行完就退出”。

| | 直接运行 | 调试 |
|--|----------|------|
| IDE 入口 | 任务 **Run on Target (Flash)** | **Cortex Debug (OpenOCD ST-Link)** / F5 |
| 命令行 | `openocd -f openocd.cfg -c "program build/firmware.elf verify reset exit"` | 由 Cortex-Debug 拉起 OpenOCD 与 GDB |
| 烧录后 | OpenOCD 退出，MCU 复位后独立运行 | GDB 保持连接；可断点、单步 |
| Call Stack `Running` | 不会出现（无调试会话） | **正常**：表示目标正在执行 |

因此：Call Stack 为 `Running` 时，固件通常**已经在板上执行**（例如 `while(1)` 闪灯循环）。若未下断点，不会停在某一行，看起来像“什么也没发生”，实则目标在跑。

本模板调试配置使用 `runToEntryPoint: "main"`：连上后会先停在 `main`，需点一次继续（Continue）才会进入循环；继续之后就会看到 `Running`。

## 想直接执行时怎么做

### 顶部调试工具栏是正常的吗？

**是。** 凡是从 **Run and Debug**（绿色按钮 / F5）启动的配置，VS Code / Cursor **都会**显示 Continue / Pause / Stop 那一栏——这是“调试会话进行中”的 IDE 控件，和是否单步无关。

因此：

| 目标 | 入口 | 会不会出现调试框 |
|------|------|------------------|
| 只要烧录、板子自己跑 | 命令面板 → `Tasks: Run Task` → **Run on Target (Flash)** | **不会** |
| 要断点 / 单步 / 看变量 | Run and Debug → **Cortex Debug (OpenOCD ST-Link)** | **会（预期）** |

`launch.json` 里**只保留调试配置**，不再把“烧录运行”放进该下拉，以免一点绿色按钮就出现调试框、误以为还能“无调试地 F5”。

## 相关改动

- 直接运行：仅通过任务 **Run on Target (Flash)**（或命令行 OpenOCD）
- 调试：仅 **Cortex Debug (OpenOCD ST-Link)**；`showDevDebugOutput` 为 `none`（排障可改回 `raw`）
