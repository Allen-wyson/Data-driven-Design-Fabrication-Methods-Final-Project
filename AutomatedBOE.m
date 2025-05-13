function f = objectiveManual(x, radialVals, spiralVals, drVals, dsVals)
    r  = radialVals(x.radialIdx);
    s  = spiralVals(x.spiralIdx);
    dr = drVals(x.drIdx);
    ds = dsVals(x.dsIdx);

    % Display which design is being evaluated
    fprintf('\n--- Running automated simulation ---\n');
    fprintf('  radialThreads = %d\n', r);
    fprintf('  spiralThreads = %d\n', s);
    fprintf('  dr            = %.2f\n', dr);
    fprintf('  ds            = %.2f\n', ds);

    %% 1. Write parameters to input file for Python
    T = table(r, s, dr, ds, 'VariableNames', {'r', 's', 'dr', 'ds'});
    writetable(T, 'web_input.csv');

    %% 2. Run Python simulation script
    status = system('python run_simulation.py');
    if status ~= 0
        error('Python script failed');
    end

    %% 3. Read result from output file
    try
        f = load('web_result.txt');
    catch
        error('Failed to read result from web_result.txt');
    end
end
