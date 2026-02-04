#!/bin/bash
set -e

APP_DIR="/Users/jihoseo/Desktop/Plaid/NUV/NUV-agent"
PID_FILE="$APP_DIR/.nuvion-agent.pid"
LOG_FILE="/tmp/nuvion-agent.log"
PYTHON="$APP_DIR/.venv314/bin/python"

export DYLD_LIBRARY_PATH=/opt/homebrew/lib
export GI_TYPELIB_PATH=/opt/homebrew/lib/girepository-1.0
export GST_PLUGIN_PATH=/opt/homebrew/lib/gstreamer-1.0
export PYTHONUNBUFFERED=1

case "${1:-start}" in
  start)
    if [ -f "$PID_FILE" ] && kill -0 "$(cat "$PID_FILE")" 2>/dev/null; then
      echo "Already running (PID $(cat "$PID_FILE"))"
      exit 1
    fi
    cd "$APP_DIR"
    $PYTHON -m nuvion_app.cli run > "$LOG_FILE" 2>&1 &
    echo $! > "$PID_FILE"
    echo "Started (PID $!, log: $LOG_FILE)"
    ;;
  start-gui)
    if [ -f "$PID_FILE" ] && kill -0 "$(cat "$PID_FILE")" 2>/dev/null; then
      echo "Already running (PID $(cat "$PID_FILE"))"
      exit 1
    fi
    cd "$APP_DIR"
    export NUVION_LOCAL_DISPLAY=true
    $PYTHON -m nuvion_app.cli run 2>&1 | tee "$LOG_FILE"
    ;;
  stop)
    if [ ! -f "$PID_FILE" ]; then
      echo "Not running (no pid file)"
      exit 1
    fi
    PID=$(cat "$PID_FILE")
    if kill -0 "$PID" 2>/dev/null; then
      kill "$PID"
      rm -f "$PID_FILE"
      echo "Stopped (PID $PID)"
    else
      rm -f "$PID_FILE"
      echo "Process already dead, cleaned up pid file"
    fi
    ;;
  restart)
    $0 stop 2>/dev/null || true
    $0 start
    ;;
  status)
    if [ -f "$PID_FILE" ] && kill -0 "$(cat "$PID_FILE")" 2>/dev/null; then
      echo "Running (PID $(cat "$PID_FILE"))"
    else
      echo "Not running"
    fi
    ;;
  log)
    tail -f "$LOG_FILE"
    ;;
  *)
    echo "Usage: $0 {start|stop|restart|start-gui|status|log}"
    exit 1
    ;;
esac
