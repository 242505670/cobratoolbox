classdef (HandleCompatible) AndNode < Node
    % AndNode are an class that represents AND connections in a logical formula
    % For further documentation please have a look at the Node Class.
    % .. Authors
    %     - Thomas Pfau 2016
    properties
    end
    
    methods
        function res = evaluate(self,assignment)
            res = true;
            for i=1:numel(self.children)
                child = self.children(i);
                if not(child.evaluate(assignment))
                    res = false;
                end
            end
            fprintf('%s : %i\n',self.toString(0),res);
        end
        
        function res = toString(self,PipeAnd)
            if nargin < 2
                PipeAnd = 0;
            end
            res = '';
            for i=1:numel(self.children)
                child = self.children(i);
                if PipeAnd
                    res = [res child.toString(PipeAnd) ' & '];
                else
                    res = [res child.toString(PipeAnd) ' and '];
                end
                
            end
            if length(res) > 2
                if PipeAnd
                    res = res(1:end-3);
                else
                    res = res(1:end-5);
                end
            end
        end
        
        function dnfNode = convertToDNF(self)
            dnfNode = OrNode();
            childNodes = [];
            sizes = [];
            for c=1:numel(self.children)
                child = self.children(c);
                if isempty(childNodes)
                    childNodes = child.convertToDNF();
                else
                    childNodes(end+1) = child.convertToDNF();
                end
                convNode = childNodes(end);
                if strcmp(class(convNode),'LiteralNode')
                    sizes(end+1) = 1;
                else
                    sizes(end+1) = numel(convNode.children);
                end
                
                
            end
            %Now make and combinations of all items in the children
            step = ones(numel(sizes),1);
            while self.isValid(sizes,step)
                nextNode = AndNode();
                for i=1:numel(step)
                    convNode = childNodes(i);
                    if strcmp(class(convNode),'LiteralNode')
                        nextNode.addChild(convNode);
                    else
                        nextNode.addChild(convNode.children(step(i)));
                    end
                end
                dnfNode.addChild(nextNode);
                step = self.nextcombination(sizes,step);
                
            end
            
        end
        
        function res = isValid(self,sizes,step)
            % Check whether a given step is a valid possibility (no step
            % element larger than sizes
            % USAGE:
            %    res = Node.isValid(sizes,step)
            %
            % INPUTS:
            %    sizes:     An array of sizes
            %    step:      An array of suggested selections
            %
            % OUTPUTS:
            %    res:       ~any(step > sizes')
            %
            res = ~any(step > sizes');
        end
        
        function combination = nextcombination(self,sizes,step)
            % Get the next combination given the current combination
            % USAGE:
            %    combination = Node.nextcombination(sizes,step)
            %
            % INPUTS:
            %    sizes:     An array of maximal sizes
            %    step:      The current combination
            %
            % OUTPUTS:
            %    combination:   The next allowed element of step
            %                   incremented, and potentially others reset
            %                   to 1.
            %            
            combination = step;
            combination(1) = combination(1) + 1;
            for i=1:numel(sizes)
                if combination(i) > sizes(i)
                    if i < numel(sizes)
                        combination(i) = 1;
                        combination(i+1) = combination(i+1)  + 1;
                    end
                else
                    break;
                end
            end
        end
        
        
        function reduce(self)
            child = 1;
            delchilds = [];
            while child <= numel(self.children)
                cchild = self.children(child);
                %Merge Nodes from the same class.
                if strcmp(class(self.children(child)),class(self))
                    %reduce the child, merging and removing "singular
                    %nodes"
                    cchild.reduce();
                    for cc = 1:numel(cchild.children)
                        cchildchild = cchild.children(cc);
                        self.children(end+1) = cchildchild;
                        cchildchild.parent = self;
                    end
                    delchilds(end+1) = child;
                    %If a child is not a literal but has only one child, move
                    %that child up.
                else
                    while ( numel(cchild.children) <= 1 && ~(isa(cchild,'LiteralNode')) )
                        cchildchild = cchild.children(1);
                        self.children(child) = cchildchild;
                        cchildchild.parent = self;
                        %we can't continue yet, as this child could now be
                        %an AND node.
                        cchild = cchildchild;
                    end
                end
                child = child + 1;
            end
            %Remove Merged childs
            self.children(delchilds)  = [];
            %And reduce all non literal and non same class children,
            %everything else should already be reduced.
            for child = 1:numel(self.children)
                if (strcmp(class(self.children(child)),class(self)) && ~(isa(cchild,'LiteralNode')) )
                    cchild = self.children(child);
                    cchild.reduce();
                end
            end
        end
    end
    
end

