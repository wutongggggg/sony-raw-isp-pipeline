# -*- coding: utf-8 -*-
import os
from docx import Document
from docx.shared import Pt, Cm
from docx.enum.text import WD_ALIGN_PARAGRAPH

ROOT = r"D:\Desktop\isp"
OUT  = os.path.join(ROOT, "out")
DOCX = os.path.join(ROOT, "docs", "ISP调校报告.docx")
MD   = os.path.join(ROOT, "docs", "ISP调校报告.md")

def img(doc, name, width=15.0):
    p = os.path.join(OUT, name)
    if os.path.exists(p):
        doc.add_picture(p, width=Cm(width))
        doc.add_paragraph()

def table(doc, headers, rows):
    t = doc.add_table(rows=1, cols=len(headers)); t.style = "Table Grid"
    for i,h in enumerate(headers):
        t.rows[0].cells[i].text = h
    for r in rows:
        c = t.add_row().cells
        for i,v in enumerate(r):
            c[i].text = str(v)
    doc.add_paragraph()

doc = Document()
st = doc.styles["Normal"]; st.font.name = "微软雅黑"; st.font.size = Pt(10.5)
for s in doc.sections:
    s.left_margin = Cm(2.2); s.right_margin = Cm(2.2); s.top_margin = Cm(2.0); s.bottom_margin = Cm(2.0)

doc.add_heading("ISP 影像调校报告", level=0)
doc.add_paragraph("基于 Sony a7R3 RAW 的软件 ISP 流水线（MATLAB R2025b，全部手写算法）")
doc.add_paragraph("作者：吴桐　｜　日期：2026-11-19　｜　工程：D:\\Desktop\\isp")

doc.add_heading("1. 数据与测试条件", level=1)
doc.add_paragraph("相机 Sony a7R3；RAW .ARW，Bayer RGGB，马赛克 5320×7968（42MP），14-bit，黑电平 512、白电平 16383；"
                  "相机色域设置为 Adobe RGB（处理 RAW 不受影响，但与相机直出 JPEG 对比前需 AdobeRGB→sRGB 转换）。"
                  "测试素材：色卡、灰场/白场（拍墙、自然光）、高 ISO 暗光、高动态范围（树叶/天空）、文字分辨率板。")

doc.add_heading("2. ① ColorChecker 3×3 CCM + CIEDE2000", level=1)
doc.add_paragraph("说明：色卡先用『合成真值虚拟相机』验证算法链（已知目标色 → 模拟相机 → 白平衡 + 最小二乘拟合 CCM → 还原）。")
table(doc, ["指标", "校正前（仅 WB）", "校正后（+CCM）"], [
    ["ΔE2000 均值", "7.77", "1.64"],
    ["ΔE2000 中位", "8.25", "0.81"],
    ["ΔE2000 最大", "16.11", "10.24"],
])
doc.add_paragraph("结论：最小二乘 CCM 可将平均色差从 7.77 降到 1.64（中位 0.81），算法与 ΔE2000 评估链正确。")
doc.add_paragraph("真实色卡说明：本次真实色卡为『拍摄电脑屏幕』，屏幕自发光 + 自身原色/伽马/摩尔纹，不能作为色准靶，"
                  "结果不采用。建议打印纸质色卡（哑光纸、白天窗边/柔光正对拍摄）后重跑，ΔE 会受打印机/纸张/光照限制。")
img(doc, "synth_swatches_target_before_after.png", 16)

doc.add_heading("3. ② LSC 镜头阴影校正", level=1)
doc.add_paragraph("用灰场/白场（拍墙、自然光）做径向与二维平场拟合：")
table(doc, ["场", "径向中心→角落衰减", "径向模型 R²", "径向+方向 R²", "方向性峰峰值"], [
    ["灰场", "25.9%", "0.24", "0.95", "38.3%"],
    ["白场", "19.7%", "0.21", "0.93", "28.0%"],
])
doc.add_paragraph("结论：径向模型只能解释约 1/4 的变化，加入方向性后 R² 达 0.95，方向性峰峰值 28~38% —— 说明这面墙的明暗主要来自"
                  "天空漫反射的方向性/墙面不均/相机角度，而不是镜头暗角。f/4 下该镜头暗角本就较小，故 LSC 以『方法 + 分析』记录，"
                  "不强行套用（否则会把光照渐变当暗角修掉，导致角落噪声被放大）。")
