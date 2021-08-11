package com.hhr;

import com.hhr.model.javaFX.MyStage;
import javafx.application.Application;
import javafx.stage.Stage;

/**
 * @Author: Harry
 * @Date: 2021/8/11 17:33
 * @Version 1.0
 */
public class Main extends Application {
    @Override
    public void start(Stage primaryStage) throws Exception {
        MyStage myStage = MyStage.getInstance();
        myStage.setStage(primaryStage);
        myStage.initStage();
//        setScene("/fxml/main.fxml",primaryStage);
        myStage.getStage().show();
    }



    public static void main(String[] args) {
        launch(args);
    }
}
