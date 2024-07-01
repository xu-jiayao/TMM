%this file is to compress the signal in the transform domain 
%based on compressed sensing 
clear;
close all;
clc;
profile on;

path(path, '../../512&512');
path(path, '../../4k');
path(path, '../../256&256');
path(path, '../../320&480');
path(path, '../../image');
path(path, './result');

%read image files
imageOriginalPath = '../../256&256';
imageFiles = [dir(fullfile(imageOriginalPath,'*png'));
              dir(fullfile(imageOriginalPath,'*jpg'));
              dir(fullfile(imageOriginalPath,'*tiff'));
              dir(fullfile(imageOriginalPath,'*tif'));
              dir(fullfile(imageOriginalPath,'*yuv'));];
numFiles = length(imageFiles);

%initialization of parameterss
sub_pixels = 4;%block size
n   = sub_pixels*sub_pixels;%n
sampling_rate = 0.5;
m = round(n*sampling_rate);%m

%change
iter_num = 8; %0.5->14    0.75->21   0.25->8

%record the data by excel
count_pos = 2;
data = {'image','bpp','Byte','bpp_code','Byte_code','bpp_dict','Byte_dict','PSNR','SSIM','sampling_rate','N'};
[status,message] = xlswrite('test.xlsx',data,'sheet1','A1');

rate = 6;
shift_point = 9;
% 0.5 & 0.25
step_0 = 6;
step_1 = 7;
%only for 0.75
step_2 = 7;

total_bpp_test = 0;
total_time_en = 0;
for image_loop = 1:numFiles 
    %load image
    image_loop
    imageFiles(image_loop).name
	
    %load image
    load_image = imread(imageFiles(image_loop).name); 

