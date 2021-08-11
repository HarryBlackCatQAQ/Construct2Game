package com.hhr.model.javaFX.dialog;

import com.hhr.model.javaFX.MyStage;
import com.hhr.model.javaFX.MyWebView;
import com.hhr.util.ResourcesPathUtil;
import javafx.scene.control.Label;
import javafx.scene.layout.VBox;

import java.util.LinkedHashMap;

/**
 * @Author: Harry
 * @Date: 2021/8/11 21:47
 * @Version 1.0
 */
public class GameEnvironmentDialog extends MainDialog{
    public GameEnvironmentDialog(){
        dialogBuilder = new DialogBuilder(MyStage.getInstance().getStage().getScene().getWindow());

        VBox vBox = dialogBuilder.getLayoutContentVBox();
        vBox.setSpacing(25);
        //添加提示窗口的组件

        //获取当前Java版本
        String javaVersion = "Java Version:" + System.getProperty("java.runtime.version");
        //获取当前JavaFx版本
        String javaFxVersion = "JavaFX Version:" + System.getProperty("javafx.runtime.version");
        //获取当前系统版本
        String systemVersion = "OS:" + System.getProperty("os.name")+"," + System.getProperty("os.arch");
        //获取WebKit内核版本
        String webKitVersion = "User Agent:" + MyWebView.getInstance().getBrowser().getEngine().getUserAgent();

        Label javaVersionLabel = new Label(javaVersion);
        Label javaFxVersionLabel = new Label(javaFxVersion);
        Label systemVersionLabel = new Label(systemVersion);
        Label webKitVersionLabel = new Label(webKitVersion);

        LinkedHashMap<String,Object> map = new LinkedHashMap<>();
        map.put("javaVersionLabel",javaVersionLabel);
        map.put("javaFxVersionLabel",javaFxVersionLabel);
        map.put("systemVersionLabel",systemVersionLabel);
        map.put("webKitVersionLabel",webKitVersionLabel);

        //设置关闭按钮
        MyDialogBuilderCloseButton myDialogBuilderCloseButton = new MyDialogBuilderCloseButton(ResourcesPathUtil.getPathOfString("/images/closeBtnImage2.jpg"),27);
        myDialogBuilderCloseButton.setSpacing(MyStage.getInstance().getStage().getScene().getWindow(),1.23);
        myDialogBuilderCloseButton.setCloseBtnAction(new MyDialogBuilderCloseButton.OnCloseButtonClickListener() {
            @Override
            public void onClick() {
                dialogBuilder.getAlert().close();
            }
        });

        dialogBuilder.getLayout().setHeading(myDialogBuilderCloseButton);
        dialogBuilder.setLayoutContentNodeMap(map);
    }
}
