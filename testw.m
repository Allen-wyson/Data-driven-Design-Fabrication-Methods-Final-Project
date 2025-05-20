%% Bayesian workflow with persistent seeds & 20-run stopping
clc; clear; close all;

%% 1) Define your discrete/continuous parameter spaces
% These are the sets of possible values for each of the design parameters.
radialVals = (5:1:15)';      % Possible radial thread counts
spiralVals = (5:1:15)';      % Possible spiral thread counts
drVals     = (2.5:0.5:4.0)'; % Discrete values for dr (e.g., radial dimension)
dsVals     = (0.5:0.5:2.0)'; % Discrete values for ds (e.g., spiral spacing)

% Define optimizable variables using indices into the discrete value sets.
vars = [
    optimizableVariable('radialIdx',[1,numel(radialVals)], 'Type','integer')
    optimizableVariable('spiralIdx',[1,numel(spiralVals)], 'Type','integer')
    optimizableVariable('drIdx',    [1,numel(drVals)],     'Type','integer')
    optimizableVariable('dsIdx',    [1,numel(dsVals)],     'Type','integer')
];

%% 2) Load or generate-and-save 4 initial LHS seeds
nInit = 4;                      % Number of initial samples
seedFile = 'initialSeeds.mat'; % File for storing/loading initial seeds

% Check if initial seed file already exists
if exist(seedFile,'file')
    load(seedFile,'initTable'); % Load previous seeds
    fprintf('Loaded existing %s (4 seed points)\n', seedFile);
else
    % If not, generate seeds using Latin Hypercube Sampling
    rng(1234);  % Set RNG seed for reproducibility
    lhsM = lhsdesign(nInit, numel(vars)); % Generate LHS matrix
    
    % Convert LHS matrix to discrete index values
    initTable = table( ...
      ceil(lhsM(:,1)*numel(radialVals)), ...
      ceil(lhsM(:,2)*numel(spiralVals)), ...
      ceil(lhsM(:,3)*numel(drVals)), ...
      ceil(lhsM(:,4)*numel(dsVals)), ...
      'VariableNames',{'radialIdx','spiralIdx','drIdx','dsIdx'} ...
    );
    
    save(seedFile,'initTable'); % Save seeds to file
    fprintf('Generated & saved %s with 4 seed points\n', seedFile);
end

%% 3) Prompt once for those 4 seed evaluations
f0 = zeros(nInit,1); % Preallocate for objective values

% Loop through each initial design and prompt the user for the measurement
for i = 1:nInit
    r  = radialVals( initTable.radialIdx(i) );
    s  = spiralVals( initTable.spiralIdx(i) );
    dr =     drVals( initTable.drIdx(i) );
    ds =     dsVals( initTable.dsIdx(i) );
    
    % Display current design
    fprintf('\nInitial sample %d:\n', i);
    fprintf('  radialThreads = %d\n', r);
    fprintf('  spiralThreads = %d\n', s);
    fprintf('  dr            = %.2f\n', dr);
    fprintf('  ds            = %.2f\n', ds);
    
    % Prompt user to input the corresponding measured performance
    f0(i) = input('Enter measured strength/weight for this sample: ');
end

%% 4) Run Bayesian optimization in segments with decreasing exploration ratio
maxEvals = 16;
segmentLength = 4;
explorationSchedule = [0.9, 0.6, 0.3, 0.1];

% First segment with seed points
results = bayesopt( ...
    @(x)objectiveManual(x,radialVals,spiralVals,drVals,dsVals), ...
    vars, ...
    'InitialX',              initTable, ...
    'InitialObjective',      f0, ...
    'NumSeedPoints',         nInit, ...
    'MaxObjectiveEvaluations', segmentLength, ...
    'AcquisitionFunctionName','expected-improvement-plus', ...
    'ExplorationRatio',      explorationSchedule(1), ...
    'PlotFcn',{@plotAcquisitionFunction,@plotObjectiveModel,@plotMinObjective} ...
);

% Continue in 3 more segments, omitting NumSeedPoints
for k = 2:length(explorationSchedule)
    results = bayesopt( ...
        @(x)objectiveManual(x,radialVals,spiralVals,drVals,dsVals), ...
        vars, ...
        'InitialX',              results.XTrace, ...
        'InitialObjective',      results.ObjectiveTrace, ...
        'MaxObjectiveEvaluations', segmentLength, ...
        'AcquisitionFunctionName','expected-improvement-plus', ...
        'ExplorationRatio',      explorationSchedule(k), ...
        'PlotFcn',{@plotAcquisitionFunction,@plotObjectiveModel,@plotMinObjective}, ...
        'IsObjectiveDeterministic', true ...
    );
end

%% 5) Objective function that only prompts for *new* points
function f = objectiveManual(x,radialVals,spiralVals,drVals,dsVals)
    % Extract the design variables from index-based encoding
    r  = radialVals( x.radialIdx );
    s  = spiralVals( x.spiralIdx );
    dr =     drVals( x.drIdx     );
    ds =     dsVals( x.dsIdx     );

    % Display the next suggested design to the user
    fprintf('\n--- Next query design ---\n');
    fprintf('  radialThreads = %d\n', r);
    fprintf('  spiralThreads = %d\n', s);
    fprintf('  dr            = %.2f\n', dr);
    fprintf('  ds            = %.2f\n', ds);

    % Prompt for the manually evaluated result (e.g., from a simulation or experiment)
    f = input('Run ANSYS and enter measured strength/weight: ');
end
