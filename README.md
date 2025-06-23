# Ubuntu VNC 自動設定スクリプト (Ubuntu VNC Auto-Setup)

このリポジトリは、Ubuntu 22.04/24.04 LTS上に、安全なVNCリモートデスクトップ環境を自動で構築するためのスクリプトを提供します。

手動での煩雑な設定作業をなくし、数コマンドでセキュアなリモートアクセス環境をセットアップできます。

## ✨ 主な機能

-   **軽量デスクトップ環境 (XFCE) のインストール:** サーバー用途に最適です。
-   **TigerVNCサーバーのインストールと設定:** 高機能なVNCサーバーを導入します。
-   **VNCパスワードの対話的設定:** 安全な方法でVNC接続パスワードを設定します。
-   **`systemd`によるサービス化:** OS起動時にVNCサーバーが自動で起動します。
-   **`ufw`ファイアウォールの自動設定:** SSH接続のみを許可し、セキュリティを確保します。
-   **SSHトンネリングによるセキュアな接続を前提とした設計。**

## 🚀 使い方 (Usage)

### 前提条件

-   Ubuntu Server / Desktop 22.04 LTS または 24.04 LTS のクリーンな環境。
-   `sudo` 権限を持つユーザーでログインしていること。

### インストール手順

以下のコマンドをターミナルにコピー＆ペーストして実行してください。

```bash
# 1. リポジトリをクローン
git clone https://github.com/gw-shinohara/setup_tigervnc.git

# 2. ディレクトリを移動
cd setup_tigervnc

# 3. スクリプトに実行権限を付与
chmod +x setup-vnc.sh

# 4. スクリプトを実行（sudoが必要です）
sudo ./setup-vnc.sh
```

スクリプトの実行中に、VNC接続時に使用するパスワードを2回入力するよう求められます。

### 💻 接続方法 (最重要)

**セキュリティのため、VNCには直接接続せず、必ずSSHトンネルを使用してください。**

#### ステップ1: SSHトンネルを確立する

お手元のPC（Windows, macOS, Linux）のターミナルで、以下のコマンドを実行します。`<your_username>` と `<your_server_ip>` はご自身の環境に合わせて変更してください。

```bash
ssh -L 5901:localhost:5901 -N -f -l <your_username> <your_server_ip>
```

-   **`-L 5901:localhost:5901`**: あなたのPCのポート`5901`へのアクセスを、SSH経由でサーバーの`5901`番ポートへ転送します。
-   `your_username`: Ubuntuサーバーのユーザー名。
-   `your_server_ip`: UbuntuサーバーのIPアドレス。

SSHのパスワードを入力すると、トンネルがバックグラウンドで確立されます。

#### ステップ2: VNCクライアントで接続

[RealVNC Viewer](https://www.realvnc.com/en/connect/download/viewer/) などのVNCクライアントソフトを起動し、接続先アドレスに以下を入力します。

**`localhost:5901`**

その後、スクリプト実行中に設定したVNCパスワードを入力すると、リモートデスクトップが表示されます。

## 🔧 カスタマイズ

-   **画面解像度の変更:**
    スクリプトによって生成された `/etc/systemd/system/vncserver@.service` ファイルを編集してください。
    `ExecStart` の行にある `1280x800` の部分をお好みの解像度（例: `1920x1080`）に変更し、`sudo systemctl daemon-reload` と `sudo systemctl restart vncserver@1.service` を実行します。

## 📜 ライセンス

This project is licensed under the MIT License.
