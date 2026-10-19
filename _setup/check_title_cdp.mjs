// 用 Edge headless + CDP 实测 Godot 页启动后的 document.title 变化。
import { spawn } from "node:child_process";
import { rmSync } from "node:fs";

const EDGE = "C:\\Program Files (x86)\\Microsoft\\Edge\\Application\\msedge.exe";
const URL = "https://visionary-concha-bf9fea.netlify.app/game/";
const PORT = 9333;
const PROFILE = "C:\\Windows\\Temp\\edge-title-check-" + Date.now();
const EXPECT = "诡异事务局 · 第一季「补丁」";

const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

const edge = spawn(EDGE, [
  "--headless=new",
  `--remote-debugging-port=${PORT}`,
  `--user-data-dir=${PROFILE}`,
  "--no-first-run",
  "--no-default-browser-check",
  "--use-angle=swiftshader",
  "--enable-unsafe-swiftshader",
  "--autoplay-policy=no-user-gesture-required",
  "about:blank",
], { stdio: "ignore" });

async function json(path, init) {
  const r = await fetch(`http://127.0.0.1:${PORT}${path}`, init);
  return r.json();
}

async function waitPort() {
  for (let i = 0; i < 60; i++) {
    try {
      await json("/json/version");
      return;
    } catch {
      await sleep(250);
    }
  }
  throw new Error("Edge CDP 未启动");
}

let ws;
let id = 0;
const pending = new Map();
function send(method, params = {}) {
  return new Promise((resolve) => {
    const msgId = ++id;
    pending.set(msgId, resolve);
    ws.send(JSON.stringify({ id: msgId, method, params }));
  });
}

try {
  await waitPort();
  const target = await json("/json/new?about:blank", { method: "PUT" });
  ws = new WebSocket(target.webSocketDebuggerUrl);
  await new Promise((res, rej) => {
    ws.onopen = res;
    ws.onerror = rej;
  });
  ws.onmessage = (ev) => {
    const msg = JSON.parse(ev.data);
    if (msg.id && pending.has(msg.id)) {
      pending.get(msg.id)(msg.result || msg.error);
      pending.delete(msg.id);
    }
  };

  await send("Page.enable");
  await send("Runtime.enable");
  await send("Page.navigate", { url: URL });

  const history = [];
  let last = null;
  const started = Date.now();
  for (let i = 0; i < 60; i++) {
    await sleep(1000);
    const res = await send("Runtime.evaluate", {
      expression: "({title: document.title, canvas: !!document.querySelector('canvas'), status: !!document.getElementById('status')})",
      returnByValue: true,
    });
    const v = res?.result?.value;
    if (!v) continue;
    const stamp = ((Date.now() - started) / 1000).toFixed(0);
    const key = `${v.title}|${v.canvas}|${v.status}`;
    if (key !== last) {
      history.push(`${stamp}s  title=${JSON.stringify(v.title)}  canvas=${v.canvas}  statusOverlay=${v.status}`);
      last = key;
    }
    if (!v.status && v.canvas) break; // 引擎启动并隐藏加载层后，再多等校正
    if (i >= 45) break;
  }
  await sleep(2500);

  const final = await send("Runtime.evaluate", {
    expression: "document.title",
    returnByValue: true,
  });
  const title = final?.result?.value;

  console.log("标题变化：");
  console.log(history.map((h) => "  " + h).join("\n") || "  (无)");
  console.log("\nFINAL TITLE:", JSON.stringify(title));
  const ok = title === EXPECT && !title.includes("0017");
  console.log(ok ? "PASS: 标签为《诡异事务局》且不含 0017" : "FAIL: 标签不符合预期");
  process.exitCode = ok ? 0 : 1;
} catch (err) {
  console.error("ERROR:", err);
  process.exitCode = 2;
} finally {
  try { ws?.close(); } catch {}
  edge.kill();
  await sleep(800);
  try { rmSync(PROFILE, { recursive: true, force: true }); } catch {}
}
