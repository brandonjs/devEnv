echo ""
echo "Top 10 CPU Processes:"
ps -opid,ppid,user,%cpu,comm -cxr | head -10

echo ""
echo ""
echo "Top 10 Mem Processes:"
ps -opid,ppid,user,vsz,%mem,comm -cxm | head -10
