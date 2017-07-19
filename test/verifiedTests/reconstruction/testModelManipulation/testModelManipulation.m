% The COBRAToolbox: testModelManipulation.m
%
% Purpose:
%     - testModelManipulation tests addReaction, removeReaction, removeMetabolite
%       first creates a simple toy network with basic S, lb, ub, rxns, mets
%       tests addReaction, removeReaction, removeMetabolite
%       then creates an empty matrix and does the previous procedures.
%       Then tests convertToReversible, and convertToIrreversible using the
%       iJR904 model. Prints whether each test was successful or not.
%
% Authors:
%     - Joseph Kang 04/16/09
%     - Richard Que (12/16/09) Added testing of convertToIrrevsible/Reversible
%     - CI integration: Laurent Heirendt January 2017

% save the current path
currentDir = pwd;

% initialize the test
fileDir = fileparts(which('testModelManipulation'));
cd(fileDir);

% Test with non-empty model
fprintf('>> Starting non-empty model tests:\n');

% addReaction, removeReaction, removeMetabolite
model.S = [-1, 0, 0 ,0 , 0, 0, 0;
            1, -1, 0, 0, 0, 0, 0;
            0, -1, 0,-1, 0, 0, 0;
            0, 1, 0, 1, 0, 0, 0;
            0, 1, 0, 1, 0, 0, 0;
            0, 1,-1, 0, 0, 0, 0;
            0, 0, 1,-1, 1, 0, 0;
            0, 0, 0, 1,-1,-1, 0;
            0, 0, 0, 0, 1, 0, 0;
            0, 0, 0, 0,-1, 0, 0;
            0, 0, 0, 0, 0, 1, 1;
            0, 0, 0, 0, 0, 1, -1];
model.lb = [0, 0, 0, 0, 0, 0, 0]';
model.ub = [20, 20, 20, 20, 20, 20, 20]';
model.rxns = {'GLCt1'; 'HEX1'; 'PGI'; 'PFK'; 'FBP'; 'FBA'; 'TPI'};
model.mets = {'glc-D[e]'; 'glc-D'; 'atp'; 'H'; 'adp'; 'g6p';'f6p'; 'fdp'; 'pi'; 'h2o'; 'g3p'; 'dhap'};
sc =  [-1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0];
mets_length = length(model.mets);
rxns_length = length(model.rxns);

% adding a reaction to the model
model = addReaction(model, 'EX_glc', model.mets, sc, 0, 0, 20);

% adding a reaction to the model (test only)
model = addReaction(model, 'ABC_def', model.mets, 2 * sc, 0, -5, 10);

% check if the number of reactions was incremented by 1
assert(length(model.rxns) == rxns_length + 2);

% adding a reaction to the model (test only)
model = addReaction(model, 'ABC_def', model.mets, 3 * sc);

% remove the reaction from the model
model = removeRxns(model, {'EX_glc'});

% remove the reaction from the model
model = removeRxns(model, {'ABC_def'});

% add exchange reaction
addExchangeRxn(model, {'glc-D[e]'; 'glc-D';})

%check if rxns length was decremented by 1
assert(length(model.rxns) == rxns_length);

% add a new reaction to the model
model = addReaction(model,'newRxn1','A -> B + 2 C');

% check if the number of reactions was incremented by 1
assert(length(model.rxns) == rxns_length + 1);

% check if the number of metabolites was incremented by 3
assert(length(model.mets) == mets_length + 3);

% change the reaction bounds
model = changeRxnBounds(model, model.rxns, 2, 'u');
assert(model.ub(1) == 2);

% remove the reaction
model = removeRxns(model, {'newRxn1'});
assert(length(model.rxns) == rxns_length);

% remove some metabolites
model = removeMetabolites(model, {'A', 'B', 'C'});
assert(length(model.mets) == mets_length);

% Tests with empty model
fprintf('>> Starting empty model tests:\n');

model.S = [];
model.rxns = {};
model.mets = {};
model.lb = [];
model.ub = [];

rxns_length = 0;
mets_length = 0;

% add a reaction
model = addReaction(model,'newRxn1','A -> B + 2 C');

% check if the number of reactions was incremented by 1
assert(length(model.rxns) == rxns_length + 1);

% check if the number of metabolites was incremented by 3
assert(length(model.mets) == mets_length + 3);

% change the reaction bounds
model = changeRxnBounds(model, model.rxns, 2, 'u');
assert(model.ub(1) == 2);

% remove the reaction
model = removeRxns(model, {'newRxn1'});
assert(length(model.rxns) == rxns_length);

% remove some metabolites
model = removeMetabolites(model, {'A', 'B', 'C'});
assert(length(model.mets) == mets_length);

% Convert to irreversible
fprintf('>> Testing convertToIrreversible (1)\n');
load('testModelManipulation.mat','model','modelIrrev');
[testModelIrrev, matchRev, rev2irrev, irrev2rev] = convertToIrreversible(model);

% test if both models are the same
assert(isSameCobraModel(modelIrrev, testModelIrrev));

