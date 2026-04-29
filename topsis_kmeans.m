% ------------------------------------------------------------------------
% 阶 段 一： 带 评 价 准 则 的 K−means 聚 类
% ------------------------------------------------------------------------

[row, col, count] = find(distribution); % 非 零 点 坐 标 与 单 车 数 量， 在 问 题 二 中 得 到
load('important_locations.mat');%在 问 题 二 中 得 到
parking_points = [col, row]; % X=col, Y=row
bike_counts = count;

% ---------- 评 价 准 则 ----------
predicted_counts = 0.9 * bike_counts;
supply_demand_match = 1 - abs(predicted_counts - bike_counts) ./ max(predicted_counts, bike_counts);

avg_distance = zeros(size(parking_points,1), 1);
for i = 1:size(parking_points,1)
    d = sqrt(sum((important_locations - parking_points(i,:)).^2, 2));
    avg_distance(i) = mean(d);
end

% ---------- 多 K 聚 类 ----------
K_range = 8:15;
all_results = struct(); % 保 存 所 有 K 的 聚 类 结 果
max_sample = 2000; % 每 次 最 多 采 样 这 么 多 点

for K = K_range
    fprintf('处 理 K = %d...\n', K);
    
    % 如 果 数 据 量 太 大 就 采 样
    N = size(parking_points,1);
    sample_idx = randsample(N, min(max_sample, N));
    sampled_points = parking_points(sample_idx, :);
    sampled_sdm = supply_demand_match(sample_idx);
    sampled_dist = avg_distance(sample_idx);
    
    best_J = Inf;
    best_idx = [];
    best_C = [];
    
    % 多 次 聚 类 尝 试
    for trial = 1:5
        try
            [idx, C] = kmeans(sampled_points, K, ...
                'Start', 'plus', ...
                'MaxIter', 300, ...
                'Replicates', 1, ...
                'Display', 'off');
            
            % 计 算 目 标 函 数
            cluster_SSE = 0;
            cluster_S3 = 0;
            for k = 1:K
                members = (idx == k);
                if sum(members) == 0
                    continue;
                end
                cluster_SSE = cluster_SSE + mean(sampled_sdm(members));
                cluster_S3 = cluster_S3 + mean(sampled_dist(members));
            end
            
            cluster_SSE = cluster_SSE / K;
            cluster_S3 = cluster_S3 / K;
            J = -0.8 * cluster_SSE + 0.2 * cluster_S3;
            
            if J < best_J
                best_J = J;
                best_idx = idx;
                best_C = C;
            end
        catch ME
            warning('K−means 聚 类 失 败：%s', ME.message);
        end
    end
    
    % 保 存 结 果
    all_results(K).K = K;
    all_results(K).idx = best_idx;
    all_results(K).centroids = best_C;
    all_results(K).J = best_J;
    all_results(K).sampled_points = sampled_points;
    
    % 可 视 化
    figure;
    gscatter(sampled_points(:,1), sampled_points(:,2), best_idx);
    hold on;
    plot(best_C(:,1), best_C(:,2), 'kx', 'MarkerSize', 12, 'LineWidth', 2);
    title(['K = ', num2str(K), ' 的 最 优 聚 类']);
    xlabel('X');
    ylabel('Y');
    legend('Location', 'bestoutside');
    hold off;
end

% ------------- 阶 段 二： TOPSIS 评 估 各 K 聚 类 方 案 -------------
% 权 重： 与 LaTeX 中 表 格 一 致
weights = [0.06, 0.04, 0.13, 0.42, 0.35]; % [S1, S2, S3, S4, S5]

% 初 始 化 指 标 矩 阵， 行 数 = K 个 方 案， 列 数 = 5 个 指 标
num_K = length(K_range);
criteria_matrix = zeros(num_K, 5);

