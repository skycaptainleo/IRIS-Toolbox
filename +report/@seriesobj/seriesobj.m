classdef seriesobj < report.genericobj & report.condformatobj
    properties
        data = { iris.get('DefaultTimeSeriesConstructor') };
    end
    

    methods
        function this = seriesobj(varargin)
            this = this@report.genericobj(varargin{:});
            this = this@report.condformatobj( );
            this.childof = {'graph', 'table'};
            this.default = [this.default, { ...
                'autodata', { }, @(x) isempty(x) ...
                    || isfunc(x) || iscell(x), ...
                    true, ...
                'colstruct', [ ], @(x) isempty(x) ...
                    || report.genericobj.validatecolstruct(x), ...
                    true, ...
                'condformat', [ ], ...
                    @(x) isempty(x) || ( ...
                    isstruct(x) ...
                    && isfield(x, 'test') && isfield(x, 'format') ...
                    && iscellstr({x.test}) && iscellstr({x.format}) ), ...
                    true, ...
                'decimal', NaN, @isnumericscalar, true, ...
                'format', '%.2f', @ischar, true, ...
                'highlight', [ ], ...
                    @(x) isempty(x) || isnumeric(x) || isfunc(x), ...
                    false, ...
                'legendentry, legend', @auto, @(x) isempty(x) ...
                    || (isnumericscalar(x) && (isnan(x) || isinf(x))) ...
                    || isequal(x, @auto) ...
                    || iscellstr(x) || ischar(x), ...
                    false, ...
                'marks', { }, @(x) isempty(x) || iscellstr(x), true, ...
                'inf', '\ensuremath{\infty}', @ischar, true, ...
                'nan', '\ensuremath{\cdots}', @ischar, true, ...
                'plotfunc', @plot, ...
                    @(x) isequal(x, @plot) || isequal(x, @area) || isequal(x, @bar) || isequal(x, @barcon) || isequal(x, @conbar) || isequal(x, @plotcmp) || isequal(x, @plotpred) || isequal(x, @stem), ...
                    true, ...
                'plotoptions', { }, ...
                    @(x) iscell(x) && iscellstr(x(1:2:end)), ...
                    true, ...
                'purezero', '', @ischar, true, ...
                'printedzero', '', @ischar, true, ...
                'round', Inf, @(x) isintscalar(x), true, ...
                'rowhighlight', false, @islogical, false, ...
                'separator', '', @(x) ischar(x) || isnumeric(x), false, ...
                'showmarks', true, @islogical, true, ...
                'units', '', @ischar, true, ...
                'yaxis, yaxislocation', 'left', ...
                    @(x) any(strcmpi(x, {'left', 'right'})), ...
                    false, ...
                }];
        end
        

        function [this, varargin] = specargin(this, varargin)
            if ~isempty(varargin)
                if isa(varargin{1}, 'tseries') || iscell(varargin{1})
                    this.data = varargin{1};
                    if isa(this.data, 'tseries')
                        this.data = {this.data};
                    end
                end
                varargin(1) = [ ];
            end
            if isequal(this.caption, Inf) && ~isempty(this.data)
                try %#ok<TRYNC>
                    x = this.data{1};
                    this.caption = x.Comment{1};
                end
            end
            if isequal(this.caption, Inf)
                this.caption = '';
            end
        end
        

        function this = setoptions(this, varargin)
            this = setoptions@report.genericobj(this, varargin{:});
            this.options.marks = this.options.marks(:).';
            if ~isempty(this.options.autodata)
                if isa(this.options.autodata, 'function_handle')
                    this.options.autodata = {this.options.autodata};
                end
                try %#ok<TRYNC>
                    this = autodata(this);
                end
            end
            if ~isnan(this.options.decimal)
                this.options.format = sprintf('%%.%gf', ...
                    round(abs(this.options.decimal)));
            end
            this = assign(this, this.options.condformat);
            if ~this.options.showmarks
                this.options.marks = { };
            end
            if strcmp(func2str(this.options.plotfunc), 'conbar')
                this.options.plotfunc = @barcon;
            end
            % Round input series after autodata.
            r = this.options.round;
            if ~isequal(r, Inf)
                for i = 1 : length(this.data)
                    if isa(this.data{i}, 'tseries')
                        this.data{i} = round(this.data{i}, r);
                    end
                end
            end
            if isnumeric(this.options.separator)
                this.options.separator = ...
                    sprintf('[%gem]', this.options.separator);
            end
        end
        
        
        varargout = plot(varargin)
        varargout = latexonerow(varargin)
        varargout = latexdata(varargin)
        varargout = autodata(varargin)
        varargout = getdata(varargin)
    end

    
    methods (Access=protected, Hidden)
        varargout = mylegend(varargin)
        varargout = speclatexcode(varargin)
    end
end
