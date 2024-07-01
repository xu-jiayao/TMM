%this function packeges the huffman table 
%input: dict [value, binary code]
%output: binary code result
%the first 5 bits is the number of value in this dict (the biggest number is 64)
%the value are all set as 9 bits (one sign bit, 8 value bits)
%coding all values first
%then code the binary code one by one.
%option: the most save way is to code the binary code in log(number) (upper
%integer) then code the binary code
function bi_table = codingHuffmanTable(dict)

bi_table = [];
[nums,~] = size(dict);
%code the number of values
bi_nums = de2bi(nums);
if numel(bi_nums)<5
    bi_nums = [zeros(1,5-numel(bi_nums)) bi_nums];
end
bi_table = bi_nums;

%code values
values_vec = dict(:,1);
values_vec = cell2mat(values_vec);
bi_value = [];

for i = 1:nums
    if values_vec(i)<0
        value = abs(values_vec(i));
        bi_value = de2bi(value);
        if numel(bi_value)<8
            bi_value = [1 zeros(1,8-numel(bi_value)) bi_value];
        end
    else
        value = values_vec(i);
        bi_value = de2bi(value);
        if numel(bi_value)<8
            bi_value = [0 zeros(1,8-numel(bi_value)) bi_value];
        end
    end
    bi_table = [bi_table bi_value];
    bi_value = [];
    
end

%code binary code
code_vec = dict(:,2);

for i = 1:nums
    bi_table = [bi_table code_vec{i}];
end

end