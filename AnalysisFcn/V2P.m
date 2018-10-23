function NEP=V2P(noise,Rf,simnoise)
%%%Funci�n para convertir el ruido en voltaje a la salida a ruido en
%%%potencia a la entrada (NEP). Necesita la sI del punto de operaci�n en
%%%cuesti�n

 sIaux=ppval(spline(simnoise.f,simnoise.sI),noise(:,1));
 NEP=sqrt((V2I(noise(:,2),Rf).^2-simnoise.squid.^2))./sIaux;