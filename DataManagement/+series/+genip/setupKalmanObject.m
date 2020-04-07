function [kalmanObj, observed] = setupKalmanObject( ...
    model, lowLevel, aggregation, stdScale ...
    , conditions, indicator, transition ...
)
% setupKalmanObject  Set up time-varying LinearSystem and array of observed data for genip model
%
% Backend [IrisToolbox] function
% No help provided

% -[IrisToolbox] for Macroeconomic Modeling
% -Copyright (c) 2007-2020 [IrisToolbox] Solutions Team

%--------------------------------------------------------------------------

numXi = size(aggregation, 2);
numLowPeriods = size(lowLevel, 1);
numHighPeriods = numXi*numLowPeriods;

% 
% Transition matrix
%
T = hereSetupTransitionMatrix( );

%
% Transition equation innovation multiplier
%
R = zeros(numXi, 1);
R(numXi, 1) = 1;

%
% Transition equation constant
%
k = hereSetupTransitionConstant( );

%
% Innovation covariance matrices
%
stdScale = reshape(stdScale, 1, 1, [ ]);
OmegaV = ones(1, 1, numHighPeriods);
OmegaV(1, 1, :) = double(stdScale).^2;

%
% Measurement (aggregation) matrix
%
[Z, observed, H, stdW] = hereSetupMeasurement( );
OmegaW = diag(stdW.^2);
numY = size(Z, 1);
numW = size(OmegaW, 1);

%
% Measurement innovation and intercept
%
d = zeros(numY, 1);

kalmanObj = LinearSystem([numXi, numXi, 1, numY, numW], numHighPeriods);
kalmanObj = steadySystem(kalmanObj, 'NotNeeded');
kalmanObj = timeVaryingSystem(kalmanObj, 1:numHighPeriods, {T, R, k, Z, H, d}, {OmegaV, OmegaW});

return

    function T = hereSetupTransitionMatrix( )
        T = diag(ones(1, numXi-1), 1);
        T = repmat(T, 1, 1, numHighPeriods);
        switch string(model)
            case "Rate"
                T(numXi, numXi, :) = hereSetupTransitionRate( );
            case "Level"
                % Level indicator, do nothing
            case "Diff"
                T(numXi, numXi, :) = 1;
            case "DiffDiff"
                T(numXi, numXi, :) = 2;
                T(numXi, numXi-1, :) = -1;
        end
    end%


    function g = hereSetupTransitionRate( )
        if isequal(transition.Rate, @auto)
            g = series.genip.getTransitionRate(model, aggregation, lowLevel);
        else
            g = double(transition.Rate);
        end
        if isscalar(g)
            g = repmat(g, 1, 1, numHighPeriods);
        else
            g = reshape(g, 1, 1, [ ]);
        end
    end%


    function k = hereSetupTransitionConstant( )
        switch string(model)
            case "Rate"
                k = 0;
            otherwise
                if isequal(transition.Constant, @auto)
                    k = series.genip.getTransitionConstant(model, aggregation, lowLevel);
                else
                    k = double(transition.Constant);
                end
        end
        if isscalar(k)
            k = repmat(k, 1, 1, numHighPeriods);
        else
            k = reshape(k, 1, 1, [ ]);
        end
        k = [zeros(numXi-1, 1, numHighPeriods); k];
    end%


    function [Z, observed, H, stdW] = hereSetupMeasurement( )
        Z = zeros(0, numXi);
        observed = zeros(0, numHighPeriods);
        H = double.empty(0);
        stdW = double.empty(0);


        %
        % High to low frequency aggregation
        %
        addZ = aggregation;
        addH = zeros(1, size(H, 2));
        addObserved = reshape([nan(numXi-1, numLowPeriods); reshape(lowLevel, 1, [ ])], 1, [ ]);

        Z = [Z; repmat(addZ, 1, 1, size(Z, 3))];
        H = [H; addH];
        observed = [observed; addObserved];


        %
        % High frequency level conditions
        %
        if ~isempty(conditions.Level) && any(isfinite(conditions.Level))
            addZ = [zeros(1, numXi-1), 1];
            addH = zeros(1, size(H, 2));
            addObserved = reshape(conditions.Level, 1, [ ]);

            Z = [Z; repmat(addZ, 1, 1, size(Z, 3))];
            H = [H; addH];
            observed = [observed; addObserved];
        end


        %
        % High frequency rate conditions
        %
        inxFinite = isfinite(conditions.Rate);
        if ~isempty(conditions.Rate) && any(inxFinite)
            hereExpandZ( );
            [addZ, addObserved] = locallyGetObservedRate(conditions.Rate, numXi);
            addH = zeros(1, size(H, 2));

            Z = [Z; addZ];
            H = [H; addH];
            observed = [observed; addObserved];
        end


        %
        % High frequency diff conditions
        %
        if ~isempty(conditions.Diff) && any(isfinite(conditions.Diff))
            addZ = [zeros(1, numXi-2), -1, 1];
            addH = zeros(1, size(H, 2));
            addObserved = reshape(conditions.Diff, 1, [ ]);

            Z = [Z; repmat(addZ, 1, 1, size(Z, 3))];
            H = [H; addH];
            observed = [observed; addObserved];
        end


        %
        % High frequency diff-diff conditions
        %
        if ~isempty(conditions.DiffDiff) && any(isfinite(conditions.DiffDiff))
            addZ = [zeros(1, numXi-3), 1, -2, 1];
            addH = zeros(1, size(H, 2));
            addObserved = reshape(conditions.DiffDiff, 1, [ ]);

            Z = [Z; repmat(addZ, 1, 1, size(Z, 3))];
            H = [H; addH];
            observed = [observed; addObserved];
        end


        %
        % Indicator
        %
        inxFinite = isfinite(indicator.Transformed);
        if ~isempty(indicator.Transformed) && any(inxFinite)
            switch string(model)
                case "Level"
                    addZ = [zeros(1, numXi-1), 1];
                    addObserved = reshape(indicator.Transformed, 1, [ ]);
                case "Rate"
                    hereExpandZ( );
                    [addZ, addObserved] = locallyGetObservedRate(indicator.Transformed, numXi);
                case "Diff"
                    addZ = [zeros(1, numXi-2), -1, 1];
                    addObserved = reshape(indicator.Transformed, 1, [ ]);
                case "DiffDiff"
                    addZ = [zeros(1, numXi-3), 1, -2, 1];
                    addObserved = reshape(indicator.Transformed, 1, [ ]);
            end
            addH = 1;
            addStdW = indicator.StdScale;

            Z = [Z; addZ];
            observed = [observed; addObserved];
            H = blkdiag(H, addH);
            stdW = blkdiag(stdW, addStdW);
        end

        return

            function hereExpandZ( )
                if size(Z, 3)==1
                    Z = repmat(Z, 1, 1, numHighPeriods);
                end
            end%
    end%
end%


%
% Local Functions
%


function [Z, observed] = locallyGetObservedRate(x, numXi)
% locallyGetObservedRate  Create measurement equation for rate of change model
%
% x  [ numeric ]
% Vector of rates of change for individual high-frequency periods
%
% numXi  [ numeric ]
% Dimension of state vector
%

    numHighPeriods = numel(x);
    x = reshape(x, 1, [ ]);
    inxFinite = isfinite(x);
    Z = zeros(1, numXi, numHighPeriods);
    Z(1, numXi-1, :) = -1;
    Z(1, numXi-1, inxFinite) = -reshape(x(inxFinite), 1, 1, [ ]);
    Z(1, numXi, :) = 1;
    observed = nan(1, numHighPeriods);
    observed(1, inxFinite) = 0;
end%
