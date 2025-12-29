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
%   3. 逐个提取字符
%   4. 归一化到40x20尺寸

function chars = segment_chars(binaryImg, outputDir)
% ==================== 1. 初始裁剪 ====================
d = qiege(binaryImg);

% ==================== 2. 粘连字符分割 ====================
[m, n] = size(d);
s = sum(d);  % 每列的白色像素和

k1 = 1;
j = 1;

while j < n
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

    % 如果字符块太宽，可能是两个字符粘连
    if k2 - k1 >= round(n / 6.5)
        % 在中间区域找到最小投影值位置进行分割
        if k1 + 5 <= k2 - 5
            [~, num] = min(sum(d(:, k1+5:k2-5)));
            d(:, k1 + num + 5) = 0;  % 在该位置插入分割线
        end
    end
end

% 再次裁剪
d = qiege(d);

% ==================== 3. 提取第一个字符（汉字） ====================
y1 = 10;    % 最小宽度阈值
y2 = 0.25;  % 中间区域占比阈值
flag = 0;
word1 = [];

while flag == 0
    [m, n] = size(d);
    wide = 0;

    % 找到第一个非空字符的宽度
    while wide < n && sum(d(:, wide + 1)) ~= 0
        wide = wide + 1;
    end

    if wide < y1
        % 太窄，认为是左侧干扰
        d(:, 1:wide) = 0;
        d = qiege(d);
    else
        temp = qiege(imcrop(d, [1, 1, wide, m]));
        [tm, ~] = size(temp);

        % 计算中间1/3区域的像素占比
        all_pixels = sum(sum(temp));
        if tm > 0
            third = round(tm / 3);
            two_thirds = sum(sum(temp(third:2*third, :)));

            if all_pixels > 0 && two_thirds / all_pixels > y2
                flag = 1;
                word1 = temp;
            end
        end

        d(:, 1:wide) = 0;
        if sum(sum(d)) ~= 0
            d = qiege(d);
        else
            flag = 1;
        end
    end

    % 防止无限循环
    if isempty(d) || sum(sum(d)) == 0
        flag = 1;
    end
end

% ==================== 4. 提取剩余6个字符 ====================
[word2, d] = getword(d);
[word3, d] = getword(d);
[word4, d] = getword(d);
[word5, d] = getword(d);
[word6, d] = getword(d);
[word7, ~] = getword(d);

% ==================== 5. 归一化到40x20 ====================
chars = cell(1, 7);
words = {word1, word2, word3, word4, word5, word6, word7};

for i = 1:7
    if ~isempty(words{i})
        chars{i} = imresize(words{i}, [40, 20]);
    else
        chars{i} = zeros(40, 20);  % 空字符用黑色填充
    end
end

% ==================== 6. 保存分割结果 ====================
if nargin >= 2 && ~isempty(outputDir)
    for i = 1:7
        filename = sprintf('09_字符%d.jpg', i);
        imwrite(chars{i}, fullfile(outputDir, filename));
    end
end
end
