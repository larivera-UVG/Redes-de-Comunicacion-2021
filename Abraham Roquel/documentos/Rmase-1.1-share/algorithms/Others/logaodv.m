% logevent(e, data, tag)
% e is event name
% data is the packet
% tag is the extra info associated with the event 

function logstr = logaodv(e, dat, tag)
global ID
global DESTINATIONS
global routeTable rreqCache
global AODV_RQCACHE_SIZE AODV_RTABLE_SIZE INVALID_MSG_ID INVALID_NODE_ID

logstr = '';

switch e
case {'Sent','Resent','Recved','Collided','Dropped'}
    try numHops = dat.numHops; catch numHops = -1; end
    try address = dat.address; catch address = 0; end
    try msgType = dat.msgType; catch msgType = 'DAT'; end

    logstr=strcat(logstr,sprintf('[type %s src %d msgID %d from %d to %d numHops %d]', ...
        msgType,dat.source, dat.msgID,dat.from,address,numHops));
    
case 'dump_rcache'
    for i=1:AODV_RQCACHE_SIZE
        if rreqCache{ID}(i).msgID ~= INVALID_MSG_ID
            logstr=strcat(logstr,sprintf(' [src %d msgID %d --> prevHops %s]',...
                rreqCache{ID}(i).source,rreqCache{ID}(i).msgID,mat2str([rreqCache{ID}(i).nextHops.id])));
        end
    end
    
case 'dump_rtable'
    for i=1:AODV_RTABLE_SIZE
        if routeTable{ID}(i).nextHop ~= INVALID_NODE_ID
            logstr=strcat(logstr,sprintf(' [src %d msgID %d --> nextHop %d]',routeTable{ID}(i).source,routeTable{ID}(i).msgID,routeTable{ID}(i).nextHop));
        end    
    end
    
case 'DESTINATIONS'
    logstr=strcat(logstr,'[');
    j=0;
    for i= DESTINATIONS
        j=j+1;
        if i
            logstr=strcat(logstr,sprintf('%d ',j));
        end
    end
    logstr=strcat(logstr,']');
end
        