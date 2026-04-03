package main

import "runtime"

const (
	appName      = "Construct2Game"
	appVersion   = "0.1.0"
	wailsVersion = "v3.0.0-alpha.74"

	commandHelp   = "show-game-help"
	commandEnv    = "show-environment"
	commandReload = "reload-game"
	commandMain   = "return-main-menu"
	commandFocus  = "focus-game"
	commandStatus = "status-message"
)

type EnvironmentInfo struct {
	AppName      string `json:"appName"`
	AppVersion   string `json:"appVersion"`
	GoVersion    string `json:"goVersion"`
	WailsVersion string `json:"wailsVersion"`
	GOOS         string `json:"goos"`
	GOARCH       string `json:"goarch"`
}

type FrontendCommand struct {
	Name    string `json:"name"`
	Message string `json:"message,omitempty"`
}

type GameService struct {
	desktop *DesktopApp
}

func NewGameService(desktop *DesktopApp) *GameService {
	return &GameService{desktop: desktop}
}

func (g *GameService) GetEnvironmentInfo() EnvironmentInfo {
	return EnvironmentInfo{
		AppName:      appName,
		AppVersion:   appVersion,
		GoVersion:    runtime.Version(),
		WailsVersion: wailsVersion,
		GOOS:         runtime.GOOS,
		GOARCH:       runtime.GOARCH,
	}
}

func (g *GameService) ToggleFullscreen() {
	g.desktop.toggleFullscreen()
}

func (g *GameService) ShowWindow() {
	g.desktop.showWindow()
}

func (g *GameService) HideWindow() {
	g.desktop.hideWindow()
}

func (g *GameService) ReloadShell() {
	g.desktop.reloadShell()
}

func (g *GameService) ReloadGame() {
	g.desktop.emitCommand(commandReload, "")
}

func (g *GameService) ReturnToMainMenu() {
	g.desktop.emitCommand(commandMain, "")
}

func (g *GameService) ShowGameHelp() {
	g.desktop.emitCommand(commandHelp, "")
}

func (g *GameService) ShowEnvironment() {
	g.desktop.emitCommand(commandEnv, "")
}

func (g *GameService) FocusGame() {
	g.desktop.emitCommand(commandFocus, "")
}

func (g *GameService) QuitApp() {
	g.desktop.quit()
}
