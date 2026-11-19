% run_fullres.m  --  item (7) full-resolution 42MP (tiled hand demosaic) + batch
clear; clc;
root = 'D:\Desktop\isp';
files = {'hdr.ARW','res.ARW','highiso.ARW'};
fprintf('%-14s %-8s %-14s %-8s %s\n','file','size','out','sec','note');
for k=1:numel(files)
    fn = fullfile(root,'raw',files{k});
    t0 = tic;
    [raw, meta] = isp_read_raw(fn);
    [H,W] = size(raw);
    % global WB / exposure from subsampled mosaic
    R = double(raw(1:8:end,1:8:end)); G1=double(raw(1:8:end,2:8:end)); G2=double(raw(2:8:end,1:8:end)); B=double(raw(2:8:end,2:8:end));
    R=R(:);G1=G1(:);G2=G2(:);B=B(:);
    mR=mean(R); mG=mean([G1;G2]); mB=mean(B);
    mn=[mR mG mB] - meta.black; mn=max(mn,eps); gains=mean(mn)./mn;
    gg = sort([G1;G2]);
    pe = (gg(min(numel(gg),round(0.995*numel(gg)))) - meta.black) / (meta.white-meta.black);
    scale = 1.0/max(pe,eps);
    % tiled pipeline, write uint8 output
    out8 = zeros(H,W,3,'uint8');
    band = 400; ov = 4; r = 1;
    while r <= H
        r0 = max(1, r-ov);
        if mod(r0,2)==0
            r0 = r0 - 1;
        end
        if r0 < 1
            r0 = 1;
        end
        r1 = min(H, r+band-1+ov);
        sub = raw(r0:r1, :);
        ds = (double(sub)-meta.black)/(meta.white-meta.black); ds=max(min(ds,1),0);
        rgb = demosaic_bilinear(ds);
        rgb = rgb .* reshape(gains,1,1,3) * scale;
        V = min(max(rgb,0),1).^(1/2.2);
        x1 = V.^0.92;
        x2 = 0.5 + (x1-0.5)*1.08;
        t = 0.80; msk = x2 > t; x3 = x2;
        x3(msk) = t + (1-t)*(1-exp(-(x2(msk)-t)/(1-t)))/(1-exp(-1));
        V = min(max(x3,0),1);
        L = 0.299*V(:,:,1)+0.587*V(:,:,2)+0.114*V(:,:,3);
        V = min(max(V + 0.05*(V-repmat(L,[1 1 3])),0),1);
        bl = gaussian_blur(V,1.0); V = min(max(V + 0.6*(V-bl),0),1);
        a = r; b = min(H, r+band-1); off = r - r0 + 1;
        out8(a:b,:,:) = uint8(round(V(off:off+(b-a),:,:)*255));
        r = b+1;
    end
    outname = fullfile(root,'out',['full_' files{k}(1:end-4) '.jpg']);
    imwrite(out8, outname, 'Quality', 92);
    fprintf('%-14s %dx%d  %-14s %6.1fs  %s\n', files{k}, H, W, ['full_' files{k}(1:end-4) '.jpg'], toc(t0), 'ok');
end
disp('DONE');
