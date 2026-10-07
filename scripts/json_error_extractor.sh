#!/bin/bash

jq '[.[]|select(.level=="ERROR")|{timestamp ,message ,trace_id}]' "$1"
