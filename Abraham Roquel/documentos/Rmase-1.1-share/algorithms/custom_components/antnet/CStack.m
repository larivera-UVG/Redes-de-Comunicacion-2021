classdef CStack < handle
% CStack define a stack data strcuture
% 
% It likes java.util.Stack, however, it could use CStack.content() to
% return all the data (in cells) of the Stack, and it is a litter faster
% than java's Stack.
% 
%   s = CStack(c);  c is a cells, and could be omitted
%   s.size() return the numble of element
%   s.isempty() return true when the stack is empty
%   s.empty() delete the content of the stack
%   s.push(el) push el to the top of stack
%   s.pop() pop out the top of the stack, and return the element
%   s.top() return the top element of the stack
%   s.remove() remove all the elements in the stack
%   s.content() return all the data of the stack (in the form of a
%   cells with size [s.size(), 1]
%   
% See also CList, CQueue
% 
% ¶¨Òå?ËÒ»¸öÕ»
% s = CStack; ¶¨ÒåÒ»¸ö¿ÕµÄÕ»¶Ô?ó
% s = CStack(c); ¶¨ÒåÕ»¶Ô?ó£¬²¢ÓÃc³õÊ¼»¯s£¬µ±cÎªcellÊ±£¬cµÄÔªËØÎª¶Ó??µÄÊý¾?£¬
%    ·ñÔòc±¾ÉíÎª¶Ó??µÄµÚÒ»¸öÊý¾?
%
% Ö§³Ö²Ù×÷£º
%     sz = s.size() ·µ»ØÕ»ÄÚÔªËØ¸öÊý£¬Ò²¿ÉÓÃÀ´Å?¶?Õ»ÊÇ·ñ·Ç¿Õ¡£
%     s.isempty() Å?¶?Õ»ÊÇ·ñÎª¿Õ
%     s.empty() Çå¿ÕÕ»
%     s.push(el) ½«?ÂÔªËØelÑ¹ÈëÕ»ÄÚ
%     s.pop()  µ¯³öÕ»¶¥ÔªËØ£¬ÓÃ»§?è×Ô¼ºÈ·±£Õ»·Ç¿Õ
%     el = s.top() ·µ»ØÕ»¶¥ÔªËØ£¬ÓÃ»§?è×Ô¼ºÈ·±£Õ»·Ç¿Õ
%     s.remove() Çå¿ÕÕ»
%     s.content() °´Ë³?ò·µ»ØsµÄÊý¾?£¬ÎªÒ»¸öcellÊý×é
%
% See also CList, CQueue
%
% Copyright: zhang@zhiqiang.org, 2010.
% url: http://zhiqiang.org/blog/it/matlab-data-structures.html
%
% inspirado en el codigo de zhang, agregando funciones para antnet
    properties (Access = private)
        buffer      % Ò»¸öcellÊý×é£¬±£´æÕ»µÄÊý¾?
        cur         % µ±Ç°ÔªËØÎ»ÖÃ, or the length of the stack
        capacity    % Õ»µÄÈ??¿£¬µ±È??¿²»¹»Ê±£¬È??¿À©³äÎª2±¶¡£
    end
    
    methods
        function obj = CStack(c)
            if nargin >= 1 && iscell(c)
                obj.buffer = c(:);
                obj.cur = numel(c);
                obj.capacity = obj.cur;
            elseif nargin >= 1
                obj.buffer = cell(100, 1);
                obj.cur = 1;
                obj.capacity =100;
                obj.buffer{1} = c;
            else
                obj.buffer = cell(100, 1);
                obj.capacity = 100;
                obj.cur = 0;
            end
        end
        
        function s = size(obj)
            s = obj.cur;
        end
        
        function remove(obj)
            obj.cur = 0;
        end
        
        function b = empty(obj)
            b = obj.cur;
            obj.cur = 0;
        end
        
        function b = isempty(obj)            
            b = ~logical(obj.cur);
        end
        function push(obj, el)
            if obj.cur >= obj.capacity
                obj.buffer(obj.capacity+1:2*obj.capacity) = cell(obj.capacity, 1);
                obj.capacity = 2*obj.capacity;
            end
            obj.cur = obj.cur + 1;
            obj.buffer{obj.cur} = el;
        end
        
        function el = top(obj)
            if obj.cur == 0
                el = [];
                warning('CStack:No_Data', 'trying to get top element of an emtpy stack');
            else
                el = obj.buffer{obj.cur};
            end
        end
        
        function el = pop(obj)
            if obj.cur == 0
                el = [];
                warning('CStack:No_Data', 'trying to pop element of an emtpy stack');
            else
                el = obj.buffer{obj.cur};
                obj.cur = obj.cur - 1;
            end        
        end
        
        function display(obj)
            if obj.cur
                for i = 1:obj.cur
                    disp([num2str(i) '-th element of the stack:']);
                    disp(obj.buffer{i});
                end
            else
                disp('The stack is empty');
            end
        end
        
        function c = content(obj)
            c = obj.buffer(1:obj.cur);
        end

        function remove_loops(obj)
            n_pivote = 1; % empezar por el primer elemento
            while n_pivote < obj.cur % condicion de paro
                n_pivote = remove_loops_from_position(obj, n_pivote); % actualizar el siguiente paso
            end
        end

        function remove_loops2(obj)
            n_pivote = 1; % empezar por el primer elemento
            while n_pivote < obj.cur % condicion de paro
                n_pivote = remove_loops_from_position2(obj, n_pivote); % actualizar el siguiente paso
            end 
        end
    end

    methods (Access = private)
        function remove_kth_position(obj, k)
            % remover la posicion k de la pila
            if k < obj.cur %se puede hacer el shift normal
                obj.buffer(k: obj.cur - 1) = obj.buffer(k + 1: obj.cur); %hacer shift a la izquierda
                obj.cur = obj.cur - 1; % decrementar el cursor
            elseif k == obj.cur %este caso es pop
                pop(obj);
            end
        end

        function next_index = remove_loops_from_position(obj, k)
            % remover los duplicados desde la referencia en posicion k
            k_el = obj.buffer{k}; % obtener el elemento en la posicion k
            % obtener las posiciones de las ocurrencias del elemento dentro del stack
            pos = find(cell2mat(obj.buffer(1:obj.cur)) == k_el);
            % filtrar por las que sean mayores a k
            pos_g_k = pos > k;
            % obtener la posicion del primer 1 en variable anterior
            pos_f_1 = find(pos_g_k == 1, 1);
            if ~isempty(pos_f_1) % si aplica el loop
                % obtener la posicion del duplicado en el arreglo original
                pos_u = pos(pos_f_1);
                % cuantas veces hacer shift
                n_remove = pos_u - k;
                % objetivo para hacer shift
                target_p = k + 1;
                for cc = 1:n_remove
                    remove_kth_position(obj, target_p);
                end
                next_index = k; % si se hallaron loops reevaluar
            else
                next_index = k + 1; % no se hallaron repetidos, seguir
            end
        end

        function next_index = remove_loops_from_position2(obj, k)
            % con este codigo se preserva el timer mas antiguo si ocurre un loop
            % remover los duplicados desde la referencia en posicion k
            k_el2 = obj.buffer{k}; % obtener el elemento en la posicion k
            k_el = k_el2(1);       % referir solo a la primera posicion del elemento
            content = cell2mat(obj.buffer(1:obj.cur));  % obtener el contenido del stack
            focus_column = content(:, 1);               % evaluar loops sobre la primera columna del contenido
            % obtener las posiciones de las ocurrencias del elemento dentro del stack
            pos = find(focus_column == k_el);
            % filtrar por las que sean mayores a k
            pos_g_k = pos > k;
            % obtener la posicion del primer 1 en variable anterior
            pos_f_1 = find(pos_g_k == 1, 1);
            if ~isempty(pos_f_1) % si aplica el loop
                % obtener la posicion del duplicado en el arreglo original
                pos_u = pos(pos_f_1);
                % cuantas veces hacer shift
                n_remove = pos_u - k;
                % objetivo para hacer shift
                target_p = k + 1;
                for cc = 1:n_remove
                    remove_kth_position(obj, target_p);
                end
                next_index = k; % si se hallaron loops reevaluar
            else
                next_index = k + 1; % no se hallaron repetidos, seguir
            end
        end
    end
end