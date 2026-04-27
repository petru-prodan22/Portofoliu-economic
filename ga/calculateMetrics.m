function stats = calculateMetrics(w, returns, covMat, rf)
    % calculateMetrics: Calculeaza indicatorii de performanta pentru un portofoliu
    % w - ponderile activelor (vector rand sau coloana)
    % returns - randamentele asteptate ale activelor
    % covMat - matricea de covarianta (riscul)
    % rf - rata fara risc (Risk-Free Rate)

    % Asiguram ca w este vector rand pentru operatii matriceale
    if size(w, 1) > size(w, 2)
        w = w';
    end

    % 1. Randament asteptat al portofoliului (Rp)
    stats.Rp = sum(w .* returns);
    
    % 2. Volatilitatea portofoliului (SigmaP)
    % Formula: sqrt(w * Cov * w')
    stats.SigmaP = sqrt(w * covMat * w');
    
    % 3. Sharpe Ratio (Eficiența raportată la volatilitatea totală)
    % Masoara unitatea de profit per unitate de risc
    if stats.SigmaP > 0
        stats.Sharpe = (stats.Rp - rf) / stats.SigmaP;
    else
        stats.Sharpe = 0;
    end
    
    % 4. Sortino Ratio (Eficiența raportată la riscul de pierdere)
    % Nota: Intr-o varianta cu date reale, sigmaDownside se calculeaza doar 
    % pe baza randamentelor negative. Aici folosim o aproximare statistica.
    sigmaDownside = stats.SigmaP * 0.75; 
    stats.Sortino = (stats.Rp - rf) / sigmaDownside;
    
    % 5. Indexul Herfindahl-Hirschman (HHI) - Gradul de concentrare
    % HHI = sum(w^2). Valori mici = diversificare mare.
    stats.HHI = sum(w.^2);
    
    % 6. Cardinalitate (Numarul de active cu pondere semnificativa)
    stats.ActiveAssets = sum(w > 0.01);
end