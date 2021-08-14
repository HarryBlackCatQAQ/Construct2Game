package com.hhr.construct2game.view.fx.dialog;

import com.hhr.construct2game.view.fx.MyStage;
import com.jfoenix.controls.JFXRadioButton;
import javafx.scene.control.Label;
import javafx.scene.control.ToggleGroup;
import javafx.scene.layout.VBox;
import javafx.stage.Window;

import java.util.LinkedHashMap;

/**
 * @Author: Harry
 * @Date: 2021/8/15 2:12
 * @Version 1.0
 */
public class StageCloseDialog extends MainDialog{

    public StageCloseDialog(){
        Window window = MyStage.getInstance().getScene().getWindow();
        //创建提示窗口
        dialogBuilder = new DialogBuilder(window);
        //设置标题
        dialogBuilder.setTitle("提示");
        Label title = dialogBuilder.getTitle();
        title.getStyleClass().add("close-layout-title");
        //设置提示窗口内容区域间距
        VBox vBox = dialogBuilder.getLayoutContentVBox();
        vBox.setSpacing(25);
        //添加提示窗口的组件
        final ToggleGroup group = new ToggleGroup();
        JFXRadioButton closeRadioBtn = new JFXRadioButton("关闭游戏");
        JFXRadioButton minimizeRadioBtn = new JFXRadioButton("最小化");
        //设置最小化按钮默认选中
        minimizeRadioBtn.setSelected(true);
        closeRadioBtn.setUserData("close");
        closeRadioBtn.setToggleGroup(group);
        minimizeRadioBtn.setToggleGroup(group);
        minimizeRadioBtn.setUserData("minimize");
        closeRadioBtn.getStyleClass().add("close-layout-radio");
        minimizeRadioBtn.getStyleClass().add("close-layout-radio");
        //将组件加入到提示窗口
        LinkedHashMap<String,Object> map = new LinkedHashMap<>();
        map.put("radioGroup",group);
        map.put("closeRadioBtn",closeRadioBtn);
        map.put("minimizeRadioBtn",minimizeRadioBtn);
        dialogBuilder.setLayoutContentNodeMap(map);

        //设置提示窗口按钮和其监听事件
        dialogBuilder.setPositiveBtn("确定", new DialogBuilder.OnClickListener() {
            @Override
            public void onClick() {
                String s = (String) group.getSelectedToggle().getUserData();
                if(s.equals("close")){
                    System.exit(0);
                }
                else{
                    MyStage.getInstance().getStage().hide();
                }
            }
        });
    }
}
