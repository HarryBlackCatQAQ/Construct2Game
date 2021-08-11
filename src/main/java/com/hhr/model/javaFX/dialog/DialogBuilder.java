package com.hhr.model.javaFX.dialog;

import com.jfoenix.controls.JFXAlert;
import com.jfoenix.controls.JFXButton;
import com.jfoenix.controls.JFXDialogLayout;
import javafx.event.ActionEvent;
import javafx.event.EventHandler;
import javafx.scene.Node;
import javafx.scene.control.ButtonType;
import javafx.scene.control.Control;
import javafx.scene.control.Hyperlink;
import javafx.scene.control.Label;
import javafx.scene.input.MouseEvent;
import javafx.scene.layout.Border;
import javafx.scene.layout.HBox;
import javafx.scene.layout.Pane;
import javafx.scene.layout.VBox;
import javafx.scene.paint.Paint;
import javafx.stage.Modality;
import javafx.stage.Stage;
import javafx.stage.Window;
import org.jetbrains.annotations.NotNull;

import java.awt.*;
import java.io.File;
import java.io.IOException;
import java.net.URI;
import java.net.URISyntaxException;
import java.util.LinkedHashMap;

/**
 * @Author: Harry
 * @Date: 2021/1/17 2:26
 * @Version 1.0
 */
public class DialogBuilder {
    private Label title, message;
    private JFXButton negativeBtn = null;
    private JFXButton positiveBtn = null;
    private Window window;
    private JFXDialogLayout layout;
    private Paint negativeBtnPaint = Paint.valueOf("#747474");//否定按钮文字颜色，默认灰色
    private Paint positiveBtnPaint = Paint.valueOf("#0099ff");
    private Hyperlink hyperlink = null;
    private JFXAlert<String> alert;
    private HBox layoutContentHBox;
    private VBox layoutContentVBox;
    private LinkedHashMap<String,Object> layoutContentNodeMap = null;

    /**
     * construction method
     * @param control Any one of these controls
     */
    public DialogBuilder(Control control) {
        window = control.getScene().getWindow();
        initLayout();
        alert = new JFXAlert<>((Stage) (window));
    }

    /**
     * construction method
     * @param window
     */
    public DialogBuilder(Window window){
        this.window = window;
        initLayout();
        alert = new JFXAlert<>((Stage) (window));
    }

    private void initLayout(){
        layout = new JFXDialogLayout();
        layoutContentHBox = new HBox();
        layoutContentVBox = new VBox();
        title = new Label();
        message = new Label();
        title.setText("");
        message.setText("");
    }

    /**
     * set Title
     * @param title 标题
     * @return this
     */
    public DialogBuilder setTitle(String title) {
        this.title.setText(title);
        return this;
    }

    /**
     * set Message
     * @param message 主题内容
     * @return this
     */
    public DialogBuilder setMessage(String message) {
        this.message.setText(message);
        return this;
    }

    /**
     * set Button Text
     * @param negativeBtnText 按钮内容
     * @return this
     */
    public DialogBuilder setNegativeBtn(String negativeBtnText) {
        return setNegativeBtn(negativeBtnText, null, null);
    }

    /**
     * 设置否定按钮文字和文字颜色
     *
     * @param negativeBtnText 文字
     * @param color           文字颜色 十六进制 #fafafa
     * @return this
     */
    public DialogBuilder setNegativeBtn(String negativeBtnText, String color) {
        return setNegativeBtn(negativeBtnText, null, color);
    }

    /**
     * 设置按钮文字和按钮文字颜色，按钮监听器和
     *
     * @param negativeBtnText 文字
     * @param negativeBtnOnclickListener 按钮监听器
     * @param color                      文字颜色 十六进制 #fafafa
     * @return this
     */
    public DialogBuilder setNegativeBtn(String negativeBtnText, @NotNull OnClickListener negativeBtnOnclickListener, String color) {
        if (color != null) {
            this.negativeBtnPaint = Paint.valueOf(color);
        }
        return setNegativeBtn(negativeBtnText, negativeBtnOnclickListener);
    }


    /**
     * 设置按钮文字和点击监听器
     *
     * @param negativeBtnText            按钮文字
     * @param negativeBtnOnclickListener 点击监听器
     * @return this
     */
    public DialogBuilder setNegativeBtn(String negativeBtnText, @NotNull final OnClickListener negativeBtnOnclickListener) {

        negativeBtn = new JFXButton(negativeBtnText);
        negativeBtn.setCancelButton(true);
        negativeBtn.setTextFill(negativeBtnPaint);
        negativeBtn.setPrefHeight(30);
        negativeBtn.setPrefWidth(60);
        negativeBtn.setButtonType(JFXButton.ButtonType.FLAT);
        negativeBtn.getStyleClass().add("button-raised");
        negativeBtn.setOnAction(new EventHandler<ActionEvent>() {
            @Override
            public void handle(ActionEvent addEvent) {
                alert.hideWithAnimation();
                if (negativeBtnOnclickListener != null) {
                    negativeBtnOnclickListener.onClick();
                }
            }
        });
        return this;
    }

