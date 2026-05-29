function mutatedPop = mutation(pop, mutationRate, cfg)
    [popSize, ~] = size(pop);
    mutatedPop = pop;
    for i = 1:popSize
        if rand() < mutationRate
            activeIdx = find(mutatedPop(i, :) > cfg.minWeight);
            inactiveIdx = find(mutatedPop(i, :) == 0);
            
            if ~isempty(activeIdx)
                source = activeIdx(randi(length(activeIdx)));
                target = source; 
                maxTransfer = 0;
                
                if rand() > 0.5 && length(activeIdx) >= 2
                    posibile = setdiff(activeIdx, source);
                    if ~isempty(posibile)
                        target = posibile(randi(length(posibile)));
                        % La active existente, mutam o fractiune aleatoare
                        maxTransfer = (mutatedPop(i, source) - cfg.minWeight) * rand();
                    end
                elseif ~isempty(inactiveIdx)
                    % Activ nou: Verificam daca sursa isi permite sa dea MINIM 5%
                    availableFunds = mutatedPop(i, source) - cfg.minWeight;
                    if availableFunds >= cfg.minWeight
                        target = inactiveIdx(randi(length(inactiveIdx)));
                        % Garantam ca primeste minim pragul necesar pentru a supravietui reparatiei
                        maxTransfer = cfg.minWeight + (availableFunds - cfg.minWeight) * rand();
                    end
                end
                
                if source ~= target && maxTransfer > 0
                    if mutatedPop(i, target) + maxTransfer > cfg.maxWeight
                        maxTransfer = cfg.maxWeight - mutatedPop(i, target);
                    end
                    
                    if maxTransfer > 0
                        mutatedPop(i, source) = mutatedPop(i, source) - maxTransfer;
                        mutatedPop(i, target) = mutatedPop(i, target) + maxTransfer;
                    end
                end
            end
        end
    end
end