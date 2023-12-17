# コマンド設定
CAT        := cat
CP         := cp
CP_FLAGSi  :=
CP_R       := cp -RT
CP_R_FLAGS :=
DEVNUL     := /dev/null
DIRSEP     := /
EXPORT     := export
FINDFILE   := find . -type f -name
PRINTENV   := printenv
RM_F       := rm -f
RM_RF      := rm -rf
SEP        := :
WHICH      := which
# Windows対応のためのコマンドの変更(Windowsかつmsysを利用していない場合)
ifeq ($(OS),Windows_NT)
	ifeq ($(MSYSTEM),)
		CAT := type
		DEVNUL := NUL
		DIRSEP := \\
		CP := copy
		CP_FLAGS := /Y
		CP_R := xcopy
		CP_R_FLAGS := /E /I /Y
		EXPORT := set
		FINDFILE := cmd.exe /C 'where /r .'
		PRINTENV := set
		RM_F := del /Q
		RM_RF := rmdir /S /Q
		SEP := ;
		SHELL := cmd.exe
		WHICH := where
	endif
endif

define find_file
    $(subst $(subst \,/,$(CURDIR)),.,$(subst \,/,$(shell $(FINDFILE) $1)))
endef

# 変数設定
BIN_DIR := bin
# 対象のパッケージ名を取得する。
ROOT_PACKAGE := $(shell go list .)
# ツールのパッケージ一覧を取得する。
COMMAND_PACKAGES := $(shell go list ./cmd/...)
# 生成するバイナリファイルのリストを取得する。
BINARIES:=$(COMMAND_PACKAGES:$(ROOT_PACKAGE)/cmd/%=$(BIN_DIR)/%)
# windowsの場合に `.exe` が必要となるため `go env` から取得する。
BINARY_SUFFIX := $(shell go env GOEXE)
# Revisionについてはgitのコミットハッシュを取得する。
REVISION := $(shell git rev-parse --short HEAD)
# cross compileを行うときにファイル名に設定する。
BINARY_OS_ARCH :=
# LDFLAGSを設定する。
# `make RELEASE=1 build` などとした場合にリリース用のビルドに変更する。
LDFLAGS_VERSION := -X '$(ROOT_PACKAGE).REVISION=$(REVISION)'
LDFLAGS_SYMBOL :=
LDFLAGS_STATIC :=
BUILD_TAGS := debug
BUILD_STATIC :=
# `-race` は cgo が有効である必要があるため、実行時の変数を確認して利用の有無を設定する。
BUILD_RACE = $(if $(CGO_ENABLED=0),-race,)
ifdef RELEASE
	LDFLAGS_SYMBOL := -w -s
	LDFLAGS_STATIC := -extldflags '-static'
	BUILD_TAGS := release
	BUILD_STATIC := -a -installsuffix netgo
	BUILD_RACE :=
endif
LDFLAGS := -buildid= $(LDFLAGS_VERSION) $(LDFLAGS_SYMBOL) $(LDFLAGS_STATIC)

all: clean test build

# lintやformatterの実行
fmt:
	go fmt
.PHONY: fmt
lint: fmt
	staticcheck
.PHONY: lint
vet: fmt
	go vet
.PHONY: vet

# バイナリをビルドする。
# `make build` を呼び出す想定。
.PHONY: build
build: $(BINARIES)
$(BINARIES): export CGO_ENABLED := 0
$(BINARIES): $(SRCS) vet
	go mod tidy
	go build \
		-trimpath \
		-tags $(BUILD_TAGS),osuergo,netgo \
		$(BUILD_RACE) \
		$(BUILD_STATIC) \
		-ldflags="$(LDFLAGS)" \
		-o $@$(BINARY_OS_ARCH)$(BINARY_SUFFIX) \
		$(@:$(BIN_DIR)/%=$(ROOT_PACKAGE)/cmd/%)

# 作成したファイル群を削除する。
.PHONY: clean
clean:
	go clean
	$(RM_RF) $(BIN_DIR)

# cross compile用の設定を行う。
# `make cross-build` のみ利用する想定。
# for文はshellに依存するため、必要な分が多くないのであれば直書きで対応する。
.PHONY: corss-build
cross-build: \
	cross-build-windows-amd64 \
	cross-build-windows-arm64 \
	cross-build-linux-amd64 \
	cross-build-linux-arm64 \
	cross-build-darwin-arm64
cross-build-with-name:
	$(MAKE) BINARY_OS_ARCH=_$(GOOS)_$(GOARCH) build
cross-build-windows-amd64:
	$(MAKE) GOOS=windows GOARCH=amd64 cross-build-with-name
cross-build-windows-arm64:
	$(MAKE) GOOS=windows GOARCH=arm64 cross-build-with-name
cross-build-linux-amd64:
	$(MAKE) GOOS=linux GOARCH=amd64 cross-build-with-name
cross-build-linux-arm64:
	$(MAKE) GOOS=linux GOARCH=arm64 cross-build-with-name
cross-build-darwin-arm64:
	$(MAKE) GOOS=darwin GOARCH=arm64 cross-build-with-name

# 設定されている変数を確認する。
.PHONY: printenv
printenv:
	@echo SHELL            : $(SHELL)
	@echo CURDIR           : $(CURDIR)
	@echo DEVNUL           : $(DEVNUL)
	@echo SEP              : "$(SEP)"
	@echo WHICH GO         : $(shell $(WHICH) go)
	@echo GOOS             : $(GOOS)
	@echo GOARCH           : $(GOARCH)
	@echo REVISION         : $(REVISION)
	@echo SRCS             : $(SRCS)
	@echo LDFLAGS          : $(LDFLAGS)
	@echo BINARIES         : $(BINARIES)
	@echo BIN_DIR          : $(BIN_DIR)
	@echo ROOT_PACKAGE     : $(ROOT_PACKAGE)
	@echo COMMAND_PACKAGES : $(COMMAND_PACKAGES)
