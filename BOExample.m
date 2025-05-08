clc; close all; clear ; 

X1 = optimizableVariable('radialThreads', [5 15], 'Type', 'integer');
X2 = optimizableVariable('spiralThreads', [5 15], 'Type', 'integer');
X3 = optimizableVariable('dr', [2.5 4]);      % diameter of radial thread
X4 = optimizableVariable('ds', [0.5 2]);      % diameter of spiral thread
vars = [X1, X2, X3, X4];

% Perform Bayesian Optimization
% results = bayesopt(@getdistance,vars,'AcquisitionFunctionName','expected-improvement-plus')
%results = bayesopt(@getdistance,vars,'AcquisitionFunctionName','expected-improvement-plus', 'ExplorationRatio',0.9, 'NumSeedPoints', 4)
results = bayesopt(@getdistance,vars,'AcquisitionFunctionName','expected-improvement-plus', 'ExplorationRatio',0.9, 'NumSeedPoints', 4, 'PlotFcn',{@plotAcquisitionFunction, @plotObjectiveModel,@plotMinObjective})


% Function to Optimize
function fval = getdistance(in)
    radialThreads = in.radialThreads;
    spiralThreads = in.spiralThreads;
    dr = in.dr;
    ds = in.ds;

    % Example objective (replace with your real one)
    Z = sin(radialThreads) + cos(spiralThreads) + dr - ds;
    fval = Z;
end


