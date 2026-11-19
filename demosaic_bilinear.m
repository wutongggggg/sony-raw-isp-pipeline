function rgb = demosaic_bilinear(M)
% Hand-written bilinear demosaic for RGGB Bayer mosaic M (HxW, values in [0,1]).
% Returns HxWx3. Uses interp2 on the regular sub-grids of each channel.
    [H, W] = size(M);
    [X, Y] = meshgrid(1:W, 1:H);

    % R sampled at (odd,odd)
    xr = 1:2:W; yr = 1:2:H;
    R = interp2(xr, yr, M(1:2:end,1:2:end), X, Y, 'linear');
    % B sampled at (even,even)
    xb = 2:2:W; yb = 2:2:H;
    B = interp2(xb, yb, M(2:2:end,2:2:end), X, Y, 'linear');
    % G sampled on checkerboard: (odd,even) and (even,odd)
    G1 = interp2(2:2:W, 1:2:H, M(1:2:end,2:2:end), X, Y, 'linear');  % from (odd,even)
    G2 = interp2(1:2:W, 2:2:H, M(2:2:end,1:2:end), X, Y, 'linear');  % from (even,odd)
    G  = 0.5*(G1 + G2);
    maskG = false(H,W); maskG(1:2:end,2:2:end) = true; maskG(2:2:end,1:2:end) = true;
    G(maskG) = M(maskG);

    % fill any NaN at borders with nearest
    Rn = interp2(xr,yr,M(1:2:end,1:2:end),X,Y,'nearest'); R(isnan(R))=Rn(isnan(R));
    Bn = interp2(xb,yb,M(2:2:end,2:2:end),X,Y,'nearest'); B(isnan(B))=Bn(isnan(B));
    Gn = 0.5*(interp2(2:2:W,1:2:H,M(1:2:end,2:2:end),X,Y,'nearest') + ...
              interp2(1:2:W,2:2:H,M(2:2:end,1:2:end),X,Y,'nearest'));
    G(isnan(G))=Gn(isnan(G));

    rgb = cat(3, R, G, B);
    rgb = min(max(rgb,0),1);
end
