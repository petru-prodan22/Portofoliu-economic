tic;
clear; clc; close all;
addpath('ga/'); % Compatibilitate Windows/Mac

% =========================================================================
% --- 1. ÎNCĂRCARE DATE ȘI CONFIGURARE ---
% =========================================================================
rng('shuffle'); 
opts = detectImportOptions('Date_companii_5y.csv');
opts.VariableNamingRule = 'preserve';
dataTab = readtable('Date_companii_5y.csv', opts);

tickers = dataTab.Properties.VariableNames(2:end);
returnsMatrix = table2array(dataTab(:, 2:end));
[numPeriods, numAssets] = size(returnsMatrix);

cfg.numAssets = numAssets;      
cfg.popSize = 150;              
cfg.generations = 300;          
cfg.mutationRate = 0.15;        
cfg.K_min = 7;                  
cfg.K_max = 12;                 
cfg.minWeight = 0.05;           
cfg.maxWeight = 0.30;           
cfg.alpha = 0.05;               
cfg.rf = 0.04 / 252; 

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
    pop = repairPortfolio(pop, cfg); % CORECȚIE: Reparăm populația inițială
    
    [bestSol, ~, ~, ~] = geneticAlgorithm(pop, meanReturnsTrain, covMatTrain, cfg, lambda);
    allBestWeights(i, :) = bestSol;
    
    m = calculateMetrics(bestSol, trainReturns, covMatTrain, cfg.rf);
    paretoResults(i, 1) = m.SigmaP; 
    paretoResults(i, 2) = m.Rp;
    sharpeRatios(i) = m.Sharpe; 
    
    fprintf('Punct Pareto %d/%d calculat.\n', i, numPoints);
end

[~, bestIdx] = max(sharpeRatios);
weightsOptim = allBestWeights(bestIdx, :);

% =========================================================================
% --- AFIȘARE RANDAMENT TOTAL INDIVIDUAL PE FIECARE COMPANIE ---
% =========================================================================
% Compunem randamentele zilnice: prod(1 + R) - 1
totalReturnCompanii = (prod(1 + returnsMatrix, 1) - 1) * 100;
fprintf('\n--- RANDAMENT TOTAL (CUMULAT) PE FIECARE COMPANIE (TOT ANUL) ---\n');
tabelRandamente = array2table(totalReturnCompanii, 'VariableNames', tickers);
disp(tabelRandamente);

% =========================================================================
% --- 3. VIZUALIZARE FRONT IERA PARETO ---
% =========================================================================
wNaive = ones(1, numAssets) / numAssets;
mNaive = calculateMetrics(wNaive, trainReturns, covMatTrain, cfg.rf);

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

% Salvare automată la rezoluție HD
exportgraphics(gcf, 'grafic1_pareto.png', 'Resolution', 300);

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

% Calculăm metricile finale pe datele de test pentru raport
finalMetrics = calculateMetrics(weightsOptim, testReturns, cov(testReturns), cfg.rf);

% Apelăm noua funcție de afișare
displayPortfolioSummary(weightsOptim, tickers, sumaInvestita, cumulativeRealized, testReturns, finalMetrics);

% Salvare automată la rezoluție HD
exportgraphics(gcf, 'grafic2_backtest.png', 'Resolution', 300);

% =========================================================================
% --- 5. ANALIZĂ STATISTICĂ ROBUSTEȚE (CERINȚĂ DIZERTAȚIE) ---
% =========================================================================
fprintf('\n--- RULARE ANALIZĂ STATISTICĂ (30 Execuții pt. stabilitate) ---\n');
numRuns = 30;
statFitness = zeros(numRuns, 1);
testLambda = 0.5;

% Facem o rulare de probă pentru a extrage istoricul de convergență
popTest = initializePopulation(cfg.popSize, numAssets, cfg);
popTest = repairPortfolio(popTest, cfg);
[~, ~, bestHist, meanHist] = geneticAlgorithm(popTest, meanReturnsTrain, covMatTrain, cfg, testLambda);

