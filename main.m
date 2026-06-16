%% === MASTER SCRIPT: EVOLUTIONARY COMPUTING FOR PORTFOLIO OPTIMIZATION ===
% Case Studies: RISCMIN1M (Minimum Risk) & RANDMAX1M (Maximum Return)
clear; clc; close all;

fisier_date = 'Date_companii_5y.csv';
ro = 100;   % Penalty factor (rho)

% Heuristic Algorithms Parameters
dim_ga = 50; NMAX_ga = 200; pc = 0.8; pm = 0.1; alfa_cross = 0.5; sigma_ga = 0.1;
dim_es = 30; NMAX_es = 200; eps_sigma = 1e-4;

%% 1. Data Loading
disp('>>> LOADING STOCK MARKET DATA...');
[Q, rmed, alpha, B, nr_actiuni, nume_companii] = citeste_date(fisier_date);

%% ================= PART 1: MINIMUM RISK (RISCMIN1M) =================
disp(' '); 
disp('>>> CASE STUDY 1: MINIMUM RISK (Target Return: 15%)');
Rp_tinta = 0.15;  

% 1. Newton Method (Analytical Benchmark)
tic;
[sol_x_nw, sol_y_nw, cost_nw, risc_nw, iter_nw] = metoda_newton(Q, rmed, B, alpha, ro, Rp_tinta, nr_actiuni);
t_nw = toc;

% 2. Genetic Algorithm (GA)
tic;
[sol_x_ga, val_max_ga, istoric_ga] = algoritm_genetic(@fobiectiv, Q, rmed, B, alpha, ro, Rp_tinta, nr_actiuni, ...
                                     dim_ga, NMAX_ga, pc, pm, alfa_cross, sigma_ga);
