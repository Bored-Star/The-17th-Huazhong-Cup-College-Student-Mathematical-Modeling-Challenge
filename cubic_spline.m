% 读 取Excel文 件
[~, ~, raw] = xlsread('附 件1−共 享 单 车 分 布 统 计 表.xlsx'); % 替 换 为 你 的 文 件 名

% 初 始 化 存 储 向 量
data_vectors = cell(1, 15); % 存 储D−R列 数 据
time_vectors = cell(1, 15); % 存 储 对 应 时 间 数 据

% 列 范 围 (D到R对 应Excel中 的4到18列)
start_col = 4;
end_col = 18;

% 先 处 理 时 间 数 据(C列)创 建 完 整time_vector
time_vector = zeros(34, 1); % 预 分 配 空 间
for row = 2:35
if size(raw,1) >= row && size(raw,2) >= 3
time_content = raw{row, 3};
total_hours = 0;

if ischar(time_content)
time_parts = strsplit(time_content , ':');
if ~isempty(time_parts)
hours = str2double(time_parts{1});
if ~isnan(hours), total_hours = hours; end


if length(time_parts) >= 2
minutes = str2double(time_parts{2});
if ~isnan(minutes), total_hours = total_hours + minutes/60; end
end

if length(time_parts) >= 3
seconds = str2double(time_parts{3});
if ~isnan(seconds), total_hours = total_hours + seconds/3600; end
end
end
elseif isnumeric(time_content)
total_hours = time_content;
end

% 添 加 行 偏 移
if row >= 2 && row <= 9
% 不 加
elseif row >= 10 && row <= 17
total_hours = total_hours + 1;
elseif row >= 18 && row <= 25
total_hours = total_hours + 2;
elseif row >= 26 && row <= 30
total_hours = total_hours + 3;
elseif row >= 31 && row <= 35
total_hours = total_hours + 4;
end

time_vector(row-1) = round(total_hours , 5);
end
end

% 处 理 数 据 列 并 创 建 对 应 时 间 向 量
for col = start_col:end_col
current_data = [];
current_time = [];

for row = 2:35
if size(raw,1) >= row && size(raw,2) >= col
cell_content = raw{row, col};
valid_data = false;

if isnumeric(cell_content) && ~isnan(cell_content)
current_data = [current_data; cell_content];
valid_data = true;
elseif ischar(cell_content)
if strcmp(strtrim(cell_content), '200+')
current_data = [current_data; 200];
valid_data = true;
else
num = str2double(cell_content);
if ~isnan(num)
current_data = [current_data; num];
valid_data = true;
end
end
end

% 只 有 当 数 据 有 效 时 才 添 加 对 应 时 间
if valid_data
current_time = [current_time; time_vector(row-1)];
end
end
end

% 在 数 据 向 量 前 后 插 入60
current_data = [60; current_data; 60];

% 在 时 间 向 量 前 后 插 入0和5
current_time = [0; current_time; 5];

% 存 储 向 量
data_vectors{col-start_col+1} = current_data;
time_vectors{col-start_col+1} = current_time;

end

% 分 配 到 工 作 区
for i = 1:15
col_char = char('C' + i); % D=4→'D',...,R=18→'R'
assignin('base', ['vector_' col_char], data_vectors{i});
assignin('base', ['time_vector_' col_char], time_vectors{i});
end

% 显 示 结 果
disp('数 据 提 取 完 成:');
disp(['1. 数 据 向 量 已 存 储 为vector_D到vector_R (' num2str(length(data_vectors)) '个 向 量)']);
disp(' 每 个 数 据 向 量 开 头 和 结 尾 已 插 入60');
disp(['2. 对 应 时 间 向 量 已 存 储 为time_vector_D到time_vector_R (' num2str(length(time_vectors)) '个 向 量)']);
disp(' 每 个 时 间 向 量 开 头 已 插 入0， 结 尾 已 插 入5');
disp('对 应 关 系 说 明:');
disp(' − 插 入 后， 每 个 数 据 向 量 中 的 第2到end-1个 元 素 对 应 时 间 向 量 中 的 第2到end-1个 元 素');
disp(' − 原 始 对 应 关 系 保 持 不 变， 只 是 前 后 各 添 加 了 一 个 固 定 值');

