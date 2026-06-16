function [val, V] = fobiectiv(Q, rmed, B, alpha, ro, Rp, x)
    % Calculeaza portofoliul complet 'y' [cite: 394]
    y = alpha + B * x;
    
    % Varianta portofoliului (Riscul pur) [cite: 396-397]
    V = y' * Q * y;
    
    % Functia de penalizare ceruta de problema RISCMIN1M [cite: 398-403]
    penalizare = (ro / Rp^2) * (rmed' * y - Rp)^2;
    
    % Costul final de minimizat
    val = V + penalizare;
end