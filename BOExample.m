clc; close all; clear ; 
% Set up design parameters
X1 = optimizableVariable('x',[1 10]);
X2 = optimizableVariable('y',[1 20]);
vars = [X1,X2];

% Perform Bayesian Optimization
% results = bayesopt(@getdistance,vars,'AcquisitionFunctionName','expected-improvement-plus')
%results = bayesopt(@getdistance,vars,'AcquisitionFunctionName','expected-improvement-plus', 'ExplorationRatio',0.9, 'NumSeedPoints', 4)
results = bayesopt(@getdistance,vars,'AcquisitionFunctionName','expected-improvement-plus', 'ExplorationRatio',0.9, 'NumSeedPoints', 4, 'PlotFcn',{@plotAcquisitionFunction, @plotObjectiveModel,@plotMinObjective})


% Function to Optimize
function fval = getdistance(in)
x(1) = in.x;
x(2) = in.y;
Z = sin(x(1)) + cos(x(2));
fval = Z;
end

% %
% [X,Y] = meshgrid(1:0.5:10,1:20);
% Z = sin(X) + cos(Y);
% C = X.*Y;
% surf(X,Y,Z,C)
% colorbar
BOExample.m
Displaying BOExample.m.