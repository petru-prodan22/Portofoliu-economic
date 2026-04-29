function f = evaluateFitness(pop, returns, covMat, cfg, lambda)
    % 1. Normalizare (Suma ponderilor = 1)
    pop = abs(pop);
    pop = pop ./ sum(pop, 2);
    
    % 2. Randament si Risc (Vectorizat)
    portReturns = pop * returns'; 
    variances = sum((pop * covMat) .* pop, 2);
    sigmas = sqrt(max(0, variances));
    
    % 3. CVaR (Risc extrem) - Formula teoretică completă
    cvar = -portReturns + sigmas * (normpdf(norminv(1 - cfg.alpha)) / cfg.alpha);
    
    % Combinăm riscul normal cu riscul de crah extrem
    totalRisk = 0.5 * sigmas + 0.5 * cvar;
    
    % Scor Final Curat
    f = (lambda * portReturns * 100) - ((1 - lambda) * totalRisk * 100);
end