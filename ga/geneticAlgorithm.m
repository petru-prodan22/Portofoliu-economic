function [bestSol, bestFit, history] = geneticAlgorithm(pop, returns, covMat, cfg, lambda)
    gens = cfg.generations;
    popSize = size(pop, 1);
    numAssets = size(pop, 2);
    history = zeros(gens, 1);

    for g = 1:gens
        % 1. Evaluare
        fitness = evaluateFitness(pop, returns, covMat, cfg, lambda);
        [maxFit, bestIdx] = max(fitness);
        history(g) = maxFit;
        
        % 2. Elitism (5%)
        [~, sortIdx] = sort(fitness, 'descend');
        numElites = max(2, round(0.05 * popSize));
        elites = pop(sortIdx(1:numElites), :);
        
        % 3. Selectie Turneu
        numParents = popSize - numElites;
        parents = zeros(numParents, numAssets);
        for p = 1:numParents
            comp = randperm(popSize, 5);
            [~, win] = max(fitness(comp));
            parents(p, :) = pop(comp(win), :);
        end
        
        % 4. Crossover & Mutatie
        children = crossover(parents, numParents);
        children = mutation(children, cfg.mutationRate);
        
        % 5. REPARATIE (Crucial pentru cardinalitate)
        children = repairPortfolio(children, cfg);
        
        % Noua generatie
        pop = [elites; children];
    end
    
    bestSol = pop(1, :);
    bestFit = history(end);
end