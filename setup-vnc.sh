#!/bin/bash

# Ubuntu VNC Auto-Setup Script (with OpenSSH Server)
#
# このスクリプトはroot権限で実行する必要があります。
# This script must be run as root.

# --- 色付け用 ---
GREEN="\033[0;32m"
YELLOW="\033[1;33m"
RED="\033[0;31m"
NC="\033[0m" # No Color

# --- スクリプトの実行者がrootかチェック ---
if [ "$(id -u)" -ne 0 ]; then
    echo -e "${RED}エラー: このスクリプトはroot権限 (sudo) で実行する必要があります。${NC}"
    exit 1
fi

# --- スクリプト自身のディレクトリを取得 ---
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

# --- sudoを実行したユーザー名を取得 ---
RUNNING_USER="$SUDO_USER"
if [ -z "$RUNNING_USER" ]; then
    echo -e "${RED}エラー: ユーザーを特定できませんでした。sudoで実行してください。${NC}"
    exit 1
fi
USER_HOME=$(getent passwd "$RUNNING_USER" | cut -d: -f6)

echo -e "${GREEN}=== Ubuntu VNC 自動設定スクリプトを開始します ===${NC}"
echo -e "実行ユーザー: ${YELLOW}${RUNNING_USER}${NC}"
echo -e "ホームディレクトリ: ${YELLOW}${USER_HOME}${NC}"
echo -e "スクリプトディレクトリ: ${YELLOW}${SCRIPT_DIR}${NC}"

# --- 1. 必要なパッケージのインストール ---
echo -e "\n${GREEN}>>> ステップ1: 必要なパッケージをインストールしています...${NC}"
apt-get update
# ★ openssh-server をインストール対象に追加 ★
apt-get install -y openssh-server xfce4 xfce4-goodies tigervnc-standalone-server ufw

# --- 1.5. SSHサーバーの起動と有効化 (★新規追加★) ---
echo -e "\n${GREEN}>>> ステップ1.5: SSHサーバーを起動・有効化しています...${NC}"
systemctl enable --now ssh
echo "SSHサービスの稼働状態:"
systemctl status ssh --no-pager
# --no-pager はステータス表示が画面を占有しないようにするため

# --- 2. VNCパスワードの設定 ---
echo -e "\n${GREEN}>>> ステップ2: VNCパスワードを設定します...${NC}"
mkdir -p "$USER_HOME/.vnc"
chown -R "$RUNNING_USER:$RUNNING_USER" "$USER_HOME/.vnc"
echo -e "${YELLOW}VNC接続用のパスワードを設定してください（8文字以内推奨）。${NC}"
su - "$RUNNING_USER" -c "vncpasswd"

# --- 3. xstartupファイルの設定 ---
echo -e "\n${GREEN}>>> ステップ3: VNC起動スクリプト (xstartup) を設定しています...${NC}"
XSTARTUP_TEMPLATE="${SCRIPT_DIR}/templates/xstartup"
XSTARTUP_PATH="$USER_HOME/.vnc/xstartup"

if [ ! -f "$XSTARTUP_TEMPLATE" ]; then
    echo -e "${RED}エラー: テンプレートファイルが見つかりません: ${XSTARTUP_TEMPLATE}${NC}"
    exit 1
fi

cp "$XSTARTUP_TEMPLATE" "$XSTARTUP_PATH"
chmod 755 "$XSTARTUP_PATH"
chown "$RUNNING_USER:$RUNNING_USER" "$XSTARTUP_PATH"
echo "xstartupファイルをコピーしました。"


# --- 4. Systemdサービスファイルの作成 ---
echo -e "\n${GREEN}>>> ステップ4: Systemdサービスを作成して自動起動を設定しています...${NC}"
SERVICE_TEMPLATE="${SCRIPT_DIR}/templates/vncserver@.service"
SERVICE_PATH="/etc/systemd/system/vncserver@.service"

if [ ! -f "$SERVICE_TEMPLATE" ]; then
    echo -e "${RED}エラー: テンプレートファイルが見つかりません: ${SERVICE_TEMPLATE}${NC}"
    exit 1
fi

sed -e "s|__USER__|${RUNNING_USER}|g" \
    -e "s|__USER_HOME__|${USER_HOME}|g" \
    "$SERVICE_TEMPLATE" > "$SERVICE_PATH"

echo "systemdサービスファイルを作成しました。"


# --- 4.5. vncserver.users ファイルの作成 ---
echo -e "\n${GREEN}>>> ステップ4.5: TigerVNCユーザーマッピングファイルを作成しています...${NC}"
# ディレクトリが存在しない場合に作成
mkdir -p /etc/tigervnc
# ファイルを作成し、ディスプレイ番号とユーザーをマッピング
echo ":1 = ${RUNNING_USER}" > /etc/tigervnc/vncserver.users
echo "ファイルを作成しました: /etc/tigervnc/vncserver.users"
echo -e "${YELLOW}---------------------------------------------------"
cat "/etc/tigervnc/vncserver.users"
echo -e "---------------------------------------------------${NC}"


# --- 5. VNCサービスの有効化と起動 ---
echo -e "\n${GREEN}>>> ステップ5: VNCサービスを有効化し、起動しています...${NC}"
systemctl daemon-reload
systemctl enable --now vncserver@1.service

# --- 6. ファイアウォール(ufw)の設定 ---
echo -e "\n${GREEN}>>> ステップ6: ファイアウォール (ufw) を設定しています...${NC}"
ufw allow ssh
# ★ VNC接続用のポート5901も許可（トンネルが使えない場合のフォールバック）★
# ufw allow 5901
echo "y" | ufw enable
echo "ファイアウォールの状態:"
ufw status

echo -e "\n${GREEN}===================================================${NC}"
echo -e "${GREEN}        🎉 セットアップが完了しました！ 🎉        ${NC}"
echo -e "${GREEN}===================================================${NC}"
echo -e "\n次に、お手元のPCから以下の手順で接続してください。"
echo -e "詳細は ${YELLOW}README.md${NC} を参照してください。"
echo -e "\n${YELLOW}1. SSHトンネルを作成:${NC}"
echo -e "   ssh -L 5901:localhost:5901 -N -f -l ${RUNNING_USER} <サーバーのIPアドレス>"
echo -e "\n${YELLOW}2. VNCクライアントで接続:${NC}"
echo -e "   接続先: ${GREEN}localhost:5901${NC}"
echo -e "\n"

echo "VNCサービスの稼働状態を確認します..."
systemctl status vncserver@1.service --no-pager
