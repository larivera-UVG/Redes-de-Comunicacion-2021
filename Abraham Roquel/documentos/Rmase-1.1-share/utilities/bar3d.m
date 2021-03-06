function bar3d(Xs, Ys, Zs)

figure;
hold on

for x=Xs
    for y=Ys
        bar3d1(x,y,Zs(y,x));
    end
end

view(38, 75);

function bar3d1(x, y, z)

   xm = x-0.5; xp = x+0.5;
   ym = y-0.5; yp = y+0.5;
   surf([xm xp], [ym yp], [z z;z z]);
   if 0   % shade from bottom
      surf([xm xm],[ym yp],[0 z;0 z]);
      surf([xm xp],[ym ym],[0 0;z z]);
      surf([xp xp],[ym yp],[0 z;0 z]);
      surf([xm xp],[yp yp],[0 0;z z]);
   else   % shade from top
      surf([xm xm],[ym yp],[z 0;z 0]);
      surf([xm xp],[ym ym],[z z;0 0]);
      surf([xp xp],[ym yp],[z 0;z 0]);
      surf([xm xp],[yp yp],[z z;0 0]);
   end
