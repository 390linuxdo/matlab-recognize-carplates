function debug_templates()
templateDir = fullfile(fileparts(mfilename('fullpath')), 'templates');
outputFile = fullfile(fileparts(mfilename('fullpath')), 'results', 'debug_templates.jpg');

digits = '0123456789';
letters = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
provinces = '京沪津渝冀豫云辽黑湘皖鲁新苏浙赣鄂桂甘晋蒙陕吉闽贵粤青藏川宁琼';

% 创建一个大图来显示所有模板
% 10行, 10列 (大约)
montageImg = [];

% 1. 数字
rowImg = [];
for i = 1:length(digits)
    char = digits(i);
    path = fullfile(templateDir, [char, '.bmp']);
    if exist(path, 'file')
        img = imread(path);
        if size(img, 3) == 3, img = rgb2gray(img); end
        img = imresize(img, [40, 20]);
    else
        img = zeros(40, 20);
    end
    % 添加边框
    img = padarray(img, [2 2], 128);
    rowImg = [rowImg, img];
end
montageImg = [montageImg; rowImg];

% 2. 字母 (分3行显示)
for k = 0:2
    rowImg = [];
    startIdx = k*10 + 1;
    endIdx = min((k+1)*10, length(letters));
    if startIdx > length(letters), break; end

    for i = startIdx:endIdx
        char = letters(i);
        path = fullfile(templateDir, [char, '.bmp']);
        if exist(path, 'file')
            img = imread(path);
            if size(img, 3) == 3, img = rgb2gray(img); end
            img = imresize(img, [40, 20]);
        else
            img = zeros(40, 20);
        end
        img = padarray(img, [2 2], 128);
        rowImg = [rowImg, img];
    end
    % 补齐宽度
    if size(rowImg, 2) < size(montageImg, 2)
        padInfo = size(montageImg, 2) - size(rowImg, 2);
        rowImg = padarray(rowImg, [0, padInfo], 0, 'post');
    end
    montageImg = [montageImg; rowImg];
end

% 3. 省份 (简单显示几个作为检查)
rowImg = [];
for i = 1:min(10, length(provinces))
    char = provinces(i);
    path = fullfile(templateDir, [char, '.bmp']);
    if exist(path, 'file')
        img = imread(path);
        if size(img, 3) == 3, img = rgb2gray(img); end
        img = imresize(img, [40, 20]);
    else
        img = zeros(40, 20);
    end
    img = padarray(img, [2 2], 128);
    rowImg = [rowImg, img];
end
if size(rowImg, 2) < size(montageImg, 2)
    padInfo = size(montageImg, 2) - size(rowImg, 2);
    rowImg = padarray(rowImg, [0, padInfo], 0, 'post');
end
montageImg = [montageImg; rowImg];

imwrite(montageImg, outputFile);
fprintf('Debug image saved to: %s\n', outputFile);
end
