function lab = srgb2lab(srgb)
% sRGB (N x 3, values in [0,1], gamma-encoded) -> CIELAB (D65)
    c = min(max(srgb,0),1);
    lin = srgb2lin(c);
    M = [0.4124 0.3576 0.1805; 0.2126 0.7152 0.0722; 0.0193 0.1192 0.9505];
    xyz = (M*lin.').';
    ref = [0.95047 1.00000 1.08883];
    xyz = xyz ./ ref;
    d = 6/29;
    f = @(t) (t>d^3).*t.^(1/3) + (t<=d^3).*(t/(3*d^2)+4/29);
    fx=f(xyz(:,1)); fy=f(xyz(:,2)); fz=f(xyz(:,3));
    lab = [116*fy-16, 500*(fx-fy), 200*(fy-fz)];
end

function lin = srgb2lin(c)
    lin = zeros(size(c));
    lo = c<=0.04045; lin(lo)=c(lo)/12.92;
    hi = ~lo; lin(hi)=((c(hi)+0.055)/1.055).^2.4;
end
