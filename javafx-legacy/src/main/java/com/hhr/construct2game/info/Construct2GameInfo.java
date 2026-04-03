package com.hhr.construct2game.info;

import java.util.List;

/**
 * @Author: Harry
 * @Date: 2021/8/14 23:49
 * @Version 1.0
 */
public interface Construct2GameInfo {
    String STAGE_TITLE = "Construct2Game";
    String GAME_ENTRY_PATH = "/construct2Game/index.html";
    String STYLE_SHEET_PATH = "/css/jfoenix-components.css";
    String GAME_SHOWS_IMAGE_PATH = "/images/gameShowsImage.png";
    String GAME_SHOWS_BACKGROUND_PATH = "/construct2Game/images/bkgameshows.png";
    String APP_ICON_PATH = "/images/icon.png";
    String TRAY_ICON_PATH = APP_ICON_PATH;
    List<String> APPLICATION_ICON_PATHS = List.of(
            APP_ICON_PATH
    );
    double DEFAULT_WINDOW_WIDTH = 1280;
    double DEFAULT_WINDOW_HEIGHT = 800;
    double MIN_WINDOW_WIDTH = 1024;
    double MIN_WINDOW_HEIGHT = 700;
}
