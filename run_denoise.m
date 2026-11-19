% run_denoise.m  --  item (3) denoise on high-ISO: hand-written bilateral vs NLM
clear; clc;
root = 'D:\Desktop\isp';
[raw, meta] = isp_read_raw(fullfile(root,'raw','highiso.ARW'));
r0=1501; r1=2500; c0=1501; c1=2900;           % 1000 x 1400 crop
crop = raw(r0:r1, c0:c1);

% to linear RGB / AWB / gamma (view domain)
d = (double(crop)-meta.black)/(meta.white-meta.black); d=max(min(d,1),0);
rgb = demosaic_bilinear(d);
m = reshape(mean(mean(rgb,1),2),1,3); gains=mean(m)./m; rgb=rgb.*reshape(gains,1,1,3);
V = min(max(rgb,0),1).^(1/2.2);               % gamma-encoded, denoise in view domain

% hand-written denoisers (per channel)
Vb = zeros(size(V)); Vn = zeros(size(V));
for ch=1:3
    Vb(:,:,ch) = bilateral_filter(V(:,:,ch), 2.0, 0.06, 2);
    Vn(:,:,ch) = nlm_filter(V(:,:,ch), 0.05, 3, 1);
end

% noise estimate (MAD of high-pass on green)
hp = @(Ig) Ig - imgaussfilt(Ig,1);
sig = @(Ig) 1.4826*median(abs(hp(Ig(:,:,2)) - median(hp(Ig(:,:,2)),'all')),'all');
sharp = @(Ig) mean(abs(diff(rgb2gray(Ig),1,1)),'all');
fprintf('noise sigma  : noisy=%.4f  bilateral=%.4f  NLM=%.4f\n', sig(V), sig(Vb), sig(Vn));
fprintf('sharpness    : noisy=%.4f  bilateral=%.4f  NLM=%.4f\n', sharp(V), sharp(Vb), sharp(Vn));

% save full comparisons (downscaled)
imwrite(imresize(V,[NaN 700]),  fullfile(root,'out','dn_noisy.png'));
imwrite(imresize(Vb,[NaN 700]), fullfile(root,'out','dn_bilateral.png'));
imwrite(imresize(Vn,[NaN 700]), fullfile(root,'out','dn_nlm.png'));
fullc = imtile({imresize(V,[NaN 500]),imresize(Vb,[NaN 500]),imresize(Vn,[NaN 500])},'GridSize',[1 3]);
imwrite(fullc, fullfile(root,'out','denoise_full_compare.png'));

% zoom on a detailed region
zr=400:700; zc=500:900;
zm = imtile({V(zr,zc,:),Vb(zr,zc,:),Vn(zr,zc,:)},'GridSize',[1 3]);
imwrite(imresize(zm,2,'nearest'), fullfile(root,'out','denoise_zoom_compare.png'));
disp('DONE');
