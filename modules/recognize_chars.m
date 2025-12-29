% recognize_chars.m
% 字符识别模块 - 使用模板匹配识别字符
%
% 输入:
%   chars - 1x7 cell数组，包含7个字符图像（40x20）
%   templateDir - 字符模板目录
% 输出:
%   result - 识别结果字符串
%   confidence - 每个字符的置信度（可选）
%
% 功能:
%   1. 遍历模板库
%   2. 计算像素差值
%   3. 选择最小误差的匹配结果

function [result, confidence] = recognize_chars(chars, templateDir)
% ==================== 字符集定义 ====================
% 数字 + 字母 + 省份
digits = '0123456789';
letters = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
provinces = '京沪津渝冀豫云辽黑湘皖鲁新苏浙赣鄂桂甘晋蒙陕吉闽贵粤青藏川宁琼';

allChars = [digits, letters, provinces];

result = '';
confidence = zeros(1, 7);

% ==================== 逐个识别 ====================
for i = 1:7
    charImg = chars{i};

    % 确保是二值图像
    if max(charImg(:)) > 1
        charImg = double(charImg) > 20;
    else
        charImg = double(charImg);
    end

    % 确保尺寸正确
    charImg = imresize(charImg, [40, 20], 'nearest');

    % 确定搜索范围
    if i == 1
        % 第一位：只搜索省份汉字
        searchChars = provinces;
    elseif i == 2
        % 第二位：只搜索字母
        searchChars = letters;
    else
        % 第3-7位：搜索数字和字母
        searchChars = [digits, letters];
    end

    % 计算与每个模板的差异
    minError = inf;
    bestMatch = '?';

    for j = 1:length(searchChars)
        templateChar = searchChars(j);

        % 读取模板
        templatePath = fullfile(templateDir, [templateChar, '.bmp']);
        if ~exist(templatePath, 'file')
            % 尝试jpg格式
            templatePath = fullfile(templateDir, [templateChar, '.jpg']);
        end

        if exist(templatePath, 'file')
            templateImg = imread(templatePath);

            % 转为二值
            if size(templateImg, 3) == 3
                templateImg = rgb2gray(templateImg);
            end
            templateImg = double(templateImg) > 1;
            templateImg = imresize(templateImg, [40, 20], 'nearest');

            % 计算像素差值
            diff = abs(charImg - templateImg);
            error = sum(diff(:));

            if error < minError
                minError = error;
                bestMatch = templateChar;
            end
        end
    end

    % 记录结果
    result = [result, bestMatch];

    % 计算置信度（误差越小置信度越高）
    maxPossibleError = 40 * 20;  % 最大可能误差
    confidence(i) = 1 - (minError / maxPossibleError);
end
end