% 做 自 然 三 次 样 条 插 值
ppD = csape(time_vector_D ,vector_D,'variational');
ppE = csape(time_vector_E ,vector_E,'variational');
ppF = csape(time_vector_F ,vector_F,'variational');
ppG = csape(time_vector_G ,vector_G,'variational');
ppH = csape(time_vector_H ,vector_H,'variational');
ppI = csape(time_vector_I ,vector_I,'variational');
ppJ = csape(time_vector_J ,vector_J,'variational');
ppK = csape(time_vector_K ,vector_K,'variational');
ppL = csape(time_vector_L ,vector_L,'variational');
ppM = csape(time_vector_M ,vector_M,'variational');
ppN = csape(time_vector_N ,vector_N,'variational');
ppO = csape(time_vector_O ,vector_O,'variational');
ppP = csape(time_vector_P ,vector_P,'variational');
ppQ = csape(time_vector_Q ,vector_Q,'variational');
ppR = csape(time_vector_R ,vector_R,'variational');

% 设 置 时 间 坐 标
time1 = [7 9 12 14 18 21 23]/24;
time2 = [7 9 12 14 18 21 23]/24+1;
time3 = [7 9 12 14 18 21 23]/24+2;
time4 = [7 9 12 14 18 21 23]/24+3;
time5 = [7 9 12 14 18 21 23]/24+4;

% 带 入 插 值 函 数 值 求 平 均
bike_D = (fnval(ppD,time1)+fnval(ppD,time2)+fnval(ppD,time3)+fnval(ppD,time4)+fnval(ppD,time5))/5;
bike_E = (fnval(ppE,time1)+fnval(ppE,time2)+fnval(ppE,time3)+fnval(ppE,time4)+fnval(ppE,time5))/5;
bike_F = (fnval(ppF,time1)+fnval(ppF,time2)+fnval(ppF,time3)+fnval(ppF,time4)+fnval(ppF,time5))/5;
bike_G = (fnval(ppG,time1)+fnval(ppG,time2)+fnval(ppG,time3)+fnval(ppG,time4)+fnval(ppG,time5))/5;
bike_H = (fnval(ppH,time1)+fnval(ppH,time2)+fnval(ppH,time3)+fnval(ppH,time4)+fnval(ppH,time5))/5;
bike_I = (fnval(ppI,time1)+fnval(ppI,time2)+fnval(ppI,time3)+fnval(ppI,time4)+fnval(ppI,time5))/5;
bike_J = (fnval(ppJ,time1)+fnval(ppJ,time2)+fnval(ppJ,time3)+fnval(ppJ,time4)+fnval(ppJ,time5))/5;
bike_K = (fnval(ppK,time1)+fnval(ppK,time2)+fnval(ppK,time3)+fnval(ppK,time4)+fnval(ppK,time5))/5;
bike_L = (fnval(ppL,time1)+fnval(ppL,time2)+fnval(ppL,time3)+fnval(ppL,time4)+fnval(ppL,time5))/5;
bike_M = (fnval(ppM,time1)+fnval(ppM,time2)+fnval(ppM,time3)+fnval(ppM,time4)+fnval(ppM,time5))/5;
bike_N = (fnval(ppN,time1)+fnval(ppN,time2)+fnval(ppN,time3)+fnval(ppN,time4)+fnval(ppN,time5))/5;
bike_O = (fnval(ppO,time1)+fnval(ppO,time2)+fnval(ppO,time3)+fnval(ppO,time4)+fnval(ppO,time5))/5;
bike_P = (fnval(ppP,time1)+fnval(ppP,time2)+fnval(ppP,time3)+fnval(ppP,time4)+fnval(ppP,time5))/5;
bike_Q = (fnval(ppQ,time1)+fnval(ppQ,time2)+fnval(ppQ,time3)+fnval(ppQ,time4)+fnval(ppQ,time5))/5;
bike_R = (fnval(ppR,time1)+fnval(ppR,time2)+fnval(ppR,time3)+fnval(ppR,time4)+fnval(ppR,time5))/5;