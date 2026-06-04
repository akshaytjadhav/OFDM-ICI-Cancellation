% sici.m
% =========================================================================
% Theoretical ICI Coefficient and CIR Analysis for OFDM
%
% Plots:
%   1. Complex ICI coefficient |S(l-k)|, Re{S(l-k)}, Im{S(l-k)} for N=16
%   2. Comparison of |S(l-k)|, |S'(l-k)|, |S''(l-k)| for N=64, ep=0.2
%   3. CIR vs normalised frequency offset ep for standard OFDM and ICI-SC
%
% Theory reference:
%   Zhao & Haggman, "Intercarrier Interference Self-Cancellation Scheme
%   for OFDM Mobile Communication Systems", IEEE Trans. Commun., 2001.
%
%   ICI coefficient:
%     S(l-k) = sin(pi*(l+ep-k)) / (N*sin(pi/N*(l+ep-k)))
%              * exp(j*pi*(1-1/N)*(l+ep-k))
%
%   After ICI cancelling modulation:
%     S'(l-k) = S(l-k) - S(l+1-k)
%
%   After ICI cancelling demodulation:
%     S''(l-k) = -S(l-k-1) + 2*S(l-k) - S(l-k+1)
% =========================================================================

%% =========================================================================
%  FIGURE 1: ICI coefficients for N=16, two frequency offsets
% =========================================================================
figure('Name', 'ICI Coefficients N=16');

ep1 = 0.2;
ep2 = 0.4;
N   = 16;
n   = (0 : N-1);

S1 = ici_coeff(n, ep1, N);
S2 = ici_coeff(n, ep2, N);

subplot(2,2,1)
plot(n, abs(S1), '*-', n, abs(S2), 'o-');
xlabel('Subcarrier index k'); ylabel('|S(l-k)|');
title('Amplitude |S(l-k)| for N=16');
legend('\epsilon=0.2', '\epsilon=0.4'); grid on;
axis([0 N-1 0 1.1*max([abs(S1), abs(S2)])]);

subplot(2,2,2)
plot(n, real(S1), '*-', n, real(S2), 'o-');
xlabel('Subcarrier index k'); ylabel('Re\{S(l-k)\}');
title('Real part of S(l-k) for N=16');
legend('\epsilon=0.2', '\epsilon=0.4'); grid on;

subplot(2,2,3)
plot(n, imag(S1), '*-', n, imag(S2), 'o-');
xlabel('Subcarrier index k'); ylabel('Im\{S(l-k)\}');
title('Imaginary part of S(l-k) for N=16');
legend('\epsilon=0.2', '\epsilon=0.4'); grid on;

%% =========================================================================
%  FIGURE 2: Comparison of |S|, |S'|, |S''| for N=64, ep=0.2
% =========================================================================
figure('Name', 'ICI Coefficient Comparison N=64');

N  = 64;
n  = (0 : N-1);
ep = 0.2;

S   = ici_coeff(n,    ep,   N);
Sp1 = ici_coeff(n, ep+1, N);
Sp2 = ici_coeff(n, ep-1, N);

S_prime  = S - Sp1;                  % S'(l-k) = S(l-k) - S(l+1-k)
S_dprime = -Sp2 - Sp1 + 2*S;        % S''(l-k) = -S(l-k-1)+2S(l-k)-S(l-k+1)

plot(n, 10*log10(abs(S) + eps),       '-.', 'DisplayName', '|S(l-k)|');
hold on;
plot(n, 10*log10(abs(S_prime) + eps), '--', 'DisplayName', '|S''(l-k)|');
plot(n, 10*log10(abs(S_dprime)+ eps),       'DisplayName', '|S''''(l-k)|');
hold off;
axis([0 N-1 -70 0]);
xlabel('Subcarrier index k'); ylabel('Magnitude (dB)');
title('Comparison of |S(l-k)|, |S''(l-k)|, |S''''(l-k)| for \epsilon=0.2, N=64');
legend show; grid on;

%% =========================================================================
%  FIGURE 3: CIR vs normalised frequency offset
% =========================================================================
figure('Name', 'CIR vs Frequency Offset');

ep_vec = linspace(0, 0.5, 100);
N      = 64;
n      = (0 : N-1);
CIR    = zeros(1, 100);
CIR_SC = zeros(1, 100);

for i = 1:100
    S = ici_coeff(n, ep_vec(i), N);

    % Standard OFDM CIR: |S(0)|^2 / sum_k!=0(|S(k)|^2)
    CIR(i) = abs(S(1))^2 / sum(abs(S(2:N)).^2);

    % ICI Self-Cancellation CIR (Eq. 11 in project report)
    S_0 = ici_coeff(0,  ep_vec(i), N);
    S_m = ici_coeff(-1, ep_vec(i), N);
    S_p = ici_coeff(1,  ep_vec(i), N);

    numerator = abs(-S_m + 2*S_0 - S_p)^2;

    denom = 0;
    for ll = 2:2:(N-1)
        Sm1 = ici_coeff(ll-1, ep_vec(i), N);
        Sl  = ici_coeff(ll,   ep_vec(i), N);
        Sp1 = ici_coeff(ll+1, ep_vec(i), N);
        denom = denom + abs(-Sm1 + 2*Sl - Sp1)^2;
    end

    CIR_SC(i) = numerator / (denom + eps);
end

plot(ep_vec, 10*log10(CIR + eps),    '--', 'DisplayName', 'Standard OFDM');
hold on;
plot(ep_vec, 10*log10(CIR_SC + eps),       'DisplayName', 'ICI Self-Cancellation');
hold off;
xlabel('Normalised Frequency Offset \epsilon');
ylabel('CIR (dB)');
title('CIR versus \epsilon: Standard OFDM vs ICI Self-Cancellation (N=64)');
legend show; grid on;

%% =========================================================================
%  Helper function
% =========================================================================
function S = ici_coeff(k_offset, ep, N)
% ICI_COEFF  Compute ICI coefficient S(ep - k) for given subcarrier offset.
%
%   S = ici_coeff(k_offset, ep, N)
%
%   Formula:
%     S(l-k) = sin(pi*(ep - k)) / (N * sin(pi/N * (ep - k)))
%              * exp(j*pi*(1 - 1/N)*(ep - k))
%
%   k_offset can be a scalar or vector of integer offsets.

    arg = ep - k_offset;
    % Avoid divide-by-zero when arg is exactly 0 (desired subcarrier)
    % sinc-like limit: S -> 1 as arg -> 0
    S = zeros(size(arg));
    nonzero = (arg ~= 0);

    S(nonzero) = sin(pi * arg(nonzero)) ...
                 ./ (N * sin(pi/N * arg(nonzero))) ...
                 .* exp(1j * pi * (1 - 1/N) * arg(nonzero));

    % At arg == 0, the ratio sin(pi*x)/(N*sin(pi*x/N)) -> 1 as x->0
    S(~nonzero) = 1;
end
