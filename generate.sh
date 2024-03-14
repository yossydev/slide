#!/bin/bash

# タイトルとファイル名の入力を促す
read -p "スライドのタイトルを入力してください: " TITLE
read -p "生成するファイル名を入力してください（拡張子なし）: " FILENAME

# 必要ならslidesディレクトリを作成
mkdir -p slides

# sedを使用してテンプレート内のプレースホルダーを置換し、指定されたファイル名でslidesディレクトリ内の新しいファイルに出力
sed "s/{{TITLE}}/$TITLE/g" template.md > "slides/${FILENAME}.md"

echo "ファイルが生成されました: slides/${FILENAME}.md"
