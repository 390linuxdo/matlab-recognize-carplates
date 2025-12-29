% normalize_char.m
% 简化的字符归一化：只做裁剪和居中，不改变粗细

function normImg = normalize_char(img)
targetH = 40;
targetW = 20;

% 转灰度
if size(img, 3) == 3
    img = rgb2gray(img);
end
img = double(img);

% 二值化
if max(img(:)) > 1
    bw = img > 128;
else
    bw = img > 0.5;
end

% 去除小噪点
bw = bwareaopen(bw, 5);

% 裁剪到内容区域
[rows, cols] = find(bw);
if isempty(rows)
    normImg = false(targetH, targetW);
    return;
end

minR = min(rows); maxR = max(rows);
minC = min(cols); maxC = max(cols);
content = bw(minR:maxR, minC:maxC);

% 保持宽高比缩放到目标大小的85%
[cH, cW] = size(content);
padH = targetH - 2;
padW = targetW - 2;

scaleH = padH / cH;
scaleW = padW / cW;
scale = min(scaleH, scaleW);

newH = max(1, round(cH * scale));
newW = max(1, round(cW * scale));

resized = imresize(content, [newH, newW], 'bilinear');
resized = resized > 0.5;

% 居中放置
normImg = false(targetH, targetW);
startR = max(1, round((targetH - newH) / 2) + 1);
startC = max(1, round((targetW - newW) / 2) + 1);

endR = min(targetH, startR + newH - 1);
endC = min(targetW, startC + newW - 1);

actualH = endR - startR + 1;
actualW = endC - startC + 1;

if actualH > 0 && actualW > 0
    normImg(startR:endR, startC:endC) = resized(1:actualH, 1:actualW);
end
end