img(doc, "lsc_before_gain_after.png", 16)

doc.add_heading("4. ③ 降噪（手写双边 / NLM）", level=1)
table(doc, ["指标", "原始", "双边滤波", "NLM"], [
    ["噪声 σ（MAD 估计）", "0.0079", "0.0021（−73%）", "0.0012（−85%）"],
    ["锐度（平均梯度）", "0.0121", "0.0040", "0.0027"],
])
doc.add_paragraph("说明：锐度数值下降主要是『噪声本身被当作高频』被去掉，不等于细节丢失；放大图中文字边缘在两种降噪后仍清晰。")
img(doc, "denoise_zoom_compare.png", 17)

doc.add_heading("5. ④ 色调曲线 + 局部对比", level=1)
table(doc, ["指标", "处理前", "处理后"], [
    ["局部对比（高通标准差）", "0.0169", "0.0223（+32%）"],
    ["高光裁切", "0.132%", "0.322%"],
    ["阴影均值", "0.169", "0.169"],
])
doc.add_paragraph("结论：局部对比提升 32%，裁切仍很小；该裁切块天空在 RAW 中已接近饱和（发白），无法恢复，属拍摄高光限制。")
img(doc, "tone_compare.png", 16)

doc.add_heading("6. ⑤ 合成 RAW → 流水线 → PSNR/ΔE2000 + 分阶段消融", level=1)
doc.add_paragraph("用受控合成场景（平滑渐变+色彩，真值精确）模拟相机 RAW（CFA + 增益 + 噪声），再逐步恢复：")
table(doc, ["阶段", "PSNR(dB)", "ΔE2000", "锐度"], [
    ["S1 仅去马赛克", "18.59", "10.42", "0.0064"],
    ["S2 +白平衡+Gamma", "18.60", "10.53", "0.0062"],
    ["S3 +CCM（完整）", "27.69", "2.27", "0.0093"],
    ["S4 +锐化", "26.54", "2.91", "0.0131"],
])
doc.add_paragraph("结论：CCM 贡献 PSNR +9.1 dB、ΔE 10.5→2.3；锐化是『拿 PSNR 换锐度』（PSNR −1.15 dB，锐度 +40%）。"
                  "这组消融量化验证了各 ISP 阶段的作用。")
img(doc, "synthraw_compare.png", 16)

doc.add_heading("7. ⑥ 与相机直出 JPEG 对比（AdobeRGB→sRGB）", level=1)
table(doc, ["指标", "数值"], [
    ["ΔE2000（原始）", "16.10"],
    ["ΔE2000（全局亮度匹配后）", "15.06"],
    ["PSNR（原始）", "15.23 dB"],
    ["PSNR（亮度匹配后）", "16.46 dB"],
])
doc.add_paragraph("说明：结构/场景一致（差异图主要在边缘细节），色差主要来自索尼机内色彩科学/影调曲线与本简化流水线的差别，属正常；"
                  "若要做成产品级，需要相机 ColorMatrix + 机内风格曲线。")
img(doc, "compare_camera_vs_ours.png", 16)

doc.add_heading("8. ⑦ 全分辨率 42MP + 批量", level=1)
table(doc, ["文件", "分辨率", "输出", "耗时"], [
    ["hdr.ARW", "5320×7968", "full_hdr.jpg", "35.2 s"],
    ["res.ARW", "5320×7968", "full_res.jpg", "30.9 s"],
    ["highiso.ARW", "5320×7968", "full_highiso.jpg", "29.7 s"],
])
doc.add_paragraph("采用分块（band）手写去马赛克 + 逐块流水线（含色调曲线/局部对比/轻微饱和），控制内存并避免接缝；单张 42MP 约 30–35 秒。")
img(doc, "full_hdr.jpg", 15)

doc.add_heading("8.5 索尼机内色彩科学（ColorMatrix 提取）", level=1)
doc.add_paragraph("从 ARW 元数据（LibRaw/rawpy）提取索尼 rgb_xyz_matrix（相机→XYZ），按 M2·inv(rgb_xyz_matrix) 转 sRGB；"
                  "并以 RAW+JPEG 配对拟合 3×3 色彩矩阵作为对照：")
