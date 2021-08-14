package com.hhr.construct2game.view.fx;


import com.hhr.construct2game.info.Construct2GameInfo;
import com.hhr.construct2game.view.fx.dialog.StageCloseDialog;
import de.felixroske.jfxsupport.GUIState;
import javafx.event.EventHandler;
import javafx.scene.Scene;
import javafx.stage.Stage;
import javafx.stage.WindowEvent;
import lombok.extern.slf4j.Slf4j;


/**
 * @Author: Harry
 * @Date: 2021/8/11 18:39
 * @Version 1.0
 */
@Slf4j
public class MyStage implements Construct2GameInfo {
    private static MyStage instance;

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
        this.getStage().setTitle(STAGE_TITLE);

        //设置托盘
        MySystemTray.getInstance().listen(getStage());

        //设置界面关闭弹出监听
        setOnCloseRequest();

    }

    /**
     * set OnCloseRequest
     */
    private void setOnCloseRequest(){
        this.getStage().setOnCloseRequest(new EventHandler<WindowEvent>() {
            @Override
            public void handle(WindowEvent event) {
                StageCloseDialog stageCloseDialog = new StageCloseDialog();
                stageCloseDialog.show();
            }
        });
    }


    public Stage getStage() {
        return GUIState.getStage();
    }

    public Scene getScene() {
        return GUIState.getScene();
    }
}

