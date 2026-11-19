function [out, st] = isp_pipeline(raw, P)
% Software ISP pipeline (learning / tuning oriented).
%   raw : uint16 Bayer mosaic (HxW)  OR  HxWx3 color image
%   P   : parameter struct (see run_isp.m for fields)
% Stages: black level -> demosaic -> AWB -> CCM -> auto-exposure -> gamma -> sharpen
% Returns final image `out` in [0,1] (double) and per-stage images in struct `st`.

    st = struct();
    d  = double(raw);

    if ndims(d) == 2
        % ---- black level + normalize ----
        d = (d - P.black) / (P.white - P.black);
        d = max(min(d, 1), 0);
        st.mosaic01 = d;
        % ---- demosaic (bilinear via IPT) ----
        rgb = demosaic_bilinear(d);               % hand-written bilinear (RGGB)
    else
        rgb = max(min(d, 1), 0);
    end
    st.demosaic = rgb;

    % ---- auto white balance ----
    switch lower(P.awb_mode)
        case 'grayworld'
            m = reshape(mean(mean(rgb,1),2), 1, 3);
            gains = mean(m) ./ max(m, eps);
        case 'white'
            gains = ones(1,3);
            for c = 1:3
                v = rgb(:,:,c); v = sort(v(:));
                p = v(min(numel(v), round(0.99*numel(v))));
                gains(c) = 1 / max(p, eps);
            end
            gains = gains / mean(gains);
        otherwise
            gains = [1 1 1];
    end
    rgb = rgb .* reshape(gains, 1, 1, 3);
    st.awb_gains = gains;
    st.awb = rgb;

    % ---- color correction matrix (CCM) ----
    H = size(rgb,1); W = size(rgb,2);
    v = reshape(rgb, H*W, 3) * P.ccm.';
    rgb = reshape(v, H, W, 3);
    rgb = max(min(rgb, 1.0), 0);
    st.ccm = rgb;

    % ---- auto exposure (scale so a high percentile maps to target level) ----
    if P.auto_exposure
        g = rgb(:,:,2); v = sort(g(:));
        pexp = v(min(numel(v), round(P.exp_prct*numel(v))));
        scale = P.target_level / max(pexp, eps) * P.exposure_gain;
        rgb = rgb * scale;
    end
    rgb = max(min(rgb, 1), 0);
    st.exposed = rgb;

    % ---- gamma encode ----
    rgb = rgb .^ (1 / P.gamma);
    st.gamma = rgb;

    % ---- optional unsharp sharpen ----
    if P.do_sharpen
        blur = imgaussfilt(rgb, 1.0);
        rgb = rgb + P.sharpen_amt * (rgb - blur);
        rgb = max(min(rgb, 1), 0);
    end
    st.sharpen = rgb;

    out = rgb;
end