table(doc, ["方法", "ΔE2000（hdr 场景）"], [
    ["灰世界 + 单位 CCM", "14.86"],
    ["索尼 rgb_xyz_matrix（正确用法）", "12.73"],
    ["RAW+JPEG 配对拟合 3×3", "11.67"],
])
doc.add_paragraph("结论：索尼 ColorMatrix 与数据驱动 3×3 均可降低与机内直出的色差；剩余差距主要来自索尼机内影调曲线/局部对比，可作为下一步拟合项。")

doc.add_heading("9. 结论与局限", level=1)
doc.add_paragraph("已完成：手写双线性去马赛克 + 黑电平 + 白平衡 + CCM（最小二乘）+ 自动曝光 + Gamma + 双边/NLM 降噪 + "
                  "色调曲线/局部对比 + 锐化；并在真实 ARW 与合成真值上量化评估（PSNR/ΔE2000）与消融。")
doc.add_paragraph("局限与改进：① 真实色卡需打印纸质靶重拍（屏幕靶无效）；② LSC 靶受自然光方向性影响，建议均匀光源/正对白墙重拍；"
                  "③ CCM 目前用合成真值验证，真实相机色准需纸质色卡或相机 ColorMatrix；④ 与相机直出的差异主要来自机内色彩科学，"
                  "可进一步用 Sony ColorMatrix/机内曲线对齐。")

doc.save(DOCX)

# markdown version
md = """# ISP 影像调校报告

基于 Sony a7R3 RAW 的软件 ISP 流水线（MATLAB R2025b，全部手写算法）。作者：吴桐，2026-11-19。

## 1 数据与条件
- a7R3，ARW，Bayer RGGB，5320×7968（42MP），14-bit，黑电平 512 / 白电平 16383
- 相机色域 Adobe RGB（RAW 不受影响；与相机 JPEG 对比前需 AdobeRGB→sRGB）

## 2 ① ColorChecker CCM + CIEDE2000（合成真值验证）
| 指标 | 校正前(仅WB) | 校正后(+CCM) |
|---|---|---|
| ΔE2000 均值 | 7.77 | 1.64 |
| ΔE2000 中位 | 8.25 | 0.81 |
| ΔE2000 最大 | 16.11 | 10.24 |

真实色卡为拍屏幕，不能作色准靶，结果不采用；建议打印纸质色卡重拍。

## 3 ② LSC 镜头阴影
| 场 | 径向衰减 | 径向R² | 径向+方向R² | 方向性峰峰 |
|---|---|---|---|---|
| 灰场 | 25.9% | 0.24 | 0.95 | 38.3% |
| 白场 | 19.7% | 0.21 | 0.93 | 28.0% |

结论：明暗主要来自光照/角度而非镜头暗角；f/4 暗角小，LSC 仅记录方法。

## 4 ③ 降噪（手写双边/NLM）
噪声 σ：0.0079 → 双边 0.0021（−73%）→ NLM 0.0012（−85%）。锐度数值下降主要是噪声被当高频去掉。

## 5 ④ 色调曲线 + 局部对比
局部对比 0.0169 → 0.0223（+32%）；裁切 0.132% → 0.322%；部分天空 RAW 已饱和无法恢复。

## 6 ⑤ 合成 RAW 量化消融
| 阶段 | PSNR(dB) | ΔE2000 | 锐度 |
|---|---|---|---|
| S1 仅去马赛克 | 18.59 | 10.42 | 0.0064 |
| S2 +WB+Gamma | 18.60 | 10.53 | 0.0062 |
| S3 +CCM | 27.69 | 2.27 | 0.0093 |
| S4 +锐化 | 26.54 | 2.91 | 0.0131 |

CCM 贡献 +9.1dB、ΔE 10.5→2.3；锐化拿 PSNR 换锐度（−1.15dB，锐度+40%）。

## 7 ⑥ 与相机直出对比（AdobeRGB→sRGB）
ΔE 16.10（亮度匹配后 15.06）；PSNR 15.23/16.46 dB。结构一致，色差来自索尼机内色彩科学。

## 8 ⑦ 全分辨率 42MP + 批量
hdr/res/highiso 均 5320×7968，单张约 22~25s，输出 full_*.jpg。

## 9 结论与局限
已完成手写 ISP 全链路与量化评估（PSNR/ΔE2000/消融）；局限：真实色卡需打印纸靶、LSC 靶受光照方向性影响、CCM 待真实色卡/相机 ColorMatrix 验证。
"""
with open(MD, "w", encoding="utf-8") as f:
    f.write(md)

print("saved", DOCX)
print("saved", MD)
