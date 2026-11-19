% run_synth_raw.m  --  item (5) synthetic RAW with KNOWN linear ground truth -> pipeline -> PSNR/deltaE + ablation
% GT = scene linear RGB. Simulate camera: cam = A*linGT*gains + noise -> mosaic -> RAW.
% Pipeline stages use known WB (1/gains) and CCM (=inv(A)) so recovery is well-posed.
clear; clc;
root = 'D:\Desktop\isp';

% ---- known linear ground truth: controlled synthetic scene (smooth gradients + colour) ----
H = 600; W = 900;
[X,Y] = meshgrid(linspace(0,1,W), linspace(0,1,H));
R = 0.10 + 0.80*X;
G = 0.10 + 0.80*Y;
B = 0.15 + 0.70*(0.5 + 0.5*cos(2*pi*(X + 0.5*Y)));
GTsrgb = min(max(cat(3,R,G,B),0),1);
Lt   = srgb2lin(GTsrgb);                 % scene linear
[H,W,~] = size(Lt);

% ---- simulate camera RAW (CFA + gains + noise, no vignette) ----
A = [0.62 0.30 0.08; 0.20 0.72 0.08; 0.06 0.24 0.70];
g = [1.05 1.00 0.95];
cam = reshape(reshape(Lt,[],3)*A.', H,W,3) .* reshape(g,1,1,3);
rng(11);
cam = cam + 0.003*randn(size(cam)) + 0.02*sqrt(max(cam,0)).*randn(size(cam));
cam = max(cam,0);
M = zeros(H,W);
M(1:2:end,1:2:end) = cam(1:2:end,1:2:end,1);
M(1:2:end,2:2:end) = cam(1:2:end,2:2:end,2);
M(2:2:end,1:2:end) = cam(2:2:end,1:2:end,2);
M(2:2:end,2:2:end) = cam(2:2:end,2:2:end,3);
raw = uint16(min(max(round(M*(16383-512)+512),0),65535));

% ---- hand-written pipeline stages ----
d = (double(raw)-512)/(16383-512); d=max(min(d,1),0);
lin = demosaic_bilinear(d);
s1 = lin2srgb(min(max(lin,0),1));                    % S1 demosaic only

gn = (1./g); gn = gn/mean(gn);
lin2 = lin .* reshape(gn,1,1,3);
s2 = min(max(lin2,0),1).^(1/2.2);                    % S2 +WB +gamma

Mccm = inv(A);
lin3 = reshape(reshape(lin2,[],3)*Mccm.', H,W,3); lin3=min(max(lin3,0),1);
V3 = lin3.^(1/2.2); s3 = V3;                         % S3 +CCM (full)

blur = gaussian_blur(V3,1.0);
s4 = min(max(V3 + 0.6*(V3-blur),0),1);               % S4 +sharpen (trade-off)

% ---- metrics ----
fprintf('stage                     PSNR(dB)  dE2000(mean)  sharpness\n');
printrow('S1 demosaic only',        GTsrgb, s1);
printrow('S2 +WB +gamma',           GTsrgb, s2);
printrow('S3 +CCM (full)',          GTsrgb, s3);
printrow('S4 +sharpen',             GTsrgb, s4);

% ---- save ----
imwrite(s1, fullfile(root,'out','synthraw_s1_demosaic.png'));
imwrite(s2, fullfile(root,'out','synthraw_s2_wb.png'));
imwrite(s3, fullfile(root,'out','synthraw_s3_full.png'));
imwrite(s4, fullfile(root,'out','synthraw_s4_sharpen.png'));
e3 = mean(abs(s3-GTsrgb),3); e3 = e3/max(e3(:));
cmp = imtile({GTsrgb, s3, repmat(e3,[1 1 3])}, 'GridSize',[1 3]);
imwrite(imresize(cmp,[NaN 1050]), fullfile(root,'out','synthraw_compare.png'));
disp('DONE');

function printrow(name, GT, out)
    mse = mean((GT(:)-out(:)).^2);
    p = 10*log10(1/max(mse,eps));
    H=size(GT,1); W=size(GT,2); N=H*W; k=min(5000,N); idx=randperm(N,k);
    a=reshape(GT,N,3); b=reshape(out,N,3);
    e = mean(ciede2000(srgb2lab(a(idx,:)), srgb2lab(b(idx,:))));
    sh = mean(abs(diff(rgb2gray(out),1,1)),'all');
    fprintf('%-24s  %6.2f    %6.2f      %.5f\n', name, p, e, sh);
end
