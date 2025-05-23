%% replayBayesOptPlots_full.m
clc; clear; close all;

%% 1) Define your physical grids
radialVals = (5:15)';       % actual radial thread counts
spiralVals = (5:15)';       % actual spiral thread counts
drVals     = (2.5:0.5:4.0)'; % actual dr values
dsVals     = (0.5:0.5:2.0)'; % actual ds values

%% 2) Paste in your 20 runs as [radial,spiral,dr,ds,S/W]
% 4 seeds followed by 16 evaluation points.
data = [
  12  5 3.5 0.5 2675;
  13 12 2.5 1.0 1720;
   8 13 4.0 2.0 3480;
   6  8 3.0 1.5 1440;
   5 15 3.5 0.5 1144.4;
   5  5 4.0 0.5 1626.2;
   5  7 2.5 0.5  686.0;
   6  5 3.0 0.5 1141.2;
   7  5 4.0 0.5 2151.4;
  15  5 2.5 0.5 2500.0;
  15 15 2.5 0.5 1725.0;
  15  5 3.0 1.0 2828.7;
   5  5 2.5 0.5  720.0;
   5  5 2.5 1.0  830.0;
  15 15 3.0 2.0 4625.0;
  15  5 2.5 0.5 1759.5;
  15  5 4.0 1.5 5230.2;
   5  5 4.0 2.0 2511.2;
  15  7 4.0 1.5 6100.0;
   5  5 2.5 0.5  720.0
];

physR  = data(:,1);
physS  = data(:,2);
physDr = data(:,3);
physDs = data(:,4);
SW     = data(:,5);

%% 3) Convert physical values → integer indices into each grid
radialIdx = arrayfun(@(v)find(radialVals==v,1),  physR);
spiralIdx = arrayfun(@(v)find(spiralVals==v,1),  physS);
drIdx     = arrayfun(@(v)find(drVals==v,1),      physDr);
dsIdx     = arrayfun(@(v)find(dsVals==v,1),      physDs);

initTable = table(radialIdx,spiralIdx,drIdx,dsIdx, ...
    'VariableNames',{'radialIdx','spiralIdx','drIdx','dsIdx'});

%% 4) Negate S/W for bayesopt (it minimizes)
objective = -SW;

%% 5) Define the same optimizableVariables you used originally
vars = [
  optimizableVariable('radialIdx',[1,numel(radialVals)],'Type','integer')
  optimizableVariable('spiralIdx',[1,numel(spiralVals)],'Type','integer')
  optimizableVariable('drIdx',    [1,numel(drVals)],    'Type','integer')
  optimizableVariable('dsIdx',    [1,numel(dsVals)],    'Type','integer')
];

%% 6) Dummy objective: guaranteed to return one scalar
dummyFcn = @(x) objective( ...
    find( ...
      initTable.radialIdx  == x.radialIdx & ...
      initTable.spiralIdx  == x.spiralIdx & ...
      initTable.drIdx      == x.drIdx     & ...
      initTable.dsIdx      == x.dsIdx, 1, 'first') ...
);

%% 7) Step A: train *silently* on your 4 seed points
nSeeds    = 4;
seedTable = initTable(1:nSeeds,:);
seedObj   = objective(1:nSeeds);

results = bayesopt( ...
    dummyFcn, ...
    vars, ...
    'InitialX',                seedTable, ...
    'InitialObjective',        seedObj, ...
    'NumSeedPoints',           nSeeds, ...
    'MaxObjectiveEvaluations', nSeeds, ...
    'IsObjectiveDeterministic', true, ...
    'Verbose',                 0 ...
);

%% 8) Step B: replay each of the 16 real evaluations *one at a time*,
%           firing *all three* built-in plot callbacks at each iteration
for i = nSeeds+1 : height(initTable)
    results = resume( ...
      results, ...
      'MaxObjectiveEvaluations',    1, ...
      'AcquisitionFunctionName',    'expected-improvement-plus', ...
      'PlotFcn', { ...
         @plotAcquisitionFunction, ...
         @plotObjectiveModel, ...
         @plotMinObjective  ...
      }, ...
      'Verbose',                    0 ...
    );
end
