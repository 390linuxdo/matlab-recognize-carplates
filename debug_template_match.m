% debug_template_match.m
% 调试脚本：检查模板和分割字符的极性差异

function debug_template_match()
% 模板目录
templateDir = fullfile(fileparts(mfilename('fullpath')), 'templates');

% 测试一些模板
testChars = {'0', 'A', '5', '京'};

fprintf('=== 模板格式检查 ===\n\n');

for i = 1:length(testChars)
    charName = testChars{i};
    templatePath = fullfile(templateDir, [charName, '.bmp']);

    if exist(templatePath, 'file')
        img = imread(templatePath);

        % 统计信息
        fprintf('字符 "%s":\n', charName);
        fprintf('  尺寸: %dx%d\n', size(img, 1), size(img, 2));
        fprintf('  数据类型: %s\n', class(img));
        fprintf('  最小值: %d, 最大值: %d\n', min(img(:)), max(img(:)));
        fprintf('  白色像素(>127)占比: %.2f%%\n', 100 * sum(img(:) > 127) / numel(img));
        fprintf('  黑色像素(<=127)占比: %.2f%%\n\n', 100 * sum(img(:) <= 127) / numel(img));

        % 显示模板
        figure;
        subplot(1, 2, 1);
        imshow(img);
        title(['原始模板: ', charName]);

        subplot(1, 2, 2);
        imshow(~img);
        title(['反转后: ', charName]);
    else
        fprintf('模板 "%s" 不存在!\n\n', charName);
    end
end

fprintf('=== 检查完成 ===\n');
fprintf('如果模板是黑字白底（字符区域值小），而分割字符是白字黑底（字符区域值大），\n');
fprintf('则需要在识别时反转其中一个。\n');
end
