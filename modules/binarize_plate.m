% binarize_plate.m
% 车牌二值化模块 - 将车牌图像转换为二值图
%
% 输入:
%   plateImg - 车牌彩色图像
%   outputDir - 输出目录（用于保存中间结果）
% 输出:
%   binaryImg - 二值化后的车牌图像
%
% 功能:
%   1. 转换为灰度图
%   2. 自适应阈值二值化
%   3. 均值滤波去噪
%   4. 膨胀或腐蚀调整

function binaryImg = binarize_plate(plateImg, outputDir)
% ==================== 1. 灰度转换 ====================
if size(plateImg, 3) == 3
    grayPlate = rgb2gray(plateImg);
else
    grayPlate = plateImg;
end

% ==================== 2. 自适应阈值二值化 ====================
g_max = double(max(max(grayPlate)));
g_min = double(min(min(grayPlate)));

% 阈值 = 最大值 - (最大值-最小值)/3
T = round(g_max - (g_max - g_min) / 3);

% 二值化
binaryImg = double(grayPlate) >= T;

% 保存二值化结果
if nargin >= 2 && ~isempty(outputDir)
    imwrite(binaryImg, fullfile(outputDir, '06_二值化.jpg'));
end

% ==================== 3. 均值滤波 ====================
h = fspecial('average', 3);  % 3x3 均值滤波模板
binaryImg = im2bw(round(filter2(h, binaryImg)));

% 保存滤波结果
if nargin >= 2 && ~isempty(outputDir)
    imwrite(binaryImg, fullfile(outputDir, '07_均值滤波.jpg'));
end

% ==================== 4. 膨胀或腐蚀调整 ====================
se = eye(2);  % 2x2单位矩阵作为结构元素
[m, n] = size(binaryImg);

% 计算白色区域占比
ratio = bwarea(binaryImg) / m / n;

if ratio >= 0.365
    % 白色区域过多，进行腐蚀
    binaryImg = imerode(binaryImg, se);
elseif ratio <= 0.235
    % 白色区域过少，进行膨胀
    binaryImg = imdilate(binaryImg, se);
end

% 保存最终二值化结果
if nargin >= 2 && ~isempty(outputDir)
    imwrite(binaryImg, fullfile(outputDir, '08_形态学调整.jpg'));
end
end
