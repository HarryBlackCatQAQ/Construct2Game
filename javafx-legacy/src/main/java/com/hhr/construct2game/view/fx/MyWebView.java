package com.hhr.construct2game.view.fx;

import com.hhr.construct2game.info.Construct2GameInfo;
import com.hhr.construct2game.util.LocalGameHttpServer;
import javafx.application.Platform;
import javafx.concurrent.Worker;
import javafx.scene.input.MouseButton;
import javafx.scene.input.MouseEvent;
import javafx.scene.layout.BorderPane;
import javafx.scene.paint.Color;
import javafx.scene.web.WebEngine;
import javafx.scene.web.WebView;

/**
 * @Author: Harry
 * @Date: 2021/8/11 18:50
 * @Version 1.0
 */
public class MyWebView implements Construct2GameInfo {
    private static final MyWebView INSTANCE = new MyWebView();
    private static final String EMBEDDED_BROWSER_USER_AGENT =
            "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/616.1 (KHTML, like Gecko) Version/17.4 Safari/616.1";

    private WebView browser;
    private String gameUrl;

    /**
     * 单例模式
     * @return
     */
    public static MyWebView getInstance() {
        return INSTANCE;
    }

    private MyWebView(){
        recreateBrowser();
    }

    public void attachTo(BorderPane pane) {
        if (browser.getParent() instanceof BorderPane) {
            BorderPane parentPane = (BorderPane) browser.getParent();
            if (parentPane.getCenter() == browser) {
                parentPane.setCenter(null);
            }
        }
        pane.setCenter(browser);
    }

    public WebView getBrowser() {
        return browser;
    }

    public void reloadGame(boolean hardReset) {
        if (hardReset) {
            recreateBrowser();
            return;
        }
        gameUrl = LocalGameHttpServer.getInstance().getGameEntryUrl();
        browser.getEngine().load(gameUrl);
    }

    public void requestFocus() {
        if (browser == null) {
            return;
        }
        Platform.runLater(browser::requestFocus);
    }

    public void dispose() {
        if (browser != null) {
            browser.getEngine().load(null);
        }
    }

    private void recreateBrowser() {
        WebView previousBrowser = this.browser;
        BorderPane parentPane = null;
        if (previousBrowser != null && previousBrowser.getParent() instanceof BorderPane) {
            parentPane = (BorderPane) previousBrowser.getParent();
        }

        this.gameUrl = LocalGameHttpServer.getInstance().getGameEntryUrl();
        this.browser = createBrowser();

        if (parentPane != null && parentPane.getCenter() == previousBrowser) {
            parentPane.setCenter(browser);
        }
    }

    private WebView createBrowser() {
        WebView webView = new WebView();
        webView.setContextMenuEnabled(false);
        webView.setFocusTraversable(true);
        webView.setStyle("-fx-background-color: #000000;");
        webView.setPageFill(Color.BLACK);
        webView.setOnMousePressed(event -> webView.requestFocus());
        webView.addEventFilter(MouseEvent.MOUSE_PRESSED, event -> {
            if (event.getButton() != MouseButton.SECONDARY) {
                webView.requestFocus();
            }
        });

        WebEngine engine = webView.getEngine();
        engine.setJavaScriptEnabled(true);
        engine.setUserAgent(EMBEDDED_BROWSER_USER_AGENT);
        engine.setOnAlert(event -> System.err.println("WebView alert: " + event.getData()));
        engine.getLoadWorker().stateProperty().addListener((observable, oldState, newState) -> {
            if (newState == Worker.State.SUCCEEDED) {
                Platform.runLater(webView::requestFocus);
                showSystemEnvironment(engine);
            }
        });
        engine.getLoadWorker().exceptionProperty().addListener((observable, oldValue, newValue) -> {
            if (newValue != null) {
                System.err.println("WebView load failed: " + newValue.getMessage());
            }
        });
        engine.load(gameUrl);
        return webView;
    }

    private void showSystemEnvironment(WebEngine webEngine){
        System.out.println("Java Version:" + System.getProperty("java.runtime.version"));
        System.out.println("JavaFX Version:" + System.getProperty("javafx.runtime.version", System.getProperty("javafx.version", "unknown")));
        System.out.println("OS:" + System.getProperty("os.name") + "," + System.getProperty("os.arch"));
        System.out.println("Game URL:" + gameUrl);
        System.out.println("User Agent:" + webEngine.getUserAgent());
    }
}
