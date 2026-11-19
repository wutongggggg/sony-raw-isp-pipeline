% run_synth_ccm.m  --  synthetic virtual-camera ColorChecker: CCM fit + CIEDE2000 (valid, known truth)
% Validates the hand-written WB + least-squares CCM + deltaE2000 chain without needing a printed chart.
clear; clc;
root = 'D:\Desktop\isp';

% ---- known targets ----
Tb = readtable(fullfile(root,'docs','colorchecker_srgb.csv'));
srgbT = [Tb.R Tb.G Tb.B]/255;
linT  = srgb2lin(srgbT);

% ---- simulate a plausible camera: cam_linear = A * srgb_linear (channel gains + noise) ----
A = [0.62 0.30 0.08; 0.20 0.72 0.08; 0.06 0.24 0.70];   % rows ~ sum to 1, plausible sensor response
rng(7);
cam = (A*linT.').' .* [1.05 1.00 0.95];
cam = cam + 0.004*randn(size(cam));                       % small sensor noise

% ---- our algorithm: WB from neutral row (19..24) then least-squares CCM ----
mN = mean(cam(19:24,:),1); gains = mean(mN)./mN; pC = cam.*gains;
M  = (pinv(pC)*linT).';
est = (M*pC.').';

srgbBefore = lin2srgb(min(max(pC,0),1));
srgbAfter  = lin2srgb(min(max(est,0),1));

labT = srgb2lab(srgbT);
dEb  = ciede2000(labT, srgb2lab(srgbBefore));
dEa  = ciede2000(labT, srgb2lab(srgbAfter));

disp('Recovered CCM M ='); disp(M);
fprintf('WB gains = [%.3f %.3f %.3f]\n', gains);
fprintf('SYNTH DeltaE2000 BEFORE(WB): mean=%.2f median=%.2f max=%.2f\n', mean(dEb),median(dEb),max(dEb));
fprintf('SYNTH DeltaE2000 AFTER(+CCM): mean=%.2f median=%.2f max=%.2f\n', mean(dEa),median(dEa),max(dEa));

% ---- swatch: target | before | after ----
sw=64; comp=zeros(4*sw, 3*6*sw, 3);
for k=1:24
    r=ceil(k/6); c=mod(k-1,6)+1; yy=(r-1)*sw+(1:sw);
    for g=0:2
        xx=(g*6 + c-1)*sw + (1:sw);
        if g==0, col=srgbT(k,:); elseif g==1, col=min(max(srgbBefore(k,:),0),1); else, col=min(max(srgbAfter(k,:),0),1); end
        for ch=1:3, comp(yy,xx,ch)=col(ch); end
    end
end
imwrite(imresize(comp,3,'nearest'), fullfile(root,'out','synth_swatches_target_before_after.png'));

% ---- hand-written demosaic self-test (mosaic a small color image, demosaic, PSNR) ----
im = imresize(double(imread(fullfile(root,'raw','hdr.JPG')))/255, [256 384]);
Mo = zeros(256,384);
Mo(1:2:end,1:2:end) = im(1:2:end,1:2:end,1);
Mo(1:2:end,2:2:end) = im(1:2:end,2:2:end,2);
Mo(2:2:end,1:2:end) = im(2:2:end,1:2:end,2);
Mo(2:2:end,2:2:end) = im(2:2:end,2:2:end,3);
dm = demosaic_bilinear(Mo);
psnr = 10*log10(1/mean((dm(:)-im(:)).^2));
fprintf('HAND demosaic self-test PSNR = %.2f dB\n', psnr);

save(fullfile(root,'ccm_synth.mat'),'M','gains','dEa','dEb');
disp('DONE');
