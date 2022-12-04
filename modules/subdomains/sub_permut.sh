#!/usr/bin/env bash

if { [ ! -f "$called_fn_dir/.${FUNCNAME[0]}" ] || [ "$DIFF" = true ]; } && [ "$SUBPERMUTE" = true ]; then
	start_subfunc ${FUNCNAME[0]} "Running : Permutations Subdomain Enumeration"
	if [ "$DEEP" = true ] || [ "$(cat subdomains/subdomains.txt | wc -l)" -le $DEEP_LIMIT ] ; then
		if [ "$PERMUTATIONS_OPTION" = "gotator" ] ; then
			[ -s "subdomains/subdomains.txt" ] && gotator -sub subdomains/subdomains.txt -perm $tools/permutations_list.txt $GOTATOR_FLAGS -silent 2>>"$LOGFILE" | head -c $PERMUTATIONS_LIMIT > .tmp/gotator1.txt
		else
			[ -s "subdomains/subdomains.txt" ] && ripgen -d subdomains/subdomains.txt -w $tools/permutations_list.txt 2>>"$LOGFILE" | head -c $PERMUTATIONS_LIMIT > .tmp/gotator1.txt
		fi
	elif [ "$(cat .tmp/subs_no_resolved.txt | wc -l)" -le $DEEP_LIMIT2 ]; then
		if [ "$PERMUTATIONS_OPTION" = "gotator" ] ; then
			[ -s ".tmp/subs_no_resolved.txt" ] && gotator -sub .tmp/subs_no_resolved.txt -perm $tools/permutations_list.txt $GOTATOR_FLAGS -silent 2>>"$LOGFILE" | head -c $PERMUTATIONS_LIMIT > .tmp/gotator1.txt
		else
			[ -s ".tmp/subs_no_resolved.txt" ] && ripgen -d .tmp/subs_no_resolved.txt -w $tools/permutations_list.txt 2>>"$LOGFILE" | head -c $PERMUTATIONS_LIMIT > .tmp/gotator1.txt
		fi
	else
		end_subfunc "Skipping Permutations: Too Many Subdomains" ${FUNCNAME[0]}
		return 1
	fi
	if [ ! "$AXIOM" = true ]; then
		resolvers_update_quick_local
		[ -s ".tmp/gotator1.txt" ] && puredns resolve .tmp/gotator1.txt -w .tmp/permute1.txt -r $resolvers --resolvers-trusted $resolvers_trusted -l $PUREDNS_PUBLIC_LIMIT --rate-limit-trusted $PUREDNS_TRUSTED_LIMIT --wildcard-tests $PUREDNS_WILDCARDTEST_LIMIT  --wildcard-batch $PUREDNS_WILDCARDBATCH_LIMIT 2>>"$LOGFILE" &>/dev/null
	else
		resolvers_update_quick_axiom
		[ -s ".tmp/gotator1.txt" ] && axiom-scan .tmp/gotator1.txt -m puredns-resolve -r /home/op/lists/resolvers.txt --resolvers-trusted /home/op/lists/resolvers_trusted.txt --wildcard-tests $PUREDNS_WILDCARDTEST_LIMIT --wildcard-batch $PUREDNS_WILDCARDBATCH_LIMIT -o .tmp/permute1.txt $AXIOM_EXTRA_ARGS 2>>"$LOGFILE" &>/dev/null
	fi		
	if [ "$PERMUTATIONS_OPTION" = "gotator" ] ; then
		[ -s ".tmp/permute1.txt" ] && gotator -sub .tmp/permute1.txt -perm $tools/permutations_list.txt $GOTATOR_FLAGS -silent 2>>"$LOGFILE" | head -c $PERMUTATIONS_LIMIT > .tmp/gotator2.txt
	else
		[ -s ".tmp/permute1.txt" ] && ripgen -d .tmp/permute1.txt -w $tools/permutations_list.txt 2>>"$LOGFILE" | head -c $PERMUTATIONS_LIMIT > .tmp/gotator2.txt
	fi
	if [ ! "$AXIOM" = true ]; then
		[ -s ".tmp/gotator2.txt" ] && puredns resolve .tmp/gotator2.txt -w .tmp/permute2.txt -r $resolvers --resolvers-trusted $resolvers_trusted -l $PUREDNS_PUBLIC_LIMIT --rate-limit-trusted $PUREDNS_TRUSTED_LIMIT --wildcard-tests $PUREDNS_WILDCARDTEST_LIMIT  --wildcard-batch $PUREDNS_WILDCARDBATCH_LIMIT 2>>"$LOGFILE" &>/dev/null
	else
		[ -s ".tmp/gotator2.txt" ] && axiom-scan .tmp/gotator2.txt -m puredns-resolve -r /home/op/lists/resolvers.txt --resolvers-trusted /home/op/lists/resolvers_trusted.txt --wildcard-tests $PUREDNS_WILDCARDTEST_LIMIT --wildcard-batch $PUREDNS_WILDCARDBATCH_LIMIT -o .tmp/permute2.txt $AXIOM_EXTRA_ARGS 2>>"$LOGFILE" &>/dev/null
	fi
	cat .tmp/permute1.txt .tmp/permute2.txt 2>>"$LOGFILE" | anew -q .tmp/permute_subs.txt
	if [ -s ".tmp/permute_subs.txt" ]; then
		deleteOutScoped $outOfScope_file .tmp/permute_subs.txt
		[[ "$INSCOPE" = true ]] && check_inscope .tmp/permute_subs.txt 2>>"$LOGFILE" &>/dev/null
		NUMOFLINES=$(cat .tmp/permute_subs.txt 2>>"$LOGFILE" | grep ".$domain$" | anew subdomains/subdomains.txt | sed '/^$/d' | wc -l)
	else
		NUMOFLINES=0
	fi
	end_subfunc "${NUMOFLINES} new subs (permutations)" ${FUNCNAME[0]}
else
	if [ "$SUBPERMUTE" = false ]; then
		printf "\n${yellow} ${FUNCNAME[0]} skipped in this mode or defined in reconftw.cfg ${reset}\n"
	else
		printf "${yellow} ${FUNCNAME[0]} is already processed, to force executing ${FUNCNAME[0]} delete\n    $called_fn_dir/.${FUNCNAME[0]} ${reset}\n\n"
	fi
fi