clc; clear; close all;

%% 1) Your 20 index‐tuples and negated S/W (as before)
idx = [
  8  1  3 1;
  9  8  1 2;
  4  9  4 4;
  2  4  2 3;
  1 11 3 1;
  1  1 4 1;
  1  3 1 1;
  2  1 2 1;
  3  1 4 1;
 11  1 1 4;
 11 11 1 1;
 11  1 2 1;
  1  1 1 1;
  1  1 1 2;
 11 11 2 4;
 11  1 1 1;
 11  1 4 3;
  1  1 4 4;
 11  5 1 1;
  1  1 1 1;
];

y = -[
 11376.37493; 9305.64114; 7772.985959; 8549.637202; 
 10162.91499;12470.59005;12093.76028;12678.55226;
 11921.64781;10257.68827;10497.86987;12048.81695;
 13225.78787;11580.47779; 9210.928996;11561.48886;
 12194.58742;11595.37896;11412.32955;13225.78787
];

% total evals = 20; seeds = first 4; we’ll plot from eval 5 → 12 as in your example
nInit     = 4;
segment1  = 8;
segment2  = 12;
% iterations = nInit:segment2;
iterations = nInit+1 : size(idx,1);   % i.e. 4:20

%% 2) Map indices into *real* inputs
radialVals = (5:15)';
spiralVals = (5:15)';
drVals     = (2.5:0.5:4.0)';
dsVals     = (0.5:0.5:2.0)';

X = zeros(size(idx));
X(:,1) = radialVals(idx(:,1));
X(:,2) = spiralVals(idx(:,2));
X(:,3) = drVals(   idx(:,3));
X(:,4) = dsVals(   idx(:,4));

%% 3) Prepare the full grid for prediction
[Rg,Sg,Dg,Sg2] = ndgrid(radialVals,spiralVals,drVals,dsVals);
gridX = [Rg(:), Sg(:), Dg(:), Sg2(:)];

%=== assume X,y,gridX are all defined as before, and iterations = 4:20 ===%

obsMin = nan(numel(iterations),1);
eiMin  = nan(numel(iterations),1);

for ii = 1:numel(iterations)
    i   = iterations(ii);
    Xi  = X(1:i,:);
    yi  = y(1:i);

    % 1) running observed min
    obsMin(ii) = min(yi);

    % 2) fit a GP
    gpr = fitrgp(Xi, yi, 'KernelFunction','ardsquaredexponential','Standardize',true);

    % 3) predict mean & std on full grid
    [mu, sigma] = predict(gpr, gridX);

    % 4) compute EI (for minimization)
    yBest = min(yi);
    Z     = (yBest - mu) ./ sigma;
    EI    = (yBest - mu).*normcdf(Z) + sigma.*normpdf(Z);

    % 5) expected‐improvement‐based min
    eiMin(ii) = yBest - max(EI(:));
end

% 6) plot
figure; hold on; grid on;
plot(iterations, obsMin, '-o','DisplayName','Min observed objective');
plot(iterations, eiMin,  '-o','DisplayName','Min obs − maxEI');
xlabel('Function evaluations');
ylabel('Min (neg) S/W');
legend('Location','best');
title('True vs EI‐based estimated minimum');

