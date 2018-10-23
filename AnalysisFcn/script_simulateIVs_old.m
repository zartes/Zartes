%%%old
%Intento de simular IVs. La superficie R(T,I) se define en RtesTI y los
%par�metros del circuito y ecuaciones en IVsolver. Tomo un vector
%de corrientes de polarizaci�n para los que resolver las ecuaciones y un set de
%temperaturas del ba�o, pero resulta muy lento. Hay que resolver la
%ecuaci�n temporal para cada punto de polarizaci�n y quedarse con el valor
%final. Para tener resoluci�n en la transici�n hay que tomar demasiados
%puntos.
Ispan=0:20e-6:1e-3;
Tb=[0.02 0.07 0.09 0.11 0.15];
for j=1:length(Tb),
for i=1:length(Ispan),
    [t,y]=ode15s(@(t,Y)IVsolver(t,Y,Ispan(i),Tb(j)),[0,0.5e-3,1e-3],[50e-3,0],[]);
    Ites(i)=y(end,2);
    Ttes(i)=y(end,1);
    Rtes(i)=RtesTI(Ttes(i),Ites(i));
    Vtes(i)=Rtes(i)*Ites(i);
end
plot(Vtes,Ites,'k')
end
