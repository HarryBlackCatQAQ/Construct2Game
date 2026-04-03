# Construct2Game

基于 `Java 21 + JavaFX WebView` 的本地桌面版 Construct2 小游戏。

这次已经把项目从旧的 `Java 8 / Spring Boot JavaFX support / JFoenix` 方案迁到了纯 JavaFX 启动链，目标是：

- 可以直接用 `Java 21` 启动
- 本地跨平台运行更直接
- 窗口图标、Dock/Taskbar 图标和托盘逻辑更正常
- 减少旧 WebView 状态残留带来的点击、显示和重载问题

## 运行要求

- JDK `21`
- 不需要单独安装 Maven，项目自带 Maven Wrapper

先确认版本：

```bash
java -version
```

## 本地启动

### macOS

推荐直接运行：

```bash
./run-mac.command
```

或者：

```bash
./mvnw -DskipTests javafx:run
```

### Linux

推荐直接运行：

```bash
./run-linux.sh
```

或者：

```bash
./mvnw -DskipTests javafx:run
```

### Windows

推荐直接运行：

```bat
run-windows.bat
```

或者：

```bat
mvnw.cmd -DskipTests javafx:run
```

## 已修复的重点

- 构建链改为 `OpenJFX + Maven`，可在 `Java 21` 下编译和运行
- 移除了旧版 `Spring Boot JavaFX support` 与 `JFoenix` 兼容层
- 主界面改成标准 JavaFX FXML 控制器
- `WebView` 重建与重载逻辑更稳，避免旧页面状态残留
- 默认禁用右键菜单，点击后会自动把焦点还给游戏区域
- `F11` 全屏切换改成场景级快捷键，可靠性更高
- 统一窗口图标、托盘图标和任务栏图标
- 系统托盘不可用时会自动回退为正常退出流程
- 修掉了 `sw.js` 里明显的日志变量错误
- 更新了游戏页面标题与 manifest 名称

## 操作说明

- `F11`：切换全屏
- `游戏主菜单`：重载游戏并回到初始状态
- `游戏说明`：打开说明图
- `运行环境`：查看 Java / JavaFX / WebKit / 系统信息
- `重载游戏`：重建 WebView，适合卡住或显示异常时恢复

## 注意事项

- 某些 Linux 桌面环境默认不支持系统托盘，这种情况下关闭窗口会直接走退出确认
- 游戏本体仍然是 Construct2 导出的网页资源，如果后续想继续修更深层的碰撞或关卡逻辑，需要继续检查 `data.js / c2runtime.js`
- 如果你要把 `src/main/resources/construct2Game` 单独部署到 Web 服务器，依然可以单独使用那部分资源

## 构建验证

本地已验证：

```bash
sh mvnw -q test
./mvnw -DskipTests javafx:run
```

如果只是想快速启动，本地直接用上面的平台脚本就可以。
