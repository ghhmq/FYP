function prep_regions_from_timeextended()
% 从 timeextended.csv 中提取 4 条区域序列：
%   Americas_UN_              -> 美洲
%   Europe_UN_                -> 欧洲
%   Non_OECDEuropeAndEurasia  -> 俄罗斯代理
%   Oceania_UN_               -> 澳大利亚/大洋洲代理
%
% 输出：
%   co2_americas_un.csv
%   co2_europe_un.csv
%   co2_non_oecd_eur_eurasia.csv
%   co2_oceania_un.csv

    %% 1. 读入总表
    T = readtable("timeextended.csv");

    disp('=== 列名检查 ===');
    disp(T.Properties.VariableNames');

    %% 2. 年份列：在这个表里叫 millionTonnesOfCO2
    yearVar = 'millionTonnesOfCO2';
    if ~ismember(yearVar, T.Properties.VariableNames)
        error('找不到年份列 millionTonnesOfCO2，请检查源文件。');
    end

    years = T.(yearVar);

    % 如果年份不是数值，转成 double
    if iscellstr(years) || isstring(years) || iscategorical(years)
        years = str2double(string(years));
    end

    %% 3. 需要提取的 4 个区域列（这些名字与你给出的完全一致）
    regionVars = {
        'Americas_UN_',              'co2_americas_un.csv';
        'Europe_UN_',                'co2_europe_un.csv';
        'Non_OECDEuropeAndEurasia',  'co2_non_oecd_eur_eurasia.csv';
        'Oceania_UN_',               'co2_oceania_un.csv';
        };

    %% 4. 逐列提取并写成 CSV（Year, CO2）
    for k = 1:size(regionVars,1)
        colName = regionVars{k,1};
        outFile = regionVars{k,2};

        if ~ismember(colName, T.Properties.VariableNames)
            warning('⚠ 找不到列 %s，已跳过。', colName);
            continue;
        end

        co2 = T.(colName);

        % 构造子表：Year + CO2
        Sub = table(years, co2, 'VariableNames', {'Year','CO2'});

        % 删除缺失行
        Sub = rmmissing(Sub);

        % 写 CSV
        writetable(Sub, outFile);
        fprintf('已保存 %-30s  (%d 行)\n', outFile, height(Sub));
    end

    disp('=== 4 个区域已提取完毕 ===');
end
