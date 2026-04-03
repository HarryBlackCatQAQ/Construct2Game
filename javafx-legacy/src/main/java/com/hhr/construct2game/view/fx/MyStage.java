package com.hhr.construct2game.view.fx;


import com.hhr.construct2game.info.Construct2GameInfo;
import com.hhr.construct2game.view.fx.dialog.StageCloseDialog;
import javafx.scene.Scene;
import javafx.scene.image.Image;
import javafx.scene.input.KeyCombination;
import javafx.stage.Stage;

import java.util.Collection;


/**
 * @Author: Harry
 * @Date: 2021/8/11 18:39
 * @Version 1.0
 */
public class MyStage implements Construct2GameInfo {
    private static final MyStage INSTANCE = new MyStage();
    private Stage stage;
    private Scene scene;

    /**
     * 单例模式
     * @return
     */
    public static MyStage getInstance() {
        return INSTANCE;
    }

    private MyStage(){

    }

    public void init(Stage stage, Scene scene, Collection<Image> icons){
        this.stage = stage;
        this.scene = scene;
        this.stage.setScene(scene);
        this.stage.setTitle(STAGE_TITLE);
        this.stage.setMinWidth(MIN_WINDOW_WIDTH);
        this.stage.setMinHeight(MIN_WINDOW_HEIGHT);
        this.stage.getIcons().setAll(icons);
        this.stage.setFullScreenExitKeyCombination(KeyCombination.NO_MATCH);
        this.stage.setFullScreenExitHint("按 F11 退出全屏");
        this.stage.centerOnScreen();
        MySystemTray.getInstance().listen(stage);
        setOnCloseRequest();
    }

    /**
     * set OnCloseRequest
     */
    private void setOnCloseRequest(){
        this.stage.setOnCloseRequest(event -> {
            event.consume();
            StageCloseDialog stageCloseDialog = new StageCloseDialog();
            stageCloseDialog.show();
        });
    }

    public void toggleFullScreen() {
        if (stage == null) {
            return;
        }
        stage.setFullScreen(!stage.isFullScreen());
    }

    public void restoreWindow() {
        if (stage == null) {
            return;
        }
        if (stage.isIconified()) {
            stage.setIconified(false);
        }
        if (!stage.isShowing()) {
            stage.show();
        }
        stage.toFront();
        requestFocus();
    }

    public void requestFocus() {
        if (scene != null && scene.getRoot() != null) {
            scene.getRoot().requestFocus();
        }
        MyWebView.getInstance().requestFocus();
    }

    public void shutdown() {
        MySystemTray.getInstance().shutdown();
    }

    public Stage getStage() {
        return stage;
    }

    public Scene getScene() {
        return scene;
    }
}
