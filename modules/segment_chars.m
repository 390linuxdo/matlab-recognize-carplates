% segment_chars.m
% 字符分割模块 - 将车牌二值图分割成7个字符
%
% 输入:
%   binaryImg - 二值化的车牌图像
%   outputDir - 输出目录（用于保存中间结果）
% 输出:
%   chars - 1x7 cell数组，包含7个字符图像（40x20）
%
% 功能:
%   1. 边缘裁剪去除空白
%   2. 处理粘连字符分割
%   3. 跳过分隔点（·）
%   4. 逐个提取字符
%   5. 归一化到40x20尺寸

function chars = segment_chars(binaryImg, outputDir)
% ==================== 1. 初始裁剪 ====================
d = qiege(binaryImg);

% ==================== 2. 分析并分割字符 ====================
[m, n] = size(d);
s = sum(d);  % 每列的白色像素和

% 找到所有字符区域的边界
charBounds = find_char_bounds(s, n);

% ==================== 3. 处理粘连字符 ====================
charBounds = handle_connected_chars(d, charBounds, n);

% ==================== 4. 提取字符 ====================
allChars = {};
for i = 1:length(charBounds)
    bounds = charBounds{i};
    k1 = bounds(1);
    k2 = bounds(2);

    % 提取字符区域
    charRegion = d(:, k1:k2);
    charRegion = qiege(charRegion);

    % 过滤分隔点（面积太小或宽高比太接近1:1）
    [ch, cw] = size(charRegion);
    if ~isempty(charRegion) && ch > 5 && cw > 3
        area = sum(charRegion(:));
        % 分隔点通常很小，且宽高比接近1:1
        if area < m * n * 0.005 && abs(ch - cw) < min(ch, cw) * 0.5
            % 可能是分隔点，跳过
            continue;
        end
        allChars{end+1} = charRegion;
    end
end

% ==================== 5. 确保有7个字符 ====================
% 如果字符数量不对，尝试其他分割方法
if length(allChars) < 7
    % 使用等宽分割作为备选
    allChars = equal_width_segment(d, 7);
elseif length(allChars) > 7
    % 如果多于7个，去除最小的（可能是噪声）
    allChars = remove_smallest_chars(allChars, length(allChars) - 7);
end

% ==================== 6. 归一化到40x20 ====================
chars = cell(1, 7);
for i = 1:7
    if i <= length(allChars) && ~isempty(allChars{i})
        chars{i} = imresize(allChars{i}, [40, 20]);
    else
        chars{i} = zeros(40, 20);  % 空字符用黑色填充
    end
end

% ==================== 7. 保存分割结果 ====================
if nargin >= 2 && ~isempty(outputDir)
    for i = 1:7
        filename = sprintf('09_字符%d.jpg', i);
        imwrite(chars{i}, fullfile(outputDir, filename));
    end
end
end

% ==================== 辅助函数：找到字符边界 ====================
function charBounds = find_char_bounds(s, n)
charBounds = {};
j = 1;

while j <= n
    % 跳过空白列
    while j <= n && s(j) == 0
        j = j + 1;
    end

    if j > n
        break;
    end

    k1 = j;

    % 找到连续非空列的结束位置
    while j <= n && s(j) ~= 0
        j = j + 1;
    end
    k2 = j - 1;

    if k2 >= k1
        charBounds{end+1} = [k1, k2];
    end
end
end

% ==================== 辅助函数：处理粘连字符 ====================
function charBounds = handle_connected_chars(d, charBounds, n)
avgWidth = n / 7.5;  % 预期的平均字符宽度

newBounds = {};
for i = 1:length(charBounds)
    bounds = charBounds{i};
    k1 = bounds(1);
    k2 = bounds(2);
    width = k2 - k1 + 1;

    % 如果宽度超过预期的1.5倍，可能是粘连字符
    if width > avgWidth * 1.5
        % 在中间区域找最小投影位置进行分割
        midStart = k1 + round(width * 0.3);
        midEnd = k2 - round(width * 0.3);

        if midEnd > midStart
            region = sum(d(:, midStart:midEnd));
            [~, minIdx] = min(region);
            splitPoint = midStart + minIdx - 1;

            newBounds{end+1} = [k1, splitPoint - 1];
            newBounds{end+1} = [splitPoint + 1, k2];
        else
            newBounds{end+1} = bounds;
        end
    else
        newBounds{end+1} = bounds;
    end
end
charBounds = newBounds;
end

% ==================== 辅助函数：等宽分割 ====================
function chars = equal_width_segment(d, numChars)
d = qiege(d);
[m, n] = size(d);
charWidth = n / numChars;

chars = {};
for i = 1:numChars
    x1 = round((i-1) * charWidth) + 1;
    x2 = round(i * charWidth);
    x2 = min(x2, n);

    if x2 > x1
        charRegion = qiege(d(:, x1:x2));
        if ~isempty(charRegion)
            chars{end+1} = charRegion;
        else
            chars{end+1} = zeros(m, round(charWidth));
        end
    end
end
end

% ==================== 辅助函数：移除最小字符 ====================
function chars = remove_smallest_chars(chars, numToRemove)
% 计算每个字符的面积
areas = zeros(1, length(chars));
for i = 1:length(chars)
    if ~isempty(chars{i})
        areas(i) = sum(chars{i}(:));
    end
end

% 找到最小的numToRemove个字符并移除
[~, sortedIdx] = sort(areas);
removeIdx = sortedIdx(1:numToRemove);

% 创建新的字符数组（排除最小的）
newChars = {};
for i = 1:length(chars)
    if ~ismember(i, removeIdx)
        newChars{end+1} = chars{i};
    end
end
chars = newChars;
end
