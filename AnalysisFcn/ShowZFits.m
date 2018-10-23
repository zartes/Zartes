function ShowZFits(ZTESDATA,Tbath)
%%%%Funci�n para ejecutar desde el directorio com�n de estructuras para
%%%%visualizar las Z(w) y ruidos.

bdir=pwd;

dir=ZTESDATA.datadir;
cd(dir);
ssn=ZTESDATA.sesion;
aux=load(ssn,'TFS');


%FitZfiles(ZTESDATA.IVset,ZTESDATA.circuit,ZTESDATA.TES,aux.TFS);

% str=dir('*mK');
% for i=1:length(str)
%     if strfind(str(i).name,Tbath) & str(i).isdir, break;end%%%Para pintar autom�ticamente los ruido a una cierta temperatura.50mK.(tiene que funcionar con 50mK y 50.0mK, pero ojo con 50.2mK p.e.)
% end

FitZset(ZTESDATA.IVset,ZTESDATA.circuit,ZTESDATA.TES,aux.TFS,Tbath);%%%%Hay que poner boolShow=1 dentro de la funcion.

cd(bdir);