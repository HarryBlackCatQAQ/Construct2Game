package com.hhr.construct2game.view.fx.dialog;

import com.hhr.construct2game.view.fx.MyStage;
import com.hhr.construct2game.view.fx.MyWebView;
import javafx.scene.control.ButtonType;
import javafx.scene.control.Dialog;
import javafx.scene.control.Label;
import javafx.scene.layout.GridPane;

/**
 * @Author: Harry
 * @Date: 2021/8/11 21:47
 * @Version 1.0
 */
public class GameEnvironmentDialog extends MainDialog{
    @Override
    public void show(){
        Dialog<ButtonType> dialog = new Dialog<>();
        dialog.initOwner(MyStage.getInstance().getStage());
        dialog.setTitle("运行环境");
        dialog.setHeaderText("当前桌面端运行环境");
        dialog.getDialogPane().getButtonTypes().add(ButtonType.CLOSE);

        GridPane gridPane = new GridPane();
        gridPane.setHgap(12);
        gridPane.setVgap(12);
        gridPane.getStyleClass().add("dialog-grid");

        int row = 0;
        addRow(gridPane, row++, "Java", System.getProperty("java.runtime.version"));
        addRow(gridPane, row++, "JavaFX", System.getProperty("javafx.runtime.version", System.getProperty("javafx.version", "unknown")));
        addRow(gridPane, row++, "系统", System.getProperty("os.name") + " (" + System.getProperty("os.arch") + ")");
        addRow(gridPane, row, "WebKit", MyWebView.getInstance().getBrowser().getEngine().getUserAgent());

        dialog.getDialogPane().setContent(gridPane);
        applyStyle(dialog);
        dialog.showAndWait();
    }

    private void addRow(GridPane gridPane, int rowIndex, String labelText, String valueText) {
        Label label = new Label(labelText + "：");
        label.getStyleClass().add("dialog-key");
        Label value = new Label(valueText);
        value.setWrapText(true);
        value.getStyleClass().add("dialog-value");
        gridPane.add(label, 0, rowIndex);
        gridPane.add(value, 1, rowIndex);
    }
}
