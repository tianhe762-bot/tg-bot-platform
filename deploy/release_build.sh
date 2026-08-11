#!/bin/bash
# ============================================================
# TG Bot Release Builder
# ============================================================

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
VERSION_FILE="$ROOT/VERSION"

if [ ! -f "$VERSION_FILE" ]; then
    echo "❌ 找不到 VERSION 文件: $VERSION_FILE"
    exit 1
fi

VERSION=$(tr -d ' \r\n' < "$VERSION_FILE")

if [ -z "$VERSION" ]; then
    echo "❌ VERSION 为空"
    exit 1
fi

echo "=========================================="
echo " Building TG Bot Release v${VERSION}"
echo "=========================================="
echo

# 1. 发布前 Shell 语法严格检查
echo "[1/3] 执行 Shell 语法检查..."
FAIL=0
while IFS= read -r script; do
    if ! bash -n "$script"; then
        echo "❌ 语法错误: $script"
        FAIL=1
    fi
done < <(find "$ROOT" -type f -name "*.sh" -not -path "$ROOT/.git/*")

if [ "$FAIL" -ne 0 ]; then
    echo "❌ 发布终止：存在 Shell 语法错误！"
    exit 1
fi
echo "✅ 所有 Shell 脚本语法校验通过"

# 2. 打包准备
OUT_DIR="$ROOT/releases"
mkdir -p "$OUT_DIR"

TAR_NAME="tg_bot-v${VERSION}.tar.gz"
TAR_PATH="$OUT_DIR/$TAR_NAME"
SHA_PATH="${TAR_PATH}.sha256"

echo
echo "[2/3] 创建归档包..."

IGNORE_FILE="$ROOT/.releaseignore"
EXCLUDE_ARGS=()

if [ -f "$IGNORE_FILE" ]; then
    while IFS= read -r line || [ -n "$line" ]; do
        [[ -z "$line" || "$line" =~ ^# ]] && continue
        EXCLUDE_ARGS+=("--exclude=$line")
    done < "$IGNORE_FILE"
fi

# 先将文件暂存到临时目录，并把文本文件统一转换为 LF 换行，
# 避免 Windows 检出产生的 CRLF 破坏服务器上的 Shell 脚本
STAGE_DIR="$(mktemp -d)"
trap 'rm -rf "$STAGE_DIR"' EXIT

tar -cf - \
    -C "$ROOT" \
    --exclude=".git" \
    --exclude="releases" \
    "${EXCLUDE_ARGS[@]}" \
    . | tar -xf - -C "$STAGE_DIR"

while IFS= read -r -d '' f; do
    # 跳过二进制文件（包含 NUL 字节）
    if ! tr -d '\0' < "$f" | cmp -s - "$f"; then
        continue
    fi
    sed -i 's/\r$//' "$f"
done < <(find "$STAGE_DIR" -type f -print0)

tar -czf "$TAR_PATH" -C "$STAGE_DIR" .

echo "✅ 打包完成: $TAR_PATH"

# 3. 生成 SHA256 校验和
echo
echo "[3/3] 生成 SHA256 校验文件..."
(cd "$OUT_DIR" && sha256sum "$TAR_NAME" > "${TAR_NAME}.sha256")

echo "✅ 校验文件生成完成: $SHA_PATH"
echo
echo "=========================================="
echo " Release Build Success (v${VERSION})"
echo "=========================================="
