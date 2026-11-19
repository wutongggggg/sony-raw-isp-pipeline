% run_tone.m  --  item (4) tone curve + local contrast (v2: shadow lift + highlight soft-compress)
clear; clc;
root = 'D:\Desktop\isp';
[raw, meta] = isp_read_raw(fullfile(root,'raw','hdr.ARW'));
r0=1801; r1=3300; c0=1801; c1=4200;
rawc = raw(r0:r1, c0:c1);
d = (double(rawc)-meta.black)/(meta.white-meta.black); d=max(min(d,1),0);
rgb = demosaic_bilinear(d);
m = reshape(mean(mean(rgb,1),2),1,3); gains=mean(m)./m; rgb=rgb.*reshape(gains,1,1,3);

% auto exposure: p99.5 -> 0.75 linear (protect highlights)
v = sort(rgb(:)); pexp = v(min(numel(v),round(0.995*numel(v))));
rgb = rgb * (0.75/max(pexp,eps)); rgb=min(max(rgb,0),1);

V = rgb.^(1/2.2);                        % BEFORE: plain gamma

% ---- hand tone curve ----
x1 = V.^0.90;                            % gentle midtone lift
x2 = 0.5 + (x1-0.5)*1.10;                % contrast
t = 0.80;                                % highlight soft-compress above t
x3 = x2;
mask = x2 > t;
x3(mask) = t + (1-t)*(1-exp(-(x2(mask)-t)/(1-t)))/(1-exp(-1));
Vt = min(max(x3,0),1);

% ---- hand local contrast ----
L  = 0.299*Vt(:,:,1)+0.587*Vt(:,:,2)+0.114*Vt(:,:,3);
Lb = gaussian_blur(L, 6);
detail = 0.28*(L - Lb);
Vt2 = min(max(Vt + repmat(detail,[1 1 3]),0),1);

% ---- metrics ----
clip0 = mean(V(:)>=0.999); clip1 = mean(Vt2(:)>=0.999);
hp = @(I) I - gaussian_blur(I,1);
L0 = 0.299*V(:,:,1)+0.587*V(:,:,2)+0.114*V(:,:,3);
L1 = 0.299*Vt2(:,:,1)+0.587*Vt2(:,:,2)+0.114*Vt2(:,:,3);
lc0 = std(hp(L0),0,'all'); lc1 = std(hp(L1),0,'all');
shadow = @(I) mean(I(I<0.2),'all');
fprintf('clipping: before=%.3f%% after=%.3f%%\n', clip0*100, clip1*100);
fprintf('local-contrast: before=%.5f after=%.5f (+%.0f%%)\n', lc0, lc1, (lc1/lc0-1)*100);
fprintf('shadow mean: before=%.3f after=%.3f\n', shadow(L0), shadow(L1));

imwrite(V,   fullfile(root,'out','tone_before.png'));
imwrite(Vt2, fullfile(root,'out','tone_after.png'));
imwrite(imresize(V,[NaN 700]),   fullfile(root,'out','tone_before_small.png'));
imwrite(imresize(Vt2,[NaN 700]), fullfile(root,'out','tone_after_small.png'));
m2 = imtile({imresize(V,[NaN 600]), imresize(Vt2,[NaN 600])},'GridSize',[1 2]);
imwrite(m2, fullfile(root,'out','tone_compare.png'));
skyR=1:300;  skyC=200:900;  trR=1000:1400; trC=500:1300;
z = imtile({V(skyR,skyC,:),Vt2(skyR,skyC,:),V(trR,trC,:),Vt2(trR,trC,:)},'GridSize',[1 4]);
imwrite(imresize(z,2,'nearest'), fullfile(root,'out','tone_zoom_sky_trees.png'));
disp('DONE');
