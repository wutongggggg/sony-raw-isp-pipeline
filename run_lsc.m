% run_lsc.m  --  item (2) Lens Shading / flat-field correction from wall shots
% Reports (a) radial center->corner lens falloff, and (b) a 2D polynomial flat-field
% correction that also removes the natural-light illumination gradient.
clear; clc;
root = 'D:\Desktop\isp';

[LdG, pG, fG, qG, gG2, LcG] = fit_field(fullfile(root,'raw','gray.ARW'));
[~,  pW, fW, ~,  ~,  ~  ] = fit_field(fullfile(root,'raw','white.ARW'));
fprintf('GRAY  wall: radial lens falloff = %.1f %%   p=[%.3f %.3f %.3f]\n', fG, pG);
fprintf('WHITE wall: radial lens falloff = %.1f %%   p=[%.3f %.3f %.3f]\n', fW, pW);

% save calibration (radial p + 2D poly q) for later use
lsc = struct('p', pG, 'q', qG, 'fullSize', [5320 7968], 'falloff_pct', fG);
save(fullfile(root,'lsc.mat'),'lsc');

% montage: raw flat field | 2D gain map | corrected
v1=scale01(LdG); v2=scale01(gG2); v3=scale01(LcG);
m = imtile({repmat(v1,[1 1 3]), repmat(v2,[1 1 3]), repmat(v3,[1 1 3])}, 'GridSize',[1 3]);
imwrite(imresize(m,[NaN 900]), fullfile(root,'out','lsc_before_gain_after.png'));
disp('DONE');

function [Ld,p,falloff,q,gain,Lcorr] = fit_field(fn)
    [raw, meta] = isp_read_raw(fn);
    d = (double(raw)-meta.black)/(meta.white-meta.black); d=max(min(d,1),0);
    G1=d(1:2:end,2:2:end); G2=d(2:2:end,1:2:end);
    h=min(size(G1,1),size(G2,1)); w=min(size(G1,2),size(G2,2));
    L=0.5*(G1(1:h,1:w)+G2(1:h,1:w));
    Ld=imresize(L,[160 NaN]);
    [Hd,Wd]=size(Ld); [X,Y]=meshgrid(1:Wd,1:Hd);
    u=(X-(Wd+1)/2)/(Wd/2); v=(Y-(Hd+1)/2)/(Hd/2);
    % radial lens model
    rho2=(u.^2+v.^2)/2;
    A=[ones(numel(rho2),1), rho2(:), rho2(:).^2];
    p=A\Ld(:);
    falloff=(p(1)-(p(1)+p(2)+p(3)))/p(1)*100;
    % 2D polynomial flat-field (captures lens + illumination)
    B=[ones(numel(u),1), u(:), v(:), u(:).^2, u(:).*v(:), v(:).^2];
    q=B\Ld(:);
    model=reshape(B*q,size(Ld));
    gain=mean(model(:))./max(model,eps); gain=max(min(gain,3),0.33);
    Lcorr=Ld.*gain;
end

function v = scale01(x)
    xs=sort(x(:)); n=numel(xs);
    lo=xs(max(1,round(0.02*n))); hi=xs(min(n,round(0.98*n)));
    v=(x-lo)/max(hi-lo,eps); v=min(max(v,0),1);
end
