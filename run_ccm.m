% run_ccm.m  --  ColorChecker -> 3x3 CCM (least squares) + CIEDE2000
% Geometry from checker.JPG (colorfulness projection); camera linear RGB sampled from checker.ARW.
clear; clc;
root = 'D:\Desktop\isp';

% ---------- 1) detect chart grid on the JPEG via colorfulness projection ----------
J  = imread(fullfile(root,'raw','checker.JPG'));
Hj = size(J,1); Wj = size(J,2);
R=double(J(:,:,1)); G=double(J(:,:,2)); B=double(J(:,:,3));
mx=max(max(R,G),B); mn=min(min(R,G),B); sat=(mx-mn)/255;
cmask = sat > 0.15;                          % colorful patches (rows 1..3)
cmask = imopen(cmask, strel('disk',2));
colp = mean(cmask,1); rowp = mean(cmask,2);
cx = find(colp > 0.08); cy = find(rowp > 0.08);
x0=min(cx); x1=max(cx); y0=min(cy); y1=max(cy);
pitchx=(x1-x0)/6; pitchy=(y1-y0)/3;          % vertical: rows1..3 span
fprintf('color bbox frac: x[%.3f %.3f] y[%.3f %.3f]\n', x0/Wj,x1/Wj,y0/Hj,y1/Hj);

cents=zeros(24,2);
for r=1:4, for c=1:6
    k=(r-1)*6+c;
    cents(k,:)=[x0+pitchx*(c-0.5), y0+pitchy*(r-0.5)];
end, end

figure('Visible','off'); imshow(J); hold on;
for k=1:24
    rectangle('Position',[cents(k,1)-0.30*pitchx, cents(k,2)-0.30*pitchy, 0.60*pitchx, 0.60*pitchy],'EdgeColor','r','LineWidth',2);
    text(cents(k,1),cents(k,2),num2str(k),'Color','y','FontSize',16,'HorizontalAlignment','center');
end
saveas(gcf, fullfile(root,'out','checker_detect.png')); close;

% ---------- 2) sample camera linear RGB from ARW (CFA-aware) ----------
[raw, meta] = isp_read_raw(fullfile(root,'raw','checker.ARW'));
Hr=size(raw,1); Wr=size(raw,2);
sx=Wr/Wj; sy=Hr/Hj; rawd=double(raw);
patchC=zeros(24,3);
for k=1:24
    cxr=cents(k,1)*sx; cyr=cents(k,2)*sy;
    dr=0.20*pitchy*sy; dc=0.20*pitchx*sx;
    r1=max(1,round(cyr-dr)); r2=min(Hr,round(cyr+dr));
    c1=max(1,round(cxr-dc)); c2=min(Wr,round(cxr+dc));
    A=rawd(r1:r2,c1:c2);
    [CC,RR]=meshgrid(c1:c2,r1:r2);
    Ro=mod(RR,2)==1; Co=mod(CC,2)==1;
    Rm=Ro&Co; Gm=(Ro&~Co)|(~Ro&Co); Bm=~Ro&~Co;
    patchC(k,1)=mean(A(Rm)); patchC(k,2)=mean(A(Gm)); patchC(k,3)=mean(A(Bm));
end
patchC=(patchC-meta.black)/(meta.white-meta.black);
patchC=max(patchC,1e-4);

% ---------- 3) targets ----------
Tb=readtable(fullfile(root,'docs','colorchecker_srgb.csv'));
srgbt=[Tb.R Tb.G Tb.B]/255;
linT=srgb2lin(srgbt);

% WB from neutral row (patches 19..24)
mN=mean(patchC(19:24,:),1); gains=mean(mN)./mN;
pC=patchC.*gains;

% ---------- 4) fit CCM ----------
M=(pinv(pC)*linT).';
est=(M*pC.').';
srgb_after=lin2srgb(min(max(est,0),1));
srgb_before=lin2srgb(min(max(pC,0),1));

% ---------- 5) deltaE ----------
lab_t=srgb2lab(srgbt);
dEb=ciede2000(lab_t, srgb2lab(srgb_before));
dEa=ciede2000(lab_t, srgb2lab(srgb_after));
disp('CCM M ='); disp(M);
fprintf('WB gains = [%.3f %.3f %.3f]\n', gains);
fprintf('DeltaE2000 BEFORE (WB only): mean=%.2f median=%.2f max=%.2f\n', mean(dEb),median(dEb),max(dEb));
fprintf('DeltaE2000 AFTER  (+CCM)  : mean=%.2f median=%.2f max=%.2f\n', mean(dEa),median(dEa),max(dEa));

% ---------- 6) swatch image: target | before | after ----------
sw=64; comp=zeros(4*sw, 3*6*sw, 3);
for k=1:24
    r=ceil(k/6); c=mod(k-1,6)+1; yy=(r-1)*sw+(1:sw);
    for g=0:2
        xx=(g*6 + c-1)*sw + (1:sw);
        if g==0, col=srgbt(k,:); elseif g==1, col=min(max(srgb_before(k,:),0),1); else, col=min(max(srgb_after(k,:),0),1); end
        for ch=1:3, comp(yy,xx,ch)=col(ch); end
    end
end
imwrite(imresize(comp,3,'nearest'), fullfile(root,'out','checker_swatches_target_before_after.png'));

save(fullfile(root,'ccm.mat'),'M','gains','dEa','dEb');
disp('DONE');

function lin=srgb2lin(c)
    lin=zeros(size(c)); lo=c<=0.04045; lin(lo)=c(lo)/12.92;
    hi=~lo; lin(hi)=((c(hi)+0.055)/1.055).^2.4;
end
function s=lin2srgb(lin)
    s=zeros(size(lin)); lo=lin<=0.0031308; s(lo)=12.92*lin(lo);
    hi=~lo; s(hi)=1.055*lin(hi).^(1/2.4)-0.055;
end
