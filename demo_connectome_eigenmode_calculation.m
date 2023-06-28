%%% demo_connectome_eigenmode_calculation.m
%%% 
%%% MATLAB脚本演示如何计算各种基于连接体的高分辨率特征模式
%%% 特别是该脚本演示了如何
%%% (1) 计算连接体的特征模式，并且
%%% (2) 计算指数距离规则(exponential distance rule, EDR)的连接体特征模式
%%%
%%% 注意 1: 该脚本在具有10k个顶点的fsaverage5表面模板上
%%%         计算合成连接体和EDR连接体的基于连接体的特征模式。这是为了演示执行快速计算。
%%%         但是，数据文件夹中提供了其他曲面分辨率供使用。
%%%         只需更改下面的surface_interest变量即可。
%%% 注意 2: 也可以使用实证上的高分辨率连接体。只需更改下面的连接体变量。
%%% 但是，请确保变量是一个大小为[顶点数量x顶点数量]的数组。
%%% 注意 3: 目前的演示使用了50种模式。为了进行正确的分析，建议使用100到200种模式。


%% 加载相关的matlab函数库
addpath(genpath('functions_matlab'));

%% 加载fsaverage5的曲面文件
surface_interest = 'fsaverage5_10k';
hemisphere = 'lh';
mesh_interest = 'midthickness';

[vertices, faces] = read_vtk( ...
    sprintf('data/template_surfaces_volumes/%s_%s-%s.vtk', ...
    surface_interest, mesh_interest, hemisphere));
surface_midthickness.vertices = vertices';
surface_midthickness.faces = faces';

% 加载大脑皮层掩膜
cortex = dlmread( ...
    sprintf('data/template_surfaces_volumes/%s_cortex-%s_mask.txt', ...
    surface_interest, hemisphere));
cortex_ind = find(cortex);

% 计算顶点数
num_vertices = length(cortex);


%% 计算合成的连接体特征模式
hemisphere = 'lh';
surface_to_analyze = surface_midthickness;


%% 生成曲面局部连接
surface_connectivity = calc_surface_connectivity(surface_to_analyze);

% 删除与内侧壁相对应的顶点
surface_connectivity = surface_connectivity(cortex_ind, cortex_ind);


%% 生成合成的连接体

% 用你的经验数据替换下面的连接体变量。但是，请确保先移除与内侧壁相对应的顶点。
connectome = zeros(size(surface_connectivity));

% 为连接组的上三角形元素生成从 imin 到 imax 的伪随机整数，
% 现在设置随机数以实现可重复性。
rng(1)
imin = 0;
imax = 1e4;
triu_ind = calc_triu_ind(connectome);
triu_val = randi([imin, imax], size(triu_ind,1), size(triu_ind,2));

connectome(triu_ind) = triu_val;

% 对称连接体
connectome = connectome + connectome';

% 阈值连接体
threshold = 0.01; % 保留 1% 的连接； 相应地改变
connectome_threshold = threshold_edges_proportional(connectome, threshold);


%% 结合表面局部连接和连接组
surface_with_connectome = surface_connectivity + (connectome_threshold>0);
surface_with_connectome(surface_with_connectome>0) = 1;


%% 计算模式
% 这部分的速度取决于surface_with_connectome的分辨率。
% Higher resolution matrices = Slower
% eig_vec = eigenvectors (eigenmodes)
% eig_val = eigenvalues

% 由于计算要求较高，如果您只想可视化模式，则预先计算的数据将存储在 data/examples 中。 
% 对于完整计算，设置 is_demo_calculate = 1
is_demo_calculate = 0;
if is_demo_calculate
    num_modes = 50;
    [eig_vec_temp, eig_val] = calc_network_eigenmode( ...
        surface_with_connectome, num_modes);
    
    % 返回具有零值的内侧壁顶点
    eig_vec = zeros(num_vertices, num_modes);
    eig_vec(cortex_ind,:) = eig_vec_temp(:,1:num_modes);
    save( ...
        sprintf('data/examples/synthetic_connectome_eigenmodes-%s_%i.mat', ...
        hemisphere, num_modes), 'eig_val', 'eig_vec', '-v7.3')
