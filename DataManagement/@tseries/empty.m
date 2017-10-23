function this = empty(varargin)
% empty  Create empty time series or empty an existing time series
%
% __Syntax__
%
%     x = tseries.empty([0, size, ...])
%     x = tseries.empty(0, size, ...)
%     x = tseries.empty(x)
%
% 
% __Input Arguments__
%
% * `size` [ numeric ] - Size of new time series in 2nd and higher
% dimensions; first dimenstion (time) must be always 0.
%
% * `this` [ tseries ] - Input time series that will be emptied.
%
%
% __Output Arguments__
%
% * `this` [ tseries ] - Empty time series with the 2nd and higher
% dimensions the same size as the input tseries object, and comments
% preserved.
%
%
% __Description__
%
%
% __Example__
%

% -IRIS Macroeconomic Modeling Toolbox.
% -Copyright (c) 2007-2017 IRIS Solutions Team.

%--------------------------------------------------------------------------

nanDate = DateWrapper(NaN);
if nargin==1 && isa(varargin{1}, 'tseries')
    this = varargin{1};
    this.Start = nanDate;
    newSize = size(this.Data);
    newSize(1) = 0;
    this.Data = double.empty(newSize);
else
    this = tseries( );
    newData = double.empty(varargin{:});
    assert( ...
        size(newData, 1)==0, ...
        exception.Base('Series:TimeDimMustBeZero', 'error') ...
    );
    this.Start = nanDate;
    this.Data = newData;
    sizeData = size(newData);
    this.Comment = repmat({''}, [1, sizeData(2:end)]);
end

end