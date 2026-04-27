tic;
clear; clc; close all;
addpath('ga/'); % Compatibilitate Windows/Mac

% =========================================================================
% --- 1. ÎNCĂRCARE DATE ȘI CONFIGURARE ---
% =========================================================================
rng('shuffle'); 
opts = detectImportOptions('returns_for_matlab.csv');
opts.VariableNamingRule = 'preserve';
dataTab = readtable('returns_for_matlab.csv', opts);

tickers = dataTab.Properties.VariableNames(2:end);
returnsMatrix = table2array(dataTab(:, 2:end));
[numPeriods, numAssets] = size(returnsMatrix);

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
% --- 1.2 SPLIT DATE: TRAIN (80%) vs TEST (20%) ---
% =========================================================================
splitIdx = round(0.8 * numPeriods);
trainReturns = returnsMatrix(1:splitIdx, :);
testReturns = returnsMatrix(splitIdx+1:end, :);

% Calculam mediile si covarianta DOAR pe datele de antrenare!
meanReturnsTrain = mean(trainReturns);
covMatTrain = cov(trainReturns);

fprintf('Zile Antrenare: %d | Zile Test: %d\n', splitIdx, numPeriods - splitIdx);

% =========================================================================
% --- 2. OPTIMIZARE PARETO PE DATELE DE TRAIN ---
% =========================================================================
numPoints = 15; 
lambdas = linspace(0, 1, numPoints);
paretoResults = zeros(numPoints, 2);
allBestWeights = zeros(numPoints, numAssets);
sharpeRatios = zeros(numPoints, 1);

fprintf('Optimizare în curs pentru %d active...\n', numAssets);
for i = 1:numPoints
    lambda = lambdas(i);
    pop = initializePopulation(cfg.popSize, numAssets, cfg); 
    
    [bestSol, ~, ~, ~] = geneticAlgorithm(pop, meanReturnsTrain, covMatTrain, cfg, lambda);
    allBestWeights(i, :) = bestSol;
    
    m = calculateMetrics(bestSol, meanReturnsTrain, covMatTrain, cfg.rf);
    paretoResults(i, 1) = m.SigmaP; 
    paretoResults(i, 2) = m.Rp;
    sharpeRatios(i) = m.Sharpe; 
    
    fprintf('Punct Pareto %d/%d calculat.\n', i, numPoints);
end

[~, bestIdx] = max(sharpeRatios);
weightsOptim = allBestWeights(bestIdx, :);

% =========================================================================
% --- 3. VIZUALIZARE FRONT IERA PARETO ---
% =========================================================================
wNaive = ones(1, numAssets) / numAssets;
mNaive = calculateMetrics(wNaive, meanReturnsTrain, covMatTrain, cfg.rf);

figure('Color', 'w', 'Name', 'Dizertatie: FinTech Dashboard', 'Position', [100, 100, 1500, 500]);
subplot(1, 3, 1);
plot(paretoResults(:,1), paretoResults(:,2), 'b-o', 'LineWidth', 2, 'MarkerFaceColor', 'b'); hold on;
plot(mNaive.SigmaP, mNaive.Rp, 'rP', 'MarkerSize', 12, 'LineWidth', 2);
title('Frontiera Pareto (Train Data)'); grid on; xlabel('Risc'); ylabel('Randament');

subplot(1, 3, 2);
area(allBestWeights); title('Evoluția Alocării'); grid on;

subplot(1, 3, 3);
mask = weightsOptim > 0.015;
if sum(mask) > 0 
    pie(weightsOptim(mask), tickers(mask)); 
    title('Portofoliu Optim (Max Sharpe)');
else
    title('Niciun activ > 1.5%');
end

% =========================================================================
% --- 4. BACKTESTING REAL (OUT-OF-SAMPLE) PE DATELE DE TEST ---
% =========================================================================
sumaInvestita = 100000;
realizedReturns = testReturns * weightsOptim'; 
cumulativeRealized = cumprod(1 + realizedReturns) * sumaInvestita;

realizedNaive = testReturns * wNaive';
cumulativeNaive = cumprod(1 + realizedNaive) * sumaInvestita;

figure('Color', 'w', 'Name', 'Backtesting Out-of-Sample');
plot(cumulativeRealized, 'b', 'LineWidth', 2); hold on;
plot(cumulativeNaive, 'r--', 'LineWidth', 1.5);
title('Performanța Reală în Afara Eșantionului (Test Data)');
xlabel('Zile de Tranzacționare (Test)'); ylabel('Valoare Portofoliu (RON)');
legend('Portofoliu Optimizat (GA)', 'Portofoliu Naiv (1/N)', 'Location', 'best'); grid on;

finalGainGA = (cumulativeRealized(end)/sumaInvestita - 1) * 100;
finalGainNaive = (cumulativeNaive(end)/sumaInvestita - 1) * 100;

fprintf('\n--- REZULTATE BACKTESTING (OUT-OF-SAMPLE) ---\n');
fprintf('Randament Portofoliu GA:   %.2f%%\n', finalGainGA);
fprintf('Randament Portofoliu Naiv: %.2f%%\n', finalGainNaive);

% =========================================================================
% --- 5. ANALIZĂ STATISTICĂ ROBUSTEȚE (CERINȚĂ DIZERTAȚIE) ---
% =========================================================================
fprintf('\n--- RULARE ANALIZĂ STATISTICĂ (30 Execuții pt. stabilitate) ---\n');
numRuns = 30;
statFitness = zeros(numRuns, 1);
testLambda = 0.5;

popTest = initializePopulation(cfg.popSize, numAssets, cfg);
[~, ~, bestHist, meanHist] = geneticAlgorithm(popTest, meanReturnsTrain, covMatTrain, cfg, testLambda);

figure('Color', 'w', 'Name', 'Performanța GA', 'Position', [100, 100, 1000, 400]);
subplot(1, 2, 1);
plot(bestHist, 'b', 'LineWidth', 2); hold on;
plot(meanHist, 'r', 'LineWidth', 1.5);
title('Curba de Învățare'); xlabel('Generație'); ylabel('Fitness');
legend('Cel mai bun (Best)', 'Media (Mean)'); grid on;

for r = 1:numRuns
    popTest = initializePopulation(cfg.popSize, numAssets, cfg);
    [~, fitVal, ~, ~] = geneticAlgorithm(popTest, meanReturnsTrain, covMatTrain, cfg, testLambda);
    statFitness(r) = fitVal;
end

subplot(1, 2, 2);
boxplot(statFitness);
title('Distribuția Fitness-ului (30 Rulări)'); ylabel('Valoare Fitness'); grid on;

fprintf('Media Fitness (30 rulări): %.4f | Dev. Standard: %.6f\n', mean(statFitness), std(statFitness));

toc;