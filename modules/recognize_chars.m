% recognize_chars.m
% 完全按照参考项目 LPRS.m 的逻辑实现
% 关键：不做任何额外预处理，直接读取模板进行汉明距离匹配

function [result, confidence] = recognize_chars(chars, templateDir)
% 字符代码表（与参考项目完全一致）
liccode = char(['0':'9' 'A':'Z' '京沪粤津苏浙鄂陕豫桂贵琼湘皖鲁新赣黑晋蒙吉闽贵青藏川宁渝辽冀甘云']);

result = '';
confidence = zeros(1, 7);

for l = 1:7
    % 读取分割字符
    charImg = chars{l};

    % 归一化为40x20（与参考项目一致）
    SegBw2 = imresize(charImg, [40, 20], 'nearest');

    % 固定阈值二值化（参考项目用阈值20）
    if max(SegBw2(:)) > 1
        SegBw2_binary = double(SegBw2) > 20;
    else
        SegBw2_binary = double(SegBw2) > 0.1;
    end

    % 确定搜索范围（与参考项目逻辑一致）
    if l == 1
        % 第一位：汉字识别（索引37-48对应汉字）
        kmin = 37;
        kmax = length(liccode);
    elseif l == 2
        % 第二位：A-Z字母识别（索引11-36对应A-Z）
        kmin = 11;
        kmax = 36;
    else
        % 第三位及以后：数字或字母（索引1-36，0-9和A-Z）
        kmin = 1;
        kmax = 36;
    end

    % 汉明距离匹配
    Error = inf(1, length(liccode));

    for k2 = kmin:kmax
        templatePath = fullfile(templateDir, [liccode(k2), '.bmp']);

        if exist(templatePath, 'file')
            SamBw2 = imread(templatePath);

            % 转灰度
            if size(SamBw2, 3) == 3
                SamBw2 = rgb2gray(SamBw2);
            end

            % 调整大小
            SamBw2 = imresize(SamBw2, [40, 20], 'nearest');

            % 参考项目的模板是直接读取的二值图像，不需要额外二值化
            % 但为了兼容，我们检测并处理
            if max(SamBw2(:)) > 1
                SamBw2_binary = double(SamBw2) > 20;
            else
                SamBw2_binary = double(SamBw2) > 0.1;
            end

            % 计算汉明距离
            Dmax = 0;
            for i = 1:40
                for j = 1:20
                    Dmax = Dmax + xor(SegBw2_binary(i,j), SamBw2_binary(i,j));
                end
            end
            Error(k2) = Dmax;
        end
    end

    % 找最小误差
    Error1 = Error(kmin:kmax);
    MinError = min(Error1);
    findc = find(Error1 == MinError);

    if ~isempty(findc)
        result = [result, liccode(findc(1) + kmin - 1)];
        confidence(l) = 1 - MinError / (40 * 20);
    else
        result = [result, '?'];
        confidence(l) = 0;
    end
end
end
