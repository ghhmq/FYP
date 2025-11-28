%% step5_hybrid_arx_plus_ml.m — ARX main + ML residuals (matrix version, fixed)
clear; clc; close all;
load dataset.mat   % T, varsX, yname

py=1; pu=1;
X = []; 
% y 滞后
if py>0
    X = [X lagmatrix(T.(yname), 1:py)];
end
% 外生变量 0..pu 期
for v = varsX
    X = [X lagmatrix(T.(v), 0:pu)];
end
y = T.(yname);

% 统一掩码
mask = all(~isnan([y X]),2);

% ===== 1) 线性 ARX 主体 =====
mdl = fitlm(X(mask,:), y(mask));           % <-- 用数值矩阵版本
yhat_arx = nan(size(y));
yhat_arx(mask) = predict(mdl, X(mask,:));  % <-- 同样用矩阵做 predict

% ===== 2) 用 ML 拟合残差（梯度提升）=====
res = y - yhat_arx;
M = fitrensemble(X(mask,:), res(mask), ...
    'Method','LSBoost','NumLearningCycles',300,'Learners','tree');
res_hat = nan(size(res));
res_hat(mask) = predict(M, X(mask,:));

% ===== 3) 混合预测 =====
yhat_hybrid = yhat_arx + res_hat;

% ===== 4) 可视化 =====
f = figure('Color','w','Position',[80 80 900 420]);
plot(T.Year, y,'-o'); hold on;
plot(T.Year, yhat_arx,'-s');
plot(T.Year, yhat_hybrid,'-^');
grid on; legend('Actual','ARX','Hybrid(ARX+ML)','Location','best');
xlabel Year; ylabel CO2; title('Hybrid model');
exportgraphics(f,'hybrid_fit.png','Resolution',300);

