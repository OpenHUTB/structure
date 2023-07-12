function coeffs = calc_eigendecomposition(data, eigenvectors, method)
% calc_eigendecomposition.m
%
% 使用特征向量分解数据，并计算每个向量的贡献系数
%
% 输入:   数据          : 数据 [MxP]
%                        M = 点的数目, P = 独立数据的数目
%         特征向量      : 特征向量 [MxN]
%                        M = 点的数目, N = 特征向量的数目
%         方法         : 计算类型
%                        'matrix', 'matrix_separate', 'regression'
% 输出: coeffs         : 系数值 [NxP]
%

%%

[M,P] = size(data);
[~,N] = size(eigenvectors);

if nargin<3
    method = 'matrix';
end

switch method
    case 'matrix'
        coeffs = (eigenvectors.'*eigenvectors)\(eigenvectors.'*data);
    case 'matrix_separate'
        coeffs = zeros(N,P);
        
        for p = 1:P
            coeffs(:,p) = (eigenvectors.'*eigenvectors)\(eigenvectors.'*data(:,p));
        end
    case 'regression'
        coeffs = zeros(N,P);
        
        for p = 1:P
            coeffs(:,p) = regress(data(:,p), eigenvectors);
        end
end
    
end