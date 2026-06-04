% complex_ICI_coefficient.m
% =========================================================================
% Plot of Complex ICI Coefficient |S(l-k)| for Three Frequency Offsets
%
% Demonstrates how the ICI coefficient magnitude changes with frequency
% offset epsilon for a 16-subcarrier OFDM system.
%
% Formula:
%   S(l-k) = sin(pi*(ep - n)) / (N * sin(pi/N * (ep - n)))
%            * exp(j * pi * (1 - 1/N) * (ep - n))
%   where n = l - k is the subcarrier index offset from l=0.
% =========================================================================

close all; clear; clc;

N   = 16;
n   = (0 : N-1);

ep1 = 0.2;
ep2 = 0.4;
ep3 = 0.05;

S1 = ici_coeff(n, ep1, N);
S2 = ici_coeff(n, ep2, N);
S3 = ici_coeff(n, ep3, N);

figure('Name', 'Complex ICI Coefficient |S(l-k)|');
plot(n, abs(S1), 'g:*',  'DisplayName', '\epsilon = 0.2'); hold on;
plot(n, abs(S2), '--rs', 'DisplayName', '\epsilon = 0.4');
plot(n, abs(S3), ':b',   'DisplayName', '\epsilon = 0.05');
hold off;

title('Complex ICI Coefficient |S(l-k)| for N=16');
xlabel('Subcarrier index k');
ylabel('|S(l-k)|');
legend show;
axis([0 N-1 -0.1 1.1]);
grid on;

%% Helper
function S = ici_coeff(k_offset, ep, N)
    arg = ep - k_offset;
    S   = zeros(size(arg));
    nz  = (arg ~= 0);
    S(nz) = sin(pi * arg(nz)) ...
            ./ (N * sin(pi/N * arg(nz))) ...
            .* exp(1j * pi * (1 - 1/N) * arg(nz));
    S(~nz) = 1;
end
