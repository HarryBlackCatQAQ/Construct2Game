package com.hhr.construct2game.view;

import com.hhr.construct2game.util.ResourcesPathUtil;
import com.hhr.construct2game.view.fx.MyStage;
import com.hhr.construct2game.view.fx.MyWebView;
import de.felixroske.jfxsupport.AbstractFxmlView;
import de.felixroske.jfxsupport.FXMLView;
import javafx.application.Platform;
import javafx.event.EventHandler;
import javafx.scene.Parent;
import javafx.scene.input.KeyCode;
import javafx.scene.input.KeyEvent;
import javafx.scene.layout.BorderPane;
import javafx.scene.layout.Pane;

/**
 * @Author: Harry
 * @Date: 2021/8/14 20:19
 * @Version 1.0
 */
@FXMLView(value = "/fxml/main.fxml")
public class MainView extends AbstractFxmlView {


    @Override
    public Parent getView() {
        Parent parent = super.getView();
        BorderPane pane = (BorderPane)parent;

        setWebView(pane);

        initFullScreenEvent(pane);

        //添加css  注解不知道为啥永不了(等解决)
        Platform.runLater(new Runnable() {
            @Override
            public void run() {
                if (MyStage.getInstance().getScene() != null){
                    MyStage.getInstance().getScene().getStylesheets().add(ResourcesPathUtil.getPathOfUrl("/css/jfoenix-components.css").toExternalForm());
                }
            }
        });
        return parent;
    }



    /**
     * 添加WebView到BorderPane中
     */
    private void setWebView(BorderPane pane){
        MyWebView myWebView = MyWebView.getInstance();

        pane.setCenter(myWebView.getBrowser());
    }

    /**
     * 初始化全屏事件
     */
    private void initFullScreenEvent(Pane pane){
        pane.setOnKeyPressed(new EventHandler<KeyEvent>() {
            @Override
            public void handle(KeyEvent event) {
                if(event.getCode().getName().equals(KeyCode.F11.getName())){
                    MyStage.getInstance().getStage().setFullScreen(true);
                }
            }
        });
    }


}
