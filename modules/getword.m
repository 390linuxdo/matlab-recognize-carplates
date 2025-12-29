% getword.m
% 字符提取函数 - 从二值图像中提取单个字符
%
% 输入:
%   d - 二值化的车牌图像
% 输出:
%   word - 提取出的单个字符图像
%   result - 剩余的图像（用于继续提取下一个字符）
%
% 功能:
%   从左到右扫描图像，找到连续的非零列作为一个字符
%   过滤掉过窄的噪声干扰
%   返回提取的字符和剩余部分供后续提取

function [word, result] = getword(d)
word = [];
flag = 0;

% 参数设置
y1 = 8;     % 最小字符宽度阈值
y2 = 0.5;   % 宽高比阈值

while flag == 0
    [m, n] = size(d);

    % 找到第一个字符的宽度
    wide = 0;
    while wide <= n-2 && sum(d(:, wide+1)) ~= 0
        wide = wide + 1;
    end

    % 裁剪出候选字符区域
    temp = qiege(imcrop(d, [1, 1, wide, m]));
    [m1, n1] = size(temp);

    % 判断是否为有效字符（而非噪声）
    if wide < y1 && n1/m1 > y2
        % 太窄且宽高比不对，认为是噪声干扰
        d(:, 1:wide) = 0;
        if sum(sum(d)) ~= 0
            d = qiege(d);
        else
            word = [];
            flag = 1;
        end
    else
        % 有效字符
        word = qiege(imcrop(d, [1, 1, wide, m]));
        d(:, 1:wide) = 0;

        if sum(sum(d)) ~= 0
            d = qiege(d);
            flag = 1;
        else
            d = [];
            flag = 1;
        end
    end
end

result = d;
end
