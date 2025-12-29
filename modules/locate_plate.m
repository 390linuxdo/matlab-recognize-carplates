% locate_plate.m
% 车牌定位模块 - 使用形态学处理和投影法定位车牌
%
% 输入:
%   edgeImg - 边缘检测后的图像
%   originalImg - 原始彩色图像
%   outputDir - 输出目录（用于保存中间结果）
% 输出:
%   plateImg - 裁剪出的车牌彩色图像
%   plateRect - 车牌位置 [x, y, width, height]
%
% 功能:
%   1. 形态学腐蚀操作
%   2. 形态学闭运算（填充空隙）
%   3. 去除小对象
%   4. 垂直和水平投影定位车牌区域
%   5. 裁剪车牌

function [plateImg, plateRect] = locate_plate(edgeImg, originalImg, outputDir)
% ==================== 1. 形态学腐蚀 ====================
se1 = [1; 1; 1];  % 垂直结构元素
I_erode = imerode(edgeImg, se1);

% ==================== 2. 形态学闭运算 ====================
se2 = strel('rectangle', [25, 25]);
I_close = imclose(I_erode, se2);

% ==================== 3. 去除小对象 ====================
I_clean = bwareaopen(I_close, 2000);

% 保存形态学处理结果
if nargin >= 3 && ~isempty(outputDir)
    imwrite(I_clean, fullfile(outputDir, '04_形态学处理.jpg'));
end

% ==================== 4. 投影法定位 ====================
[y, x, ~] = size(I_clean);
myI = double(I_clean);

% Y方向投影（统计每行的白色像素数）
Blue_y = zeros(y, 1);
for i = 1:y
    Blue_y(i, 1) = sum(myI(i, :));
end

% 找到Y方向最大值位置
[~, MaxY] = max(Blue_y);

% 向上扩展找到上边界
PY1 = MaxY;
while PY1 > 1 && Blue_y(PY1, 1) >= 5
    PY1 = PY1 - 1;
end

% 向下扩展找到下边界
PY2 = MaxY;
while PY2 < y && Blue_y(PY2, 1) >= 5
    PY2 = PY2 + 1;
end

% X方向投影（在Y范围内统计每列的白色像素数）
Blue_x = zeros(1, x);
for j = 1:x
    Blue_x(1, j) = sum(myI(PY1:PY2, j));
end

% 找到X方向左边界
PX1 = 1;
while PX1 < x && Blue_x(1, PX1) < 3
    PX1 = PX1 + 1;
end

% 找到X方向右边界
PX2 = x;
while PX2 > PX1 && Blue_x(1, PX2) < 3
    PX2 = PX2 - 1;
end

% 边界校正（稍微扩大范围）
PX1 = max(1, PX1 - 1);
PX2 = min(x, PX2 + 1);
PY2 = max(1, PY2 - 8);  % 减去底部边框

% ==================== 5. 裁剪车牌 ====================
plateImg = originalImg(PY1:PY2, PX1:PX2, :);
plateRect = [PX1, PY1, PX2-PX1, PY2-PY1];

% 保存车牌定位结果
if nargin >= 3 && ~isempty(outputDir)
    imwrite(plateImg, fullfile(outputDir, '05_定位车牌.jpg'));
end
end
