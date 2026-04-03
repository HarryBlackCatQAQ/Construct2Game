package com.hhr.construct2game.util;

import com.sun.net.httpserver.Headers;
import com.sun.net.httpserver.HttpExchange;
import com.sun.net.httpserver.HttpServer;

import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;
import java.net.InetAddress;
import java.net.InetSocketAddress;
import java.net.URL;
import java.nio.charset.StandardCharsets;
import java.util.Locale;
import java.util.Map;
import java.util.concurrent.Executors;

/**
 * 用本地 HTTP 服务承载 Construct2 静态资源，让 JavaFX WebView 的加载方式更接近 Wails。
 */
public final class LocalGameHttpServer {
    private static final LocalGameHttpServer INSTANCE = new LocalGameHttpServer();
    private static final String RESOURCE_ROOT = "/construct2Game";
    private static final Map<String, String> CONTENT_TYPES = Map.ofEntries(
            Map.entry(".html", "text/html; charset=UTF-8"),
            Map.entry(".js", "application/javascript; charset=UTF-8"),
            Map.entry(".json", "application/json; charset=UTF-8"),
            Map.entry(".css", "text/css; charset=UTF-8"),
            Map.entry(".png", "image/png"),
            Map.entry(".jpg", "image/jpeg"),
            Map.entry(".jpeg", "image/jpeg"),
            Map.entry(".gif", "image/gif"),
            Map.entry(".ico", "image/x-icon"),
            Map.entry(".svg", "image/svg+xml"),
            Map.entry(".woff", "font/woff"),
            Map.entry(".woff2", "font/woff2"),
            Map.entry(".ttf", "font/ttf"),
            Map.entry(".m4a", "audio/mp4"),
            Map.entry(".ogg", "audio/ogg"),
            Map.entry(".mp3", "audio/mpeg"),
            Map.entry(".wav", "audio/wav"),
            Map.entry(".appcache", "text/cache-manifest; charset=UTF-8")
    );

    private HttpServer server;
    private int port = -1;

    public static LocalGameHttpServer getInstance() {
        return INSTANCE;
    }

    private LocalGameHttpServer() {
    }

    public synchronized String getGameEntryUrl() {
        ensureStarted();
        return "http://127.0.0.1:" + port + "/index.html?desktop=javafx-http&ts=" + System.nanoTime();
    }

    public synchronized void stop() {
        if (server != null) {
            server.stop(0);
            server = null;
            port = -1;
        }
    }

    private void ensureStarted() {
        if (server != null) {
            return;
        }
        try {
            HttpServer httpServer = HttpServer.create(new InetSocketAddress(InetAddress.getLoopbackAddress(), 0), 0);
            httpServer.createContext("/", this::handleRequest);
            httpServer.setExecutor(Executors.newCachedThreadPool(runnable -> {
                Thread thread = new Thread(runnable, "construct2game-local-http");
                thread.setDaemon(true);
                return thread;
            }));
            httpServer.start();
            server = httpServer;
            port = httpServer.getAddress().getPort();
            System.out.println("Local game server started at http://127.0.0.1:" + port);
        } catch (IOException exception) {
            throw new IllegalStateException("Failed to start local game server.", exception);
        }
    }

    private void handleRequest(HttpExchange exchange) throws IOException {
        try {
            String method = exchange.getRequestMethod();
            if (!"GET".equalsIgnoreCase(method) && !"HEAD".equalsIgnoreCase(method)) {
                sendText(exchange, 405, "Method Not Allowed");
                return;
            }

            String path = exchange.getRequestURI().getPath();
            if (path == null || path.isBlank() || "/".equals(path)) {
                path = "/index.html";
            }
            String normalizedPath = normalizePath(path);
            if (normalizedPath == null) {
                sendText(exchange, 400, "Bad Request");
                return;
            }

            String resourcePath = RESOURCE_ROOT + normalizedPath;
            URL resource = ResourcesPathUtil.class.getResource(resourcePath);
            if (resource == null) {
                sendText(exchange, 404, "Not Found");
                return;
            }

            byte[] bytes;
            try (InputStream inputStream = resource.openStream()) {
                bytes = inputStream.readAllBytes();
            }

            Headers headers = exchange.getResponseHeaders();
            headers.set("Content-Type", guessContentType(normalizedPath));
            headers.set("Cache-Control", "no-store, no-cache, must-revalidate");

            if ("HEAD".equalsIgnoreCase(method)) {
                exchange.sendResponseHeaders(200, -1);
                return;
            }

            exchange.sendResponseHeaders(200, bytes.length);
            try (OutputStream outputStream = exchange.getResponseBody()) {
                outputStream.write(bytes);
            }
        } finally {
            exchange.close();
        }
    }

    private String normalizePath(String path) {
        String normalized = path.replace('\\', '/');
        if (!normalized.startsWith("/")) {
            normalized = "/" + normalized;
        }
        if (normalized.contains("..")) {
            return null;
        }
        return normalized;
    }

    private String guessContentType(String path) {
        String lowerPath = path.toLowerCase(Locale.ROOT);
        for (Map.Entry<String, String> entry : CONTENT_TYPES.entrySet()) {
            if (lowerPath.endsWith(entry.getKey())) {
                return entry.getValue();
            }
        }
        return "application/octet-stream";
    }

    private void sendText(HttpExchange exchange, int statusCode, String body) throws IOException {
        byte[] bytes = body.getBytes(StandardCharsets.UTF_8);
        exchange.getResponseHeaders().set("Content-Type", "text/plain; charset=UTF-8");
        exchange.sendResponseHeaders(statusCode, bytes.length);
        try (OutputStream outputStream = exchange.getResponseBody()) {
            outputStream.write(bytes);
        }
    }
}
