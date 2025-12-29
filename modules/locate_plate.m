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
%   6. 增加多参数尝试和基于颜色的备选定位

function [plateImg, plateRect] = locate_plate(edgeImg, originalImg, outputDir)
% ==================== 1. 主定位方法：形态学+投影法 ====================
[plateImg, plateRect, success] = locate_by_morphology(edgeImg, originalImg, outputDir);

% ==================== 2. 如果主方法失败，尝试颜色定位 ====================
if ~success || isempty(plateImg) || size(plateImg, 1) < 10 || size(plateImg, 2) < 30
    fprintf('主定位方法失败，尝试颜色定位...\n');
    [plateImg, plateRect, success] = locate_by_color(originalImg, outputDir);
end

% ==================== 3. 如果颜色定位也失败，尝试不同参数 ====================
if ~success || isempty(plateImg) || size(plateImg, 1) < 10 || size(plateImg, 2) < 30
    fprintf('颜色定位失败，尝试调整形态学参数...\n');
    [plateImg, plateRect, ~] = locate_by_morphology_alt(edgeImg, originalImg, outputDir);
end

% ==================== 4. 最终检查 ====================
if isempty(plateImg) || size(plateImg, 1) < 5 || size(plateImg, 2) < 20
    % 返回整个原图的中心区域作为后备
    [h, w, ~] = size(originalImg);
    cy = round(h/2);
    cx = round(w/2);
    plateRect = [max(1, cx-80), max(1, cy-20), 160, 40];
    plateImg = imcrop(originalImg, plateRect);
end

% 保存最终结果
if nargin >= 3 && ~isempty(outputDir)
    imwrite(plateImg, fullfile(outputDir, '05_定位车牌.jpg'));
end
end

% ==================== 子函数：形态学定位（主方法）====================
function [plateImg, plateRect, success] = locate_by_morphology(edgeImg, originalImg, outputDir)
success = false;
plateImg = [];
plateRect = [0, 0, 0, 0];

% 1. 形态学腐蚀
se1 = [1; 1; 1];  % 垂直结构元素
I_erode = imerode(edgeImg, se1);

% 2. 形态学闭运算
se2 = strel('rectangle', [25, 25]);
I_close = imclose(I_erode, se2);

% 3. 去除小对象
I_clean = bwareaopen(I_close, 2000);

% 保存形态学处理结果
if nargin >= 3 && ~isempty(outputDir)
    imwrite(I_clean, fullfile(outputDir, '04_形态学处理.jpg'));
end

% 4. 投影法定位
[y, x, ~] = size(I_clean);

% 检查是否有足够的白色区域
if sum(I_clean(:)) < 100
    return;  % 返回失败
end

myI = double(I_clean);

% Y方向投影
Blue_y = zeros(y, 1);
for i = 1:y
    Blue_y(i, 1) = sum(myI(i, :));
end

% 找到Y方向最大值位置
[maxVal, MaxY] = max(Blue_y);
if maxVal < 5
    return;  % 返回失败
end

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

% X方向投影
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

% 边界校正
PX1 = max(1, PX1 - 1);
PX2 = min(x, PX2 + 1);
PY2 = max(1, PY2 - 8);

% 验证区域有效性
width = PX2 - PX1;
height = PY2 - PY1;

if width < 30 || height < 10 || width/height > 8 || width/height < 1.5
    return;  % 比例不对，返回失败
end

% 5. 裁剪车牌
plateImg = originalImg(PY1:PY2, PX1:PX2, :);
plateRect = [PX1, PY1, width, height];
success = true;
end

% ==================== 子函数：颜色定位（备选方法）====================
function [plateImg, plateRect, success] = locate_by_color(originalImg, outputDir)
success = false;
plateImg = [];
plateRect = [0, 0, 0, 0];

% 转换到HSV空间
if size(originalImg, 3) == 3
    hsv = rgb2hsv(originalImg);
else
    return;  % 灰度图无法使用颜色定位
end

h = hsv(:,:,1);
s = hsv(:,:,2);
v = hsv(:,:,3);

% 蓝色车牌的HSV范围
% H: 0.55-0.70 (蓝色)
% S: 0.4-1.0 (饱和度较高)
% V: 0.2-1.0 (亮度适中)
blueMask = (h >= 0.55 & h <= 0.72) & (s >= 0.35) & (v >= 0.15);

% 形态学处理
se = strel('rectangle', [5, 15]);
blueMask = imclose(blueMask, se);
blueMask = imopen(blueMask, strel('disk', 3));
blueMask = bwareaopen(blueMask, 500);

% 保存颜色检测结果
if nargin >= 2 && ~isempty(outputDir)
    imwrite(blueMask, fullfile(outputDir, '04b_颜色检测.jpg'));
end

% 找到最大连通区域
stats = regionprops(blueMask, 'BoundingBox', 'Area');
if isempty(stats)
    return;
end

% 按面积排序，选择最大的
[~, idx] = sort([stats.Area], 'descend');

for i = 1:min(3, length(idx))  % 尝试前3个最大区域
    bbox = stats(idx(i)).BoundingBox;
    x = round(bbox(1));
    y = round(bbox(2));
    w = round(bbox(3));
    ht = round(bbox(4));

    % 验证宽高比（车牌约为3:1到5:1）
    ratio = w / ht;
    if ratio >= 2 && ratio <= 6 && w >= 50 && ht >= 15
        % 稍微扩大裁剪区域
        x = max(1, x - 5);
        y = max(1, y - 5);
        w = min(size(originalImg, 2) - x, w + 10);
        ht = min(size(originalImg, 1) - y, ht + 10);

        plateImg = imcrop(originalImg, [x, y, w, ht]);
        plateRect = [x, y, w, ht];
        success = true;
        return;
    end
end
end

% ==================== 子函数：形态学定位（备选参数）====================
function [plateImg, plateRect, success] = locate_by_morphology_alt(edgeImg, originalImg, ~)
success = false;
plateImg = [];
plateRect = [0, 0, 0, 0];

% 尝试不同的形态学参数组合
params = {
    [1;1], strel('rectangle', [15, 30]), 1000;   % 更小的结构元素
    [1;1;1;1], strel('rectangle', [20, 40]), 1500;  % 更大的垂直腐蚀
    [1], strel('rectangle', [30, 30]), 2500;   % 最小腐蚀
    };

for p = 1:size(params, 1)
    se1 = params{p, 1};
    se2 = params{p, 2};
    minArea = params{p, 3};

    I_erode = imerode(edgeImg, se1);
    I_close = imclose(I_erode, se2);
    I_clean = bwareaopen(I_close, minArea);

    % 使用连通域分析
    stats = regionprops(I_clean, 'BoundingBox', 'Area');
    if isempty(stats)
        continue;
    end

    % 找到最佳候选区域
    for j = 1:length(stats)
        bbox = stats(j).BoundingBox;
        w = bbox(3);
        ht = bbox(4);
        ratio = w / ht;

        % 车牌宽高比约为3:1
        if ratio >= 2 && ratio <= 6 && w >= 60 && ht >= 15
            x = max(1, round(bbox(1)));
            y = max(1, round(bbox(2)));
            w = min(size(originalImg, 2) - x, round(w));
            ht = min(size(originalImg, 1) - y, round(ht));

            plateImg = imcrop(originalImg, [x, y, w, ht]);
            plateRect = [x, y, w, ht];
            success = true;
            return;
        end
    end
end
end
