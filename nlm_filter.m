function J = nlm_filter(I, h, sw, pw)
% Hand-written Non-Local Means for a single-channel image I in [0,1].
%   h : filtering strength, sw: search half-window, pw: patch half-window
    I = double(I); [H, Wd] = size(I);
    pad = sw + pw;
    P = padarray(I, [pad pad], 'replicate');
    J = zeros(H, Wd); Z = zeros(H, Wd);
    K = ones(2*pw+1, 2*pw+1) / ((2*pw+1)^2);   % patch mean -> mean squared diff
    for dy = -sw:sw
        for dx = -sw:sw
            Is = P(pad+1+dy : pad+H+dy, pad+1+dx : pad+Wd+dx);
            D  = (I - Is).^2;
            Df = conv2(D, K, 'same');          % local mean of squared differences
            w  = exp(-Df / (h^2));
            if dy==0 && dx==0, w = ones(H,Wd); end
            J = J + w .* Is; Z = Z + w;
        end
    end
    J = J ./ max(Z, eps);
end
