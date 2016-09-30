(ns ncurses
  (:require [pixie.ffi-infer :refer :all]
            [pixie.ffi :as ffi]
            [pixie.time :refer [time]]))

(with-config {:library "ncurses"
              :cxx-flags ["-I/usr/local/Cellar/ncurses/6.0_2/include/ -DGCC_PRINTF"]
              :includes ["ncurses.h"]}
  (defconst COLOR_BLACK)
  (defconst COLOR_RED)
  (defconst COLOR_GREEN)
  (defconst COLOR_YELLOW)
  (defconst COLOR_BLUE)	
  (defconst COLOR_MAGENTA)	
  (defconst COLOR_CYAN)	
  (defconst COLOR_WHITE)
  (defcfn initscr)
  (defcfn addch)
  (defcfn attron)
  (defcfn refresh)
  (defcfn getch)
  (defcfn init_pair)
  (defcfn start_color)
  (defcfn move)
  (defcfn addstr)
  (defcfn endwin))

(def game-map-input ["#### ######## "
                     "#..# #......# "
                     "#..###...$..##"
                     "#........... #"
                     "#..###......# "
                     "#..# #......# "
                     "#### ######## "])

(def game-map (mapv (fn [l]
                      (mapv (fn [c]
                              (condp = c
                                \# {:char \# :color [:red :black]}
                                \. {:char \. :color [:green :black]}
                                
                                c))
                            l))
                   game-map-input))

(defprotocol IRenender
  (do-render [this]))

(extend-protocol IRender PersistentHashMap
                 (do-render [this]
                   (attron (colors (:color this)))
                   (addch (int (:char this)))))

(extend-protocol IRender Character
                 (do-render [this]
                   (addch (int this))))
(def color-map {:black COLOR_BLACK 
                :red COLOR_RED 
                :green COLOR_GREEN 
                :yellow COLOR_YELLOW 
                :blue COLOR_BLUE 
                :magenta COLOR_MAGENTA 
                :cyan COLOR_CYAN 
                :white COLOR_WHITE })



(initscr)
(start_color)
(def colors
  (loop [[fg & fgs] (keys color-map)
         i 0
         color-number {}]
    (if fg
      (let [[i color-number ]
            (loop [[bg & bgs] (keys color-map) i i color-number color-number]
              (cond (not bg)
                    [i color-number ]

                    :else
                    (do
                      (init_pair (inc i) (color-map fg) (color-map bg))
                      (recur bgs (inc i) (assoc color-number [fg bg] (* 256 (inc i)))))))]
        (recur fgs i color-number))

      color-number)))

(for [[y line] (map vector (range) game-map)]
  (for [[x c] (map vector (range) line)]
    
    (move y x)
    (do-render c)))

(refresh)
(getch)
(endwin)
