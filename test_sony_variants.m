% test_sony_variants.m  --  find the correct way to use Sony metadata / fit empirical CCM
clear; clc;
root='D:\Desktop\isp';
rc=[1801 3000 1801 3600];
M2=[3.2404542 -1.5371385 -0.4985314; -0.9692660 1.8760108 0.0415560; 0.0556434 -0.2040259 1.0572252];
name='hdr';
[raw,meta]=isp_read_raw(fullfile(root,'raw',[name '.ARW']));
r0=rc(1);r1=rc(2);c0=rc(3);c1=rc(4);
d=(double(raw(r0:r1,c0:c1))-meta.black)/(meta.white-meta.black); d=max(min(d,1),0);
lin=demosaic_bilinear(d); H=size(lin,1);W=size(lin,2);
S=readmatrix(fullfile(root,'docs',['sony_' name '.csv'])); Mxyz=S(1:3,:); wb=S(4,:);
J=adobergb2srgb(double(imread(fullfile(root,'raw',[name '.JPG'])))/255);
Jc=J(r0:min(r1,size(J,1)),c0:min(c1,size(J,2)),:);
Jc=imresize(Jc,[H W]);
sonyLin=reshape(srgb2lin(reshape(Jc,[],3)),H,W,3);

variants={};
variants{end+1}=struct('n','wb*M2*Mxyz','wb',wb,'M',M2*Mxyz);
variants{end+1}=struct('n','wb*M2*Mxyz''','wb',wb,'M',M2*Mxyz.'); %#ok
variants{end+1}=struct('n','1 *M2*Mxyz','wb',[1 1 1],'M',M2*Mxyz);
variants{end+1}=struct('n','wb*M2*inv(Mxyz)','wb',wb,'M',M2*inv(Mxyz));
variants{end+1}=struct('n','1 *M2*inv(Mxyz)','wb',[1 1 1],'M',M2*inv(Mxyz));
% empirical 3x3 fit from our camera linear -> sony linear
A=reshape(lin,[],3); B=reshape(sonyLin,[],3);
n=size(A,1); idx=1:max(1,round(n/200000)):n;
Memp=(pinv(A(idx,:))*B(idx,:)).';
variants{end+1}=struct('n','fit 3x3 -> Sony','wb',[1 1 1],'M',Memp);
for k=1:numel(variants)
    v=variants{k};
    lin2=lin.*reshape(v.wb,1,1,3);
    lin3=reshape(reshape(lin2,[],3)*v.M.',H,W,3);
    O=finish(lin3,[1 1 1]);
    fprintf('%-22s dE=%.2f\n', v.n, dEof(Jc,O));
end
disp('DONE');
function g=grayworld(lin), m=reshape(mean(mean(lin,1),2),1,3); g=mean(m)./m; end
function O=finish(lin,gains)
    lin=lin.*reshape(gains,1,1,3);
    v=sort(lin(:)); pe=v(min(numel(v),round(0.995*numel(v)))); lin=lin*(0.9/max(pe,eps));
    V=min(max(lin,0),1).^(1/2.2);
    bl=gaussian_blur(V,1.0); O=min(max(V+0.6*(V-bl),0),1);
end
function e=dEof(A,B)
    H=size(A,1);W=size(A,2);N=H*W;k=min(5000,N);idx=randperm(N,k);
    a=reshape(A,N,3);b=reshape(B,N,3);
    e=mean(ciede2000(srgb2lab(a(idx,:)),srgb2lab(b(idx,:))));
end
