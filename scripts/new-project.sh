#!/usr/bin/env bash
# 从本模板创建新工程，支持多种方式：本地复制 / 本地 git clone / 远程 git clone。
set -euo pipefail

DEFAULT_REMOTE="git@github.com:jiangbyte/stm32f103c8t6-template.git"

usage() {
  cat <<EOF
用法: ./scripts/new-project.sh [选项] <项目名> [输出父目录]

  项目名         新目录名（字母/数字/下划线/连字符）
  输出父目录     默认为模板仓库的上一级目录

选项:
  --mode <方式>  创建方式（默认 copy）
                   copy | rsync   本地文件复制（离线，含已检出 Drivers）
                   cp             同 copy，强制用 cp（无 rsync 时）
                   git-local      git clone 本地模板路径，submodule 用 --reference
                   git | clone    git clone --recurse-submodules 远程仓库
  --remote <url> 仅 --mode git 时使用（默认: ${DEFAULT_REMOTE}）
  --keep-origin  保留 origin（默认会删掉，避免误推到模板）
  -h, --help     显示帮助

示例:
  ./scripts/new-project.sh led-blink
  ./scripts/new-project.sh --mode cp my-app
  ./scripts/new-project.sh --mode git-local my-app ~/work
  ./scripts/new-project.sh --mode git --remote ${DEFAULT_REMOTE} my-app
EOF
}

MODE="copy"
REMOTE="$DEFAULT_REMOTE"
KEEP_ORIGIN=0
NAME=""
PARENT_ARG=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    -h|--help)
      usage
      exit 0
      ;;
    --mode)
      MODE="${2:?--mode 需要参数}"
      shift 2
      ;;
    --mode=*)
      MODE="${1#*=}"
      shift
      ;;
    --remote)
      REMOTE="${2:?--remote 需要参数}"
      shift 2
      ;;
    --remote=*)
      REMOTE="${1#*=}"
      shift
      ;;
    --keep-origin)
      KEEP_ORIGIN=1
      shift
      ;;
    -*)
      echo "错误: 未知选项: $1" >&2
      usage >&2
      exit 1
      ;;
    *)
      if [[ -z "$NAME" ]]; then
        NAME="$1"
      elif [[ -z "$PARENT_ARG" ]]; then
        PARENT_ARG="$1"
      else
        echo "错误: 多余参数: $1" >&2
        usage >&2
        exit 1
      fi
      shift
      ;;
  esac
done

if [[ -z "$NAME" ]]; then
  usage >&2
  exit 1
fi

if [[ ! "$NAME" =~ ^[A-Za-z0-9][A-Za-z0-9_-]*$ ]]; then
  echo "错误: 项目名无效: $NAME（需以字母或数字开头，仅含字母/数字/_/-）" >&2
  exit 1
fi

case "$MODE" in
  copy|rsync|cp|git-local|git|clone) ;;
  *)
    echo "错误: 未知 --mode: $MODE" >&2
    usage >&2
    exit 1
    ;;
esac

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMPLATE_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
PARENT="$(cd "${PARENT_ARG:-$TEMPLATE_ROOT/..}" && pwd)"
DEST="$PARENT/$NAME"

require_local_submodules() {
  for rel in \
    Drivers/CMSIS/Core \
    Drivers/CMSIS/Device/ST/STM32F1xx \
    Drivers/STM32F1xx_HAL_Driver
  do
    if [[ ! -d "$TEMPLATE_ROOT/$rel" ]]; then
      echo "错误: 模板缺少 $rel" >&2
      echo "请先在模板根目录执行: git submodule update --init --recursive" >&2
      exit 1
    fi
  done
  if [[ ! -f "$TEMPLATE_ROOT/Drivers/CMSIS/Device/ST/STM32F1xx/Include/stm32f1xx.h" ]]; then
    echo "错误: CMSIS Device 头文件未检出，请先: git submodule update --init --recursive" >&2
    exit 1
  fi
}

clean_build_artifacts() {
  rm -rf "$DEST/build" "$DEST/.cache"
  rm -f "$DEST/compile_commands.json"
}

strip_origin_unless_kept() {
  if [[ "$KEEP_ORIGIN" -eq 1 ]]; then
    return 0
  fi
  if git -C "$DEST" remote get-url origin >/dev/null 2>&1; then
    git -C "$DEST" remote remove origin
  fi
}

copy_tree_rsync() {
  command -v rsync >/dev/null 2>&1 || {
    echo "错误: 未找到 rsync，可改用: --mode cp" >&2
    exit 1
  }
  mkdir -p "$DEST"
  rsync -a \
    --exclude='/build/' \
    --exclude='/.cache/' \
    --exclude='/compile_commands.json' \
    "$TEMPLATE_ROOT/" "$DEST/"
}

copy_tree_cp() {
  mkdir -p "$DEST"
  # 用 tar 流水线复制，便于排除目录；不依赖 rsync
  (
    cd "$TEMPLATE_ROOT"
    tar --exclude='./build' --exclude='./.cache' --exclude='./compile_commands.json' \
      -cf - .
  ) | (cd "$DEST" && tar -xf -)
}

create_via_copy() {
  require_local_submodules
  if [[ "$MODE" == "cp" ]]; then
    copy_tree_cp
  elif command -v rsync >/dev/null 2>&1; then
    copy_tree_rsync
  else
    echo "提示: 无 rsync，改用 cp/tar 方式"
    copy_tree_cp
  fi
  clean_build_artifacts
  strip_origin_unless_kept
}

create_via_git_local() {
  require_local_submodules
  git clone "$TEMPLATE_ROOT" "$DEST"
  # 尽量用本地对象，减少/避免按 submodule URL 上网
  git -C "$DEST" submodule update --init --recursive --reference "$TEMPLATE_ROOT"
  clean_build_artifacts
  strip_origin_unless_kept
}

create_via_git_remote() {
  git clone --recurse-submodules "$REMOTE" "$DEST"
  clean_build_artifacts
  strip_origin_unless_kept
}

if [[ -e "$DEST" ]]; then
  echo "错误: 目标已存在: $DEST" >&2
  exit 1
fi

echo "方式: $MODE"
echo "创建: $DEST"

case "$MODE" in
  copy|rsync|cp)
    echo "模板: $TEMPLATE_ROOT"
    create_via_copy
    ;;
  git-local)
    echo "模板: $TEMPLATE_ROOT"
    create_via_git_local
    ;;
  git|clone)
    echo "远程: $REMOTE"
    create_via_git_remote
    ;;
esac

ORIGIN_NOTE="已移除 origin；需要时可自行: git remote add origin <url>"
if [[ "$KEEP_ORIGIN" -eq 1 ]]; then
  ORIGIN_NOTE="已保留 origin"
fi

cat <<EOF

已创建工程: $DEST
（$ORIGIN_NOTE）

下一步:
  cd "$DEST"
  cmake -S . -B build -G Ninja \\
    -DCMAKE_BUILD_TYPE=Debug \\
    -DCMAKE_TOOLCHAIN_FILE=cmake/gcc-arm-none-eabi.cmake
  cmake --build build -j

业务入口: Core/Src/main.c
烧录（不调试）: 命令面板 → Tasks: Run Task → Run on Target (Flash)
EOF
