function mutatedPop = mutation(pop, mutationRate, cfg)
    [popSize, ~] = size(pop);
    mutatedPop = pop;
    for i = 1:popSize
        if rand() < mutationRate
            % Cautam ce active sunt in portofoliu
            activeIdx = find(mutatedPop(i, :) > cfg.minWeight);
            
            if length(activeIdx) >= 2
                % Alegem 2 active existente la intamplare
                idx = activeIdx(randperm(length(activeIdx), 2));
                source = idx(1);
                target = idx(2);
                
                % Transferam maxim ce depaseste pragul minim al sursei
                maxTransfer = (mutatedPop(i, source) - cfg.minWeight) * rand();
                
                % Verificam sa nu incalcam limita maxWeight la destinatie
                if mutatedPop(i, target) + maxTransfer > cfg.maxWeight
                    maxTransfer = cfg.maxWeight - mutatedPop(i, target);
                end
                
                % Efectuam mutarea de capital
                if maxTransfer > 0
                    mutatedPop(i, source) = mutatedPop(i, source) - maxTransfer;
                    mutatedPop(i, target) = mutatedPop(i, target) + maxTransfer;
                end
            end
        end
    end
end