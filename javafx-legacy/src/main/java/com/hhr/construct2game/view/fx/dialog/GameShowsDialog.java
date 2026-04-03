package com.hhr.construct2game.view.fx.dialog;

import com.hhr.construct2game.Construct2GameApplication;
import com.hhr.construct2game.util.ResourcesPathUtil;
import com.hhr.construct2game.view.fx.MyStage;
import javafx.geometry.Insets;
import javafx.geometry.Pos;
import javafx.scene.Scene;
import javafx.scene.control.Button;
import javafx.scene.control.ScrollPane;
import javafx.scene.image.Image;
import javafx.scene.image.ImageView;
import javafx.scene.layout.Background;
import javafx.scene.layout.BackgroundImage;
import javafx.scene.layout.BackgroundPosition;
import javafx.scene.layout.BackgroundRepeat;
import javafx.scene.layout.BackgroundSize;
import javafx.scene.layout.BorderPane;
import javafx.scene.layout.HBox;
import javafx.stage.Modality;
import javafx.stage.Stage;


/**
 * @Author: Harry
 * @Date: 2021/8/11 19:14
 * @Version 1.0
 */
public class GameShowsDialog extends MainDialog{

    @Override
    public void show(){
        Stage owner = MyStage.getInstance().getStage();
        Stage dialogStage = new Stage();
        dialogStage.initOwner(owner);
        dialogStage.initModality(Modality.WINDOW_MODAL);
        dialogStage.setTitle("游戏说明");
        dialogStage.getIcons().setAll(Construct2GameApplication.loadApplicationIcons());

        ImageView imageView = new ImageView(new Image(ResourcesPathUtil.getPathOfString(GAME_SHOWS_IMAGE_PATH)));
        imageView.setPreserveRatio(true);
        imageView.setSmooth(true);

        ScrollPane scrollPane = new ScrollPane(imageView);
        scrollPane.setFitToWidth(true);
        scrollPane.setFitToHeight(true);
        scrollPane.setPannable(true);
        scrollPane.getStyleClass().add("game-shows-scroll-pane");

        Button closeButton = new Button("关闭");
        closeButton.setOnAction(event -> dialogStage.close());

        HBox buttonBar = new HBox(closeButton);
        buttonBar.setAlignment(Pos.CENTER_RIGHT);
        buttonBar.setPadding(new Insets(12));
        buttonBar.getStyleClass().addAll("dialog-button-bar", "game-shows-button-bar");

        BorderPane root = new BorderPane(scrollPane);
        root.setBottom(buttonBar);
        root.getStyleClass().add("game-shows-root");
        root.setBackground(createBackground());

        double width = owner == null ? DEFAULT_WINDOW_WIDTH * 0.75 : Math.max(900, owner.getWidth() * 0.8);
        double height = owner == null ? DEFAULT_WINDOW_HEIGHT * 0.8 : Math.max(650, owner.getHeight() * 0.82);

        Scene scene = new Scene(root, width, height);
        applyStyle(scene);
        dialogStage.setScene(scene);

        imageView.fitWidthProperty().bind(scene.widthProperty().subtract(48));
        imageView.fitHeightProperty().bind(scene.heightProperty().subtract(120));
        dialogStage.showAndWait();
    }

    private Background createBackground() {
        Image background = new Image(ResourcesPathUtil.getPathOfString(GAME_SHOWS_BACKGROUND_PATH));
        BackgroundImage backgroundImage = new BackgroundImage(
                background,
                BackgroundRepeat.REPEAT,
                BackgroundRepeat.REPEAT,
                BackgroundPosition.CENTER,
                new BackgroundSize(BackgroundSize.AUTO, BackgroundSize.AUTO, false, false, false, false)
        );
        return new Background(backgroundImage);
    }
}
