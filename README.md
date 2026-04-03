# Construct2Game

<p align="center">
  <img src="./wails3-go/build/appicon.png" width="120" alt="Construct2Game icon" />
</p>

一个以 Construct2 游戏资源为核心的桌面项目工作区，当前同时保留了两套桌面实现：

- `wails3-go/`: 新版桌面壳层，基于 `Wails 3 + Go`，当前推荐使用
- `javafx-legacy/`: 旧版桌面壳层，基于 `Java 21 + JavaFX WebView`

两个版本共用同一套游戏素材与主要玩法，差异主要在桌面运行时、窗口壳层、打包方式以及图形兼容性。

## 项目状态

| 版本 | 技术栈 | 当前定位 | 状态 |
| --- | --- | --- | --- |
| `wails3-go` | Wails 3 + Go + Vite | 主力版本 | 推荐日常运行、开发与打包 |
| `javafx-legacy` | Java 21 + JavaFX WebView + Maven | 兼容保留版本 | 可启动，但仍可能有 WebView 显示兼容问题 |

## 界面与玩法预览

两个版本共享同一套游戏画面资源，下面这两张图可以直接代表当前项目的主视觉与操作说明。

### 开始画面

![Construct2Game Start Preview](./wails3-go/frontend/public/app-assets/startUpImage.png)

### 操作说明画面

![Construct2Game Guide Preview](./wails3-go/frontend/public/app-assets/gameShowsImage.png)

## 版本说明

### Wails 3 + Go 版

目录：

```text
/Users/mac/Desktop/workplace/Construct2Game/wails3-go
```

这个版本是当前推荐版本，特点是：

- 使用原生桌面窗口承载 Construct2 游戏资源
- 顶部工具栏集成了 `返回主菜单`、`重新载入`、`游戏说明`、`运行环境`、`全屏`
- 支持系统托盘、菜单栏、窗口隐藏与恢复
- 支持直接打包出 macOS 可执行文件和 Windows `.exe`
- 相比 JavaFX 版，当前实际运行表现更稳定

更详细的说明见：

- [wails3-go/README.md](/Users/mac/Desktop/workplace/Construct2Game/wails3-go/README.md)

### JavaFX Legacy 版

目录：

```text
/Users/mac/Desktop/workplace/Construct2Game/javafx-legacy
```

这个版本是保留的旧桌面实现，特点是：

- 已迁移到 `Java 21 + JavaFX` 启动链
- 保留了原来的 Java 桌面壳层思路
- 支持 `F11` 全屏、窗口图标、托盘回退和 WebView 重载
- 更适合做历史版本保留、代码参考和兼容性对照

当前状态说明：

- 这个版本已经可以启动
- 但根据当前实测结论，仍可能存在 WebView 内核导致的点击、显示或渲染兼容问题
- 因此如果是实际游玩或对外分发，优先建议使用 `wails3-go`

更详细的说明见：

- [javafx-legacy/README.md](/Users/mac/Desktop/workplace/Construct2Game/javafx-legacy/README.md)

## 快速开始

### 推荐启动方式

如果你只是想直接启动新版游戏，在根目录运行：

```bash
cd /Users/mac/Desktop/workplace/Construct2Game
./start-game.command
```

对应平台脚本：

- macOS: [start-game.command](/Users/mac/Desktop/workplace/Construct2Game/start-game.command)
- Linux: [start-game.sh](/Users/mac/Desktop/workplace/Construct2Game/start-game.sh)
- Windows: [start-game.bat](/Users/mac/Desktop/workplace/Construct2Game/start-game.bat)

### 直接进入 Go 版本

macOS:

```bash
cd /Users/mac/Desktop/workplace/Construct2Game/wails3-go
./run-dev.command
```

Linux:

```bash
cd /Users/mac/Desktop/workplace/Construct2Game/wails3-go
./run-dev.sh
```

Windows:

```powershell
cd /Users/mac/Desktop/workplace/Construct2Game/wails3-go
run-dev.bat
```

### 直接进入 Java 版本

macOS:

```bash
cd /Users/mac/Desktop/workplace/Construct2Game/javafx-legacy
./run-mac.command
```

Linux:

```bash
cd /Users/mac/Desktop/workplace/Construct2Game/javafx-legacy
./run-linux.sh
```

Windows:

```powershell
cd /Users/mac/Desktop/workplace/Construct2Game/javafx-legacy
run-windows.bat
```

## 打包说明

### Go 版本打包

macOS 本机打包：

```bash
cd /Users/mac/Desktop/workplace/Construct2Game/wails3-go
export PATH="$HOME/go/bin:$PATH"
npm --prefix frontend install
wails3 build
```

在 macOS 上交叉打包 Windows `.exe`：

```bash
cd /Users/mac/Desktop/workplace/Construct2Game/wails3-go
export PATH="$HOME/go/bin:$PATH"
npm --prefix frontend install
GOOS=windows GOARCH=amd64 wails3 build
```

当前已经验证能生成：

- `wails3-go/bin/Construct2Game`
- `wails3-go/bin/Construct2Game.exe`

### Java 版本运行与构建

Java 版本当前主要作为兼容保留版本，常用命令：

```bash
cd /Users/mac/Desktop/workplace/Construct2Game/javafx-legacy
./mvnw -q test
./mvnw -DskipTests javafx:run
```

## 目录结构

```text
Construct2Game/
├── README.md
├── start-game.command
├── start-game.sh
├── start-game.bat
├── javafx-legacy/
│   ├── README.md
│   └── ...
└── wails3-go/
    ├── README.md
    └── ...
```

## 选择建议

- 想直接玩、继续开发、打包发给别人：用 `wails3-go`
- 想保留旧实现、研究 Java 桌面封装方式、做历史对照：看 `javafx-legacy`

如果你后面还想继续把根目录 `README` 做得更像正式发布页，我也可以继续帮你补：

- 版本徽章
- 更新日志入口
- 发行包下载说明
- 常见问题与已知问题列表
