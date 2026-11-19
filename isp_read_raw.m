function [raw, meta] = isp_read_raw(fn)
% Read a camera RAW (.arw/.dng/...) into a uint16 mosaic + metadata.
% Uses Image Processing Toolbox rawread/rawinfo (LibRaw under the hood).
    raw  = rawread(fn);                 % uint16 mosaic (H x W), Bayer
    info = rawinfo(fn);
    meta = struct();
    meta.filename    = fn;
    meta.size        = size(raw);
    meta.cfa         = char(info.CFALayout);        % e.g. 'RGGB'
    meta.sensor_type = char(info.CFASensorType);    % 'Bayer'
    % Sony 14-bit defaults; override via pipeline params if needed
    meta.black = 512;
    meta.white = 16383;
end
