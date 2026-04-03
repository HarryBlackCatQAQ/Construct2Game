package com.hhr.construct2game.view.fx.dialog;

import com.hhr.construct2game.view.fx.MyStage;
import com.hhr.construct2game.view.fx.MySystemTray;
import javafx.scene.control.ButtonBar;
import javafx.scene.control.ButtonType;
import javafx.scene.control.Dialog;
import javafx.scene.control.Label;
import javafx.scene.control.RadioButton;
import javafx.scene.control.ToggleGroup;
import javafx.scene.layout.VBox;

import java.util.Optional;

/**
 * @Author: Harry
 * @Date: 2021/8/15 2:12
 * @Version 1.0
 */
public class StageCloseDialog extends MainDialog{

    @Override
    public void show(){
        if (MySystemTray.getInstance().isEnabled()) {
            showTrayAwareDialog();
            return;
        }
        showExitOnlyDialog();
    }

    private void showTrayAwareDialog() {
        Dialog<ButtonType> dialog = new Dialog<>();
        dialog.initOwner(MyStage.getInstance().getStage());
        dialog.setTitle("关闭游戏");
        dialog.setHeaderText("请选择关闭后的行为");

        ToggleGroup group = new ToggleGroup();
        RadioButton minimizeRadioButton = new RadioButton("最小化到托盘");
        minimizeRadioButton.setToggleGroup(group);
        minimizeRadioButton.setUserData("minimize");
        minimizeRadioButton.setSelected(true);

        RadioButton closeRadioButton = new RadioButton("完全退出游戏");
        closeRadioButton.setToggleGroup(group);
        closeRadioButton.setUserData("close");

        VBox content = new VBox(12,
                new Label("托盘可用时，建议最小化到托盘，之后可以从托盘再次打开。"),
                minimizeRadioButton,
                closeRadioButton
        );
        content.getStyleClass().add("dialog-content");

        ButtonType confirmButton = new ButtonType("确定", ButtonBar.ButtonData.OK_DONE);
        ButtonType cancelButton = new ButtonType("取消", ButtonBar.ButtonData.CANCEL_CLOSE);
        dialog.getDialogPane().getButtonTypes().setAll(cancelButton, confirmButton);
        dialog.getDialogPane().setContent(content);
        applyStyle(dialog);

        Optional<ButtonType> result = dialog.showAndWait();
        if (result.isEmpty() || result.get() != confirmButton || group.getSelectedToggle() == null) {
            return;
        }

        String action = String.valueOf(group.getSelectedToggle().getUserData());
        if ("close".equals(action)) {
            MySystemTray.getInstance().exitApplication();
        } else {
            MySystemTray.getInstance().hide(MyStage.getInstance().getStage());
        }
    }

    private void showExitOnlyDialog() {
        Dialog<ButtonType> dialog = new Dialog<>();
        dialog.initOwner(MyStage.getInstance().getStage());
        dialog.setTitle("退出游戏");
        dialog.setHeaderText("当前系统环境不支持托盘最小化");

        VBox content = new VBox(12, new Label("确定要退出游戏吗？"));
        content.getStyleClass().add("dialog-content");

        ButtonType exitButton = new ButtonType("退出", ButtonBar.ButtonData.OK_DONE);
        ButtonType cancelButton = new ButtonType("取消", ButtonBar.ButtonData.CANCEL_CLOSE);
        dialog.getDialogPane().getButtonTypes().setAll(cancelButton, exitButton);
        dialog.getDialogPane().setContent(content);
        applyStyle(dialog);

        Optional<ButtonType> result = dialog.showAndWait();
        if (result.isPresent() && result.get() == exitButton) {
            MySystemTray.getInstance().exitApplication();
        }
    }
}
