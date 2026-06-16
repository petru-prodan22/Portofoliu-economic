function [val, R_portofoliu] = fobiectiv_randmax(Q, rmed, B, alpha, ro, Vac, x)
    % Construim portofoliul
    y = alpha + B * x;
    
    % Randamentul curent al portofoliului (pe care vrem sa-l tragem in sus)
    R_portofoliu = rmed' * y;
    
    % Riscul curent (Varianta)
    V_curent = y' * Q * y;
    
    % Functia de minimizat RANDMAX1M: 
    % Minimizam (minus Randamentul) + Penalizarea daca riscul sare de tinta Vac
    penalizare = (ro / Vac^2) * (V_curent - Vac)^2;
    val = -R_portofoliu + penalizare; 
end