function varargout = Conf_Setup(varargin)
% CONF_SETUP MATLAB code for Conf_Setup.fig
%      CONF_SETUP, by itself, creates a new CONF_SETUP or raises the existing
%      singleton*.
%
%      H = CONF_SETUP returns the handle to a new CONF_SETUP or the handle to
%      the existing singleton*.
%
%      CONF_SETUP('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in CONF_SETUP.M with the given input arguments.
%
%      CONF_SETUP('Property','Value',...) creates a new CONF_SETUP or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before Conf_Setup_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to Conf_Setup_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help Conf_Setup

% Last Modified by GUIDE v2.5 23-Jul-2018 10:35:04

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @Conf_Setup_OpeningFcn, ...
                   'gui_OutputFcn',  @Conf_Setup_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT


% --- Executes just before Conf_Setup is made visible.
function Conf_Setup_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to Conf_Setup (see VARARGIN)

% Choose default command line output for Conf_Setup
handles.output = hObject;
handles.varargin = varargin;
position = get(handles.figure1,'Position');
set(handles.figure1,'Color',[0 0.2 0.5],'Position',...
    [0.5-position(3)/2 0.5-position(4)/2 position(3) position(4)],...
    'Units','Normalized');


switch varargin{1}.Tag
    case 'DSA_TF_Conf'
        handles.Options.String = {'Sweept Sine';'Fixed Sine'};
        ConfInstrs{1} = {'AUTO 0';'SSIN';'LGSW';'RES 20P/DC';'SF 1Hz';'FRS 5Dec';...
            'SWUP';'SRLV 100mV';'C2AC 0';'FRQR';'VTRM';'VHZ';'NYQT'};
        ConfInstrs{2} = {'LGRS';['FSIN ' varargin{3}.Sine_Freq.String 'Hz'];['SRLV ' varargin{3}.Sine_Amp.String 'mV']};
        switch varargin{2}
            case 1 % Sweept Sine
                handles.Options.Value = 1;
                
            case 2 % Fixed Sine
                handles.Options.Value = 2;
        end
        
    case 'DSA_Noise_Conf'
        handles.Options.String = {'Noise Setup 1';'Noise Setup 2'};
        ConfInstrs{1} = {'AUTO 0';'LGRS';'SF 10Hz';'FRS 4Dec';'PSUN';'VTRM';'VHZ';'STBL';...
            'AVG 5';'C2AC 1';'PSP2';'MGDB';'YASC'};
        ConfInstrs{2} = {'LGRS';'RND';['SRLV ' varargin{3}.Noise_Amp.String 'mV']};
        switch varargin{2}
            case 1 % Noise Setup 1
                handles.Options.Value = 1;
                % Noise Conf.                            
                
            case 2 % Noise Setup 2
                handles.Options.Value = 2;                                
        end        
end

% Configuration of the DSA options
handles.ConfInstrs = ConfInstrs;

handles.Table.Data = handles.ConfInstrs{varargin{2}};





% Update handles structure
guidata(hObject, handles);

% UIWAIT makes Conf_Setup wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = Conf_Setup_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;
handles.figure1.Visible = 'on';


% --- Executes on button press in Add.
function Add_Callback(hObject, eventdata, handles)
% hObject    handle to Add (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.Table.Data = [handles.Table.Data; cell(1,3)];

% --- Executes on button press in Remove.
function Remove_Callback(hObject, eventdata, handles)
% hObject    handle to Remove (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
if size(handles.Table.Data,1) > 1
    handles.Table.Data(end,:) = [];
end


% --- Executes on selection change in Options.
function Options_Callback(hObject, eventdata, handles)
% hObject    handle to Options (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns Options contents as cell array
%        contents{get(hObject,'Value')} returns selected item from Options


handles.Table.Data = handles.ConfInstrs{hObject.Value};


% --- Executes during object creation, after setting all properties.
function Options_CreateFcn(hObject, eventdata, handles)
% hObject    handle to Options (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



% --- Executes on button press in Cancel.
function Cancel_Callback(hObject, eventdata, handles)
% hObject    handle to Cancel (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

figure1_DeleteFcn(handles.figure1,eventdata,handles);  



% --- Executes during object deletion, before destroying properties.
function figure1_DeleteFcn(hObject, eventdata, handles)
% hObject    handle to figure1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

delete(handles.figure1);


% --- Executes on button press in Save.
function Save_Callback(hObject, eventdata, handles)
% hObject    handle to Save (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

switch handles.varargin{1}.Tag
    case 'DSA_TF_Conf'
        handles.varargin{3}.TF_Menu.Value = handles.Options.Value;
    case 'DSA_Noise_Conf'
        handles.varargin{3}.Noise_Menu.Value = handles.Options.Value;        
end

figure1_DeleteFcn(handles.figure1,eventdata,handles);  
