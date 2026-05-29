function repairedPop = repairPortfolio(pop, cfg)
    [popSize, ~] = size(pop);
    repairedPop = pop;
    
    for i = 1:popSize
        w = repairedPop(i, :);
        
        % curatare Weights (Active sub 5%)
        dustIdx = find(w > 0 & w < cfg.minWeight);
        if ~isempty(dustIdx)
            dustCapital = sum(w(dustIdx));
            w(dustIdx) = 0; % Le anulam complet
            
            % redistribuim capitalul catre activele valide
            validIdx = find(w >= cfg.minWeight);
            if ~isempty(validIdx)
                w(validIdx) = w(validIdx) + dustCapital * (w(validIdx) / sum(w(validIdx)));
            end
        end
        
        % identificam activele peste pragul minim dupa curatare
        activeIdx = find(w >= cfg.minWeight);
        
        % cazul 1 cu prea multe active
        if length(activeIdx) > cfg.K_max
            [~, sortedIdx] = sort(w, 'descend');
            w(sortedIdx(cfg.K_max+1:end)) = 0;
            
        %cazul 2 cu prea putine active
        elseif length(activeIdx) < cfg.K_min
            inactiveIdx = find(w < cfg.minWeight);
            needed = cfg.K_min - length(activeIdx);
            if needed > 0 && ~isempty(inactiveIdx)
                toActivate = inactiveIdx(randperm(length(inactiveIdx), min(needed, length(inactiveIdx))));
                w(toActivate) = cfg.minWeight + rand(1, length(toActivate)) * 0.05;
            end
        end
        
        %normalizare si plafonare iterativa
        if sum(w) > 0
            w = w / sum(w); % Normalizare la 1
            
            % taiere si redistribuire
            maxIter = 10; 
            iter = 0;
            while any(w > cfg.maxWeight + 1e-5) && iter < maxIter
                excess = sum(w(w > cfg.maxWeight) - cfg.maxWeight);
                w(w > cfg.maxWeight) = cfg.maxWeight;
                
                %redistribuire exces active
                validIdx = find(w > 0 & w < cfg.maxWeight - 1e-5);
                if ~isempty(validIdx)
                    w(validIdx) = w(validIdx) + excess * (w(validIdx) / sum(w(validIdx)));
                else
                    break; 
                end
                iter = iter + 1;
            end
        end
        
        repairedPop(i, :) = w;
    end
end