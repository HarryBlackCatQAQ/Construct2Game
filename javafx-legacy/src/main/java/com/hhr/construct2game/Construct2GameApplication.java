package com.hhr.construct2game;

import com.hhr.construct2game.info.Construct2GameInfo;
import com.hhr.construct2game.util.LocalGameHttpServer;
import com.hhr.construct2game.util.ResourcesPathUtil;
import com.hhr.construct2game.view.MainView;
import com.hhr.construct2game.view.fx.MyStage;
import com.hhr.construct2game.view.fx.MyWebView;
import javafx.application.Application;
import javafx.application.Platform;
import javafx.scene.Parent;
import javafx.scene.Scene;
import javafx.scene.image.Image;
import javafx.stage.Stage;

import javax.imageio.ImageIO;
import java.awt.GraphicsEnvironment;
import java.awt.Taskbar;
import java.awt.image.BufferedImage;
import java.io.InputStream;
import java.util.List;
import java.util.Objects;
import java.util.stream.Collectors;

/**
 * @Author: Harry
 * @Date: 2021/8/14 20:19
 * @Version 1.0
 */
public class Construct2GameApplication extends Application implements Construct2GameInfo {
    private static Construct2GameApplication instance;

    public static void main(String[] args) {
        System.setProperty("apple.awt.application.name", STAGE_TITLE);
        launch(args);
    }

    @Override
    public void init() {
        instance = this;
    }

    @Override
    public void start(Stage stage) {
        configureTaskbarIcon();
        Parent root = new MainView().getView();
        Scene scene = new Scene(root, DEFAULT_WINDOW_WIDTH, DEFAULT_WINDOW_HEIGHT);
        MyStage.getInstance().init(stage, scene, loadApplicationIcons());
        stage.show();
        Platform.runLater(MyWebView.getInstance()::requestFocus);
    }

    /**
     * 重载程序的 UI 与游戏页面，避免旧 WebView 状态残留。
     */
    public void relaunch(){
        Platform.runLater(() -> {
            MyWebView.getInstance().reloadGame(true);
            MyStage.getInstance().restoreWindow();
        });
    }

    @Override
    public void stop() {
        MyWebView.getInstance().dispose();
        LocalGameHttpServer.getInstance().stop();
        MyStage.getInstance().shutdown();
    }

    public static Construct2GameApplication getInstance() {
        return Objects.requireNonNull(instance, "Application has not been initialized yet.");
    }

    public static List<Image> loadApplicationIcons() {
        return APPLICATION_ICON_PATHS.stream()
                .map(ResourcesPathUtil::getPathOfString)
                .map(Image::new)
                .collect(Collectors.toList());
    }

    private void configureTaskbarIcon() {
        if (GraphicsEnvironment.isHeadless() || !Taskbar.isTaskbarSupported()) {
            return;
        }
        try {
            Taskbar taskbar = Taskbar.getTaskbar();
            if (!taskbar.isSupported(Taskbar.Feature.ICON_IMAGE)) {
                return;
            }
            try (InputStream inputStream = ResourcesPathUtil.openResource(APPLICATION_ICON_PATHS.get(APPLICATION_ICON_PATHS.size() - 1))) {
                BufferedImage image = ImageIO.read(inputStream);
                if (image != null) {
                    taskbar.setIconImage(image);
                }
            }
        } catch (Exception exception) {
            System.err.println("Unable to set taskbar icon: " + exception.getMessage());
        }
    }
}
