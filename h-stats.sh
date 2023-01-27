#!/usr/bin/env bash

format_khs(){
	case ${units,,} in
		ghs)
			khs=`echo $khs | awk '{ print $1*1000000 }'`
		;;
		mhs)
			khs=`echo $khs | awk '{ print $1*1000 }'`
		;;
		hs|gs|sols)
			khs=`echo $khs | awk '{ print $1/1000 }'`
			units="hs"
		;;
		*)
		units="hs"
	esac
}

format_algo(){
	case "$algo" in
		BEAM)
			algo="equihash 150/5/3"
			;;
		BEAM-I)
			algo="equihash 150/5"
			;;
		BEAM-II)
			algo="equihash 150/5/3"
			;;
		BEAM-III)
			algo="beamhashv3"
			;;
		EXCC)
			algo="equihash 144/5"
			;;
		MWC-C29|GRIN-C29M)
			algo="cuckoo"
			;;
		MWC-C31)
			algo="cuckootoo31"
			;;
		GRIN-C32)
			algo="cuckootoo32"
			;;
		ZEL)
			algo="equihash 125/4"
			;;
		*)
			algo=$(jq -r '.Mining.Algorithm' <<< $stats_raw)
			[[ $algo =~ "Autolykos" ]]      && algo="autolykos2"
			[[ $algo == "BeamHash III" ]]   && algo="beamhashv3"
			[[ $algo == "Cuckoo 29" ]]      && algo="cuckoo cycle"
			[[ $algo == "Cuckaroo 29-40" ]] && algo="cuckaroo29b"
			[[ $algo == "Cuckaroo 29-48" ]] && algo="cuckaroo29i"
			[[ $algo == "Cuckaroo 29-32" ]] && algo="cuckaroo29s"
			;;
	esac
	algo=`echo "$algo" | awk '{print tolower($0)}'`
}

stats_raw=`curl --connect-timeout 2 --max-time 5 --silent --noproxy '*' http://127.0.0.1:44445/summary`
#stats_raw=`cat /hive/miners/rigel/stats_raw`
if [[ $? -ne 0 || -z $stats_raw ]]; then
	echo -e "${YELLOW}Failed to read $miner from localhost:${MINER_API_PORT}${NOCOLOR}"
