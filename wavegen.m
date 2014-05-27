function varargout = wavegen(varargin)
% WAVEGEN MATLAB code for wavegen.fig
%      WAVEGEN, by itself, creates a new WAVEGEN or raises the existing
%      singleton*.
%
%      H = WAVEGEN returns the handle to a new WAVEGEN or the handle to
%      the existing singleton*.
%
%      WAVEGEN('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in WAVEGEN.M with the given input arguments.
%
%      WAVEGEN('Property','Value',...) creates a new WAVEGEN or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before wavegen_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to wavegen_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help wavegen

% Last Modified by GUIDE v2.5 22-May-2014 11:36:46

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @wavegen_OpeningFcn, ...
                   'gui_OutputFcn',  @wavegen_OutputFcn, ...
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

% --- Executes just before wavegen is made visible.
function wavegen_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to wavegen (see VARARGIN)

% Choose default command line output for wavegen
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes wavegen wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = wavegen_OutputFcn(hObject, eventdata, handles)
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;

% --- Executes on button press in pushbutton1.
function pushbutton1_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

clear all;
%run the generator
global rotorSpeed;
global a;
global run;
global gen;
global loop;
global step_tot;
global loopSpeed;
loopSpeed = 1000;
rotorSpeed = 0;

microstepcurve = [0, 50, 98, 142, 180, 212, 236, 250, 255];

%% create arduino object and connect to board
if exist('a','var') && isa(a,'arduino') && isvalid(a),
    % nothing to do    
else
    a=arduino('/dev/tty.usbmodem1411');
end

%% basic analog and digital IO

% specify pin mode for pins 13
pinMode(a,9,'output');      %M1_PWM 
pinMode(a,7,'output');      %M1_DIR
% pinMode(a,0,'input');       %M1_CURRENT
% pinMode(a,1,'input');       %GEN_CURRENT
encoderAttach(a,0,3,2);     %M1_ENCODER 
% encoderAttach(a,1,18,19);   %GEN_ENCODER
pinMode(a,6,'output');      %STP_PULSE
pinMode(a,5,'output');      %STP_DIR  

digitalWrite(a,7,1);        %SET M1 DIR

av = 0;
gen(1) = av;
plot(gen);

run = 1;
stepperSpeed(a,1,1);


% rotates stepper with given amplitude and freq
setupStepper(30, .5);
i = 1;
delay = loop(1);
dir = 'forward';
pulse = 1;
t0=clock;

%main loop @ 200hz
k = 0;
j = 0;
while (run == 1)
    k=k+1;
    av = analogRead(a,3);
%     gen(i) = av;
%     gen(k) = step_tot;

    enc(k) = encoderRead(a,0);
    
    mot(k)=round(rotorSpeed*255);

    plot(enc);
    
    % control stepper
    if (loopSpeed<=etime(clock,t0))
        t0=clock;
        stepperStep(a,1,dir,'single',delay);
        i=i+1;
        delay = loop(i);
            
        if (strcmp(dir, 'forward'))
            step_tot = step_tot+loopSpeed/(loop(i-1)*1000);
        else
            step_tot = step_tot-loopSpeed/(loop(i-1)*1000);
        end
        
        j=j+1;
        gen(j) = step_tot;
    end


    if (i==size(loop,1))
        if (strcmp(dir, 'forward'))
            dir = 'backward';
        else
            dir = 'forward';
        end
        i = 1;
    end
    
    pause(.005);
end

function setupStepper(amp, freq)
global loop;
global loopSpeed;
global step_tot;
step_tot = 0;
resolution = 5;
period = 1/freq;
steps_per_rot = 800; % given in datasheet, adjust by using microsteps
deg_per_step = 360/steps_per_rot; 
steps_to_amp = round(amp/deg_per_step);
time_to_amp = period/4;
loopSpeed = time_to_amp/resolution;
avg_delay = time_to_amp/steps_to_amp;
steps=zeros(steps_to_amp,1);
delay_factor = (2/pi)*avg_delay/0.3639*1000;
for i=1:steps_to_amp
    steps(i) = asin(i*(1/steps_to_amp))*delay_factor;
end

% create loop with resolution
s = floor(size(steps,1)/resolution);
speeds=zeros(resolution,1);
for j = 1:resolution
    speeds(j) = round(steps(s*j));
end

%initialize loop
loop = [flipud(speeds); speeds]



function edit1_Callback(hObject, eventdata, handles)
% hObject    handle to edit1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit1 as text
%        str2double(get(hObject,'String')) returns contents of edit1 as a double


% --- Executes during object creation, after setting all properties.
function edit1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function edit2_Callback(hObject, eventdata, handles)
% hObject    handle to edit2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit2 as text
%        str2double(get(hObject,'String')) returns contents of edit2 as a double


% --- Executes during object creation, after setting all properties.
function edit2_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function edit3_Callback(hObject, eventdata, handles)
% hObject    handle to edit3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit3 as text
%        str2double(get(hObject,'String')) returns contents of edit3 as a double


% --- Executes during object creation, after setting all properties.
function edit3_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on slider movement.
function rotorSlider_Callback(hObject, eventdata, handles)
% hObject    handle to rotorSlider (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider
global rotorSpeed;
global a;
rotorSpeed = get(hObject,'Value')
analogWrite(a,9,round(rotorSpeed*255));


% --- Executes during object creation, after setting all properties.
function rotorSlider_CreateFcn(hObject, eventdata, handles)
% hObject    handle to rotorSlider (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end


% --- Executes on button press in pushbutton5.
function pushbutton5_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton5 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% save the output
global a;
global run;
global gen;

% stop the run loop
run = 0;

% stop the motor
analogWrite(a,9,0);

% releases stepper 
stepperSpeed(a,2,-1); 

if(~isdir('output'))
    mkdir('output');
end
save('output/generator_data.mat','gen')


flush(a);
delete(a);
