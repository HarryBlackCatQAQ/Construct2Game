package com.hhr.util;

import java.net.URL;

/**
 * @Author: Harry
 * @Date: 2021/1/10 1:40
 * @Version 1.0
 */
public class ResourcesPathUtil {

    public static URL getPathOfUrl(String path){
        return ResourcesPathUtil.class.getResource(path);
    }

    public static String getPathOfString(String path){
        return getPathOfUrl(path).toString();
    }
}
