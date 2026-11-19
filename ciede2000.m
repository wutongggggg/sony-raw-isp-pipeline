function dE = ciede2000(lab1, lab2)
% CIEDE2000 color difference (Sharma et al.). Inputs lab1,lab2: N x 3 (L,a,b)
    L1=lab1(:,1); a1=lab1(:,2); b1=lab1(:,3);
    L2=lab2(:,1); a2=lab2(:,2); b2=lab2(:,3);
    C1=sqrt(a1.^2+b1.^2); C2=sqrt(a2.^2+b2.^2);
    Cb=(C1+C2)/2;
    G=0.5*(1-sqrt(Cb.^7./(Cb.^7+25^7)));
    a1p=(1+G).*a1; a2p=(1+G).*a2;
    C1p=sqrt(a1p.^2+b1.^2); C2p=sqrt(a2p.^2+b2.^2);
    h1p=mod(atan2d(b1,a1p),360); h2p=mod(atan2d(b2,a2p),360);
    dLp=L2-L1; dCp=C2p-C1p;
    dhp=zeros(size(h1p));
    for i=1:numel(h1p)
        if C1p(i)*C2p(i)==0, dhp(i)=0;
        elseif abs(h2p(i)-h1p(i))<=180, dhp(i)=h2p(i)-h1p(i);
        elseif h2p(i)-h1p(i)>180, dhp(i)=h2p(i)-h1p(i)-360;
        else, dhp(i)=h2p(i)-h1p(i)+360; end
    end
    dHp=2*sqrt(C1p.*C2p).*sind(dhp/2);
    Lbp=(L1+L2)/2; Cbp=(C1p+C2p)/2;
    hbp=zeros(size(h1p));
    for i=1:numel(h1p)
        if C1p(i)*C2p(i)==0, hbp(i)=h1p(i)+h2p(i);
        elseif abs(h1p(i)-h2p(i))<=180, hbp(i)=(h1p(i)+h2p(i))/2;
        elseif h1p(i)+h2p(i)<360, hbp(i)=(h1p(i)+h2p(i)+360)/2;
        else, hbp(i)=(h1p(i)+h2p(i)-360)/2; end
    end
    T=1-0.17*cosd(hbp-30)+0.24*cosd(2*hbp)+0.32*cosd(3*hbp+6)-0.20*cosd(4*hbp-63);
    dth=30*exp(-((hbp-275)/25).^2);
    Rc=2*sqrt(Cbp.^7./(Cbp.^7+25^7));
    SL=1+0.015*(Lbp-50).^2./sqrt(20+(Lbp-50).^2);
    SC=1+0.045*Cbp; SH=1+0.015*Cbp.*T;
    RT=-sind(2*dth).*Rc;
    dE=sqrt((dLp./SL).^2+(dCp./SC).^2+(dHp./SH).^2+RT.*(dCp./SC).*(dHp./SH));
end
