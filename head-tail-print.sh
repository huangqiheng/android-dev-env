

for filename in $(ls -1t "$1"); do
	headStr=$(head -c 8 "$filename" | xxd -p)
	tailStr=$(tail -c 8 "$filename" | xxd -p)
	echo "$filename: \t $headStr -- $tailStr"
done


