% main_gui.m
% 车牌识别系统主程序 - GUI界面
%
% 功能:
%   1. 提供图形用户界面
%   2. 调用各模块完成车牌识别
%   3. 显示所有中间处理步骤
%   4. 保存处理结果到独立文件夹

function main_gui()
% 添加模块目录到路径
moduleDir = fullfile(fileparts(mfilename('fullpath')), 'modules');
addpath(moduleDir);

% 创建主窗口
fig = figure('Name', '模板匹配车牌识别系统', ...
    'NumberTitle', 'off', ...
    'Position', [100, 100, 1200, 700], ...
    'MenuBar', 'none', ...
    'Resize', 'on', ...
    'Color', [0.1, 0.1, 0.15]);

% 存储数据的结构
data = struct();
data.img = [];
data.outputDir = '';
guidata(fig, data);

% ==================== 标题 ====================
uicontrol('Style', 'text', ...
    'String', '模板匹配车牌识别系统', ...
    'Position', [400, 650, 400, 40], ...
    'FontSize', 20, ...
    'FontWeight', 'bold', ...
    'ForegroundColor', [0.3, 0.6, 1], ...
    'BackgroundColor', [0.1, 0.1, 0.15], ...
    'HorizontalAlignment', 'center');

% ==================== 显示面板标签 ====================
uicontrol('Style', 'text', 'String', '显示面板', ...
    'Position', [20, 620, 80, 20], ...
    'FontSize', 10, 'ForegroundColor', 'white', ...
    'BackgroundColor', [0.1, 0.1, 0.15]);

% ==================== 第一行图像显示区域 ====================
% 原图
ax1 = axes('Position', [0.03, 0.55, 0.15, 0.2]);
title('原图', 'Color', 'white');
set(ax1, 'Color', [0.15, 0.15, 0.2], 'XColor', 'white', 'YColor', 'white');
axis off;

% 灰度图
ax2 = axes('Position', [0.20, 0.55, 0.15, 0.2]);
title('灰度图', 'Color', 'white');
set(ax2, 'Color', [0.15, 0.15, 0.2]);
axis off;

% 灰度直方图
ax3 = axes('Position', [0.37, 0.55, 0.15, 0.2]);
title('灰度化直方图', 'Color', 'white');
set(ax3, 'Color', [0.15, 0.15, 0.2], 'XColor', 'white', 'YColor', 'white');

% 边缘检测
ax4 = axes('Position', [0.54, 0.55, 0.15, 0.2]);
title('边缘检测', 'Color', 'white');
set(ax4, 'Color', [0.15, 0.15, 0.2]);
axis off;

% 定位车牌
ax5 = axes('Position', [0.71, 0.55, 0.15, 0.2]);
title('定位车牌', 'Color', 'white');
set(ax5, 'Color', [0.15, 0.15, 0.2]);
axis off;

% ==================== 第二行：分割字符显示 ====================
charAxes = cell(1, 7);
for i = 1:7
    charAxes{i} = axes('Position', [0.03 + (i-1)*0.1, 0.25, 0.08, 0.2]);
    title(num2str(i), 'Color', 'white');
    set(charAxes{i}, 'Color', [0.15, 0.15, 0.2]);
    axis off;
end

% ==================== 识别结果显示 ====================
ax_result_label = uicontrol('Style', 'text', ...
    'String', '车牌号码：', ...
    'Position', [850, 320, 300, 30], ...
    'FontSize', 14, ...
    'ForegroundColor', [0.3, 0.8, 0.3], ...
    'BackgroundColor', [0.1, 0.1, 0.15], ...
    'HorizontalAlignment', 'left');

ax_result = axes('Position', [0.73, 0.25, 0.22, 0.2]);
set(ax_result, 'Color', [0.15, 0.15, 0.2]);
axis off;

% ==================== 控制面板 ====================
uicontrol('Style', 'text', 'String', '控制面板', ...
    'Position', [20, 130, 80, 20], ...
    'FontSize', 10, 'ForegroundColor', 'white', ...
    'BackgroundColor', [0.1, 0.1, 0.15]);

% 选择车牌按钮
btn_select = uicontrol('Style', 'pushbutton', ...
    'String', '选择车牌', ...
    'Position', [50, 60, 120, 50], ...
    'FontSize', 12, ...
    'BackgroundColor', [0.3, 0.7, 0.3], ...
    'ForegroundColor', 'white', ...
    'Callback', @selectImage);

% 车牌识别按钮
btn_recognize = uicontrol('Style', 'pushbutton', ...
    'String', '车牌识别', ...
    'Position', [200, 60, 120, 50], ...
    'FontSize', 12, ...
    'BackgroundColor', [0.3, 0.7, 0.3], ...
    'ForegroundColor', 'white', ...
    'Callback', @recognizePlate);

