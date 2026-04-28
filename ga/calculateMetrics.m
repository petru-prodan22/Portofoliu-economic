function stats = calculateMetrics(w, returns, covMat, rf)
    if size(w, 1) > size(w, 2)
        w = w';
    end

    stats.Rp = sum(w .* returns);
    stats.SigmaP = sqrt(w * covMat * w');
    
    if stats.SigmaP > 0
        stats.Sharpe = (stats.Rp - rf) / stats.SigmaP;
    else
        stats.Sharpe = 0;
    end
    
    % Sortino bazat pe asumptia de normalitate a randamentelor (aprobata academic in lipsa seriilor brute).
    % Formula: DownsideRisk = sqrt((SigmaP^2) / 2)
    if stats.SigmaP > 0
        sigmaDownside = sqrt((stats.SigmaP^2) / 2); 
        stats.Sortino = (stats.Rp - rf) / sigmaDownside;
    else
        stats.Sortino = 0;
    end
    
    stats.HHI = sum(w.^2);
    stats.ActiveAssets = sum(w > 0.01);
end