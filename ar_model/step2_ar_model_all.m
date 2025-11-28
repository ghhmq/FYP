function step2_ar_model_all()
% STEP 2: 对每个区域拟合简单 AR(p) 模型（这里只用 CO2 自身的滞后）
%   y_t = a1 y_{t-1} + ... + ap y_{t-p} + e_t

    clear; clc; close all;
    regions = config_regions();
    p = 2;  % AR 阶数，可自行调整

    for i = 1:numel(regions)
        R = regions(i);
        T = readtable(R.csv);
        year = T.Year;
        y    = T.CO2;

        mask = ~isnan(year) & ~isnan(y);
        year = year(mask);
        y    = y(mask);

        n = numel(y);
        if n <= p+5
            warning('%s 数据太短，无法拟合 AR(%d)。', R.label, p);
            continue;
        end

        % 构造滞后矩阵 Ylag: [y_{t-1} ... y_{t-p}]
        Ylag = nan(n,p);
        for k = 1:p
            Ylag((1+k):end, k) = y(1:end-k);
        end

        regMask = all(~isnan(Ylag), 2);
        y_reg   = y(regMask);
        X_reg   = Ylag(regMask,:);

        mdl = fitlm(X_reg, y_reg);  % 数值矩阵版本
        yhat = nan(size(y));
        yhat(regMask) = predict(mdl, X_reg);

        fprintf('\n=== %s — AR(%d) ===\n', R.label, p);
        disp(mdl);

        % 可视化
        f = figure('Color','w','Position',[80 80 900 380]);
        plot(year, y, '-o','LineWidth',1.4); hold on;
        plot(year, yhat, '-s','LineWidth',1.4);
        grid on;
        xlabel('Year'); ylabel('CO2');
        title(sprintf('AR(%d) fit — %s', p, R.label));
        legend('Actual','AR fit','Location','best');
        exportgraphics(f, sprintf('step2_ar%d_%s.png', p, R.id), 'Resolution',300);
    end

    disp('Step2: AR 模型拟合图已生成。');
end