% 退出系统按钮
btn_exit = uicontrol('Style', 'pushbutton', ...
    'String', '退出系统', ...
    'Position', [350, 60, 120, 50], ...
    'FontSize', 12, ...
    'BackgroundColor', [0.3, 0.7, 0.3], ...
    'ForegroundColor', 'white', ...
    'Callback', @exitSystem);

% 状态栏
status_text = uicontrol('Style', 'text', ...
    'String', '请选择车牌图像', ...
    'Position', [500, 70, 650, 30], ...
    'FontSize', 11, ...
    'ForegroundColor', [0.8, 0.8, 0.8], ...
    'BackgroundColor', [0.1, 0.1, 0.15], ...
    'HorizontalAlignment', 'left');

% ==================== 回调函数 ====================

% 选择图像
    function selectImage(~, ~)
        [filename, pathname] = uigetfile({'*.jpg;*.png;*.bmp', '图像文件'}, '选择车牌图像');
        if filename ~= 0
            data = guidata(fig);
            data.img = imread(fullfile(pathname, filename));
            data.filename = filename;

            % 创建输出目录
            [~, name, ~] = fileparts(filename);
            timestamp = datestr(now, 'yyyymmdd_HHMMSS');
            data.outputDir = fullfile(fileparts(mfilename('fullpath')), ...
                'results', [name, '_', timestamp]);
            if ~exist(data.outputDir, 'dir')
                mkdir(data.outputDir);
            end

            guidata(fig, data);

            % 显示原图
            axes(ax1);
            imshow(data.img);
            title('原图', 'Color', 'white');

            set(status_text, 'String', ['已加载: ', filename, ' | 输出目录: ', data.outputDir]);
        end
    end

% 车牌识别
    function recognizePlate(~, ~)
        data = guidata(fig);

        if isempty(data.img)
            set(status_text, 'String', '错误：请先选择车牌图像！');
            return;
        end

        try
            set(status_text, 'String', '正在处理...');
            drawnow;

            % Step 1: 预处理
            set(status_text, 'String', '步骤 1/5: 图像预处理...');
            drawnow;
            [grayImg, edgeImg] = preprocess(data.img, data.outputDir);

            % 显示灰度图
            axes(ax2);
            imshow(grayImg);
            title('灰度图', 'Color', 'white');

            % 显示灰度直方图
            axes(ax3);
            imhist(grayImg);
            title('灰度化直方图', 'Color', 'white');
            set(ax3, 'XColor', 'white', 'YColor', 'white');

            % 显示边缘检测
            axes(ax4);
            imshow(edgeImg);
            title('边缘检测', 'Color', 'white');

            % Step 2: 车牌定位
            set(status_text, 'String', '步骤 2/5: 车牌定位...');
            drawnow;
            [plateImg, ~] = locate_plate(edgeImg, data.img, data.outputDir);

            % 显示定位车牌
            axes(ax5);
            imshow(plateImg);
            title('定位车牌', 'Color', 'white');

            % Step 3: 二值化
            set(status_text, 'String', '步骤 3/5: 车牌二值化...');
            drawnow;
            binaryImg = binarize_plate(plateImg, data.outputDir);

            % Step 4: 字符分割
            set(status_text, 'String', '步骤 4/5: 字符分割...');
            drawnow;
            chars = segment_chars(binaryImg, data.outputDir);

            % 显示分割字符
            for i = 1:7
                axes(charAxes{i});
                imshow(chars{i});
                title(num2str(i), 'Color', 'white');
            end

            % Step 5: 字符识别
            set(status_text, 'String', '步骤 5/5: 字符识别...');
            drawnow;
            templateDir = fullfile(fileparts(mfilename('fullpath')), 'templates');
            [result, confidence] = recognize_chars(chars, templateDir);

            % 显示识别结果
            set(ax_result_label, 'String', ['车牌号码：', result]);
            axes(ax_result);
            imshow(plateImg);
            title(result, 'Color', [0.3, 0.6, 1], 'FontSize', 14);

            % 保存识别结果
            resultFile = fullfile(data.outputDir, '识别结果.txt');
            fid = fopen(resultFile, 'w', 'n', 'UTF-8');
            fprintf(fid, '车牌号码: %s\n', result);
            fprintf(fid, '置信度: ');
            fprintf(fid, '%.2f ', confidence);
            fprintf(fid, '\n处理时间: %s\n', datestr(now));
            fclose(fid);

            set(status_text, 'String', ['识别完成! 结果: ', result, ' | 已保存到: ', data.outputDir]);

        catch ME
            set(status_text, 'String', ['错误: ', ME.message]);
            disp(getReport(ME));
        end
    end

% 退出系统
    function exitSystem(~, ~)
        close(fig);
    end
end
