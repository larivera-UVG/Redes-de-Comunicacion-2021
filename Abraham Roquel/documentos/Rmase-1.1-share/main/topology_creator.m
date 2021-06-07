function [topology,mote_IDs]=topology(varargin);
% Topology Creation

%* Copyright (C) 2003 PARC Inc.  All Rights Reserved.
%*
%* Use, reproduction, preparation of derivative works, and distribution 
%* of this software is permitted, but only for non-commercial research 
%* or educational purposes. Any copy of this software or of any derivative 
%* work must include both the above copyright notice of PARC Incorporated 
%* and this paragraph. Any distribution of this software or derivative 
%* works must comply with all applicable United States export control laws. 
%* This software is made available AS IS, and PARC INCORPORATED DISCLAIMS 
%* ALL WARRANTIES, EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION THE 
%* IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR 
%* PURPOSE, AND NOTWITHSTANDING ANY OTHER PROVISION CONTAINED HEREIN, ANY 
%* LIABILITY FOR DAMAGES RESULTING FROM THE SOFTWARE OR ITS USE IS EXPRESSLY 
%* DISCLAIMED, WHETHER ARISING IN CONTRACT, TORT (INCLUDING NEGLIGENCE) 
%* OR STRICT LIABILITY, EVEN IF PARC INCORPORATED IS ADVISED OF THE 
%* POSSIBILITY OF SUCH DAMAGES. This notice applies to all files in this 
%* release (sources, executables, libraries, demos, and documentation).
%*/

% Modified by Ying Zhang, yzhang@parc.com
% Last modified: Nov. 3, 2002

% Modified by Lukas D. Kuhn, lukas.kuhn@parc.com
% Last modified: Nov. 13, 2003


% number of points on the grid
Nx=sim_params('get_app', 'Xsize'); 
Ny=sim_params('get_app', 'Ysize');
if isempty(Nx); Nx=7; end
if isempty(Ny); Ny=7; end

% distance between points in the grid 
Dix=sim_params('get_app', 'Xdist'); 
Diy=sim_params('get_app', 'Ydist'); 
if isempty(Dix); Dix=1; end
if isempty(Diy); Diy=1; end

% alive probability of a node
AliveP=sim_params('get_app', 'AliveProb');
if isempty(AliveP); AliveP=1; end

% maximum random offset for nodes to be placed away from specified node
% position 
Ox=sim_params('get_app', 'Xoffset');
Oy=sim_params('get_app', 'Yoffset');
if isempty(Ox); Ox=0; end
if isempty(Oy); Oy=0; end

% number of nodes per side from grid point to grid point
Dex=sim_params('get_app', 'Xdensity'); 
Dey=sim_params('get_app', 'Ydensity'); 
if isempty(Dex); Dex=1; end
if isempty(Dey); Dey=1; end

% Shift of the grid points from one row/column to the next as a percentage
% of the grid spacing.
Sx=sim_params('get_app', 'Xshift');
Sy=sim_params('get_app', 'Yshift');
Swrap=sim_params('get_app', 'wraparound');
if isempty(Sx);     Sx=0; end
if isempty(Sy);     Sy=0; end
if isempty(Swrap);  Swrap=0; end
if((length(Sx)~=1) & (length(Sx)<(Nx+((Nx)*(Dex-1)))))
    prowler('PrintEvent', '"Xshift" has less entrys then the grid columns!');
end
if((length(Sy)~=1) & (length(Sy)<(Ny+((Ny)*(Dey-1)))))
    prowler('PrintEvent', '"Yshift" has less entrys then the grid columns!');
end


% hole
% position of rectangle center
% length, heigth and angle of the rectangle
hpx=sim_params('get_app', 'HPosX'); 
hpy=sim_params('get_app', 'HPosY'); 
hlx=sim_params('get_app', 'HLengthX'); 
hhy=sim_params('get_app', 'HHeigthY');
ha=sim_params('get_app', 'HAngle');
if isempty(hpx);    hpx=0;  end
if isempty(hpy);    hpy=0;  end
if isempty(hlx);    hlx=0;  end
if isempty(hhy);    hhy=0;  end
if isempty(ha);     ha=0;   end

rhb=sim_params('get_app', 'HBorder');
if isempty(rhb);    rhb=0;  end

% RandHoles
% Number of the random rectangles
% length, heigth and the randomized part of length, heigth
rhn=sim_params('get_app', 'RHNumber');
rhl=sim_params('get_app', 'RHLengthX'); 
rhlr=sim_params('get_app', 'RHLengthXRand'); 
rhh=sim_params('get_app', 'RHHeigthY');
rhhr=sim_params('get_app', 'RHHeigthYRand');
if isempty(rhn);    rhn=0;  end
if isempty(rhl);    rhl=0;  end
if isempty(rhlr);   rhlr=0; end
if isempty(rhh);    rhh=0;  end
if isempty(rhhr);   rhhr=0; end

