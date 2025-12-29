% 基于MATLAB的车牌识别
% 参考链接 https://blog.csdn.net/tutu998/article/details/120177086
% 载入车牌图像
% function [d]=main(jpg)
[filename, pathname] = uigetfile({'车牌测试集/test.jpg'});
if(filename == 0), return, end
global FILENAME  %定义全局变量
FILENAME = [pathname filename];
I=imread(FILENAME);
% figure(1),imshow(I);title('原图像');%将车牌的原图显示出来结果如下：
%% 一、图像预处理
% 1.RGB转灰度中值滤波
I1=rgb2gray(I);%RGB转灰度
I1=medfilt2(I1,[3 3]);%中值滤波
figure(1),imshow(I1);title('中值滤波灰度图像');
saveas(gca,'fig1_中值滤波灰度图像.png');

% 2.用roberts算子进行边缘检测
I2=edge(I1,'roberts',0.15,'both');%选择阈值0.15，用roberts算子进行边缘检测
figure(2),imshow(I2);title('roberts算子边缘检测');
saveas(gca,'fig2_roberts算子边缘检测.png');

% 3.图像实施腐蚀操作
se=[1;1;1];
I3=imerode(I2,se);%对图像实施腐蚀操作，即膨胀的反操作
figure(3),imshow(I3);title('腐蚀后图像');
saveas(gca,'fig3_腐蚀后图像.png');

% 4.对图像执行形态学闭运算
se=strel('rectangle',[25,25]);%构造结构元素以正方形构造一个se
I4=imclose(I3,se);% 对图像执行形态学闭运算
figure(4),imshow(I4);title('对图像执行形态学闭运算');
saveas(gca,'fig4_对图像执行形态学闭运算.png');

% 5.从二值图像中删除小对象
I5=bwareaopen(I4,2000);% 去除聚团灰度值小于2000的部分
figure(5),imshow(I5);title('从二值图像中删除小对象');
saveas(gca,'fig5_从二值图像中删除小对象.png');


%% 二、车牌定位
[y,x,z]=size(I5);%返回I5各维的尺寸，存储在x,y,z中
myI=double(I5);%将I5转换成双精度
%%Y方向车牌区域确定%%
Blue_y=zeros(y,1);%产生一个y*1的零阵
for i=1:y
    for j=1:x
        if(myI(i,j,1)==1)
            %如果myI(i,j,1)即myI的图像中坐标为(i,j)的点值为1，即该点为车牌背景颜色蓝色
            %则Blue_y(i,1)的值加1
            Blue_y(i,1)= Blue_y(i,1)+1;%蓝色像素点统计
        end
    end
end
[temp MaxY]=max(Blue_y);%Y方向车牌区域确定
%temp为向量white_y的元素中的最大值，MaxY为该值的索引
PY1=MaxY;
while ((Blue_y(PY1,1)>=5)&&(PY1>1))
    PY1=PY1-1;
end
PY2=MaxY;
while ((Blue_y(PY2,1)>=5)&&(PY2<y))
    PY2=PY2+1;
end
IY=I(PY1:PY2,:,:);
%%X方向车牌区域确定%%
Blue_x=zeros(1,x);%进一步确定x方向的车牌区域
for j=1:x
    for i=PY1:PY2
        if(myI(i,j,1)==1)
            Blue_x(1,j)= Blue_x(1,j)+1;
        end
    end
end
PX1=1;
while ((Blue_x(1,PX1)<3)&&(PX1<x))
    PX1=PX1+1;
end
PX2=x;
while ((Blue_x(1,PX2)<3)&&(PX2>PX1))
    PX2=PX2-1;
end
PX1=PX1-1;%对车牌区域的校正
PX2=PX2+1;
dw=I(PY1:PY2,PX1:PX2,:);
figure(6),subplot(1,2,1),imshow(IY),title('行方向合理区域');%行方向车牌区域确定
figure(6),subplot(1,2,2),imshow(dw),title('定位裁剪后的车牌彩色图像');%的车牌区域如下所示：
saveas(gca,'fig6_车牌定位.png');

%% 三、车牌的进一步处理
imwrite(dw,'彩色车牌.jpg');%将彩色车牌写入彩色车牌文件中
a=imread('彩色车牌.jpg');%读取车牌文件中的数据
b=rgb2gray(a);%将车牌图像转换为灰度图
imwrite(b,'车牌灰度图像.jpg');%将灰度图像写入文件中
figure(7);subplot(3,2,1),imshow(b),title('车牌灰度图像')
g_max=double(max(max(b)));
g_min=double(min(min(b)));
T=round(g_max-(g_max-g_min)/3); % T 为二值化的阈值
[m,n]=size(b);
d=(double(b)>=T); % d:二值图像
imwrite(d,'均值滤波前.jpg');
subplot(3,2,2),imshow(d),title('均值滤波前')
%均值滤波前
% 滤波
h=fspecial('gaussian',3);
%建立预定义的滤波算子，average为均值滤波，模板的尺寸为3*3
d=im2bw(round(filter2(h,d)));%使用指定的滤波器h对h进行d即均值滤波
imwrite(d,'均值滤波后.jpg');
subplot(3,2,3),imshow(d),title('均值滤波后')
% 某些图像进行操作
% 膨胀或腐蚀
% se=strel('square',3); % 使用一个3X3的正方形结果元素对象对创建的图像进行膨胀
% 'line'/'diamond'/'ball'...
se=eye(2); % eye(n) returns the n-by-n identity matrix 单位矩阵
[m,n]=size(d);%返回矩阵b的尺寸信息， 并存储在m,n中
if bwarea(d)/m/n>=0.365 %计算二值图像中对象的总面积与整个面积的比是否大于0.365
    d=imerode(d,se);%如果大于0.365则图像进行腐蚀
