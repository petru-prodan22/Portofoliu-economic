function repairedPop = repairPortfolio(pop, cfg)
    [popSize, numAssets] = size(pop);
    repairedPop = pop;
    
    for i = 1:popSize
        w = repairedPop(i, :);
        % Identificam activele peste pragul minim
        activeIdx = find(w > cfg.minWeight);
        
        % CAZ 1: Prea multe active -> Le taiem pe cele mai mici
        if length(activeIdx) > cfg.K_max
            [~, sortedIdx] = sort(w, 'descend');
            w(sortedIdx(cfg.K_max+1:end)) = 0;
            
        % CAZ 2: Prea putine active -> Activam unele la intamplare
        elseif length(activeIdx) < cfg.K_min
            inactiveIdx = find(w <= cfg.minWeight);
            needed = cfg.K_min - length(activeIdx);
            % Alegem cateva active "stinse" si le dam o valoare mica
            toActivate = inactiveIdx(randperm(length(inactiveIdx), needed));
            w(toActivate) = cfg.minWeight + rand(1, needed) * 0.05;
        end
        
        % Final: Normalizam sa insumeze 100%
        if sum(w) > 0
            w = w / sum(w);
            % REPARAT: Fortam respectarea limitei maxime per activ
            w(w > cfg.maxWeight) = cfg.maxWeight;
            w = w / sum(w); % Renormalizare
        else
            w = ones(1, numAssets) / numAssets;
        end
        repairedPop(i, :) = w;
    end
end