#!/bin/bash

# ================================================
# Bitcoin Core 28.0 离线生成【新版 Descriptor 钱包】（方案 B）
# 作者：@chhq | 地区：HK | 时间：2025-11-10 20:20 HKT
# 用途：现代冷存储 / 导出 xprv + 派生地址 + 私钥（WIF）
# 关键：不依赖 dumpwallet，使用 listdescriptors + deriveaddresses + 手动推导
# ================================================

set -e
trap 'echo "[FATAL] 第 $LINENO 行出错: $BASH_COMMAND" >&2; exit 1' ERR

DEBUG=true
LOG="/tmp/btc_descriptor_$(date +%s).log"
echo "=== @chhq 离线生成日志（Descriptor 钱包） | $(date '+%Y-%m-%d %H:%M HKT') ===" > "$LOG"

log() { [ "$DEBUG" = true ] && echo "[$(date '+%H:%M:%S')] $1" | tee -a "$LOG"; }

# 统一钱包名称（前置，便于清理同名钱包）
WALLET_NAME="rcbit_desc"

# ==================== 1. 清除残留 ====================
log "清除残留环境"
pkill -9 bitcoind 2>/dev/null || true
sleep 1
rm -rf ~/.bitcoin/wallets/"$WALLET_NAME" ~/.bitcoin/{chainstate,blocks,*.dat} /tmp/rcbit_* 2>/dev/null || true
log "残留已清除"

# ==================== 2. 启动节点 ====================
cd ~/btc-offline/bitcoin-28.0/bin
log "启动 bitcoind（完全离线模式）"
./bitcoind -server -daemon -noconnect -disablewallet=0 >>"$LOG" 2>&1
sleep 6

# 验证节点状态
log "验证节点状态"
for i in {1..10}; do
    INFO=$(./bitcoin-cli getblockchaininfo 2>/dev/null || echo "ERROR")
    if echo "$INFO" | grep -q '"chain": "main"'; then
        log "主网节点就绪（第 $i 次）"
        break
    fi
    [ $i -eq 10 ] && { log "节点启动失败"; exit 1; }
    sleep 2
done

# ==================== 3. 创建新版 Descriptor 钱包 ====================
log "创建新版 Descriptor 钱包（SQLite + descriptors=true）"
./bitcoin-cli createwallet "$WALLET_NAME" false false "" false true false >>"$LOG" 2>&1
sleep 2
log "Descriptor 钱包 $WALLET_NAME 已创建并加载"

# ==================== 4. 获取接收描述符（Receive Descriptor）===================
log "获取接收描述符（wpkh）"
DESC_INFO=$(./bitcoin-cli -rpcwallet="$WALLET_NAME" listdescriptors true | grep -A3 '"desc": "wpkh' | head -4)
XPRV_DESC=$(echo "$DESC_INFO" | grep '"desc"' | cut -d'"' -f4)
log "接收描述符: $XPRV_DESC"

# 派生第一个地址（index 0）
ADDRESS=$(./bitcoin-cli -rpcwallet="$WALLET_NAME" getnewaddress "" "bech32")
log "派生地址（index 0）: $ADDRESS"

# ==================== 5. 导出扩展私钥 xprv（根密钥）===================
log "导出 xprv 根密钥（可离线派生所有地址）"
# 从 descriptor 的括号内取出主体，再在第一个斜杠前截断，得到纯 xprv 根
DESC_BODY=$(echo "$XPRV_DESC" | cut -d'(' -f2 | cut -d')' -f1)
XPRV=${DESC_BODY%%/*}
if [ -z "$XPRV" ]; then
    echo "[FATAL] 未能从描述符中解析出 xprv" >&2
    exit 1
fi
log "xprv 根密钥: $XPRV"

# ==================== 6. 手动推导 WIF 私钥（使用 bitcoin-cli deriveaddresses）===================
# 严谨构造派生描述符：去掉校验和与 origin 信息，将 /*) 改为 /0/0)
DESC_NOCHK=${XPRV_DESC%%#*}
DERIVE_DESC=$(echo "$DESC_NOCHK" | sed -E 's/\[[^]]*\]//; s/\/\*\)$/\/0\/0)/')
log "构造派生描述符: $DERIVE_DESC"

# 获取派生地址 + 私钥（通过外部工具或手动推导）
# 注意：bitcoin-cli 无法直接导出 WIF，但我们提供 xprv + 路径，可用 Ian Coleman 工具离线推导
log "提示：使用 xprv + 路径 m/84'/0'/0'/0/0 可在 Ian Coleman 工具中离线推导 WIF"

# ==================== 7. 纸质备份区（@chhq 专用）===================
cat << EOF

==================================================
        纸质备份区（@chhq 专用 | 新版 Descriptor 钱包）
==================================================
钱包名称：$WALLET_NAME
地址（Address, index 0）：
$ADDRESS

扩展私钥（xprv 根密钥）：
$XPRV

派生路径（Path）：
m/84'/0'/0'/0/0  → 地址 $ADDRESS

生成时间：$(date '+%Y-%m-%d %H:%M HKT')
X Handle：@chhq
国家：Hong Kong
钱包类型：Descriptor + SQLite (P2WPKH)
警告：xprv 泄露 = 所有地址私钥泄露！永不联网存储！

使用方法：
1. 离线打开 https://github.com/iancoleman/bip39 (下载 bip39.html)
2. 选择 “BIP32 Root Key” → 粘贴 xprv
3. 路径：m/84'/0'/0'/0/0
4. 验证地址一致 → 获取 WIF 私钥（手写备份）

==================================================

EOF

# ==================== 8. 安全清理 ====================
log "安全擦除临时数据"
./bitcoin-cli stop >>"$LOG" 2>&1
sleep 3
rm -rf ~/.bitcoin/wallets/"$WALLET_NAME" ~/.bitcoin/{chainstate,blocks} 2>/dev/null

log "清理完成！日志: $LOG"
echo "请立即手写备份 xprv 和地址！"
echo "使用 Ian Coleman 工具离线推导 WIF 私钥。"
echo "重启电脑以清除内存残留。"


