function [opsys, geometry] = configureZoomSystem(nominal, gaps, meta)
%CONFIGUREZOOMSYSTEM Create an independent state, keeping C1/C2/C13 fixed.
arguments
    nominal (1,1) opticalSystem
    gaps (1,2) double {mustBeFinite}
    meta (1,1) struct
end
assert(all(gaps>=meta.MinGaps-1e-8) && sum(gaps)<=meta.MaxGapSum+1e-8, ...
    'zoom:Geometry','Unsafe gaps: [%.6f %.6f] mm. Analysis stopped.',gaps(1),gaps(2));
opsys=copy(nominal);
changeGap(opsys,2,gaps(1),GapLocation="after");
changeGap(opsys,4,gaps(2),GapLocation="after");
opsys.Components(13).Position(3)=meta.FixedImagePlaneZ;
p=vertcat(opsys.Components.Position);
q=meta.NominalPositions;
assert(max(abs(p([1 2 13],:)-q([1 2 13],:)),[],'all')<1e-8, ...
    'zoom:FixedGroup','Fixed components moved.');
for group={3:4,5:12}
    idx=group{1};
    assert(max(abs((p(idx,:)-p(idx(1),:))-(q(idx,:)-q(idx(1),:))),[],'all')<1e-8, ...
        'zoom:RigidGroup','A zoom group lost its rigid geometry.');
end
t=opsys.SurfaceTable;
assert(all(diff(t.Position(:,3))>=-1e-8),'zoom:Geometry','Negative axial surface separation.');
geometry.Gaps=gaps;
geometry.ImageGap=meta.TotalFreeSpace-sum(gaps);
geometry.SurfaceClearances=[gaps geometry.ImageGap]-meta.SagAllowance;
assert(all(geometry.SurfaceClearances>=meta.Clearance-1e-8), ...
    'zoom:Geometry','Optical surfaces overlap or violate clearance.');
end
