#==============================================================================
# This module adds support for the ECMA-48 SGR (Set Graphics Rendition) escape
# sequence `ESC [ <parameters> m' that allows to set display attributes. For
# more information on most of these escape sequences please consult the man
# page on Linux console escape and control sequences - `man 4 console_codes'
# (except for those described as rarely implemented)
#==============================================================================
module ECMA48SGR

On = { '*'             => "\033[1m", # bold
       'bold'          => "\033[1m",
       'half-bright'   => "\033[2m",
       '/'             => "\033[3m", # rarely implemented
       'italic'        => "\033[3m", # rarely implemented
       '_'             => "\033[4m", # underline
       'underline'     => "\033[4m",
       'underscore'    => "\033[4m", # Same as above
       'blink'         => "\033[5m",
       'rapid blink'   => "\033[6m", # rarely implemented
       'reverse video' => "\033[7m",
       'concealed'     => "\033[8m",
       'strikethrough' => "\033[9m"  # rarely implemented
     }

Off = { '*'             => "\033[22m", # normal intensity
        'bold'          => "\033[22m", # normal intensity
        'half-bright'   => "\033[22m", # normal intensity
        '/'             => "\033[23m", # rarely implemented
        'italic'        => "\033[23m", # rarely implemented
        '_'             => "\033[24m", # underline
        'underline'     => "\033[24m",
        'underscore'    => "\033[24m",
        'blink'         => "\033[25m",
        'rapid blink'   => "\033[26m", # rarely implemented
        'reverse video' => "\033[27m",
        'concealed'     => "\033[28m",
        'strikethrough' => "\033[29m"  # rarely implemented
      }

Std = { 'all'         => "\033[0m",  # Reset of all attributes
        'background'  => "\033[49m", # default background
        'bg'          => "\033[49m", # default background
        'fg'          => "\033[39m", # default forground, no underscore
        'fg_'         => "\033[38m", # default forground but underscore
        'foreground'  => "\033[39m", # default forground, no underscore
        'foreground_' => "\033[38m", # default forground but underscore
        'intensity'   => "\033[22m"  # normal intensity
      }

  Fg = { 'black'    => "\033[30m", # black   foreground
         'blue'     => "\033[34m", # blue    foreground
         'brown'    => "\033[33m", # brown   foreground
         'cyan'     => "\033[36m", # cyan    foreground
         'default'  => "\033[39m", # default foreground, no underscore
         'default_' => "\033[38m", # default foreground but underscore
         'green'    => "\033[32m", # green   foreground
         'magenta'  => "\033[35m", # magenta foreground
         'red'      => "\033[31m", # red     foreground
         'std'      => "\033[39m", # default foreground, no underscore
         'std_'     => "\033[38m", # default foreground but underscore
         'white'    => "\033[37m"  # white   foreground
       }

  # Sets background color
  Bg = { 'black'   => "\033[40m", # black   background
         'blue'    => "\033[44m", # blue    background
         'brown'   => "\033[43m", # brown   background
         'cyan'    => "\033[46m", # cyan    background
         'default' => "\033[49m", # default background
         'green'   => "\033[42m", # green   background
         'magenta' => "\033[45m", # magenta background
         'red'     => "\033[41m", # red     background
         'std'     => "\033[49m", # default background
         'white'   => "\033[47m"  # white   background
       }
end
