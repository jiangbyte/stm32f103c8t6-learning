# 工程改名/搬家后：头文件红线与 CMake 缓存失效

## 现象

1. 编辑器（clangd）在 `#include "stm32f1xx.h"` 上报错：`file not found`，连带 `uint32_t`、`__NOP()` 等标红。
2. 头文件实际仍在 `Drivers/CMSIS/Device/ST/STM32F1xx/Include/`，真机交叉编译未必失败。
3. 执行 `cmake -S . -B build` 可能报错，例如：

```text
CMake Error: The current CMakeCache.txt directory .../stm32f103c8t6-template/build/CMakeCache.txt
is different than the directory .../stm32f103c8t6/build where CMakeCache.txt was created.

CMake Error: The source ".../stm32f103c8t6-template/CMakeLists.txt" does not match
the source ".../stm32f103c8t6/CMakeLists.txt" used to generate cache.
```

## 原因

CMake 配置时会把**绝对路径**写入：

- `build/CMakeCache.txt`
- `build/compile_commands.json`（本仓库根目录有指向它的软链）

工程目录改名或移动后（例如 `stm32f103c8t6` → `stm32f103c8t6-template`）：

- 旧路径目录已不存在，但 `build/` 仍保留旧缓存；
- clangd 优先读 `compile_commands.json`，按其中过期的 `-I` 路径找头文件，于是报「找不到」；
- 直接 `cmake -S . -B build` 会因缓存里的源码/构建目录与当前路径不一致而拒绝复用。

这是 **IDE 语言服务 + 过期编译数据库** 与 **CMake 绝对路径缓存** 的问题，不是 CMSIS/HAL 子模块丢失。

## 解决办法

1. 删除旧构建目录后重新配置（保留原构建类型与工具链）：

```bash
rm -rf build
cmake -S . -B build \
  -DCMAKE_BUILD_TYPE=Debug \
  -DCMAKE_TOOLCHAIN_FILE=cmake/gcc-arm-none-eabi.cmake
```

2. 确认根目录软链仍指向新生成的数据库：

```bash
ls -l compile_commands.json
# 期望: compile_commands.json -> build/compile_commands.json
```

可用下面命令抽查路径是否已更新为当前工程目录：

```bash
python3 -c "import json; print(json.load(open('compile_commands.json'))[0]['file'])"
```

3. 刷新语言服务：执行 **Clangd: Restart language server**，或重载窗口；必要时删除 `.cache/clangd` 后再重启。

## 预防

- 改名/搬家后务必清掉 `build/` 再重新 cmake，不要沿用旧缓存。
- `build/`、`.cache/`、`compile_commands.json` 已在 `.gitignore` 中，勿把旧机器上的绝对路径产物提交进仓库。
