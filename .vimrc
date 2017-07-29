set nocompatible
set autoindent
set expandtab
set shiftwidth=4
set softtabstop=4
set showmatch
set ruler
set nohls
set incsearch
syntax on

" Set the color scheme
colorscheme slate

" Display line numbers
set number

" Copy to the system clipboard:w
set clipboard=unnamed

" Remove toolbar
set guioptions-=T

" Set the font
if has("gui_running")
  if has("gui_win32")
    set guifont=Consolas:h8:cANSI
  elseif has("gui_gtk2")
    set guifont=Inconsolata\ 8
  endif
endif

" Restore screen size and position
" Saves data in a separate file, and so works with multiple instances of Vim.
if has("gui_running")
  function! ScreenFilename()
    if has('win32')
      return $HOME.'\_vimsize'
    else
      return $HOME.'/.vimsize'
    endif
  endfunction

  function! ScreenRestore()
    " - Remembers and restores winposition, columns and lines stored in
    "   a .vimsize file
    " - Must follow font settings so that columns and lines are accurate
    "   based on font size.
    if !has("gui_running")
      return
    endif
    if g:screen_size_restore_pos != 1
      return
    endif
    let vim_instance = (g:screen_size_by_vim_instance==1?(v:servername):'GVIM')
    " read any existing variables from .vimsize file
    silent! execute "sview " . escape(ScreenFilename(),'%#\ $')
    silent! execute "0/^" . vim_instance . " /"
    let vim_name  = matchstr(getline('.'), '^\w\+')
    let vim_cols  = matchstr(getline('.'), '^\w\+\s\+\zs\d\+')
    let vim_lines = matchstr(getline('.'), '^\w\+\s\+\d\+\s\+\zs\d\+')
    let vim_posx  = matchstr(getline('.'), '^\w\+\s\+\d\+\s\+\d\+\s\+\zs\d\+')
    let vim_posy  = matchstr(getline('.'), '^\w\+\s\+\d\+\s\+\d\+\s\+\d\+\s\+\zs\d\+')
    if vim_name == vim_instance
      execute "set columns=".vim_cols
      execute "set lines=".vim_lines
      silent! execute "winpos ".vim_posx." ".vim_posy
    endif
    silent! q
  endfunction

  function! ScreenSave()
    " used on exit to retain window position and size
    if !has("gui_running")
      return
    endif
    if !g:screen_size_restore_pos
      return
    endif
    let vim_instance = (g:screen_size_by_vim_instance==1?(v:servername):'GVIM')
    silent! execute "split " . escape(ScreenFilename(),'%#\ $')
    silent! execute "0/^" . vim_instance . " /"
    let vim_name  = matchstr(getline('.'), '^\w\+')
    if vim_name == vim_instance
      delete _
    endif
    $put = vim_instance . ' ' . &columns . ' ' . &lines . ' ' .
          \ (getwinposx()<0?0:getwinposx()) . ' ' .
          \ (getwinposy()<0?0:getwinposy())
    silent! x!
  endfunction

  if !exists('g:screen_size_restore_pos')
    let g:screen_size_restore_pos = 1
  endif
  if !exists('g:screen_size_by_vim_instance')
    let g:screen_size_by_vim_instance = 1
  endif
  autocmd VimEnter * call ScreenRestore()
  autocmd VimLeavePre * call ScreenSave()
endif

" Tell vim to remember certain things when we exit
"  '10 : marks will be remembered for up to 10 previously edited files
"  "100 : will save up to 100 lines for each register
"  :20 : up to 20 lines of command-line history will be remembered
"  % : saves and restores the buffer list
"  n... : where to save the viminfo files
if has('win32')
  set viminfo='10,\"100,:20,%,n~/_viminfo
else
  set viminfo='10,\"100,:20,%,n~/.viminfo
endif

