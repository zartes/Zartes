function [data, WfmI, TimeLapsed] = pxi_GetWaveForm(pxi)
% Function to donwload one screen capture and the related information to this vector; of PXI Acq. Card
%
% Output:
% - pxi: Object communication with the PXI card
%
% Example:
% pxi_GetWaveForm(pxi)
%
% Last update: 06/07/2018

%% Funci�n para descargar una captura y la informacion asociada a un vector

% numSamples = get(get(pxi.ObjHandle,'horizontal'),'min_number_of_points');
numSamples=get(get(pxi.ObjHandle,'horizontal'),'min_number_of_points');
% numSamples = pxi.ConfStructs.Horizontal.RL;
ChL = length(pxi.ConfStructs.Vertical.ChannelList);
if ChL == 1
    numChannels = 1;
else
    numChannels = 2;
end
waveformArray = zeros(1,numSamples*numChannels);%%%Prealojamos espacio.

% Este bloque de c�digo ya est� incluido en pxi.

% TimeOut=Options.TimeOut;
% channelList=Options.channelList;
% 
% 
% for i = 1:numChannels %%%Inicializamos la Info.
%     waveformInfo(i).absoluteInitialX = 0;
%     waveformInfo(i).relativeInitialX = 0;
%     waveformInfo(i).xIncrement = 0;
%     waveformInfo(i).actualSamples = 0;
%     waveformInfo(i).offset = 0;
%     waveformInfo(i).gain = 0;
%     waveformInfo(i).reserved1 = 0;
%     waveformInfo(i).reserved2 = 0;
% end 
% pxi.AbortAcquisition; 
try
    invoke(pxi.ObjHandle.Acquisition, 'initiateacquisition'); %%%Puede ir aqu� o fuera.
catch
    
end
try
[Wfm, WfmI] = invoke(pxi.ObjHandle.Acquisition, 'fetch',...
    pxi.Options.channelList,...
    pxi.Options.TimeOut,...
    numSamples,...
    waveformArray,... 
    pxi.WaveFormInfo); %%
    TimeLapsed = 0;
catch me
    switch me.message
        case ['The instrument returned an error while executing the function.' char(10) 'Maximum time exceeded before the operation completed.']
            data = [];
            WfmI = [];
            TimeLapsed = 1;
            return;
    end
end

DT = WfmI.xIncrement;
L = WfmI.actualSamples;
data(:,1) = (0:L-1)*DT;
data(:,2) = Wfm(1:L);
if numChannels == 2 
    data(:,3) = Wfm(L+1:end);
end