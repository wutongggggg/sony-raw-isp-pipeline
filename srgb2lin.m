function lin = srgb2lin(c)
% sRGB gamma-encoded -> linear (elementwise, works on arrays/Nx3)
    lin = zeros(size(c));
    lo = c <= 0.04045; lin(lo) = c(lo)/12.92;
    hi = ~lo; lin(hi) = ((c(hi)+0.055)/1.055).^2.4;
end
