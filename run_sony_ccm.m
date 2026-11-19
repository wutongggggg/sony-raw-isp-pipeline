% run_sony_ccm.m  --  use Sony's own WB + ColorMatrix (from ARW metadata) vs gray-world+identity
clear; clc;
root = 'D:\Desktop\isp';
rc = [1801 3000 1801 3600];
M2 = [3.2404542 -1.5371385 -0.4985314; -0.9692660 1.8760108 0.0415560; 0.0556434 -0.2040259 1.0572252];
files = {'hdr','res','highiso'};
fprintf('%-10s %-14s %-14s\n','scene','dE identity','dE Sony-CCM');
for k=1:3
    name=files{k};
    [raw,meta]=isp_read_raw(fullfile(root,'raw',[name '.ARW']));
    r0=rc(1);r1=rc(2);c0=rc(3);c1=rc(4);
    d=(double(raw(r0:r1,c0:c1))-meta.black)/(meta.white-meta.black); d=max(min(d,1),0);
    lin=demosaic_bilinear(d);
    % identity path
    Oi=finish(lin, grayworld(lin));
    % sony path
    S=readmatrix(fullfile(root,'docs',['sony_' name '.csv']));
    Mxyz=S(1:3,:); wb=S(4,:); CCM=M2*Mxyz;
    lin2=lin.*reshape(wb,1,1,3);
    lin3=reshape(reshape(lin2,[],3)*CCM.', size(lin,1), size(lin,2), 3);
    Os=finish(lin3, [1 1 1]);
    J=adobergb2srgb(double(imread(fullfile(root,'raw',[name '.JPG'])))/255);
    Jc=J(r0:min(r1,size(J,1)), c0:min(c1,size(J,2)), :);
    Oi=imresize(Oi,[size(Jc,1) size(Jc,2)]); Os=imresize(Os,[size(Jc,1) size(Jc,2)]);
    fprintf('%-10s %-14.2f %-14.2f\n', name, dEof(Jc,Oi), dEof(Jc,Os));
    if strcmp(name,'hdr')
        cmp=imtile({Jc,Oi,Os},'GridSize',[1 3]);
        imwrite(imresize(cmp,[NaN 1200]), fullfile(root,'out','sony_ccm_hdr.png'));
    end
end
disp('DONE');

function g=grayworld(lin)
    m=reshape(mean(mean(lin,1),2),1,3); g=mean(m)./m;
end
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