else
    num_modes = 50;
    load( ...
        sprintf('data/examples/synthetic_connectome_eigenmodes-%s_%i.mat', ...
        hemisphere, num_modes), 'eig_vec')
end


%% 结果的一些可视化
% 具有内侧壁视图的第一至第五模式
mode_interest = [1:5];
surface_to_plot = surface_midthickness;
data_to_plot = eig_vec(:, mode_interest);
medial_wall = find(cortex==0);
with_medial = 1;

% 注意: 上述演示计算得出的连接组特征模式不一定与论文中的相似。
% 这是因为上面使用的连接组是人工生成的（即，不是实证的）。
fig = draw_surface_bluewhitered_gallery_dull( ...
    surface_to_plot, data_to_plot, hemisphere, medial_wall, with_medial);
fig.Name = 'Multiple connectome eigenmodes with medial wall view';


%% 计算人工合成 EDR 连接组特征模式
hemisphere = 'lh';
surface_to_analyze = surface_midthickness;


%% 计算没有内壁的表面顶点的欧式距离
surface_dist = squareform(pdist(surface_to_analyze.vertices(cortex_ind,:)));


%% 生成人工合成 EDR 连接组

% 概率函数
Pspace_func = @(scale, distance) exp(-scale*distance);

% 生成伪随机数以与概率函数进行比较
% 现在设置随机数是为了可复现
rng(1)
rand_prob = rand(size(surface_dist));
rand_prob = triu(rand_prob,1) + triu(rand_prob,1)';
rand_prob(1:1+size(rand_prob,1):end) = 1;

% 计算概率
% Scale=0.120与经验结构连通性数据相匹配。
% 但可以相应地更改其值。
scale = 0.120;
Pspace = Pspace_func(scale, surface_dist);
Pspace(1:1+size(Pspace,1):end) = 0;
Pspace = Pspace/max(Pspace(:));
    
% 生成EDR连接体
connectome = double(rand_prob < Pspace);
connectome(1:1+size(connectome,1):end) = 0;
 

%% 计算模式
% 这个部分的速度取决于连接体的分辨率。
% Higher resolution matrices = Slower
% eig_vec = eigenvectors (特征模式)
% eig_val = eigenvalues

% 由于计算要求很高，如果只想可视化模式，则预先计算的数据会存储在数据/示例中。
% 为了进行完整的计算，设置is_demo_calculate=1
is_demo_calculate = 0;
if is_demo_calculate
    num_modes = 50;
    [eig_vec_temp, eig_val] = calc_network_eigenmode(connectome, num_modes);
    
    % Bring back medial wall vertices with zero values
    eig_vec = zeros(num_vertices, num_modes);
    eig_vec(cortex_ind,:) = eig_vec_temp(:,1:num_modes);
    save( ...
        sprintf('data/examples/synthetic_EDRconnectome_eigenmodes-%s_%i.mat', ...
        hemisphere, num_modes), 'eig_val', 'eig_vec', '-v7.3')
else
    num_modes = 50;
    load( ...
        sprintf('data/examples/synthetic_EDRconnectome_eigenmodes-%s_%i.mat', ...
        hemisphere, num_modes), 'eig_vec')
end


%% 一些结果的可视化
% 带内侧壁视图的第1至第5模式
mode_interest = [1:5];
surface_to_plot = surface_midthickness;
data_to_plot = eig_vec(:, mode_interest);
medial_wall = find(cortex==0);
with_medial = 1;

fig = draw_surface_bluewhitered_gallery_dull(surface_to_plot, data_to_plot, hemisphere, medial_wall, with_medial);
fig.Name = 'Multiple EDR connectome eigenmodes with medial wall view';
