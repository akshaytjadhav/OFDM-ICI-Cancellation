function BER = run_standard_ofdm(M, ep, EbNo, NS, carriers, ifftsize)
% RUN_STANDARD_OFDM  BER simulation of a standard OFDM system with QAM.
%
%   BER = run_standard_ofdm(M, ep, EbNo, NS, carriers, ifftsize)
%
%   Inputs:
%     M         - QAM modulation order (2, 4, 16, 64)
%     ep        - Vector of normalised frequency offsets (e.g. [0 0.15 0.3])
%     EbNo      - Vector of Eb/No values in dB
%     NS        - Number of OFDM symbols per trial
%     carriers  - Subcarrier index vector (e.g. (1:52)+2 for 52 carriers)
%     ifftsize  - IFFT/FFT size (e.g. 64)
%
%   Output:
%     BER       - Matrix of size [length(ep) x length(EbNo)]
%
%   Description:
%     Simulates a baseband OFDM link over an AWGN channel with a carrier
%     frequency offset (CFO) modelled as a phase ramp on the time-domain
%     signal.  No ICI cancellation is applied.
%
%   Changes from original (2012) code:
%     - Replaced legacy modem.qammod / modem.qamdemod objects with
%       qammod() / qamdemod() (available from R2014b onwards).
%     - Serial-to-parallel and BER calculation now scale correctly for
%       all values of M (not just M=2).
%     - EbNo sweep is now fully vectorised across all SNR points.
%     - Noise power derived from Eb/No correctly using log2(M) bits/symbol.

    bitsPerSym  = log2(M);          % bits per QAM symbol
    numCarriers = length(carriers); % 52
    totalBits   = numCarriers * NS * bitsPerSym;

    % ---- Generate random bit stream ----
    input_bit_stream = randi([0 1], 1, totalBits);

    % ---- Serial-to-Parallel: group into bitsPerSym-wide words ----
    % Each row = one QAM symbol's worth of bits, reshaped to integer indices
    parallel_bits = reshape(input_bit_stream, bitsPerSym, []).';
    % Convert bit rows to decimal symbol indices
    symbol_indices = bi2de(parallel_bits, 'left-msb');   % column vector

    % ---- QAM Modulation ----
    modulated_data = qammod(symbol_indices, M, 'UnitAveragePower', true);

    % ---- Pre-allocate BER output ----
    BER = zeros(length(ep), length(EbNo));

    % ---- Main simulation loops ----
    for ll = 1:length(ep)
        for l = 1:length(EbNo)

            % Noise variance: sigma^2 = 1 / (2 * bitsPerSym * 10^(EbNo/10))
            % Factor of 2 because noise has real + imag components
            noiseVar = 1 / (2 * bitsPerSym * 10^(EbNo(l)/10));

            received_symbols = zeros(1, numCarriers * NS);
            k = 1;

            for n = 1:NS
                % ---- Build OFDM symbol ----
                ofdm_symbol = zeros(1, ifftsize);
                ofdm_symbol(carriers) = modulated_data(k : k + numCarriers - 1);

                % ---- IFFT: frequency -> time domain ----
                tx_signal = ifft(ofdm_symbol, ifftsize);

                % ---- Apply normalised frequency offset (Doppler / CFO) ----
                % y(n) = x(n) * exp(j*2*pi*ep*n / N)
                n_idx     = 0 : ifftsize - 1;
                rx_signal = tx_signal .* exp(1j * 2 * pi * ep(ll) * n_idx / ifftsize);

                % ---- Add AWGN ----
                noise     = sqrt(noiseVar) * (randn(1, ifftsize) + 1j * randn(1, ifftsize));
                rx_signal = rx_signal + noise;

                % ---- FFT: time -> frequency domain ----
                received_ofdm = fft(rx_signal, ifftsize);

                % ---- Extract data subcarriers ----
                received_symbols(k : k + numCarriers - 1) = received_ofdm(carriers);
                k = k + numCarriers;
            end

            % ---- QAM Demodulation ----
            received_indices = qamdemod(received_symbols.', M, 'UnitAveragePower', true);

            % ---- Convert symbol indices back to bits ----
            received_bits_matrix = de2bi(received_indices, bitsPerSym, 'left-msb');
            output_bit_stream    = reshape(received_bits_matrix.', 1, []);

            % ---- BER calculation ----
            BER(ll, l) = sum(xor(input_bit_stream, output_bit_stream)) / totalBits;
        end

        fprintf('  ep=%.2f done\n', ep(ll));
    end
end
