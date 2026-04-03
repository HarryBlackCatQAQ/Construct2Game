package main

import (
	"embed"
	"log"
	"runtime"

	"github.com/wailsapp/wails/v3/pkg/application"
	"github.com/wailsapp/wails/v3/pkg/events"
)

//go:embed all:frontend/dist
var assets embed.FS

//go:embed build/appicon.png
var appIcon []byte

type DesktopApp struct {
	app        *application.App
	mainWindow *application.WebviewWindow
	systemTray *application.SystemTray
	quitting   bool
}

func main() {
	desktop := &DesktopApp{}
	service := NewGameService(desktop)

	app := application.New(application.Options{
		Name:        appName,
		Description: "Construct2Game desktop edition powered by Wails 3 and Go",
		Icon:        appIcon,
		Services: []application.Service{
			application.NewService(service),
		},
		Assets: application.AssetOptions{
			Handler: application.AssetFileServerFS(assets),
		},
		Mac: application.MacOptions{
			ApplicationShouldTerminateAfterLastWindowClosed: false,
		},
		ShouldQuit: func() bool {
			desktop.quitting = true
			return true
		},
	})

	desktop.app = app
	app.Menu.Set(desktop.buildApplicationMenu())
	desktop.mainWindow = desktop.buildMainWindow()
	desktop.systemTray = desktop.buildSystemTray()
	desktop.registerAppHooks()

	if err := app.Run(); err != nil {
		log.Fatal(err)
	}
}

func (d *DesktopApp) buildMainWindow() *application.WebviewWindow {
	windowMenu := d.buildWindowMenu()
	window := d.app.Window.NewWithOptions(application.WebviewWindowOptions{
		Name:                       "construct2-main",
		Title:                      appName,
		Width:                      1366,
		Height:                     840,
		MinWidth:                   1120,
		MinHeight:                  760,
		URL:                        "/",
		BackgroundColour:           application.NewRGB(10, 12, 17),
		DefaultContextMenuDisabled: true,
		Windows: application.WindowsWindow{
			Menu:             windowMenu,
			ResizeDebounceMS: 10,
		},
		Linux: application.LinuxWindow{
			Icon:             appIcon,
			Menu:             windowMenu,
			WebviewGpuPolicy: application.WebviewGpuPolicyOnDemand,
		},
		KeyBindings: map[string]func(window application.Window){
			"F11": func(window application.Window) {
				window.ToggleFullscreen()
			},
		},
	})

	window.RegisterHook(events.Common.WindowClosing, func(event *application.WindowEvent) {
		if d.quitting {
			return
		}
		window.Hide()
		d.emitCommand(commandStatus, "窗口已隐藏到托盘，可从托盘菜单重新打开。")
		event.Cancel()
	})

	return window
}

func (d *DesktopApp) buildApplicationMenu() *application.Menu {
	menu := d.app.NewMenu()
	if runtime.GOOS == "darwin" {
		menu.AddRole(application.AppMenu)
	}
	menu.Append(d.buildWindowMenu())

	helpMenu := menu.AddSubmenu("帮助")
	helpMenu.Add("游戏说明").OnClick(func(ctx *application.Context) {
		d.showWindow()
		d.emitCommand(commandHelp, "")
	})
	helpMenu.Add("运行环境").OnClick(func(ctx *application.Context) {
		d.showWindow()
		d.emitCommand(commandEnv, "")
	})
	helpMenu.AddSeparator()
	helpMenu.Add("关于 Construct2Game").OnClick(func(ctx *application.Context) {
		d.app.Dialog.Info().
			SetTitle(appName).
			SetMessage("Wails 3 + Go 桌面版，保留原始 Construct2 游戏资源并提供跨平台桌面壳层。").
			SetIcon(appIcon).
			Show()
	})

	return menu
}

func (d *DesktopApp) buildWindowMenu() *application.Menu {
	menu := d.app.NewMenu()

	gameMenu := menu.AddSubmenu("游戏")
	gameMenu.Add("显示窗口").OnClick(func(ctx *application.Context) {
		d.showWindow()
	})
	gameMenu.Add("返回主菜单").OnClick(func(ctx *application.Context) {
		d.showWindow()
		d.emitCommand(commandMain, "")
	})
	gameMenu.Add("重新载入游戏").OnClick(func(ctx *application.Context) {
		d.showWindow()
		d.emitCommand(commandReload, "")
	})
	gameMenu.AddSeparator()
	gameMenu.Add("退出").OnClick(func(ctx *application.Context) {
		d.quit()
	})

	menu.AddRole(application.EditMenu)

	viewMenu := menu.AddSubmenu("视图")
	viewMenu.AddRole(application.Reload)
	viewMenu.AddRole(application.ForceReload)
	viewMenu.AddSeparator()
	viewMenu.AddRole(application.ResetZoom)
	viewMenu.AddRole(application.ZoomIn)
	viewMenu.AddRole(application.ZoomOut)
	viewMenu.AddSeparator()
	viewMenu.AddRole(application.ToggleFullscreen)

	if runtime.GOOS == "darwin" {
		menu.AddRole(application.WindowMenu)
	}

	return menu
}

func (d *DesktopApp) buildSystemTray() *application.SystemTray {
	tray := d.app.SystemTray.New()
	tray.SetTooltip(appName)
	tray.SetIcon(appIcon)

	trayMenu := d.app.NewMenu()
	trayMenu.Add("打开游戏").OnClick(func(ctx *application.Context) {
		d.showWindow()
	})
	trayMenu.Add("返回主菜单").OnClick(func(ctx *application.Context) {
		d.showWindow()
		d.emitCommand(commandMain, "")
	})
	trayMenu.Add("重新载入游戏").OnClick(func(ctx *application.Context) {
		d.showWindow()
		d.emitCommand(commandReload, "")
	})
	trayMenu.AddSeparator()
	trayMenu.Add("游戏说明").OnClick(func(ctx *application.Context) {
		d.showWindow()
		d.emitCommand(commandHelp, "")
	})
	trayMenu.Add("运行环境").OnClick(func(ctx *application.Context) {
		d.showWindow()
		d.emitCommand(commandEnv, "")
	})
	trayMenu.AddSeparator()
	trayMenu.Add("退出").OnClick(func(ctx *application.Context) {
		d.quit()
	})

	tray.SetMenu(trayMenu)
	tray.AttachWindow(d.mainWindow).WindowOffset(8)

	return tray
}

func (d *DesktopApp) registerAppHooks() {
	if runtime.GOOS == "darwin" {
		d.app.Event.OnApplicationEvent(events.Mac.ApplicationShouldHandleReopen, func(event *application.ApplicationEvent) {
			d.showWindow()
		})
	}
}

func (d *DesktopApp) emitCommand(name string, message string) {
	if d.app == nil {
		return
	}
	d.app.Event.Emit("desktop:command", FrontendCommand{
		Name:    name,
		Message: message,
	})
}

func (d *DesktopApp) showWindow() {
	if d.mainWindow == nil {
		return
	}
	d.mainWindow.Show().Focus()
}

func (d *DesktopApp) hideWindow() {
	if d.mainWindow == nil {
		return
	}
	d.mainWindow.Hide()
}

func (d *DesktopApp) toggleFullscreen() {
	if d.mainWindow == nil {
		return
	}
	d.mainWindow.ToggleFullscreen()
}

func (d *DesktopApp) reloadShell() {
	if d.mainWindow == nil {
		return
	}
	d.mainWindow.Reload()
}

func (d *DesktopApp) quit() {
	d.quitting = true
	if d.app != nil {
		d.app.Quit()
	}
}
