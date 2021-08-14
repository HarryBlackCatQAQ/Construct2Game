package com.hhr.construct2game;

import com.hhr.construct2game.info.Construct2GameInfo;
import com.hhr.construct2game.util.ResourcesPathUtil;
import com.hhr.construct2game.view.MainView;
import com.hhr.construct2game.view.StartUpPage;
import com.hhr.construct2game.view.fx.MyStage;
import com.hhr.construct2game.view.fx.MyWebView;
import de.felixroske.jfxsupport.AbstractJavaFxApplicationSupport;
import javafx.application.Platform;
import javafx.scene.image.Image;
import javafx.stage.Stage;
import org.springframework.boot.autoconfigure.SpringBootApplication;

import java.util.*;

/**
 * @Author: Harry
 * @Date: 2021/8/14 20:19
 * @Version 1.0
 */

@SpringBootApplication
public class Construct2GameApplication extends AbstractJavaFxApplicationSupport implements Construct2GameInfo {

	public static void main(String[] args) {
		launch(Construct2GameApplication.class, MainView.class,new StartUpPage(), args);
	}

	@Override
	public void start(Stage stage) throws Exception {
		super.start(stage);
		MyStage.getInstance().initStage();
	}

	/**
	 * 设置图标
	 */
	@Override
	public Collection<Image> loadDefaultIcons() {
		return Collections.singletonList(new Image(ResourcesPathUtil.getPathOfString(ICON_PATH)));
	}



	/**
	 * 重启程序
	 */
	public void relaunch(){
		Platform.runLater(() -> {
			// 关闭窗口
			getStage().close();
			try {
				// 关闭ApplicationContext
				this.stop();
				// 重新初始化
				this.init();
				this.start(new Stage());
				MyWebView.getInstance().getBrowser().getEngine().reload();
			} catch (Exception e) {
				System.err.println(e);
			}
		});
	}


}
