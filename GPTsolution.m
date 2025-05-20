clc; clear; close all;

%% Define parameter spaces
radialVals = (5:1:15)';
spiralVals = (5:1:15)';
drVals     = (2.5:0.5:4.0)';
dsVals     = (0.5:0.5:2.0)';

vars = [
    optimizableVariable('radialIdx',[1,numel(radialVals)], 'Type','integer')
    optimizableVariable('spiralIdx',[1,numel(spiralVals)], 'Type','integer')
    optimizableVariable('drIdx',    [1,numel(drVals)],     'Type','integer')
    optimizableVariable('dsIdx',    [1,numel(dsVals)],     'Type','integer')
];

%% Load or generate initial seed points
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
    f0(i) = -raw;
end

%% Sequential bayesopt phases with decreasing exploration
explorationLevels = [0.9, 0.6, 0.3, 0.1];
prevX = initTable;
prevF = f0;

for phase = 1:length(explorationLevels)
    fprintf('\n=== Phase %d: ExplorationRatio = %.1f ===\n', phase, explorationLevels(phase));
results = bayesopt( ...
    @(x)objectiveManual(x,radialVals,spiralVals,drVals,dsVals), ...
    vars, ...
    'InitialX',             prevX, ...
    'InitialObjective',     prevF, ...
    'MaxObjectiveEvaluations', size(prevX,1) + 4, ...
    'ExplorationRatio',     explorationLevels(phase), ...
    'AcquisitionFunctionName','expected-improvement-plus', ...
    'PlotFcn', {} ...
);
    % Extract all evaluated points and scores
    T = results.XTrace;
    scores = results.ObjectiveTrace;

    prevX = T;
    prevF = scores;
end

%% Final plot and output
figure;
plot(prevF, '-o'); title('Objective Value per Evaluation');
xlabel('Evaluation'); ylabel('Negated Strength/Weight');

[~,bestIdx] = min(prevF);
bestDesign = prevX(bestIdx,:);

fprintf('\n=== Best Design Found ===\n');
fprintf('  radialThreads = %d\n', radialVals(bestDesign.radialIdx));
fprintf('  spiralThreads = %d\n', spiralVals(bestDesign.spiralIdx));
fprintf('  dr            = %.2f\n', drVals(bestDesign.drIdx));
fprintf('  ds            = %.2f\n', dsVals(bestDesign.dsIdx));

