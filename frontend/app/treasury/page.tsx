"use client";

import React, { useState } from "react";
import { AssetList } from "./AssetList";
import { AddAsset } from "./AddAsset";

export default function Page() {
  
  
    return (
      <main className="w-full h-fit flex flex-col gap-6 justify-center items-center pt-20 px-2">
        <AssetList />
        <AddAsset /> 
      </main>
    )
}