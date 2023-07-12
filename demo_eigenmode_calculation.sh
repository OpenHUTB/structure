#!/bin/env bash

################################################################################################################################
### demo_eigenmode_calculation.sh
###
### Bash脚本演示如何计算皮层表面和皮层下体积的特征模式
### 
### 注意 1: 该脚本对开源外部包（Python环境内部和外部）有几个依赖项。
###       在运行此脚本之前，请参阅存储库的自述文件的“依赖项”部分。
### 注意 2: 例子1计算表面的特征模式
### 注意 3: 例子2计算体积的特征模式
###
### Original: James Pang, Monash University, 2022
################################################################################################################################


### 提示:
# If using an HPC system, load the gmsh, python, freesurfer, and connectome workbench modules first
# An example syntax is shown below (syntax depends on your HPC system)
# module load gmsh
# module load anaconda/2019.03-Python3.7-gcc5
# module load freesurfer
# module load connectome


################################################################################################################################
### 例子 1
# 计算左右fsLR_32k模板中等厚表面的200个表面特征模式，包括和不包括掩模，这将皮层与内侧壁区分开来。建议使用皮层掩膜。
#
# 需要的输入：（1）vtk格式的皮层表面；
#            （2）txt或gii格式的皮层掩膜（皮层值为1，内侧壁值为0）
#
### NOTE 1: If your input surface is not a vtk file (e.g., a FreeSurfer surf file or a gifti file), you can convert it to vtk 
###         using the FreeSurfer command mris_convert.
### NOTE 2: Surface structures for pial, white, sphere, inflated, very_inflated surfaces in fsLR_32k space are also provided in 
###         data/template_surface_volumes for you to use. Just change the structure variable below.
###
### Original: James Pang, Monash University, 2022
################################################################################################################################

surface_interest='fsLR_32k'
structure='midthickness'
hemispheres='lh rh'
num_modes=200
save_cut=0

for hemisphere in ${hemispheres}; do
	echo Processing ${hemisphere}

	surface_input_filename=data/template_surfaces_volumes/${surface_interest}_${structure}-${hemisphere}.vtk

	# with cortex mask (remove medial wall)
    # this is the advisable way
	is_mask=1
    output_eval_filename=data/template_eigenmodes/${surface_interest}_${structure}-${hemisphere}_eval_${num_modes}.txt
    output_emode_filename=data/template_eigenmodes/${surface_interest}_${structure}-${hemisphere}_emode_${num_modes}.txt
    mask_input_filename=data/template_surfaces_volumes/${surface_interest}_cortex-${hemisphere}_mask.txt

    python surface_eigenmodes.py ${surface_input_filename} \
    							 ${output_eval_filename} ${output_emode_filename} \
    							 -save_cut ${save_cut} -N ${num_modes} -is_mask ${is_mask} \
                                 -mask ${mask_input_filename}
                

    # without cortex mask
    is_mask=0
    output_eval_filename=data/template_eigenmodes/no_mask_${surface_interest}_${structure}-${hemisphere}_eval_${num_modes}.txt
    output_emode_filename=data/template_eigenmodes/no_mask_${surface_interest}_${structure}-${hemisphere}_emode_${num_modes}.txt

    python surface_eigenmodes.py ${surface_input_filename} \
    							 ${output_eval_filename} ${output_emode_filename} \
    							 -save_cut ${save_cut} -N ${num_modes} -is_mask ${is_mask}
done


# ################################################################################################################################
# ### EXAMPLE 2
# ### Calcute 31 volume eigenmodes of the thalamus (tha), the mask of which came from the Harvard-Oxford 2mm resolution atlas with 
# ### 25% probability threshold registered on HCP data
# ###
# ### Input needed: (1) volume mask of the thalamus in nifti format
# ###
# ### NOTE 1: Subcortical volume masks for striatum (striatum) and hippocampus (hippo) are also provided in 
# ###         data/template_surface_volumes for you to use. Just change the structure variable below.
# ################################################################################################################################

# structure='tha'
# hemispheres='lh rh'
# num_modes=31
# normalization_type='none'
# normalization_factor=1

# for hemisphere in ${hemispheres}; do
#     echo Processing ${hemisphere}

#     nifti_input_filename=data/template_surfaces_volumes/hcp_${structure}-${hemisphere}_thr25.nii.gz
#     nifti_output_filename=data/template_eigenmodes/hcp_${structure}-${hemisphere}_emode_${num_modes}.nii.gz
#     output_eval_filename=data/template_eigenmodes/hcp_${structure}-${hemisphere}_eval_${num_modes}.txt
#     output_emode_filename=data/template_eigenmodes/hcp_${structure}-${hemisphere}_emode_${num_modes}.txt
    
#     python volume_eigenmodes.py ${nifti_input_filename} ${nifti_output_filename} \
#                                 ${output_eval_filename} ${output_emode_filename} \
#                                 -N ${num_modes} -norm ${normalization_type} -normfactor ${normalization_factor}
# done
