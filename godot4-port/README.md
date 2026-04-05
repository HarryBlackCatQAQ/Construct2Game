# Construct2Game Godot 4 Port

这个目录是项目的 `Godot 4` 原生重制版本，和根目录里的 `javafx-legacy`、`wails3-go` 并列存在，默认不会修改原有 Java / Wails 文件。

## 目录说明

- `assets/construct2/`: 从原 Construct2 导出中复制过来的图片和音频资源
- `data/construct2_export.json`: 从原 `data.js` 提取出来的关卡、动画与布局数据
- `tools/extract_construct2_layouts.js`: 数据提取脚本
- `scripts/`: Godot 4 的主逻辑脚本
- `scenes/main.tscn`: Godot 启动入口

## 使用方式

1. 用 Godot 4 打开 `godot4-port/project.godot`
2. 如果你想重新从 Wails 版导出数据，执行：

```powershell
cd E:\Workplace\Construct2Game
node godot4-port\tools\extract_construct2_layouts.js
```

3. 在 Godot 里直接运行主场景即可

可选：如果想直接启动到某一关做无界面验证，可以追加用户参数 `--start-stage="Layout 1"`。

## 当前实现

- 主菜单、说明页、选关页
- 5 个战斗关卡和通关页
- 玩家移动、跳跃、二段跳、近战与技能
- 普通敌人、回复怪、Boss、传送门
- HUD、关卡重开、返回主菜单

## 控制说明

- `A / D` 或方向键：移动
- `Space / K / W / 上方向键`：跳跃
- `J / Z / Enter`：普通攻击
- `Q`：飓风
- `E`：冲刺斩
- `R`：重锤
- `T`：冲击波

## 备注

这个 Godot 版本是基于原 Construct2 导出的资源和布局数据重建的“原生可玩版”，重点是保留关卡结构、角色资源和总体玩法节奏，而不是逐字节复刻 `c2runtime.js` 的全部行为。
原始 `bkmusic.ogg` 资源无法被 Godot 正常导入，因此当前版本默认跳过菜单背景音乐。
