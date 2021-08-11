package com.hhr.controller;

import com.hhr.model.javaFX.MyWebView;
import com.hhr.model.javaFX.dialog.GameEnvironmentDialog;
import com.hhr.model.javaFX.dialog.GameShowsDialog;
import com.hhr.view.MainView;
import javafx.event.ActionEvent;
import javafx.fxml.FXML;

import java.net.URL;
import java.util.ResourceBundle;

/**
 * @Author: Harry
 * @Date: 2021/8/11 18:34
 * @Version 1.0
 */
public class MainController extends MainView {
    @Override
    public void initialize(URL location, ResourceBundle resources) {

    }

    @FXML
    private void mainMenuBtnClicked(ActionEvent event) {
        //重新加载
        MyWebView.getInstance().getBrowser().getEngine().reload();
    }

    @FXML
    private void gameShowsBtnClick(ActionEvent event) {
        GameShowsDialog gameShowsDialog = new GameShowsDialog();
        gameShowsDialog.show();
    }

    @FXML
    private void gameEnvironmentBtnClick(ActionEvent event) {
        GameEnvironmentDialog gameEnvironmentDialog = new GameEnvironmentDialog();
        gameEnvironmentDialog.show();
    }

}
