function [sol_optima, val_maxima, istoric_v] = strategii_evolutive(Q, rmed, B, alpha, ro, Rp, nr_actiuni, dim, NMAX, eps_sigma)
    n_vars = nr_actiuni - 1;
    % Dimensiune cromozom: n_vars (solutii) + n_vars (sigma) + 1 (fitness)
    total_cols = 2 * n_vars + 1;
    
    % 1. Generarea populatiei initiale
    pop = zeros(dim, total_cols);
    for i = 1:dim
        x = gen_cr_local(nr_actiuni);
        pop(i, 1:n_vars) = x;
        
        % Initializare uniforma in intervalul [0.05, 0.5] pentru fiecare pas sigma
        pop(i, n_vars+1:2*n_vars) = 0.05 + (0.5 - 0.05) * rand(1, n_vars); 
        
        [val_fob, ~] = fobiectiv(Q, rmed, B, alpha, ro, Rp, x');
        pop(i, total_cols) = 1 / (val_fob + 1);
    end
    
    istoric_v = max(pop(:, total_cols));
    gata = false; 
    it = 0;
    lambda = 7 * dim; 
    
    % Constantele de invatare
    tau = 2 / sqrt(2 * sqrt(n_vars));
    tau_prime = 2 / sqrt(2 * n_vars);
    
    % 2. Bucla principala ES
    while it < NMAX && ~gata
        % Crossover Global Aritmetic
        pop_o = crossover_global_local(pop, dim, lambda, n_vars, total_cols);
        
        % Mutatie Auto-adaptiva
        pop_mo = mutatie_es_local(pop_o, lambda, n_vars, total_cols, Q, rmed, B, alpha, ro, Rp, tau, tau_prime, eps_sigma);
        
        % Selectie miu + lambda (Reuniune si sortare determinista)
        bazin_comun = [pop; pop_mo];
        bazin_comun = sortrows(bazin_comun, total_cols, 'descend');
        pop = bazin_comun(1:dim, :);
        
        maxim = pop(1, total_cols);
        minim = pop(dim, total_cols);
        
        if maxim == minim
            gata = true;
        else
            it = it + 1;
            istoric_v(end+1) = maxim;
        end
    end
    
    val_maxima = pop(1, total_cols);
    sol_optima = pop(1, 1:n_vars);
end

%% --- FUNCȚII LOCALE PENTRU ES ---
function c = gen_cr_local(nr_actiuni)
    c = zeros(1, nr_actiuni - 1);
    s = 0; 
    i = 0; 
    generat = false(1, nr_actiuni - 1);
    
    while i < nr_actiuni - 1 && s < 1
        j = randi([1, nr_actiuni - 1]);
        while generat(j)
            j = randi([1, nr_actiuni - 1]); 
        end
        
        c(j) = rand(); 
        s = sum(c); 
        generat(j) = true;
        
        if s > 1
            c(j) = c(j) - (s - 1); 
            s = 1; 
        else
            i = i + 1; 
        end
    end
end

function pop_o = crossover_global_local(pop, dim, lambda, n_vars, total_cols)
    pop_o = zeros(lambda, total_cols);
    for i = 1:lambda
        pop_o(i, 1:2*n_vars) = calcul_copil_varianta(pop, dim, n_vars);
    end
end

function copil = calcul_copil_varianta(pop, dim, n_vars)
    copil = zeros(1, 2 * n_vars);
    pozitii = randi([1, dim], n_vars, 2);
    
    % 1. Recombinarea aritmetica pentru partea parametrica
    for i = 1:n_vars
        poz = pozitii(i, :);
        copil(n_vars + i) = (pop(poz(1), n_vars + i) + pop(poz(2), n_vars + i)) / 2;
    end
    
    % 2. Recombinarea aritmetica pentru partea solutie
    generat = false(1, n_vars);
    cnt = 0; 
    s = 0;
    
    while cnt < n_vars && s < 1
        j = randi([1, n_vars]);
        while generat(j)
            j = randi([1, n_vars]);
        end
        poz = pozitii(j, :);
        copil(j) = (pop(poz(1), j) + pop(poz(2), j)) / 2;
        s = sum(copil(1:n_vars));
        generat(j) = true;
        
        if s > 1
            copil(j) = max(0, copil(j) - (s - 1));
            s = 1;
        else
            cnt = cnt + 1;
        end
    end
end

function pop_mo = mutatie_es_local(pop_o, lambda, n_vars, total_cols, Q, rmed, B, alpha, ro, Rp, tau, tau_prime, eps_sigma)
    pop_mo = pop_o;
    for i = 1:lambda
        x = pop_o(i, 1:n_vars);
        sigma = pop_o(i, n_vars+1:2*n_vars);
        
        zgomot_global = randn();
        mutat = false;
        
        for j = 1:n_vars
            sigma(j) = sigma(j) * exp(tau_prime * zgomot_global + tau * randn());
            
            if sigma(j) < eps_sigma
                sigma(j) = eps_sigma; 
            end
            
            p = sigma(j) * randn();
            y = x(j) + p;
            
            if y > 1
                y = 1; 
            elseif y < 0
                y = 0; 
            end
            
            x(j) = y;
            s = sum(x);
            
            if s > 1
                x(j) = max(0, x(j) - (s - 1));
            end
            mutat = true;
        end
        
        if mutat
            pop_mo(i, 1:n_vars) = x;
            pop_mo(i, n_vars+1:2*n_vars) = sigma;
            [val, ~] = fobiectiv(Q, rmed, B, alpha, ro, Rp, x');
            pop_mo(i, total_cols) = 1 / (1 + val);
        end
    end
end