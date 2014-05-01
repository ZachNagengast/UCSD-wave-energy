function simulation(wave_freq,wave_mag,omega_rotor,time_elapsed)
%Simulate Wave Generator Inner Gimabal Motion
%simulation(wave frequency Hz, wave magnitude meter, rotor speed rpm)

%conversion factors
in_m = .0254;           %multiply inches to get meters, divide meters to get inches
rpm_radps = 2*pi/60;    %multiply rpm to get rad/s, divide rad/s to get rpm
g = 9.81;               %m/s^2

%Initialize known variables
r = 6;                  %in
thick = .25;            %in
density = 1400;         %kg/m^3 acrylic from http://www.avlandesign.com/density_construction.htm
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
time = 0:dt:time_elapsed;       %seconds
alpha_outer = ((2*pi/wave_period)^4)*(wave_mag/g)* ...  %derivation eq 89 in paper
    sin(2*pi*time/wave_period);   %array of accelerations outer gimbal over time

dalpha_outer = ((2*pi/wave_period)^5)*(wave_mag/g)* ...  
    cos(2*pi*time/wave_period);

%Euler method - omega_inner = omega_gyro + omega_initial
for n=1:length(alpha_outer)-1
    omega_inner(n+1) = abs(alpha_outer(n))/(2*omega_rotor*rpm_radps)+omega_inner(n);
    if omega_inner(n+1) > 2*pi*wave_freq
        omega_inner(n+1) = 2*pi*wave_freq;
    end
end
for n=1:length(omega_inner)-1
    theta_inner(n+1) = theta_inner(n)+omega_inner(n)*dt;
end

%plot angular position and velocity
plot(time,omega_inner,time,theta_inner,'r')
title('Inner Gimbal Position and Velocity')
xlabel('Time, sec'); ylabel('Position, rad & Velocity, rad/sec')
legend('Velocity','Position')

%desired rotor speed - sqrt(2)/2 * omega_inner