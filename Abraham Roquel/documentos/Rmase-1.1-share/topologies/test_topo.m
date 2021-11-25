% UNIVERSIDAD DEL VALLE DE GUATEMALA
% Archivo para definir la topologia a usar en RMASE
%

function [topology, mote_IDs] = test_topo(varargin)
	% vectores fila: 
	% el vector mote_IDs tiene los ids que se asignaran a los nodos
	% el vector mote_Xs tiene las coordenadas en x en el orden de mote_IDs
	% el vector mote_Ys tiene las coordenadas en y en el orden de mote_IDs

	% definir a conveniencia
	h = 2;
	d = 2;
	mote_IDs = [1, 2, 3, 4, 5, 6];	%definir los IDs de los nodos
	mote_Xs = [0, d, 3*d/2, 2*d, 2*d, 3*d];	%ubicaciones respectivas sobre eje X
	mote_Ys = [0, 0, h/2, h/2, -h/2, 0];	%ubicaciones respectivas sobre eje Y

	mote_IDs = [1, 2, 3, 4, 5, 6];	%definir los IDs de los nodos
	mote_Xs = [0, 1, 2, 3, 4, 1];	%ubicaciones respectivas sobre eje X
	mote_Ys = [0, 1, 2, 1, 0, -1];	%ubicaciones respectivas sobre eje Y

	% no editar
	topology = [mote_Xs', mote_Ys'];
end