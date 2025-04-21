#!/bin/bash

# ec2ssm.sh - EC2インスタンスにSSM経由で接続するBashスクリプト

# 設定ファイルのパスを取得
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# キャッシュファイルの読み込み
get_instances() {
    local profile=$1
    local cache_file="${SCRIPT_DIR}/${profile}_instances.cache"
    
    if [ -f "$cache_file" ]; then
        cat "$cache_file"
    else
        update_instances "$profile"
        cat "$cache_file"
    fi
}

# キャッシュの更新
update_instances() {
    local profile=$1
    local cache_file="${SCRIPT_DIR}/${profile}_instances.cache"
    
    # AWS CLI の出力を明示的に JSON 形式に指定
    aws ec2 describe-instances --profile "$profile" --output json > "$cache_file"
    echo "インスタンス情報を更新しました"
}

# キャッシュを削除
remove_cache() {
    local profile=$1
    local cache_file="${SCRIPT_DIR}/${profile}_instances.cache"
    local aws_instances_file="$HOME/.aws_instances_$profile"
    
    if [ -f "$cache_file" ]; then
        rm -f "$cache_file"
        echo "キャッシュファイル $cache_file を削除しました"
    else
        echo "キャッシュファイル $cache_file が見つかりません"
    fi
    
    if [ -f "$aws_instances_file" ]; then
        rm -f "$aws_instances_file"
        echo "インスタンスリストファイル $aws_instances_file を削除しました"
    else
        echo "インスタンスリストファイル $aws_instances_file が見つかりません"
    fi
}

# インスタンス名からインスタンスIDを検索
find_ec2_instanceid() {
    local instance_name=$1
    local profile=$2
    local cache_data=$(get_instances "$profile")
    
    # JSON形式チェック
    if ! echo "$cache_data" | jq -e . > /dev/null 2>&1; then
        echo "キャッシュファイルの形式が正しくありません。update コマンドを実行してキャッシュを更新してください。" >&2
        return 1
    fi
    
    # jqを使ってNameタグが一致するインスタンスIDを抽出
    echo "$cache_data" | jq -r ".Reservations[].Instances[] | select(.Tags[] | select(.Key==\"Name\" and .Value==\"$instance_name\")) | .InstanceId" | head -1
}

# インスタンスリストを取得
get_ec2_instance_list() {
    local profile=$1
    local cache_data=$(get_instances "$profile")
    
    # jqを使ってすべてのインスタンス名を抽出（エラーハンドリング追加）
    if ! echo "$cache_data" | jq -e . > /dev/null 2>&1; then
        echo "キャッシュファイルの形式が正しくありません。update コマンドを実行してキャッシュを更新してください。" >&2
        return 1
    fi
    
    echo "$cache_data" | jq -r '.Reservations[].Instances[] | (.Tags[] | select(.Key=="Name") | .Value)' | sort
}

# インスタンスリストを更新してホームディレクトリにファイルを保存
update_ec2_instance_list() {
    local profile=$1
    
    # 更新を実行
    update_instances "$profile"
    local cache_file="${SCRIPT_DIR}/${profile}_instances.cache"
    local cache_data=$(cat "$cache_file")
    
    # JSON形式チェック
    if ! echo "$cache_data" | jq -e . > /dev/null 2>&1; then
        echo "キャッシュファイルの形式が正しくありません。" >&2
        return 1
    fi
    
    # jqを使ってすべてのインスタンス名を抽出
    local instance_list=$(echo "$cache_data" | jq -r '.Reservations[].Instances[] | (.Tags[] | select(.Key=="Name") | .Value)' | sort)
    
    # ホームディレクトリに保存するファイルのパス
    local aws_instances_file="$HOME/.aws_instances_$profile"
    
    # インスタンス名をスペース区切りで保存
    echo "$instance_list" | tr '\n' ' ' > "$aws_instances_file"
    echo " " >> "$aws_instances_file"  # 末尾にスペースを追加
    
    echo "インスタンスリストを $aws_instances_file に保存しました"
    
    # 結果を返す
    echo "$instance_list"
}

