function opsys = createPhotoZoom(options)
arguments
    options.ZoomPosition (1,1) double {mustBeMember(options.ZoomPosition,[1 2])} = 1
end

% Reference: 
% Handbook Of Optics Volume II Second Edition
% Chap 16, Fig 14-Fig 15
% 70-210 mm F/2.8-4

opsys = opticalSystem(Name="Photo Zoom");

opsys.Wavelengths = [433, 483, 558, 634, 685];


gapMat = optics.material.vacuum;

% Equivalent materials
FD1=opticalMaterial([ 1.71736,29.50028],Name="FD1");
FCD1=opticalMaterial([1.496997,81.608379],Name="FCD1");
FC5=opticalMaterial([1.487489,70.441164],Name="FC5");
FD6=opticalMaterial([1.805184,25.465194],Name="FD6");
TAC2=opticalMaterial([1.740997,52.602013],Name="TAC2");
LAC14=opticalMaterial([1.696802,55.459694],Name="LAC14");
BACD5=opticalMaterial([1.589129,61.252619],Name="BACD5");
F5=opticalMaterial([ 1.60342,38],Name="F5");
NBFD10=opticalMaterial([1.834001,37.345055],Name="NBFD10");
FD14=opticalMaterial([1.761823,26.552048],Name="FD14");

% Note - Table in book uses clear aperture diameters, /2 to convert to
% SemiDiameter.

addRefractiveSurface(opsys, Radius=63.7262, DistanceToNext=2.9000, Material=FD1, SemiDiameter=51.59/2);
addRefractiveSurface(opsys, Radius=41.4392, DistanceToNext=12.2000, Material=FCD1, SemiDiameter=49.08/2);
addRefractiveSurface(opsys, Radius=-194.5870, DistanceToNext=0.1000, Material=gapMat, SemiDiameter=48.28/2);
addRefractiveSurface(opsys, Radius=73.5061, DistanceToNext=4.2000, Material=FC5, SemiDiameter=45.44/2);

if options.ZoomPosition==1
    % Zoom Position 1
    addRefractiveSurface(opsys, Radius=159.0812, DistanceToNext=2.4, Material=gapMat, SemiDiameter=44.23/2);
else
    % Zoom Position 2
    addRefractiveSurface(opsys, Radius=159.0812, DistanceToNext=18.25269, Material=gapMat, SemiDiameter=44.23/2);
end

addRefractiveSurface(opsys, Radius=-481.4192, DistanceToNext=3.4000, Material=FD6, SemiDiameter=36.10/2);
addRefractiveSurface(opsys, Radius=-119.3247, DistanceToNext=1.8000, Material=TAC2, SemiDiameter=34.61/2);
addRefractiveSurface(opsys, Radius=45.7271, DistanceToNext=6.2100, Material=gapMat, SemiDiameter=31.49/2);
addRefractiveSurface(opsys, Radius=-50.2560, DistanceToNext=1.8000, Material=LAC14, SemiDiameter=31.22/2);
addRefractiveSurface(opsys, Radius=42.1790, DistanceToNext=4.4000, Material=FD6, SemiDiameter=33.15/2);

if options.ZoomPosition==1
    % Zoom Position 1
    addRefractiveSurface(opsys, Radius=638.3038, DistanceToNext=40.3794, Material=gapMat, SemiDiameter=33.36/2);
else
    % Zoom Position 2
    addRefractiveSurface(opsys, Radius=638.3038, DistanceToNext=0.5000, Material=gapMat, SemiDiameter=33.36/2);
end

addRefractiveSurface(opsys, Radius=83.0243, DistanceToNext=3.8000, Material=FC5, SemiDiameter=36.06/2);
addRefractiveSurface(opsys, Radius=-177.6418, DistanceToNext=0.1000, Material=gapMat, SemiDiameter=36.12/2);
addRefractiveSurface(opsys, Radius=62.2167, DistanceToNext=3.6000, Material=BACD5, SemiDiameter=36.14/2);
addRefractiveSurface(opsys, Radius=192.0383, DistanceToNext=0.1000, Material=gapMat, SemiDiameter=35.75/2);
addRefractiveSurface(opsys, Radius=50.9787, DistanceToNext=7.7000, Material=FC5, SemiDiameter=35.17/2);
addRefractiveSurface(opsys, Radius=-55.6299, DistanceToNext=2.20000, Material=FD6, SemiDiameter=34.44/2);
addRefractiveSurface(opsys, Radius=730.9878, DistanceToNext=12.1770, Material=gapMat, SemiDiameter=33.41/2);

if options.ZoomPosition==1
    % Zoom Position 1
    addDiaphragm(opsys, DistanceToNext=11.9105, SemiDiameter=29.50/2);
else
    % Zoom Position 2
    addDiaphragm(opsys, DistanceToNext=11.9105, SemiDiameter=28.995/2);
end

addRefractiveSurface(opsys, Radius=179.5821, DistanceToNext=4.1000, Material=F5, SemiDiameter=25.77/2);
addRefractiveSurface(opsys, Radius=-55.0342, DistanceToNext=5.9640, Material=gapMat, SemiDiameter=25.30/2);

addDiaphragm(opsys, DistanceToNext=7.48, SemiDiameter=20.39/2);

addRefractiveSurface(opsys, Radius=-25.5712, DistanceToNext=2.2000, Material=NBFD10, SemiDiameter=19.36/2);
addRefractiveSurface(opsys, Radius=-475.9078, DistanceToNext=0.2000, Material=gapMat, SemiDiameter=20.83/2);
addRefractiveSurface(opsys, Radius=384.4369, DistanceToNext=2.4000, Material=FD14, SemiDiameter=21.13/2);
addRefractiveSurface(opsys, Radius=-105.6988, Material=gapMat, SemiDiameter=21.70/2);

% SemiDiameter is assumed.
% Ensure image plane stays at the same global point.
% (Computed based on table info for Zoom Position 2)
setConstructionFrame(opsys,Position=[0 0 182.6223]);
addImagePlane(opsys,SemiDiameter=20.5)
end


%   Copyright 2024 The MathWorks, Inc.
