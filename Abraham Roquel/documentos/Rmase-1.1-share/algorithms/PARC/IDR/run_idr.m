function run_routing(varargin)
dir = varargin{1};
datfile = varargin{2};
Number_of_Runs = varargin{3};
Number_of_Packets = varargin{4};

[hops, mses, sizes] = run_idr_test(Number_of_Runs, Number_of_Packets);
X=[hops;mses;sizes];
filename = [dir, datfile];
fid = fopen(filename, 'w');
fprintf(fid, '%d %f %f\n', X);
fclose(fid);
