local M={}
function M.new()
 local api={};local last;local fps;local run;local result
 function api.begin()run={frames=0,seconds=0,low=math.huge,high=0,windows=0};result=nil;last=nil end
 function api.reset()last=nil;fps=nil;if run then result={error='Measurement cancelled: world changed'}end;run=nil end
 function api.sample(frames,seconds,paused)
  if type(frames)~='number'or type(seconds)~='number'or frames~=frames or seconds~=seconds then return end
  if paused then last=nil;fps=nil;return end
  if not last or frames<last.frames or seconds<last.seconds then last={frames=frames,seconds=seconds};return end
  local dt,df=seconds-last.seconds,frames-last.frames
  if dt<.5 then return end
  last={frames=frames,seconds=seconds}
  if dt>2 or df<=0 then fps=nil;return end -- discard loading stalls / suspended sampling
  fps=df/dt
  if run then
   run.frames=run.frames+df;run.seconds=run.seconds+dt;run.windows=run.windows+1
   run.low=math.min(run.low,fps);run.high=math.max(run.high,fps)
   if run.seconds>=30 then result={average=run.frames/run.seconds,low=run.low,high=run.high,seconds=run.seconds,windows=run.windows};run=nil end
  end
 end
 function api.status()return{fps=fps,remaining=run and math.max(0,30-run.seconds),result=result}end
 return api
end
return M
