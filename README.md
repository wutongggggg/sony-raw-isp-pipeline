# ISP 影像调校：Sony a7R3 RAW 软件 ISP 流水线（MATLAB）

MATLAB R2025b 实现的软件 ISP 流水线，直接读取 Sony a7R3 的 **.ARW** 原始数据（图像处理工具箱
`rawread`/`rawinfo`，LibRaw 0.21.4 解码），逐级完成 ISP 处理，并用 PSNR / CIEDE2000 做量化评估。
全部算法手写实现，不依赖高层图像处理 API 完成核心步骤。

## 流水线

黑电平校正 → 手写双线性去马赛克（RGGB）→ 灰度世界/白点白平衡 → 3×3 色彩校正矩阵（CCM，最小二乘拟合）
→ 自动曝光 → Gamma 编码 → 双边 / 非局部均值(NLM) 降噪 → 色调曲线 / 局部对比 → 非锐化掩膜锐化

## 主要结果

- **CCM + CIEDE2000**：3×3 CCM 最小二乘拟合，ΔE2000 均值 **7.77 → 1.64**（中位 0.81）
- **LSC**：径向暗角与方向性建模分析（灰场/白场），完成均匀性评估
- **降噪**：手写双边 / NLM，噪声 σ **0.0079 → 0.0021 / 0.0012**（−73% / −85%）
- **色调 / 局部对比**：局部对比 **+32%**，高光裁切 0.13% → 0.32%
- **合成 RAW 真值评估（PSNR/ΔE + 分阶段消融）**：
  | 阶段 | PSNR(dB) | ΔE2000 | 锐度 |
  |---|---|---|---|
  | 仅去马赛克 | 18.59 | 10.42 | 0.0064 |
  | +白平衡+Gamma | 18.60 | 10.53 | 0.0062 |
  | +CCM（完整） | 27.69 | 2.27 | 0.0093 |
  | +锐化 | 26.54 | 2.91 | 0.0131 |
- **全分辨率 42MP + 批量**：hdr / res / highiso 三张 5320×7968，单张约 22–25 s
- **与相机直出对比**：AdobeRGB→sRGB 后并排对比，PSNR 15.2–16.5 dB、结构一致

## 目录结构

```
.
├─ raw/                 原始 ARW / JPG（测试素材）
├─ out/                 各阶段结果图与对比图
├─ docs/                报告（ISP调校报告.md/.docx/.pdf）与说明
├─ isp_read_raw.m       读取 ARW -> uint16 马赛克 + 元数据
├─ demosaic_bilinear.m  手写双线性去马赛克（RGGB）
├─ isp_pipeline.m       主流水线
├─ bilateral_filter.m   手写双边滤波
├─ nlm_filter.m         手写非局部均值
├─ gaussian_blur.m      手写高斯模糊（可分离）
├─ srgb2lab.m / ciede2000.m   色彩空间与 ΔE2000
├─ lsc_apply.m          LSC 径向增益应用
├─ run_*.m              各实验脚本（CCM / 降噪 / 色调 / 合成RAW / 全分辨率 / 索尼对比）
└─ build_isp_report.py  报告生成
```

## 运行

```matlab
cd D:\Desktop\isp
run_isp          % 单张流水线演示
run_ccm          % CCM + ΔE 标定
run_denoise      % 降噪对比
run_tone         % 色调 / 局部对比
run_synth_raw    % 合成 RAW PSNR / ΔE 消融
run_fullres      % 全分辨率 42MP 批量
```
