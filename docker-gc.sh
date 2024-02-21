#!/bin/bash
set -e
set -o noglob


TMP_DIR=

# --- helper functions for logs ---
info()
{
    echo '[INFO] ' "$@"
}
debug()
{
	echo '[DEBUG] ' "$@"
}
warn()
{
	echo '[WARN] ' "$@" >&2
}
fatal()
{
	echo '[ERROR] ' "$@" >&2
	exit 1
}

setup() {
	TMP_DIR=$(mktemp -d -t docker-gc.XXXXXXXXXX)
	
	touch ${TMP_DIR}/containers.reap
	touch ${TMP_DIR}/images.reap
	touch ${TMP_DIR}/volumes.reap
	
	cleanup() {
		code=$?
		set +e
		trap - EXIT
		rm -rf ${TMP_DIR}
		exit $code
	}
	trap cleanup INT EXIT

}

allowed_commands() {
	warn 'Only available commands are:'
	warn '--purge-all'

}

get_disk_size() {
	CURRENTUSAGEPERCENT=$(df -h / | awk 'NR==2 {print $5}' | sed 's/%//')
	CURRENTUSAGE=$(df -h / | awk 'NR==2 {print $3}')
	TOTAL=$(df -h / | awk 'NR==2 {print $2}')

	info "${CURRENTUSAGE}/${TOTAL} / $CURRENTUSAGEPERCENT%"

}

get_disk_size_bytes() {
	local result=$(df -B1 --output=used . | awk 'NR==2 {print $1}')

	echo $result

}

get_all_containers() {
	# get all
	local result=$(docker ps -a -q --no-trunc | sort | uniq )

	echo $result

}

get_all_images() {
	local result=$(docker images --no-trunc --format "{{.ID}}")

	echo $result

}

get_all_volumes() {
	local result=$(docker volume ls --filter "dangling=true" -q)

	echo $result
}

remove_containers() {
	xargs -n 1 docker rm -f --volumes=true < ${TMP_DIR}/containers.reap &>/dev/null || true

}

remove_images() {
	xargs -n 1 docker rmi -f < ${TMP_DIR}/images.reap &>/dev/null || true
}

remove_volumes() {
	xargs -n 1 docker volume rm < ${TMP_DIR}/volumes.reap &>/dev/null || true
}

purge_all() {
	read -p "This is going to destroy everything, are you sure? (yes/no): " response

	if [[ $response == "no" ]]; then
		info "Phew! Disaster averted. Exiting..."
		exit 0
	elif [[ "$response" != "yes" ]]; then
		warn "Invalid response. Please enter 'yes' or 'no'."
		exit 0
	fi

	setup

	local before_cleanup=$(get_disk_size_bytes)
	info "Disk size before cleanup"
	get_disk_size

	get_all_containers > ${TMP_DIR}/containers.reap
	get_all_images > ${TMP_DIR}/images.reap
	get_all_volumes > ${TMP_DIR}/volumes.reap

	remove_containers
	remove_images
	remove_volumes

	docker system prune -a -f &>/dev/null
	docker builder prune -a -f &>/dev/null

	info "Disk size after cleanup"
	get_disk_size

	local after_cleanup=$(get_disk_size_bytes)
	local difference=$((before_cleanup - after_cleanup))


	if [[ $difference -gt 0 ]]; then
		local saved=$(numfmt --to=iec-i --suffix=B --format='%.1f' $difference)

		info "You saved ${saved}"
	else
		info "Nothing to cleanup"

	fi
}

entrypoint() {
	case "$1" in
		(-*)
		case "$1" in
			--purge-all) purge_all "$@";;
			*)
				allowed_commands
		esac
		;;
		"")
			allowed_commands
			;;
		*)
	esac

}

{
	entrypoint "$@"
}