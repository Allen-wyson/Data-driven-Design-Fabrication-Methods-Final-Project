@ -1,99 +0,0 @@
%% Bayesian workflow with persistent seeds & 10-run stopping
clc; clear; close all;

%% 1) Define parameter spaces
radialVals = (5:1:15)';      % possible radial thread counts
spiralVals = (5:1:15)';      % possible spiral thread counts
drVals     = (2.5:0.5:4.0)'; % possible dr values
dsVals     = (0.5:0.5:2.0)'; % possible ds values

vars = [
    optimizableVariable('radialIdx',[1,numel(radialVals)], 'Type','integer')
    optimizableVariable('spiralIdx',[1,numel(spiralVals)], 'Type','integer')
    optimizableVariable('drIdx',    [1,numel(drVals)],     'Type','integer')
    optimizableVariable('dsIdx',    [1,numel(dsVals)],     'Type','integer')
];

%% 2) Load or generate 6 initial LHS seed points
nInit    = 6;
seedFile = 'initialSeeds.mat';

if exist(seedFile,'file')
    load(seedFile,'initTable');
    fprintf('Loaded existing %s (6 seed points)\n', seedFile);
else
    % Generate a 6×4 table of initial sample indices
    initTable = generateInitialSamples(radialVals,spiralVals,drVals,dsVals,nInit);
    save(seedFile,'initTable');
    fprintf('Generated & saved %s with 6 seed points\n', seedFile);
end

% At this point, size(initTable) is [6,4]

%% 3) Prompt user for observed strength/weight (negated for maximization)
f0 = zeros(nInit,1);
for i = 1:nInit
    r   = radialVals( initTable.radialIdx(i) );
    s   = spiralVals( initTable.spiralIdx(i) );
    drv =     drVals( initTable.drIdx(i) );
    dsv =     dsVals( initTable.dsIdx(i) );

    fprintf('\nInitial sample %d:\n', i);
    fprintf('  radialThreads = %d\n', r);
    fprintf('  spiralThreads = %d\n', s);
    fprintf('  dr            = %.2f\n', drv);
    fprintf('  ds            = %.2f\n', dsv);
    raw = input('Enter measured strength/weight for this sample: ');
    f0(i) = -raw;   % negate so bayesopt maximizes the original ratio
end

%% 4) Run Bayesian optimization (10 total evaluations including seeds)
results = bayesopt( ...
    @(x)objectiveManual(x,radialVals,spiralVals,drVals,dsVals), ...
    vars, ...
    'InitialX',              initTable, ...
    'InitialObjective',      f0, ...
    'NumSeedPoints',         nInit, ...
    'MaxObjectiveEvaluations', 10, ...      
    'AcquisitionFunctionName','expected-improvement-plus', ...
    'ExplorationRatio',      0.9, ...
    'PlotFcn',{@plotAcquisitionFunction,@plotObjectiveModel,@plotMinObjective} ...
);

%% 5) Objective function: prompt only for new points
function f = objectiveManual(x,radialVals,spiralVals,drVals,dsVals)
    r   = radialVals(x.radialIdx);
    s   = spiralVals(x.spiralIdx);
    drv =     drVals(x.drIdx);
    dsv =     dsVals(x.dsIdx);

    fprintf('\n--- Next design to evaluate ---\n');
    fprintf('  radialThreads = %d\n', r);
    fprintf('  spiralThreads = %d\n', s);
    fprintf('  dr            = %.2f\n', drv);
    fprintf('  ds            = %.2f\n', dsv);

    raw = input('Run simulation and enter measured strength/weight: ');
    f   = -raw;  % negate to maximize original ratio
end

%% Local function: generate LHS seed table
function initTable = generateInitialSamples(radialVals,spiralVals,drVals,dsVals,nSamples)
% GENERATEINITIALSAMPLES Uses Latin Hypercube Sampling to create a
% nSamples×4 table of indices: radialIdx, spiralIdx, drIdx, dsIdx

    % Create normalized LHS matrix
    lhsM = lhsdesign(nSamples, 4);

    % Map to integer indices for each parameter
    radialIdx = ceil(lhsM(:,1) * numel(radialVals));
    spiralIdx = ceil(lhsM(:,2) * numel(spiralVals));
    drIdx     = ceil(lhsM(:,3) * numel(drVals));
    dsIdx     = ceil(lhsM(:,4) * numel(dsVals));

    % Combine into a table
    initTable = table( ...
        radialIdx, spiralIdx, drIdx, dsIdx, ...
        'VariableNames',{'radialIdx','spiralIdx','drIdx','dsIdx'} ...
    );
end