function [status,message] =  Excel_write(image_name,bpp,Byte,...
    bpp_code,Byte_code,bpp_dict,Byte_dict,...
    PSNR,SSIM,pos,sampling_rate,N)


data = {image_name,bpp,Byte,bpp_code,Byte_code,...
    bpp_dict,Byte_dict,PSNR,SSIM,sampling_rate,N};


position = sprintf ('%s%d','A',pos);%strcat(str,str1)
[status,message] = xlswrite('test.xlsx',...
    data,'sheet1',position);

end