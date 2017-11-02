function this = if_(this, test, ifTrue, varargin)
% if_  Replace time series values based on a test condition
%
% __Syntax__
%
% Input arguments marked with a `~` sign may be omitted.
%
%     X = if_(X, Test, IfTrue, ~IfFalse)
%
%
% __Input Arguments__
%
% * `X` [ TimeSeriesBase ] - Input time series.
%
% * `Test` [ function_handle ] - Test function that returns `true` or
% `false` for each observation.
%
% * `IfTrue` [ any | empty ] - Value assigned to observations for which the
% `Test` function returns `true`; if isempty, these observations will
% remain unchanged.
%
% * `IfFalse` [ any | empty ] - Value assigned to observations for which
% the `Test` function returns `false`; if isempty or omitted, these
% observations will remain unchanged.
%
% 
% __Output Arguments__
%
% `X` [ TimeSeriesBase ] - Output time series.
%
%
% __Description__
%
%
% __Example__
%

% -IRIS Macroeconomic Modeling Toolbox.
% -Copyright (c) 2007-2017 IRIS Solutions Team.

persistent INPUT_PARSER
if isempty(INPUT_PARSER)
    INPUT_PARSER = extend.InputParser('TimeSeriesBase.if_');
    INPUT_PARSER.addRequired('TimeSeries', @(x) isa(x, 'TimeSeriesBase'));
    INPUT_PARSER.addRequired('Test', @(x) isa(x, 'function_handle'));
    INPUT_PARSER.addRequired('IfTrue');
    INPUT_PARSER.addOptional('IfFalse', [ ]);
end
INPUT_PARSER.parse(this, test, ifTrue, varargin{:});
ifFalse = INPUT_PARSER.Results.IfFalse;

%--------------------------------------------------------------------------

data = this.Data;
indexTrue = test(data);

assert( ...
    islogical(indexTrue) && isequal(size(data), size(indexTrue)), ...
    exception.Base('TimeSeriesBase:IfTestCompliance', 'error') ...
);

if isempty(ifTrue) && isempty(ifFalse)
    return
end

if ~isempty(ifTrue)
    if isequal(ifTrue, @missing) || isequal(ifTrue, @MissingValue)
        ifTrue = this.MissingValue;
    end
    data(indexTrue) = ifTrue;
end

if ~isempty(ifFalse)
    if isequal(ifFalse, @missing) || isequal(ifFalse, @MissingValue)
        ifFalse = this.MissingValue;
    end
    data(~indexTrue) = ifFalse;
end

this.Data = data;
this = trim(this);

end
