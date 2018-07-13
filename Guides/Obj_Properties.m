function varargout = Obj_Properties(varargin)
% OBJ_PROPERTIES M-file for Obj_Properties.fig
%      OBJ_PROPERTIES, by itself, creates a new OBJ_PROPERTIES or raises the existing
%      singleton*.
%
%      H = OBJ_PROPERTIES returns the handle to a new OBJ_PROPERTIES or the handle to
%      the existing singleton*.
%
%      OBJ_PROPERTIES('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in OBJ_PROPERTIES.M with the given input arguments.
%
%      OBJ_PROPERTIES('Property','Value',...) creates a new OBJ_PROPERTIES or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before Obj_Properties_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to Obj_Properties_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help Obj_Properties

% Last Modified by GUIDE v2.5 13-Jul-2018 11:49:11

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @Obj_Properties_OpeningFcn, ...
                   'gui_OutputFcn',  @Obj_Properties_OutputFcn, ...
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


% --- Executes just before Obj_Properties is made visible.
function Obj_Properties_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to Obj_Properties (see VARARGIN)

% Choose default command line output for Obj_Properties
handles.output = hObject;
if ~isempty(varargin{1})
    handles.Obj = varargin{1};
end
% Update handles structure
guidata(hObject, handles);

% UIWAIT makes Obj_Properties wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = Obj_Properties_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;

position = get(handles.figure1,'Position');
set(handles.figure1,'Color',[0.3 0.35 0.59],'Position',...
    [0.5-position(3)/2 0.5-position(4)/2 position(3) position(4)],...
    'Units','Normalized','Name',handles.Obj.Label);


content.ParametersStr = properties(handles.Obj.UserData);

for i = 1:length(content.ParametersStr)
    eval('data{i,1} = content.ParametersStr{i};');
    if strcmp(eval(['class(handles.Obj.UserData.' content.ParametersStr{i} ')']),'PhysicalMeasurement')
        eval(['data{i,2} = handles.Obj.UserData.' content.ParametersStr{i} '.Value;']);
        eval(['data{i,3} = handles.Obj.UserData.' content.ParametersStr{i} '.Units;']);
    elseif ~iscell(eval(['class(handles.Obj.UserData.' content.ParametersStr{i} ')']))        
        eval(['data{i,2} = handles.Obj.UserData.' content.ParametersStr{i} ';']);
        data{i,3} = '';
    else
        for j = 1:length(eval(['handles.Obj.UserData.' content.ParametersStr{i}]))
            % Casos en los que el dato es un cell 
        end
    end
end
set(handles.tabla,'Data',data);
% data_conf = data;
% 
% set(handles.Conf_File,'String',handles.ConfFile,'Value',handles.ConfFileNum);    
%     Conf_File_Callback(handles.Conf_File,[],handles);    
    
    
set(handles.figure1,'Visible','on');
guidata(hObject,handles);
% --- Executes on button press in Default_File.
function Default_File_Callback(hObject, eventdata, handles)
% hObject    handle to Default_File (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

handles.Obj.UserData = handles.Obj.UserData.Constructor;
content.ParametersStr = properties(handles.Obj.UserData);

for i = 1:length(content.ParametersStr)
    eval('data{i,1} = content.ParametersStr{i};');
    eval(['data{i,2} = handles.Obj.UserData.' content.ParametersStr{i} '.Value;']);
    eval(['data{i,3} = handles.Obj.UserData.' content.ParametersStr{i} '.Units;']);
end
set(handles.tabla,'Data',data);

guidata(hObject,handles);

% --- Executes on selection change in Conf_File.
function Conf_File_Callback(hObject, eventdata, handles)
% hObject    handle to Conf_File (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns Conf_File contents as cell array
%        contents{get(hObject,'Value')} returns selected item from Conf_File




guidata(hObject,handles)
% --- Executes during object creation, after setting all properties.
function Conf_File_CreateFcn(hObject, eventdata, handles)
% hObject    handle to Conf_File (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in Browse.
function Browse_Callback(hObject, eventdata, handles)
% hObject    handle to Browse (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% global prmSetup
name = handles.ConfFile{handles.ConfFileNum};

[ecgannot, anotdir] = uigetfile({['*' name '*.mat'],'Mat file (*.mat)';
    '*.mat','All files (*.*)'},...
    'Select one annotation file','*.mat');

if ~isempty(ecgannot)&&~isequal(ecgannot,0)
    handles.ConfFileDir{end+1} = anotdir;
    handles.ConfFile{end+1} = ecgannot(1:strfind(ecgannot,'.mat')-1);
    handles.ConfFileNum = handles.ConfFileNum +1;
    
    set(handles.Conf_File,'String',handles.ConfFile,'Value',handles.ConfFileNum);
    Conf_File_Callback(handles.Conf_File,[],handles);
%     prmSetup.wavedet.Conf_File = handles.ConfFile;
%     prmSetup.wavedet.Conf_File_Dir = handles.ConfFileDir;
%     prmSetup.wavedet.Conf_File_Num = handles.ConfFileNum;
end
guidata(hObject,handles);
% --- Executes on button press in cancel.
function cancel_Callback(hObject, eventdata, handles)
% hObject    handle to cancel (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
figure1_DeleteFcn(handles.figure1,[],handles);

% --- Executes on button press in save.
function save_Callback(hObject, eventdata, handles)
% hObject    handle to save (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global data_conf

data = get(handles.tabla,'Data');
if ~isequal(data_conf,data)  
    for i = 1:length(data)
        eval([data{i,1} '= ' num2str(data{i,2}) ';']);
    end
    units = data(:,3);
    ParametersStr = data(:,1);
    
    uiwait(tickbox('New Properties were saved successfully!','ZarTES v.1'));
    return;
end

delete(handles.figure1);

% --- Executes on key press with focus on figure1 or any of its controls.
function figure1_WindowKeyPressFcn(hObject, eventdata, handles)
% hObject    handle to figure1 (see GCBO)
% eventdata  structure with the following fields (see FIGURE)
%	Key: name of the key that was pressed, in lower case
%	Character: character interpretation of the key(s) that was pressed
%	Modifier: name(s) of the modifier key(s) (i.e., control, shift) pressed
% handles    structure with handles and user data (see GUIDATA)
try
    if strcmp(eventdata.Key,'escape')
        cancel_Callback(handles.cancel,eventdata,handles);
    elseif strcmp(eventdata.Key,'return')
        save_Callback(handles.save,eventdata,handles);
    end
catch
end


% --- Executes during object deletion, before destroying properties.
function figure1_DeleteFcn(hObject, eventdata, handles)
% hObject    handle to figure1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
delete(handles.figure1);


% --- Executes when entered data in editable cell(s) in tabla.
function tabla_CellEditCallback(hObject, eventdata, handles)
% hObject    handle to tabla (see GCBO)
% eventdata  structure with the following fields (see UITABLE)
%	Indices: row and column indices of the cell(s) edited
%	PreviousData: previous data for the cell(s) edited
%	EditData: string(s) entered by the user
%	NewData: EditData or its converted form set on the Data property. Empty if Data was not changed
%	Error: error string when failed to convert EditData to appropriate value for Data
% handles    structure with handles and user data (see GUIDATA)
