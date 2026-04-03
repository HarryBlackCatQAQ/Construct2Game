package com.hhr.construct2game.view.fx;

/**
 * @Author: Harry
 * @Date: 2021/1/12 21:01
 * @Version 1.0
 */

import com.hhr.construct2game.info.Construct2GameInfo;
import com.hhr.construct2game.util.ResourcesPathUtil;
import javafx.application.Platform;
import javafx.stage.Stage;

import javax.imageio.ImageIO;
import java.awt.GraphicsEnvironment;
import java.awt.MenuItem;
import java.awt.PopupMenu;
import java.awt.SystemTray;
import java.awt.TrayIcon;
import java.awt.event.MouseAdapter;
import java.awt.event.MouseEvent;
import java.awt.image.BufferedImage;
import java.io.InputStream;

/**
 * 自定义系统托盘(单例模式)
 */
public class MySystemTray implements Construct2GameInfo {

    private static final MySystemTray INSTANCE = new MySystemTray();
    private TrayIcon trayIcon;
    private Stage listenedStage;
    private boolean enabled;

    public static MySystemTray getInstance() {
        return INSTANCE;
    }

    private MySystemTray(){
    }

    /**
     * 更改系统托盘所监听的Stage
     */
    public synchronized void listen(final Stage stage){
        this.listenedStage = stage;
        if (!isTraySupported()) {
            Platform.setImplicitExit(true);
            enabled = false;
            return;
        }
        Platform.setImplicitExit(false);
        installTrayIfNecessary();
    }

    public boolean isEnabled() {
        return enabled;
    }

    public void exitApplication() {
        Platform.exit();
        System.exit(0);
    }

    /**
     * 关闭窗口
     */
    public void hide(final Stage stage){
        Platform.runLater(() -> {
            if (enabled) {
                stage.hide();
            } else {
                exitApplication();
            }
        });
    }

    /**
     * 点击系统托盘,显示界面(并且显示在最前面,将最小化的状态设为false)
     */
    private void showStage(final Stage stage){
        if (stage == null) {
            return;
        }
        Platform.runLater(() -> {
            if (stage.isIconified()) {
                stage.setIconified(false);
            }
            if (!stage.isShowing()) {
                stage.show();
            }
            stage.toFront();
            MyWebView.getInstance().requestFocus();
        });
    }

    public synchronized void shutdown() {
        if (!enabled || trayIcon == null) {
            return;
        }
        SystemTray.getSystemTray().remove(trayIcon);
        trayIcon = null;
        enabled = false;
    }

    private boolean isTraySupported() {
        return !GraphicsEnvironment.isHeadless() && SystemTray.isSupported();
    }

    private void installTrayIfNecessary() {
        if (trayIcon != null) {
            enabled = true;
            return;
        }
        try {
            PopupMenu popupMenu = new PopupMenu();
            MenuItem showItem = new MenuItem("打开");
            MenuItem exitItem = new MenuItem("退出");
            popupMenu.add(showItem);
            popupMenu.add(exitItem);

            BufferedImage trayImage;
            try (InputStream inputStream = ResourcesPathUtil.openResource(TRAY_ICON_PATH)) {
                trayImage = ImageIO.read(inputStream);
            }

            trayIcon = new TrayIcon(trayImage, STAGE_TITLE, popupMenu);
            trayIcon.setImageAutoSize(true);
            showItem.addActionListener(event -> showStage(listenedStage));
            exitItem.addActionListener(event -> exitApplication());
            trayIcon.addMouseListener(new MouseAdapter() {
                @Override
                public void mouseClicked(MouseEvent event) {
                    if (event.getButton() == MouseEvent.BUTTON1) {
                        showStage(listenedStage);
                    }
                }
            });

            SystemTray.getSystemTray().add(trayIcon);
            enabled = true;
        } catch (Exception exception) {
            enabled = false;
            trayIcon = null;
            Platform.setImplicitExit(true);
            System.err.println("System tray is unavailable: " + exception.getMessage());
        }
    }
}
