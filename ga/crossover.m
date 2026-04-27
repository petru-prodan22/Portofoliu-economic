function children = crossover(parents, numChildren)
    [numParents, numAssets] = size(parents);
    children = zeros(numChildren, numAssets);
    alpha = 0.5;
    for i = 1:numChildren
        p1 = parents(randi(numParents), :);
        p2 = parents(randi(numParents), :);
        for j = 1:numAssets
            cmin = min(p1(j), p2(j));
            cmax = max(p1(j), p2(j));
            range = cmax - cmin;
            low = max(0, cmin - range * alpha);
            high = min(1, cmax + range * alpha);
            children(i, j) = low + rand * (high - low);
        end
        children(i, :) = children(i, :) / sum(children(i, :));
    end
end