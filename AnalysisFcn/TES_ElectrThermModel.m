classdef TES_ElectrThermModel
    % Class TF for TES data
    %   This class contains options for Z(W) analysis
    
    properties              
        Zw_Models = {'1TB';'2TB (Hanging)';'2TB (Intermediate)'} % One Single Thermal Block, Two Thermal Blocks
        Selected_Zw_Models = 1;
        Options = {'No restriction';'Fixing C'};
        Selected_Options = 1;
        StrModelPar = {[]};
        bool_Show = 1;      
        TF_BaseName = {'HP';'PXI'};% 0,1
        Selected_TF_BaseName = 1;
        Zw_R2Thrs = 0.9;
        Zw_LowFreq = 0;
        Zw_HighFreq = 100000;
        Zw_rpLB = 0;
        Zw_rpUB = 1;        
        Z0_Zinf_Thrs = 1.5e-3;
        
        tipo = {'current';'nep'};               % current, nep
        Selected_tipo = 1;
        bool_components = 0;             % 0,1
        bool_Mjo = 0;                        % Jonson noise 0,1
        bool_Mph = 0;                        % Phonon noise 0,1        
        Noise_BaseName = {'HP';'PXI'};   % \HP_noise*, \PXI_noise*
        Selected_NoiseBaseName = 1;
        Noise_Models = {'irwin';'2TB (Hanging)';'2TB (Intermediate)';'wouter'};           % irwin, wouter
        Selected_Noise_Models = 1;
        Noise_LowFreq = 1e2;
        Noise_HighFreq = 10e4;
        DataMedFilt = 40;
        Kb = 1.38e-23;
    end
    properties (Access = private)
        version = 'ZarTES v2.1';
    end
    
    methods
        
        function obj = Constructor(obj)
            switch obj.Zw_Models{obj.Selected_Zw_Models}
                case obj.Zw_Models{1}
                    obj.StrModelPar = {'Zinf';'Z0';'taueff'};          % 3 parameters
                case obj.Zw_Models{2}
                    obj.StrModelPar = {'Zinf';'Z0';'taueff';'ca0';'tauA'};
                case obj.Zw_Models{3}
                    obj.StrModelPar = {'Zinf';'Z0';'taueff';'ca0';'tauA'};
                case obj.Zw_Models{4}
                    obj.StrModelPar = {'Zinf';'Z0';'taueff';'tau1';'tau2';'d1';'d2'};                    
            end
        end
        
        function obj = View(obj)
            % Function to check visually the class values
            
            h = figure('Visible','off','Tag','TES_ElectrThermModel');
            waitfor(Conf_Setup(h,[],obj));
            TF_Opt = guidata(h);
            if ~isempty(TF_Opt)
                obj = obj.Update(TF_Opt);
            end
        end
        
        function obj = Update(obj,data)
            % Function to update the class values
            
            FN = properties(obj);
            if nargin == 2
                fieldNames = fieldnames(data);
                for i = 1:length(fieldNames)
                    if ~isempty(cell2mat(strfind(FN,fieldNames{i})))
                        eval(['obj.' fieldNames{i} ' = data.' fieldNames{i} ';']);
                    end
                end
            end
        end
        
        function [param, ztes, fZ, fS, ERP, R2, CI, aux1, p0] = FitZ(obj,TES,FileName,FreqRange)
            indSep = find(FileName == filesep);
            Path = FileName(1:indSep(end));
            Name = FileName(find(FileName == filesep, 1, 'last' )+1:length(FileName));
            Tbath = sscanf(FileName(indSep(end-1)+1:indSep(end)),'%dmK');
            Ib = str2double(Name(find(Name == '_', 1, 'last')+1:strfind(Name,'uA.txt')-1))*1e-6;
            % Buscamos si es Ibias positivos o negativos
            if ~isempty(strfind(Path,'Negative')) %#ok<STREMP>
                [~,Tind] = min(abs([TES.IVsetN.Tbath]*1e3-Tbath));
                IV = TES.IVsetN(Tind);
                CondStr = 'N';
            else
                [~,Tind] = min(abs([TES.IVsetP.Tbath]*1e3-Tbath));
                IV = TES.IVsetP(Tind);
                CondStr = 'P';
            end
            % Primero valoramos que este en la lista
            filesZ = ListInBiasOrder([Path TES.TFOpt.TFBaseName])';
            SearchFiles = strfind(filesZ,Name);
            for i = 1:length(filesZ)
                if ~isempty(SearchFiles{i})
                    IndFile = i;
                    break;
                end
            end
            try
                eval(['[~,Tind] = find(abs([TES.P' CondStr '.Tbath]*1e3-Tbath)==0);']);
                eval(['ztes = TES.P' CondStr '(Tind).ztes{IndFile};'])
                eval(['fS = TES.P' CondStr '(Tind).fS{IndFile};'])
                if isempty(ztes)
                    error;
                end
            catch
                data = importdata(FileName);
                IndDist = find(data(:,2) ~= 0);
                data = data(IndDist,:);                
                tf = data(:,2)+1i*data(:,3);
                Rth = TES.circuit.Rsh+eval(['TES.TESParam' CondStr '.Rpar'])+2*pi*TES.circuit.L*data(:,1)*1i;                
                fS = TES.TFS.f(IndDist);                                
                ztes = (TES.TFS.tf(IndDist)./tf-1).*Rth;                
                ztes = ztes(fS >= FreqRange(1) & fS <= FreqRange(2));
                fS = fS(fS >= FreqRange(1) & fS <= FreqRange(2));                
            end
            Zinf = real(ztes(end));
            Z0 = real(ztes(1));
            [~,indfS] = min(imag(ztes));
            tau0 = 1/(2*pi*fS(indfS));
            opts = optimset('Display','off','Algorithm','levenberg-marquardt');
            switch obj.Zw_Models{obj.Selected_Zw_Models}
                case obj.Zw_Models{1}
                    p0 = [Zinf Z0 tau0];          % 3 parameters
                case obj.Zw_Models{2}
                    ca0 = 1e-1;
                    tauA = 1e-6;
                    p0 = [Zinf Z0 tau0 ca0 tauA];%%%p0 for 2 block model.  % 5 parameters
                case obj.Zw_Models{3}
                    ca0 = 1e-1;
                    tauA = 1e-6;
                    p0 = [Zinf Z0 tau0 ca0 tauA];%%%p0 for 2 block model.  % 5 parameters
                case obj.Zw_Models{4}
                    tau1 = 1e-5;
                    tau2 = 1e-5;
                    d1 = 0.8;
                    d2 = 0.1;
                    p0 = [Zinf Z0 tau0 tau1 tau2 d1 d2];%%%p0 for 3 block model.   % 7 parameters                                        
            end
            [p,aux1,aux2,aux3,out,lambda,jacob] = lsqcurvefit(@obj.fitZ,p0,fS,...
                [real(ztes) imag(ztes)],[],[],opts);%#ok<ASGLU> %%%uncomment for real parameters.
            MSE = (aux2'*aux2)/(length(fS)-length(p)); %#ok<NASGU>
            ci = nlparci(p,aux2,'jacobian',jacob);
            CI = (ci(:,2)-ci(:,1))';  
            p_CI = [p; CI];
            param = obj.GetModelParameters(TES,p_CI,IV,Ib,CondStr);
            fZ = obj.fitZ(p,fS);
            ERP = sum(abs(abs(ztes-fZ(:,1)+1i*fZ(:,2))./abs(ztes)))/length(ztes);
            R2 = goodnessOfFit(fZ(:,1)+1i*fZ(:,2),ztes,'NRMSE');
            
        end
        
        function fz = fitZ(obj,p,f)
            % Function to fit Z(w) according to the selected
            % electro-thermal model
            
            w = 2*pi*f;
            D = (1+(w.^2)*(p(3).^2));
            switch obj.Zw_Models{obj.Selected_Zw_Models}
                case obj.Zw_Models{1}
                    rfz = p(1)-(p(1)-p(2))./D;%%%modelo de 1 bloque.
                    imz = -(p(1)-p(2))*w*p(3)./D;%%% modelo de 1 bloque.
                    imz = -abs(imz);
                case obj.Zw_Models{2}
                    fz = p(1)+(p(1)-p(2)).*(-1+1i*w*p(3).*(1-p(4)*1i*w*p(5)./(1+1i*w*p(5)))).^-1;%%%SRON
                    rfz = real(fz);
                    imz = -abs(imag(fz));
                case obj.Zw_Models{3}
                    fz = p(1)+(p(1)-p(2)).*(-1+1i*w*p(3).*(1-p(4)*1i*w*p(5)./(1+1i*w*p(5)))).^-1;%%%SRON
                    rfz = real(fz);
                    imz = -abs(imag(fz));
                case obj.Zw_Models{4}
                    %p=[Zinf Z0 tau_I tau_1 tau_2 d1 d2]. Maasilta IH.
                    fz = p(1)+(p(2)-p(1)).*(1-p(6)-p(7)).*(1+1i*w*p(3)-p(6)./(1+1i*w*p(4))-p(7)./(1+1i*w*p(5))).^-1;
                    rfz = real(fz);
                    imz = -abs(imag(fz));
            end
            fz = [rfz imz];
        end
        
        function param = GetModelParameters(obj,TES,p,IVmeasure,Ib,CondStr)
            Rn = eval(['TES.TESParam' CondStr '.Rn;']);
            
%             
            
            IVmeasure.vout = IVmeasure.vout+1000;  % Sumo 1000 para que toda la curva IV
            %sea positiva siempre, que no haya cambios de signo para que los splines no devuelvan valores extra�os
            % Luego se restan los 1000.
            [iaux,ii] = unique(IVmeasure.ibias,'stable');
            vaux = IVmeasure.vout(ii);
            [m,i3] = min(diff(vaux)./diff(iaux)); %#ok<ASGLU>
            
            Vout = ppval(spline(iaux(1:i3),vaux(1:i3)),Ib);
            IVaux.ibias = Ib;
            IVaux.vout = Vout-1000;
            IVaux.Tbath = IVmeasure.Tbath;
            
            F = TES.circuit.invMin/(TES.circuit.invMf*TES.circuit.Rf);%36.51e-6;
            I0 = IVaux.vout*F;
            Vs = (IVaux.ibias-I0)*TES.circuit.Rsh;%(ibias*1e-6-ites)*Rsh;if Ib in uA.
            V0 = Vs-I0*eval(['TES.TESParam' CondStr '.Rpar;']);
            
            P0 = V0.*I0;
            R0 = V0/I0;
            
            param.R0 = R0;
            param.P0 = P0;
            if size(eval(['[TES.Gset' CondStr '.n]']),2) > 1
                rp = R0/Rn;
                [val, ind] = min(abs(eval(['[TES.Gset' CondStr '.rp]'])-rp));
                eval(['T0 = TES.Gset' CondStr '(ind).T_fit;'])   
                % Si fijo n, cojo T0 y G0 se toman segun su rp (variables)
%                 G0 = eval(['TES.TES' CondStr '.G']);  %(W/K)
                eval(['G0 = TES.Gset' CondStr '(ind).G;'])   
%                 param.G0 = TES.TESP.n*TES.TESP.K*T0^(TES.TESP.n-1);
            else
                % Un solo valor de n, K, G y T_fit
                T0 = eval(['TES.TESThermal' CondStr '.T_fit;']); %(K)
                G0 = eval(['TES.TESThermal' CondStr '.G']);  %(W/K)
            end            
            
            
            switch obj.Zw_Models{obj.Selected_Zw_Models}
                case obj.Zw_Models{1}
                    rp = p(1,:);
                    rp_CI = p(2,:);
                    rp(1,3) = abs(rp(3));
                    param.rp = R0/Rn;
                    
                    param.Zinf = rp(1);
                    param.Zinf_CI = rp_CI(1);
                    
                    param.Z0 = rp(2);
                    param.Z0_CI = rp_CI(2);
                    
                    param.taueff = rp(3);
                    param.taueff_CI = rp_CI(3);
                    
                    param.L0 = (param.Z0-param.Zinf)/(param.Z0+R0);
                    param.L0_CI = sqrt((((param.Zinf+R0)/((param.Z0+R0)^2))*param.Z0_CI)^2 + ((-1/(R0 + param.Z0))*param.Zinf_CI)^2 );
                    
                    param.Z0Zinf = (param.Z0-param.Zinf);
                    param.Z0R0 = (param.Z0+R0);
                    
                    param.ai = param.L0*G0*T0/P0;
                    param.ai_CI = (G0*T0/P0)*param.L0_CI;
                    
                    param.bi = (param.Zinf/R0)-1;
                    param.bi_CI = (1/R0)*param.Zinf_CI;
                    
                    
                    param.tau0 = param.taueff*(param.L0-1);
                    param.tau0_CI = sqrt(((param.L0-1)*param.taueff_CI)^2 + ((param.taueff)*param.L0_CI)^2 );
                    
                    param.C = param.tau0*G0;
                    param.C_CI = G0*param.tau0_CI;
                    
                    
                    if TES.TESDim.Abs_bool
                        
                        gammas = [TES.TESDim.Abs_gammaBi TES.TESDim.Abs_gammaAu];
                        rhoAs = [TES.TESDim.Abs_rhoBi TES.TESDim.Abs_rhoAu];                                                
                        param.C_fixed = sum((gammas.*rhoAs).*([TES.TESDim.hMo TES.TESDim.hAu].*TES.TESDim.Abs_sides(1)*TES.TESDim.Abs_sides(2)).*eval(['TES.TESThermal' CondStr '.T_fit']));
                        param.tau0_fixed = param.C_fixed/G0;
                        param.L0_fixed = (param.tau0_fixed/param.taueff) + 1;
                        param.ai_fixed = param.L0_fixed*G0*T0/P0;
                        
                    else
                        
                    end
                    
                    
                case obj.Zw_Models{2}
                    % hay que definir estos par�metros
                    rp = p(1,:);
                    rp_CI = p(2,:);
%                     rp(1,3) = abs(rp(3));
                    %derived parameters for 2 block model case A
                    param.rp = R0/Rn;
                    param.Zinf = rp(1);
                    param.Zinf_CI = rp_CI(1);
                    param.Z0 = rp(2);
                    param.Z0_CI = rp_CI(2);
                    param.taueff = abs(rp(3));
                    param.taueff_CI = rp_CI(3);
                    param.ca0 = rp(4);
                    param.ca0_CI = rp_CI(4);
                    param.tauA = rp(5);
                    param.tauA_CI = rp_CI(5);
                    
                    param.L0 = (param.Z0-param.Zinf)/(param.Z0+R0);
                    param.L0_CI = sqrt((((param.Zinf+R0)/((param.Z0+R0)^2))*param.Z0_CI)^2 + ((-1/(R0 + param.Z0))*param.Zinf_CI)^2 );
                    
                    param.ai = param.L0*G0*T0/P0;                    
                    param.ai_CI = (G0*T0/P0)*param.L0_CI;
                    
                    param.bi = (param.Zinf/R0)-1;
                    param.bi_CI = (1/R0)*param.Zinf_CI;
                                        
                    param.tau0 = param.taueff*(param.L0-1);
                    param.tau0_CI = sqrt( ((param.L0-1)*param.taueff_CI)^2 + ((param.taueff)*param.L0_CI)^2 );
                   
                    param.C = param.tau0*G0;                    
                    param.C_CI = G0*param.tau0_CI;
                    
                    param.CA = param.C*param.ca0/(1-param.ca0);
                    param.CA_CI = sqrt( (param.ca0/(1-param.ca0)*param.C_CI)^2 + (((param.C*param.ca0)/(param.ca0 - 1)^2 - param.C/(param.ca0 - 1))*param.ca0_CI)^2 );
                    
                    param.GA = param.CA/param.tauA;
                    param.GA_CI = sqrt( ((-param.CA/param.tauA^2)*param.tauA_CI)^2  );                    
                    
                    
                case obj.Zw_Models{3}
                    param = nan;
                case  obj.Zw_Models{4}
                    param = nan;
            end
        end    
                
        function [RES, SimRes, M, Mph, fNoise, SigNoise] = fitNoise(obj,TES,FileName, param)
            % Function for Noise analysis.
            
            indSep = find(FileName == filesep);
            Path = FileName(1:indSep(end));
            Name = FileName(find(FileName == filesep, 1, 'last' )+1:end);
            Tbath = sscanf(FileName(indSep(end-1)+1:indSep(end)),'%dmK');
            Ib = str2double(Name(find(Name == '_', 1, 'last')+1:strfind(Name,'uA.txt')-1))*1e-6;
            % Buscamos si es Ibias positivos o negativos
            if ~isempty(strfind(Path,'Negative'))
                [~,Tind] = min(abs([TES.IVsetN.Tbath]*1e3-Tbath));
                IV = TES.IVsetN(Tind);
                CondStr = 'N';
            else
                [~,Tind] = min(abs([TES.IVsetP.Tbath]*1e3-Tbath));
                IV = TES.IVsetP(Tind);
                CondStr = 'P';
            end            
                                    
            noisedata{1} = importdata(FileName);            
            fNoise = noisedata{1}(:,1);
            
            SigNoise = TES.V2I(noisedata{1}(:,2)*1e12);
            OP = TES.setTESOPfromIb(Ib,IV,param,CondStr);
            f = logspace(0,5,1000);
            M = 0;
            
            SimulatedNoise = obj.noisesim(TES,OP,M,f,CondStr);
            SimRes = SimulatedNoise.Res;            
            sIaux = ppval(spline(f,SimulatedNoise.sI),noisedata{1}(:,1));
            NEP = sqrt(TES.V2I(noisedata{1}(:,2)).^2-SimulatedNoise.squid.^2)./sIaux;
            NEP = NEP(~isnan(NEP));%%%Los ruidos con la PXI tienen el ultimo bin en NAN.
            RES = 2.35/sqrt(trapz(noisedata{1}(1:size(NEP,1),1),1./medfilt1(real(NEP),obj.DataMedFilt).^2))/2/1.609e-19;
            
            if isreal(NEP)
                findx = find(fNoise > max(obj.Noise_LowFreq-20,1) & fNoise < obj.Noise_HighFreq);
                xdata = fNoise(findx);                
                ydata = medfilt1(NEP(findx)*1e18,obj.DataMedFilt);                
                
                findx = find(xdata > obj.Noise_LowFreq & xdata < obj.Noise_HighFreq);
                xdata = xdata(findx);
                ydata = ydata(findx);
                
                if isempty(findx)||sum(ydata == inf)
                    M = NaN;
                    Mph = NaN;
                else
                    opts = optimset('Display','off');
                    maux = lsqcurvefit(@(x,xdata) obj.fitjohnson(TES,x,xdata,OP,CondStr),[0 0],xdata,ydata,[],[],opts);                    
                    M = maux(2);
                    Mph = maux(1);
                    if M <= 0
                        M = NaN;
                    end
                    if Mph <= 0
                        Mph = NaN;
                    end
                end
            else
                M = NaN;
                Mph = NaN;
            end                        
        end
        
        function noise = noisesim(obj,TES,OP,M,f,CondStr)
            % Function for noise simulation.
            %
            % Simulacion de componentes de ruido.
            % de donde salen las distintas componentes de la fig13.24 de la pag.201 de
            % la tesis de maria? ahi estan dadas en pA/rhz.
            % Las ecs 2.31-2.33 de la tesis de Wouter dan nep(f) pero no tienen la
            % dependencia con la freq adecuada. Cuadra más con las ecuaciones 2.25-2.27
            % que de hecho son ruido en corriente.
            % La tesis de Maria hce referencia (p199) al capítulo de Irwin y Hilton
            % sobre TES en el libro Cryogenic Particle detection. Tanto en ese capítulo
            % como en el Ch1 de McCammon salen expresiones para las distintas
            % componentes de ruido.
            %
            %definimos unos valores razonables para los parámetros del sistema e
            %intentamos aplicar las expresiones de las distintas referencias.
            
            gamma = 0.5;            
            C = OP.C;
            L = TES.circuit.L;
%             G = eval(['TES.TES' CondStr '.G;']);
            alfa = OP.ai;
            bI = OP.bi;
            Rn = eval(['TES.TESParam' CondStr '.Rn;']);
            Rs = TES.circuit.Rsh;
            Rpar = eval(['TES.TESParam' CondStr '.Rpar;']);
            RL = Rs+Rpar;
            R0 = OP.R0;
            beta = (R0-Rs)/(R0+Rs);
%             T0 = eval(['TES.TES' CondStr '.T_fit;']);
            Ts = OP.Tbath;
            P0 = OP.P0;
            I0 = OP.I0;
            V0 = OP.V0;
            if size(eval(['[TES.Gset' CondStr '.n]']),2) > 1
                rp = R0/Rn;
                [val, ind] = min(abs(eval(['[TES.Gset' CondStr '.rp]'])-rp));
                eval(['T0 = TES.Gset' CondStr '(ind).T_fit;'])   
                % Si fijo n, cojo T0 y G0 se toman segun su rp (variables)
                G = eval(['TES.TESThermal' CondStr '.G']);  %(W/K)
%                 eval(['G = TES.Gset' CondStr '(ind).G;'])   
%                 param.G0 = TES.TESP.n*TES.TESP.K*T0^(TES.TESP.n-1);
            else
                % Un solo valor de n, K, G y T_fit
                T0 = eval(['TES.TESThermal' CondStr '.T_fit;']); %(K)
                G = eval(['TES.TESThermal' CondStr '.G']);  %(W/K)
            end           
            
            L0 = P0*alfa/(G*T0);
%             n = obj.TES.n;
            n = eval(['TES.TESThermal' CondStr '.n;']);
            
            if isfield(TES.circuit,'Nsquid')
                Nsquid = TES.circuit.Nsquid;
            else
                Nsquid = 3e-12;
            end
            if abs(OP.Z0-OP.Zinf) < obj.Z0_Zinf_Thrs
                I0 = (Rs/RL)*OP.ibias;
            end
            tau = C/G;
            taueff = tau/(1+beta*L0);
            tauI = tau/(1-L0);
            tau_el = L/(RL+R0*(1+bI));
            
            if nargin < 3
                M = 0;
                f = logspace(0,5,1000);
            end
            
            switch obj.Noise_Models{obj.Selected_Noise_Models}
                case obj.Noise_Models{4} % 'wouter'
                    i_ph = sqrt(4*gamma*obj.Kb*T0^2*G)*alfa*I0*R0./(G*T0*(R0+Rs)*(1+beta*L0)*sqrt(1+4*pi^2*taueff^2.*f.^2));
                    i_jo = sqrt(4*obj.Kb*T0*R0)*sqrt(1+4*pi^2*tau^2.*f.^2)./((R0+Rs)*(1+beta*L0)*sqrt(1+4*pi^2*taueff^2.*f.^2));
                    i_sh = sqrt(4*obj.Kb*Ts*Rs)*sqrt((1-L0)^2+4*pi^2*tau^2.*f.^2)./((R0+Rs)*(1+beta*L0)*sqrt(1+4*pi^2*taueff^2.*f.^2));%%%
                    noise.ph = i_ph;
                    noise.jo = i_jo;
                    noise.sh = i_sh;
                    noise.sum = sqrt(i_ph.^2+i_jo.^2+i_sh.^2);
                case obj.Noise_Models{1} % 'irwin'
                    sI = -(1/(I0*R0))*(L/(tau_el*R0*L0)+(1-RL/R0)-L*tau*(2*pi*f).^2/(L0*R0)+1i*(2*pi*f)*L*tau*(1/tauI+1/tau_el)/(R0*L0)).^-1;%funcion de transferencia.
                    
                    t = Ts/T0;
                    %%%calculo factor F. See McCammon p11.
                    %n = 3.1;
                    %F = t^(n+1)*(t^(n+2)+1)/2;%F de boyle y rogers. n =  exponente de la ley de P(T). El primer factor viene de la pag22 del cap de Irwin.
                    F = (t^(n+2)+1)/2;%%%specular limit
                    %F = t^(n+1)*(n+1)*(t^(2*n+3)-1)/((2*n+3)*(t^(n+1)-1));%F de Mather. La
                    %diferencia entre las dos fórmulas es menor del 1%.
                    %F = (n+1)*(t^(2*n+3)-1)/((2*n+3)*(t^(n+1)-1));%%%diffusive limit.
                    
                    stfn = 4*obj.Kb*T0^2*G*abs(sI).^2*F;%Thermal Fluctuation Noise
                    ssh = 4*obj.Kb*Ts*I0^2*RL*(L0-1)^2*(1+4*pi^2*f.^2*tau^2/(1-L0)^2).*abs(sI).^2/L0^2; %Load resistor Noise
                    %M = 1.8;
                    stes = 4*obj.Kb*T0*I0^2*R0*(1+2*bI)*(1+4*pi^2*f.^2*tau^2).*abs(sI).^2/L0^2*(1+M^2);%%%Johnson noise at TES.
                    if ~isreal(sqrt(stes))
                        stes = zeros(1,length(f));
                    end
                    smax = 4*obj.Kb*T0^2*G.*abs(sI).^2;
                    
                    sfaser = 0;%21/(2*pi^2)*((6.626e-34)^2/(1.602e-19)^2)*(10e-9)*P0/R0^2/(2.25e-8)/(1.38e-23*T0);%%%eq22 faser
                    sext = (18.5e-12*abs(sI)).^2;
                    
                    NEP_tfn = sqrt(stfn)./abs(sI);
                    NEP_ssh = sqrt(ssh)./abs(sI);
                    NEP_tes = sqrt(stes)./abs(sI);
                    Res_tfn = 2.35/sqrt(trapz(f,1./NEP_tfn.^2))/2/1.609e-19;
                    Res_ssh = 2.35/sqrt(trapz(f,1./NEP_ssh.^2))/2/1.609e-19;
                    Res_tes = 2.35/sqrt(trapz(f,1./NEP_tes.^2))/2/1.609e-19;
                    Res_tfn_tes = 2.35/sqrt(trapz(f,1./(NEP_tes.*NEP_tfn)))/2/1.609e-19;
                    Res_tfn_ssh = 2.35/sqrt(trapz(f,1./(NEP_ssh.*NEP_tfn)))/2/1.609e-19;
                    Res_ssh_tes = 2.35/sqrt(trapz(f,1./(NEP_tes.*NEP_ssh)))/2/1.609e-19;
                    
                    NEP = sqrt(stfn+ssh+stes)./abs(sI);
                    Res = 2.35/sqrt(trapz(f,1./NEP.^2))/2/1.609e-19;%resolución en eV. Tesis Wouter (2.37).
                    
                    %stes = stes*M^2;
                    i_ph = sqrt(stfn);
                    i_jo = sqrt(stes);
                    if ~isreal(i_jo)
                        i_jo = zeros(1,length(f));
                    end
                    i_sh = sqrt(ssh);
                    %G*5e-8
                    %(n*TES.K*Ts.^n)*5e-6
                    %i_temp = (n*TES.K*Ts.^n)*0e-6*abs(sI);%%%ruido en Tbath.(5e-4 = 200uK, 5e-5 = 20uK, 5e-6 = 2uK)
                    
                    noise.f = f;
                    noise.ph = i_ph;
                    noise.jo = i_jo;
                    noise.sh = i_sh;
                    noise.sum = sqrt(stfn+stes+ssh);%noise.sum = i_ph+i_jo+i_sh;
                    noise.sI = abs(sI);
                    
                    noise.NEP = NEP;
                    noise.max = sqrt(smax);
                    noise.Res = Res;%noise.tbath = i_temp;
                    noise.Res_tfn = Res_tfn;
                    noise.Res_ssh = Res_ssh;
                    noise.Res_tes = Res_tes;
                    noise.Res_tfn_tes = Res_tfn_tes;
                    noise.Res_tfn_ssh = Res_tfn_ssh;
                    noise.Res_ssh_tes = Res_ssh_tes;
                    noise.squid = Nsquid;
                    noise.squidarray = Nsquid*ones(1,length(f));
                otherwise
                    warndlg('no valid model',obj.version);
                    noise = [];
            end
        end
        
        function NEP = fitjohnson(obj,TES,M,f,OP,CondStr)
            
            R0=OP.R0;
            if size(eval(['[TES.Gset' CondStr '.n]']),2) > 1
                rp = R0/eval(['TES.TESParam' CondStr '.Rn']);
                [val, ind] = min(abs(eval(['[TES.Gset' CondStr '.rp]'])-rp));
                eval(['T0 = TES.Gset' CondStr '(ind).T_fit;'])   
                % Si fijo n, cojo T0 y G0 se toman segun su rp (variables)
                G = eval(['TES.TESThermal' CondStr '.G']);  %(W/K)
%                 eval(['G = TES.Gset' CondStr '(ind).G;'])   
%                 param.G0 = TES.TESP.n*TES.TESP.K*T0^(TES.TESP.n-1);
            else
                % Un solo valor de n, K, G y T_fit
                T0 = eval(['TES.TESThermal' CondStr '.T_fit;']); %(K)
                G = eval(['TES.TESThermal' CondStr '.G']);  %(W/K)
            end          
            
            Circuit = TES.circuit;
            TESThemal = eval(['TES.TESThermal' CondStr ';']);
            TES = eval(['TES.TESParam' CondStr ';']);
            
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%             G = TES.G;
%             T0 = TES.T_fit;
            
            Rn = TES.Rn;
            Rpar=TES.Rpar;
            n = TESThemal.n;            
            
            Rs=Circuit.Rsh;            
            L=Circuit.L;
            
            alfa=OP.ai;
            bI=OP.bi;
            RL=Rs+Rpar;
            
            beta=(R0-Rs)/(R0+Rs);
            %T0=OP.T0;
            Ts=OP.Tbath;
            P0=OP.P0;
            I0=OP.I0;
            V0=OP.V0;            
             
            
            L0=P0*alfa/(G*T0);
            C=OP.C;
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            
            tau=C/G;
            taueff = tau/(1+beta*L0);
            tauI=tau/(1-L0);
            tau_el=L/(RL+R0*(1+bI));
            
            t=Ts/T0;
            F=(t^(n+2)+1)/2;%%%specular limit
            
            sI=-(1/(I0*R0))*(L/(tau_el*R0*L0)+(1-RL/R0)-L*tau*(2*pi*f).^2/(L0*R0)+1i*(2*pi*f)*L*tau*(1/tauI+1/tau_el)/(R0*L0)).^-1;
            stfn=4*obj.Kb*T0^2*G*abs(sI).^2*F*(1+M(1)^2);
            stes=4*obj.Kb*T0*I0^2*R0*(1+2*bI)*(1+4*pi^2*f.^2*tau^2).*abs(sI).^2/L0^2*(1+M(2)^2);
            ssh=4*obj.Kb*Ts*I0^2*RL*(L0-1)^2*(1+4*pi^2*f.^2*tau^2/(1-L0)^2).*abs(sI).^2/L0^2; %Load resistor Noise
            NEP=1e18*sqrt(stes+stfn+ssh)./abs(sI);
        end
        
    end
end