function [theta, phi_before, psi ] = GetMeasurementMatrix(m,n)

hadamard_matrix          = hadamard(n);     % This function handles only the cases where n, n/12, or n/20 is a power of 2.
HadIdx                   = 0:n-1;                          % Hadamard index
M                        = log2(n)+1;                           % Number of bits to represent the index
binHadIdx                = fliplr(dec2bin(HadIdx,M))-'0'; % Bit reversing of the binary index
binSeqIdx                = zeros(n,M);                  % Pre-allocate memory
for k = M:-1:2
    % Binary sequency index
    binSeqIdx(:,k) = xor(binHadIdx(:,k),binHadIdx(:,k-1));
end
SeqIdx                   = binSeqIdx*pow2((M-1:-1:0)');    % Binary to integer sequency index
walshMatrix              = hadamard_matrix(SeqIdx+1,:); % 1-based indexing
phi_before                      = max(walshMatrix(1:n,1:n), 0);
% phi_before                      = walshMatrix(1:m,1:n);

theta = zeros(n,n); 
psi = zeros(n,n);
for theta_loop = 1:n
    ek = zeros(1,n);
    ek(theta_loop) = 1;
    psi_before = ifwht(ek)';
    psi(:,theta_loop) = psi_before;
    theta(:,theta_loop)      = phi_before*psi_before;
    %theta_left(:,theta_loop) = phi_left*psi;
end
% psi = max(psi(1:n,1:n), 0);
end