type TitleTextProps = {
  title?: string; 
  subtitle?: string;
  size?: 0 | 1 | 2;
}

type SectionTextProps = {
  text?: string; 
  subtext?: string;
  size?: 0 | 1 | 2;
}

type NoteTextProps = {
  message: string; 
  size?: 0 | 1 | 2; 
  align?: 0 | 1 | 2;
}

const appearanceTitle = [
  "text-md py-0",
  "text-lg py-0",
  "text-2xl py-1"
]

const appearanceSubtitle = [
  "text-sm",
  "text-md",
  "text-lg"
]

const appearanceNote = [
  "text-xs",
  "text-md",
  "text-lg"
]

const alignText = [
  "text-start",
  "text-center",
  "text-end"
]

export const TitleText = ({
  title, 
  subtitle, 
  size = 1
}: TitleTextProps) => {
  // Subtle, modern section label style
  return (
    <div className="flex flex-col items-start w-full my-4">
      <div className={`font-semibold break-words text-left ${size === 2 ? 'text-xl md:text-2xl' : size === 1 ? 'text-lg' : 'text-base'} text-slate-800 mb-0.5`}>
        {title}
      </div>
      {subtitle && (
        <div className={`text-slate-500 break-words text-left ${size === 2 ? 'text-base md:text-lg' : size === 1 ? 'text-sm' : 'text-xs'} mb-1 tracking-tight`}>
          {subtitle}
        </div>
      )}
      {/* <div className="w-10 h-0.5 bg-slate-200 rounded mt-1 mb-2" /> */}
    </div>
  );
};

export const SectionText = ({
  text, 
  subtext, 
  size = 1
}: SectionTextProps) => {
  return (
    <div className="grid grid-cols-1">
      <div className={`text-start font-bold break-words ${appearanceTitle[size]}`}>
        {text}
      </div>
      <div className={`text-start text-slate-500 break-words ${appearanceSubtitle[size]}` }>
        {subtext}
      </div>
    </div>
  );
};

export const NoteText = ({
  message, 
  size = 1,
  align = 0
}: NoteTextProps) => {
  return (
    <div className={`grid grid-cols-1 px-2 gap-1 break-words text-gray-500 font-sm`}>
      <div className={`${alignText[align]} italic  ${appearanceNote[size]}`}>
        {message}
      </div>
    </div>
  );
};