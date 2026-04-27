function mutatedPop = mutation(pop, mutationRate)
    [popSize, numAssets] = size(pop);
    mutatedPop = pop;
    for i = 1:popSize
        if rand() < mutationRate
            idx = randi(numAssets);
            mutatedPop(i, idx) = rand() * 0.4; % Injectam o valoare noua
            mutatedPop(i, :) = mutatedPop(i, :) / sum(mutatedPop(i, :));
        end
    end
end