% Define discrete value sets based on step sizes
radialThreadsVals = 5:1:15;
spiralThreadsVals = 5:1:15;
drVals = 2.5:0.5:4;    % Diameter of radial thread
dsVals = 0.5:0.5:2;    % Diameter of spiral thread

% Latin Hypercube Sampling
nSamples = 6;        % Number of samples
nParams = 4;            % Number of design parameters
lhsMatrix = lhsdesign(nSamples, nParams);  % Normalized LHS values

% Map LHS to discrete value sets
radialThreads = radialThreadsVals(ceil(lhsMatrix(:,1) * numel(radialThreadsVals)));
spiralThreads = spiralThreadsVals(ceil(lhsMatrix(:,2) * numel(spiralThreadsVals)));
dr = drVals(ceil(lhsMatrix(:,3) * numel(drVals)));
ds = dsVals(ceil(lhsMatrix(:,4) * numel(dsVals)));

% Optional: Combine into one matrix
sampledParams = [radialThreads, spiralThreads, dr, ds];

% Loop and print or process
for i = 1:nSamples
    fprintf('Sample %d:\n', i);
    fprintf('  Radial Threads: %d\n', radialThreads(i));
    fprintf('  Spiral Threads: %d\n', spiralThreads(i));
    fprintf('  dr: %.2f\n', dr(i));
    fprintf('  ds: %.2f\n', ds(i));
    
    % You can call your generation function here
    % generateSpiderWeb(radialThreads(i), spiralThreads(i), dr(i), ds(i));
end

