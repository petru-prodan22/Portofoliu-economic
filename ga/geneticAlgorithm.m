function [bestSol, bestFit, history, meanHistory] = geneticAlgorithm(pop, returns, covMat, cfg, lambda)
    gens = cfg.generations;
    popSize = size(pop, 1);
    numAssets = size(pop, 2);
    
    history = zeros(gens, 1);
    meanHistory = zeros(gens, 1);

    for g = 1:gens
        % 1. Evaluare
        fitness = evaluateFitness(pop, returns, covMat, cfg, lambda);
        [maxFit, bestIdx] = max(fitness);
        
        history(g) = maxFit;
        meanHistory(g) = mean(fitness);
        
        % 2. Elitism (5%)
        [~, sortIdx] = sort(fitness, 'descend');
        numElites = max(2, round(0.05 * popSize));
        elites = pop(sortIdx(1:numElites), :);
        
        % 3. Selectie Turneu
        numParents = popSize - numElites;
        parents = zeros(numParents, numAssets);
        
        % Folosim functia actualizata de selectie
        selectedParents = selection(pop, fitness); 
        
        % Daca functia ta de selectie returneaza doar jumatate din populatie,
        % trebuie sa generam perechi. Pentru siguranta, o apelam de mai multe ori
        % sau refacem parintii:
        for p = 1:numParents
             idx = randperm(popSize, 3);
             [~, win] = max(fitness(idx));
             parents(p, :) = pop(idx(win), :);
        end
        
        % 4. Crossover & Mutatie
        % Presupunem ca functia crossover returneaza acelasi numar de copii
        children = crossover(parents, numParents);
        
        % AICI ERA EROAREA: Acum trimitem si parametrul 'cfg' !
        children = mutation(children, cfg.mutationRate, cfg);
        
        % 5. Reparatie (Crucial pentru cardinalitate)
        children = repairPortfolio(children, cfg);
        
        % Noua generatie
        pop = [elites; children];
    end
    
    % Returnam cel mai bun individ din ultima generatie
    fitness = evaluateFitness(pop, returns, covMat, cfg, lambda);
    [~, bestIdx] = max(fitness);
    
    bestSol = pop(bestIdx, :);
    bestFit = history(end);
end