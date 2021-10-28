function [topology, mote_IDs] = test_topo(varargin)
	mote_IDs = [1, 2, 3, 4, 5, 6];	%definir los IDs de los nodos
	mote_Xs = [0, 0, 0, 0, 0, 0];	%ubicaciones respectivas sobre eje X
	mote_Ys = 2*[0, 1, 2, 3, 4, 5];	%ubicaciones respectivas sobre eje Y
	topology = [mote_Xs', mote_Ys'];
end