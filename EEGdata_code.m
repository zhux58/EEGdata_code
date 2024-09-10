clc;clear all;close all
%申明原始数据所在的路径 注意修改（最后面的\不能丢！）
datapath = 'E:\data\';
%利用dir函数查找datapath下面以.vhdr结尾的文件 （不同型号的机器，后缀名注意修改）
datafile = dir(fullfile(datapath,'*.vhdr'));
%获取文件名
dataname = {datafile.name};
%保存路径 注意修改
despath = 'E:\data_set\';
mkdir(despath);%新建结果路径
for i = 1:length(dataname)%沿着每个被试进行循环
    %导入原始数据进行格式转换 pop_loadbv只适用于BP格式的数据，如果是其他厂家的，记得修改 
    EEG = pop_loadbv(datapath,dataname{i},[],[]);
    EEG = eeg_checkset( EEG );
    %通道定位 注意修改电极定位文件路径
    EEG=pop_chanedit(EEG, 'lookup','D:\\eeglab2021.1\\plugins\\dipfit\\standard_BESA\\standard-10-5-cap385.elp');
    %剔除无用电极 
    EEG = pop_select( EEG, 'nochannel',{'LOC','ROC','EMG1','EMG2','VEOG'});    
    %带通滤波，如果高通低通分开做则替换代码
     EEG = pop_eegfiltnew(EEG, 'locutoff',0.5);    
     EEG = pop_eegfiltnew(EEG, 'hicutoff',30);    
     EEG = pop_eegfiltnew(EEG, 'locutoff',48,'hicutoff',52,'revfilt',1);
    %strrep 字符串的替换 将文件名的.vhdr替换为.set
    newname = strrep(dataname{i},'.vhdr','.set');
    %保存数据
    EEG = pop_saveset( EEG, 'filename',newname, 'filepath',despath);
end
%% 降采样率
EEG = pop_resample( EEG, 500);
%% 分段
clc;clear all;close all;
%申明数据所在的路径 注意修改
datapath = 'E:\data_set\';
%利用dir函数查找datapath下面以.set格式结尾的文件
datafile = dir(fullfile(datapath,'*.set'));
%获取文件名
dataname = {datafile.name};
%申明结果保存路径
despath = 'E:\data_set1\';
mkdir(despath);%新建结果路径
for i = 1:length(dataname)%沿着每个被试
    %导入数据
    EEG = pop_loadset('filename',dataname{i}, 'filepath',datapath);
    EEG = eeg_checkset( EEG );
    %分段
    EEG = pop_epoch( EEG, {'S  1'  'S  2'  'S  3'  'S  4'}, [-0.2 1], 'epochinfo', 'yes');
    %基线校正
    EEG = pop_rmbase( EEG, [-200 0] ,[]);
    %保存数据
    EEG = pop_saveset( EEG, 'filename',dataname{i}, 'filepath',despath);
end

%%  完成上述操作的数据后，肉眼观察数据，将漂移较大的分段删掉、EMG伪迹较大的分段删掉，并标记下坏电极；接着对坏电极进行插补
% 有眼电伪迹的分段不应该删掉，但是如果某些分段眼电过大可考虑删掉这些分段。
% 假设上述三个被试完成上述操作后，保存到新文件夹set1

%% 重参考、runICA  跑完的数据保存到set2
clc;clear all;close all;
%申明数据所在的路径 注意修改
datapath = 'E:\data_set1\';
%利用dir函数查找datapath下面以.set格式结尾的文件
datafile = dir(fullfile(datapath,'*.set'));
%获取文件名
dataname = {datafile.name};
%申明结果保存路径
despath = 'E:\data_set2\';
mkdir(despath);
for i = 1:length(dataname)%沿着每个被试
    % 导入数据
    EEG = pop_loadset('filename',dataname{i}, 'filepath',datapath);
    EEG = eeg_checkset( EEG );
    % 重参考(采用双侧乳突重参考)
    EEG = pop_reref( EEG, [57 58] );
    % runICA
    EEG = pop_runica(EEG, 'icatype', 'runica', 'extended',1,'pca',50,'interrupt','on');
    %保存数据
    EEG = pop_saveset( EEG, 'filename',dataname{i}, 'filepath',despath);
end
%% 对runICA之后的数据，浏览数据并删除伪迹相关独立成分,然后把数据保存到set3

