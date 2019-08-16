% validate  Utility class with static validators
%
% Backend class
% No help provided

% -IRIS Macroeconomic Modeling Toolbox
% -Copyright (c) 2007-2019 IRIS Solutions Team


classdef validate
    methods (Static)
        function flag = databank(input)
            flag = isstruct(input) ...
                || isa(input, 'Dictionary') ...
                || isa(input, 'containers.Map');
        end%


        function flag = numericScalar(input, lim)
            if ~isnumeric(input) || ~isscalar(input)
                flag = false;
                return
            end
            if nargin==1
                flag = true;
                return
            end
            flag = input>=lim(1) && input<=lim(2);
        end%

            
        function flag = roundScalar(input)
            flag = validate.numericScalar(input) && input==round(input);
        end%


        function flag = logicalScalar(input)
            flag = isequal(input, true) | isequal(input, false);
        end%


        function flag = string(input)
            flag = ischar(input) || isa(input, 'string');
        end%


        function flag = list(input)
            flag = validate.string(input) || iscellstr(input);
        end%


        function flag = anyString(input, varargin)
            if ~validate.string(input)
                flag = false;
                return
            end
            flag = any(strcmpi(input, varargin));
        end%


        function flag = solvedModel(input)
            flag = (isa(input, 'model') || isa(input, 'Model')) ...
                   && all(beenSolved(input));
        end%
    end
end
