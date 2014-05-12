% PROGRAMMER: ARDAVAN AMINI
% 
% INPUTS: Start-Torque, Brush Voltage Loss, Currents and Voltages at a
%         Fixed Rotational Speed, Currents and Voltages Under a Specified 
%         Load, Currents and Voltages with Varying Rotational Speed (Under 
%         Previous Specified Load)
% OUTPUTS: Internal Resistance, External Resistance, Power Input/Output,
%          Torque to Drive Generator, Plots
%
% Ru=External Resistance / Ri=Internal Resistance / phi=Magnetic Flux Const
% U=Voltage / I=Current / T=Torque to Drive Generator / L=Losses /
% T0=Torque to Overcome Losses / Ub=Voltage Brush Losses
%
clear, clc
T0=input('Enter the Start-Torque of the Generator [N*m]: '); % test .045
Ub=input('Enter the Voltage Losses [V]: '); % test .1
% Tests Using Rheostat [To Find Ri]
% Example Matrices
  U=[5.38,5.26,5.19,5.05,4.9,4.625,4.26,4.1,3.88,3.55,3.1,2.75,2.25,1.75];
  I=[0,.5,.97,2,2.64,4,5.9,6.95,8.16,10.25,12.8,14.15,16.9,19.3];
PRi=polyfit(I,U,1);
Ri=abs(PRi(1));
% Tests with Specific Load [To Find Ru]    **Ru is dependent on load
% Example Matrices
  Uu=[.42,.99,1.55,2.14,2.65,3.21];
  Iu=[1.4,3,4.75,6.8,8.15,10];
PRu=polyfit(Iu,Uu,1);
Ru=abs(PRu(1));
% Polyfit Coefficients
% Plotting of Constants
figure(1)
subplot(1,2,1)
plot(I,U,'o',I,PRi(1)*I+PRi(2))
xlabel('Current [A]'); ylabel('Voltage [V]')
title('Internal Resistance Ri [\Omega]')
subplot(1,2,2)
plot(Iu,Uu,'o',Iu,PRu(1)*Iu+PRu(2))
xlabel('Current [A]'); ylabel('Voltage [V]')
title('External Resistance Ru [\Omega]')
% Calculation of Phi using voltage & current with varying speed and a
% constant load
% Example Matrices
  wgen=[437.5,850,1125,1600,1990,2375];
  Igen=[1.32,2.89,4.69,6.86,8.125,10];
  Ugen=[.475,.99,1.55,2.12,2.625,3.19];
phi=(Ugen+Igen*Ri+Ub)./(wgen*(2*pi()/60));
phi=sum(phi)/length(phi);
% Power / efficiency
P_elec=((phi*wgen*(2*pi()/60)-Ub)/(Ru+Ri)).^2*Ru;
P_mech=(phi*((phi*wgen*(2*pi()/60)-Ub)/(Ru+Ri))+T0).*wgen*(2*pi()/60);
eff=P_elec./P_mech*100;
T=phi*Igen+T0; % THE TORQUE
% Polyfit Coefficients
PUgen=polyfit(wgen,Ugen,1);
PIgen=polyfit(wgen,Igen,1);
Ppower=polyfit(wgen,P_elec,2);
Ptq=polyfit(wgen,T,1);
% Plots
figure(2)
subplot(2,2,1)
plot(wgen,Ugen,'o',wgen,PUgen(1)*wgen+PUgen(2))
xlabel('Rotational Speed [rpm]'); ylabel('Voltage [V]');
title('Rotational Speed vs. Voltage Under Certain Load')
subplot(2,2,2)
plot(wgen,Igen,'o',wgen,PIgen(1)*wgen+PIgen(2))
xlabel('Rotational Speed [rpm]'); ylabel('Current [A]');
title('Rotational Speed vs. Current Under Certain Load')
subplot(2,2,3)
plot(wgen,P_elec,'o',wgen,Ppower(1)*wgen.^2+Ppower(2)*wgen+Ppower(3))
xlabel('Rotational Speed [rpm]'); ylabel('Electrical Power [W]');
title('Rotational Speed vs. Power Generation')
subplot(2,2,4)
plot(wgen,T,'o',wgen,Ptq(1)*wgen+Ptq(2))
xlabel('Rotational Speed [rpm]'); ylabel('Torque [N*m]');
title('Rotational Speed vs. Torque to Drive Generator')
