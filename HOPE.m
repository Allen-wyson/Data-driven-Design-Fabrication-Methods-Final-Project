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

%% 2) Load or generate 4 initial LHS seed points
nInit    = 4;
seedFile = 'initialSeeds.mat';
if exist(seedFile,'file')
    load(seedFile,'initTable');
    fprintf('Loaded existing %s (4 seed points)\n', seedFile);
else
    initTable = generateInitialSamples(radialVals,spiralVals,drVals,dsVals,nInit);
    save(seedFile,'initTable');
    fprintf('Generated & saved %s with 4 seed points\n', seedFile);
end

%% 3) Prompt user for the 4 seed measurements (negated for maximization)
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

%% 4) Set up segment breakpoints and decaying ratios
segmentTotals    = [8, 12, 16, 20];           % cumulative eval counts
explorationRatio = [0.90, 0.64, 0.38, 0.10];   % per segment

results = [];

for seg = 1:numel(segmentTotals)
    totEvals = segmentTotals(seg);
    ratio    = explorationRatio(seg);
    
    if seg == 1
        % First segment: seed + new points
        results = bayesopt( ...
            @(x)objectiveManual(x,radialVals,spiralVals,drVals,dsVals), ...
            vars, ...
            'InitialX',                   initTable, ...
            'InitialObjective',           f0, ...
            'MaxObjectiveEvaluations',    totEvals, ...
            'AcquisitionFunctionName',    'expected-improvement-plus', ...
            'ExplorationRatio',           ratio, ...
            'Verbose',                    0 ...
        );
        toDo = totEvals - nInit;
    else
        % Resume previous optimization
        currentCount = size(results.XTrace,1);
        toDo = totEvals - currentCount;
        results = resume( ...
            results, ...
            'MaxObjectiveEvaluations',    toDo, ...
            'AcquisitionFunctionName',    'expected-improvement-plus', ...
            'ExplorationRatio',           ratio, ...
            'Verbose',                    0 ...
        );
    end
    
    fprintf('\n=== After segment %d (total evals=%d, ER=%.2f) ===\n', seg, totEvals, ratio);
    newPts = results.XTrace(end-toDo+1:end, :);
    disp(newPts);
    
    % Check for duplicates
    [G,~,~] = findgroups(results.XTrace.radialIdx, ...
                         results.XTrace.spiralIdx, ...
                         results.XTrace.drIdx, ...
                         results.XTrace.dsIdx);
    dupGroups = find(accumarray(G,1) > 1);
    if ~isempty(dupGroups)
        fprintf('Warning: repeated design(s) detected in segment %d:\n', seg);
        for g = dupGroups'
            rows = find(G==g);
            disp(results.XTrace(rows,:));
        end
    end
end

%% 5) Final report
bestX = results.XAtMinObjective;
bestF = results.MinObjective;
optStrength = -bestF;

rOpt  = radialVals(bestX.radialIdx);
sOpt  = spiralVals(bestX.spiralIdx);
drOpt = drVals(   bestX.drIdx);
dsOpt = dsVals(   bestX.dsIdx);

fprintf('\n** Optimal design found **\n');
fprintf('  radialThreads = %d\n', rOpt);
fprintf('  spiralThreads = %d\n', sOpt);
fprintf('  dr            = %.2f\n', drOpt);
fprintf('  ds            = %.2f\n', dsOpt);
fprintf('  Measured strength/weight = %.4f\n', optStrength);

%% 6) Objective function with duplicate filtering
function f = objectiveManual(x, radialVals, spiralVals, drVals, dsVals)
    % Track evaluated points using persistent Map
    persistent history
    if isempty(history)
        history = containers.Map();
    end

    key = sprintf('%d_%d_%d_%d', x.radialIdx, x.spiralIdx, x.drIdx, x.dsIdx);
    if isKey(history, key)
        fprintf('⚠️  Duplicate configuration detected. Skipping this point.\n');
        f = 1e6;  % Penalize duplicates
        return;
    end

    history(key) = true;

    % Extract real values and prompt
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

%% 7) Latin Hypercube seed generator
function initTable = generateInitialSamples(radialVals,spiralVals,drVals,dsVals,nSamples)
    lhsM = lhsdesign(nSamples, 4);
    radialIdx = ceil(lhsM(:,1) * numel(radialVals));
    spiralIdx = ceil(lhsM(:,2) * numel(spiralVals));
    drIdx     = ceil(lhsM(:,3) * numel(drVals));
    dsIdx     = ceil(lhsM(:,4) * numel(dsVals));
    initTable = table(radialIdx, spiralIdx, drIdx, dsIdx, ...
        'VariableNames',{'radialIdx','spiralIdx','drIdx','dsIdx'});
end