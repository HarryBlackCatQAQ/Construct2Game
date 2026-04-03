package com.hhr.construct2game.controller;

import javafx.fxml.FXML;
import javafx.fxml.Initializable;
import javafx.scene.control.Button;

/**
 * @Author: Harry
 * @Date: 2021/8/14 20:21
 * @Version 1.0
 */
public abstract class MainControllerAbstract implements Initializable {
    @FXML
    protected Button mainMenuBtn;

    @FXML
    protected Button gameShowsBtn;

    @FXML
    protected Button gameEnvironmentBtn;

    @FXML
    protected Button restartProgramBtn;
}
