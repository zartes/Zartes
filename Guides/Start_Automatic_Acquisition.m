function Start_Automatic_Acquisition(handles, SetupTES, Conf)

% handles perteneciente a los setups
% Conf estructura de configuraci�n de la adquisici�n autom�tica

temps = Conf.Temps.Values*1e3;  % Now temps array is in milliKelvin
TempName = Conf.Temps.File(max(strfind(Conf.Temps.File,filesep))+1:end);
TempDir = Conf.Temps.File(1:max(strfind(Conf.Temps.File,filesep)));

Bvalues = Conf.Field.Values;

%% Main block (repeated for each temperature value)

% - Intensity-Voltage acquisition block 
% - Critical intensities acquisition block (Optional)
% - Acquisition block varying magnetic field values
% - Impedance + noise (Z(w)+ N) acquisition block
%   - Acquire or not an IV coarse (Optional)
for i = 1:length(temps)
    
    % Generating a temporal file to (specify what for)
    Tstring = sprintf('%0.1fmK',temps(i));
    SETstr = [TempDir 'T' Tstring '.stb'];
    
    %% Waiting for Tbath set file
    h = waitbar(0,['Please wait... Acquisition will start at Tbath ' Tstring]);
    h1.hi = 0;
    h1.Nsteps = 50;
    
    while(~exist(SETstr,'file'))
        if ishandle(h)
            waitbar(h1.hi/h1.Nsteps,h)
            h1.hi = h1.hi+1;
            if h1.hi > h1.Nsteps
                h1.hi = 0;
            end
            
        end        
        pause(0.1);
    end
    if ishandle(h)
        delete(h)
        clear h1;
    end
    %%
    
    % (repeated for each B Field value)
    for j = 1:length(Bvalues)
        if Bvalues(j) ~= 0  % In the case of being just more than one single value and different than zero.
            % Current Source for Field control must be activated                        
            SetupTEScontrolers('CurSource_Cal_Callback',SetupTES.CurSource_Cal,[],guidata(SetupTES.CurSource_Cal))
            SetupTES.CurSource_I.String = num2str(Conf.Field.Values(j));
            SetupTES.CurSource_I_Units.Value = 3;
            SetupTEScontrolers('CurSource_OnOff_Callback',SetupTES.CurSource_OnOff,[],guidata(SetupTES.CurSource_OnOff));
            
        end
        
        %% Acquisition block, once bath temperature and field were set
        
        if Conf.Ibvalues.Mode % If 1, then IV curves are acquired
            % Calibration
            SetupTEScontrolers('SQ_Calibration_Callback',SetupTES.SQ_Calibration,[],guidata(SetupTES.SQ_Calibration));
            Rf = str2double(SetupTES.SQ_Rf_real.String);
            % Configuration to be stored
            [signo,pol,dire] = IbvaluesExtraction(Conf.Ibvalues.Values);
            
            % Set TES to Normal State
            SetupTEScontrolers('SQ_TES2NormalState_Callback',SetupTES.SQ_TES2NormalState,[],guidata(SetupTES.SQ_TES2NormalState));
            
            % Reset Closed Loop
            SetupTEScontrolers('SQ_Reset_Closed_Loop_Callback',SetupTES.SQ_Reset_Closed_Loop,[],guidata(SetupTES.SQ_Reset_Closed_Loop));
            
            data = [];
            slope = 0;
            state = 0;
            averages = 1;
            jj = 1;
            for k = 1:length(Conf.Ibvalues.Values)  % (Repeated for each Ibvalue)
                
                %% Adapting Ibvalues resolution (under construction) 
                disp(['Ibias: ' num2str(Conf.Ibvalues.Values(k)) ' uA'])                
                if slope > 3000  % State variable changes from 0 (normal) to 1 (superconductor)
                    state = 1;
                end %%% state = 1 -> superconductor. Be aware! slope value of 3000 is just for Rf = 3Kohm.
                
                if state && mod(Conf.Ibvalues.Values(k),5) %%% When the state is superconductor then the resolution is changed
                    continue;
                end
                
                % Set Ibvalue
                SetupTES.SQ_Ibias.String = num2str(Conf.Ibvalues.Values(k));
                SetupTES.SQ_Ibias_Units.Value = 3;
                SetupTEScontrolers('SQ_Set_I_Callback',SetupTES.SQ_Set_I,[],guidata(SetupTES.SQ_Set_I));
                if k == 1
                    pause(2);
                end
                for i_av = 1:averages
                    SetupTEScontrolers('Multi_Read_Callback',SetupTES.Multi_Read,[],guidata(SetupTES.Multi_Read));
                    aux1{i_av} = str2double(SetupTES.Multi_Value.String);
                    if i_av == averages
                        Vdc = mean(cell2mat(aux1));
                    end
                end
                
                % Read I real value
                SetupTEScontrolers('SQ_Read_I_Callback',SetupTES.SQ_Read_I,[],guidata(SetupTES.SQ_Read_I));                
                Ireal = str2double(SetupTES.SQ_realIbias.String);
                
                data(jj,1) = now;
                data(jj,2) = Ireal; %*1e-6;
                data(jj,3) = 0; %%%Vout
                data(jj,4) = Vdc;
                jj = jj+1;
                
                if k > 1 && ~state
                    slope = (data(i,4)-data(i-1,4))/((data(i,2)-data(i-1,2))*1e-6);
                end
                
                IV = corregir1rama(data);
                IV.Tbath = temps(i);
                
                file = strcat(temps(i),'_Rf',num2str(Rf),'K_',dire,'_',pol,'_matlab.txt');
%                 save(file,'data','-ascii');
                
            end
        end
        
        if Conf.ZwNoise.Mode % If 1, then Z(w) + Noise are acquired
            
        end        
        
        if Conf.Pulses.Mode % If 1, then Pulses are acquired
            
        end
    end
end
%%
Conf.Ibvalues.Mode = handles.AQ_IVs.Value; % 0 (off), 1 (on) 
Conf.Ibvalues.Values = Ibvalues;

Conf.Field.Mode = handles.BField_Mode.Value;  % 0 (off), 1 (on)
Conf.Field.Values = Field;

Conf.ZwNoise.Mode = handles.AQ_mode.Value; % 0 (off), 1 (on)
Conf.ZwNoise.Zw.Parameters = [];
Conf.ZwNoise.Noise.Parameters = [];

Conf.Pulses.Mode = handles.AQ_Pulse.Value; % 0 (off), 1 (on)
Conf.Pulses.Parameters = [];




