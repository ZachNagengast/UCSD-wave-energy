%Simulate Wave Generator Motion

%Kevin - eventually we'll want to make it a function but to make sure it
%works now, I'll start by leaving it a script.  Makin it a function later
%should be easy

%conversion factors
in_m = .0254;           %multiply inches to get meters, divide meters to get inches
rpm_radps = 2*pi*60;    %multiply rpm to get rad/s, divide rad/s to get rpm

%Initialize known variables
r = 6;                  %in
thick = .25;            %in
density = 1400;         %kg/m^3 acrylic from http://www.avlandesign.com/density_construction.htm
omega_rotor = 3000;     %rpm
wave_f = 1;             %Hz
wave_mag = 1;           %m

%Convert radius and thickness
r = r*in_m;
thick = thick*in_m;

%Resulting parameters
area = pi*r^2;          %m^2
volume = area*thick;    %m^3
m = volume*density;     %kg
Iz = .5*m*r^2;          %kgm^2
Iy = .5*Iz;             %kgm^2
Ix = Iy;                %kgm^2

%Initial conditions
theta_inner = 0;        %rad
omega_inner = 0;        %rad/s

