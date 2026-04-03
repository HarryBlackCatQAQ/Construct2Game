package com.hhr.construct2game.controller.impl;

import com.hhr.construct2game.Construct2GameApplication;
import com.hhr.construct2game.controller.MainControllerAbstract;
import com.hhr.construct2game.view.fx.MyWebView;
import com.hhr.construct2game.view.fx.dialog.GameEnvironmentDialog;
import com.hhr.construct2game.view.fx.dialog.GameShowsDialog;
import javafx.event.ActionEvent;
import javafx.fxml.FXML;

import java.net.URL;
import java.util.ResourceBundle;

/**
 * @Author: Harry
 * @Date: 2021/8/11 18:34
 * @Version 1.0
 */
public class MainControllerAbstractImpl extends MainControllerAbstract {
    @Override
    public void initialize(URL location, ResourceBundle resources) {
    }

    @FXML
    private void mainMenuBtnClicked(ActionEvent event) {
        MyWebView.getInstance().reloadGame(true);
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

    @FXML
    private void restartProgramBtnClick(ActionEvent event) {
        Construct2GameApplication.getInstance().relaunch();
    }
}