global RECTANGLES;
allHoles=[];
allHoles = rectangles_disjoint(rhn,rhl,rhlr,rhh,rhhr,Nx,Ny,Dix,Diy,Sx,Sy);
allHoles=[allHoles; hpx , hpy , hlx , hhy ,  ha];

[A,B,C,D] = get_vertex([hpx , hpy , hlx , hhy ,  ha]);
RECTANGLES = [RECTANGLES;[A,B,C,D]];



% start with the calculation of the nodes 
N=0;
for i=1:(Nx+((Nx)*(Dex-1)))
    for j=1:(Ny+((Ny)*(Dey-1)))
        if (rand<=AliveP)
            if((mod(i,(Dex)) == 1) | (Dex == 1 )) | ((mod(j,(Dey)) == 1) | (Dey == 1 ))
                N = N+1;
                alive(i,j)=1;
            end
        end
    end
end
Dx = Dix/(Dex);
Dy = Diy/(Dey);
t=[];
for i=1:(Nx+((Nx)*(Dex-1)))
    for j=1:(Ny+((Ny)*(Dey-1)))
        if (alive(i,j))
            if((mod(i,(Dex)) == 1) | (Dex == 1 )) | ((mod(j,(Dey)) == 1) | (Dey == 1 ))
                if(size(Sx)<i)
                    xs = (j-1)*Sx(1);
                else
                    xs = (j-1)*Sx(i);
                end
                if(size(Sy)<j)
                    ys = (i-1)*Sy(1);
                else
                    ys = (i-1)*Sy(j);
                end
                x = (i-1)*Dx + 2*Ox*(rand-0.5)*Dx + xs*Dx;
                y = (j-1)*Dy + 2*Oy*(rand-0.5)*Dy + ys*Dy;
                addNode = 1;
                borderNode = 0;
                for h=1:(size(allHoles))
                    if((allHoles(h,3) ~= 0) & (allHoles(h,4) ~= 0))
                        thx = x - allHoles(h,1);
                        thy = y - allHoles(h,2);
                        thx2= thx*cos(2*pi*allHoles(h,5)/360) + thy*sin(2*pi*allHoles(h,5)/360);
                        thy2= -thx*sin(2*pi*allHoles(h,5)/360) + thy*cos(2*pi*allHoles(h,5)/360);
                        if(((0-allHoles(h,3)/2)<=thx2)&((allHoles(h,3)/2)>=thx2)&((0-allHoles(h,4)/2)<=thy2)&((allHoles(h,4)/2)>=thy2))
                            if((rand<=rhb))
                                borderNode = 1;
                                N = N-1;
                            else
                                addNode=0;
                                N = N-1;     
                            end
                            break;
                        end
                    end
                end
                if(addNode)
                    if(borderNode)
                        for e=1:round(rhb)
                            [x,y] = borderPos(allHoles(h,1),allHoles(h,2),allHoles(h,3),allHoles(h,4),allHoles(h,5));
                            t = insertNode(t,Swrap,x,y,Dix,Diy,Nx,Ny);
                            N = N+1;
                        end
                    else
                        t = insertNode(t,Swrap,x,y,Dix,Diy,Nx,Ny);
                    end
                end
            end
        end
    end
end
% end with the calculation of the nodes
topology=t;
mote_IDs=1:N;  

function [t]=insertNode(t,Swrap,x,y,Dix,Diy,Nx,Ny)
if(Swrap)
    x = mod(x,(Dix*(Nx)));
    y = mod(y,(Diy*(Ny)));
end
t=[t; x,y];



% This function returns the vertexes of a given rectangle
% The vertexes are specified by the Postion.
% return [A[x,y],B[x,y],C[x,y],D[x,y]]
function [A,B,C,D]=get_vertex(RA)
cx = RA(1);
cy = RA(2);
le = RA(3);
he = RA(4);
an = 360-RA(5);
% rotation + displacement
A = [( (-le/2)*cos(2*pi*an/360) + (-he/2)*sin(2*pi*an/360))+cx,...
     (-(-le/2)*sin(2*pi*an/360) + (-he/2)*cos(2*pi*an/360))+cy];
B = [(  (le/2)*cos(2*pi*an/360) + (-he/2)*sin(2*pi*an/360))+cx,...
     ( -(le/2)*sin(2*pi*an/360) + (-he/2)*cos(2*pi*an/360))+cy];
C = [(  (le/2)*cos(2*pi*an/360) +  (he/2)*sin(2*pi*an/360))+cx,...
     ( -(le/2)*sin(2*pi*an/360) +  (he/2)*cos(2*pi*an/360))+cy];
