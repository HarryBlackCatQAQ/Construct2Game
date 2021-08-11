package com.hhr.model.javaFX;

import com.hhr.util.ResourcesPathUtil;
import javafx.beans.value.ChangeListener;
import javafx.beans.value.ObservableValue;
import javafx.concurrent.Worker;
import javafx.event.Event;
import javafx.event.EventDispatchChain;
import javafx.event.EventDispatcher;
import javafx.scene.input.MouseButton;
import javafx.scene.input.MouseEvent;
import javafx.scene.web.WebEngine;
import javafx.scene.web.WebView;

/**
 * @Author: Harry
 * @Date: 2021/8/11 18:50
 * @Version 1.0
 */
public class MyWebView {
    private static MyWebView instance;

    private WebView browser;
    private WebEngine webEngine;

    /**
     * 单例模式
     * @return
     */
    public static MyWebView getInstance() {
        if (instance == null) {
            synchronized (MyStage.class) {
                if (instance == null) {
                    instance = new MyWebView();
                }
            }
        }
        return instance;
    }

    private MyWebView(){
        browser = new WebView();
            EventDispatcher originalDispatcher = browser.getEventDispatcher();
            browser.setEventDispatcher(new MyEventDispatcher(originalDispatcher));
        webEngine = browser.getEngine();

        //加载Construct2Game
        webEngine.load(ResourcesPathUtil.getPathOfString("/construct2Game/index.html"));

        //显示系统环境
        showSystemEnvironment();
    }

    private void showSystemEnvironment(){
        //获取当前Java版本
        System.out.println("Java Version:"+System.getProperty("java.runtime.version"));
        //获取当前JavaFx版本
        System.out.println("JavaFx Version:"+System.getProperty("javafx.runtime.version"));
        //获取当前系统版本
        System.out.println("OS:"+System.getProperty("os.name")+","+System.getProperty("os.arch"));
        //获取WebKit内核版本
        System.out.println("User Agent:"+browser.getEngine().getUserAgent());
    }


    public WebView getBrowser() {
        return browser;
    }

    public class MyEventDispatcher implements EventDispatcher {

        private EventDispatcher originalDispatcher;

        public MyEventDispatcher(EventDispatcher originalDispatcher) {
            this.originalDispatcher = originalDispatcher;
        }

        @Override
        public Event dispatchEvent(Event event, EventDispatchChain tail) {
            if (event instanceof MouseEvent) {
                MouseEvent mouseEvent = (MouseEvent) event;
                if (MouseButton.SECONDARY == mouseEvent.getButton()) {
                    mouseEvent.consume();
                }
            }
            return originalDispatcher.dispatchEvent(event, tail);
        }
    }
}
