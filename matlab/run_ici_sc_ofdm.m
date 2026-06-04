function BER = run_ici_sc_ofdm(M, ep, EbNo, NS, carriers, ifftsize)
% RUN_ICI_SC_OFDM  BER simulation of OFDM with ICI Self-Cancellation (SC).
%
%   BER = run_ici_sc_ofdm(M, ep, EbNo, NS, carriers, ifftsize)
%
%   Inputs:
%     M         - QAM modulation order (2, 4, 16, 64)
%     ep        - Vector of normalised frequency offsets (e.g. [0 0.15 0.3])
%     EbNo      - Vector of Eb/No values in dB
%     NS        - Number of OFDM symbols per trial
%     carriers  - Subcarrier index vector (must have even length, e.g. 52)
%     ifftsize  - IFFT/FFT size (e.g. 64)
%
%   Output:
%     BER       - Matrix of size [length(ep) x length(EbNo)]
%
%   ICI Self-Cancellation Scheme (Zhao & Haggman, 2001):
%     Modulation:  Each data symbol d mapped onto adjacent carrier pair
%                  (k, k+1) with weights (+1, -1):
%                    X(k)   =  d
%                    X(k+1) = -d
%     Demodulation: Combine received signals Y(k) and Y(k+1):
%                    d_hat = 0.5 * (Y(k) - Y(k+1))
%     This causes ICI contributions from adjacent subcarriers to cancel,
%     improving CIR at the cost of 50% bandwidth efficiency.
%
%   Changes from original (2012) code:
%     - Replaced legacy modem.qammod / modem.qamdemod with qammod/qamdemod.
%     - Serial-to-parallel and BER calculation scale correctly for all M.
%     - Noise added manually (consistent with run_standard_ofdm.m).
%     - Odd/even carrier split made explicit and self-documenting.

    bitsPerSym  = log2(M);
    numCarriers = length(carriers);   % 52 total; 26 used for unique data
    numDataCarriers = numCarriers / 2; % each symbol uses 2 subcarriers

    totalBits = numDataCarriers * NS * bitsPerSym;

    % ---- Odd/even carrier split for SC scheme ----
    odd_carriers  = carriers(1:2:end);   % 26 carriers: data subcarriers
    even_carriers = carriers(2:2:end);   % 26 carriers: negated copies

    % ---- Generate random bit stream ----
    input_bit_stream = randi([0 1], 1, totalBits);

    % ---- Serial-to-Parallel -> QAM modulation ----
    parallel_bits  = reshape(input_bit_stream, bitsPerSym, []).';
    symbol_indices = bi2de(parallel_bits, 'left-msb');
    modulated_data = qammod(symbol_indices, M, 'UnitAveragePower', true);

    % ---- Pre-allocate output ----
    BER = zeros(length(ep), length(EbNo));

    % ---- Main simulation loops ----
    for ll = 1:length(ep)
        for l = 1:length(EbNo)

            noiseVar = 1 / (2 * bitsPerSym * 10^(EbNo(l)/10));

            received_symbols = zeros(1, numDataCarriers * NS);
            k = 1;

            for n = 1:NS
                % ---- ICI Self-Cancellation Modulation ----
                ofdm_symbol = zeros(1, ifftsize);
                data_chunk  = modulated_data(k : k + numDataCarriers - 1);

                ofdm_symbol(odd_carriers)  =  data_chunk;   % X(k)   =  d
                ofdm_symbol(even_carriers) = -data_chunk;   % X(k+1) = -d

                % ---- IFFT ----
                tx_signal = ifft(ofdm_symbol, ifftsize);

                % ---- Frequency offset ----
                n_idx     = 0 : ifftsize - 1;
                rx_signal = tx_signal .* exp(1j * 2 * pi * ep(ll) * n_idx / ifftsize);

                % ---- AWGN ----
                noise     = sqrt(noiseVar) * (randn(1, ifftsize) + 1j * randn(1, ifftsize));
                rx_signal = rx_signal + noise;

                % ---- FFT ----
                received_ofdm = fft(rx_signal, ifftsize);

                % ---- ICI Self-Cancellation Demodulation ----
                % Combine adjacent carrier pair: d_hat = 0.5*(Y(k) - Y(k+1))
                demod_syms = 0.5 * (received_ofdm(odd_carriers) - received_ofdm(even_carriers));

                received_symbols(k : k + numDataCarriers - 1) = demod_syms;
                k = k + numDataCarriers;
            end

            % ---- QAM Demodulation ----
            received_indices  = qamdemod(received_symbols.', M, 'UnitAveragePower', true);
            received_bits_mat = de2bi(received_indices, bitsPerSym, 'left-msb');
            output_bit_stream = reshape(received_bits_mat.', 1, []);

            % ---- BER ----
            BER(ll, l) = sum(xor(input_bit_stream, output_bit_stream)) / totalBits;
        end

        fprintf('  ep=%.2f done\n', ep(ll));
    end
end
