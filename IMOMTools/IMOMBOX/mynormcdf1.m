function p = mynormcdf1(x)
% Hart Algorithm for normcdf : Haug, p.465
% for m=1e+5, normcdf: 2.9s, mynormcdf1: 0.17s, mynormcdf2: 0.98s
% mynormcdf1 >> mynormcdf2 >>>> normcdf

a1 = 0.0352624965998911;
a2 = 0.700383064443688;
a3 = 6.37396220353165;
a4 = 33.912866078383;
a5 = 112.079291497871;
a6 = 221.213596169931;
a7 = 220.206867912376;

b1 = 0.0883883476483184;
b2 = 1.75566716318264;
b3 = 16.064177579207;
b4 = 86.7807322029461;
b5 = 296.564248779674;
b6 = 637.333633378831;
b7 = 793.826512519948;
b8 = 440.413735824752;

y = abs(x);
A = ((((((a1.*y+a2).*y +a3).*y +a4).*y +a5).*y + a6).*y +a7);
B = (((((((b1.*y+b2).*y+b3).*y+b4).*y+b5).*y+b6).*y+b7).*y+b8);
C = y + 1./(y+2./(y+3./(y+4./(y+0.65))));

%----------------------------------------------------------------------
% Below doesn't work if x = [0.1; -0.1];
% in this case, x<0 returns [0;1], which is inconclusive
% if x < 0
%     if y < 7.07106781186547
%         p = exp(-0.5.*y.^2).*A./B;
%     elseif y >= 7.07106781186547 && y <= 37
%         p = exp(-0.5.*y.^2)./(2.506628274631.*C);
%     elseif y > 37
%         p = 0;
%     end
% elseif x > 0
%     if y < 7.07106781186547
%         p = 1 - exp(-0.5.*y.^2).*A./B;
%     elseif y >= 7.07106781186547 && y <= 37
%         p = 1 - exp(-0.5.*y.^2)./(2.506628274631.*C);
%     elseif y > 37
%         p = 0;
%     end    
% end
%----------------------------------------------------------------------

%

p1 = exp(-0.5.*y.^2).*A./B;
p2 = exp(-0.5.*y.^2)./(2.506628274631.*C);
p3 = 1 - p1;
p4 = 1 - p2;

m = length(x);
p = zeros(m,1);
for i=1:m
    if x(i) <= 0    % here or next elseif should contain "="
        if y(i) < 7.07106781186547
            p(i) = p1(i);
        elseif y(i) >= 7.07106781186547 && y(i) <= 37
            p(i) = p2(i);
        elseif y(i) > 37
            p(i) = 0;
        end
    elseif x(i) > 0
        if y(i) < 7.07106781186547
            p(i) = p3(i);
        elseif y(i) >= 7.07106781186547 && y(i) <= 37
            p(i) = p4(i);
        elseif y(i) > 37
            p(i) = 1;
        end    
    end
end

p = reshape(p,size(x));
