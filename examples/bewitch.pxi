(ns bewitch
  (:require [pixie.ffi-infer :refer :all]
            [pixie.ffi :as ffi]
            [pixie.time :refer [time]]))

(with-config {:library "ncurses"
              :cxx-flags ["-I/usr/local/Cellar/ncurses/6.0_2/include/ -DGCC_PRINTF"]
              :includes ["ncurses.h"]}
  (defconst KEY_ENTER)
  (defconst KEY_LEFT)
  (defconst KEY_RIGHT)
  (defconst KEY_UP)
  (defconst KEY_DOWN)
  (defconst COLOR_BLACK)
  (defconst COLOR_RED)
  (defconst COLOR_GREEN)
  (defconst COLOR_YELLOW)
  (defconst COLOR_BLUE)	
  (defconst COLOR_MAGENTA)	
  (defconst COLOR_CYAN)	
  (defconst COLOR_WHITE)
  (defglobal stdscr)
  (defcfn initscr)
  (defcfn usleep)
  (defcfn addch)
  (defcfn waddch)
  (defcfn nonl)
  (defcfn keypad)
  (defcfn clear)
  (defcfn cbreak)
  (defcfn nocbreak)
  (defcfn curs_set)
  (defcfn newwin)
  (defcfn box)
  (defcfn attron)
  (defcfn wattron)
  (defcfn werase)
  (defcfn erase)
  (defcfn refresh)
  (defcfn wrefresh)
  (defcfn noecho)
  (defcfn echo)
  (defcfn getch)
  (defcfn delwin)
  (defcfn init_pair)
  (defcfn start_color)
  (defcfn move)
  (defcfn wmove)
  (defcfn addstr)
  (defcfn waddstr)
  (defcfn endwin))

(def color->ncurses {:black COLOR_BLACK 
                     :red COLOR_RED 
                     :green COLOR_GREEN 
                     :yellow COLOR_YELLOW 
                     :blue COLOR_BLUE 
                     :magenta COLOR_MAGENTA 
                     :cyan COLOR_CYAN 
                     :white COLOR_WHITE })

(def color-pairs
  (for [fg (keys color->ncurses)
        bg (keys color->ncurses)]
    [fg bg]))

(def colors
  (into {}
        (for [[i pair] (map vector (range) color-pairs)]
          [pair (* 256 (inc i))]) ))

(defprotocol IWritable
  (do-clear [this])
  (render [this y x thing])
  (do-refresh [this]))

(defprotocol IDestroyable
  (destroy [this]))

(deftype Screen [scr]
  IWritable
  (do-clear [this]
    (erase))
  (render [this y x thing]
    (move (inc y) (inc x))
    (cond (char? thing)
          (addch (int thing))

          (string? thing)
          (addstr thing)

          (map? thing)
          (do
            (when-let [color (:color thing)]
              (attron (colors color)))
            (render this y x (or (:string thing)
                                 (:char thing))))

          :else
          nil)
    this)
  (do-refresh [this]
    (refresh))

  IDestroyable
  (destroy [this]
    (nocbreak)
    (clear)
    (keypad scr 0)
    (echo)
    (endwin)))

(deftype Window [win]
  
  IWritable
  (do-clear [this]
    (werase win))
  (render [this y x thing]
    (wmove win (inc y) (inc x))
    (cond (char? thing)
          (waddch win (int thing))

          (string? thing)
          (waddstr win thing)

          (map? thing)
          (do
            (when-let [color (:color thing)]
              (wattron win (colors color)))
            (render this y x (or (:string thing)
                                 (:char thing))))

          :else
          nil)
    this)
  (do-refresh [this]
    (wrefresh win))

  IDestroyable
  (destroy [this]
    
    (delwin win)))

(defn init []
  (let [scr (initscr)]
    (keypad scr 1)
    (clear)
    (start_color)
    (noecho)
    (curs_set 0)
    (cbreak)
    (nonl)
    (doseq [[i [fg bg]] (map vector (range) color-pairs)]
      (init_pair (inc i) (color->ncurses fg) (color->ncurses bg)))
    (->Screen scr)))

(defn new-window [height width y x]
  (let [win (newwin height width y x)
        window (->Window win)]
    (box win 0 0)
    window))

(defmacro with-window [binding & forms]
  (let [first-binding (into [] (take 2 binding))]
    (if (seq first-binding)
      `(let ~first-binding
         (try
           (with-window ~(drop 2 binding) ~@forms) 
           (do-refresh ~(first first-binding))
           (destroy ~(first first-binding))
           (catch ex (destroy ~(first first-binding)))))
      `(do ~@forms))))


