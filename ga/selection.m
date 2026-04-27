function selected = selection(pop, fitness)
    [popSize, numAssets] = size(pop);
    numSelected = floor(popSize / 2);
    selected = zeros(numSelected, numAssets);
    
    tournamentSize = 3; % Standard in literatura de specialitate
    
    for i = 1:numSelected
        % Alegem 3 indici aleatori
        idx = randi(popSize, [1, tournamentSize]);
        % Vedem care are fitness-ul cel mai mare
        [~, bestIdx] = max(fitness(idx));
        % Castigatorul merge in generatia urmatoare
        selected(i, :) = pop(idx(bestIdx), :);
    end
end