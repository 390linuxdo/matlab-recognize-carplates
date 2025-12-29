% generate_templates.m
% 使用统一归一化生成模板

function generate_templates()
templateDir = fullfile(fileparts(mfilename('fullpath')), 'templates');
if ~exist(templateDir, 'dir')
    mkdir(templateDir);
end

height = 40;
width = 20;

digits = '0123456789';
letters = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
provinces = '京沪津渝冀豫云辽黑湘皖鲁新苏浙赣鄂桂甘晋蒙陕吉闽贵粤青藏川宁琼';

fprintf('开始生成模板...\n');
count = 0;

fig = figure('Visible', 'off', 'Color', 'black');

% 数字
for i = 1:length(digits)
    createAndSave(fig, digits(i), 'Arial', false, height, width, ...
        fullfile(templateDir, [digits(i), '.bmp']));
    count = count + 1;
end

% 字母
for i = 1:length(letters)
    createAndSave(fig, letters(i), 'Arial', false, height, width, ...
        fullfile(templateDir, [letters(i), '.bmp']));
    count = count + 1;
end

% 省份
for i = 1:length(provinces)
    createAndSave(fig, provinces(i), 'SimHei', true, height, width, ...
        fullfile(templateDir, [provinces(i), '.bmp']));
    count = count + 1;
end

close(fig);
fprintf('完成! 共 %d 个模板\n', count);
end

function createAndSave(fig, char, fontName, isChinese, height, width, savePath)
scale = 8;
clf(fig);
set(fig, 'Units', 'pixels', 'Position', [100 100 width*scale height*scale], 'Color', 'black');
ax = axes('Parent', fig, 'Position', [0 0 1 1], 'Color', 'black');
axis off;
xlim([0 1]); ylim([0 1]);

if isChinese
    fontSize = height * scale * 0.7;
else
    fontSize = height * scale * 0.8;
end

text(0.5, 0.5, char, 'Parent', ax, 'FontName', fontName, ...
    'FontSize', fontSize, 'FontUnits', 'pixels', 'FontWeight', 'bold', ...
    'HorizontalAlignment', 'center', 'VerticalAlignment', 'middle', ...
    'Color', 'white');
drawnow;

frame = getframe(fig);
img = frame.cdata;

% 使用统一归一化函数
normImg = normalize_char(img);

% 保存
imwrite(uint8(normImg) * 255, savePath);
end
