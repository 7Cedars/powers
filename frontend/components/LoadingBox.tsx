"use client";

export function LoadingBox() {
  return (
    <div className="w-full flex flex-col justify-center items-center gap-3 animate-pulse">
      <div className="w-full h-4 bg-slate-200 rounded-full"></div>
      <div className="w-full flex flex-row justify-center items-center gap-6">
        <div className="w-24 h-4 bg-slate-200 rounded-full"></div>
        <div className="grow h-4 bg-slate-200 rounded-full"></div>
      </div>
      <div className="w-full flex flex-row justify-center items-center">
        <div className="grow h-4 bg-slate-200 rounded-full"></div>
        <div className="w-44 h-4 opacity-0"></div>
      </div>
    </div>
  )
}
