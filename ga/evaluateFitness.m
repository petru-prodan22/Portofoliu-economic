function f = evaluateFitness(pop, returns, covMat, cfg, lambda)
    pop = abs(pop);
    pop = pop ./ sum(pop, 2);
    
    portReturns = pop * returns'; 
    variances = sum((pop * covMat) .* pop, 2);
    sigmas = sqrt(max(0, variances));
  
    % medie pierderi
    cvar = -portReturns + sigmas * (normpdf(norminv(1 - cfg.alpha)) / (1 - cfg.alpha));
    
    % risc combbinat: 50% volatilitate + 50% CVaR
    totalRisk = 0.5 * sigmas + 0.5 * cvar;
    
    % funcția de obiectiv scalarizată
    f = (lambda * portReturns * 100) - ((1 - lambda) * totalRisk * 100);
end