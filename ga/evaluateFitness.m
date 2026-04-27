function f = evaluateFitness(pop, returns, covMat, cfg, lambda)
    [popSize, ~] = size(pop);
    
    % 1. Normalizare (Suma ponderilor = 1)
    pop = abs(pop);
    pop = pop ./ sum(pop, 2);
    
    % 2. Randament si Risc (Vectorizat)
    portReturns = pop * returns'; 
    variances = sum((pop * covMat) .* pop, 2);
    sigmas = sqrt(max(0, variances));
    
    % 3. CVaR (Risc extrem)
    cvar = sigmas * (normpdf(norminv(1 - cfg.alpha)) / cfg.alpha);
    totalRisk = 0.5 * sigmas + 0.5 * cvar;
    
    % 4. Penalizari Cardinalitate
    activeCount = sum(pop > cfg.minWeight, 2);
    penaltyTooMany = max(0, activeCount - cfg.K_max) * 20;
    penaltyTooFew = max(0, cfg.K_min - activeCount) * 20;
    
    % 5. Penalizare Greutate Maxima
    penaltyMaxW = sum(max(0, pop - cfg.maxWeight), 2) * 50;
    
    % Scor Final
    f = (lambda * portReturns * 100) - ((1 - lambda) * totalRisk * 100) ...
        - (penaltyTooMany + penaltyTooFew + penaltyMaxW);
end