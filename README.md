# EC2SSM

EC2SSMは、AWSのEC2インスタンスにSession Manager (SSM)経由で簡単に接続するためのコマンドラインツールです。インスタンス名からの接続、自動ユーザー切り替え、tmux統合などの機能を提供します。

## 機能

- インスタンス名を使用したEC2インスタンスへの接続
- ローカルキャッシュによる高速なインスタンス検索
- プロファイルごとのインスタンスリスト管理
- 環境変数を使用した自動ユーザー切り替え（expect利用）
- tmuxとの統合（接続時にウィンドウ名を変更）

## 前提条件

- AWS CLI がインストールされていること
- jq コマンドがインストールされていること (`apt-get install jq` または `brew install jq`)
- 自動ユーザー切り替えを使用する場合は expect がインストールされていること (`apt-get install expect` または `brew install expect`)
- AWS SSM が設定されており、対象のEC2インスタンスにSSMエージェントがインストールされていること
- Zsh シェルの使用を推奨

## インストール

```bash
# リポジトリをクローン
git clone https://github.com/yuhiwa/ec2ssm.git

# スクリプトに実行権限を付与
chmod +x ec2ssm/ec2ssm.sh

# Zshの設定ファイルに以下の3行を追加
echo '# ec2ssmコマンドの定義' >> ~/.zshrc
echo 'function ec2ssm { ~/ec2ssm/ec2ssm.sh "$@" }' >> ~/.zshrc
echo 'function _ec2ssm { compadd $(cat ~/.aws_instances_* 2>/dev/null) }' >> ~/.zshrc
echo 'compdef _ec2ssm ec2ssm' >> ~/.zshrc

# 設定を反映
source ~/.zshrc
```

## 使用方法

### 基本的な使い方

```bash
# インスタンス名を指定して接続
ec2ssm instance-name

# 特定のプロファイルを使用して接続
ec2ssm instance-name --profile production
```

### インスタンスリストの更新

```bash
# デフォルトプロファイルのインスタンスリストを更新
ec2ssm update

# 特定のプロファイルのインスタンスリストを更新
ec2ssm update --profile production
```

### キャッシュの削除

```bash
# デフォルトプロファイルのキャッシュを削除
ec2ssm remove

# 特定のプロファイルのキャッシュを削除
ec2ssm remove --profile production
```

### 環境変数を使った自動ユーザー切り替え

```bash
# 環境変数を設定
export EC2USER=username
export EC2PASSWORD=password

# EC2インスタンスに接続し、自動的に指定したユーザーにスイッチ
ec2ssm instance-name
```

## Zshでのシェル補完との統合

インスタンス名の補完を有効にするには、以下の3行を`.zshrc`に追加するだけです：

```zsh
# ec2ssmコマンドの定義
function ec2ssm { ~/ec2ssm/ec2ssm.sh "$@" }

# ec2ssmの補完関数
function _ec2ssm { compadd $(cat ~/.aws_instances_* 2>/dev/null) }

# 補完を登録
compdef _ec2ssm ec2ssm
```

この設定を行うと、タブキーを押すことでEC2インスタンス名が補完されるようになります。

## 仕組み

1. インスタンス情報はローカルにキャッシュされ、素早い検索が可能
2. updateコマンドはキャッシュを更新し、ホームディレクトリにインスタンス名リストを保存
3. インスタンス名からインスタンスIDを検索し、AWS SSM経由で接続
4. 環境変数EC2USERとEC2PASSWORDが設定されている場合、expectスクリプトを使って自動的にユーザー切り替え

## トラブルシューティング

- **インスタンスが見つからない場合**: `update` コマンドを実行してキャッシュを更新
- **キャッシュに問題がある場合**: `remove` コマンドでキャッシュをクリアしてから `update` を実行
- **jqエラーが発生する場合**: jqがインストールされていることを確認
- **自動ログインが機能しない場合**: expectがインストールされていることを確認し、EC2USERとEC2PASSWORDが正しく設定されていることを確認

## ライセンス

[MITライセンス](LICENSE)
