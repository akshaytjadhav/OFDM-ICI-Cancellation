function BER = run_mle_ofdm(M, ep, EbNo, NS, carriers, ifftsize)
% RUN_MLE_OFDM  BER simulation of OFDM with Maximum Likelihood Estimation
%               (MLE) frequency offset correction (Moose, 1994).
%
%   BER = run_mle_ofdm(M, ep, EbNo, NS, carriers, ifftsize)
%
%   MLE Method (Moose, 1994):
%     - Each OFDM symbol is transmitted twice (symbol repetition).
%     - The phase difference between the two received copies gives an
%       estimate of the frequency offset.
%     - Estimate:  ep_hat = (1/(2*pi)) * atan( Im(sum) / Re(sum) )
%                  where sum = sum_k { R2(k) * conj(R1(k)) }
%     - The received signal is then corrected using the estimate.
%
%   Inputs / Outputs same as run_standard_ofdm.m.
%
%   Note: Bandwidth efficiency is halved (repetition overhead).

    bitsPerSym  = log2(M);
    numCarriers = length(carriers);   % 52
    halfFFT     = ifftsize / 2;       % 32

    % Use only half the carriers for MLE (matches original design)
    active_carriers = carriers(1 : halfFFT);  % first 32 of 52
    numActive       = length(active_carriers);

    totalBits = numActive * NS * bitsPerSym;

    % ---- Generate bit stream ----
    input_bit_stream = randi([0 1], 1, totalBits);
    parallel_bits    = reshape(input_bit_stream, bitsPerSym, []).';
    symbol_indices   = bi2de(parallel_bits, 'left-msb');
    modulated_data   = qammod(symbol_indices, M, 'UnitAveragePower', true);

    BER       = zeros(length(ep), length(EbNo));
    epestMLE  = zeros(length(ep), length(EbNo));

    for ll = 1:length(ep)
        for l = 1:length(EbNo)

            noiseVar = 1 / (2 * bitsPerSym * 10^(EbNo(l)/10));

            received_symbols = zeros(1, numActive * NS);
            k = 1;

            for n = 1:NS
                % ---- Build symbol using N/2-point IFFT, then replicate ----
                ofdm_half          = zeros(1, halfFFT);
                ofdm_half(active_carriers(active_carriers <= halfFFT)) = ...
                    modulated_data(k : k + numActive - 1);

                tx_half   = ifft(ofdm_half, halfFFT);
                tx_signal = [tx_half, tx_half];      % N-point by repetition

                % ---- Frequency offset ----
                n_idx     = 0 : ifftsize - 1;
                rx_signal = tx_signal .* exp(1j * 2*pi * ep(ll) * n_idx / ifftsize);

                % ---- AWGN ----
                noise      = sqrt(noiseVar) * (randn(1, ifftsize) + 1j * randn(1, ifftsize));
                rx_noisy   = rx_signal + noise;

                % ---- MLE frequency offset estimation ----
                R1 = fft(rx_noisy(1        : halfFFT), halfFFT);
                R2 = fft(rx_noisy(halfFFT+1 : ifftsize), halfFFT);

                cross = sum(R2 .* conj(R1));
                ep_hat = atan2(imag(cross), real(cross)) / (2*pi);
                if ep_hat < 0
                    ep_hat = ep_hat + 0.5;
                end
                epestMLE(ll, l) = ep_hat;

                % ---- Correct frequency offset then demodulate ----
                rx_corrected = rx_noisy .* exp(-1j * 2*pi * ep_hat * n_idx / ifftsize);
                received_ofdm = fft(rx_corrected(1:halfFFT), halfFFT);

                received_symbols(k : k + numActive - 1) = received_ofdm(1:numActive);
                k = k + numActive;
            end

            % ---- Demodulate ----
            received_indices  = qamdemod(received_symbols.', M, 'UnitAveragePower', true);
            received_bits_mat = de2bi(received_indices, bitsPerSym, 'left-msb');
            output_bit_stream = reshape(received_bits_mat.', 1, []);

            BER(ll, l) = sum(xor(input_bit_stream, output_bit_stream)) / totalBits;
        end

        fprintf('  MLE ep=%.2f done  (estimated: %.3f)\n', ep(ll), mean(epestMLE(ll,:)));
    end
end
