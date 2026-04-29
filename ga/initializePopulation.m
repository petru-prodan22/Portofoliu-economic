function pop = initializePopulation(popSize, numAssets, cfg)
    % Inițializăm populația cu zerouri
    pop = zeros(popSize, numAssets);
    
    for i = 1:popSize
        % 1. Alegem o cardinalitate aleatoare
        K = randi([cfg.K_min, cfg.K_max]);
        
        % 2. Alegem aleator 'K' active
        idx = randperm(numAssets, K);
        
        % 3. Generăm ponderi aleatoare
        weights = cfg.minWeight + rand(1, K) * (cfg.maxWeight - cfg.minWeight);
        
        % 4. Normalizăm
        weights = weights / sum(weights);
        
        % 5. Atribuim ponderile activelor selectate
        pop(i, idx) = weights;
    end
end