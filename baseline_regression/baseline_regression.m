%% step1_baseline_regression.m — Static OLS baseline
clear; clc; close all; load dataset.mat

tbl = T(:, ["Year", varsX, yname]);
formula = sprintf('%s ~ %s', yname, strjoin(varsX,' + '));
mdl = fitlm(tbl, formula);
disp(mdl)

yhat = predict(mdl, tbl);
res = tbl.(yname) - yhat;

f1 = figure('Color','w','Position',[80 80 900 420]);
plot(tbl.Year, tbl.(yname),'-o','LineWidth',1.4); hold on;
plot(tbl.Year, yhat,'-s','LineWidth',1.4); grid on;
legend('Actual','OLS fit','Location','best'); xlabel Year; ylabel CO2;
title('Baseline OLS: Actual vs Fit');
exportgraphics(f1,'ols_fit.png','Resolution',300);

f2 = figure('Color','w','Position',[80 80 900 420]);
subplot(2,1,1); plot(tbl.Year, res,'-','LineWidth',1.2); grid on;
xlabel Year; ylabel Residual; title('OLS residual (time series)');
subplot(2,1,2); histogram(res,10); grid on; xlabel Residual; title('Residual histogram');
exportgraphics(f2,'ols_residuals.png','Resolution',300);
