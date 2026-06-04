% =========================================================================
% run_all.m
% Master script for OFDM ICI Self-Cancellation BER Simulation
%
% Project : ICI Reduction in OFDM using Self-Cancellation Scheme
% Updated : Fixed for modern MATLAB (R2014b+), no legacy Communications
%           Toolbox objects (modem.qammod etc.)
%
% Runs:
%   1. Standard OFDM BER for QAM-2, 4, 16, 64
%   2. ICI Self-Cancellation BER for QAM-2, 4, 16, 64
%   3. Comparison plots
%   4. ICI coefficient and CIR theory plots (sici.m)
% =========================================================================

clc;
clear all;
close all;

%% ---- Shared Simulation Parameters -----
ep    = [0, 0.15, 0.3];     % Normalized frequency offsets
EbNo  = 1:30;               % Eb/No range in dB
NS    = 100;                 % OFDM symbols per simulation run
N     = 52;                  % Number of data subcarriers
ifftsize = 64;               % IFFT/FFT size
carriers = (1:52) + 2;       % Subcarrier indices (skip DC and guard)

%% ---- Standard OFDM: QAM-2 ----
fprintf('Running Standard OFDM - QAM-2...\n');
M = 2;
BERqam2 = run_standard_ofdm(M, ep, EbNo, NS, carriers, ifftsize);
save('results/BERqam2.mat', 'BERqam2');

%% ---- Standard OFDM: QAM-4 ----
fprintf('Running Standard OFDM - QAM-4...\n');
M = 4;
BERqam4 = run_standard_ofdm(M, ep, EbNo, NS, carriers, ifftsize);
save('results/BERqam4.mat', 'BERqam4');

%% ---- Standard OFDM: QAM-16 ----
fprintf('Running Standard OFDM - QAM-16...\n');
M = 16;
BERqam16 = run_standard_ofdm(M, ep, EbNo, NS, carriers, ifftsize);
save('results/BERqam16.mat', 'BERqam16');

%% ---- Standard OFDM: QAM-64 ----
fprintf('Running Standard OFDM - QAM-64...\n');
M = 64;
BERqam64 = run_standard_ofdm(M, ep, EbNo, NS, carriers, ifftsize);
save('results/BERqam64.mat', 'BERqam64');

%% ---- ICI Self-Cancellation: QAM-2 ----
fprintf('Running ICI Self-Cancellation - QAM-2...\n');
M = 2;
BERqam2sc = run_ici_sc_ofdm(M, ep, EbNo, NS, carriers, ifftsize);
save('results/BERqam2sc.mat', 'BERqam2sc');

%% ---- ICI Self-Cancellation: QAM-4 ----
fprintf('Running ICI Self-Cancellation - QAM-4...\n');
M = 4;
BERqam4sc = run_ici_sc_ofdm(M, ep, EbNo, NS, carriers, ifftsize);
save('results/BERqam4sc.mat', 'BERqam4sc');

%% ---- ICI Self-Cancellation: QAM-16 ----
fprintf('Running ICI Self-Cancellation - QAM-16...\n');
M = 16;
BERqam16sc = run_ici_sc_ofdm(M, ep, EbNo, NS, carriers, ifftsize);
save('results/BERqam16sc.mat', 'BERqam16sc');

%% ---- ICI Self-Cancellation: QAM-64 ----
fprintf('Running ICI Self-Cancellation - QAM-64...\n');
M = 64;
BERqam64sc = run_ici_sc_ofdm(M, ep, EbNo, NS, carriers, ifftsize);
save('results/BERqam64sc.mat', 'BERqam64sc');

%% =========================================================================
%  FIGURE 1: Standard OFDM BER for all QAM orders
% =========================================================================
figure('Name', 'Standard OFDM BER');
legend_str = {'\epsilon=0', '\epsilon=0.15', '\epsilon=0.3'};

subplot(2,2,1)
semilogy(EbNo, BERqam2(1,:), '-o', EbNo, BERqam2(2,:), '.-', EbNo, BERqam2(3,:), '*-');
title('QAM-2 (BPSK) - Standard OFDM'); xlabel('E_b/N_o (dB)'); ylabel('BER');
legend(legend_str); grid on; ylim([1e-4 1]);

subplot(2,2,2)
semilogy(EbNo, BERqam4(1,:), '-o', EbNo, BERqam4(2,:), '.-', EbNo, BERqam4(3,:), '*-');
title('QAM-4 (QPSK) - Standard OFDM'); xlabel('E_b/N_o (dB)'); ylabel('BER');
legend(legend_str); grid on; ylim([1e-4 1]);

