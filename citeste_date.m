function [Q, rmed, alpha, B, nr_actiuni, nume_companii] = citeste_date(nume_fisier)
    % 1. Citim fisierul inteligent cu headere
    T = readtable(nume_fisier);
    nume_companii = T.Properties.VariableNames(2:end)';
    
    % 2. Extragem doar coloanele numerice
    R = table2array(T(:, 2:end));
    [nr_obs, nr_actiuni] = size(R);
    
    % 3. Matricele B si alpha pentru restrictia sumei
    B = [eye(nr_actiuni-1); -ones(1, nr_actiuni-1)];
    alpha = [zeros(nr_actiuni-1, 1); 1];
    
    % 4. Randamentul mediu si Covarianta ANUALIZATE pentru datele tale
    rmed = mean(R)' * 252;      %
    Q = cov(R) * 252;           %
end