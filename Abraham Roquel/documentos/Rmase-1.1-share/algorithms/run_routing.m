function run_routing(varargin)

global TIME
dir = varargin{1};
datfile = varargin{2};
Max_Sim_Time = varargin{3};
Number_of_Runs = varargin{4};
Time_Interval = varargin{5};

[delays, throughput, lossrate, succrate, energy, energy_var, sent] = routing_test(Max_Sim_Time, Number_of_Runs, Time_Interval);
X=[TIME;delays;throughput;lossrate;succrate;energy;energy_var;sent];
filename = [dir, datfile];
fid = fopen(filename, 'w');
fprintf(fid, '%f %f %f %f %f %d %f %d\n', X);
fclose(fid);
