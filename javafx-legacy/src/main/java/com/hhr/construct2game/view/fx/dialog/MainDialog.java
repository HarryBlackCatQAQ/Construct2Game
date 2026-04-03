package com.hhr.construct2game.view.fx.dialog;

import com.hhr.construct2game.info.Construct2GameInfo;
import com.hhr.construct2game.util.ResourcesPathUtil;
import javafx.scene.Scene;
import javafx.scene.control.Dialog;

/**
 * @Author: Harry
 * @Date: 2021/8/11 21:56
 * @Version 1.0
 */

public abstract class MainDialog implements Construct2GameInfo {

    public abstract void show();

    protected void applyStyle(Dialog<?> dialog) {
        String styleSheet = ResourcesPathUtil.getPathOfString(STYLE_SHEET_PATH);
        if (!dialog.getDialogPane().getStylesheets().contains(styleSheet)) {
            dialog.getDialogPane().getStylesheets().add(styleSheet);
        }
        dialog.getDialogPane().getStyleClass().add("app-dialog");
    }

    protected void applyStyle(Scene scene) {
        String styleSheet = ResourcesPathUtil.getPathOfString(STYLE_SHEET_PATH);
        if (!scene.getStylesheets().contains(styleSheet)) {
            scene.getStylesheets().add(styleSheet);
        }
    }
}