elseif bwarea(d)/m/n<=0.235 %计算二值图像中对象的总面积与整个面积的比是否小于0.235
    d=imdilate(d,se);%如果小于则实现膨胀操作
end
imwrite(d,'膨胀或腐蚀处理后.jpg');
subplot(3,2,4),imshow(d),title('膨胀或腐蚀处理后');
sgtitle('1.车牌的进一步处理');
saveas(gca,'fig7_1.车牌的进一步处理.png');


%% 四、字符分割
% 寻找连续有文字的块，若长度大于某阈值，则认为该块有两个字符组成，需要分割
% 首先创建子函数qiege与getword，而后调用子程序，将车牌的字符分割开并且进行归一化处理
d=qiege(d);
[m,n]=size(d);
% subplot(3,2,5),imshow(d),title(n)
k1=1;k2=1;s=sum(d);j=1;
while j~=n
    while s(j)==0
        j=j+1;
    end
    k1=j;
    while s(j)~=0 && j<=n-1
        j=j+1;
    end
    k2=j-1;
    if k2-k1>=round(n/6.5)
        [val,num]=min(sum(d(:,[k1+5:k2-5])));
        d(:,k1+num+5)=0;  % 分割
    end
end
% 再切割
d=qiege(d);
% 切割出 7 个字符
y1=10;y2=0.25;flag=0;word1=[];
while flag==0
    [m,n]=size(d);
    left=1;wide=0;
    while sum(d(:,wide+1))~=0
        wide=wide+1;
    end
    if wide<y1   % 认为是左侧干扰
        d(:,[1:wide])=0;
        d=qiege(d);
    else
        temp=qiege(imcrop(d,[1 1 wide m]));
        [m,n]=size(temp);
        all=sum(sum(temp));
        two_thirds=sum(sum(temp([round(m/3):2*round(m/3)],:)));
        if two_thirds/all>y2
            flag=1;word1=temp;
        end
        d(:,[1:wide])=0;d=qiege(d);
    end
end
% 分割出第二个字符
[word2,d]=getword(d);
% 分割出第三个字符
[word3,d]=getword(d);
% 分割出第四个字符
[word4,d]=getword(d);
% 分割出第五个字符
[word5,d]=getword(d);
% 分割出第六个字符
[word6,d]=getword(d);
% 分割出第七个字符
[word7,d]=getword(d);
figure(8);
subplot(2,7,1),imshow(word1),title('1');
subplot(2,7,2),imshow(word2),title('2');
subplot(2,7,3),imshow(word3),title('3');
subplot(2,7,4),imshow(word4),title('4');
subplot(2,7,5),imshow(word5),title('5');
subplot(2,7,6),imshow(word6),title('6');
subplot(2,7,7),imshow(word7),title('7');
[m,n]=size(word1);
% 归一化为 40*20
word1=imresize(word1,[40 20]);
word2=imresize(word2,[40 20]);
word3=imresize(word3,[40 20]);
word4=imresize(word4,[40 20]);
word5=imresize(word5,[40 20]);
word6=imresize(word6,[40 20]);
word7=imresize(word7,[40 20]);
subplot(2,7,8),imshow(word1),title('1');
subplot(2,7,9),imshow(word2),title('2');
subplot(2,7,10),imshow(word3),title('3');
subplot(2,7,11),imshow(word4),title('4');
subplot(2,7,12),imshow(word5),title('5');
subplot(2,7,13),imshow(word6),title('6');
subplot(2,7,14),imshow(word7),title('7');
sgtitle('2.字符分割');
saveas(gca,'fig8_2.字符分割.png');
imwrite(word1,'1.jpg');
imwrite(word2,'2.jpg');
imwrite(word3,'3.jpg');
imwrite(word4,'4.jpg');
imwrite(word5,'5.jpg');
imwrite(word6,'6.jpg');
imwrite(word7,'7.jpg');


%% 五、车牌匹配识别
liccode=char(['0':'9' 'A':'Z' '京沪粤津苏浙鄂陕豫桂贵琼']); %建立自动识别字符代码表
SubBw2_binary=zeros(40,20); %产生40*20的全0矩阵
l=1;
for I=1:7
    ii=int2str(I); %转为串
    t=imread([ii,'.jpg']); %读取图片文件中的数据
    SegBw2=imresize(t,[40 20],'nearest'); %对图像做缩放处理
    SegBw2_binary=double(SegBw2)>20; %固定阈值二值化
    if l==1 %第一位汉字识别
        kmin=37;
        kmax=48;
    elseif l==2 %第二位 A~Z 字母识别
        kmin=11;
        kmax=36;
    else l>=3 %第三位以后是字母或数字识别
        kmin=1;
        kmax=36;
    end
    for k2=kmin:kmax
        fname=strcat('字符模板(4020)\',liccode(k2),'.bmp'); %把行向量转化成字符串
        SamBw2_binary = imread(fname);
        Dmax=0;
        for i=1:40
            for j=1:20
                Dmax=Dmax+xor(SegBw2_binary(i,j),SamBw2_binary(i,j));%汉明距离
            end
        end
        Error(k2)=Dmax;
    end
    Error1=Error(kmin:kmax);
    MinError=min(Error1);
    findc=find(Error1==MinError);
    Code(l*2-1)=liccode(findc(1)+kmin-1);
    Code(l*2)=' '; %输出最大相关图像
    l=l+1;
end
figure(9),imshow(dw),title (['车牌号码:', Code],'Color','r');
saveas(gca,'fig9_车牌匹配识别.png');