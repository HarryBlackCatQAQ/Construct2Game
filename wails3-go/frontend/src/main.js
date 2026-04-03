import {Events} from "@wailsio/runtime";
import {GameService} from "../bindings/construct2gamewails3";

const gameFrame = document.getElementById("game-frame");
const loadingPanel = document.getElementById("loading-panel");
const statusText = document.getElementById("status-text");
const runtimePill = document.getElementById("runtime-pill");
const modalLayer = document.getElementById("modal-layer");
const modalBackdrop = document.getElementById("modal-backdrop");
const modalClose = document.getElementById("modal-close");
const modalContent = document.getElementById("modal-content");
const shellNotice = document.getElementById("shell-notice");
const shellNoticeText = document.getElementById("shell-notice-text");
const shellNoticeClose = document.getElementById("shell-notice-close");

let lastFocusTimer = null;
let noticeTimer = null;

function setStatus(message) {
    if (statusText) {
        statusText.textContent = message;
    }
}

function focusGameFrame(delay = 50) {
    window.clearTimeout(lastFocusTimer);
    lastFocusTimer = window.setTimeout(() => {
        gameFrame.focus();
        try {
            gameFrame.contentWindow?.focus();
        } catch (error) {
            console.debug("Unable to focus iframe content window", error);
        }
    }, delay);
}

function gameUrl() {
    return `/game/index.html?desktop=wails&ts=${Date.now()}`;
}

function reloadGame(message) {
    loadingPanel.classList.remove("is-hidden");
    setStatus(message);
    gameFrame.src = gameUrl();
}

function openModal(html) {
    modalContent.innerHTML = html;
    modalLayer.hidden = false;
    document.body.classList.add("modal-open");
}

function closeModal() {
    modalLayer.hidden = true;
    modalContent.innerHTML = "";
    document.body.classList.remove("modal-open");
    focusGameFrame();
}

function hideNotice() {
    window.clearTimeout(noticeTimer);
    shellNotice.hidden = true;
}

function showNotice(message, sticky = true) {
    shellNoticeText.textContent = message;
    shellNotice.hidden = false;
    window.clearTimeout(noticeTimer);
    if (!sticky) {
        noticeTimer = window.setTimeout(hideNotice, 5000);
    }
}

function escapeHtml(value) {
    return String(value)
        .replaceAll("&", "&amp;")
        .replaceAll("<", "&lt;")
        .replaceAll(">", "&gt;")
        .replaceAll('"', "&quot;")
        .replaceAll("'", "&#39;");
}

function renderHelpModal() {
    return `
        <div class="modal-heading">
            <div class="modal-eyebrow">游戏说明</div>
            <h2 id="modal-title">桌面版操作指引</h2>
        </div>
        <img class="modal-hero" src="/app-assets/gameShowsImage.png" alt="Game instructions"/>
        <div class="modal-grid">
            <div class="modal-panel">
                <h3>基础操作</h3>
                <p>J 攻击，K 跳跃，支持二段跳。</p>
                <p>Q / E 为技能键，先点一次游戏画面再施法会更稳。</p>
                <p>F11 可以切换桌面全屏。</p>
            </div>
            <div class="modal-panel">
                <h3>桌面壳层</h3>
                <p>关闭窗口时不会直接退出，而是隐藏到系统托盘。</p>
                <p>如果画面异常，可以用“重新载入”快速重置回主菜单。</p>
                <p>菜单栏、托盘和顶部按钮的行为保持一致。</p>
            </div>
        </div>
    `;
}

function renderEnvironmentModal(info) {
    const rows = [
        ["应用名称", info.appName],
        ["应用版本", info.appVersion],
        ["Go 版本", info.goVersion],
        ["Wails 版本", info.wailsVersion],
        ["运行系统", `${info.goos} / ${info.goarch}`],
        ["浏览器内核", navigator.userAgent]
    ];

    return `
        <div class="modal-heading">
            <div class="modal-eyebrow">运行环境</div>
            <h2 id="modal-title">当前桌面环境信息</h2>
        </div>
        <div class="env-list">
            ${rows.map(([label, value]) => `
                <div class="env-row">
                    <span>${escapeHtml(label)}</span>
                    <code>${escapeHtml(value)}</code>
                </div>
            `).join("")}
        </div>
    `;
}

