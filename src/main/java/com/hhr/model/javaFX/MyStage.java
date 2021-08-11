package com.hhr.model.javaFX;

import com.hhr.util.ResourcesPathUtil;
import javafx.event.EventHandler;
import javafx.fxml.FXMLLoader;
import javafx.scene.Parent;
import javafx.scene.Scene;
import javafx.scene.image.Image;
import javafx.scene.input.KeyCombination;
import javafx.scene.input.KeyEvent;
import javafx.scene.layout.BorderPane;
import javafx.stage.Screen;
import javafx.stage.Stage;

/**
 * @Author: Harry
 * @Date: 2021/8/11 18:39
 * @Version 1.0
 */
public class MyStage {
    private static MyStage instance;
    private Stage stage;

    /**
     * 单例模式
     * @return
     */
    public static MyStage getInstance() {
        if (instance == null) {
            synchronized (MyStage.class) {
                if (instance == null) {
                    instance = new MyStage();
                }
            }
        }
        return instance;
    }

    private MyStage(){
    }

    public void initStage(){
        //设置标题
        this.stage.setTitle("Construct2Game");
        //设置图标
        this.stage.getIcons().add(new Image(ResourcesPathUtil.getPathOfString("/images/icon.png")));
        //设置禁止缩放
//        this.setResizable(false);
        //设置托盘
//        MySystemTray.getInstance().listen(this);
        //初始化初始界面
        setScene("/fxml/main.fxml");
        //设置界面关闭弹出监听
//        setOnCloseRequest();

    }

    /**
     * Change user interface
     * @param fxmlPath interface path
     */
    private void setScene(String fxmlPath){
        try {
            Parent root = FXMLLoader.load(ResourcesPathUtil.getPathOfUrl(fxmlPath));
            BorderPane pane = (BorderPane)root;

            MyWebView myWebView = MyWebView.getInstance();

            pane.setCenter(myWebView.getBrowser());

            Scene scene = new Scene(root);
            scene.getStylesheets().add(ResourcesPathUtil.getPathOfUrl("/css/jfoenix-components.css").toExternalForm());

            stage.setScene(scene);
            pane.setOnKeyPressed(new EventHandler<KeyEvent>() {
                @Override
                public void handle(KeyEvent event) {
                    if(event.getCode().getName().equals("F11")){
                        stage.setFullScreen(true);
                    }
                }
            });

        } catch (Exception e) {
            System.err.println("fxml path is wrong.");
            System.err.println(e);
        }
    }

    public Stage getStage() {
        return stage;
    }

    public void setStage(Stage stage) {
        this.stage = stage;
    }
}
