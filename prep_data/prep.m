%% step0_prep.m — Build/Load dataset and quick EDA
% 需要文件与本脚本同一文件夹：
%  - China_Energy_Inventory_1997-2022.xlsx
%  - China_CO2_Inventory_1997-2022_(IPCC_Sectoral_Emissions).xlsx
%  - clean_energy_emission_China_1997_2022.csv （若存在优先用）
% 产出：
%  - dataset.mat (T, varsX, yname)
%  - prep_inputs_trend.png / prep_co2_trend.png / prep_corr.png

clear; clc; close all;

energyFile = "China_Energy_Inventory_1997-2022.xlsx";
co2File    = "China_CO2_Inventory_1997-2022_(IPCC_Sectoral_Emissions).xlsx";
csvFile    = "clean_energy_emission_China_1997_2022.csv";

if exist(csvFile, "file")
    T = readtable(csvFile);
else
    warning('CSV not found. Will build from the two XLSX files ...');

    % ---------- CO2 (sum 表) ----------
    S = readtable(co2File,'Sheet','sum');
    names = lower(string(S.Properties.VariableNames));
    ycol = find(strcmpi(names, "scope_1_total"), 1);
    yname = "co2_scope1_total";
    if isempty(ycol)
        nonFuel = ["emission_inventory","scope_2_heat","scope_2_electricity","process"];
        fuelCols = setdiff(string(S.Properties.VariableNames), nonFuel, 'stable');
        CO2 = sum(S{:, fuelCols}, 2, 'omitnan');
    else
        CO2 = S{:, ycol};
    end
    yvarIdx = find(strcmpi(names,'emission_inventory'), 1);
    if ~isempty(yvarIdx), Year = S{:, yvarIdx}; else, Year = S{:,1}; end
    CO2tbl = table(Year, CO2, 'VariableNames', {'Year', char(yname)});

    % ---------- Energy：每年 sheet 汇总为四大类 ----------
    [~, sheets] = xlsfinfo(energyFile);
    years = [];
    for k = 1:numel(sheets)
        y = str2double(sheets{k});
        if ~isnan(y) && y>=1997 && y<=2022, years(end+1)=y; end
    end
    years = sort(unique(years));

    Eall = table();
    for y = years
        Te = readtable(energyFile, 'Sheet', num2str(y));
        % 丢单位行（若有）
        if height(Te)>0
            v = Te{1,1};
            if (iscell(v) && any(contains(string(v),"unit",'IgnoreCase',true))) || ...
               (ischar(v) && contains(string(v),"unit",'IgnoreCase',true)) || ...
               (isstring(v) && contains(v,"unit",'IgnoreCase',true))
                Te(1,:) = [];
            end
        end
        Te.Properties.VariableNames = matlab.lang.makeUniqueStrings(lower(string(Te.Properties.VariableNames)));
        data = Te(:, 2:width(Te));  % 第1列通常是行业名
        % 统一转数值
        for j=1:width(data)
            x = data.(j);
            if iscell(x), x = str2double(string(x)); end
            if ~isnumeric(x), x = str2double(string(x)); end
            data.(j) = x;
        end
        totals = varfun(@(x) sum(x,'omitnan'), data);
        row = totals; row.Year = y; row = movevars(row,"Year","Before",1);
        Eall = [Eall; row];
    end

    % 关键词聚合
    coalKeys = ["coal","raw_coal","cleaned_coal","washed_coal","briquettes","coke"];
    oilKeys  = ["oil","petroleum","gasoline","diesel","kerosene","fuel_oil","lpg","refinery_gas","other_petroleum"];
    gasKeys  = ["gas","natural_gas","coke_oven_gas","other_gas"];
    elecKeys = ["electric","electricity","kwh","power"];
    f = @(kw) ~cellfun(@isempty, regexp(lower(string(Eall.Properties.VariableNames)), strjoin(kw,"|"), 'once'));
    idxCoal = f(coalKeys); idxCoal(1)=false;
    idxOil  = f(oilKeys);  idxOil(1) =false;
    idxGas  = f(gasKeys);  idxGas(1) =false;
    idxElec = f(elecKeys); idxElec(1)=false;

    EnergyAgg = table(Eall.Year, ...
        sum(table2array(Eall(:,idxCoal)),2,'omitnan'), ...
        sum(table2array(Eall(:,idxOil )),2,'omitnan'), ...
        sum(table2array(Eall(:,idxGas )),2,'omitnan'), ...
        sum(table2array(Eall(:,idxElec)),2,'omitnan'), ...
        'VariableNames', {'Year','coal_total','oil_total','gas_total','elec_total'});

    T = innerjoin(EnergyAgg, CO2tbl, 'Keys','Year');
end

varsX = ["coal_total","oil_total","gas_total","elec_total"];
yname = "co2_scope1_total";
save dataset.mat T varsX yname

% ====== 可视化 ======
f1 = figure('Color','w','Position',[80 80 900 420]);
plot(T.Year, T{:,varsX}, 'LineWidth',1.5); grid on;
legend(strrep(varsX,'_','\_'),'Location','best'); xlabel Year; ylabel('Energy');
title('Inputs by fuel');
exportgraphics(f1,'prep_inputs_trend.png','Resolution',300);

f2 = figure('Color','w','Position',[80 80 900 420]);
plot(T.Year, T.(yname),'-o','LineWidth',1.6); grid on;
xlabel Year; ylabel('CO2'); title('CO2 (Scope 1 total)');
exportgraphics(f2,'prep_co2_trend.png','Resolution',300);

labels = [varsX yname];
C = corr(T{:,labels}, 'rows','pairwise');
f3 = figure('Color','w','Position',[80 80 680 520]);
imagesc(C); axis equal tight; colorbar;
set(gca,'XTick',1:numel(labels),'XTickLabel',strrep(labels,'_','\_'),...
        'YTick',1:numel(labels),'YTickLabel',strrep(labels,'_','\_'),...
        'XTickLabelRotation',30);
title('Correlation matrix');
exportgraphics(f3,'prep_corr.png','Resolution',300);

