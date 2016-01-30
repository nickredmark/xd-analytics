intervalIdString = (interval) ->
	$concat: [
			# year
			$substr: [
					$year: "$date"
				, 0, 4 ]
		,
			# month
			$cond: [
					$lte: [
							$month: "$date"
						, 9 ]
				,
					$concat: [
							"0"
						,
							$substr: [
									$month: "$date"
								, 0, 2 ]
						]
				,
					$substr: [
							$month: "$date"
						, 0, 2 ]
				]
		,
			# date
			$cond: [
					$lte: [
							$dayOfMonth: "$date"
						, 9 ]
				,
					$concat: [
							"0"
						,
							$substr: [
									$dayOfMonth: "$date"
								, 0, 2 ]
						]
				,
					$substr: [
							$dayOfMonth: "$date"
						, 0, 2 ]
				]
		,
			# hour
			$cond: [
					$lte: [
							$hour: "$date"
						, 9 ]
				,
					$concat: [
							"0"
						,
							$substr: [
									$hour: "$date"
								, 0, 2 ]
						]
				,
					$substr: [
							$hour: "$date"
						, 0, 2 ]
				]
		,
			# interval
			$cond: [
					$lte: [
							$subtract: [
									$minute: "$date"
								,
									$mod: [
											$minute: "$date"
										, interval ]
								]
						, 9 ]
				,
					$concat: [ "0",
							$substr: [
									$subtract: [
											$minute: "$date"
										,
											$mod: [
													$minute: "$date"
												, interval ]
										]
								, 0, 2]
						]
				,
					$substr: [
							$subtract: [
									$minute: "$date"
								,
									$mod: [
											$minute: "$date"
										, interval ]
								]
						, 0, 2]
				]
		]

@preprocessLogs = (appId, from, to) ->
	return
	threshold = 1000 * 60 * 5 # 5 minutes
	logs = Logs.find
		appId: appId
		date:
			$exists: false
	count = logs.count()
	if count
		log count
		i = 0
		logs.forEach (l) ->
			if Math.abs(l.createdAt - l.loggedAt) > threshold
				date = l.createdAt
			else
				date = l.loggedAt
			Logs.update l._id,
				$set:
					date: date
			if i % 1000 is 0
				log i
			i++
