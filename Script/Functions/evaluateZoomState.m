function state = evaluateZoomState(opsys, options)
%EVALUATEZOOMSTATE Evaluate the primary wavelength; optionally trace/spot.
arguments
    opsys (1,1) opticalSystem
    options.Rays (1,1) logical = true
    options.Spot (1,1) logical = false
end
p=paraxialInfo(opsys,Wavelengths=opsys.PrimaryWavelength);
state.FocalLength=p.FocalLength;
state.FNumber=p.FNumber;
state.FocusOffset=p.SecondFocalPoint(3)-opsys.Components(end).Position(3);
assert(isfinite(state.FocalLength),'zoom:Optics','Nonfinite focal length.');
if options.Rays
    state.Rays=traceMarginalRays(opsys,Wavelengths=opsys.PrimaryWavelength);
end
if options.Spot
    s=spot(opsys,Wavelengths=opsys.PrimaryWavelength);
    state.SpotRMS=s.RMS;
    assert(isfinite(s.RMS),'zoom:Optics','Nonfinite spot RMS.');
end
end
