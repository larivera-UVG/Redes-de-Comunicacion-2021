function DrawHoles

global RECTANGLES

ax = prowler('GetDisplayHandle');
for j=1:size(RECTANGLES)
     line([RECTANGLES(j,1),RECTANGLES(j,3)],[RECTANGLES(j,2),RECTANGLES(j,4)],'LineWidth',2,'Color',[.8 .8 .8],'parent',ax);
     line([RECTANGLES(j,3),RECTANGLES(j,5)],[RECTANGLES(j,4),RECTANGLES(j,6)],'LineWidth',2,'Color',[.8 .8 .8],'parent',ax);
     line([RECTANGLES(j,5),RECTANGLES(j,7)],[RECTANGLES(j,6),RECTANGLES(j,8)],'LineWidth',2,'Color',[.8 .8 .8],'parent',ax);
     line([RECTANGLES(j,7),RECTANGLES(j,1)],[RECTANGLES(j,8),RECTANGLES(j,2)],'LineWidth',2,'Color',[.8 .8 .8],'parent',ax);
end