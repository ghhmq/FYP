function step1_baseline_and_residual()
% STEP 1: 对 4 个区域做基准趋势回归 + 残差分析
%   y_t = beta0 + beta1 * t

    clear; clc; close all;
    regions = config_regions();

    for i = 1:numel(regions)
        R = regions(i);
        T = readtable(R.csv);
        year = T.Year;
        y    = T.CO2;

        % 只保留有效行
        mask = ~isnan(year) & ~isnan(y);
        year = year(mask);
        y    = y(mask);

        % 基准线性回归
        X = [ones(size(year)) year];
        beta = X \ y;
        yfit = X * beta;
        res  = y - yfit;

        fprintf('\n=== %s ===\n', R.label);
        fprintf('Baseline: y = %.3f + %.3f * t\n', beta(1), beta(2));

        % 图 1: 实际 vs Baseline 拟合
        f1 = figure('Color','w','Position',[80 80 900 380]);
        plot(year, y, 'o-','LineWidth',1.4); hold on;
        plot(year, yfit, '--','LineWidth',1.4);
        grid on;
        xlabel('Year'); ylabel('CO2');
        title(sprintf('Baseline trend fit — %s', R.label));
        legend('Actual','Baseline trend','Location','best');
        exportgraphics(f1, sprintf('step1_baseline_%s.png', R.id), 'Resolution',300);

        % 图 2: 残差时间序列 + 直方图
        f2 = figure('Color','w','Position',[80 80 1000 380]);
        subplot(1,2,1);
        plot(year, res,'-o','LineWidth',1.2);
        grid on; xlabel('Year'); ylabel('Residual');
        title(sprintf('Residuals over time — %s', R.label));

        subplot(1,2,2);
        histogram(res, 10);
        grid on; xlabel('Residual'); ylabel('Freq');
        title('Residual histogram');
        exportgraphics(f2, sprintf('step1_residual_%s.png', R.id), 'Resolution',300);
    end

    disp('Step1: Baseline + Residual 图已生成。');
end
