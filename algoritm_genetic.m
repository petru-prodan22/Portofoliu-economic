function [sol_optima, val_maxima, istoric_v] = algoritm_genetic(fobj_handle, Q, rmed, B, alpha, ro, tinta, nr_actiuni, dim, NMAX, pc, pm, alfa_cross, sigma)
    % Am adaugat fobj_handle la inceput si am redenumit Rp in tinta
    
    % 1. Generarea populatiei initiale 
    pop = zeros(dim, nr_actiuni);
    for i = 1:dim
        x = gen_cr(nr_actiuni); % Fara short selling
        pop(i, 1:nr_actiuni-1) = x;
        
        % Aici intervine magia: apelam functia transmisa ca parametru!
        [val_fob, ~] = fobj_handle(Q, rmed, B, alpha, ro, tinta, x');
        
        pop(i, nr_actiuni) = 1 / (val_fob + 1); % Maximizam 1/(1+F) 
    end
    
    istoric_v = max(pop(:, nr_actiuni)); 
    gata = false; it = 0;
    
    % 2. Bucla de evolutie 
    while it < NMAX && ~gata
        % Selectia (Ruleta) 
        [pop_s, sval] = ruleta_local(pop(:, 1:nr_actiuni-1), pop(:, nr_actiuni), dim);
        pop_parinti = [pop_s, sval];
        
        % Crossover Aritmetic Total (transmitem tinta si fobj_handle mai departe)
        pop_o = crossover_populatie(pop_parinti, dim, nr_actiuni, Q, rmed, B, alpha, ro, tinta, pc, alfa_cross, fobj_handle);
        
        % Mutatia Fluaj (transmitem tinta si fobj_handle mai departe)
        pop_mo = mutatie_populatie(pop_o, dim, nr_actiuni, Q, rmed, B, alpha, ro, tinta, pm, sigma, fobj_handle);
        
        % Elitism 
        [newpop, newval] = elitism_local(pop(:, 1:nr_actiuni-1), pop(:, nr_actiuni), pop_mo(:, 1:nr_actiuni-1), pop_mo(:, nr_actiuni));
        
        minim = min(newval); maxim = max(newval);
        if maxim == minim
            gata = true; 
        else
            it = it + 1;
            istoric_v(end+1) = maxim; 
            pop(:, 1:nr_actiuni-1) = newpop;
            pop(:, nr_actiuni) = newval;
        end
    end
    
    [val_maxima, idx_sol] = max(pop(:, nr_actiuni));
    sol_optima = pop(idx_sol(1), 1:nr_actiuni-1);
end

%% --- FUNCTII LOCALE PENTRU GA ---

function c = gen_cr(nr_actiuni)
    % Generare aleatoare cu suma <= 1 
    c = zeros(1, nr_actiuni - 1);
    s = 0; i = 0; generat = false(1, nr_actiuni - 1);
    while i < nr_actiuni - 1 && s < 1
        j = randi([1, nr_actiuni - 1]);
        while generat(j), j = randi([1, nr_actiuni - 1]); end
        c(j) = rand(); s = sum(c); generat(j) = true;
        if s > 1, c(j) = c(j) - (s - 1); s = 1; else, i = i + 1; end
    end
end

function po = crossover_populatie(pop, dim, nr_actiuni, Q, rmed, B, alpha, ro, tinta, pc, alfa_cross, fobj_handle)
    % Crossover aritmetic 
    po = pop;
    for i = 1:2:(dim-1)
        if rand() <= pc
            x = pop(i, 1:nr_actiuni-1); y = pop(i+1, 1:nr_actiuni-1);
            c1 = alfa_cross * x + (1 - alfa_cross) * y;
            c2 = alfa_cross * y + (1 - alfa_cross) * x;
            
            po(i, 1:nr_actiuni-1) = c1; 
            [v1, ~] = fobj_handle(Q, rmed, B, alpha, ro, tinta, c1'); 
            po(i, nr_actiuni) = 1/(1+v1);
            
            po(i+1, 1:nr_actiuni-1) = c2; 
            [v2, ~] = fobj_handle(Q, rmed, B, alpha, ro, tinta, c2'); 
            po(i+1, nr_actiuni) = 1/(1+v2);
        end
    end
end

function mpop = mutatie_populatie(pop, dim, nr_actiuni, Q, rmed, B, alpha, ro, tinta, pm, sigma, fobj_handle)
    % Mutatie cu fluaj (fara short selling) 
    mpop = pop;
    for i = 1:dim
        x = pop(i, 1:nr_actiuni-1); mutat = false;
        for j = 1:nr_actiuni-1
            if rand() <= pm
                p = sigma * randn(); y = x(j) + p;
                if y > 1, y = 1; end; if y < 0, y = 0; end
                x(j) = y; s = sum(x);
                if s > 1, x(j) = max(0, x(j) - (s - 1)); end
                mutat = true;
            end
        end
        if mutat
            mpop(i, 1:nr_actiuni-1) = x; 
            [val, ~] = fobj_handle(Q, rmed, B, alpha, ro, tinta, x'); 
            mpop(i, nr_actiuni) = 1/(1+val);
        end
    end
end

function [spop, sval] = ruleta_local(pop_gene, pop_fit, dim)
    spop = zeros(size(pop_gene)); sval = zeros(size(pop_fit));
    fit_total = sum(pop_fit); prob_cumulata = cumsum(pop_fit / fit_total);
    for i = 1:dim
        idx = find(prob_cumulata >= rand(), 1, 'first');
        spop(i, :) = pop_gene(idx, :); sval(i) = pop_fit(idx);
    end
end

function [newpop, newval] = elitism_local(p_gen, p_fit, c_gen, c_fit)
    newpop = c_gen; newval = c_fit;
    [best_p_fit, i_p] = max(p_fit); [worst_c_fit, i_c] = min(newval);
    if best_p_fit > worst_c_fit
        newpop(i_c(1), :) = p_gen(i_p(1), :); newval(i_c(1)) = best_p_fit;
    end
end