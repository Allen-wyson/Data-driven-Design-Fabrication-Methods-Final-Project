%% Bayesian optimization in 4 segments with decaying ExplorationRatio
clc; clear; close all;

%% 1) Define parameter spaces
radialVals = (5:15)';      % possible radial thread counts
spiralVals = (5:15)';      % possible spiral thread counts
drVals     = (2.5:0.5:4.0)';% possible dr values
dsVals     = (0.5:0.5:2.0)';% possible ds values

vars = [
  optimizableVariable('radialIdx',[1,numel(radialVals)],'Type','integer')
  optimizableVariable('spiralIdx',[1,numel(spiralVals)],'Type','integer')
  optimizableVariable('drIdx',    [1,numel(drVals)],    'Type','integer')
  optimizableVariable('dsIdx',    [1,numel(dsVals)],    'Type','integer')
];

%% 2) Load/generate seeds and/or previous BO state
nInit      = 4;
seedFile   = 'initialSeeds.mat';
stateFile  = 'bayesState.mat';

if exist(stateFile,'file')
    % Resume from previous state
    load(stateFile,'results','segmentDone');
    fprintf('Resuming from segment %d\n', segmentDone);
else
    % First run: generate or load 4 LHS seeds
    if exist(seedFile,'file')
        load(seedFile,'initTable');
    else
        initTable = generateInitialSamples(radialVals,spiralVals,drVals,dsVals,nInit);
        save(seedFile,'initTable');
    end
    % Prompt for the 4 seed measurements
    f0 = zeros(nInit,1);
    for i = 1:nInit
        r   = radialVals(initTable.radialIdx(i));
        s   = spiralVals(initTable.spiralIdx(i));
        drv = drVals(   initTable.drIdx(i));
        dsv = dsVals(   initTable.dsIdx(i));
        fprintf('Seed %d: r=%d, s=%d, dr=%.2f, ds=%.2f\n', i, r, s, drv, dsv);
        raw = input('  Enter measured strength/weight: ');
        f0(i) = -raw;
    end
    results      = [];
    segmentDone  = 0;
end

%% 3) Set up segment breakpoints & decaying ratios
segmentTotals    = [8, 12, 16, 20];           % cumulative eval counts
explorationRatio = [0.90, 0.64, 0.38, 0.20];   % per segment

%% 4) Run remaining segments
for seg = (segmentDone+1):numel(segmentTotals)
    totEvals = segmentTotals(seg);
    ratio    = explorationRatio(seg);
    
    if seg == 1
        % Build from seeds → first 8 evals
        results = bayesopt( ...
          @(x)objectiveManual(x,radialVals,spiralVals,drVals,dsVals), ...
          vars, ...
          'InitialX',                initTable, ...
          'InitialObjective',        f0, ...
          'MaxObjectiveEvaluations', totEvals, ...
          'AcquisitionFunctionName','expected-improvement-plus', ...
          'ExplorationRatio',       ratio, ...
          'Verbose',                0 ...
        );
        newCount = totEvals - nInit;
    else
        % Resume to reach totEvals
        currentCount = size(results.XTrace,1);
        toDo = totEvals - currentCount;
        results = resume( ...
          results, ...
          'MaxObjectiveEvaluations', toDo, ...
          'AcquisitionFunctionName','expected-improvement-plus', ...
          'ExplorationRatio',       ratio, ...
          'Verbose',                0 ...
        );
        newCount = toDo;
    end
    
    % Display new designs
    fprintf('\n--- Segment %d done (total=%d, ER=%.2f) ---\n', seg, totEvals, ratio);
    disp(results.XTrace(end-newCount+1:end,:));
    
    % Save state so you can resume later without re-running ANSYS
    segmentDone = seg;
    save(stateFile,'results','segmentDone');
end

%% 5) Final report
bestX = results.XAtMinObjective;
bestF = results.MinObjective;
optStrength = -bestF;

rOpt   = radialVals(bestX.radialIdx);
sOpt   = spiralVals(bestX.spiralIdx);
drOpt  = drVals(   bestX.drIdx);
dsOpt  = dsVals(   bestX.dsIdx);

fprintf('\n** Optimal design found **\n');
fprintf('  radialThreads = %d\n', rOpt);
fprintf('  spiralThreads = %d\n', sOpt);
fprintf('  dr            = %.2f\n', drOpt);
fprintf('  ds            = %.2f\n', dsOpt);
fprintf('  Measured strength/weight = %.4f\n', optStrength);

%% Objective function: prompt only for new points
function f = objectiveManual(x,radialVals,spiralVals,drVals,dsVals)
    r   = radialVals(x.radialIdx);
    s   = spiralVals(x.spiralIdx);
    drv = drVals(x.drIdx);
    dsv = dsVals(x.dsIdx);
    fprintf('\n--- Next design to evaluate ---\n');
    fprintf('  radialThreads = %d\n', r);
    fprintf('  spiralThreads = %d\n', s);
    fprintf('  dr            = %.2f\n', drv);
    fprintf('  ds            = %.2f\n', dsv);
    raw = input('Run simulation and enter measured strength/weight: ');
    f   = -raw;
end






