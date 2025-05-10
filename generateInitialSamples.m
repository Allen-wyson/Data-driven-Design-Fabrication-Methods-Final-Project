function sampledParams = generateInitialSamples()
%GENERATEINITIALSAMPLES Returns a 6x4 matrix of sampled design parameters
%   Each row is [radialThreads, spiralThreads, dr, ds], where:
%     radialThreads ∈ {5:15}, spiralThreads ∈ {5:15},
%     dr ∈ {2.5:0.5:4}, ds ∈ {0.5:0.5:2}
%   Uses Latin Hypercube Sampling with 6 samples.

% Define value sets
radialThreadsVals = 5:1:15;
spiralThreadsVals = 5:1:15;
drVals             = 2.5:0.5:4;
dsVals             = 0.5:0.5:2;

% Number of samples and dimensions
nSamples = 6;
nParams  = 4;

% Generate normalized LHS matrix
lhsMatrix = lhsdesign(nSamples, nParams);

% Map LHS into your discrete sets
radialThreads = radialThreadsVals( ceil(lhsMatrix(:,1) * numel(radialThreadsVals)) );
spiralThreads = spiralThreadsVals( ceil(lhsMatrix(:,2) * numel(spiralThreadsVals)) );
dr            = drVals(             ceil(lhsMatrix(:,3) * numel(drVals)) );
ds            = dsVals(             ceil(lhsMatrix(:,4) * numel(dsVals)) );

% Combine into output matrix
% Columns: [radialThreads, spiralThreads, dr, ds]
sampledParams = [radialThreads(:), spiralThreads(:), dr(:), ds(:)];
save('sampledParams');
end
