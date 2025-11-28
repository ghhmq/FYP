%% step3_arimax.m — ARIMAX or diff-OLS fallback (fixed diff construction)
clear; clc; close all;
load dataset.mat   % T, varsX, yname

y    = T.(yname);           % n×1
Xexo = T{:, varsX};         % n×p (numeric)

% ---- 正确的差分构造：行数与 dy 对齐为 n ----
dy = [NaN; diff(y)];                    % n×1
dX = [NaN(1,size(Xexo,2)); diff(Xexo)]; % n×p  ← 顶部补一行 NaN

% 统一掩码（去掉任何 NaN 的行）
mask  = ~any(isnan([dy dX]), 2);
dy_m  = dy(mask);
dX_m  = dX(mask,:);
years = T.Year(mask);

try
    % ====== ARIMAX（带外生变量的 ARIMA，差分序列）======
    M = arima('Constant',0,'D',0,'ARLags',1,'MALags',0);
    M = estimate(M, dy_m, 'X', dX_m, 'Display','off');

    % 拟合得到的残差均值为 0，使用 infer 得到拟合的“差分水平”
    [yhatd, ~] = infer(M, dy_m, 'X', dX_m);

    % 把差分序列还原到水平（累加到起点）
    startLevel = y(find(mask,1)-1);      % 差分对应的“起点”是掩码第一行的前一时期
    yhat_level = cumsum([startLevel; yhatd]);

    % 可视化（对齐掩码）
    f = figure('Color','w','Position',[80 80 900 420]);
    plot(T.Year, y,'-o'); hold on;
    plot([T.Year(find(mask,1)-1); years], yhat_level,'-s');
    grid on; legend('Actual','ARIMAX (inferred level)','Location','best');
    xlabel Year; ylabel CO2; title('ARIMAX with exogenous regressors');
    exportgraphics(f,'arimax_fit.png','Resolution',300);

catch
    warning('Econometrics Toolbox ARIMA失败或不可用，使用差分OLS + AR(1)兜底。');

    % 兜底：差分OLS + 滞后项（proxy ARIMAX）
    Xfallback = [dX lagmatrix(dy,1)];    % n×(p+1)
    m2 = all(~isnan(Xfallback),2) & ~isnan(dy);
    mdl = fitlm(Xfallback(m2,:), dy(m2));

    yhatd = NaN(size(dy));
    yhatd(m2) = predict(mdl, Xfallback(m2,:));

    startLevel = y(find(m2,1)-1);
    yhat_level = cumsum([startLevel; yhatd(m2)]);

    f = figure('Color','w','Position',[80 80 900 420]);
    plot(T.Year, y,'-o'); hold on;
    plot([T.Year(find(m2,1)-1); T.Year(m2)], yhat_level,'-s');
    grid on; legend('Actual','Diff-OLS (proxy ARIMAX)','Location','best');
    xlabel Year; ylabel CO2; title('ARIMAX fallback');
    exportgraphics(f,'arimax_fallback.png','Resolution',300);
end

