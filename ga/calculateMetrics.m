function stats = calculateMetrics(w, returnsMatrix, covMat, rf)
    if size(w, 1) > size(w, 2)
        w = w';
    end

    % Calculam media randamentelor (ceea ce inainte primeai gata calculat)
    meanRet = mean(returnsMatrix);
    
    stats.Rp = sum(w .* meanRet);
    stats.SigmaP = sqrt(w * covMat * w');
    
    if stats.SigmaP > 0
        stats.Sharpe = (stats.Rp - rf) / stats.SigmaP;
    else
        stats.Sharpe = 0;
    end
    
    % --- CALCUL CORECT SORTINO RATIO (Riscul de Scadere) ---
    % Randamentele zilnice istorice ale portofoliului
    portReturnsOverTime = returnsMatrix * w'; 
    
    % Filtram doar zilele in care randamentul a fost sub rata fara risc
    negativeReturns = portReturnsOverTime(portReturnsOverTime < rf) - rf;
    
    % Deviatia standard calculata doar pe partea negativa (Downside Deviation)
    if ~isempty(negativeReturns)
        sigmaDownside = sqrt(mean(negativeReturns.^2)); 
    else
        sigmaDownside = 0;
    end
    
    if sigmaDownside > 0
        stats.Sortino = (stats.Rp - rf) / sigmaDownside;
    else
        stats.Sortino = 0;
    end
    
    stats.HHI = sum(w.^2);
    stats.ActiveAssets = sum(w >= 0.01);
end