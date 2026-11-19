function out = adobergb2srgb(im)
% Convert an Adobe RGB (1998) gamma-encoded image (HxWx3, [0,1]) to sRGB gamma-encoded.
    H = size(im,1); W = size(im,2);
    lin = min(max(double(im),0),1).^2.19921875;         % Adobe RGB gamma ~2.2
    M1 = [0.5767309 0.1855540 0.1881852; ...
          0.2973769 0.6273491 0.0752741; ...
          0.0270343 0.0706872 0.9911085];               % AdobeRGB linear -> XYZ (D65)
    M2 = [ 3.2404542 -1.5371385 -0.4985314; ...
          -0.9692660  1.8760108  0.0415560; ...
           0.0556434 -0.2040259  1.0572252];            % XYZ -> sRGB linear
    v = reshape(lin, [], 3);
    xyz = (M1*v.').';
    sl  = (M2*xyz.').';
    sl  = min(max(sl,0),1);
    out = reshape(lin2srgb(sl), H, W, 3);
end
