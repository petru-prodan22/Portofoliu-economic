tic;
clear; clc; close all;
addpath("ga\") % Asigură-te că folderul există

% =========================================================================
% --- 1. ÎNCĂRCARE DATE ȘI CONFIGURARE (Baza ta existentă) ---
% =========================================================================
rng('shuffle'); 
opts = detectImportOptions('returns_for_matlab.csv');
opts.VariableNamingRule = 'preserve';
dataTab = readtable('returns_for_matlab.csv', opts);

tickers = dataTab.Properties.VariableNames(2:end);
returnsMatrix = table2array(dataTab(:, 2:end));
[numPeriods, numAssets] = size(returnsMatrix);
meanReturns = mean(returnsMatrix);
covMat = cov(returnsMatrix);

cfg.numAssets = numAssets;      
cfg.popSize = 300;              
cfg.generations = 500;          
cfg.mutationRate = 0.30;        
cfg.K_min = 10;                  
cfg.K_max = 15;                 
cfg.minWeight = 0.02;           
cfg.maxWeight = 0.35;           
cfg.alpha = 0.05;               
cfg.rf = 0.02 / 252; 

% =========================================================================
% --- 2. OPTIMIZARE PARETO (Algoritmul Genetic) ---
% =========================================================================
numPoints = 15; 
lambdas = linspace(0, 1, numPoints);
paretoResults = zeros(numPoints, 2);
allBestWeights = zeros(numPoints, numAssets);

fprintf('Optimizare în curs pentru %d active...\n', numAssets);
for i = 1:numPoints
    lambda = lambdas(i);
    pop = rand(cfg.popSize, numAssets); 
    pop = pop ./ sum(pop, 2);
    [bestSol, ~, ~] = geneticAlgorithm(pop, meanReturns, covMat, cfg, lambda);
    allBestWeights(i, :) = bestSol;
    m = calculateMetrics(bestSol, meanReturns, covMat, cfg.rf);
    paretoResults(i, 1) = m.SigmaP; 
    paretoResults(i, 2) = m.Rp;
    fprintf('Punct Pareto %d/%d calculat.\n', i, numPoints);
end

% Identificăm portofoliul Max Sharpe pentru Dashboard
sharpeRatios = zeros(numPoints, 1);
for i = 1:numPoints
    mTmp = calculateMetrics(allBestWeights(i,:), meanReturns, covMat, cfg.rf);
    sharpeRatios(i) = mTmp.Sharpe;
end
[~, bestIdx] = max(sharpeRatios);
weightsOptim = allBestWeights(bestIdx, :);

% =========================================================================
% --- 3. VIZUALIZARE (Dashboard-ul tău original) ---
% =========================================================================
wNaive = ones(1, numAssets) / numAssets;
mNaive = calculateMetrics(wNaive, meanReturns, covMat, cfg.rf);

figure('Color', 'w', 'Name', 'Dizertatie: FinTech Dashboard', 'Position', [100, 100, 1500, 500]);
subplot(1, 3, 1);
plot(paretoResults(:,1), paretoResults(:,2), 'b-o', 'LineWidth', 2, 'MarkerFaceColor', 'b'); hold on;
plot(mNaive.SigmaP, mNaive.Rp, 'rP', 'MarkerSize', 12, 'LineWidth', 2);
title('Frontiera Pareto'); grid on;

subplot(1, 3, 2);
area(allBestWeights); title('Evoluția Alocării'); grid on;

subplot(1, 3, 3);
mask = weightsOptim > 0.015; 
pie(weightsOptim(mask), tickers(mask)); title('Portofoliu Optim (Sharpe)');

% =========================================================================
% --- 4. MODUL ROBO-ADVISOR (Interfața Client) ---
% =========================================================================
fprintf('\n--- GENERARE RAPORT ROBO-ADVISOR ---\n');
sumaInvestita = 100000;    % Exemplu: 100.000 RON
riscAles = 10;             % Scara 1-10

idxPunct = round(1 + (riscAles - 1) * (numPoints - 1) / 9);
wClient = allBestWeights(idxPunct, :);
mClient = calculateMetrics(wClient, meanReturns, covMat, cfg.rf);

fprintf('Suma: %d | Risc: %d/10\n', sumaInvestita, riscAles);
fprintf('Randament Estimat: %.2f%% | Volatilitate: %.2f%%\n', mClient.Rp*252*100, mClient.SigmaP*sqrt(252)*100);
fprintf('--------------------------------------------------\n');
for j = 1:numAssets
    if wClient(j) > 0.01
        fprintf(' -> %-6s : %5.1f%% | Suma: %8.2f\n', tickers{j}, wClient(j)*100, wClient(j)*sumaInvestita);
    end
end

% =========================================================================
% --- 5. SIMULARE MONTE CARLO (Proiecție Viitor) ---
% =========================================================================
numSim = 1000; zile = 252;
scenarii = zeros(zile, numSim);
scenarii(1, :) = sumaInvestita;

for t = 2:zile
    z = randn(1, numSim);
    randament = exp((mClient.Rp - 0.5 * mClient.SigmaP^2) + mClient.SigmaP * z);
    scenarii(t, :) = scenarii(t-1, :) .* randament;
end

figure('Color', 'w', 'Name', 'Proiecție Monte Carlo');
plot(scenarii(:, 1:100), 'Color', [0.8 0.8 0.8 0.2]); hold on;
plot(mean(scenarii, 2), 'b', 'LineWidth', 3);
plot(prctile(scenarii, 95, 2), 'g--', 'LineWidth', 2);
plot(prctile(scenarii, 5, 2), 'r--', 'LineWidth', 2);
title('Evoluția Probabilă a Investiției (1 An)');
xlabel('Zile'); ylabel('Valoare Portofoliu');
grid on;

toc;