package com.hhr.construct2game.view.fx.dialog;

import com.hhr.construct2game.util.ResourcesPathUtil;
import com.hhr.construct2game.view.fx.MyStage;
import javafx.scene.image.Image;
import javafx.scene.image.ImageView;
import javafx.stage.Window;

import java.util.LinkedHashMap;


/**
 * @Author: Harry
 * @Date: 2021/8/11 19:14
 * @Version 1.0
 */
public class GameShowsDialog extends MainDialog{

    public GameShowsDialog(){
        Window window = MyStage.getInstance().getScene().getWindow();
        dialogBuilder = new DialogBuilder(window);
        ImageView imageView = new ImageView(new Image(ResourcesPathUtil.getPathOfString("/images/gameShowsImage.png")));
        imageView.setFitWidth(window.getWidth() / 1.2);
        imageView.setFitHeight(window.getHeight() / 1.2);
        LinkedHashMap<String,Object> map = new LinkedHashMap<>();
        map.put("gameShowsImage",imageView);

        //设置关闭按钮
        MyDialogBuilderCloseButton myDialogBuilderCloseButton = new MyDialogBuilderCloseButton(ResourcesPathUtil.getPathOfString("/images/closeBtnImage2.jpg"),27);
        myDialogBuilderCloseButton.setSpacing(window,1.23);
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
