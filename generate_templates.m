% generate_templates.m
% 自动生成车牌识别所需的字符模板
% 修复版：强制使用 figure 渲染，确保字符可见且完整

function generate_templates()
% 模板保存目录
templateDir = fullfile(fileparts(mfilename('fullpath')), 'templates');
if ~exist(templateDir, 'dir')
    mkdir(templateDir);
end

% 模板尺寸
templateHeight = 40;
templateWidth = 20;

% ===================== 定义字符 =====================
digits = '0123456789';
letters = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
provinces = '京沪津渝冀豫云辽黑湘皖鲁新苏浙赣鄂桂甘晋蒙陕吉闽贵粤青藏川宁琼';

fprintf('开始生成字符模板...\n');
count = 0;

% 创建一个不可见的 figure用于绘图
% 保持 figure 打开状态以提高速度
fig = figure('Visible', 'off', 'Color', 'white');

% 生成数字
fprintf('生成数字模板 (0-9)...\n');
for i = 1:length(digits)
    char = digits(i);
    savePath = fullfile(templateDir, [char, '.bmp']);
    % 不指定字体名，使用系统默认，加粗
    createAndSaveChar(fig, char, templateHeight, templateWidth, '', false, savePath);
    count = count + 1;
end

% 生成字母
fprintf('生成字母模板 (A-Z)...\n');
for i = 1:length(letters)
    char = letters(i);
    savePath = fullfile(templateDir, [char, '.bmp']);
    createAndSaveChar(fig, char, templateHeight, templateWidth, '', false, savePath);
    count = count + 1;
end

% 生成省份
fprintf('生成省份汉字模板...\n');
for i = 1:length(provinces)
    char = provinces(i);
    savePath = fullfile(templateDir, [char, '.bmp']);
    createAndSaveChar(fig, char, templateHeight, templateWidth, 'SimHei', true, savePath);
    count = count + 1;
end

close(fig);
fprintf('\n模板生成完成! 共生成 %d 个模板文件。\n', count);
end

function createAndSaveChar(fig, char, height, width, fontName, isChinese, savePath)
% 大画布渲染 (避免文字贴边被截断)
scale = 8; % 增大缩放倍数
canvasH = height * scale;
canvasW = width * scale;

% 清空 figure
clf(fig);
% 设置一个足够大的 figure
set(fig, 'Units', 'pixels', 'Position', [100 100 canvasW canvasH]);
ax = axes('Parent', fig, 'Position', [0 0 1 1]);
axis off;

% 字体大小 (适度减小，避免撑破画布)
if isChinese
    fontSize = canvasH * 0.75;
    useFont = 'SimHei';
else
    fontSize = canvasH * 0.9;
    useFont = 'Arial';
end

if isempty(fontName)
    useFont = 'Arial';
else
    useFont = fontName;
end

% 绘制文字 (居中)
t = text(0.5, 0.5, char, ...
    'Parent', ax, ...
    'FontName', useFont, ...
    'FontSize', fontSize, ...
    'FontUnits', 'pixels', ...
    'FontWeight', 'bold', ...
    'HorizontalAlignment', 'center', ...
    'VerticalAlignment', 'middle', ...
    'Color', 'black');

% 强制刷新绘图
drawnow;

% 捕获图像
frame = getframe(ax);
img = frame.cdata;

% 灰度化
if size(img, 3) == 3
    grayImg = rgb2gray(img);
else
    grayImg = img;
end

% 二值化 (黑字 < 128)
bwImg = grayImg < 128;

% 最小外接矩形裁剪
[y, x] = find(bwImg);

if ~isempty(y)
    minY = min(y); maxY = max(y);
    minX = min(x); maxX = max(x);

    % 增加一点边距，防止贴边太紧
    padding = 2;
    minY = max(1, minY - padding);
    maxY = min(size(bwImg, 1), maxY + padding);
    minX = max(1, minX - padding);
    maxX = min(size(bwImg, 2), maxX + padding);

    charContent = bwImg(minY:maxY, minX:maxX);

    % 缩放到标准尺寸 40x20
    % 使用 bicubic 保持平滑
    finalImg = imresize(charContent, [height, width], 'bicubic');
    finalImg = finalImg > 0.5; % 再次二值化
else
    % 如果生成失败，创建一个全白的占位符，避免报错
    fprintf('警告: 字符 "%s" 生成为空！使用备用字体再次尝试...\n', char);
    % 如果 Arial 失败，尝试不指定字体
    t.FontName = 'FixedTrip'; % 尝试系统默认
    drawnow;
    frame = getframe(ax);
    img = frame.cdata;
    if size(img, 3) == 3, grayImg = rgb2gray(img); else, grayImg = img; end
    bwImg = grayImg < 128;
    [y, x] = find(bwImg);
    if ~isempty(y)
        minY = min(y); maxY = max(y); minX = min(x); maxX = max(x);
        charContent = bwImg(minY:maxY, minX:maxX);
        finalImg = imresize(charContent, [height, width], 'bicubic');
        finalImg = finalImg > 0.5;
    else
        finalImg = true(height, width); % 彻底失败
        finalImg(10:30, 9:11) = 0; % 画个 "1" 样子的占位
    end
end

% 保存 (白字黑底: 字=255, 背景=0)
% finalImg: 1=字(黑?), 0=背景(白?)  --> 之前逻辑是黑字<128=1
% 所以 finalImg 中 1 代表字的部分。
% 我们希望保存成黑底白字：字=255(白), 背景=0(黑)
% 所以 uint8(finalImg) * 255 即可。

imwrite(uint8(finalImg) * 255, savePath);
end
