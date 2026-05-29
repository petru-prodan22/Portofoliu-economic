function stats = calculateMetrics(w, returnsMatrix, covMat, rf)
    if size(w, 1) > size(w, 2)
        w = w';
    end

    % Calculam media randamentelor (ceea ce inainte primeai gata calculat)
    meanRet = mean(returnsMatrix);
    
    stats.Rp = sum(w .* meanRet);
    stats.SigmaP = sqrt(w * covMat * w');
    
    % --- SHARPE RATIO (Anualizat) ---
    if stats.SigmaP > 0
        stats.Sharpe = ((stats.Rp - rf) / stats.SigmaP) * sqrt(252);
    else
        stats.Sharpe = 0;
    end
    
    % --- SORTINO RATIO CORECTAT ȘI ANUALIZAT (Riscul de Scadere) ---
    % Randamentele zilnice istorice ale portofoliului
    portReturnsOverTime = returnsMatrix * w'; 
    
    % Calculăm diferența față de rata risk-free; dacă e pe profit, punem 0
    downsideArray = min(0, portReturnsOverTime - rf); 
    
    % Acum mean() va împărți corect la numărul TOTAL de zile
    sigmaDownside = sqrt(mean(downsideArray.^2)); 
    
    if sigmaDownside > 0
        stats.Sortino = ((stats.Rp - rf) / sigmaDownside) * sqrt(252);
    else
        stats.Sortino = 0;
    end
    
    stats.HHI = sum(w.^2);
    stats.ActiveAssets = sum(w >= 0.01);
end