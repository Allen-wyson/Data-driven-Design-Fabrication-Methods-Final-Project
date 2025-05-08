%% Bayesian workflow with persistent seeds & 30-run stopping
clc; clear; close all;

%% 1) Define your discrete/continuous parameter spaces
radialVals = (5:1:15)';      % possible radial thread counts
spiralVals = (5:1:15)';      % possible spiral thread counts
drVals     = (2.5:0.5:4.0)'; % discrete dr values
dsVals     = (0.5:0.5:2.0)'; % discrete ds values

vars = [
    optimizableVariable('radialIdx',[1,numel(radialVals)], 'Type','integer')
    optimizableVariable('spiralIdx',[1,numel(spiralVals)], 'Type','integer')
    optimizableVariable('drIdx',    [1,numel(drVals)],     'Type','integer')
    optimizableVariable('dsIdx',    [1,numel(dsVals)],     'Type','integer')
];

%% 2) Load or generate-and-save 6 initial LHS seeds
nInit = 6;
seedFile = 'initialSeeds.mat';
if exist(seedFile,'file')
    load(seedFile,'initTable');
    fprintf('Loaded existing %s (6 seed points)\n', seedFile);
else
    rng(1234);  % fixed RNG seed for reproducibility
    lhsM = lhsdesign(nInit, numel(vars));
    initTable = table( ...
      ceil(lhsM(:,1)*numel(radialVals)), ...
      ceil(lhsM(:,2)*numel(spiralVals)), ...
      ceil(lhsM(:,3)*numel(drVals)), ...
      ceil(lhsM(:,4)*numel(dsVals)), ...
      'VariableNames',{'radialIdx','spiralIdx','drIdx','dsIdx'} ...
    );
    save(seedFile,'initTable');
    fprintf('Generated & saved %s with 6 seed points\n', seedFile);
end

%% 3) Prompt once for those 6 seed evaluations
f0 = zeros(nInit,1);
for i = 1:nInit
    r  = radialVals( initTable.radialIdx(i) );
    s  = spiralVals( initTable.spiralIdx(i) );
    dr =     drVals( initTable.drIdx(i) );
    ds =     dsVals( initTable.dsIdx(i) );
    fprintf('\nInitial sample %d:\n', i);
    fprintf('  radialThreads = %d\n', r);
    fprintf('  spiralThreads = %d\n', s);
    fprintf('  dr            = %.2f\n', dr);
    fprintf('  ds            = %.2f\n', ds);
    f0(i) = input('Enter measured strength/weight for this sample: ');
end

%% 4) Run Bayesian Optimization (total 30 runs including the 6 seeds)
results = bayesopt( ...
    @(x)objectiveManual(x,radialVals,spiralVals,drVals,dsVals), ...
    vars, ...
    'InitialX',         initTable, ...
    'InitialObjective', f0, ...
    'NumSeedPoints',    nInit, ...
    'MaxObjectiveEvaluations', 30, ...      % stop after 30 total
    'AcquisitionFunctionName','expected-improvement-plus', ...
    'ExplorationRatio', 0.9, ...
    'PlotFcn',{@plotAcquisitionFunction,@plotObjectiveModel,@plotMinObjective} ...
);

%% 5) Objective function that only prompts for *new* points
function f = objectiveManual(x,radialVals,spiralVals,drVals,dsVals)
    r  = radialVals( x.radialIdx );
    s  = spiralVals( x.spiralIdx );
    dr =     drVals( x.drIdx     );
    ds =     dsVals( x.dsIdx     );

    fprintf('\n--- Next query design ---\n');
    fprintf('  radialThreads = %d\n', r);
    fprintf('  spiralThreads = %d\n', s);
    fprintf('  dr            = %.2f\n', dr);
    fprintf('  ds            = %.2f\n', ds);
    f = input('Run ANSYS and enter measured strength/weight: ');
end
