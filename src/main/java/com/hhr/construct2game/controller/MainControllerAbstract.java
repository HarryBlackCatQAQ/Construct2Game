package com.hhr.construct2game.controller;

import com.jfoenix.controls.JFXButton;
import javafx.fxml.FXML;
import javafx.fxml.Initializable;
import lombok.Getter;

/**
 * @Author: Harry
 * @Date: 2021/8/14 20:21
 * @Version 1.0
 */
@Getter
public abstract class MainControllerAbstract implements Initializable {
    @FXML
    private JFXButton mainMenuBtn;

    @FXML
    private JFXButton gameShowsBtn;

    @FXML
    private JFXButton gameEnvironmentBtn;

    @FXML
    private JFXButton restartProgramBtn;
}
