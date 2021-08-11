package com.hhr.model.javaFX.dialog;

import com.hhr.model.javaFX.MyStage;
import com.hhr.util.ResourcesPathUtil;
import javafx.scene.image.Image;
import javafx.scene.image.ImageView;

import java.util.LinkedHashMap;


/**
 * @Author: Harry
 * @Date: 2021/8/11 19:14
 * @Version 1.0
 */
public class GameShowsDialog extends MainDialog{

    public GameShowsDialog(){
        dialogBuilder = new DialogBuilder(MyStage.getInstance().getStage().getScene().getWindow());
        ImageView imageView = new ImageView(new Image(ResourcesPathUtil.getPathOfString("/images/gameShowsImage.png")));
        imageView.setFitWidth(MyStage.getInstance().getStage().getScene().getWindow().getWidth() / 1.2);
        imageView.setFitHeight(MyStage.getInstance().getStage().getScene().getWindow().getHeight() / 1.2);
        LinkedHashMap<String,Object> map = new LinkedHashMap<>();
        map.put("gameShowsImage",imageView);

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
