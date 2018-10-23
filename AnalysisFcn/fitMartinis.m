function Tc=fitMartinis(p,ds)%ds
%Creo una funci�n a partir de 'martinis.m' con la forma adecuada para usar
%lsqcurvefit. Permite ajustar datos experimentales para sacar los valores
%de d_oro, 't' y 'Tc0' que mejor ajustan.
bool=0;
p=real(p);
Tc=martinis(ds,p(1),p(2),p(3),bool,p(4)); %a�ado p(4)=RRRs,usado si bool=1.