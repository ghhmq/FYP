%% step2_arx.m — Grid-search ARX (Econometrics Toolbox present)
% 说明：
% - 自动在 py ∈ [0..3], pu ∈ [0..3] 中网格搜索，按 AIC 选最优
% - 使用 lagmatrix 构造滞后项
% - 用统一 mask 对齐 y 与 X，避免维度不一致
% - 输出拟合图 arx_fit.png（300dpi）

clear; clc; close all;
load dataset.mat    % T, varsX, yname

% 搜索范围
maxLagY = 3;                 % AR 阶数
maxLagU = 3;                 % 输入滞后阶数（含 0 期）

bestAIC = inf;
best = struct();

for py = 0:maxLagY
    for pu = 0:maxLagU

        % ---------- 构造自回归滞后 ----------
        X = []; names = {};
        if py > 0
            Ylags = lagmatrix(T.(yname), 1:py);       % y 的 1..py 期
            X = [X Ylags];
            for k = 1:py
                names{end+1} = sprintf('y_lag%d', k); %#ok<SAGROW>
            end
        end

        % ---------- 构造外生变量滞后（含当期0期） ----------
        for iv = 1:numel(varsX)
            v = char(varsX(iv));
            Ulags = lagmatrix(T.(v), 0:pu);          % 0..pu 期
            X = [X Ulags];
            for k = 0:pu
                names{end+1} = sprintf('%s_lag%d', v, k); %#ok<SAGROW>
            end
        end

        % ---------- 统一 mask 对齐 ----------
        y = T.(yname);
        rowMask = all(~isnan(X), 2) & ~isnan(y);
        if nnz(rowMask) < 10
            continue;   % 有效样本太少，跳过
        end

        % ---------- 表格建模（y 最后一列） ----------
        tbl = array2table(X(rowMask, :), 'VariableNames', names);
        tbl.(yname) = y(rowMask);

        % ---------- 线性回归估计并记录 AIC ----------
        mdl = fitlm(tbl, sprintf('%s ~ %s', yname, strjoin(names,' + ')));
        aic = mdl.ModelCriterion.AIC;
        if aic < bestAIC
            bestAIC = aic;
            best.mdl   = mdl;
            best.py    = py;
            best.pu    = pu;
            best.names = names;
        end
    end
end

% ---------- 若没有找到可用模型 ----------
if ~isfield(best,'mdl') || isempty(best.mdl)
    error('未能找到可用的 ARX 模型（有效样本不足）。请检查数据或调整滞后范围。');
end

% ---------- 打印最优模型信息 ----------
fprintf('Best ARX by AIC: py = %d, pu = %d\n', best.py, best.pu);
disp(best.mdl)

% ---------- 复原整段时间的拟合曲线 ----------
Xfull = [];
if best.py > 0
    Xfull = [Xfull lagmatrix(T.(yname), 1:best.py)];
end
for iv = 1:numel(varsX)
    v = char(varsX(iv));
    Xfull = [Xfull lagmatrix(T.(v), 0:best.pu)];
end
y = T.(yname);
maskFull = all(~isnan(Xfull), 2) & ~isnan(y);

tblPred = array2table(Xfull(maskFull,:), 'VariableNames', best.names);
yhat_full = nan(size(y));
yhat_full(maskFull) = predict(best.mdl, tblPred);

% ---------- 可视化 ----------
f = figure('Color','w','Position',[80 80 900 420]);
plot(T.Year, y,'-o','LineWidth',1.4); hold on;
plot(T.Year, yhat_full,'-s','LineWidth',1.4);
grid on; legend('Actual','ARX fit','Location','best');
xlabel Year; ylabel CO2; title(sprintf('ARX Fit (py=%d, pu=%d)', best.py, best.pu));
exportgraphics(f,'arx_fit.png','Resolution',300);

