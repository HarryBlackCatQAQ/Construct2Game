package com.hhr.construct2game.view;

import com.hhr.construct2game.info.Construct2GameInfo;
import com.hhr.construct2game.util.ResourcesPathUtil;
import com.hhr.construct2game.view.fx.MyStage;
import com.hhr.construct2game.view.fx.MyWebView;
import javafx.fxml.FXMLLoader;
import javafx.scene.Parent;
import javafx.scene.input.KeyCode;
import javafx.scene.input.KeyEvent;
import javafx.scene.layout.BorderPane;
import javafx.scene.layout.Pane;

import java.io.IOException;

/**
 * @Author: Harry
 * @Date: 2021/8/14 20:19
 * @Version 1.0
 */
public class MainView implements Construct2GameInfo {
    private static final String FULL_SCREEN_HANDLER_KEY = "construct2game.fullscreen-handler";

    public Parent getView() {
        try {
            FXMLLoader loader = new FXMLLoader(ResourcesPathUtil.getRequiredResource("/fxml/main.fxml"));
            BorderPane pane = loader.load();
            setWebView(pane);
            initFullScreenEvent(pane);
            addStyleSheet(pane);
            return pane;
        } catch (IOException exception) {
            throw new IllegalStateException("Failed to load main view.", exception);
        }
    }

    private void addStyleSheet(Parent parent) {
        String styleSheet = ResourcesPathUtil.getPathOfString(STYLE_SHEET_PATH);
        if (!parent.getStylesheets().contains(styleSheet)) {
            parent.getStylesheets().add(styleSheet);
        }
    }

    /**
     * 添加WebView到BorderPane中
     */
    private void setWebView(BorderPane pane){
        MyWebView.getInstance().attachTo(pane);
    }

    /**
     * 初始化全屏事件
     */
    private void initFullScreenEvent(Pane pane){
        pane.sceneProperty().addListener((observable, oldScene, newScene) -> {
            if (newScene == null) {
                return;
            }
            if (newScene.getProperties().putIfAbsent(FULL_SCREEN_HANDLER_KEY, Boolean.TRUE) != null) {
                return;
            }
            newScene.addEventFilter(KeyEvent.KEY_PRESSED, event -> {
                if (event.getCode() == KeyCode.F11) {
                    MyStage.getInstance().toggleFullScreen();
                    event.consume();
                }
            });
        });
    }
}
