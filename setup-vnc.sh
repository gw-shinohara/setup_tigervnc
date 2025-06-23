#!/bin/bash

# Ubuntu VNC Auto-Setup Script
#
# このスクリプトはroot権限で実行する必要があります。
# This script must be run as root.

# --- 色付け用 ---
GREEN="\033[0;32m"
YELLOW="\033[1;33m"
RED="\033[0;31m"
NC="\033[0m" # No Color

# --- スクリプトの実行者がrootかチェック ---
if [ "<span class="math-inline">\(id \-u\)" \-ne 0 \]; then
echo \-e "</span>{RED}エラー: このスクリプトはroot権限 (sudo) で実行する必要があります。${NC}"
    exit 1
fi

# --- sudoを実行したユーザー名を取得 ---
RUNNING_USER="$SUDO_USER"
if [ -z "<span class="math-inline">RUNNING\_USER" \]; then
echo \-e "</span>{RED}エラー: ユーザーを特定できませんでした。sudoで実行してください。<span class="math-inline">\{NC\}"
exit 1
fi
USER\_HOME\=</span>(getent passwd "<span class="math-inline">RUNNING\_USER" \| cut \-d\: \-f6\)
echo \-e "</span>{GREEN}=== Ubuntu VNC 自動設定スクリプトを開始します ===${NC}"
echo -e "実行ユーザー: <span class="math-inline">\{YELLOW\}</span>{RUNNING_USER}${NC}"
echo -e "ホームディレクトリ: <span class="math-inline">\{YELLOW\}</span>{USER_HOME}<span class="math-inline">\{NC\}"
\# \-\-\- 1\. 必要なパッケージのインストール \-\-\-
echo \-e "\\n</span>{GREEN}>>> ステップ1: 必要なパッケージをインストールしています...<span class="math-inline">\{NC\}"
apt\-get update
apt\-get install \-y xfce4 xfce4\-goodies tigervnc\-standalone\-server ufw
\# \-\-\- 2\. VNCパスワードの設定 \-\-\-
echo \-e "\\n</span>{GREEN}>>> ステップ2: VNCパスワードを設定します...${NC}"
# vncpasswdは対話的に実行する必要があるため、ユーザーに直接操作させる
# ~/.vncディレクトリを作成
mkdir -p "$USER_HOME/.vnc"
chown -R "$RUNNING_USER:$RUNNING_USER" "<span class="math-inline">USER\_HOME/\.vnc"
\# suコマンドでユーザーになり、vncpasswdを実行
echo \-e "</span>{YELLOW}VNC接続用のパスワードを設定してください（8文字以内推奨）。${NC}"
su - "<span class="math-inline">RUNNING\_USER" \-c "vncpasswd"
\# \-\-\- 3\. xstartupファイルの設定 \-\-\-
echo \-e "\\n</span>{GREEN}>>> ステップ3: VNC起動スクリプト (xstartup) を設定しています...${NC}"
XSTARTUP_PATH="$USER_HOME/.vnc/xstartup"
cat <<'EOF' > "$XSTARTUP_PATH"
#!/bin/sh
unset SESSION_MANAGER
unset DBUS_SESSION_BUS_ADDRESS
[ -x /etc/vnc/xstartup ] && exec /etc/vnc/xstartup
[ -r $HOME/.Xresources ] && xrdb $HOME/.Xresources
startxfce4 &
EOF

# 権限を設定
chmod 755 "$XSTARTUP_PATH"
chown "$RUNNING_USER:$RUNNING_USER" "<span class="math-inline">XSTARTUP\_PATH"
\# \-\-\- 4\. Systemdサービスファイルの作成 \-\-\-
echo \-e "\\n</span>{GREEN}>>> ステップ4: Systemdサービスを作成して自動起動を設定しています...${NC}"
SERVICE_PATH="/etc/systemd/system/vncserver@.service"
cat <<EOF > "<span class="math-inline">SERVICE\_PATH"
\[Unit\]
Description\=Start TigerVNC server at startup for %i
After\=syslog\.target network\.target
\[Service\]
Type\=forking
User\=</span>{RUNNING_USER}
Group=<span class="math-inline">\{RUNNING\_USER\}
WorkingDirectory\=</span>{USER_HOME}

PIDFile=<span class="math-inline">\{USER\_HOME\}/\.vnc/%H\:%i\.pid
ExecStartPre\=\-/usr/bin/vncserver \-kill \:%i \> /dev/null 2\>&1
ExecStart\=/usr/bin/vncserver \-depth 24 \-geometry 1280x800 \:%i
ExecStop\=/usr/bin/vncserver \-kill \:%i
\[Install\]
WantedBy\=multi\-user\.target
EOF
\# \-\-\- 5\. サービスの有効化と起動 \-\-\-
echo \-e "\\n</span>{GREEN}>>> ステップ5: VNCサービスを有効化し、起動しています...<span class="math-inline">\{NC\}"
systemctl daemon\-reload
\# \-\-now オプションで有効化と起動を同時に行う
systemctl enable \-\-now vncserver@1\.service
\# \-\-\- 6\. ファイアウォール\(ufw\)の設定 \-\-\-
echo \-e "\\n</span>{GREEN}>>> ステップ6: ファイアウォール (ufw) を設定しています...<span class="math-inline">\{NC\}"
\# SSHを許可
ufw allow ssh
\# ufwを有効化 \(対話プロンプトを回避\)
echo "y" \| ufw enable
echo \-e "\\n</span>{GREEN}===================================================<span class="math-inline">\{NC\}"
echo \-e "</span>{GREEN}         🎉 セットアップが完了しました！ 🎉          <span class="math-inline">\{NC\}"
echo \-e "</span>{GREEN}===================================================${NC}"
echo -e "\n次に、お手元のPCから以下の手順で接続してください。"
echo -e "詳細は <span class="math-inline">\{YELLOW\}README\.md</span>{NC} を参照してください。"
echo -e "\n${YELLOW}1. SSHトンネルを作成:${NC}"
echo -e "   ssh -L 5901:localhost:5901 -N -f -l <span class="math-inline">\{RUNNING\_USER\} <サーバーのIPアドレス\>"
echo \-e "\\n</span>{YELLOW}2. VNCクライアントで接続:${NC}"
echo -e "   接続先: <span class="math-inline">\{GREEN\}localhost\:5901</span>{NC}"
echo -e "\n"

# サービスのステータスを表示して最終確認
systemctl status vncserver@1.service