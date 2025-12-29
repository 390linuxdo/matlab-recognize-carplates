% debug_recognition.m
% 调试工具：可视化对比分割字符和模板

function debug_recognition()
% 加载最近一次识别结果
resultsDir = fullfile(fileparts(mfilename('fullpath')), 'results');
dirs = dir(resultsDir);
dirs = dirs([dirs.isdir]);
dirs = dirs(~ismember({dirs.name}, {'.', '..'}));

if isempty(dirs)
    fprintf('没有找到识别结果目录!\n');
    return;
end

% 找最新的结果
[~, idx] = max([dirs.datenum]);
latestDir = fullfile(resultsDir, dirs(idx).name);
fprintf('分析目录: %s\n\n', latestDir);

% 读取分割的字符
templateDir = fullfile(fileparts(mfilename('fullpath')), 'templates');

figure('Name', '调试: 分割字符 vs 模板', 'Position', [50 50 1400 800]);

% 预定义的正确字符（用于测试）
correctChars = {'京', 'A', 'F', '0', '2', '3', '6'};

for i = 1:7
    charFile = fullfile(latestDir, sprintf('09_字符%d.jpg', i));
    if ~exist(charFile, 'file')
        fprintf('字符%d文件不存在\n', i);
        continue;
    end

    % 读取分割字符
    charImg = imread(charFile);
    if size(charImg, 3) == 3
        charImg = rgb2gray(charImg);
    end
    charImg = imresize(charImg, [40, 20], 'nearest');
    charBinary = double(charImg) > 128;

    % 读取对应模板
    templatePath = fullfile(templateDir, [correctChars{i}, '.bmp']);
    if exist(templatePath, 'file')
        templateImg = imread(templatePath);
        if size(templateImg, 3) == 3
            templateImg = rgb2gray(templateImg);
        end
        templateImg = imresize(templateImg, [40, 20], 'nearest');
        templateBinary = double(templateImg) > 128;
    else
        templateBinary = zeros(40, 20);
    end

    % 计算汉明距离
    hammingDist = sum(sum(xor(charBinary, templateBinary)));

    % 显示
    subplot(4, 7, i);
    imshow(charBinary);
    title(sprintf('分割字符%d', i));

    subplot(4, 7, i + 7);
    imshow(templateBinary);
    title(sprintf('模板: %s', correctChars{i}));

    subplot(4, 7, i + 14);
    imshow(xor(charBinary, templateBinary));
    title(sprintf('差异: %d', hammingDist));

    % 统计信息
    subplot(4, 7, i + 21);
    bar([sum(charBinary(:)), sum(templateBinary(:))]);
    set(gca, 'XTickLabel', {'分割', '模板'});
    title('白色像素数');

    fprintf('字符%d (%s): 汉明距离=%d, 分割白像素=%d, 模板白像素=%d\n', ...
        i, correctChars{i}, hammingDist, sum(charBinary(:)), sum(templateBinary(:)));
end

fprintf('\n如果差异图中白色区域很多，说明匹配度低。\n');
fprintf('如果分割字符和模板的白色像素数差异很大，说明二值化阈值有问题。\n');
end