k_idx = 1;
for K = K_range
    result = all_results(K);
    C = result.centroids;
    idx = result.idx;
    points = result.sampled_points;
    
    % --- S1: 聚 类 数 量 ---
    S1 = K;
    
    % --- S2: 聚 类 中 心 之 间 的 平 均 距 离 ---
    pairwise_dist = pdist(C);
    S2 = mean(pairwise_dist);
    
    % --- S3: 聚 类 中 心 到 重 要 位 置 的 平 均 距 离 ---
    center_to_important = zeros(K, 1);
    for i = 1:K
        dists = sqrt(sum((important_locations - C(i,:)).^2, 2));
        center_to_important(i) = mean(dists);
    end
    S3 = mean(center_to_important);
    
    % --- S4: 供 需 匹 配 率（聚 类 内 部 平 均）---
    sdm_vals = supply_demand_match;
    sampled_idx = ismember(parking_points, points, 'rows'); % 匹 配 供 需 数 据
    cluster_sdm = 0;
    for k = 1:K
        members = (idx == k);
        cluster_points = points(members,:);
        match_idx = ismember(parking_points, cluster_points, 'rows');
        cluster_sdm = cluster_sdm + mean(sdm_vals(match_idx));
    end
    S4 = cluster_sdm / K;
    
    % --- S5: 调 度 成 本（各 点 到 对 应 中 心 的 距 离 × 点 数）---
    total_cost = 0;
    for k = 1:K
        members = (idx == k);
        cluster_points = points(members,:);
        center = C(k,:);
        dists = sqrt(sum((cluster_points - center).^2, 2));
        total_cost = total_cost + sum(dists);
    end
    S5 = total_cost;
    
    % 填 入 评 价 矩 阵
    criteria_matrix(k_idx, :) = [S1, S2, S3, S4, S5];
    k_idx = k_idx + 1;
end

% ------------- TOPSIS 处 理 -------------
% 1. 极 小 化 指 标：S1, S2, S3, S5 → 越 小 越 好； S4 越 大 越 好
% 将 S4 转 换 为 负 向（用 于 统 一 最 小 化 处 理）
criteria_matrix(:,4) = -criteria_matrix(:,4); % S4 反 转

% 2. 归 一 化
norm_matrix = criteria_matrix ./ vecnorm(criteria_matrix, 2, 1);

% 3. 加 权
weighted_matrix = norm_matrix .* weights;

% 4. 确 定 理 想 解 与 负 理 想 解
positive_ideal = min(weighted_matrix); % 越 小 越 好
negative_ideal = max(weighted_matrix);

% 5. 计 算 与 理 想 解 的 距 离
D_plus = sqrt(sum((weighted_matrix - positive_ideal).^2, 2));
D_minus = sqrt(sum((weighted_matrix - negative_ideal).^2, 2));

% 6. 得 分
scores = D_minus ./ (D_plus + D_minus);

% 找 出 得 分 最 高 的 K
[~, best_k_idx] = max(scores); % 使 用 best_k_idx 替 代 max_idx
best_K_value = K_range(best_k_idx);

% 输 出 最 优 聚 类 数 K 和 得 分
fprintf('TOPSIS 最 优 聚 类 数 K = %d， 得 分 = %.4f\n', best_K_value, scores(best_k_idx));

% 可 视 化 TOPSIS 结 果
figure;
plot(K_range, scores, '-o', 'LineWidth', 2, 'MarkerSize', 8);
xlabel('聚 类 数 K');
ylabel('TOPSIS 得 分');
title('不 同 K 值 的 TOPSIS 得 分');
grid on;

% 读 取 地 图
map_img = imread('map.png');

% 获 取 道 路 像 素 位 置（黄 色）
yellow_mask = map_img(:,:,1) == 255 & map_img(:,:,2) == 255 & map_img(:,:,3) == 0;
[road_y, road_x] = find(yellow_mask);
road_pixels = [road_x, road_y];

best_centroids = all_results(best_K_value).centroids;

% 对 每 个 聚 类 中 心， 找 到 最 近 的 道 路 点
parking_locations = zeros(size(best_centroids));
for i = 1:size(best_centroids,1)
    center = best_centroids(i,:);
    distances = sum((road_pixels - center).^2, 2);
    [~, min_idx] = min(distances);
    parking_locations(i,:) = road_pixels(min_idx,:);
end

disp('选 定 的 道 路 停 车 点 坐 标：');
disp(parking_locations);
save('final_parking_locations.mat', 'parking_locations');

figure;
imshow(map_img);
hold on;
plot(parking_locations(:,1), parking_locations(:,2), 'ro', 'MarkerSize', 8, 'LineWidth', 2);
title('投 影 到 道 路 上 的 停 车 点');
legend('最 终 停 车 点');
hold off;