# メイン処理
main() {
    local instance_name=""
    local profile="default"
    
    # 引数解析
    if [ $# -lt 1 ]; then
        echo "使用法: $0 [instance_name|update|remove] [--profile PROFILE]"
        exit 1
    fi
    
    instance_name=$1
    shift
    
    while [ $# -gt 0 ]; do
        case "$1" in
            --profile)
                profile="$2"
                shift 2
                ;;
            *)
                echo "不明なオプション: $1"
                exit 1
                ;;
        esac
    done
    
    # updateコマンドの場合
    if [ "$instance_name" = "update" ]; then
        echo "インスタンス情報を更新中..."
        instance_list=$(update_ec2_instance_list "$profile")
        if [ $? -ne 0 ]; then
            echo "更新中にエラーが発生しました。"
            exit 1
        fi
        
        echo "インスタンス情報の更新が完了しました。"
        exit 0
    fi
    
    # removeコマンドの場合
    if [ "$instance_name" = "remove" ]; then
        remove_cache "$profile"
        exit 0
    fi
    
    # インスタンスIDを検索
    instance_id=$(find_ec2_instanceid "$instance_name" "$profile")
    
    if [ -z "$instance_id" ]; then
        echo "インスタンスが見つかりません。Nameタグと環境設定を確認してください。"
        exit 1
    fi
    
    # 画面サイズを取得
    stty_size=$(stty size)
    rows=$(echo "$stty_size" | cut -d' ' -f1)
    cols=$(echo "$stty_size" | cut -d' ' -f2)
    
    # TMUXが実行中の場合、ウィンドウ名を変更
    if [ -n "$TMUX" ]; then
        tmux rename-window "$instance_name"
    fi
    
    # expectコマンドがインストールされているか確認
    if [ -n "$EC2USER" ] && [ -n "$EC2PASSWORD" ]; then
        if ! command -v expect &> /dev/null; then
            echo "警告: 環境変数 EC2USER と EC2PASSWORD が設定されていますが、expect コマンドがインストールされていません。"
            echo "自動ログインを使用するには、次のコマンドで expect をインストールしてください:"
            echo "  Debian/Ubuntu: sudo apt-get install expect"
            echo "  Red Hat/CentOS: sudo yum install expect"
            echo "  macOS: brew install expect"
            echo ""
            echo "expectなしで続行します。ログイン後に手動でユーザー切り替えが必要です。"
        else
            echo "環境変数 EC2USER と EC2PASSWORD を使用して自動ログインを行います"
        fi
    fi
    
    # AWS SSMセッションを開始
    echo "接続中: $instance_name ($instance_id)"
    
    # EC2USERとEC2PASSWORDが設定されている場合はexpectスクリプトを使用
    if [ -n "$EC2USER" ] && [ -n "$EC2PASSWORD" ] && command -v expect &> /dev/null; then
        echo "expectを使用して $EC2USER としてログインします..."
        
        # expectスクリプトを一時ファイルに作成
        EXPECT_SCRIPT=$(mktemp)
        cat > "$EXPECT_SCRIPT" << EOF
#!/usr/bin/expect -f
# 無限のタイムアウトを設定
set timeout -1

# コマンドライン引数を取得
set instance_id [lindex \$argv 0]
set profile [lindex \$argv 1]
set rows [lindex \$argv 2]
set cols [lindex \$argv 3]
set ec2user [lindex \$argv 4]
set ec2password [lindex \$argv 5]

# SSMセッションを開始
spawn aws ssm start-session --region ap-northeast-1 --target \$instance_id --profile \$profile

# ターミナルプロンプトを待機
expect {
    "\\\$" {
        # 画面サイズを設定
        send "stty rows \$rows cols \$cols\r"
        
        # ユーザー切り替え
        send "su - \$ec2user\r"
        
        # パスワードプロンプトを待機
        expect "Password:"
        send "\$ec2password\r"
        
        # インタラクティブモードに切り替え
        interact
    }
}
EOF
        chmod +x "$EXPECT_SCRIPT"
        
        # expectスクリプトを実行
        "$EXPECT_SCRIPT" "$instance_id" "$profile" "$rows" "$cols" "$EC2USER" "$EC2PASSWORD"
        
        # 一時ファイルを削除
        rm -f "$EXPECT_SCRIPT"
    else
        # 通常のSSMセッション
        aws ssm start-session \
            --region ap-northeast-1 \
            --target "$instance_id" \
            --profile "$profile"
    fi
    
    # TMUXが実行中の場合、ウィンドウ名をリセット
    if [ -n "$TMUX" ]; then
        tmux rename-window "$(basename "$PWD")"
    fi
}

# スクリプト実行
main "$@"
