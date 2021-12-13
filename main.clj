;;convert not to nor
(defn convert-not [exp]
 ;;split the expression
	(let [expression (rest exp)]
	;;make a new list, put nor in beginning
		(distinct (conj expression 'nor))
		))

;;now convert or to nor
(defn convert-or [exp]
;;split the expression
(let [expression (rest exp)]
;;(nor x y)
	(let [list1 (conj expression 'nor)]
	;;(_ nor x y)
	  (let [list2 (conj list1 '_)]
		;;((nor x y))
		  (let [list3 (list (rest list2))]
			;;(nor(nor x y))
			(conj list3 'nor))
		))))

		(defn convert-and [exp]
		;;we only want the variables (x,y,etc)
		  (let [expression (rest exp)] 
			;;make every element a list
				 (let [list2 (map list expression)]
				 ;;puts nor in the beginning of all the lists
	          (let [list3 (map (fn[i](conj i 'nor))list2)]
						;;put nor at the beginning of the entire list
						(conj list3 'nor)
							 ))))