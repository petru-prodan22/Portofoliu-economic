function pop = initializePopulation(popSize, numAssets)
    pop = rand(popSize, numAssets);
    pop = pop ./ sum(pop, 2); % suma = 1
end