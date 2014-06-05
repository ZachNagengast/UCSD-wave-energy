function []=simulation(wave_freq,ang_mag,omega_rotor,time_elapsed)
%Simulate Wave Generator Inner Gimabal Motion
%simulation(wave frequency Hz, wave magnitude meter, rotor speed rpm)
%(Simulation code should have frequency of   0.1-0.4 Hz to simulate the realistic wave)

% Consider this frequencies
%If  abs(tau_wave*cos)<tau_gen                     Gen1(0.21)   Gen2(0.06)      No movement
%if  tau_gen<abs(tau_wave*cos)<4*tau_gen           Gen1(0.39)   Gen2(1.13)      Rotate some degree ish in one way and stop
%if  4*tau_gen<abs(tau_wave*cos)<10*tau_gen        Gen1(0.69)   Gen2(0.22)      Oscillate at some angle
%if  10*tau_gen<abs(tau_wave*cos)< 12* tau_gen     Gen1(0.79)   Gen 2(0.25)     moves in one direction but stops after certain time
%if  12*tau_gen<abs(tau_wave*cos) <30* tau_gen     Gen1(1.25)   Gen2(0.78)      going in one direction  w a little of oscilation


%conversion factors
in_m = .0254;           %multiply inches to get meters, divide meters to get inches
rpm_radps = 2*pi/60;    %multiply rpm to get rad/s, divide rad/s to get rpm
g = 9.81;               %m/s^2

%Initialize known variables
r = 6;                  %in
thick = .25;            %in
density = 1400;         %kg/m^3 acrylic from http://www.avlandesign.com/density_construction.htm
wave_period = 1/wave_freq; %seconds
%Required Generator Information /consider listed below
%(Generator 1  -  12V, 0.2A, 4100 RPM,   will give   Tau_o=0.0056)
%(Generator 2  - 12V, 0.025A, 5500 RPM,  will give   Tau_o=0.00052)
RPM_noload=4100;
V_noload=12;
I_noload=0.2;
R_gr=3;
%Convert radius and thickness
r = r*in_m;             %m
thick = thick*in_m;     %m

%Resulting parameters
area = pi*r^2;          %m^2
volume = area*thick;    %m^3
m = volume*density;     %kg
Iz = .5*m*r^2;         %kgm^2
Iy = .5*Iz    ;         %kgm^2
Ix = Iy;                %kgm^2

%Initial conditions
theta_inner = 0;        %rad
omega_inner = 0;        %rad/s

%wave input
dt = 0.01;              %time step
time = 0:dt:time_elapsed;       %seconds

%Equation for the Angular Acceleration for the wave simulator
alpha_outer=ang_mag*(2*pi/wave_period)^2*sin(2*pi/wave_period*time);

%Euler method - omega_inner = omega_gyro + omega_initial
for n=1:length(alpha_outer)-1
    %resistive torque from generator
    tau_gen=R_gr*V_noload*I_noload/(RPM_noload*rpm_radps);
    
    %Torque generated from the wave
    tau_wave(n) = Ix*alpha_outer(n)*(cos(theta_inner(n)))^2;
   
    %if statements for different conditions,  General function is 
    if abs(tau_wave(n)*cos(theta_inner(n))) >= tau_gen          %%torque of wave greater than resistance from the generator
        if ((omega_inner(n) >= 0) &&  (alpha_outer(n)>0))      %speed up positive rotation
            omega_inner(n+1) = omega_inner(n) + (abs(tau_wave(n)*cos(theta_inner(n)))-tau_gen)/(Iz*omega_rotor*rpm_radps);
            
        elseif ((omega_inner(n) > 0) &&  (alpha_outer(n)<0) )  %slow down positive rotation
            omega_inner(n+1) = omega_inner(n) - (abs(tau_wave(n)*cos(theta_inner(n)))+tau_gen)/(Iz*omega_rotor*rpm_radps);
            
        elseif ((omega_inner(n) <= 0) &&  (alpha_outer(n)<0) )   %speed up negative rotation
            omega_inner(n+1) = omega_inner(n) - (abs(tau_wave(n)*cos(theta_inner(n)))-tau_gen)/(Iz*omega_rotor*rpm_radps);
            
        else                                                    %slow down negative rotation
            omega_inner(n+1) = omega_inner(n) + (abs(tau_wave(n)*cos(theta_inner(n)))+tau_gen)/(Iz*omega_rotor*rpm_radps);
            
        end
         
    elseif tau_wave(n)*cos(theta_inner(n)) == 0                 %%no wave torque
        if omega_inner(n) > 0                                   %slows down positive rotation
            omega_inner(n+1) = omega_inner(n) - tau_gen/(Iz*omega_rotor*rpm_radps);
            
        elseif omega_inner(n) < 0                               %slows down negative rotation
            omega_inner(n+1) = omega_inner(n) + tau_gen/(Iz*omega_rotor*rpm_radps);
            
        else
            omega_inner(n+1) = omega_inner(n);                  %keeps resting at 0
        end
        
    elseif abs(tau_wave(n)*cos(theta_inner(n))) < tau_gen       %%torque from the wave is smaller than resistance torque from generator
        if ((omega_inner(n) < 0) &&  (alpha_outer(n)>0) )       %slows down negative rotation resisting both torques
            omega_inner(n+1) = omega_inner(n) + (abs(tau_wave(n)*cos(theta_inner(n)))+tau_gen)/(Iz*omega_rotor*rpm_radps);
            
        elseif ((omega_inner(n) < 0) &&  (alpha_outer(n)<0) )   %slows down negative rotation resisting the difference in torque
            omega_inner(n+1) = omega_inner(n) - (abs(tau_wave(n)*cos(theta_inner(n)))-tau_gen)/(Iz*omega_rotor*rpm_radps);
            
        elseif ((omega_inner(n) > 0) &&  (alpha_outer(n)>0) )   %slows down positive rotation resisting the difference in torque
            omega_inner(n+1) = omega_inner(n) + (abs(tau_wave(n)*cos(theta_inner(n)))-tau_gen)/(Iz*omega_rotor*rpm_radps);
            
        elseif ((omega_inner(n) > 0) &&  (alpha_outer(n)<0) )   %slows down positive rotation resisting both torques
            omega_inner(n+1) = omega_inner(n) - (abs(tau_wave(n)*cos(theta_inner(n)))+tau_gen)/(Iz*omega_rotor*rpm_radps);
            
        else                                                    %keeps at stationary position
            omega_inner(n+1) = omega_inner(n);
        end
    end
      
    theta_inner(n+1) = theta_inner(n)+omega_inner(n)*dt;
end

theta_inner=theta_inner*180/pi;
%plot angular position and velocity
hold on
subplot(2,1,1);plot(time,theta_inner);title('Inner Gimbal Position')
ylabel('Position, deg')
hold on
subplot(2,1,2);plot(time,omega_inner);title('Inner Gimbal Velocity');
xlabel('Time, sec');ylabel('Velocity, rad/sec')

display(tau_gen);
display(max(tau_wave));
display(min(tau_wave))
display(Iz*omega_rotor);
%Yields total energy generated in Joules
energy = sum(abs(tau_gen*omega_inner*dt))
ave_power = energy/time_elapsed
end


% end
%desired rotor speed - sqrt(2)/2 * omega_inner