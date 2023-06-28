%%% demo_eigenmode_analysis.m
%%%
%%% 演示如何使用表面特征模式来分析fMRI数据的 MATLAB 脚本
%%% 特别是该脚本演示了如何：
%%% (1) 重建任务fMRI空间图，
%%% (2) 重建静息状态fMRI时空图和功能连接（functional connectivity, FC）矩阵，以及
%%% (3) 计算基于特征模式空间图的功率谱内容
%%%
%%% 注意 1：该脚本还可用于使用其他类型的表面特征模式（例如连接组特征模式）
%%% 来分析 fMRI 数据。 只需更改下面的 eigenmodes 变量即可。 
%%% 但是，请确保变量是大小为 [顶点数 x 模式数] 的数组。
%%% 注意 2：当前演示使用 50 种模式。 为了进行正确的分析，
%%% 建议使用 100 到 200 种模式。
%%% data/template_eigenmodes 中提供了 200 个模板几何特征模式。


%% 加载 Matlab 函数相关的代码库
addpath(genpath('functions_matlab'));


%% 加载用于可视化的表面文件
surface_interest = 'fsLR_32k';  % 感兴趣表面
hemisphere = 'lh';              % 大脑半球
mesh_interest = 'midthickness'; % 感兴趣表面的网格划分稠密度

[vertices, faces] = read_vtk( ...
    sprintf('data/template_surfaces_volumes/%s_%s-%s.vtk', ...
    surface_interest, mesh_interest, hemisphere));
surface_midthickness.vertices = vertices';
surface_midthickness.faces = faces';

% 加载皮层掩膜
cortex = dlmread( ...
    sprintf('data/template_surfaces_volumes/%s_cortex-%s_mask.txt', ...
    surface_interest, hemisphere));
cortex_ind = find(cortex);


%% 重建单受试者任务 fMRI 空间图
hemisphere = 'lh';
num_modes = 50;


%% 加载特征模式数据和empirical数据
% 加载 Load 50 fsLR_32k 模板中等密度表面特征模式
eigenmodes = dlmread(sprintf('data/examples/fsLR_32k_midthickness-%s_emode_%i.txt', hemisphere, num_modes));

% 如果使用data/template_enginemodes中提供的200个模式，
% 则将上面的行替换为下面的行，并使num_modes=200
% eigenmodes = dlmread(sprintf('data/template_eigenmodes/fsLR_32k_midthickness-%s_emode_%i.txt', hemisphere, num_modes));

% 加载样本 单受试者 tfMRI z-stat 数据
data = load(sprintf('data/examples/subject_tfMRI_zstat-%s.mat', hemisphere));
data_to_reconstruct = data.zstat;


%% 使用1到num_modes个特征模式计算重建β系数
recon_beta = zeros(num_modes, num_modes);
for mode = 1:num_modes
    basis = eigenmodes(cortex_ind, 1:mode);
    
    recon_beta(1:mode,mode) = calc_eigendecomposition( ...
        data_to_reconstruct(cortex_ind), basis, 'matrix');
end


%% 使用1到num_mode个特征模式计算重建精度
% 重建精度 = 经验数据和重建数据的相关性

% 在顶点层次
recon_corr_vertex = zeros(1, num_modes);               
for mode = 1:num_modes
    recon_temp = eigenmodes(cortex_ind, 1:mode)*recon_beta(1:mode,mode);

    recon_corr_vertex(mode) = corr(data_to_reconstruct(cortex_ind), recon_temp);
end

% 在分割层次
parc_name = 'Glasser360';
parc = dlmread( ...
    sprintf('data/parcellations/fsLR_32k_%s-%s.txt', parc_name, hemisphere));

recon_corr_parc = zeros(1, num_modes);               
for mode = 1:num_modes
    recon_temp = eigenmodes(:, 1:mode)*recon_beta(1:mode,mode);

    recon_corr_parc(mode) = corr(calc_parcellate(parc, data_to_reconstruct), calc_parcellate(parc, recon_temp));
end


%% 一些结果的可视化

% 重建精度 vs 定点和分割层次的模式数
figure('Name', 'tfMRI reconstruction - accuracy');
hold on;
plot(1:num_modes, recon_corr_vertex, ...
    'k-', 'linewidth', 2, 'displayname', 'vertex')
plot(1:num_modes, recon_corr_parc, ...
    'b-', 'linewidth', 2, 'displayname', 'parcellated')
hold off;
leg = legend('fontsize', 12, 'location', 'southeast', 'box', 'off');
set(gca, 'fontsize', 10, 'ticklength', [0.02 0.02], ...
    'xlim', [1 num_modes], 'ylim', [0 1])
xlabel('number of modes', 'fontsize', 12)
ylabel('reconstruction accuracy', 'fontsize', 12)

% 使用N=num_modes个模式重建的空间图
N = num_modes;
surface_to_plot = surface_midthickness;
data_to_plot = eigenmodes(:, 1:N)*recon_beta(1:N,N);
medial_wall = find(cortex==0);
with_medial = 1;

fig = draw_surface_bluewhitered_dull( ...
    surface_to_plot, data_to_plot, hemisphere, medial_wall, with_medial);
fig.Name = sprintf('tfMRI reconstruction - surface map using %i modes', N);


%% 重建单个受试者静息态fMRI时空图和功能连接矩阵
hemisphere = 'lh';
num_modes = 50;


%% 加载特征模式和经验数据

% 加载50个 fsLR_32k 模板的中等密度表面特征模式
eigenmodes = dlmread( ...
    sprintf('data/examples/fsLR_32k_midthickness-%s_emode_%i.txt', ...
    hemisphere, num_modes));