" Change the color scheme from a list of color scheme names.
" Version 2010-09-12 from http://vim.wikia.com/wiki/VimTip341
" Press key:
"   F8                next scheme
"   Shift-F8          previous scheme
"   Alt-F8            random scheme
" Set the list of color schemes used by the above (default is 'all'):
"   :SetColors all              (all $VIMRUNTIME/colors/*.vim)
"   :SetColors my               (names built into script)
"   :SetColors blue slate ron   (these schemes)
"   :SetColors                  (display current scheme names)
" Set the current color scheme based on time of day:
"   :SetColors now
if v:version < 700 || exists('loaded_setcolors') || &cp
  finish
endif

let loaded_setcolors = 1
let s:mycolors = ['slate', 'evening', 'torte', 'darkblue', 'delek', 'murphy', 'elflord', 'pablo', 'koehler']  " colorscheme names that we use to set color

" Set list of color scheme names that we will use, except
" argument 'now' actually changes the current color scheme.
function! s:SetColors(args)
  if len(a:args) == 0
    echo 'Current color scheme names:'
    let i = 0
    while i < len(s:mycolors)
      echo '  '.join(map(s:mycolors[i : i+4], 'printf("%-14s", v:val)'))
      let i += 5
    endwhile
  elseif a:args == 'all'
    let paths = split(globpath(&runtimepath, 'colors/*.vim'), "\n")
    let s:mycolors = map(paths, 'fnamemodify(v:val, ":t:r")')
    echo 'List of colors set from all installed color schemes'
  elseif a:args == 'my'
    let c1 = 'default elflord peachpuff desert256 breeze morning'
    let c2 = 'darkblue gothic aqua earth black_angus relaxedgreen'
    let c3 = 'darkblack freya motus impact less chocolateliquor'
    let s:mycolors = split(c1.' '.c2.' '.c3)
    echo 'List of colors set from built-in names'
  elseif a:args == 'now'
    call s:HourColor()
  else
    let s:mycolors = split(a:args)
    echo 'List of colors set from argument (space-separated names)'
  endif
endfunction

command! -nargs=* SetColors call <SID>SetColors('<args>')

" Set next/previous/random (how = 1/-1/0) color from our list of colors.
" The 'random' index is actually set from the current time in seconds.
" Global (no 's:') so can easily call from command line.
function! NextColor(how)
  call s:NextColor(a:how, 1)
endfunction

" Helper function for NextColor(), allows echoing of the color name to be
" disabled.
function! s:NextColor(how, echo_color)
  if len(s:mycolors) == 0
    call s:SetColors('all')
  endif
  if exists('g:colors_name')
    let current = index(s:mycolors, g:colors_name)
  else
    let current = -1
  endif
  let missing = []
  let how = a:how
  for i in range(len(s:mycolors))
    if how == 0
      let current = localtime() % len(s:mycolors)
      let how = 1  " in case random color does not exist
    else
      let current += how
      if !(0 <= current && current < len(s:mycolors))
        let current = (how>0 ? 0 : len(s:mycolors)-1)
      endif
    endif
    try
      execute 'colorscheme '.s:mycolors[current]
      break
    catch /E185:/
      call add(missing, s:mycolors[current])
    endtry
  endfor
  redraw
  if len(missing) > 0
    echo 'Error: colorscheme not found:' join(missing)
  endif
  if (a:echo_color)
    echo g:colors_name
  endif
endfunction

nnoremap <F8> :call NextColor(1)<CR>
nnoremap <S-F8> :call NextColor(-1)<CR>
nnoremap <A-F8> :call NextColor(0)<CR>

" Set color scheme according to current time of day.
function! s:HourColor()
  let hr = str2nr(strftime('%H'))
  if hr <= 3
    let i = 0
  elseif hr <= 7
    let i = 1
  elseif hr <= 14
    let i = 2
  elseif hr <= 18
    let i = 3
  else
    let i = 4
  endif
  let nowcolors = 'elflord morning desert evening pablo'
  execute 'colorscheme '.split(nowcolors)[i]
  redraw
  echo g:colors_name
endfunction
