function results = optimizeSpiderWeb()
    %─────────────────────────────────────────────────────────────────────────
    % 1) Define your design variables
    %─────────────────────────────────────────────────────────────────────────
    % nradial, nspiral: integer steps of 1
    X1 = optimizableVariable('nradial', [5,15], 'Type','integer');
    X2 = optimizableVariable('nspiral', [5,15], 'Type','integer');

    % rad_radial, rad_spiral: continuous, but we’ll round to .5 steps inside the obj
    X3 = optimizableVariable('rad_radial', [3.5, 4.0], 'Type','real');    % will round to 3.5 or 4.0
    X4 = optimizableVariable('rad_spiral', [0.5, 2.0], 'Type','real');    % will round to nearest 0.5
    vars = [X1, X2, X3, X4];                                              % :contentReference[oaicite:0]{index=0}

    %─────────────────────────────────────────────────────────────────────────
    % 2) Supply your six existing samples
    %─────────────────────────────────────────────────────────────────────────
    % Replace the placeholder data below (nradial_i, nspiral_i, …, ratio_i)
    % with your actual FEM results and computed load/weight ratios.
    InitialX = table( ...
        [nradial_1; nradial_2; nradial_3; nradial_4; nradial_5; nradial_6], ...
        [nspiral_1; nspiral_2; nspiral_3; nspiral_4; nspiral_5; nspiral_6], ...
        [radial_1;    radial_2;    radial_3;    radial_4;    radial_5;    radial_6], ...
        [spiral_1;    spiral_2;    spiral_3;    spiral_4;    spiral_5;    spiral_6], ...
        'VariableNames', {'nradial','nspiral','rad_radial','rad_spiral'} );

    % Your objective values = load_capacity / weight
    InitialObjective = [ ratio_1; ratio_2; ratio_3; ratio_4; ratio_5; ratio_6 ];

    % Telling bayesopt to use these as “priors” (won’t re-evaluate them) :contentReference[oaicite:1]{index=1}
    bayesOpts = struct( ...
        'InitialX',          InitialX, ...
        'InitialObjective',  InitialObjective, ...
        'NumSeedPoints',     0, ...                         % skip random seeds
        'AcquisitionFunctionName','expected-improvement-plus', ...
        'ExplorationRatio',  0.8, ...                       % tune as needed
        'MaxObjectiveEvaluations', 40, ...                  % total sims (incl. your 6)
        'PlotFcn',           {@plotAcquisitionFunction, ...
                              @plotObjectiveModel, ...
                              @plotMinObjective}, ...
        'Verbose',           1 ...
    );

    %─────────────────────────────────────────────────────────────────────────
    % 3) Run the Bayesian optimization
    %─────────────────────────────────────────────────────────────────────────
    results = bayesopt(@webObjective, vars, bayesOpts);

    % Display the best found point (remember we minimized the negative ratio)
    best = results.XAtMinObjective;
    bestRatio = -results.MinObjective;
    fprintf('Best nradial=%d, nspiral=%d, rad_radial=%.1f, rad_spiral=%.1f → ratio=%.3f\n', ...
        best.nradial, best.nspiral, best.rad_radial, best.rad_spiral, bestRatio);
end

%───────────────────────────────────────────────────────────────────────────
% Objective function: negative load/weight ratio (so bayesopt “minimizes” it)
%───────────────────────────────────────────────────────────────────────────
function fval = webObjective(optVars)
    % 1) Enforce your grid increments
    nrad  = optVars.nradial;
    nspir = optVars.nspiral;
    % round to nearest 0.5
    radR  = round(optVars.rad_radial * 2)/2;
    radS  = round(optVars.rad_spiral  * 2)/2;

    % 2) Run your FEM sim to get load capacity
    loadCap = runMyFEM(nrad, nspir, radR, radS);

    % 3) Compute the web’s weight via your geometry routine
    wt = computeWebWeight(nrad, nspir, radR, radS);

    % 4) We want to *maximize* loadCap/weight, so return its *negative*
    fval = - (loadCap / wt);
end