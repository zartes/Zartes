classdef NoiseThermalModelClass < handle
    
    properties
        Kb=1.38e-23;
        %%%Basic Properties
        fname='1TB';
        fNumberOfBlocks=1;
        fNumberOfLinks=1;
        fLinksList={'TES-B'}; %%%Definici�n del modelo de bloques a trav�s de la lista con el tipo de links
        %%%opciones: 'TES-B', 'TES-H', 'TES-I', 'I-B'. Todos los modelos se
        %%%construyen como combinaciones de ellos.
        fNumberOfComponents=3;%%Numero de componentes de ruido sin contar el circuitnoise.
        fOperatingPoint=[];
        fCircuit=[];
        fTES=[];
        fParameters=[];
        fZtesHandler=@(x)x;
        fsIHandler=@(x)x;
        fRshNoiseHandler=@(x)x;
        fJohnsonNoiseHandler=@(x)x;
        fPhononNoiseHandlerArray=[];
        fTotalCurrentNoiseModel=@(x)x;
        %%%boolean parameters
        boolUseExperimentalZtes=0;
        boolUseExperimentalCircuitNoise=0;
        boolAddMjohnson=1;
        boolAddMphononArray=[1 1 1];
        
        %%%Plotting Properties
        boolPlotComponents=0;
        PlotCurrentScale=1e12;%%%Para pintar en picoA/raizHz.
        PlotNEPScale=1e18;%%%Para pintar en aW/raizHz.
        
        %%%Calculation Properties
        maxResolutionFrequency=Inf;%%%(use 1e5 for experimental comparison, Inf for theoretical Limit.
    end
    
    methods
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %%%Constructor
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function obj=NoiseThermalModelClass(PARAMETERS,varargin)
            %%%alteramos el orden respecto a BuildThermalModel() function.
            %%%Obligamos a pasar OP, TES y circuit, que son necesarios, y
            %%%opcionalmente el nombre del modelo.
            
            if nargin==2
                obj.fname=varargin{1};
                obj.ParseModelName(varargin{1});%%%Funcion para actualizar el fLinksList
            end
            obj.fOperatingPoint=PARAMETERS.OP;%%%Si definimos OP como una clase habr� que cambiar esto.
            obj.fCircuit=PARAMETERS.circuit;
            obj.fTES=PARAMETERS.TES;
            s=numel(PARAMETERS.OP.parray);
            obj.fNumberOfBlocks=(s-1)/2;
            obj.fNumberOfLinks=numel(obj.fLinksList);
            obj.fNumberOfComponents=obj.fNumberOfLinks+2;           
            obj.BuildZtesfunction();
            obj.BuildsIfunction();
            obj.BuildRshNoisefunction();
            obj.BuildJohnsonNoisefunction();
            obj.BuildPhononNoiseComponents();
            obj.GetTotalCurrentNoise()
        end
        function list=ParseModelName(obj,modelname)
            switch modelname
                case {'default' 'irwin'}
                    list={'TES-B'};
                case '2TB_hanging'
                    list={'TES-B' 'TES-H'};
                case '2TB_intermediate'
                    list={'TES-I' 'I-B'};
                case '2TB_parallel'
                    list={'TES-B' 'TES-I' 'I-B'};
            end
            obj.fLinksList=list;
        end
        function fZtesHandler=BuildZtesfunction(obj)
%             if obj.fNumberOfBlocks==1
%                 fH=@(p,f)(p(1)+(p(2)-p(1)).*(1-1i*(2*pi*f)*p(3)).^-1);
%             elseif obj.fNumberOfBlocks==2
%                 fH=@(p,f)(p(1)+(p(2)-p(1)).*(1+p(4)).*(1-1i*(2*pi*f)*p(3)+p(4)./(1+1i*(2*pi*f)*p(5))).^-1);
%             elseif obj.fNumberOfBlocks>2%%%Generalizar para cualquier p size.
%                 warning('modelo no implementado')
%             end
%             p0=obj.fOperatingPoint.parray;
%             fZtesHandler=@(f)fH(p0,f);
%             obj.fZtesHandler=fZtesHandler;

                %%%%Version generalizable
                Num=@(p,f) 1;
                for i=1:obj.fNumberOfBlocks-1
                    Num=@(p,f) Num(p,f)+p(i+3);
                end
                Den=@(p,f) 1-1i*(2*pi*f)*p(3);
                for i=1:obj.fNumberOfBlocks-1
                    Den=@(p,f) Den(p,f)+p(i+3)./(1+1i*(2*pi*f)*p(i+4));
                end
                fH=@(p,f) p(1)+(p(2)-p(1)).*Num(p,f)./Den(p,f);
                p0=obj.fOperatingPoint.parray;
                fZtesHandler=@(f)fH(p0,f);
                obj.fZtesHandler=fZtesHandler;
        end
        function ZcircuitHandler=BuildZcircuitHandler(obj)
            RL=obj.fCircuit.Rsh+obj.fCircuit.Rpar;
            L=obj.fCircuit.L;
            if isfield(obj.fOperatingPoint,'ztes')&& obj.boolUseExperimentalZtes
                OP=obj.fOperatingPoint;
                ztes=@(f)interp1(OP.ztes.freqs,OP.ztes.data,f);
            else
                ztes=obj.BuildZtesfunction();
            end
            ZcircuitHandler=@(f)ztes(f)+RL+1i*2*pi*f*L;
        end
        function fsIHandler=BuildsIfunction(obj)
            zcirc=obj.BuildZcircuitHandler();
            ztes=obj.BuildZtesfunction();
            R0=obj.fOperatingPoint.R0;
            bI=obj.fOperatingPoint.bi;
            I0=obj.fOperatingPoint.I0;
            V0=I0*R0;
            fsIHandler=@(f)(ztes(f)-R0*(1+bI))./(zcirc(f)*V0*(2+bI));
            obj.fsIHandler=fsIHandler;
        end
        
        function fRshNoiseHandler=BuildRshNoisefunction(obj)
            Kb=obj.Kb;
            RL=obj.fCircuit.Rsh+obj.fCircuit.Rpar;
            zcirc=obj.BuildZcircuitHandler();
            Ts=obj.fOperatingPoint.Tbath;
            fRshNoiseHandler=@(f)4*Kb*Ts*RL./abs(zcirc(f)).^2;%%%johnson en la shunt
            obj.fRshNoiseHandler=fRshNoiseHandler;
        end
        function fJohnsonNoiseHandler=BuildJohnsonNoisefunction(obj)     
            Kb=obj.Kb;
            zcirc=obj.BuildZcircuitHandler();
            ztes=obj.BuildZtesfunction();
            T0=obj.fOperatingPoint.T0;
            R0=obj.fOperatingPoint.R0;
            bI=obj.fOperatingPoint.bi;
            fJohnsonNoiseHandler=@(f)(4*Kb*T0*R0*(1+2*bI)).*abs(ztes(f)+R0).^2./(R0^2*(2+bI).^2*abs(zcirc(f)).^2);%%%ruido johnson
            obj.fJohnsonNoiseHandler=fJohnsonNoiseHandler;
        end
        function fPhononNoiseHandlerArray=BuildPhononNoiseComponents(obj)
            Kb=obj.Kb;
            sI=obj.BuildsIfunction();
            for i=1:obj.fNumberOfLinks
                linkmodel=obj.fLinksList{i};
                LinkParameters=obj.ParseLinkParameters(linkmodel);
                P2=obj.BuildGeneralLinkPowerSpectrumNoise(LinkParameters);
                H=obj.GetModelDependent_H_Term(linkmodel,LinkParameters);
                fPhononNoiseHandlerArray{i}=@(f) P2(f).*abs(sI(f)).^2.*H(f);
            end
            obj.fPhononNoiseHandlerArray=fPhononNoiseHandlerArray;
        end
        
        function fTotalCurrentNoiseHandler=GetTotalCurrentNoise(obj)
            ssh=obj.BuildRshNoisefunction();
            stes=obj.BuildJohnsonNoisefunction();
            sjo=@(f,Mjo)ssh(f)+stes(f)*(1+Mjo^2);%%%Definimos el Mjo tambien como parametro para poder hacer fit.
            
            sphSum=@(f,Mph)0;%%%Initialization
            for i=1:obj.fNumberOfLinks
                sph=obj.fPhononNoiseHandlerArray{i};
                sphSum=@(f,Mph)sphSum(f,Mph)+sph(f)*(1+Mph(i)^2);%%% Mph es un array con los Mph. Ojo al orden.
            end
            stot=@(f,Mjo,Mph) sjo(f,Mjo)+sphSum(f,Mph);
            if isfield(obj.fCircuit,'circuitnoise') && obj.boolUseExperimentalCircuitNoise
                circuitnoise=@(f)interp1(obj.fCircuit.circuitnoise(:,1),obj.fCircuit.circuitnoise(:,2),f);
            else
                circuitnoise=@(f)obj.fCircuit.squid;
            end
            fTotalCurrentNoiseHandler=@(f,Mjo,Mph)sqrt(stot(f,Mjo,Mph)+circuitnoise(f).^2);
            obj.fTotalCurrentNoiseModel=fTotalCurrentNoiseHandler;
        end
        function fTotalNEPHandler=GetTotalNEPNoise(obj)
            ssh=obj.BuildRshNoisefunction();
            stes=obj.BuildJohnsonNoisefunction();
            sjo=@(f,Mjo)ssh(f)+stes(f)*(1+Mjo^2);%%%Definimos el Mjo tambien como parametro para poder hacer fit.
            
            sphSum=@(f,Mph)0;%%%Initialization
            for i=1:obj.fNumberOfLinks
                sph=obj.fPhononNoiseHandlerArray{i};
                sphSum=@(f,Mph)sphSum(f,Mph)+sph(f)*(1+Mph(i)^2);%%% Mph es un array con los Mph. Ojo al orden.
            end
            stot=@(f,Mjo,Mph) sjo(f,Mjo)+sphSum(f,Mph);
            sI=obj.fsIHandler;
            fTotalNEPHandler=@(f,Mjo,Mph)sqrt(stot(f,Mjo,Mph))./abs(sI(f));
        end
        
        function P2=BuildGeneralLinkPowerSpectrumNoise(obj,LinkParameters)
            %%%Todos los ruidos phonon parten de una expresi�n general para
            %%%el espectro de potencias del ruido t�rminco entre dos
            %%%bloques a temperatura T0 y T1. La expresi�n genreal es la
            %%%(18) del art�culo de Maasilta, que desarrollando, y
            %%%asumiendo que el mecanismo de conducci�n es el mismo en los
            %%%dos extremos del link t�rmico, se puede convertir en la
            %%%expresi�n phonon de 1TB. Pero seg�n se pasen unos valores u
            %%%otros de Ts, G y n, esta funci�n general se puede usar para
            %%%todos los modelos. Despu�s se combina con la |sI| y con una
            %%%parte dependiente de 'w' y del link concreto, que es la que
            %%%hay que particularizar seg�n el modelo. Esto va a ser v�lido
            %%%tambi�n para los dos modelos 3TB que considera Maasilta, el
            %%%2H y el IH.
            T0=LinkParameters.T0;
            T1=LinkParameters.T1;
            G0=LinkParameters.G0;
            n0=LinkParameters.n0;
            t=T1/T0;
            F=(1+t^(n0+1))/2;
            P2=@(f) 4*obj.Kb*T0^2*G0*F; %%%Notar que este t�rmino es constante en frecuencia, la dependencia en freq la dan los otros t�rminos.
            %%%Devolvemos un handle a funcion aunque sea constante para
            %%%usarla en combinaci�n con el resto de t�rminos.
        end
        function H=BuildGeneral_H_Term(obj,tau,a,b)
            %%%Este t�rmino es general para construir cualquier
            %%%contribuci�n phonon. El ruido en corriente phonon espec�fico
            %%%ser� sph=P2*|sI(w)|^2*H(w), donde el H(w) hay que
            %%%construirlo de manera espec�fica para cada modelo a partir
            %%%de esta funci�n, seg�n los valores de a y b.
            
            H=@(f) (a+b*(2*pi*f*tau).^2)./(1+(2*pi*f*tau).^2);
            %%%Por ejemplo, el H para 1TB es B_H_Term(tau,1,1). Devolvemos
            %%%de nuevo handle a funci�n de la frecuencia.
        end
        function H=GetModelDependent_H_Term(obj,model,varargin)
            %%%Esta funci�n puede devolver el t�rmino H espec�fico para
            %%%cada Link en funci�n del par de bloques a considerar. Pero
            %%%faltar� combinar seg�n el modelo los distintos t�rminos.
            
            %%%Hay que llamarla con opt.tau y opt.g2, aunque para TES-B no
            %%%hace falta.
            
            %%%Hasta 3TB (al menos los modelos considerados por Maasilta,
            %%%existen s�lo 4 tipos distintos de Link, que podemos definir
            %%% (usando D=(1+(w*tau)^2) como:
            %%%-- TES-Ba�o: H=1
            %%%-- TES-Hanging: H=(wtau)^2/D(w)
            %%%-- TES-Intermediate: H=(g2+(w*tau)^2)/D
            %%%--Intermediate-Ba�o: H=g2*1/D
            %%% donde g2 es un cociente adimensional de conductancias al
            %%% cuadrado dependiennte del modelo.
            
            %%%Recordar que llamamos H_Tetm(tau,a,b)
            switch model
                case 'TES-B'
                    H=obj.BuildGeneral_H_Term(0,1,1);
                    %H=@(f)1
                case 'TES-H'
                    tau=varargin{1}.tau;
                    H=obj.BuildGeneral_H_Term(tau,0,1);
                case 'TES-I'
                    tau=varargin{1}.tau;
                    g2=varargin{1}.g2;
                    H=obj.BuildGeneral_H_Term(tau,g2,1);
                case 'I-B'
                    tau=varargin{1}.tau;
                    g2=varargin{1}.g2;
                    H=obj.BuildGeneral_H_Term(tau,g2,0);
            end
        end
        function LinkParameters=ParseLinkParameters(obj,LinkModel)
            %%%%Funci�n para extraer los par�metros espec�ficos que
            %%%%permiten construir las componentes phonon a partir del tipo
            %%%%de link y del OP.
            
            OP=obj.fOperatingPoint;
            TES=obj.fTES;
            P0=OP.P0;
            Tbath=OP.Tbath;
            p=OP.parray;
            if isfield(TES,'Ttes')
                Ttes=TES.Ttes(P0,Tbath);
            end
            if isfield(TES,'Gtes')
                Gtes=TES.Gtes(Ttes);
            end
            
            %%%Falta verificar que estas asignaciones conducen a las
            %%%componentes correctas para cada uno de los modelos 2TB, pero
            %%%se ejecuta ya sin error y conduce a modelos razonables.
            switch LinkModel
                case 'TES-B'
                    %%%P2 parameters
                    T0=Ttes;
                    T1=OP.Tbath;
                    G0=Gtes;
                    n0=TES.n;
                    %%%H parameters
                    tau=OP.C/G0;%?
                    g2=0;
                case 'TES-H'
                    %%%P2 parameters
                    T0=Ttes;
                    T1=T0;
                    G0=OP.g_1;%?
                    n0=TES.n;%da igual
                    %%%H parameters
                    tau=p(5);%?
                    g2=0;
                case 'TES-I'
                    %%%P2 parameters
                    T0=Ttes;
                    T1=OP.P.T1;
                    G0=OP.P.g_t1_0;
                    n0=TES.n;
                    %%%H parameters
                    tau=p(5);
                    g2=(1-OP.P.a).^2;
                case 'I-B'
                    %%%P2 parameters
                    T0=OP.P.T1;
                    T1=Tbath;
                    G0=OP.P.g_1b;
                    n0=TES.n;%%%Aqui hacemos la hip�tesis de que m=n.
                    %%%H parameters
                    tau=p(5);
                    g2=OP.P.a.^2;
            end
        LinkParameters.T0=T0;
        LinkParameters.T1=T1;
        LinkParameters.G0=G0;
        LinkParameters.n0=n0;
        LinkParameters.tau=tau;
        LinkParameters.g2=g2;
        end
    
        %%%%%%%%%%%%%%%%%%%%%
        %%% Plotter Functions
        %%%%%%%%%%%%%%%%%%%%%        
        function PlotNoiseModel(obj,varargin)
            options=BuildNoiseOptions();
            if nargin>1
                options=varargin{1};
            end
            if obj.boolAddMjohnson && isfield(obj.fOperatingPoint.P,'M')
                Mjo=obj.fOperatingPoint.P.M;
            else
                Mjo=0;
            end
            for i=1:length(obj.boolAddMphononArray)
                if obj.boolAddMphononArray(i) && isfield(obj.fOperatingPoint.P,'Mph')
                Mph(i)=obj.fOperatingPoint.P.Mph(i);
                else
                Mph(i)=0;
                end
            end
            
            f=logspace(0,5,1000);
            if strcmpi(options.tipo,'current')
                func=obj.fTotalCurrentNoiseModel;
                scale=obj.PlotCurrentScale;
                legendstring={'Total Current Nosie'};
            elseif strcmpi(options.tipo,'nep')
                func=obj.GetTotalNEPNoise();
                scale=obj.PlotNEPScale;
                obj.boolPlotComponents=0;%%%De moomento no pintamos componentes para NEP.
                legendstring={'Total NEP'};
            end
            if obj.boolPlotComponents
                fh{1}=obj.BuildRshNoisefunction();                
                fh{2}=obj.BuildJohnsonNoisefunction();
                for i=1:obj.fNumberOfLinks
                    fh{2+i}=obj.fPhononNoiseHandlerArray{i};
                end
                for i=1:obj.fNumberOfComponents                    
                    loglog(f,scale*sqrt(fh{i}(f)),'-'),hold on;
                end
                legendstring=([{'R_{sh}' 'Johnson_{TES}'} obj.fLinksList {'Total Current Noise'}]);
            end
            loglog(f,scale*func(f,Mjo,Mph),'.-'),grid on;
            
            %%%Formatting.
            legend(legendstring);
            ylim([1 1e2])
            set(gca,'fontsize',12)
        end
        
        %%%%%%%%%%%%%%%%
        %%%Calculations
        %%%%%%%%%%%%%%%%
        function Res = GetModelResolution(obj)
            %%%C�lculo de la resoluci�n te�rica sin incluir Ms.
            fmax=obj.maxResolutionFrequency;
            nep=obj.GetTotalNEPNoise();
            integrand=@(f) 1./nep(f,0,[0 0]).^2;
            aux=integral(integrand,0,fmax);
            Res=2.35/sqrt(aux)/2/1.609e-19;
        end
    end
end