% Rulăm de 30 de ori independent pentru a popula array-ul statFitness
for r = 1:numRuns
    popTest = initializePopulation(cfg.popSize, numAssets, cfg);
    popTest = repairPortfolio(popTest, cfg);
    [~, finalFit, ~, ~] = geneticAlgorithm(popTest, meanReturnsTrain, covMatTrain, cfg, testLambda);
    statFitness(r) = finalFit;
end

% Generăm Figura cu 3 sub-grafice: Învățare, Boxplot și Histogramă
figure('Color', 'w', 'Name', 'Performanța și Robustețea GA', 'Position', [100, 100, 1200, 400]);

subplot(1, 3, 1);
plot(bestHist, 'b', 'LineWidth', 2); hold on;
plot(meanHist, 'r', 'LineWidth', 1.5);
title('Curba de Învățare (1 Rulare)'); xlabel('Generație'); ylabel('Fitness');
legend('Best', 'Mean'); grid on;

subplot(1, 3, 2);
boxplot(statFitness);
title('Distribuția Fitness-ului (30 Rulări)'); ylabel('Fitness Score'); grid on;

subplot(1, 3, 3);
histogram(statFitness, 8, 'FaceColor', '#0072BD');
title('Histograma - Frecvența Optimului'); xlabel('Fitness Score'); ylabel('Frecvență'); grid on;

% Salvare automată la rezoluție HD
exportgraphics(gcf, 'grafic3_statistici.png', 'Resolution', 300);

% =========================================================================
% --- 6. ANALIZĂ DE SENSIBILITATE: IMPACTUL RESTRICȚIEI DE CARDINALITATE ---
% =========================================================================
fprintf('\n--- RULARE ANALIZĂ DE SENSIBILITATE (Impactul Cardinalității) ---\n');

cfgBackup = cfg; % Salvăm configurația inițială
lambdas_test = 0:0.1:1;
culori = {'r', 'b', 'g'};

% Securizare: Dacă ai mai puțin de 18 companii în Excel, algoritmul nu va crăpa
cazuri_K = [4, 6; 7, 12; 13, min(18, numAssets)]; 

figure('Color', 'w', 'Name', 'Sensibilitate Pareto', 'Position', [150, 150, 800, 500]);
hold on;
legendLabels = {};

for c = 1:size(cazuri_K, 1)
    cfg.K_min = cazuri_K(c, 1);
    cfg.K_max = cazuri_K(c, 2);
    
    riscuri_caz = zeros(length(lambdas_test), 1);
    randamente_caz = zeros(length(lambdas_test), 1);
    
    for l = 1:length(lambdas_test)
        % Indicator progres
        fprintf('  -> Se calculează punctul %d/%d pentru K in [%d, %d]...\n', l, length(lambdas_test), cfg.K_min, cfg.K_max);
        
        popTmp = initializePopulation(cfg.popSize, numAssets, cfg);
        popTmp = repairPortfolio(popTmp, cfg);
        [bestW, ~, ~, ~] = geneticAlgorithm(popTmp, meanReturnsTrain, covMatTrain, cfg, lambdas_test(l));
        
        randamente_caz(l) = sum(bestW .* meanReturnsTrain);
        varP = bestW * covMatTrain * bestW';
        sigmaP = sqrt(max(0, varP));
        cvarP = -randamente_caz(l) + sigmaP * (normpdf(norminv(1 - cfg.alpha)) / (1 - cfg.alpha));
        riscuri_caz(l) = 0.5 * sigmaP + 0.5 * cvarP;
    end
    
    plot(riscuri_caz * 100, randamente_caz * 100, [culori{c} '-o'], 'LineWidth', 2, 'MarkerFaceColor', culori{c});
    legendLabels{c} = sprintf('Cardinalitate K in [%d, %d]', cfg.K_min, cfg.K_max);
end

cfg = cfgBackup; % Restaurăm configurația originală
title('Impactul Restricțiilor de Cardinalitate asupra Frontierei Pareto');
xlabel('Risc Total Hibrid (%)');
ylabel('Randament Așteptat (%)');
legend(legendLabels, 'Location', 'Best');
grid on;

% Salvare automată la rezoluție HD
exportgraphics(gcf, 'grafic4_sensibilitate.png', 'Resolution', 300);

fprintf('\n>>> Execuție completă! Toate cele 4 grafice au fost salvate în folder. <<<\n');
toc