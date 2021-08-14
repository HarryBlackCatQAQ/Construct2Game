package com.hhr.construct2game.view;

import com.jfoenix.controls.JFXProgressBar;
import de.felixroske.jfxsupport.SplashScreen;
import javafx.scene.Parent;
import javafx.scene.image.ImageView;
import javafx.scene.layout.VBox;

/**
 * @Author: Harry
 * @Date: 2021/8/14 22:38
 * @Version 1.0
 */

public class StartUpPage extends SplashScreen {

    @Override
    public Parent getParent() {
        ImageView imageView = new ImageView(this.getClass().getResource(this.getImagePath()).toExternalForm());
        JFXProgressBar splashProgressBar = new JFXProgressBar();
        splashProgressBar.setPrefWidth(imageView.getImage().getWidth());
        VBox vbox = new VBox();
        vbox.getChildren().addAll(imageView, splashProgressBar);
        return vbox;
    }

    /**
     * 是否显示: true显示
     * @return
     */
    @Override
    public boolean visible() {
        return true;
    }

    /***
     * 启动页图片
     * @return
     */
    @Override
    public String getImagePath() {
        // 图片路径
        return "/images/startUpImage.png";
    }
}
