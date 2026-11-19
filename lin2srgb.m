function s = lin2srgb(lin)
% linear -> sRGB gamma-encoded (elementwise)
    s = zeros(size(lin));
    lo = lin <= 0.0031308; s(lo) = 12.92*lin(lo);
    hi = ~lo; s(hi) = 1.055*lin(hi).^(1/2.4) - 0.055;
end
