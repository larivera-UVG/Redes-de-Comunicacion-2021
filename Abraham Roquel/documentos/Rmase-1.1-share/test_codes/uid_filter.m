ts = 1e-3; %suponiendo tiempo de muestreo de 1ms (a cada ms tenemos nueva muestra)
sigma = 0.01; %50 muestras representativas (5/sigma)
             %sistema estable para 0 < sigma < 2 
z = zpk('z', ts);

sigma = linspace(0.05, 1.5, 5);

h1 = sigma(1)*z / (z + sigma(1) - 1);
h2 = sigma(2)*z / (z + sigma(2) - 1);
h3 = sigma(3)*z / (z + sigma(3) - 1);
h4 = sigma(4)*z / (z + sigma(4) - 1);
h5 = sigma(5)*z / (z + sigma(5) - 1);


% f1 = figure;
% 
% [y1,tOut1] = step(h1, 0.02);
% [y2,tOut2] = step(h2, 0.02);
% [y3,tOut3] = step(h3, 0.02);
% [y4,tOut4] = step(h4, 0.02);
% [y5,tOut5] = step(h5, 0.02);
% 
% plot(tOut1, y1);
% hold on
% plot(tOut2, y2);
% plot(tOut3, y3);
% plot(tOut4, y4);
% plot(tOut5, y5);
% xlim([0, 0.02]);
% ylim([0, 1.2]);
% xlabel("tiempo (s)");
% ylabel("Amplitud");
%legend(["\varsigma = 0.05","\varsigma = 0.4125","\varsigma = 0.7750","\varsigma = 1.1375","\varsigma = 1.5"]);
%figure;

bode(h1); %filtro pasa bajas
hold on
bode(h2);
bode(h3);
bode(h4);
bode(h5);

legend(["\varsigma = 0.05","\varsigma = 0.4125","\varsigma = 0.7750","\varsigma = 1.1375","\varsigma = 1.5"], 'location','northwest');
%figure;