%     gray image
    if size(load_image,3)==3
        original_image = double(rgb2gray(load_image));
    else
        original_image = double(load_image);
    end
    
    %change size 
    size_height = size(original_image,1);
    size_width = size(original_image,2);
    residual_height = mod(size_height,sub_pixels);
    residual_width = mod(size_width,sub_pixels);
    change_height = 1:size(original_image,1)-residual_height;
    change_width = 1:size(original_image,2)-residual_width;
    original_image = original_image(change_height,change_width);
    [num_rows,num_cols] = size(original_image);
    
    %get the measurement matrix
    [theta, phi,psi] =  GetMeasurementMatrix(m,n);
    
    N_1 = zeros(1, size(original_image,1)/sub_pixels) + sub_pixels;
    N_2 = zeros(1, size(original_image,2)/sub_pixels) + sub_pixels;
    C = mat2cell(double(original_image), N_1, N_2);
    
    num_of_rows = size(original_image,1)/sub_pixels;
    num_of_columns = size(original_image,2)/sub_pixels;
    %%measurement 
    y_deresidual = cell(num_of_rows,num_of_columns);
    %%original transform domain data
    original_trans_cell= cell(num_of_rows,num_of_columns);
    %%reconstruct into transform domain
    trans_cell = cell(num_of_rows,num_of_columns);
    zero_vector = zeros(n-m,1);
    temp_theta = theta(:,1:m);
    code = [];
    code_dict = [];
    %%reconstruct image
    trans_image = cell(num_of_rows,num_of_columns);
    bpp_test = 0;
    bpp_test_block = 0;
    time_ = 0;
    %coding
    for indexX = 1:num_of_rows
        odd_first_vec = [];
        odd_sec_vec = [];
        other_vec = [];
        for indexY = 1:num_of_columns
            
            %measurement compression 
            one_block_image = reshape(C{indexX,indexY}.',1,[])';
            tic
            y_deresidual{indexX,indexY} = phi * one_block_image;
            time_ = toc +time_;
            
            %record the original data in the transfrom domain 
            original_trans_cell{indexX,indexY} = psi^(-1)*one_block_image;
            
            %reconstruct the measurement into transform domain
            temp_residual = y_deresidual{indexX,indexY};
            recons_in_trans_inverse = double(int64(temp_theta^(-1)*2^rate))*temp_residual;

            %compression procedure %%%%%%%%%%%%%%%%%
            %%% Quantization Parameter
            step_QR  = fix(recons_in_trans_inverse/(2^shift_point));
            
            %data after quantization & input of entropy coding
            trans_cell{indexX, indexY}  = step_QR;
            
            %bpp test
            bpp_test_block = bpp_test_block + measurement_entropy(temp_residual,num_rows*num_cols);
            

        end
        
        %%sep first row
        cell_temp = trans_cell(indexX, :);
        mat_temp = cell2mat(cell_temp);
        [rows,~] = size(mat_temp);
        nbin = unique(mat_temp);
        
        %first row code
        temp_block_first = mat_temp(1,:);
        temp_block_first = temp_block_first';
        nbin_first = unique(temp_block_first);
        if size(nbin_first,1) == 1
            p_first = 1;
            dict_first = {nbin_first 1};
        else 
            frequency_first = hist(temp_block_first,nbin_first);
            p_first = frequency_first/sum(frequency_first);
            dict_first = huffmandict(nbin_first,p_first);
        end
        bi_fre_first = huffmanenco(temp_block_first,dict_first);
        bi_table_first = codingHuffmanTable(dict_first);
        %others
        temp_block = mat_temp(2:rows,:);
        temp_block = reshape(temp_block,[],1);
        nbin = unique(temp_block);
        if size(nbin,1) == 1
            p = 1;
            dict = {nbin 1};
        else 
            frequency = hist(temp_block,nbin);
            p = frequency/sum(frequency);
            dict = huffmandict(nbin,p);
        end
        bi_fre = huffmanenco(temp_block,dict);
        code = [code; bi_fre_first; bi_fre];
        bi_table = codingHuffmanTable(dict);
        code_dict = [code_dict bi_table_first bi_table];
        
    end
    
    bpp_code = numel(code)/(256*256);
    Byte_code = numel(code)/8;
    bpp_dict = numel(code_dict)/(256*256);
    Byte_dict = numel(code_dict)/8;
    bpp_cal = bpp_code + bpp_dict;
    Byte = Byte_code + Byte_dict;
	
	
    %reconstruction 
    for indexX = 1:num_of_rows
        for indexY = 1:num_of_columns
            
            %entropy decoding
            sig = huffmandeco(code,dict);
            %inverse from transform domain
            %one step 
            recons_in_trans_inverse_16 = trans_cell{indexX, indexY};
            recons_in_trans_inverse = [recons_in_trans_inverse_16;zero_vector];
            trans_block_image = fix(psi*recons_in_trans_inverse/(2^(rate - shift_point)));
            trans_image{indexX, indexY} = reshape(trans_block_image.',sub_pixels,[])';
            
        end
    end

    trans_final_image_reconstruct = round(cell2mat(trans_image)); 
    trans_image_psnr = PSNR(trans_final_image_reconstruct, original_image)
    trans_image_ssim = ssim(trans_final_image_reconstruct, original_image)
    total_bpp_test = total_bpp_test + bpp_test_block;
    
    imwrite(uint8(trans_final_image_reconstruct),fullfile(strcat('./result/', ...
        '_SR_', num2str(sampling_rate),...
        '_N_', num2str(n),...
        '_BPP_',num2str(bpp_cal),...
        '_Byte_',num2str(Byte),...
        '_PSNR_',num2str(trans_image_psnr), ...
        '_SSIM_',num2str(trans_image_ssim),...
        '_NAME_',imageFiles(image_loop).name)));

    [status,message] =  Excel_write(imageFiles(image_loop).name,...
        num2str(bpp_cal),num2str(Byte),...
        num2str(bpp_code),num2str(Byte_code),...
        num2str(bpp_dict),num2str(Byte_dict),...
        num2str(trans_image_psnr),num2str(trans_image_ssim),count_pos,...
        num2str(sampling_rate),num2str(n));
    
    count_pos = count_pos+1;
    
end 