subplot(2,2,3)
semilogy(EbNo, BERqam16(1,:), '-o', EbNo, BERqam16(2,:), '.-', EbNo, BERqam16(3,:), '*-');
title('QAM-16 - Standard OFDM'); xlabel('E_b/N_o (dB)'); ylabel('BER');
legend(legend_str); grid on; ylim([1e-4 1]);

subplot(2,2,4)
semilogy(EbNo, BERqam64(1,:), '-o', EbNo, BERqam64(2,:), '.-', EbNo, BERqam64(3,:), '*-');
title('QAM-64 - Standard OFDM'); xlabel('E_b/N_o (dB)'); ylabel('BER');
legend(legend_str); grid on; ylim([1e-4 1]);

%% =========================================================================
%  FIGURE 2: ICI Self-Cancellation BER for all QAM orders
% =========================================================================
figure('Name', 'ICI Self-Cancellation BER');

subplot(2,2,1)
semilogy(EbNo, BERqam2sc(1,:), '-o', EbNo, BERqam2sc(2,:), '.-', EbNo, BERqam2sc(3,:), '*-');
title('QAM-2 - ICI Self-Cancellation'); xlabel('E_b/N_o (dB)'); ylabel('BER');
legend(legend_str); grid on; ylim([1e-4 1]);

subplot(2,2,2)
semilogy(EbNo, BERqam4sc(1,:), '-o', EbNo, BERqam4sc(2,:), '.-', EbNo, BERqam4sc(3,:), '*-');
title('QAM-4 - ICI Self-Cancellation'); xlabel('E_b/N_o (dB)'); ylabel('BER');
legend(legend_str); grid on; ylim([1e-4 1]);

subplot(2,2,3)
semilogy(EbNo, BERqam16sc(1,:), '-o', EbNo, BERqam16sc(2,:), '.-', EbNo, BERqam16sc(3,:), '*-');
title('QAM-16 - ICI Self-Cancellation'); xlabel('E_b/N_o (dB)'); ylabel('BER');
legend(legend_str); grid on; ylim([1e-4 1]);

subplot(2,2,4)
semilogy(EbNo, BERqam64sc(1,:), '-o', EbNo, BERqam64sc(2,:), '.-', EbNo, BERqam64sc(3,:), '*-');
title('QAM-64 - ICI Self-Cancellation'); xlabel('E_b/N_o (dB)'); ylabel('BER');
legend(legend_str); grid on; ylim([1e-4 1]);

%% =========================================================================
%  FIGURE 3: Standard vs ICI-SC comparison for QAM-2
% =========================================================================
figure('Name', 'Standard OFDM vs ICI Self-Cancellation - QAM-2');

subplot(2,2,1)
semilogy(EbNo, BERqam2(1,:), '-o', EbNo, BERqam2(2,:), '.-', EbNo, BERqam2(3,:), '*-');
title('QAM-2 Standard OFDM'); xlabel('E_b/N_o (dB)'); ylabel('BER');
legend(legend_str); grid on; ylim([1e-4 1]);

subplot(2,2,2)
semilogy(EbNo, BERqam2sc(1,:), '-o', EbNo, BERqam2sc(2,:), '.-', EbNo, BERqam2sc(3,:), '*-');
title('QAM-2 ICI Self-Cancellation'); xlabel('E_b/N_o (dB)'); ylabel('BER');
legend(legend_str); grid on; ylim([1e-4 1]);

subplot(2,2,3)
semilogy(EbNo, BERqam2(2,:), 'b-o', EbNo, BERqam2sc(2,:), 'r*-');
title('QAM-2  \epsilon = 0.15: Standard vs SC'); xlabel('E_b/N_o (dB)'); ylabel('BER');
legend('Standard OFDM', 'ICI Self-Cancellation'); grid on; ylim([1e-4 1]);

subplot(2,2,4)
semilogy(EbNo, BERqam2(3,:), 'b-o', EbNo, BERqam2sc(3,:), 'r*-');
title('QAM-2  \epsilon = 0.3: Standard vs SC'); xlabel('E_b/N_o (dB)'); ylabel('BER');
legend('Standard OFDM', 'ICI Self-Cancellation'); grid on; ylim([1e-4 1]);

%% ---- Run ICI Coefficient and CIR Theory Plots ----
fprintf('Generating ICI theory plots...\n');
run('sici.m');

fprintf('\nAll simulations complete. Results saved in results/ folder.\n');
