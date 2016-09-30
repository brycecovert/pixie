(ns ncurses
  (:require [pixie.ffi-infer :refer :all]
            [pixie.ffi :as ffi]
            [pixie.time :refer [time]]
            [bewitch :as bewitch]))



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


(def player {:x 1 :y 1 :renderable {:color [:blue :black] :char "@"}})

(defn update-score-window [window]
  (bewitch/render window 0 0 "Score: 100")
  (bewitch/render window 1 0 "HP: 20/20")
  (bewitch/render window 2 0 "MP: 10/10")
  (bewitch/do-refresh window)
  window)
(defn score-window []
  (update-score-window (bewitch/new-window 5 30 1 50)))

(let [scr (bewitch/init)
      play-win (bewitch/new-window 20 40 0 0)
      ]
  (loop [player player]
    (for [[y line] (map vector (range) game-map)]
      (for [[x c] (map vector (range) line)]
        (bewitch/render play-win y x c)))

    (bewitch/render play-win  (:y player) (:x player) (:renderable player))
    (bewitch/do-refresh scr)
    (bewitch/do-refresh play-win)
    (score-window)

    
    (condp = (bewitch/getch)
      bewitch/KEY_UP
      (recur (update-in player [:y] dec))

      bewitch/KEY_DOWN
      (recur (update-in player [:y] inc))

      bewitch/KEY_LEFT
      (recur (update-in player [:x] dec))

      bewitch/KEY_RIGHT
      (recur (update-in player [:x] inc))

      (int \q)
      nil
      
      (recur player)))
  (bewitch/destroy play-win)
  (bewitch/destroy scr))



