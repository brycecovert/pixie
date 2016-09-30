(ns ncurses
  (:require [pixie.ffi-infer :refer :all]
            [pixie.ffi :as ffi]
            [pixie.time :refer [time]]
            [pixie.walk :as walk]
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

(defn update-score-window [window turns]
  (-> window
   (bewitch/render 0 0 "Score: 100")
   (bewitch/render 1 0 "HP: 20/20")
   (bewitch/render 2 0 "MP: 10/10")
   (bewitch/render 3 0 (str "Turns: " turns))))
(defn score-window []
  (update-score-window (bewitch/new-window 5 30 1 50)))


(let [scr (bewitch/init)]
  (loop [player player
         turns 0]
    
    (bewitch/with-window [score-win (bewitch/new-window 20 40 0 50)
                          play-win (bewitch/new-window 20 40 0 0)]
      (bewitch/do-refresh scr)
      (for [[y line] (map vector (range) game-map)]
        (for [[x c] (map vector (range) line)]
          (bewitch/render play-win y x c)))

      (bewitch/render play-win  (:y player) (:x player) (:renderable player))
      
      (update-score-window score-win turns))
    (condp = (bewitch/getch)
      bewitch/KEY_UP
      (recur (update-in player [:y] dec) (inc turns))

      bewitch/KEY_DOWN
      (recur (update-in player [:y] inc) (inc turns))

      bewitch/KEY_LEFT
      (recur (update-in player [:x] dec) (inc turns))

      bewitch/KEY_RIGHT
      (recur (update-in player [:x] inc) (inc turns))

      (int \q)
      nil
      
      (recur player (inc turns)))) 
  (bewitch/destroy scr))



