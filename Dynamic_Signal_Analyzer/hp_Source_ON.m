function hp_Source_ON(dsa)
% Function to activate the output of the source provided by HP3562A device 
% output
%
% Input:
% - dsa: Object class HP3562A
%
% Example:
% hp_Source_ON(dsa)
%
% Last update: 06/07/2018

%% funci�n para activar la fuente

fprintf(dsa.ObjHandle,'SRON1');