classdef ElectronicMagnicon
    % Class of Electronic Magnicon Setup
    
    properties
        COM;
        baudrate;
        databits;
        parity;
        timeout;
        terminator;
        SourceCH;
        Rf;
        PulseAmp;
        RL;        
        PulseDT;
        PulseDuration;
        ObjHandle;
    end
    
    methods
        function obj = Constructor(obj)
            
            obj.COM = 'COM5';
            obj.baudrate = 57600;
            obj.databits = 7;
            obj.parity = 'even';
            obj.timeout = 2;
            obj.terminator = {'CR','CR'};
            obj.SourceCH = 2;
            obj.Rf = PhysicalMeasurement;            
            obj.Rf.Value = 1e4;
            obj.Rf.Units = 'Ohm';
            
            obj.PulseAmp = PhysicalMeasurement;            
            obj.PulseAmp.Value = 40;
            obj.PulseAmp.Units = 'uA';
            obj.RL = PhysicalMeasurement;            
            obj.RL.Value = 0;
            obj.RL.Units = 'Ohm';  % Comprobar que es la unidad correcta
            obj.PulseDT = PhysicalMeasurement;            
            obj.PulseDT.Value = 1000;
            obj.PulseDT.Units = 'ms';  % Comprobar que es la unidad correcta
            obj.PulseDuration = PhysicalMeasurement;            
            obj.PulseDuration.Value = 2000;
            obj.PulseDuration.Units = 'us';  % Comprobar que es la unidad correcta
            

        end
        
        function obj = Initialize(obj)
%             addpath('G:\Mi unidad\ICMA\zartes_ACQ-master\Magnicon_Matlab\');
            obj = mag_init_updated(obj);
        end
        
        function obj = Calibration(obj)
            [obj, out] = mag_setRf_FLL_CH_updated(obj);
            if strcmp(out, 'OK')
                disp('Initialization completed');
            else
                disp('Problem detected, check the connections!');
            end
        end       
        
        function TES2NormalState(obj,Ibias_sign)
            %%% Maximum current value is imposed
            Put_TES_toNormal_State_CH_updated(obj,Ibias_sign);           
            status = obj.CheckNormalState;% status == 1 Normal State reached % status == 0 Superconductor State
            Ibias = 500;
            while status == 0
                mag_ConnectLNCS_updated(obj);
                mag_setLNCSImag_updated(obj,signo*Ibias*1.25);                
                % In the case of using the source in channel 1, it is mandatory to remove
                % the LNCS device.
                mag_setImag_CH_updated(obj,signo*500);
                mag_setLNCSImag_updated(obj,0);
                mag_DisconnectLNCS_updated(obj);
                status = obj.CheckNormalState;
                Ibias = Ibias*1.25;
            end                        
            
        end
        
        function status = CheckNormalState(obj)
            Ibvalue = [500 490 480];
            Ireal = zeros(1,3);
            for i = 1:length(Ibvalue)
                obj.Set_Current_Value(Ibvalue(i));
                Ireal(i) = obj.Read_Current_Value;
            end
            P = polyfit(Ibvalue,Ireal,1);
            if P(1) < 3000 % Normal State Reached
                status = 1;
            else
                status = 0;
            end
        end
        
        function ResetClossedLoop(obj) 
            %%% Clossed loop is reset
            mag_setAMP_CH_updated(obj);
            mag_setFLL_CH_updated(obj);
        end
        
        function Pulse_Configuration(obj)
            mag_Configure_CalPulse_updated(obj);        
        end
        
        function Cal_Pulse_ON(obj)
             mag_setCalPulseON_CH_updated(obj);
        end
        
        function Cal_Pulse_OFF(obj)
             mag_setCalPulseOFF_CH_updated(obj);
        end
        
        function Set_Current_Value(obj,Ibvalue)
            mag_setImag_CH_updated(obj,Ibvalue);
        end
        
        function Ireal = Read_Current_Value(obj)
            Ireal = PhysicalMeasurement;
            Ireal.Value = mag_readImag_CH_updated(obj);
            Ireal.Units = 'uA';
        end
        
        function Destructor(obj)
            try
                fclose(obj.ObjHandle);
            catch
            end
            delete(obj.ObjHandle);
        end
       
    end
    
end

