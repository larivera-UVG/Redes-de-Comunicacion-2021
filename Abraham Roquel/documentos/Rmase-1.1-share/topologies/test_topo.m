function [topology, mote_IDs] = test_topo(varargin)
	%mote_IDs = [1, 2, 3, 4, 5, 6];	%definir los IDs de los nodos
	%mote_Xs = [0, 0, 0, 0, 0, 0];	%ubicaciones respectivas sobre eje X
	%mote_Ys = [0, 1, 2, 3, 4, 5];	%ubicaciones respectivas sobre eje Y

	h = 2;
	d = 2;
	mote_IDs = [1, 2, 3, 4, 5, 6];	%definir los IDs de los nodos
	mote_Xs = [0, d, 3*d/2, 2*d, 2*d, 3*d];	%ubicaciones respectivas sobre eje X
	mote_Ys = [0, 0, h/2, h/2, -h/2, 0];	%ubicaciones respectivas sobre eje Y


	topology = [mote_Xs', mote_Ys'];
end