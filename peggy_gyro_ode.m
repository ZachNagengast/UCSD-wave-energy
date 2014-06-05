% Simple Gyro Equation of Motion Solution

%% Function for theta

function dthphidt = peggy_gyro_ode(t,x)
psip = 60; %rad/s
J3c = 4; %twice as J1c for disk
J1c = 2; 
dthphidt = zeros(4,1); %initialize
dthphidt(1) = x(2);
dthphidt(2) = (2*x(2)*x(4)*(J3c-J1c)*cos(x(3))*sin(x(3))+x(4)*psip*J3c*sin(x(3)))/(J1c*(sin(x(3)))^2+J3c*(cos(x(3)))^2);
dthphidt(3) = x(4);
dthphidt(4) = (-(x(2))^2*(J3c-J1c)*cos(x(3))*sin(x(3))+x(4)*psip*J1c*sin(x(3))-x(2)*psip*J3c*sin(x(3)))/J1c;

% [t,x] = ode45(@peggy_gyro_ode ,[0 5], [0 pi/90 pi/2 0]);
% plot(t,x(:,3),t,x(:,1))
% plot(t,x(:,4),t,x(:,2))


% psip = constant