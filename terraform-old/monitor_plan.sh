#!/bin/bash

# Start monitoring in background
(
  while true; do
    # Get terraform process stats
    ps aux | grep "[t]erraform plan" | awk '{print $2,$3,$4}' >> /tmp/tf_monitor.log
    sleep 1
  done
) &
MONITOR_PID=$!

# Run terraform plan and time it
echo "Starting terraform plan at $(date)"
START=$(date +%s)

/usr/bin/time -l terraform plan -out=plan.out 2>&1 | tee /tmp/tf_plan_output.log

END=$(date +%s)
DURATION=$((END - START))

# Stop monitoring
kill $MONITOR_PID 2>/dev/null

echo "Plan completed in $DURATION seconds"
echo "Memory stats from time command are in the output above"
echo "Process monitoring saved to /tmp/tf_monitor.log"

# Check plan file size
if [ -f plan.out ]; then
  echo "Plan file created:"
  ls -lh plan.out
fi
