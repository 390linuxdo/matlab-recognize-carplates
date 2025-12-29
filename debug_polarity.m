% debug_polarity.m
% 调试脚本：检查模板和分割字符的极性

function debug_polarity()
templateDir = fullfile(fileparts(mfilename('fullpath')), 'templates');

% 读取一个模板
templatePath = fullfile(templateDir, 'A.bmp');
if exist(templatePath, 'file')
    template = imread(templatePath);

    fprintf('=== 模板 A.bmp 分析 ===\n');
    fprintf('尺寸: %dx%d\n', size(template, 1), size(template, 2));
    fprintf('数据类型: %s\n', class(template));
    fprintf('最小值: %d\n', min(template(:)));
    fprintf('最大值: %d\n', max(template(:)));
    fprintf('平均值: %.1f\n', mean(template(:)));

    % 分析比例
    white_ratio = sum(template(:) > 128) / numel(template);
    fprintf('白色像素占比 (>128): %.1f%%\n', white_ratio * 100);
    fprintf('黑色像素占比 (<=128): %.1f%%\n', (1 - white_ratio) * 100);

    % 判断极性
    if white_ratio > 0.5
        fprintf('\n结论: 模板是 白底黑字 (背景白，字符黑)\n');
        fprintf('==> 字符区域值小, 背景区域值大\n');
    else
        fprintf('\n结论: 模板是 黑底白字 (背景黑，字符白)\n');
        fprintf('==> 字符区域值大, 背景区域值小\n');
    end

    % 显示模板
    figure('Name', '模板极性分析');
    subplot(1, 3, 1);
    imshow(template);
    title('原始模板');

    subplot(1, 3, 2);
    imshow(template > 20);
    title('阈值20二值化');

    subplot(1, 3, 3);
    imshow(template > 128);
    title('阈值128二值化');
else
    fprintf('模板文件不存在!\n');
end

fprintf('\n=== 分割字符通常是 ===\n');
fprintf('白字黑底 (背景黑=0, 字符白=255)\n');
fprintf('二值化后: 字符=true, 背景=false\n');

fprintf('\n=== 如果模板是白底黑字 ===\n');
fprintf('使用阈值20: 背景(白)>20=true, 字符(黑)>20=false\n');
fprintf('结果: 极性与分割字符完全相反!\n');
fprintf('解决方案: 对模板进行反转 (~template)\n');
end
