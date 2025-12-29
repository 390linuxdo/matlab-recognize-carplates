% qiege.m
% 边缘裁剪函数 - 去除二值图像的空白边缘
%
% 输入:
%   d - 二值图像矩阵
% 输出:
%   e - 裁剪后的图像（最小包围矩形）
%
% 功能:
%   从上下左右四个方向扫描，找到实际内容的边界
%   返回只包含有效内容的最小矩形区域

function e = qiege(d)
[m, n] = size(d);

% 初始化边界
top = 1;
bottom = m;
left = 1;
right = n;

% 从上向下找到第一个非空行
while top <= m && sum(d(top, :)) == 0
    top = top + 1;
end

% 从下向上找到第一个非空行
while bottom > 1 && sum(d(bottom, :)) == 0
    bottom = bottom - 1;
end

% 从左向右找到第一个非空列
while left < n && sum(d(:, left)) == 0
    left = left + 1;
end

% 从右向左找到第一个非空列
while right >= 1 && sum(d(:, right)) == 0
    right = right - 1;
end

% 计算裁剪区域的宽度和高度
width = right - left;
height = bottom - top;

% 裁剪图像
if width > 0 && height > 0
    e = imcrop(d, [left, top, width, height]);
else
    e = d; % 如果图像为空，返回原图
end
end
