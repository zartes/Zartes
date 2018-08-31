function Start_Automatic_Acquisition(handles, Conf)

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
    
    % Waiting for Tbath set file
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
    
    % (repeated for each B Field value)
    for j = 1:Bvalues        
        if length(Bvalues) ~= 1 && Bvalues(j) ~= 0
            
        else  % There is no need of activating the Current Source, since no field is required.
            
            %%%%  Aqu� me he quedado
            
            
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