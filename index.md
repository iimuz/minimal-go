---
title: Minimal go
date: 2023-08-11
lastmod: 2023-08-12
---

## 概要

Go でコードを書き始めるときの最小限の構成です。

## ファイル構成

- フォルダ
  - `.vscode`: VSCode の基本設定を記述します。
- ファイル
  - `.editorconfig`: エディタの設定です。
  - `.gitginore`: [Go 用の gitignore](https://github.com/github/gitignore/blob/main/Go.gitignore) です。
  - `go.mod`: モジュール設定です。
  - `LICENSE`: ライセンスを記載します。 MIT ライセンスを設定しています。
  - `main.go`: サンプルのコードです。
  - `Makefile`: build, lint, format などの Makefile です。
  - `README.md`: 本ドキュメントです。

## 実行方法

lint, format, build などの実行コマンドは、Makefile から行います。

## VSCode 環境の構築

### 拡張機能

`.vscode/extensions.json` に recommendations を記載しているため、必須拡張機能は recommendations からインストールします。

### Go tools のインストール

[Go 開発用に Visual Studio Code を構成する](https://learn.microsoft.com/ja-jp/azure/developer/go/configure-visual-studio-code) を参考に環境を構築します。

1. Go 拡張機能(`golang.go`)のインストール
1. `Go: Install/Update tools` で全て go ツールを選択してインストール
