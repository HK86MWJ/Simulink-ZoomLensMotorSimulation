function gaps=interpolateZoomGaps(trajectory,focalLength)
%INTERPOLATEZOOMGAPS Linear interpolation preserves convex clearance limits.
validateattributes(focalLength,{'double'},{'real','finite','>=',70,'<=',210});
gaps=interp1(trajectory.TargetFocalLength,trajectory.Gaps,focalLength(:),'linear');
end
