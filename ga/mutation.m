function mutatedPop = mutation(pop, mutationRate, cfg)
    [popSize, ~] = size(pop);
    mutatedPop = pop;
    for i = 1:popSize
        if rand() < mutationRate
            % Cautam ce active sunt active si care sunt inactive in portofoliu
            activeIdx = find(mutatedPop(i, :) > cfg.minWeight);
            inactiveIdx = find(mutatedPop(i, :) == 0);
            
            if ~isempty(activeIdx)
                % Alegem un activ sursa dintre cele existente
                source = activeIdx(randi(length(activeIdx)));
                
                % Decidem destinatia: 50% un alt activ existent, 50% un activ complet NOU
                if rand() > 0.5 && length(activeIdx) >= 2
                    posibile = setdiff(activeIdx, source);
                    if ~isempty(posibile)
                        target = posibile(randi(length(posibile)));
                    else
                        target = source;
                    end
                elseif ~isempty(inactiveIdx)
                    % TREZIM O GENĂ NOUĂ (activăm un activ din cele ignorate)
                    target = inactiveIdx(randi(length(inactiveIdx)));
                else
                    target = source;
                end
                
                if source ~= target
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
end