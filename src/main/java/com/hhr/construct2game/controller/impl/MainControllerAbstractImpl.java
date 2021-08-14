package com.hhr.construct2game.controller.impl;

import com.hhr.construct2game.Construct2GameApplication;
import com.hhr.construct2game.controller.MainControllerAbstract;
import com.hhr.construct2game.view.fx.MyWebView;
import com.hhr.construct2game.view.fx.dialog.GameEnvironmentDialog;
import com.hhr.construct2game.view.fx.dialog.GameShowsDialog;
import de.felixroske.jfxsupport.FXMLController;
import javafx.event.ActionEvent;
import javafx.fxml.FXML;
import org.springframework.beans.factory.annotation.Autowired;

import java.net.URL;
import java.util.ResourceBundle;

/**
 * @Author: Harry
 * @Date: 2021/8/11 18:34
 * @Version 1.0
 */

@FXMLController
public class MainControllerAbstractImpl extends MainControllerAbstract {
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

    @Autowired
    private  Construct2GameApplication construct2GameApplication;

    @FXML
    private void restartProgramBtnClick(ActionEvent event) {
        construct2GameApplication.relaunch();
    }

}