async function showEnvironmentModal() {
    try {
        const info = await GameService.GetEnvironmentInfo();
        openModal(renderEnvironmentModal(info));
        setStatus("已打开运行环境信息。");
    } catch (error) {
        console.error(error);
        setStatus("读取运行环境失败，请查看控制台日志。");
    }
}

async function toggleFullscreen() {
    try {
        await GameService.ToggleFullscreen();
        setStatus("已切换全屏状态。");
    } catch (error) {
        console.error(error);
        setStatus("切换全屏失败，请重试。");
    } finally {
        focusGameFrame();
    }
}

function normalizeGameRuntimeMessage(message) {
    const text = String(message || "").trim();

    if (!text) {
        return "游戏给出了一条空提示。";
    }

    if (text.includes("Error fetching data.js")) {
        return "游戏资源 data.js 读取失败，请点击“重新载入”，如果还不行再告诉我。";
    }

    if (text.startsWith("Failed to load image:")) {
        const imagePath = text.substring("Failed to load image:".length).trim();
        return imagePath
            ? `游戏图片资源读取失败：${imagePath}`
            : "游戏图片资源读取失败。";
    }

    return `游戏运行提示：${text}`;
}

function runCommand(name) {
    switch (name) {
        case "return-main-menu":
            reloadGame("已返回主菜单。");
            break;
        case "reload-game":
            reloadGame("正在重新载入游戏...");
            break;
        case "show-game-help":
            openModal(renderHelpModal());
            setStatus("已打开游戏说明。");
            break;
        case "show-environment":
            void showEnvironmentModal();
            break;
        case "toggle-fullscreen":
            void toggleFullscreen();
            break;
        default:
            console.warn(`Unknown command: ${name}`);
    }
}

document.querySelectorAll("[data-command]").forEach((button) => {
    button.addEventListener("click", () => {
        runCommand(button.dataset.command);
    });
});

gameFrame.addEventListener("load", () => {
    loadingPanel.classList.add("is-hidden");
    setStatus("游戏已载入，可以开始游玩。");
    focusGameFrame(120);
});

gameFrame.addEventListener("error", () => {
    loadingPanel.classList.add("is-hidden");
    setStatus("游戏载入失败，请尝试重新载入。");
});

modalBackdrop.addEventListener("click", closeModal);
modalClose.addEventListener("click", closeModal);
shellNoticeClose.addEventListener("click", hideNotice);

window.addEventListener("keydown", (event) => {
    if (event.key === "Escape" && !modalLayer.hidden) {
        event.preventDefault();
        closeModal();
        return;
    }

    if (event.key === "F11") {
        event.preventDefault();
        void toggleFullscreen();
    }
});

window.addEventListener("message", (event) => {
    if (event.source !== gameFrame.contentWindow) {
        return;
    }

    const payload = event.data ?? {};
    if (payload.channel === "construct2-alert") {
        const message = normalizeGameRuntimeMessage(payload.message);
        setStatus(message);
        showNotice(message, true);
        return;
    }

    if (payload.channel === "construct2-error") {
        const message = `游戏脚本异常：${String(payload.message || "未知错误")}`;
        setStatus(message);
        showNotice(message, true);
    }
});

Events.On("desktop:command", (event) => {
    const payload = event.data ?? {};
    if (payload.name === "status-message" && payload.message) {
        setStatus(payload.message);
        return;
    }
    if (typeof payload.name === "string") {
        runCommand(payload.name);
    }
});

setStatus("正在载入游戏资源...");
void GameService.GetEnvironmentInfo()
    .then((info) => {
        if (runtimePill) {
            runtimePill.textContent = `${info.wailsVersion} / ${info.goos}`;
        }
    })
    .catch((error) => {
        console.error(error);
        if (runtimePill) {
            runtimePill.textContent = "Wails 3";
        }
    });
