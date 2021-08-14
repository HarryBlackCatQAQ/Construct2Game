package com.hhr.construct2game.view.fx.dialog;

/**
 * @Author: Harry
 * @Date: 2021/8/11 21:56
 * @Version 1.0
 */

public abstract class MainDialog {
    protected DialogBuilder dialogBuilder;

    public void show(){
        this.dialogBuilder.create();
    }
}
