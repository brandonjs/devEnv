echo ""
echo "Memory:"
top -l 1 | awk '/PhysMem/ {print $2" "$3".\n"$(NF-1)" "$NF}'

echo ""
echo "Uptime:"
uptime | sed -e 's/.*up //g' -e 's/ [0-9]* users.*//g' -e 's/,//g' | tr -s ' '| sed -e 's/ mins,/ minutes/g' -e 's/day, 0:[0-9][0-9]/day /g' -e 's/days, 0:[0-9][0-9]/days /g' -e 's/ 0:[0-9][0-9]/ under an hour/g' -e 's/, [0-9] users/ /g' -e 's/, 1 user/ /g' -e 's/ 1:[0-9][0-9]/ 1 hour/g' -e 's/:[0-9][0-9]/ hours/g' -e 's/\s+$//g'

echo ""
echo "Interfaces:"
ifconfig en0 | grep -E "(inet )" | head -n 1 | awk '{ print "Ethernet: "$2}'
ifconfig en1 | grep -E "(inet )" | head -n 1 | awk '{ print "Airport:  "$2}'

