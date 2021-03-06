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

% Last Modified by GUIDE v2.5 28-May-2014 14:58:23

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

global usbPort;
set(handles.usbPort, 'String', usbPort);


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

% --- Executes on button press in beginButton.
function beginButton_Callback(hObject, eventdata, handles)
% hObject    handle to beginButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

%run the generator
global rotorSpeed;
global wave_freq;
global wave_amp;
global a;
global usbPort;
global run;

usbPort = get(handles.usbPort, 'String')

%plot vars
global gen;
global enc;
global pot;
global step;
global loop;
global step_tot;
global yTime;
global mot;
global curr;
global pow;

%initializations
global loopSpeed;
global data;
global runStepper;
loopSpeed = 1000;
rotorSpeed = 0;

usbPort=get(handles.usbPort,'String');

% create arduino object and connect to board
if exist('a','var') && isa(a,'arduino') && isvalid(a),
    % nothing to do    
else
    a=arduino(usbPort);
end


%% basic analog and digital IO

% specify pin mode for pins 13
global M1_PWM;
M1_PWM = 10;
M1_DIR = 7;
M1_CURR = 15;
M1_ENC1 = 18;
M1_ENC2 = 19;
GEN_ENC1 = 3;
GEN_ENC2 = 2;
STP_PULSE = 6;
STP_DIR = 5;
POT_PIN = 2;
GEN_PIN = 3;

pinMode(a,8,'output');
pinMode(a,M1_PWM,'output');      %M1_PWM 
pinMode(a,M1_DIR,'output');      %M1_DIR
pinMode(a,M1_CURR,'input');       %M1_CURRENT
% encoderAttach(a,1,M1_ENC1,M1_ENC2);     %M1_ENCODER 
encoderAttach(a,0,GEN_ENC1,GEN_ENC2);   %GEN_ENCODER
pinMode(a,STP_PULSE,'output');      %STP_PULSE
pinMode(a,STP_DIR,'output');      %STP_DIR  
pinMode(a,POT_PIN,'input');      %Potentiometer
pinMode(a,GEN_PIN,'input');      %Generator Voltage

digitalWrite(a,M1_DIR,1);        %SET M1 DIR
stepperSpeed(a,1,1);             %SET STP STARTING SPEED (HACK)
digitalWrite(a,8,0);

mot = [0; 0];
enc = [0; 0];
gen = [0; 0];
curr = [0; 0];
pow = [0; 0];
step = [0; 0];
pot = [0; 0];
yTime = [0; 0];

data = plot(step);
hold on;
motor = plot(mot,'r');
encoder = plot(enc, 'k');
generator = plot(gen, 'g');
potentiometer = plot(pot, 'm');
power = plot(pow, 'c');
current = plot(curr, 'y');

set(data,'XData',yTime,'YData',step);
set(motor,'XData',yTime,'YData',mot);
set(encoder,'XData',yTime,'YData',enc);
set(generator,'XData',yTime,'YData',gen);
set(potentiometer,'XData',yTime,'YData',pot);
set(power,'XData',yTime,'YData',pow);
set(current,'XData',yTime,'YData',curr);
xlabel('Time (s)');
ylabel('Data');
tStart = clock;

run = 1;
gearRatio = 3;

runStepper = 0;
wave_amp = str2double(get(handles.ampText, 'String'));
wave_freq = str2double(get(handles.freqText, 'String'));

% rotates stepper with given amplitude and freq
setupStepper(wave_amp, wave_freq);
i = 1;
t0=clock;
dir = 'forward';

%main loop @ 200hz
k = 0;
j = 0;
i=round(size(loop,1)/2);
while (run == 1)
    k=k+1;
    
%   Update the plot

    yTime(k) = etime(clock, tStart);
    gen(k) = encoderRead(a,0)*360/(48*gearRatio);
    pot(k) = round(analogRead(a,POT_PIN) - 512)*360/1023;
    pow(k) = analogRead(a,GEN_PIN) * 5;
    curr(k) = analogRead(a,M1_CURR) * 34;
%     step(k) = step_tot*100000;
%     mot(k)=round(rotorSpeed);
%     enc(k) = encoderRead(a,1)*360/465;
    
    set(generator,'XData',yTime,'YData',gen); 
    set(potentiometer,'XData',yTime,'YData',pot);
    set(power,'XData',yTime,'YData',pow);
    set(current,'XData',yTime,'YData',curr);
%     set(motor,'XData',yTime,'YData',mot);
%     set(data,'XData',yTime,'YData',step);
%     set(encoder,'XData',yTime,'YData',enc);
    
    % control stepper
    if (loopSpeed<=etime(clock,t0) && runStepper == 1)
        t0=clock;
        delay = loop(i);
        stepperStep(a,1,dir,'single',delay);
        i=i+1;
            
        if (strcmp(dir, 'forward'))
            step_tot = step_tot+loopSpeed/(loop(i-1)*1000);
        else
            step_tot = step_tot-loopSpeed/(loop(i-1)*1000);
        end
        
        j=j+1;
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
resolution = 6;
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
loop = [flipud(speeds); speeds];



function freqText_Callback(hObject, eventdata, handles)
% hObject    handle to freqText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of freqText as text
%        str2double(get(hObject,'String')) returns contents of freqText as a double


