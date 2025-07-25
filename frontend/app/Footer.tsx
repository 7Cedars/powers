"use client";

import { HeartIcon } from '@heroicons/react/24/outline';
import Image from 'next/image'

export function Footer() {

  return (
    <section className="w-full flex flex-col justify-between items-center min-h-fit bg-slate-50 snap-end pt-12 pb-6 border-t border-slate-300 snap-end">
        
        <div className = "max-w-7xl w-full flex md:flex-row flex-col justify-between md:items-start items-center text-slate-800 text-sm px-4 gap-16"> 
            <div className="grid md:grid-cols-3 grid-cols-2 gap-28">
                <div className="flex flex-col gap-3 justify-start items-start">
                    <div className="font-bold"> 
                        DApp
                    </div>
                    <a
                        href={`https://7cedars.gitbook.io/separated-powers/using-the-app`} target="_blank" rel="noopener noreferrer"
                        className="text-slate-500"
                    >
                        Docs
                    </a>
                    <a
                        href={`https://github.com/7Cedars/separated-powers/tree/main/frontend`} target="_blank" rel="noopener noreferrer"
                        className="text-slate-500"
                    >
                        Github repo
                    </a>
                </div>
                <div className="flex flex-col gap-3 justify-start items-start">
                    <div className="font-bold"> 
                        Protocol
                    </div>
                    <a
                        href={`https://7cedars.gitbook.io/powers-protocol`} target="_blank" rel="noopener noreferrer"
                        className="text-slate-500"
                    >
                        About
                    </a>
                    <a
                        href={`https://7cedars.gitbook.io/powers-protocol`} target="_blank" rel="noopener noreferrer"
                        className="text-slate-500"
                    >
                        Docs
                    </a>
                    <a
                        href={`https://github.com/7Cedars/separated-powers/tree/main/solidity`} target="_blank" rel="noopener noreferrer"
                        className="text-slate-500"
                    >
                        Github repo
                    </a>
                </div>
            </div>

        <div className="w-full flex flex-row gap-3 md:justify-end justify-center items-end snap-end">
            <div className="flex flex-col gap-3 justify-start md:items-end items-center pb-12">
            <Image 
            src='/logo1_notext.png' 
            width={48}
            height={48}
            alt="Logo Separated Powers"
            >
            </Image>
            <div className="text-md font-bold flex flex-row gap-1">
                <p>Made with</p> 
                <HeartIcon className="w-4 h-4 text-red-700" />
                <p>by 7Cedars</p>
            </div>
            <div className="flex flex-row gap-2">
                <a
                    href={`https://discordapp.com/users/1006928106487021638`} target="_blank" rel="noopener noreferrer"
                    className="text-slate-500"
                >
                    discord
                </a>
                <a
                    href={`https://mirror.xyz/7cedars.eth`} target="_blank" rel="noopener noreferrer"
                    className="text-slate-500"
                >
                    mirror.xyz
                </a>
                <a
                    href={`https://t.me/thd83`} target="_blank" rel="noopener noreferrer"
                    className="text-slate-500"
                >
                    telegram
                </a>
                <a
                    href={`https://github.com/7Cedars`} target="_blank" rel="noopener noreferrer"
                    className="text-slate-500"
                >
                    github
                </a>
            </div>
            </div>
        </div>
    </div> 
  </section>

  )
}