% Convert to reversible
fprintf('>> Testing convertToReversible\n');
testModelRev = convertToReversible(testModelIrrev);
testModelRev = rmfield(testModelRev,'reversibleModel'); % this should now be the original model!

% test if both models are the same
assert(isSameCobraModel(model,testModelRev));

% test irreversibility of model
fprintf('>> Testing convertToIrreversible (2)\n');
load('testModelManipulation.mat','model','modelIrrev');

% set a lower bound to positive (faulty model)
modelRev.lb(1) = 10;
[testModelIrrev, matchRev, rev2irrev, irrev2rev] = convertToIrreversible(model);

% test if both models are the same
assert(isSameCobraModel(modelIrrev, testModelIrrev));


%test Conversion with special ordering
fprintf('>> Testing convertToIrreversible (3)\n');
load('testModelManipulation.mat','model','modelIrrevOrdered');

[testModelIrrev, matchRev, rev2irrev, irrev2rev] = convertToIrreversible(model, 'orderReactions', true);

% test if both models are the same
assert(isSameCobraModel(modelIrrevOrdered, testModelIrrev));


%Test moveRxn
model2 = moveRxn(model,10,20);
fields = getModelFieldsForType(model,'rxns');
rxnSize = numel(model.rxns);
for i = 1:numel(fields)
    if size(model.(fields{i}),1) == rxnSize
        val1 = model.(fields{i})(10,:);    
        val2 = model2.(fields{i})(20,:);    
    elseif size(model.(fields{i}),2) == rxnSize
        val1 = model.(fields{i})(:,10);    
        val2 = model2.(fields{i})(:,20);    
    end
    assert(isequal(val1,val2));
end

% Test addReaction with name-value argument input
fprintf('>> Testing addReaction with name-value argument input\n');
% options available in the input:
name = {'reactionName', 'reversible', ...
    'lowerBound', 'upperBound', 'objectiveCoef', 'subSystem', 'geneRule', ...
    'geneNameList', 'systNameList', 'checkDuplicate', 'printLevel'};
value = {'TEST', true, ...
    -1000, 1000, 0, '', '', ...
    {}, {}, true, 1};
arg = [name; value];
model2 = addReaction(model, 'TEST', 'reactionFormula', [model.mets{1} ' <=>'], arg{:});
for k = 1:numel(name)
    % test differet optional name-value argument as the first argument after rxnID
    model2b = addReaction(model, 'TEST', name{k}, value{k}, 'reactionFormula', [model.mets{1} ' <=>']);
    assert(isequal(rmfield(model2, 'rev'), rmfield(model2b, 'rev')))  % rev field can be nan, not comparable
    
    model2b = addReaction(model, 'TEST', name{k}, value{k}, 'metaboliteList', model.mets(1), 'stoichCoeffList', -1);
    assert(isequal(rmfield(model2, 'rev'), rmfield(model2b, 'rev')))  % rev field can be nan, not comparable
    
    % test differet optional name-value argument as argument after reactionFormula or stoichCoeffList
    model2b = addReaction(model, 'TEST', 'reactionFormula', [model.mets{1} ' <=>'], name{k}, value{k});
    assert(isequal(rmfield(model2, 'rev'), rmfield(model2b, 'rev')))  % rev field can be nan, not comparable
    
    model2b = addReaction(model, 'TEST', 'metaboliteList', model.mets(1), 'stoichCoeffList', -1, name{k}, value{k});
    assert(isequal(rmfield(model2, 'rev'), rmfield(model2b, 'rev')))  % rev field can be nan, not comparable
end

