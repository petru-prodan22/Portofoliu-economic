function repairedPop = repairPortfolio(pop, cfg)
    [popSize, numAssets] = size(pop);
    repairedPop = pop;
    
    for i = 1:popSize
        w = repairedPop(i, :);
        
        % --- REPARATIE: Curatare Dust Weights (MUTATĂ AICI PENTRU A NU STRICA K_min) ---
        dustIdx = find(w > 0 & w < cfg.minWeight);
        if ~isempty(dustIdx)
            dustCapital = sum(w(dustIdx));
            w(dustIdx) = 0; % Le anulam complet
            
            % Redistribuim capitalul recuperat catre activele care au șanse să fie valide
            validIdx = find(w >= cfg.minWeight);
            if ~isempty(validIdx)
                w(validIdx) = w(validIdx) + dustCapital * (w(validIdx) / sum(w(validIdx)));
            end
        end
        % -------------------------------------------------------------------------
        
        % Identificam activele peste pragul minim (dupa curatarea dust)
        activeIdx = find(w >= cfg.minWeight);
        
        % CAZ 1: Prea multe active
        if length(activeIdx) > cfg.K_max
            [~, sortedIdx] = sort(w, 'descend');
            w(sortedIdx(cfg.K_max+1:end)) = 0;
            
        % CAZ 2: Prea putine active
        elseif length(activeIdx) < cfg.K_min
            inactiveIdx = find(w < cfg.minWeight);
            needed = cfg.K_min - length(activeIdx);
            if needed > 0 && ~isempty(inactiveIdx)
                toActivate = inactiveIdx(randperm(length(inactiveIdx), min(needed, length(inactiveIdx))));
                w(toActivate) = cfg.minWeight + rand(1, length(toActivate)) * 0.05;
            end
        end
        
        % Final: Normalizam si aplicam plafonarea iterativa
        if sum(w) > 0
            w = w / sum(w);
            
            % Taiere si redistribuire iterativa (Clip and Redistribute)
            maxIter = 10; iter = 0;
            while any(w > cfg.maxWeight) && iter < maxIter
                excess = sum(w(w > cfg.maxWeight) - cfg.maxWeight);
                w(w > cfg.maxWeight) = cfg.maxWeight;
                
                % Redistribuim excesul proportional activelor valide (sub pragul max)
                validIdx = find(w > 0 & w < cfg.maxWeight);
                if ~isempty(validIdx)
                    w(validIdx) = w(validIdx) + excess * (w(validIdx) / sum(w(validIdx)));
                else
                    break;
                end
                iter = iter + 1;
            end
            
            w = w / sum(w); % Ultima normalizare de siguranta
        else
            w = ones(1, numAssets) / numAssets;
        end
        repairedPop(i, :) = w;
    end
end