    /**
     * 设置按钮文字和颜色
     *
     * @param positiveBtnText 文字
     * @param color           颜色 十六进制 #fafafa
     * @return this
     */
    public DialogBuilder setPositiveBtn(String positiveBtnText, String color) {
        return setPositiveBtn(positiveBtnText, null, color);
    }

    /**
     * 设置按钮文字，颜色和点击监听器
     *
     * @param positiveBtnText            文字
     * @param positiveBtnOnclickListener 点击监听器
     * @param color                      颜色 十六进制 #fafafa
     * @return this
     */
    public DialogBuilder setPositiveBtn(String positiveBtnText, @NotNull OnClickListener positiveBtnOnclickListener, String color) {
        this.positiveBtnPaint = Paint.valueOf(color);
        return setPositiveBtn(positiveBtnText, positiveBtnOnclickListener);
    }

    /**
     * 设置按钮文字和监听器
     *
     * @param positiveBtnText            文字
     * @param positiveBtnOnclickListener 点击监听器
     * @return this
     */
    public DialogBuilder setPositiveBtn(String positiveBtnText, @NotNull
    final OnClickListener positiveBtnOnclickListener) {
        positiveBtn = new JFXButton(positiveBtnText);
        positiveBtn.setDefaultButton(true);
        positiveBtn.setTextFill(positiveBtnPaint);
        positiveBtn.setPrefWidth(60);
        positiveBtn.setPrefHeight(30);
        positiveBtn.getStyleClass().add("button-raised");
//        System.out.println("执行setPostiveBtn");
        positiveBtn.setOnAction(new EventHandler<ActionEvent>() {
            @Override
            public void handle(ActionEvent closeEvent) {
                alert.hideWithAnimation();
                if (positiveBtnOnclickListener != null) {
                    positiveBtnOnclickListener.onClick();//回调onClick方法
                }
            }
        });
        return this;
    }

    public DialogBuilder setHyperLink(final String text) {
        hyperlink = new Hyperlink(text);
        hyperlink.setBorder(Border.EMPTY);
        hyperlink.setOnMouseClicked(new EventHandler<MouseEvent>() {
            @Override
            public void handle(MouseEvent event) {
                if (text.contains("www") || text.contains("com") || text.contains(".")) {
                    try {
                        Desktop.getDesktop().browse(new URI(text));
                    } catch (IOException | URISyntaxException e) {
                        e.printStackTrace();
                    }
                } else if (text.contains(File.separator)) {
                    try {
                        Desktop.getDesktop().open(new File(text));
                    } catch (IOException e) {
                        e.printStackTrace();
                    }
                }
            }
        });
        return this;
    }

    /**
     * 创建对话框并显示
     *
     * @return JFXAlert<String>
     */
    public JFXAlert<String> create() {
        alert.initModality(Modality.APPLICATION_MODAL);
        alert.setOverlayClose(false);

        if(!(title == null || title.getText().equals(""))){
            layout.setHeading(title);
        }

        //添加hyperlink超链接文本
        if (hyperlink != null) {
            addMessage(layoutContentHBox);
            layoutContentHBox.getChildren().addAll(hyperlink);
            addLayoutContentNodeMap(layoutContentHBox);
            layout.setBody(layoutContentHBox);
        } else {
            addMessage(layoutContentVBox);
            addLayoutContentNodeMap(layoutContentVBox);
            layout.setBody(layoutContentVBox);
        }
        //添加确定和取消按钮
        if (negativeBtn != null && positiveBtn != null) {
            layout.setActions(negativeBtn, positiveBtn);
        } else {
            if (negativeBtn != null) {
                layout.setActions(negativeBtn);
            } else if (positiveBtn != null) {
                layout.setActions(positiveBtn);
            }
        }

        alert.setContent(layout);
        alert.showAndWait();

        return alert;
    }

    public interface OnClickListener {
        void onClick();
    }

    private void addLayoutContentNodeMap(Pane pane){
        if(layoutContentNodeMap != null){
            for(Object o : layoutContentNodeMap.values()){
                if(o instanceof Node){
                    pane.getChildren().add((Node)o);
                }
            }
        }
    }

    private void addMessage(Pane pane){
        if(!(message == null || message.getText().equals(""))){
            pane.getChildren().add(message);
        }
    }



    public JFXDialogLayout getLayout() {
        return layout;
    }

    public HBox getLayoutContentHBox() {
        return layoutContentHBox;
    }

    public VBox getLayoutContentVBox() {
        return layoutContentVBox;
    }

    public LinkedHashMap<String, Object> getLayoutContentNodeMap() {
        return layoutContentNodeMap;
    }

    public void setLayoutContentNodeMap(LinkedHashMap<String, Object> layoutContentNodeMap) {
        this.layoutContentNodeMap = layoutContentNodeMap;
    }

    public Label getTitle() {
        return title;
    }

    public Label getMessage() {
        return message;
    }

    public JFXAlert<String> getAlert() {
        return alert;
    }
}
