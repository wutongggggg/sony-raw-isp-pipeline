function out = lsc_apply(img, lsc, cropRC, fullSize)
% Apply radial LSC gain to img (HxW or HxWx3).
%   lsc.p : [p1 p2 p3] radial model L = p1 + p2*rho2 + p3*rho2^2
%   cropRC: [r0 c0] top-left of crop in the full frame (1-based)
%   fullSize: [Hf Wf] full frame size
    [H, W, ~] = size(img);
    r0 = cropRC(1); c0 = cropRC(2); Hf = fullSize(1); Wf = fullSize(2);
    [Y, X] = ndgrid(r0:r0+H-1, c0:c0+W-1);
    cx = (Wf+1)/2; cy = (Hf+1)/2;
    rho2 = (((X-cx)/(Wf/2)).^2 + ((Y-cy)/(Hf/2)).^2) / 2;
    g = lsc.p(1) ./ (lsc.p(1) + lsc.p(2)*rho2 + lsc.p(3)*rho2.^2);
    g = max(min(g, 2.0), 0.5);
    if ndims(img)==3
        out = img .* g;
    else
        out = img .* g;
    end
end
