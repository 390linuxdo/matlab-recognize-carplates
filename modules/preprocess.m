% preprocess.m
% 图像预处理模块 - 灰度转换和边缘检测
%
% 输入:
%   img - 原始彩色图像
%   outputDir - 输出目录（用于保存中间结果）
% 输出:
%   grayImg - 灰度图像
%   edgeImg - 边缘检测图像
%
% 功能:
%   1. 将彩色图像转换为灰度图
%   2. 使用Roberts算子进行边缘检测
%   3. 保存中间结果到输出目录

function [grayImg, edgeImg] = preprocess(img, outputDir)
% ==================== 1. 灰度转换 ====================
if size(img, 3) == 3
    grayImg = rgb2gray(img);
else
    grayImg = img;
end

% ==================== 2. 边缘检测 ====================
% 使用Roberts算子，阈值0.15-0.18
edgeImg = edge(grayImg, 'roberts', 0.15, 'both');

% ==================== 3. 保存中间结果 ====================
if nargin >= 2 && ~isempty(outputDir)
    % 保存原图
    imwrite(img, fullfile(outputDir, '01_原图.jpg'));

    % 保存灰度图
    imwrite(grayImg, fullfile(outputDir, '02_灰度图.jpg'));

    % 保存边缘检测结果
    imwrite(edgeImg, fullfile(outputDir, '03_边缘检测.jpg'));

    % 保存灰度直方图
    fig = figure('Visible', 'off');
    imhist(grayImg);
    title('灰度直方图');
    saveas(fig, fullfile(outputDir, '02_灰度直方图.png'));
    close(fig);
end
end
