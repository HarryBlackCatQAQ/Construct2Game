package com.hhr.view;

import com.jfoenix.controls.JFXButton;
import javafx.fxml.FXML;
import javafx.fxml.Initializable;

/**
 * @Author: Harry
 * @Date: 2021/8/11 18:35
 * @Version 1.0
 */

public abstract class MainView implements Initializable {
    @FXML
    private JFXButton mainMenuBtn;

    @FXML
    private JFXButton gameShowsBtn;

    @FXML
    private JFXButton gameEnvironmentBtn;

}
