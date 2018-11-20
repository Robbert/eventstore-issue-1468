#!/bin/bash -ex

set -ex

EVENTSTORE_USER="${EVENTSTORE_USER:-admin}"
EVENTSTORE_PASS="${EVENTSTORE_PASS:-changeit}"
EVENTSTORE_URL="${EVENTSTORE_URL:-http://localhost:2113/}"

health_check() {
  curl --fail "${EVENTSTORE_URL}info" > /dev/null
}

wait_for_eventstore() {
    local interval=1
    local retries=$1
    local attempt=1

    while (( attempt < retries ))
    do
        echo "EventStore health check (attempt ${attempt} of ${retries})"
        if (( attempt == retries ))
        then
            echo "Waiting for healthy EventStore failed"
            break
        fi

        if health_check
        then
            echo "EventStore is up"
            attempt=$(( retries + 1 ))
            break
        fi

        attempt=$(( attempt + 1 ))
        sleep $interval
    done
}

projection_exists() {
  local name="$1"

  curl --fail "${EVENTSTORE_URL}projection/${name}/query" > /dev/null
}

upload_projection() {
  local name="$1"
  local path="$2"

  if ! test -f "${path}"
  then
    echo "File not found: ${path}"
    exit 1
  fi

  # if projection_exists "${name}"
  # then
    # Overwrite
    # curl --fail --silent -X PUT -u "${EVENTSTORE_USER}:${EVENTSTORE_PASS}" -d "@${path}" \
    #   "${EVENTSTORE_URL}projection/${name}/query?type=js&enabled=true&emit=true" > /dev/null
  # else
    # Add
    curl --fail --silent -i -u "${EVENTSTORE_USER}:${EVENTSTORE_PASS}" -d "@${path}" \
      "${EVENTSTORE_URL}projections/continuous?name=${name}&type=js&enabled=true&emit=true&trackemittedstreams=false" > /dev/null
  # fi
}

enable_projection() {
  local name="$1"
  curl --silent --fail -X POST \
    -u "${EVENTSTORE_USER}:${EVENTSTORE_PASS}" \
    -d '{}' \
    "${EVENTSTORE_URL}projection/${name}/command/enable" > /dev/null
}

disable_projection() {
  local name="$1"
  curl --silent --fail -X POST \
    -u "${EVENTSTORE_USER}:${EVENTSTORE_PASS}" \
    -d '{}' \
    "${EVENTSTORE_URL}projection/${name}/command/disable" > /dev/null
}

set_metadata() {
  local stream="$1"
  local path="$2"
  local eventType="\$meta-updated"

  if ! test -f "${path}"
  then
    echo "File not found: ${path}"
    exit 1
  fi

  curl --fail --silent -i \
    --header "ES-EventId: $(uuidgen)" \
    --header 'Content-Type: application/json; charset=UTF-8' \
    -d "@${path}" \
    "${EVENTSTORE_URL}streams/${stream}/metadata" > /dev/null
}

append_event() {
  local stream="$1"
  local eventType="$2"
  local data="$3"

  curl --fail --silent -i \
    --header "ES-EventId: $(uuidgen)" \
    --header "ES-EventType: ${eventType}" \
    --header 'Content-Type: application/json; charset=UTF-8' \
    -d "${data}" \
    "${EVENTSTORE_URL}streams/${stream}" > /dev/null
}

append_events() {
  local stream="$1"
  local eventType="$2"
  local count="$3"

  for i in $(seq 0 "${count}")
  do
    append_event "$1" "$2" "$i"
  done
}

scavenge() {
  curl --silent --fail -X POST \
    -u "${EVENTSTORE_USER}:${EVENTSTORE_PASS}" \
    -d '{}' \
    "${EVENTSTORE_URL}admin/scavenge" > /dev/null
}

wait_for_eventstore 60

upload_projection 'example' 'src/example.projection.js'

set_metadata 'example-stream' 'data/example-stream.metadata.json'

for i in $(seq 0 42)
do
  append_events 'example-stream' 'message' 5000

  sleep 5
done
