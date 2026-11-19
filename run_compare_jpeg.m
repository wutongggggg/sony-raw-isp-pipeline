% run_compare_jpeg.m  --  item (6) our RAW pipeline vs camera JPEG (AdobeRGB -> sRGB)
clear; clc;
root = 'D:\Desktop\isp';
[raw, meta] = isp_read_raw(fullfile(root,'raw','hdr.ARW'));
r0=1801; r1=3300; c0=1801; c1=4200;
d = (double(raw(r0:r1,c0:c1))-meta.black)/(meta.white-meta.black); d=max(min(d,1),0);
rgb = demosaic_bilinear(d);
m = reshape(mean(mean(rgb,1),2),1,3); gains=mean(m)./m; rgb=rgb.*reshape(gains,1,1,3);
v = sort(rgb(:)); pe=v(min(numel(v),round(0.995*numel(v)))); rgb = rgb*(0.9/max(pe,eps));
V = min(max(rgb,0),1).^(1/2.2);
blur = gaussian_blur(V,1.0); ours = min(max(V + 0.6*(V-blur),0),1);

% camera JPEG is AdobeRGB -> sRGB
J = adobergb2srgb(double(imread(fullfile(root,'raw','hdr.JPG')))/255);
Jc = J(r0:min(r1,size(J,1)), c0:min(c1,size(J,2)), :);
ours = imresize(ours, [size(Jc,1) size(Jc,2)]);
% global luminance match for a fair color-shape comparison
g = mean(Jc(:))/max(mean(ours(:)),eps); oursG = min(max(ours*g,0),1);

dEraw = dEfn(Jc, ours);
dEg   = dEfn(Jc, oursG);
praw  = psnrfn(Jc, ours);
pg    = psnrfn(Jc, oursG);
fprintf('vs camera JPEG (sRGB-converted): dEraw=%.2f  dE(gain-matched)=%.2f  PSNR raw=%.2f dB  PSNR matched=%.2f dB\n', dEraw,dEg,praw,pg);

diff = mean(abs(Jc-oursG),3); diff=diff/max(diff(:));
cmp = imtile({Jc, oursG, repmat(diff,[1 1 3])}, 'GridSize',[1 3]);
imwrite(imresize(cmp,[NaN 1200]), fullfile(root,'out','compare_camera_vs_ours.png'));
zr=350:650; zc=400:800;
z = imtile({Jc(zr,zc,:), oursG(zr,zc,:)},'GridSize',[1 2]);
imwrite(imresize(z,2,'nearest'), fullfile(root,'out','compare_camera_vs_ours_zoom.png'));
disp('DONE');

function e=dEfn(A,B)
    H=size(A,1);W=size(A,2);N=H*W;k=min(5000,N);idx=randperm(N,k);
    a=reshape(A,N,3);b=reshape(B,N,3);
    e=mean(ciede2000(srgb2lab(a(idx,:)),srgb2lab(b(idx,:))));
end
function p=psnrfn(A,B)
    p=10*log10(1/max(mean((A(:)-B(:)).^2),eps));
end
