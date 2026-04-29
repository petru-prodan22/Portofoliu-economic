function selected = selection(pop, fitness, numSelected)
    [popSize, numAssets] = size(pop);
    selected = zeros(numSelected, numAssets);
    
    tournamentSize = 3; % Standard in literatura de specialitate
    
    for i = 1:numSelected
        % Folosim randperm pentru a alege 3 participanti unici
        idx = randperm(popSize, tournamentSize);
        % Vedem care are fitness-ul cel mai mare
        [~, bestIdx] = max(fitness(idx));
        % Castigatorul merge in generatia urmatoare
        selected(i, :) = pop(idx(bestIdx), :);
    end
end