% 如果使用data/template_enginemodes中提供的200个模式，
% 则将上面的代码行替换为下面的代码行，并使num_modes=200
% eigenmodes = dlmread( ...
%     sprintf('data/template_eigenmodes/fsLR_32k_midthickness-%s_emode_%i.txt', ...
%     hemisphere, num_modes));

% 加载示例单个受试者rfMRI时间序列数据
data = load( ...
    sprintf('data/examples/subject_rfMRI_timeseries-%s.mat', hemisphere));
data_to_reconstruct = data.timeseries;
T = size(data_to_reconstruct, 2);


%% 使用1到 num_modes 个特征模式计算重建β系数
recon_beta = zeros(num_modes, T, num_modes);
for mode = 1:num_modes
    basis = eigenmodes(cortex_ind, 1:mode);
    
    recon_beta(1:mode,:,mode) = calc_eigendecomposition( ...
        data_to_reconstruct(cortex_ind,:), basis, 'matrix');
end


%% 使用1到num_mode个特征模式本征模计算重建精度
% 重建精度 = 经验数据和重建数据的相关性

% 在分割层次
parc_name = 'Glasser360';
parc = dlmread( ...
    sprintf('data/parcellations/fsLR_32k_%s-%s.txt', parc_name, hemisphere));
num_parcels = length(unique(parc(parc>0)));

% 提取上三角索引
triu_ind = calc_triu_ind(zeros(num_parcels, num_parcels));

% 计算实证的（实验记录的）功能连接
data_parc_emp = calc_parcellate(parc, data_to_reconstruct);
data_parc_emp = calc_normalize_timeseries(data_parc_emp');
data_parc_emp(isnan(data_parc_emp)) = 0;

FC_emp = data_parc_emp'*data_parc_emp;
FC_emp = FC_emp/T;
FCvec_emp = FC_emp(triu_ind);

% 计算重建的功能连接和精度（模式较多时运行速度较慢）
FCvec_recon = zeros(length(triu_ind), num_modes);
recon_corr_parc = zeros(1, num_modes);               
for mode = 1:num_modes
    recon_temp = eigenmodes(:, 1:mode)*squeeze(recon_beta(1:mode,:,mode));
 
    data_parc_recon = calc_parcellate(parc, recon_temp);
    data_parc_recon = calc_normalize_timeseries(data_parc_recon');
    data_parc_recon(isnan(data_parc_recon)) = 0;

    FC_recon_temp = data_parc_recon'*data_parc_recon;
    FC_recon_temp = FC_recon_temp/T;

    FCvec_recon(:,mode) = FC_recon_temp(triu_ind);
                    
    recon_corr_parc(mode) = corr(FCvec_emp, FCvec_recon(:,mode));
end


%% 一些结果的可视化

% 重建精度 vs 在分割层次的模式数
figure('Name', 'rfMRI reconstruction - accuracy');
hold on;
plot(1:num_modes, recon_corr_parc, 'b-', 'linewidth', 2)
hold off;
set(gca, 'fontsize', 10, 'ticklength', [0.02 0.02], 'xlim', [1 num_modes], 'ylim', [0 1])
xlabel('number of modes', 'fontsize', 12)
ylabel('reconstruction accuracy', 'fontsize', 12)

% 使用N = num_modes 个模式的重建功能连接
N = num_modes;
FC_recon = zeros(num_parcels, num_parcels);
FC_recon(triu_ind) = FCvec_recon(:,N);
FC_recon = FC_recon + FC_recon';
FC_recon(1:(num_parcels+1):num_parcels^2) = 1;

figure('Name', sprintf('rfMRI reconstruction - FC matrix using %i modes', N));
imagesc(FC_recon)
caxis([-1 1])
colormap(bluewhitered)
cbar = colorbar;
set(gca, 'fontsize', 10, 'ticklength', [0.02 0.02])
xlabel('region', 'fontsize', 12)
ylabel('region', 'fontsize', 12)
ylabel(cbar, 'FC', 'fontsize', 12)
axis image


%% 计算空间图的模态功率谱内容
hemisphere = 'lh';
num_modes = 50;


%% 加载特征模式数据和实证数据

% 加载50个 fsLR_32k 模板的中等密度表面特征模式
eigenmodes = dlmread( ...
    sprintf('data/examples/fsLR_32k_midthickness-%s_emode_%i.txt', ...
    hemisphere, num_modes));

% 如果使用data/template_enginemodes中提供的200个模式，
% 则将上面的行替换为下面的行，并使num_modes=200
% eigenmodes = dlmread( ...
%     sprintf('data/template_eigenmodes/fsLR_32k_midthickness-%s_emode_%i.txt', ...
%     hemisphere, num_modes));

% 加载示例 neurovault 空间图
if strcmpi(hemisphere, 'lh')
    data = gifti('data/examples/neurovault_map_100259.L.func.gii');
elseif strcmpi(hemisphere, 'rh')
    data = gifti('data/examples/neurovault_map_100259.R.func.gii');
end
data_to_reconstruct = data.cdata;


%% 计算重建贝塔系数

basis = eigenmodes(cortex_ind, 1:num_modes);    
recon_beta = calc_eigendecomposition( ...
    data_to_reconstruct(cortex_ind), basis, 'matrix');


%% 计算模式功率谱

[~, spectrum_norm] = calc_power_spectrum(recon_beta);


%% 一些结果的可视化

% 归一化的功率谱
figure('Name', 'rfMRI reconstruction - accuracy');
bar(1:num_modes, spectrum_norm)
set(gca, 'fontsize', 10, 'ticklength', [0.02 0.02], ...
    'xlim', [2 num_modes], 'yscale', 'log')
xlabel('mode', 'fontsize', 12)
ylabel('normalized power (log scale)', 'fontsize', 12);
