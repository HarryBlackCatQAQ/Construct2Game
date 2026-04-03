# Construct2Game Wails 3 Desktop Port

这个目录是新的 `Wails 3 + Go` 桌面版项目。

原来的 JavaFX 版本已经保留在：

```text
/Users/mac/Desktop/workplace/Construct2Game/javafx-legacy
```

## 项目说明

- 现有游戏资源继续使用原来的 Construct2 导出内容
- 桌面壳层改成 `Wails 3 + Go`
- 支持窗口菜单、系统托盘、游戏说明、运行环境查看、全屏和重载
- 图标统一使用项目里的原始 `icon.png`

## 准备环境

先确保已经安装：

- Go
- Node.js / npm
- `wails3` CLI

如果 `wails3` 命令找不到，先把 Go 的 bin 目录加到 PATH：

```bash
export PATH="$HOME/go/bin:$PATH"
```

## 本地开发启动

首次进入项目后执行：

```bash
cd /Users/mac/Desktop/workplace/Construct2Game/wails3-go
npm --prefix frontend install
wails3 dev
```

如果你只是想直接玩，不想每次手动切目录，推荐在工作区根目录运行：

```bash
cd /Users/mac/Desktop/workplace/Construct2Game
./start-game.command
```

## 打包成可运行文件

下面这两套命令我已经在当前项目里实际验证过。

### macOS 打包

在 macOS 本机执行：

```bash
cd /Users/mac/Desktop/workplace/Construct2Game/wails3-go
export PATH="$HOME/go/bin:$PATH"
npm --prefix frontend install
wails3 build
```

打包完成后，产物会出现在：

- `bin/Construct2Game`
- `bin/Construct2Game.dev.app`（如果当前构建同时生成 `.app` 包，也会在这里）

终端直接运行：

```bash
./bin/Construct2Game
```

如果 Finder 里有 `.app`，也可以直接双击打开。

### Windows 打包

最稳的方法是在 Windows 本机执行：

```powershell
cd /Users/mac/Desktop/workplace/Construct2Game/wails3-go
npm --prefix frontend install
wails3 build
```

打包完成后，产物通常在：

- `bin/Construct2Game.exe`

### 在 macOS 上交叉打包 Windows `.exe`

如果你现在手上是 mac，也可以直接在当前项目里交叉打一个 Windows 可执行文件：

```bash
cd /Users/mac/Desktop/workplace/Construct2Game/wails3-go
export PATH="$HOME/go/bin:$PATH"
npm --prefix frontend install
GOOS=windows GOARCH=amd64 wails3 build
```

打包完成后，产物在：

- `bin/Construct2Game.exe`

这个命令我已经实际跑过，当前仓库可以正常生成 `PE32+` 的 Windows GUI 可执行文件。

## 常用命令

开发运行：

```bash
wails3 dev
```

构建当前平台：

```bash
wails3 build
```

如果你后面还要做 Linux 交叉构建，这个项目也已经带了 Docker 任务：

```bash
wails3 task setup:docker
```

## 目录说明

- `main.go`: Wails 应用入口、窗口/托盘/菜单
- `gameservice.go`: Go 暴露给前端的服务
- `frontend/src/main.js`: 桌面壳层前端逻辑
- `frontend/public/game`: 原始 Construct2 游戏资源
- `build/`: Wails 构建配置与多平台图标