D = [( (-le/2)*cos(2*pi*an/360) +  (he/2)*sin(2*pi*an/360))+cx,...
     (-(-le/2)*sin(2*pi*an/360) +  (he/2)*cos(2*pi*an/360))+cy];

% This function returns a given number of disjoint rectangles
% This are specified by the postion of the center, the length, the heigth and the angle.
% return allRA[PosX, PosY, length, heigth, angle]
function [allRA]=rectangles_disjoint(rhn,rhl,rhlr,rhh,rhhr,Nx,Ny,Dix,Diy,Sx,Sy)
global RECTANGLES;
RECTANGLES=[];
allRA=[];
if(rhn~=0)
    firstRA =rectangle_create(Nx,Ny,Dix,Diy,Sx,Sy,rhl,rhlr,rhh,rhhr); 
    [A,B,C,D] = get_vertex(firstRA);
    
    RECTANGLES = [A,B,C,D];
    minX = min([A(1),B(1),C(1),D(1)]);
    minY = min([A(2),B(2),C(2),D(2)]);
    maxX = max([A(1),B(1),C(1),D(1)]);
    maxY = max([A(2),B(2),C(2),D(2)]);
    allRA = firstRA;
    testRA=[minX,maxX,minY,maxY];
    a = size (allRA);
    count=1;
    while ((rhn-1) >= a(1))
        newRA =rectangle_create(Nx,Ny,Dix,Diy,Sx,Sy,rhl,rhlr,rhh,rhhr);
        [A,B,C,D] = get_vertex(newRA);
        minX = min([A(1),B(1),C(1),D(1)]);
        minY = min([A(2),B(2),C(2),D(2)]);
        maxX = max([A(1),B(1),C(1),D(1)]);
        maxY = max([A(2),B(2),C(2),D(2)]);
        test=1;
        for i=1:size(allRA)
            if(~((maxX < testRA(i,1))|(testRA(i,2) < minX)|(maxY < testRA(i,3))|(testRA(i,4) < minY)))
                test=0;
                break;
            end
        end
        if(test)
            allRA=[allRA;newRA];
            testRA=[testRA; minX, maxX, minY, maxY];
            RECTANGLES = [RECTANGLES ;A,B,C,D];
        end
        a = size (allRA);
        if(count > rhn^2)
            t=1;
            prowler('PrintEvent', 'To many rectangles');
            break;
        end
        count=count*1.01;
    end
end

% This function returns a rectangle
% It is specified by the postion of the center, the length, the heigth and the angle.
% return rectangle[PosX, PosY, length, heigth, angle]
function [rectangle] = rectangle_create(Nx,Ny,Dix,Diy,Sx,Sy,lengthX,lengthRand,heigthY,heigthRand)
lengthX =lengthX*(1+lengthRand*(2*(rand-0.5)));
heigthY =heigthY*(1+heigthRand*(2*(rand-0.5)));
PosXnoS =((rand*(((Nx-1)*Dix)-lengthX))+lengthX/2);
PosYnoS =((rand*(((Ny-1)*Diy)-heigthY))+heigthY/2);
if((length(Sx) >= int32(PosYnoS)) & (1 < int32(PosYnoS)))
    PosX = PosXnoS + (Sx(int32(PosYnoS))*PosYnoS);
else
    PosX = PosXnoS + (Sx(1)*PosYnoS);
end
if((length(Sy) >= int32(PosXnoS)) & (1 < int32(PosXnoS)))
    PosY = PosYnoS + (Sy(int32(PosXnoS))*PosXnoS);
else
    PosY = PosYnoS + (Sy(1)*PosXnoS);
end
rectangle =[PosX, PosY, lengthX, heigthY, (rand*360)]; 

% This function returns the position of a node on the border of the given rectangle.
% The node is specified by the postion of it self.
% return [x,y]
function [x,y] = borderPos(RAX,RAY,length,heigth,angle)
newPos=(rand*2*(length+heigth));
if(newPos<heigth)
    x=(-length/2);
    y=(-heigth/2)+newPos;
elseif(newPos<(heigth+length))
    x=(-length/2)+newPos-(heigth);
    y=(+heigth/2);
elseif(newPos<(2*heigth+length))
    x=(+length/2);
    y=(+heigth/2)-newPos+(heigth+length);
else
    x=(-length/2)+newPos-(2*heigth+length);
    y=(-heigth/2);    
end
helpx= x *cos(2*pi*(360-angle)/360) + y*sin(2*pi*(360-angle)/360);
helpy= -x*sin(2*pi*(360-angle)/360) + y*cos(2*pi*(360-angle)/360);
x = helpx + RAX;
y = helpy + RAY;



