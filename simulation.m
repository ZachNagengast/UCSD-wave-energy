function [array, array2]=simulation(wave_freq,wave_mag,omega_rotor,time_elapsed)
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



% for i = 0:10:omega_rotor
alpha_outer = ((2*pi/wave_period)^4)*(wave_mag/g)* ...  %derivation eq 89 in paper
    sin(2*pi*time/wave_period);   %array of accelerations outer gimbal over time

GR = .5;
%Euler method - omega_inner = omega_gyro + omega_initial
for n=1:length(alpha_outer)-1
    %resistive torque from generator
    if omega_inner(n) > 4100*rpm_radps
        tau_gen=0;
    else
    tau_gen = .292 - .292*omega_inner(n)/(4100*rpm_radps);
    end
    tau_gen = tau_gen*GR;
    tau_wave(n) = Ix*alpha_outer(n)*(cos(theta_inner(n)))^2;
    %if statements for different conditions
    if abs(tau_wave(n)) >= tau_gen     %torque of wave greater than resistance
        if alpha_outer(n) > 0              %speed up positive rotation
            omega_inner(n+1) = omega_inner(n) + (tau_wave(n)/cos(theta_inner(n))-tau_gen)/(Iz*omega_rotor*rpm_radps);
            
        elseif alpha_outer(n) < 0          %speed up negative rotation
            omega_inner(n+1) = omega_inner(n) + (tau_wave(n)/cos(theta_inner(n))+tau_gen)/(Iz*omega_rotor*rpm_radps);
        end
        
    elseif tau_wave(n) == 0            %no wave torque
        if omega_inner(n) > 0       %slows down positive rotation
            omega_inner(n+1) = omega_inner(n) - tau_gen/(Iz*omega_rotor*rpm_radps*cos(theta_inner(n)));
            
        elseif omega_inner(n) < 0   %slows down negative rotation
            omega_inner(n+1) = omega_inner(n) + tau_gen/(Iz*omega_rotor*rpm_radps*cos(theta_inner(n)));
            
        else
            omega_inner(n+1) = omega_inner(n);  %keeps rotation at 0
        end
        
    elseif abs(tau_wave(n)) < tau_gen
        if omega_inner(n) == 0  %keeps rotation at 0
            omega_inner(n+1) = omega_inner(n);
            
        elseif omega_inner(n) > 0   %slows down positive rotation
            omega_inner(n+1) = omega_inner(n) + (tau_wave(n)/cos(theta_inner(n))-tau_gen)/(Iz*omega_rotor*rpm_radps);
            
        else                        %slows down negative rotation
            omega_inner(n+1) = omega_inner(n) + (tau_wave(n)/cos(theta_inner(n))+tau_gen)/(Iz*omega_rotor*rpm_radps);
        end
    end
               
    theta_inner(n+1) = theta_inner(n)+omega_inner(n)*dt;
end

%plot angular position and velocity
hold on
subplot(2,1,1);plot(time,theta_inner);title('Inner Gimbal Position')
ylabel('Position, rad')
hold on
subplot(2,1,2);plot(time,omega_inner);title('Inner Gimbal Velocity');
xlabel('Time, sec');ylabel('Velocity, rad/sec')

array = theta_inner;
array2 = omega_inner;
% end
%desired rotor speed - sqrt(2)/2 * omega_inner