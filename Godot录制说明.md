# Godot 怎么录制（三条路，按省事程度排）

## 你手上的现状（我先确认过）

- Godot 版本：`C:\Users\Sabrina\AppData\Local\Microsoft\WinGet\Packages\GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe\Godot_v4.7.2-stable_win64.exe`
- 项目路径：`C:\Users\Sabrina\Documents\ChatGPT\最后的地铁：0017\岚桥站0017-Godot`（主场景 `scenes/main.tscn`，窗口 1600×900，Forward+）
- 实测结论：Godot 自带的录制模式在你这个项目上**能用**。我用它录了 10 秒，得到一个 **28.9 MB 的 .avi**（约 2.9 MB/秒，1600×900 / 30fps / MJPEG）。**默认只录画面，不录声音**。

---

## 方案 1（最省事，直接出 mp4）：Win+G 游戏栏

Win11 自带，不用装任何东西。

1. 双击 `启动岚桥站0017-游戏.bat` 进游戏
2. 按 **Win+Alt+R** 开始录，再按一次停止（也可以 Win+G 打开面板点录制）
3. 文件自动落在 `C:\Users\Sabrina\Videos\Captures\*.mp4`

设置：**设置 → 游戏 → 捕获** → 帧速率 30fps、视频质量「高」、勾上「录制音频」。

注意：
- 它录的是窗口/屏幕，录之前 Alt+Tab 到干净画面，别把桌面图标录进去
- **输入法切英文**，否则中文候选框会出现在画面里
- 开始前关掉通知（Win+A → 专注助手）

---

## 方案 2（画面最稳、不掉帧，但要多一步转码）：Godot Movie Maker 模式

我已经建好了脚本，**双击 `录制-岚桥站0017-MovieMaker.bat`** 就行（录完直接关游戏窗口，文件才会写完）。

它等价于命令行：

```
"...\Godot_v4.7.2-stable_win64.exe" --path "...\岚桥站0017-Godot" --write-movie "...\_record\xxx.avi" --fixed-fps 30
```

- 画面是逐帧渲染的，不会因为电脑卡顿掉帧，适合交作业的「稳定版」
- 输出是 `.avi`，要转成 mp4（本机目前**没有** ffmpeg）：

```
winget install Gyan.FFmpeg          &:: 装完重开一个终端
ffmpeg -i xxx.avi -c:v libx264 -crf 18 -pix_fmt yuv420p out.mp4
```

- **想连游戏声音一起录**：项目设置 → Audio → Driver 改成 `Dummy`，重启编辑器。录完会额外生成一个 `.wav`，和 avi 一起合成：

```
ffmpeg -i xxx.avi -i xxx.wav -c:v libx264 -crf 18 -pix_fmt yuv420p -c:a aac out.mp4
```

- 体量参考：90 秒 ≈ 260 MB 的 avi，转完 mp4 大约 10–20 MB

---

## 方案 3（最专业，可长时间录）：OBS

```
winget install OBSProject.OBSStudio
```

来源 → **窗口采集** → 选 Godot 窗口 → 输出 1080p / 30fps → 录制 → mp4。要加摄像头、字幕、多来源切换时才用它。

---

## 录之前 5 个小动作（三个方案通用）

1. 游戏窗口 1600×900 或全屏，鼠标别停在 HUD 上挡字
2. 输入法切英文
3. 关掉桌面通知
4. 先空跑一遍要录的路径，掐表 **60–90 秒** 就够（答辩不给你放长片）
5. 录完看一眼首帧和末帧，别录到桌面或黑屏

---

## 录完之后

把 mp4 放进答辩 PPT：在「三层原型架构」或「原型整体流程」页，**插入 → 视频 → 此设备**。

顺带一句：如果只是想证明 3D 能跑，**2D 原型链接**（`https://visionary-concha-bf9fea.netlify.app/`）当场点比放视频更稳；视频是防网络/防卡顿的备份。