%% 根据极端值去伪迹，将干净的数据保存到set4文件夹
%申明数据所在的路径 注意修改
datapath = 'E:\data_set3\';
datafile = dir(fullfile(datapath,'*.set'));
dataname = {datafile.name};
%申明数据保存的路径
despath = 'E:\data_set4';
mkdir(despath);
for i = 1:length(dataname)%沿着每个被试
    %导入数据
    EEG = pop_loadset('filename',dataname{i}, 'filepath',datapath);
    EEG = eeg_checkset( EEG );   
    %根据极端值去伪迹
    EEG = pop_eegthresh(EEG,1,[1:57] ,-100,100,-0.2,0.998,1,1);
    %保存数据
    EEG = pop_saveset( EEG, 'filename',dataname{i}, 'filepath',despath);
end
%% 数据预处理完成
% 提取感兴趣ERP成分的特征值
%% 如果数据里面有多个条件，如何去提取峰值点的波幅和潜伏期
clear all; clc; close all
%记得修改路径
datapath = 'E:\data_set4\';
datafile = dir(fullfile(datapath,'*.set'));
dataname = {datafile.name};

%声明四种条件的名称  以字符串的形式存储
Cond = {'S  1'  'S  2'  'S  3'  'S  4'}; %% condition name 

%对于1号被试到10号被试
for i = 1:length(dataname)
    %导入预处理完的数据
    EEG = pop_loadset('filename',dataname{i},'filepath',datapath); %% load the data
    EEG = eeg_checkset( EEG );    
    %对于每一种条件（本例中，共计4种）
    for j = 1:length(Cond)
        %利用分段函数挑选出当前条件的数据
        EEG_new = pop_epoch( EEG, Cond(j), [-200 1], 'newname', 'datasets pruned with ICA', 'epochinfo', 'yes'); %% epoch by conditions, input to EEG_new
        EEG_new = eeg_checkset( EEG_new );
        EEG_new = pop_rmbase( EEG_new, [-200 0]); %% baseline correction for EEG_new
        EEG_new = eeg_checkset( EEG_new );
        %对第i个被试的第j个条件的数据做叠加平均，然后汇总
        %本例数据，汇总后EEG_avg  四维数组： 被试*条件*通道*时间点  10*4*59*3000
        EEG_avg(i,j,:,:) = squeeze(mean(EEG_new.data,3));  %% average across trials for EEG_new, EEG_avg dimension: subj*cond*channel*time
    end 
end

%%提取不同成分的潜伏期和峰值点的波幅
N2_interval=find((EEG.times>=197)&(EEG.times<=217)); %% N2 interval  197-217ms
P2_interval=find((EEG.times>=364)&(EEG.times<=384)); %% P2 interval    364-384ms
N2_mean_amp = squeeze(mean(EEG_avg(:,:,:,N2_interval),4));
P2_mean_amp = squeeze(mean(EEG_avg(:,:,:,P2_interval),4));

%对于N2成分提取峰值点的波幅和潜伏期
%对于每一个被试
for i = 1:size(EEG_avg,1)
    %对于每一个条件
    for j = 1:size(EEG_avg,2)
        %提取第i个被试第j个条件所有通道下N2时间段内的数据  二维数组 通道*N2时间点
    N2data =squeeze(EEG_avg(i,j,:,N2_interval)); 
    %利用min函数提取每个通道上峰值点的波幅【peak_amplitude_temp】及其对应的时间点【peak_latency_temp】
    [peak_amplitude_temp, peak_latency_temp] = min(N2data,[],2);
    %获取峰值点在整个分段里面所处的时间点位置，把对应位置的毫秒值从EEG.times提取出来，也即潜伏期
    peak_latency_temp = EEG.times(1,find(EEG.times==197) + peak_latency_temp - 1)';
    %三维数组 被试*条件*通道
    N2_peak_amp(i,j,:) = peak_amplitude_temp;
    N2_peak_latency(i,j,:) = peak_latency_temp;
    end
end

%对于P2成分提取峰值点的波幅和潜伏期
for i = 1:size(EEG_avg,1)  %沿着每一个被试
    for j  = 1:size(EEG_avg,2) %沿着每一个条件
     %提取第i个第j个条件P2时间段内的数据
    P2data =squeeze(EEG_avg(i,j,:,P2_interval)); 
     %利用max函数提取每个通道上峰值点的波幅【peak_amplitude_temp】及其对应的时间点【peak_latency_temp】
    [peak_amplitude_temp, peak_latency_temp] = max(P2data,[],2);
     %获取峰值点在整个分段里面所处的时间点位置，把对应位置的毫秒值从EEG.times提取出来，也即潜伏期   
    peak_latency_temp = EEG.times(1,find(EEG.times==364) + peak_latency_temp - 1)';
    %三维数组 被试*条件*通道
    P2_peak_amp(i,j,:) = peak_amplitude_temp;
    P2_peak_latency(i,j,:) = peak_latency_temp;
    end
end