% Test addReaction backward compatibility
fprintf('>> Testing addReaction backward compatibility\n');
% backward signature: model = addReaction(model,rxnName,metaboliteList,stoichCoeffList,revFlag,lowerBound,upperBound,objCoeff,subSystem,grRule,geneNameList,systNameList,checkDuplicate)
% reactionName
fprintf('reactionFormula\n');
model2 = addReaction(model, 'TEST', 'reactionFormula', [model.mets{1} ' <=>'], 'reactionName', 'TestReaction');
model2b = addReaction(model, {'TEST', 'TestReaction'}, [model.mets{1} ' <=>']);
assert(isequal(rmfield(model2, 'rev'), rmfield(model2b, 'rev')))
% metaboliteList & stoichCoeffList
fprintf('metaboliteList & stoichCoeffList\n');
model2 = addReaction(model, 'TEST', 'metaboliteList', model.mets(1), 'stoichCoeffList', -1);
model2b = addReaction(model, 'TEST', model.mets(1), -1);
assert(isequal(rmfield(model2, 'rev'), rmfield(model2b, 'rev')))
% revFlag
fprintf('reversible\n');
model2 = addReaction(model, 'TEST', 'metaboliteList', model.mets(1), 'stoichCoeffList', -1, 'reversible', 0);
model2b = addReaction(model, 'TEST', model.mets(1), -1, 0);
assert(isequal(rmfield(model2, 'rev'), rmfield(model2b, 'rev')))
% irreversible revFlag overridden by reversible reaction formula
model2 = addReaction(model, 'TEST', 'reactionFormula', [model.mets{1} ' <=>'], 'stoichCoeffList', -1, 'reversible', 0);
model2b = addReaction(model, 'TEST', [model.mets{1} ' <=>'], [], 0);
assert(isequal(rmfield(model2, 'rev'), rmfield(model2b, 'rev')) & model2.lb(end) < 0)
% lowerBound
fprintf('lowerBound\n');
model2 = addReaction(model, 'TEST', 'reactionFormula', [model.mets{1} ' <=>'], 'lowerBound', -10);
model2b = addReaction(model, 'TEST', [model.mets{1} ' <=>'], [], [], -10);
assert(isequal(rmfield(model2, 'rev'), rmfield(model2b, 'rev')) & model2.lb(end) == -10)
% upperBound
fprintf('upperBound\n');
model2 = addReaction(model, 'TEST', 'reactionFormula', [model.mets{1} ' <=>'], 'upperBound', 10);
model2b = addReaction(model, 'TEST', [model.mets{1} ' <=>'], [], [], [], 10);
assert(isequal(rmfield(model2, 'rev'), rmfield(model2b, 'rev')) & model2.ub(end) == 10)
% objCoeff
fprintf('objectiveCoef\n');
model2 = addReaction(model, 'TEST', 'reactionFormula', [model.mets{1} ' <=>'], 'objectiveCoef', 3);
model2b = addReaction(model, 'TEST', [model.mets{1} ' <=>'], [], [], [], [], 3);
assert(isequal(rmfield(model2, 'rev'), rmfield(model2b, 'rev')) & model2.c(end) == 3)
% subSystem
fprintf('subSystem\n');
model2 = addReaction(model, 'TEST', 'reactionFormula', [model.mets{1} ' <=>'], 'subSystem', 'testSubSystem');
model2b = addReaction(model, 'TEST', [model.mets{1} ' <=>'], [], [], [], [], [], 'testSubSystem');
assert(isequal(rmfield(model2, 'rev'), rmfield(model2b, 'rev')) & strcmp(model2.subSystems{end},'testSubSystem'))
% grRule
fprintf('geneRule\n');
model2 = addReaction(model, 'TEST', 'reactionFormula', [model.mets{1} ' <=>'], 'geneRule', 'test1 & test2');
model2b = addReaction(model, 'TEST', [model.mets{1} ' <=>'], [], [], [], [], [], [], 'test1 & test2');
nGene = numel(model2.genes);
assert(isequal(rmfield(model2, 'rev'), rmfield(model2b, 'rev')) ...
    & isequal(model2.genes(end-1:end), {'test1'; 'test2'}) & strcmp(model2.grRules{end}, 'test1 & test2') ...
    & strcmp(model2.rules{end}, ['x(' num2str(nGene-1) ') & x(' num2str(nGene) ')']))
% geneNameList & systNameList
fprintf('geneRule with geneNameList and systNameList\n');
model2 = addReaction(model, 'TEST', 'reactionFormula', [model.mets{1} ' <=>'], ...
    'geneRule', 'testGeneName1 & testGeneName2', 'geneNameList', {'testGeneName1'; 'testGeneName2'}, ...
    'systNameList', {'testSystName1'; 'testSystName2'});
model2b = addReaction(model, 'TEST', [model.mets{1} ' <=>'], [], [], [], [], [], [], ...
    'testGeneName1 & testGeneName2', {'testGeneName1'; 'testGeneName2'}, {'testSystName1'; 'testSystName2'});
nGene = numel(model2.genes);
assert(isequal(rmfield(model2, 'rev'), rmfield(model2b, 'rev')) ...
    & isequal(model2.genes(end-1:end), {'testSystName1'; 'testSystName2'}) & strcmp(model2.grRules{end}, 'testSystName1 & testSystName2') ...
    & strcmp(model2.rules{end}, ['x(' num2str(nGene-1) ') & x(' num2str(nGene) ')']))
% checkDuplicate
fprintf('checkDuplicate\n');
formula = printRxnFormula(model,'rxnAbbrList', model.rxns(1), 'printFlag', false);
model2 = addReaction(model, 'TEST', 'reactionFormula', formula{1}, 'checkDuplicate', true);
model2b = addReaction(model, 'TEST', formula{1}, [], [], [], [], [], [], [], [], [], true);
assert(isequal(rmfield(model2, 'rev'), rmfield(model, 'rev')) ...
    & isequal(rmfield(model2b, 'rev'), rmfield(model2, 'rev')))
model2 = addReaction(model, 'TEST', 'reactionFormula', formula{1}, 'checkDuplicate', false);
model2b = addReaction(model, 'TEST', formula{1}, [], [], [], [], [], [], [], [], [], false);
assert(isequal(rmfield(model2, 'rev'), rmfield(model2b, 'rev')) & numel(model2.rxns) == numel(model.rxns) + 1)


% change the directory
cd(currentDir)
