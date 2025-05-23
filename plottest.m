clc; clear; close all;

%% 1) The 20 index‐tuples and negated SW you already have
idx = [  % 20×4 as before
  8  1  3 1;
  9  8  1 2;
  4  9  4 4;
  2  4  2 3;
  1 11  3 1;
  1  1  4 1;
  1  3  1 1;
  2  1  2 1;
  3  1  4 1;
 11  1  1 4;
 11 11  1 1;
 11  1  2 1;
  1  1  1 1;
  1  1  1 2;
 11 11  2 4;
 11  1  1 1;
 11  1  4 3;
  1  1  4 4;
 11  5  1 1;
  1  1  1 1;
];
y = -[  % your 20 negated strength/weight
 11376.37493;9305.64114;7772.985959;8549.637202; ...
 10162.91499;12470.59005;12093.76028;12678.55226; ...
 11921.64781;10257.68827;10497.86987;12048.81695; ...
 13225.78787;11580.47779; 9210.928996;11561.48886; ...
 12194.58742;11595.37896;11412.32955;13225.78787 ];

%% 2) Map indices into real input space
radialVals = (5:15)';
spiralVals = (5:15)';
drVals     = (2.5:0.5:4.0)';
dsVals     = (0.5:0.5:2.0)';

X = zeros(size(idx));  
X(:,1) = radialVals(idx(:,1));
X(:,2) = spiralVals(idx(:,2));
X(:,3) = drVals(   idx(:,3));
X(:,4) = dsVals(   idx(:,4));

%% 3) Fit a Gaussian‐process regressor
gprMdl = fitrgp( ...
  X, y, ...
  'Basis','constant', ...
  'KernelFunction','ardsquaredexponential', ...
  'FitMethod','exact', ...
  'Sigma',1e-6, ...          % near‐deterministic
  'Standardize',true ...
);

%% 4) Find the “best” point in your data
[~,bestIdx] = min(y);
xBest = X(bestIdx,:);

%% 5) For each of the 4 variables, plot mean ± 2·std
varNames = {'radialThreads','spiralThreads','dr','ds'};
grids = {radialVals,spiralVals,drVals,dsVals};

for v = 1:4
  G = grids{v};
  m = numel(G);
  mu  = zeros(m,1);
  sigma = zeros(m,1);
  
  % build a batch of queries, holding others at xBest
  Xq = repmat(xBest, m, 1);
  Xq(:,v) = G;
  
  [mu, s] = predict(gprMdl, Xq);
  sigma = s;
  
  figure;
  plot(G, mu, 'LineWidth',1.5); hold on;
  plot(G, mu + 2*sigma, '--'); 
  plot(G, mu - 2*sigma, '--');
  xlabel(varNames{v}, 'Interpreter','none');
  ylabel('Predicted (neg) S/W');
  title(['Surrogate slice for ', varNames{v}]);
  grid on;
end
