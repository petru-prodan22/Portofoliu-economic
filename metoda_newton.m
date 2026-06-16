function [sol_x, sol_y, cost_minim, risc, iteratii] = metoda_newton(Q, rmed, B, alpha, ro, Rp, nr_actiuni)
    % Constantele matematice pentru Gradient si Hessian
    rho_bar = ro / (Rp^2);
    Rx = B' * rmed;
    Vxx = 2 * B' * Q * B;
    
    % Hessianul (Fxx) este constant pentru problema RISCMIN1M
    Fxx = Vxx + 2 * rho_bar * (Rx * Rx'); 
    
    % Initializare: punct de start egal distribuit
    x = (1/nr_actiuni) * ones(nr_actiuni - 1, 1); 
    toleranta = 1e-5 * sqrt(nr_actiuni);
    eroare = 1; 
    iteratii = 0;
    
    while eroare > toleranta && iteratii < 1000
        R_curent = rmed' * (alpha + B * x);
        Vx = 2 * B' * Q * (alpha + B * x);
        
        % Calculul Gradientului analitic
        Fx = Vx + 2 * rho_bar * (R_curent - Rp) * Rx; 
        
        % Directia de coborare (Newton step)
        p = - Fxx \ Fx; 
        x = x + p;
        
        eroare = norm(Fx);
        iteratii = iteratii + 1;
    end
    
    sol_x = x';
    sol_y = alpha + B * x;
    [cost_minim, risc] = fobiectiv(Q, rmed, B, alpha, ro, Rp, x);
end