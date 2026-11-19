p=fullfile('D:\Desktop\isp\raw','sample1.ARW');
d=rawread(p);
disp(['size ' mat2str(size(d)) ' class ' class(d)]);
disp(['global max=' num2str(max(d(:))) ' min=' num2str(min(d(:)))]);
R=double(d(1:2:end,1:2:end)); G1=double(d(1:2:end,2:2:end)); G2=double(d(2:2:end,1:2:end)); B=double(d(2:2:end,2:2:end));
names={'R','G1','G2','B'}; ch={R,G1,G2,B};
for k=1:4
  x=ch{k}(:); x=sort(x); n=numel(x);
  p01=x(max(1,round(0.001*n))); p1=x(max(1,round(0.01*n))); p50=x(round(0.5*n));
  p99=x(round(0.99*n)); p999=x(min(n,round(0.999*n)));
  disp(sprintf('%s min=%d p0.1=%d p1=%d p50=%d p99=%d p99.9=%d max=%d', names{k}, x(1), p01,p1,p50,p99,p999,x(end)));
end
prev=d(1:8:end,1:8:end); prev=double(prev); prev=(prev-min(prev(:)))/(max(prev(:))-min(prev(:))+eps)*255;
imwrite(uint8(prev), fullfile('D:\Desktop\isp\out','raw_preview_mosaic.png'));
disp('saved raw_preview_mosaic.png');