% --- Executes during object creation, after setting all properties.
function freqText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to freqText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function ampText_Callback(hObject, eventdata, handles)
% hObject    handle to ampText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of ampText as text
%        str2double(get(hObject,'String')) returns contents of ampText as a double


% --- Executes during object creation, after setting all properties.
function ampText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to ampText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function rotorText_Callback(hObject, eventdata, handles)
% hObject    handle to rotorText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of rotorText as text
%        str2double(get(hObject,'String')) returns contents of rotorText as a double


% --- Executes during object creation, after setting all properties.
function rotorText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to rotorText (see GCBO)
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
global M1_PWM;
rotorSpeed = get(hObject,'Value')
max_speed = 2000; %rpm
set(handles.rotorText, 'String', round(rotorSpeed*maxSpeed));
analogWrite(a,M1_PWM,round(rotorSpeed*255));


% --- Executes during object creation, after setting all properties.
function rotorSlider_CreateFcn(hObject, eventdata, handles)
% hObject    handle to rotorSlider (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end


% --- Executes on button press in stopButton.
function stopButton_Callback(hObject, eventdata, handles)
% hObject    handle to stopButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% save the output
global a;
global run;
global gen;
global step;
global enc;
global pot;
global step;
global loop;
global step_tot;
global yTime;
global mot;
global curr;
global pow;

% stop the run loop
run = 0;

if(~isdir('output'))
    mkdir('output');
end
filename = strcat('output/generator_data_',datestr(clock),'.mat');
save(filename,'gen');
save(filename,'step', '-append');
save(filename,'enc', '-append');
save(filename,'pot', '-append');
save(filename,'loop', '-append');
save(filename,'step_tot', '-append');
save(filename,'yTime', '-append');
save(filename,'mot', '-append');
save(filename,'curr', '-append');
save(filename,'pow', '-append');

% stop the motor
analogWrite(a,9,0);

% releases stepper 
stepperStep(a,1,'forward','single',255);

flush(a);
delete(a);


% --- Executes on button press in connectButton.
function connectButton_Callback(hObject, eventdata, handles)
% hObject    handle to connectButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

global a;
global usbPort;
usbPort=get(handles.usbPort,'String');
% create arduino object and connect to board
if exist('a','var') && isa(a,'arduino') && isvalid(a),
    % nothing to do    
else
    a=arduino(usbPort);
end



% --- Executes on button press in rotorButton.
function rotorButton_Callback(hObject, eventdata, handles)
% hObject    handle to rotorButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global a;
global rotorSpeed;
global M1_PWM;
rotorSpeed = str2double(get(handles.rotorText,'String'))/2000;
analogWrite(a,M1_PWM,round(rotorSpeed*255));



% --- Executes on button press in waveButton.
function waveButton_Callback(hObject, eventdata, handles)
% hObject    handle to waveButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global runStepper;
runStepper = 1;



% --- Executes on selection change in popupmenu3.
function popupmenu3_Callback(hObject, eventdata, handles)
% hObject    handle to popupmenu3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns popupmenu3 contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popupmenu3


% --- Executes during object creation, after setting all properties.
function popupmenu3_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popupmenu3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in popupmenu4.
function popupmenu4_Callback(hObject, eventdata, handles)
% hObject    handle to popupmenu4 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns popupmenu4 contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popupmenu4


% --- Executes during object creation, after setting all properties.
function popupmenu4_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popupmenu4 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function usbPort_Callback(hObject, eventdata, handles)
% hObject    handle to usbPort (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of usbPort as text
%        str2double(get(hObject,'String')) returns contents of usbPort as a double


% --- Executes during object creation, after setting all properties.
function usbPort_CreateFcn(hObject, eventdata, handles)
% hObject    handle to usbPort (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on slider movement.
function ampSlider_Callback(hObject, eventdata, handles)
% hObject    handle to ampSlider (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider
global wave_amp;
wave_amp = get(hObject,'Value')
max_amp = 45;
set(handles.ampText, 'String', round(wave_amp*100*max_amp)/100);


% --- Executes during object creation, after setting all properties.
function ampSlider_CreateFcn(hObject, eventdata, handles)
% hObject    handle to ampSlider (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end


% --- Executes on slider movement.
function freqSlider_Callback(hObject, eventdata, handles)
% hObject    handle to freqSlider (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider
global wave_freq;
wave_freq = get(hObject,'Value')
set(handles.freqText, 'String', round(wave_freq*100)/100);


% --- Executes during object creation, after setting all properties.
function freqSlider_CreateFcn(hObject, eventdata, handles)
% hObject    handle to freqSlider (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end


% --- Executes on button press in resetButton.
function resetButton_Callback(hObject, eventdata, handles)
% hObject    handle to resetButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global a;
global run;
global loop;
global step_tot;
global gen;
global step;
global enc;
global pot;
global yTime;
global mot;
global curr;
global pow;

mot = [0; 0];
enc = [0; 0];
gen = [0; 0];
curr = [0; 0];
pow = [0; 0];
step = [0; 0];
pot = [0; 0];
yTime = [0; 0];

% clear the plot
if(exist('data','var'))
    clf(data, 'reset');
end
 
set(motor,'XData',yTime,'YData',mot);
set(encoder,'XData',yTime,'YData',enc);
set(generator,'XData',yTime,'YData',gen);
set(potentiometer,'XData',yTime,'YData',pot);
set(power,'XData',yTime,'YData',pow);
set(current,'XData',yTime,'YData',curr);
