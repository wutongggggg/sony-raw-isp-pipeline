clear;clc;
root='D:\Desktop\isp';
for k=1:2
 if k==1, fn=fullfile(root,'raw','gray.ARW'); nm='GRAY'; else fn=fullfile(root,'raw','white.ARW'); nm='WHITE'; end
 [raw,meta]=isp_read_raw(fn);
 d=(double(raw)-meta.black)/(meta.white-meta.black); d=max(min(d,1),0);
 G1=d(1:2:end,2:2:end); G2=d(2:2:end,1:2:end);
 h=min(size(G1,1),size(G2,1)); w=min(size(G1,2),size(G2,2));
 L=0.5*(G1(1:h,1:w)+G2(1:h,1:w));
 Ld=imresize(L,[160 NaN]); [Hd,Wd]=size(Ld);
 [X,Y]=meshgrid(1:Wd,1:Hd); u=(X-(Wd+1)/2)/(Wd/2); v=(Y-(Hd+1)/2)/(Hd/2);
 rho2=(u.^2+v.^2)/2; y=Ld(:); n=numel(y);
 A1=[ones(n,1) rho2(:) rho2(:).^2];
 A2=[A1 u(:) v(:)];
 A3=[ones(n,1) u(:) v(:) u(:).^2 u(:).*v(:) v(:).^2];
 mods={A1,A2,A3}; names={'radial','radial+directional','2D poly'};
 fprintf('--- %s field ---\n',nm);
 varY=var(y);
 for m=1:3
  q=mods{m}\y; res=y-mods{m}*q; r2=1-var(res)/varY; rms=sqrt(mean(res.^2));
  fprintf('%-20s R2=%.4f  RMS=%.5f\n',names{m},r2,rms);
 end
 q1=A1\y; fall=(q1(1)-(q1(1)+q1(2)+q1(3)))/q1(1)*100;
 q2=A2\y; dir_amp=(max(q2(4)*u(:)+q2(5)*v(:))-min(q2(4)*u(:)+q2(5)*v(:)))/q2(1)*100;
 fprintf('radial falloff=%.1f%%  directional peak-to-peak=%.1f%% of mean\n',fall,dir_amp);
end
