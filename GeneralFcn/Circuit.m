classdef Circuit
    % Class defining a Circuit class.
    
    properties              
        Rpar;           % Parasitic Impedance (TES branch)
        Rn;             % Impedance of TES in Normal state  
        Rf;             % Impedance of FLL (linked to Squid Rf magnitude)
        Rsh;            % Impedance of the resistive divisor
        invMf;          % Inverse of the relation between Amplitude and flux (input)
        invMin;         % Inverse of the relation between Amplitude and flux (feedback)
        L;              % Inductance of the circuit 
        mN;             % Slope of the IV characterization during Normal state (TES)
        mS;             % Slope of the IV characterization during Superconductor state (TES)
    end
    
    methods        
        function obj = Constructor(obj)
            % Function to generate the class with default values
            
            obj.Rf = PhysicalMeasurement;            
            obj.Rf.Value = [];
            obj.Rf.Units = 'Ohm';
            
            obj.Rpar = PhysicalMeasurement;            
            obj.Rpar.Value = 2.035e-05;
            obj.Rpar.Units = 'Ohm';
            
            obj.Rn = PhysicalMeasurement;
            obj.Rn.Value = 0.0232;
            obj.Rn.Units = 'Ohm';
            
            obj.Rsh = PhysicalMeasurement;
            obj.Rsh.Value = 0.002;
            obj.Rsh.Units = 'Ohm';
            
            obj.invMf = PhysicalMeasurement;
            obj.invMf.Value = 66;
            obj.invMf.Units = 'uA/phi';
            
            obj.invMin = PhysicalMeasurement;
            obj.invMin.Value = 24.1;
            obj.invMin.Units = 'uA/phi';
            
            obj.L = PhysicalMeasurement;
            obj.L.Value = 7.7e-08;
            obj.L.Units = 'H';
            
            obj.mN = PhysicalMeasurement;
            obj.mN.Value = 650.7;
            obj.mN.Units = 'Ohm';
            
            obj.mS = PhysicalMeasurement;
            obj.mS.Value = 8133;
            obj.mS.Units = 'Ohm';
        end
    end
    
end