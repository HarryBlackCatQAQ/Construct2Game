package com.hhr.model.javaFX.dialog;

import javafx.event.EventHandler;
import javafx.scene.control.Label;
import javafx.scene.image.Image;
import javafx.scene.image.ImageView;
import javafx.scene.input.MouseEvent;
import javafx.scene.layout.HBox;
import javafx.stage.Window;
import org.jetbrains.annotations.NotNull;


/**
 * @Author: Harry
 * @Date: 2021/8/11 21:00
 * @Version 1.0
 */
public class MyDialogBuilderCloseButton extends HBox {
    private Label label;
    private ImageView closeBtnImageView;
    private double closeBtnImageViewSize;

    public MyDialogBuilderCloseButton(String imagePath){
        label = new Label("2232131");
        label.setStyle("-fx-text-fill: white");
        closeBtnImageView = new ImageView(new Image(imagePath));
        this.getChildren().addAll(label,closeBtnImageView);
    }

    public MyDialogBuilderCloseButton(String imagePath,double closeBtnImageViewSize){
        label = new Label("2232131");
        label.setStyle("-fx-text-fill: white");
        closeBtnImageView = new ImageView(new Image(imagePath));
        setCloseBtnImageViewSize(closeBtnImageViewSize);
        this.getChildren().addAll(label,closeBtnImageView);
    }

    public void setSpacing(Window window,double spacing){
        this.setSpacing(window.getWidth() / spacing);
    }

    public void setCloseBtnImageViewSize(double size){
        this.closeBtnImageViewSize = size;
        closeBtnImageView.setFitWidth(closeBtnImageViewSize);
        closeBtnImageView.setFitHeight(closeBtnImageViewSize);
    }

    public void setBackGround(String style){
        label.setStyle(style);
    }

    public void setCloseBtnAction(@NotNull final OnCloseButtonClickListener onCloseButtonClickListener){
        closeBtnImageView.setOnMouseClicked(new EventHandler<MouseEvent>() {
            @Override
            public void handle(MouseEvent event) {
                if (onCloseButtonClickListener != null) {
                    onCloseButtonClickListener.onClick();//回调onClick方法
                }
            }
        });
    }

    public interface OnCloseButtonClickListener {
        void onClick();
    }
}
