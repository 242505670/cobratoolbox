function model = liftModel(model, BIG, printLevel,fileName,directory)
% Lifts a COBRA model with badly-scaled stoichiometric and
% coupling constraints of the form:
% :math:`max c*v`  subject to: :math:`Sv = 0, x, Cv <= 0`
%
% INPUTS:
%    model:         COBRA Structure contain the original LP to be solved. The format of
%                   this struct is described in the documentation for `solveCobraLP.m`
%
% OPTIONAL INPUTS:
%    BIG:           A parameter the controls the largest entries that appear in the
%                   reformulated problem.
%    printLevel:    printLevel = 1 enables printing of problem statistics;
%                   printlevel = 0 silent
%
% OUTPUTS:
%    model:         COBRA Structure contain the reformulated LP to be solved.
%
% .. Authors:
%       - Michael Saunders, saunders@stanford.edu
%       - Yuekai Sun, yuekai@stanford.edu, Systems Optimization Lab (SOL), Stanford University
%       - Ronan Fleming   (updated interface to take COBRA model structure)

if ~exist('BIG','var')
    BIG=1000;
end
if ~exist('printLevel','var')
    printLevel=1;
end
if exist('fileName','var') && exist('directory','var') && isempty(model)
    model = loadIdentifiedModel(fileName,directory);
end

%save original model
origModel=model;

% Assume constraint matrix is S if no A provided.
if ~isfield(model,'A')
    if isfield(model,'S')
        model.A = model.S;
    end
end

% Assume constraint S*v = b if csense not provided
if ~isfield(model,'csense')
    % If csense is not declared in the model, assume that all
    % constraints are equalities.
    model.csense(:,1) = 'E';
end

% Assume constraint S*v = 0 if b not provided
if ~isfield(model,'b')
    warning('LP problem has no defined b in S*v=b. b should be defined, for now we assume b=0')
    model.b=zeros(size(model.A,1),1);
end

% Assume max c'v s.t. S v = b if osense not provided
if ~isfield(model,'osense')
    model.osense = -1;
end

%call the LP reformulate script by Michael and Yuekai
model = reformulate(model, BIG, printLevel);

if exist('fileName','var') && exist('directory','var')
    save([directory filesep 'L_' fileName '.mat'],'model');
end
