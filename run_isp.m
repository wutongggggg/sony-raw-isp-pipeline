% run_isp.m  --  run the software ISP pipeline on a Sony ARW crop
% Reads a real .ARW (RGGB), crops a region for speed, runs the pipeline,
% saves stage images + a comparison montage + prints simple metrics.
clear; clc;

root = 'D:\Desktop\isp';
fn   = fullfile(root,'raw','sample1.ARW');

[raw, meta] = isp_read_raw(fn);

% ---- crop a region for speed; odd start keeps the RGGB phase ----
r0=2001; r1=4000; c0=2001; c1=5000;
raw = raw(r0:r1, c0:c1);

% ---- pipeline parameters (tune here) ----
P = struct( ...
    'cfa',           lower(meta.cfa), ...     % 'rggb'
    'black',         meta.black, ...           % 512
    'white',         meta.white, ...           % 16383
    'awb_mode',      'grayworld', ...          % 'grayworld' | 'white' | 'none'
    'ccm',           eye(3), ...               % color correction matrix (identity by default)
    'auto_exposure', true, ...
    'exp_prct',      0.995, ...
    'target_level',  0.90, ...
    'exposure_gain', 1.00, ...
    'gamma',         2.2, ...
    'do_sharpen',    true, ...
    'sharpen_amt',   0.60);

fprintf('RAW : %s\n', meta.filename);
fprintf('CFA = %s | full size = %dx%d | crop = %dx%d\n', meta.cfa, meta.size(1),meta.size(2), size(raw,1),size(raw,2));
fprintf('black=%d  white=%d\n', P.black, P.white);

[out, st] = isp_pipeline(raw, P);

% ---- save images ----
imwrite(out, fullfile(root,'out','final.png'));
imwrite(imresize(st.demosaic,[NaN 900]), fullfile(root,'out','stage1_demosaic.png'));
imwrite(imresize(st.awb,     [NaN 900]), fullfile(root,'out','stage2_awb.png'));
imwrite(imresize(st.gamma,   [NaN 900]), fullfile(root,'out','stage3_gamma.png'));
imwrite(imresize(out,        [NaN 900]), fullfile(root,'out','final_small.png'));
cmp = imtile({imresize(st.demosaic,[NaN 600]), imresize(st.gamma,[NaN 600]), imresize(out,[NaN 600])}, 'GridSize',[1 3]);
imwrite(cmp, fullfile(root,'out','compare.png'));

% ---- simple metrics ----
fprintf('AWB gains            = [%.3f %.3f %.3f]\n', st.awb_gains);
m = reshape(mean(mean(out,1),2),1,3);
fprintf('final channel means  = [%.3f %.3f %.3f]\n', m);
gy = mean(abs(diff(rgb2gray(out),1,1)),'all');
fprintf('sharpness mean|grad| = %.5f\n', gy);
clip = mean(out(:) >= 0.999);
fprintf('clipping             = %.3f %%\n', clip*100);
disp('DONE');
