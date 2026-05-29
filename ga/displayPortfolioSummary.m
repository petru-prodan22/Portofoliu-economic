function displayPortfolioSummary(weights, tickers, initialSum, cumulativeValue, testReturns, metrics)
    % DISPLAYPORTFOLIOSUMMARY - Afișează un raport detaliat al portofoliului optim
    
    separator = repmat('=', 1, 60);
    
    fprintf('\n%s\n', separator);
    fprintf('          RAPORT DETALIAT PORTOFOLIU OPTIM (GA)\n');
    fprintf('%s\n', separator);

    % 1. COMPOZIȚIA PORTOFOLIULUI (Ponderi și Sume)
    mask = weights > 0.0001; % Filtrăm activele cu pondere neglijabilă
    activeWeights = weights(mask);
    activeTickers = tickers(mask);
    investedAmounts = activeWeights * initialSum;
    
    portfolioTable = table(activeTickers', (activeWeights*100)', investedAmounts', ...
        'VariableNames', {'Activ', 'Pondere_Procentuala', 'Suma_Investita_RON'});
    
    fprintf('\n--- ALOCARE ACTIVE ---\n');
    disp(portfolioTable);

    % 2. METRICI DE PERFORMANȚĂ ȘI RISC
    finalValue = cumulativeValue(end);
    totalReturnPercent = (finalValue / initialSum - 1) * 100;
    
    fprintf('\n--- ANALIZĂ PERFORMANȚĂ (Perioada Test) ---\n');
    fprintf('Investiție Inițială:    %.2f RON\n', initialSum);
    fprintf('Valoare Finală:         %.2f RON\n', finalValue);
    fprintf('Profit/Pierdere Netă:   %.2f RON\n', finalValue - initialSum);
    fprintf('Randament Total Test:   %.2f %%\n', totalReturnPercent);
    fprintf('Sharpe Ratio:           %.4f\n', metrics.Sharpe);
    fprintf('Sortino Ratio:          %.4f\n', metrics.Sortino);
    fprintf('Diversificare (HHI):    %.4f (apropiat de 0 = diversificat)\n', metrics.HHI);
    fprintf('Active Selectate:       %d din %d disponibile\n', metrics.ActiveAssets, length(tickers));

    % 3. ISTORIC EVOLUȚIE (Tranzacționare Virtuală)
    fprintf('\n--- ISTORIC ZILNIC (Eșantion din perioada de Test) ---\n');
    zile = (1:length(cumulativeValue))';
    % Afișăm doar câteva rânduri (început, mijloc, sfârșit) pentru claritate
    sampleIdx = round(linspace(1, length(cumulativeValue), 10));
    historyTable = table(zile(sampleIdx), cumulativeValue(sampleIdx), ...
        'VariableNames', {'Zi_Test', 'Valoare_Portofoliu_RON'});
    disp(historyTable);
    
    fprintf('%s\n\n', separator);
end