else
	local ver=`jq -c -r ".Software" <<< $stats_raw | awk '{ print $2 }'`
	dpkg --compare-versions "$ver" "lt" "1.43"
	if [ $? -eq "0" ]; then
		local fan=`jq '[.GPUs[]."Fan Speed (%)"]' <<< $stats_raw`
		local temp=`jq '[.GPUs[]."Temp (deg C)"]' <<< $stats_raw`
		local bus_numbers=`jq -r ".GPUs[].PCIE_Address" <<< $stats_raw | cut -f 1 -d ':' | jq -sc .`
		local algo=`jq -r '.Mining.Coin' <<< $stats_raw`
		format_algo

		units=`jq -c -r ".Session.Performance_Unit" <<< $stats_raw | tr -d "/"`
		khs=`jq -r '.Session.Performance_Summary' <<< $stats_raw`
		format_khs

		local Rejected=`jq -c -r ".Session.Submitted - .Session.Accepted" <<< $stats_raw`
		[[ $Rejected -lt 0 ]] && Rejected=0

		stats=$(jq --argjson temp "$temp" \
				--argjson fan "$fan" \
				--arg ver "$ver" \
				--argjson bus_numbers "$bus_numbers" \
				--arg algo "$algo" \
				--arg rej "$Rejected" \
				--arg units "$units" \
				--arg inv_all "$(jq '[.GPUs[].Session_HWErr] | add'  <<< $stats_raw)" \
				--arg inv_gpu "$(jq '.GPUs[].Session_HWErr' <<< $stats_raw | jq -cs '.' | sed  's/,/;/g' | tr -d [ | tr -d ])" \
				'{hs: [.GPUs[].Performance], hs_units: $units, $temp, $fan, uptime: .Session.Uptime, ar: [ .Session.Accepted, $rej, $inv_all, $inv_gpu ], $bus_numbers, algo: $algo, ver: $ver}' <<< "$stats_raw")
	else
		local fan=`jq '[.Workers[]."Fan_Speed"]' <<< $stats_raw`
		local temp=`jq '[.Workers[]."Core_Temp"]' <<< $stats_raw`
		local bus_numbers=`jq -r ".Workers[].PCIE_Address" <<< $stats_raw | cut -f 1 -d ':' | jq -sc .`

		algo=`jq -r '.Algorithms[0].Algorithm' <<< $stats_raw`
		units=`jq -c -r '.Algorithms[0].Performance_Unit' <<< $stats_raw | tr -d "/"`
		khs=`jq -r '.Algorithms[0].Total_Performance' <<< $stats_raw`
		format_khs

		local Accepted=`jq -c -r '.Algorithms[0].Total_Accepted' <<< $stats_raw`
		local Rejected=`jq -c -r '.Algorithms[0].Total_Rejected' <<< $stats_raw`
		local Invalid=`jq -c -r '.Algorithms[0].Total_Errors' <<< $stats_raw`
		local InvGPU=`jq '.Algorithms[0].Worker_Errors' <<< $stats_raw | jq -cs '.' | sed  's/,/;/g' | tr -d [ | tr -d ]`

		hs=`jq '.Algorithms[0].Worker_Performance' <<< $stats_raw`


		if [[ `jq '.Num_Algorithms' <<< $stats_raw` -le 1 ]]; then
			stats=$(jq --argjson temp "$temp" \
				--argjson fan "$fan" \
				--arg ver "$ver" \
				--argjson hs "$hs" \
				--argjson bus_numbers "$bus_numbers" \
				--arg algo "$algo" \
				--arg acc "$Accepted" \
				--arg rej "$Rejected" \
				--arg hs_units "${units,,}" \
				--arg inv "$Invalid" \
				--arg inv_gpu "$InvGPU" \
				'{$hs, $hs_units, $temp, $fan, uptime: .Session.Uptime, ar: [ $acc, $rej, $inv, $inv_gpu ], $bus_numbers, $algo, $ver}' <<< "$stats_raw")
		else
			algo1=$algo
			units1=${units,,}
			khs1=$khs

			algo=`jq -r '.Algorithms[1].Algorithm' <<< $stats_raw`
			units=`jq -c -r '.Algorithms[1].Performance_Unit' <<< $stats_raw | tr -d "/"`
			khs=`jq -r '.Algorithms[1].Total_Performance' <<< $stats_raw`
			format_khs
			algo2=$algo
			units2=${units,,}
			khs2=$khs
			khs=$khs1

			local Accepted2=`jq -c -r '.Algorithms[1].Total_Accepted' <<< $stats_raw`
			local Rejected2=`jq -c -r '.Algorithms[1].Total_Rejected' <<< $stats_raw`
			local Invalid2=`jq -c -r '.Algorithms[1].Total_Errors' <<< $stats_raw`
			local InvGPU2=`jq '.Algorithms[1].Worker_Errors' <<< $stats_raw | jq -cs '.' | sed  's/,/;/g' | tr -d [ | tr -d ]`

			hs2=`jq '.Algorithms[1].Worker_Performance' <<< $stats_raw`

			stats=$(jq --argjson temp "$temp" \
				--argjson fan "$fan" \
				--arg ver "$ver" \
				--argjson bus_numbers "$bus_numbers" \
				--arg total_khs "$khs1" \
				--argjson hs "$hs" \
				--arg hs_units "$units1" \
				--arg algo "$algo1" \
				--arg acc "$Accepted" \
				--arg rej "$Rejected" \
				--arg inv "$Invalid" \
				--arg inv_gpu "$InvGPU" \
				--arg total_khs2 "$khs2" \
				--argjson hs2 "$hs2" \
				--arg hs_units2 "$units2" \
				--arg algo2 "$algo2" \
				--arg acc2 "$Accepted2" \
				--arg rej2 "$Rejected2" \
				--arg inv2 "$Invalid2" \
				--arg inv_gpu2 "$InvGPU2" \
				'{$hs, $hs_units, $temp, $fan, uptime: .Session.Uptime, ar: [ $acc, $rej, $inv, $inv_gpu ], $bus_numbers, $algo, $ver,
				$hs2, $hs_units2, ar2: [ $acc2, $rej2, $inv2, $inv_gpu2 ], $algo2}' <<< "$stats_raw")
		fi

	fi
fi

[[ -z $khs ]] && khs=0
[[ -z $stats ]] && stats="null"