t_ga = toc;
sol_y_ga = alpha + B * sol_x_ga';
[cost_ga, risc_ga] = fobiectiv(Q, rmed, B, alpha, ro, Rp_tinta, sol_x_ga'); 

% 3. Evolutionary Strategies (ES)
tic;
[sol_x_es, val_max_es, istoric_es] = strategii_evolutive(Q, rmed, B, alpha, ro, Rp_tinta, nr_actiuni, dim_es, NMAX_es, eps_sigma);
t_es = toc;
sol_y_es = alpha + B * sol_x_es';
[cost_es, risc_es] = fobiectiv(Q, rmed, B, alpha, ro, Rp_tinta, sol_x_es'); 

% --- Performance Table ---
disp('==================================================================');
disp('           PERFORMANCE COMPARISON (Target Return: 15%)            ');
disp('==================================================================');
Method = {'Newton (Analytical)'; 'Genetic Algorithm (GA)'; 'Evolutionary Strategies (ES)'};
Time_Seconds = [t_nw; t_ga; t_es];
Total_Cost = [cost_nw; cost_ga; cost_es];
Isolated_Risk_V = [risc_nw; risc_ga; risc_es];
Expected_Return = [rmed'*sol_y_nw; rmed'*sol_y_ga; rmed'*sol_y_es] * 100;

performance_table = table(Method, Time_Seconds, Total_Cost, Isolated_Risk_V, Expected_Return);
disp(performance_table);

disp('------------------------------------------------------------------');
disp('OPTIMAL PORTFOLIO WEIGHTS [%]:');
weights_table = table(nume_companii, sol_y_nw*100, sol_y_ga*100, sol_y_es*100, ...
    'VariableNames', {'Company', 'Newton_Pct', 'GA_Pct', 'ES_Pct'});
disp(weights_table);

% --- SALVARE TABELE ---
disp('>>> Saving tables to CSV files...');
writetable(performance_table, 'Table1_Performance_Comparison.csv');
writetable(weights_table, 'Table2_Optimal_Weights.csv');

%% ================= PART 2: DUALITY TEST (RANDMAX1M) =================
disp(' '); 
disp('>>> CASE STUDY 2: MAXIMUM RETURN (Mathematical Duality Test)');
% We extract the optimal risk found by GA in Part 1 and enforce it as the Maximum Risk allowed
Vac_impus = risc_ga; 
disp(['Enforcing maximum allowed risk (V): ', num2str(Vac_impus)]);
disp('If the algorithm is accurate, the found return should bounce back to approx 15%!');

[sol_x_rmax, ~, ~] = algoritm_genetic(@fobiectiv_randmax, Q, rmed, B, alpha, ro, Vac_impus, nr_actiuni, ...
                                     dim_ga, NMAX_ga, pc, pm, alfa_cross, sigma_ga);
sol_y_rmax = alpha + B * sol_x_rmax';
randament_rmax = rmed' * sol_y_rmax;

disp(['Maximum Expected Return found by RANDMAX1M: ', num2str(randament_rmax * 100), '%']);

%% ================= PART 3: GENERATING & SAVING ENGLISH CHARTS =================
disp(' '); disp('>>> GENERATING AND SAVING CHARTS FOR DISSERTATION...');

% --- CHART 1: Convergence Speed ---
fig1 = figure('Name', 'Convergence Analysis', 'Color', 'w');
cost_istoric_ga = (1 - istoric_ga) ./ istoric_ga;
cost_istoric_es = (1 - istoric_es) ./ istoric_es;

plot(1:length(cost_istoric_ga), cost_istoric_ga, 'b-', 'LineWidth', 2); hold on;
plot(1:length(cost_istoric_es), cost_istoric_es, 'r--', 'LineWidth', 2);
line([1 max(length(cost_istoric_ga), length(cost_istoric_es))], [cost_nw cost_nw], 'Color', 'g', 'LineStyle', ':', 'LineWidth', 1.5);

xlabel('Generation / Iteration', 'FontWeight', 'bold'); 
ylabel('Objective Function Cost', 'FontWeight', 'bold');
title('1. Convergence Speed: GA vs. ES vs. Newton', 'FontSize', 12);
legend('Genetic Algorithm (GA)', 'Evolutionary Strategies (ES)', 'Newton Analytical Optimum', 'Location', 'northeast'); 
grid on;
saveas(fig1, 'Chart1_Convergence.png');

% --- CHART 2: Duality (MinRisk vs MaxReturn) ---
fig2 = figure('Name', 'Duality RiscMin vs RandMax', 'Color', 'w');
b = bar([sol_y_ga*100, sol_y_rmax*100]);
b(1).FaceColor = [0.2 0.6 0.8]; % Blueish for MinRisk
b(2).FaceColor = [0.8 0.4 0.2]; % Orangeish for MaxReturn

set(gca, 'XTickLabel', nume_companii, 'XTick', 1:nr_actiuni);
xtickangle(45);
ylabel('Invested Percentage [%]', 'FontWeight', 'bold');
title('2. Portfolio Comparison: Minimum Risk vs. Maximum Return', 'FontSize', 12);
legend(['Min. Risk (Target R = ', num2str(Rp_tinta*100), '%)'], ...
       ['Max. Return (Target V = ', num2str(Vac_impus, 4), ')'], ...
       'Location', 'northwest');
grid on;
saveas(fig2, 'Chart2_Duality.png');

% --- CHART 3: Optimal Distribution (Pie Chart) ---
% Filter out negligible fractions (< 1%) for a clean pie chart
idx_investit = sol_y_ga > 0.01; 
fig3 = figure('Name', 'Portfolio Distribution', 'Color', 'w');
pie(sol_y_ga(idx_investit), nume_companii(idx_investit));
title('3. Optimal Investment Distribution (Calculated via GA)', 'FontSize', 12);
saveas(fig3, 'Chart3_Portfolio_Pie.png');

% --- CHART 4: Markowitz Efficient Frontier ---
disp('Calculating Markowitz Efficient Frontier (this takes a few seconds)...');
Rp_valori = 0.05:0.02:0.25; 
riscuri_asociate = zeros(length(Rp_valori), 1);
for i = 1:length(Rp_valori)
    [sol_tmp, ~, ~] = algoritm_genetic(@fobiectiv, Q, rmed, B, alpha, ro, Rp_valori(i), nr_actiuni, dim_ga, 80, pc, pm, alfa_cross, sigma_ga);
    [~, r_tmp] = fobiectiv(Q, rmed, B, alpha, ro, Rp_valori(i), sol_tmp');
    riscuri_asociate(i) = r_tmp;
end

fig4 = figure('Name', 'Markowitz Efficient Frontier', 'Color', 'w');
plot(riscuri_asociate, Rp_valori * 100, 'b-o', 'LineWidth', 2, 'MarkerFaceColor', 'r');
xlabel('Risk (Variance V)', 'FontWeight', 'bold'); 
ylabel('Expected Return [%]', 'FontWeight', 'bold');
title('4. Efficient Portfolio Frontier', 'FontSize', 12); 
grid on;
saveas(fig4, 'Chart4_Efficient_Frontier.png');

disp('>>> COMPLETE! All tables and charts have been successfully saved to your folder.');