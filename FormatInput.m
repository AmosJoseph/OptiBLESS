function [Nvar,NpatchVar,NthetaVar,NdropVar,LamType,LB,UB,AllowedNplies]  = FormatInput(Objectives,Constraints)

NplyIni = cell2mat(Objectives.Table(2:end,2));

if Constraints.Sym  && Constraints.Balanced,
    DeltaNPly = 4;                  % The allowed ply numbers are multiple of DeltaNPly
    LamType   = 'Balanced_Sym';     % Type of Laminate
end

if Constraints.Sym && ~Constraints.Balanced,
    DeltaNPly = 2;
    LamType   = 'Sym';
end

if ~Constraints.Sym && Constraints.Balanced,
    DeltaNPly = 2;
    LamType   = 'Balanced';
end

if  ~Constraints.Sym && ~Constraints.Balanced,
    LamType   = 'Generic';
    DeltaNPly = 1;
end

Nplies    = round(NplyIni/DeltaNPly)*DeltaNPly;                    % Upper and lower Number of plies allowed for each patch
NthetaVar = max(Nplies(:))/DeltaNPly;                              % Number of variable angles


[MaxNplies,rowIndMax] = max(Nplies(:,2)); 
NpliesTemp = Nplies;
NpliesTemp(rowIndMax,:) = [];
if ~isempty(NpliesTemp), 
    NdropVar = (MaxNplies-min(NpliesTemp(:)))/DeltaNPly;           % Number of guide drops variable
    clear NpliesTemp
else
    NdropVar = 0;
end


if Constraints.Balanced
    NbalVar = NthetaVar;                                           % Number of balanced angles
else
    NbalVar = 0;
end

AllowedNplies = cell(size(NplyIni,1),1);
for i=1:size(NplyIni,1)
    AllowedNplies{i} = (Nplies(i,1):DeltaNPly:Nplies(i,2))/DeltaNPly;       % Number of Ply Range
end



% [~,sortIndex]   = sort(NplyIni(:,1),'descend');
% AllowedNplies   = AllowedNplies(sortIndex);
% ObjectivesTable = [Objectives.Table(1,:); Objectives.Table(1+sortIndex,:)];


Nrange = cellfun(@max,AllowedNplies,'UniformOutput', true) - cellfun(@min,AllowedNplies,'UniformOutput', true); % max ply - min ply per lam.
NpatchVar = zeros(length(Nrange),1);
NpatchVar(Nrange>0)=1; % number of variable thickness lam.



%% Genotype Upper and Lower Bounds 

Nvar      = sum(NpatchVar) + NthetaVar + NbalVar + NdropVar;
Nd_state  = length(-90:Constraints.DeltaAngle:90);              % number of discrete state for variable angles

LB = [];
UB = [];

LB = [LB; cellfun(@min,AllowedNplies(find(NpatchVar)),'UniformOutput', true)];
UB = [UB; cellfun(@max,AllowedNplies(find(NpatchVar)),'UniformOutput', true)];

LB = [LB; 0*ones(NthetaVar,1)];
UB = [UB; (Nd_state-1)*ones(NthetaVar,1)];

LB = [LB; ones(NbalVar,1)];
UB = [UB; 2*NbalVar*ones(NbalVar,1)];
    
if Constraints.Vector(7) % covering
    if strcmp(LamType,'Generic')
        LB = [LB; 2*ones(NdropVar,1)];                  % remove the first
        UB = [UB; (NthetaVar-1)*ones(NdropVar,1)];      % remove the last
    else
        LB = [LB; 2*ones(NdropVar,1)];                  % remove the first
        UB = [UB; NthetaVar*ones(NdropVar,1)];
    end
else
    LB = [LB; ones(NdropVar,1)];
    UB = [UB; NthetaVar*ones(NdropVar,1)];
end

if Constraints.Vector(1) % if Damtol, make the first ply +- 45
    LB(sum(NpatchVar)+1) = 1;
    UB(sum(NpatchVar)+1) = 2;
end
end