function mutatedPop = mutation(pop, mutationRate, cfg)
    [popSize, numAssets] = size(pop);
    mutatedPop = pop;
    for i = 1:popSize
        if rand() < mutationRate
            idx = randi(numAssets);
            % REPARAT: Injectam o valoare noua strict intre limitele setate
            mutatedPop(i, idx) = cfg.minWeight + rand() * (cfg.maxWeight - cfg.minWeight); 
            mutatedPop(i, :) = mutatedPop(i, :) / sum(mutatedPop(i, :));
        end
    end
end