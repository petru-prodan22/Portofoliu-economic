% VARIANTA CORECTATĂ (crossover.m)
function children = crossover(parents, numChildren)
    [numParents, numAssets] = size(parents);
    children = zeros(numChildren, numAssets);
    alpha = 0.5;
    for i = 1:numChildren
        p1 = parents(randi(numParents), :);
        p2 = parents(randi(numParents), :);
        
        % Vectorizare completa (fara bucla for j=1:numAssets)
        cmin = min(p1, p2);
        cmax = max(p1, p2);
        range = cmax - cmin;
        
        low = max(0, cmin - range * alpha);
        high = min(1, cmax + range * alpha);
        
        % Generam un array de numere aleatoare dintr-o data
        children(i, :) = low + rand(1, numAssets) .* (high - low);
        
        % Normalizare
        children(i, :) = children(i, :) / sum(children(i, :));
    end
end