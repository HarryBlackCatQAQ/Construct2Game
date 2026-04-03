package com.hhr.construct2game.util;

import java.io.IOException;
import java.io.InputStream;
import java.io.UncheckedIOException;
import java.net.URL;

/**
 * @Author: Harry
 * @Date: 2021/1/10 1:40
 * @Version 1.0
 */
public final class ResourcesPathUtil {
    private ResourcesPathUtil() {
    }

    public static URL getPathOfUrl(String path){
        return getRequiredResource(path);
    }

    public static URL getRequiredResource(String path) {
        URL url = ResourcesPathUtil.class.getResource(path);
        if (url == null) {
            throw new IllegalArgumentException("Resource not found: " + path);
        }
        return url;
    }

    public static String getPathOfString(String path){
        return getRequiredResource(path).toExternalForm();
    }

    public static InputStream openResource(String path) {
        try {
            return getRequiredResource(path).openStream();
        } catch (IOException exception) {
            throw new UncheckedIOException("Failed to open resource: " + path, exception);
        }
    }
}
