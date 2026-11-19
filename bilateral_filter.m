function J = bilateral_filter(I, ss, sr, W)
% Hand-written bilateral filter for a single-channel image I in [0,1].
%   ss: spatial sigma, sr: range sigma, W: half window (window = 2W+1)
    I = double(I); [H, Wd] = size(I);
    P = padarray(I, [W W], 'replicate');
    [gx, gy] = meshgrid(-W:W, -W:W);
    gs = exp(-(gx.^2 + gy.^2) / (2*ss^2));
    J = zeros(H, Wd); Z = zeros(H, Wd);
    for dy = -W:W
        for dx = -W:W
            Is = P(W+1+dy : W+H+dy, W+1+dx : W+Wd+dx);
            gr = exp(-(Is - I).^2 / (2*sr^2));
            w  = gs(dy+W+1, dx+W+1) * gr;
            J = J + w .* Is; Z = Z + w;
        end
    end
    J = J ./ max(Z, eps);
end
