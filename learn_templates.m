% learn_templates.m
% 从分割结果学习模板 - 手动标注后保存为模板
% 这样模板和分割结果格式完全一致

function learn_templates()
templateDir = fullfile(fileparts(mfilename('fullpath')), 'templates');
if ~exist(templateDir, 'dir')
    mkdir(templateDir);
end

% 找到最近的识别结果
resultsDir = fullfile(fileparts(mfilename('fullpath')), 'results');
dirs = dir(resultsDir);
dirs = dirs([dirs.isdir]);
dirs = dirs(~ismember({dirs.name}, {'.', '..'}));

if isempty(dirs)
    fprintf('没有找到识别结果目录!\n');
    return;
end

[~, idx] = max([dirs.datenum]);
latestDir = fullfile(resultsDir, dirs(idx).name);
fprintf('使用目录: %s\n\n', latestDir);

fprintf('=== 模板学习工具 ===\n');
fprintf('将显示分割的字符，请输入正确的字符来保存为模板\n');
fprintf('输入 "s" 跳过, "q" 退出\n\n');

for i = 1:7
    charFile = fullfile(latestDir, sprintf('09_字符%d.jpg', i));
    if ~exist(charFile, 'file')
        continue;
    end

    % 读取并显示
    charImg = imread(charFile);
    figure(1);
    imshow(charImg);
    title(sprintf('字符 %d - 请在命令窗口输入正确字符', i));
    drawnow;

    % 获取用户输入
    prompt = sprintf('字符%d 是什么? (输入字符/s跳过/q退出): ', i);
    userInput = input(prompt, 's');

    if strcmpi(userInput, 'q')
        fprintf('退出\n');
        break;
    elseif strcmpi(userInput, 's') || isempty(userInput)
        fprintf('跳过字符%d\n', i);
        continue;
    end

    % 处理并保存为模板
    charName = userInput(1);  % 只取第一个字符

    if size(charImg, 3) == 3
        charImg = rgb2gray(charImg);
    end
    charImg = imresize(charImg, [40, 20], 'nearest');

    % 二值化
    if max(charImg(:)) > 1
        charBinary = uint8(double(charImg) > 128) * 255;
    else
        charBinary = uint8(double(charImg) > 0.5) * 255;
    end

    % 保存
    savePath = fullfile(templateDir, [charName, '.bmp']);
    imwrite(charBinary, savePath);
    fprintf('已保存模板: %s\n\n', savePath);
end

close(1);
fprintf('=== 完成 ===\n');
fprintf('现在可以重新运行 main_gui 测试识别效果\n');
end
