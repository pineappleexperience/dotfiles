#!/usr/bin/env bash
# Registers the newest installed JDK of each major version with mise (java@11, java@17, ...), so mise uses the
# JDKs of macOS (/Library/Java/JavaVirtualMachines, ~/Library/Java/JavaVirtualMachines) instead of downloading.

/usr/libexec/java_home -V 2>&1 | awk '/^ +[0-9]/ { print $1, $NF }' | while read -r version home; do
	major="${version%%.*}"
	[[ "$major" == "1" ]] && major="$(cut -d. -f2 <<<"$version")"
	# java_home lists the newest version of each major first
	if [[ -z "${linked[$major]}" ]]; then
		mise link --force "java@$major" "$home" && echo "java@$major -> $home"
		linked[$major]=1
	fi
done
