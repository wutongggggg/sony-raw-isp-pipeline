% run_sony_match.m  --  approximate Sony in-camera colour science by fitting a colour/tone mapping
% Train on RAW->our-pipeline vs Sony JPEG(sRGB) pairs; test on a different scene; report deltaE before/after.
clear; clc;
root = 'D:\Desktop\isp';
rc = [1801 3000 1801 3600];   % 1200 x 1800 crop

[O1,S1,H1,W1] = getpair(root,'hdr.ARW','hdr.JPG',rc);
[O2,S2,~,~]   = getpair(root,'res.ARW','res.JPG',rc);
[O3,S3,~,~]   = getpair(root,'highiso.ARW','highiso.JPG',rc);

W = train_poly(O1,S1);                 % fit on hdr
O2m = apply_poly(O2,W);
d0 = dEof(O2,S2); d1 = dEof(O2m,S2);
fprintf('TRAIN hdr -> TEST res : dE(ours vs Sony)=%.2f  ->  dE(matched)=%.2f\n', d0,d1);

W2 = train_poly([O1;O2;O3],[S1;S2;S3]); % fit on all (in-sample)
fprintf('FIT all: dE hdr %.2f->%.2f | res %.2f->%.2f | highiso %.2f->%.2f\n', ...
    dEof(O1,S1),dEof(apply_poly(O1,W2),S1), ...
    dEof(O2,S2),dEof(apply_poly(O2,W2),S2), ...
    dEof(O3,S3),dEof(apply_poly(O3,W2),S3));

% montage for res: Sony | our | matched
H=H1; Wd=W1;
Simg=reshape(S2,H,Wd,3); Oimg=reshape(O2,H,Wd,3); Mimg=reshape(O2m,H,Wd,3);
cmp=imtile({Simg,Oimg,Mimg},'GridSize',[1 3]);
imwrite(imresize(cmp,[NaN 1200]), fullfile(root,'out','sony_match_res.png'));
disp('DONE');

function [O,S,H,W] = getpair(root,arw,jpg,rc)
    [raw,meta]=isp_read_raw(fullfile(root,'raw',arw));
    r0=rc(1);r1=rc(2);c0=rc(3);c1=rc(4);
    d=(double(raw(r0:r1,c0:c1))-meta.black)/(meta.white-meta.black); d=max(min(d,1),0);
    rgb=demosaic_bilinear(d);
    m=reshape(mean(mean(rgb,1),2),1,3); g=mean(m)./m; rgb=rgb.*reshape(g,1,1,3);
    v=sort(rgb(:)); pe=v(min(numel(v),round(0.995*numel(v)))); rgb=rgb*(0.9/max(pe,eps));
    V=min(max(rgb,0),1).^(1/2.2);
    bl=gaussian_blur(V,1.0); V=min(max(V+0.6*(V-bl),0),1);
    J=adobergb2srgb(double(imread(fullfile(root,'raw',jpg)))/255);
    S=J(r0:min(r1,size(J,1)), c0:min(c1,size(J,2)), :);
    O=imresize(V,[size(S,1) size(S,2)]);
    H=size(S,1); W=size(S,2);
    O=reshape(O,[],3); S=reshape(S,[],3);
end

function X=feat(I)
    R=I(:,1); G=I(:,2); B=I(:,3);
    X=[ones(size(R)), R,G,B, R.^2,G.^2,B.^2, R.*G,R.*B,G.*B];
end
function Wm=train_poly(O,S)
    n=size(O,1); step=max(1,round(n/150000)); idx=1:step:n;
    Wm=feat(O(idx,:))\S(idx,:);
end
function Om=apply_poly(O,Wm)
    Om=feat(O)*Wm; Om=min(max(Om,0),1);
end
function e=dEof(A,B)
    n=size(A,1); idx=randperm(n,min(5000,n));
    e=mean(ciede2000(srgb2lab(A(idx,:)),srgb2lab(B(idx,:))));
end
