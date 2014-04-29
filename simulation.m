%Simulate Wave Generator Motion

%Kevin - eventually we'll want to make it a function but to make sure it
%works now, I'll start by leaving it a script.  Makin it a function later
%should be easy
%unsure of how inertia plays into equations based on Anderson's derivation
%seems like it's only ratio of inerta?

%conversion factors
in_m = .0254;           %multiply inches to get meters, divide meters to get inches
rpm_radps = 2*pi/60;    %multiply rpm to get rad/s, divide rad/s to get rpm
g = 9.81;               %m/s^2

%Initialize known variables
r = 6;                  %in
thick = .25;            %in
density = 1400;         %kg/m^3 acrylic from http://www.avlandesign.com/density_construction.htm
omega_rotor = 3000;     %rpm
wave_freq = .125;       %Hz *** I used same parameters as in paper from Oscar
wave_mag = 1.5;         %m
wave_period = 1/wave_freq; %seconds

%Convert radius and thickness
r = r*in_m;             %m
thick = thick*in_m;     %m

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

%wave input
dt = 0.01;              %time step
time = 0:dt:100;       %seconds
alpha_outer = ((2*pi/wave_period)^4)*(wave_mag/g)* ...  %derivation eq 89 in paper
    sin(2*pi*time/wave_period);   %array of accelerations outer gimbal over time

% %try 1 - omega_inner = omega_gyro + omega_initial
% for n=1:length(alpha_outer)-1
%     omega_inner1(n+1) = alpha_outer(n)/(2*omega_rotor*rpm_radps)+omega_inner1(n);
% end
% theta_inner1(1)=0;
% for n=1:length(omega_inner)-1
%     theta_inner1(n+1) = theta_inner1(n)+omega_inner1(n)*dt;
% end

%try 2 - dtheta method
dtheta_inner = alpha_outer/(2*omega_rotor*rpm_radps) * dt;
for n=1:length(alpha_outer)-1
    theta_inner(n+1) = theta_inner(n)+omega_inner(n)*dt;
    omega_inner(n+1) = abs(alpha_outer(n))/(2*omega_rotor*rpm_radps*abs(cos(theta_inner(n))));
end
