function B = gaussian_blur(I, sigma)
% Hand-built separable Gaussian blur; supports 2D or 3D (HxWxC) input.
    r = max(1, ceil(3*sigma));
    x = -r:r;
    k = exp(-(x.^2)/(2*sigma^2)); k = k / sum(k);
    if ndims(I) == 3
        B = zeros(size(I));
        for c = 1:size(I,3)
            B(:,:,c) = conv2(conv2(double(I(:,:,c)), k, 'same'), k.', 'same');
        end
    else
        B = conv2(conv2(double(I), k, 'same'), k.', 'same');
    end
end
