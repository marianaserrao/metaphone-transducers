#!/bin/zsh

mkdir -p compiled images

# ############ Convert friendly and compile to openfst ############
for i in friendly/*.txt; do
	echo "Converting friendly: $i"
   python3 compact2fst.py  $i  > sources/$(basename $i)
done


# ############ convert words to openfst ############
for f in tests/*.str; do
	echo "Converting words: $f"
    counter=1
    for w in `cat $f`; do
	    ./word2fst.py $w > tests/$(basename $f ".str").$counter.txt;
        let counter++
    done
done

# ############ Compile source transducers ############
for i in sources/*.txt tests/*.txt; do
	echo "Compiling: $i"
    fstcompile --isymbols=syms.txt --osymbols=syms.txt $i | fstarcsort > compiled/$(basename $i ".txt").fst
done

# ############ CORE OF THE PROJECT  ############

for i in $(seq 1 8); do
    f=$(($i+1))
    if [ $i -eq 1 ]; then
        fstcompose compiled/step$i.fst compiled/step$f.fst compiled/compose1-$f.fst
    elif [ $i -eq 8 ]; then
        fstcompose compiled/compose1-$i.fst compiled/step$f.fst compiled/metaphoneLN.fst
        fstinvert compiled/metaphoneLN.fst compiled/invertMetaphoneLN.fst
    else
        fstcompose compiled/compose1-$i.fst compiled/step$f.fst compiled/compose1-$f.fst
    fi
done

# ############ generate PDFs  ############

echo "Starting to generate PDFs"
for i in compiled/*.fst; do
	echo "Creating image: images/$(basename $i '.fst').pdf"
   fstdraw --portrait --isymbols=syms.txt --osymbols=syms.txt $i | dot -Tpdf > images/$(basename $i '.fst').pdf
done

# ############ tests ############

function output {    
    fstcompose $1 compiled/$2 | fstshortestpath | fstproject --project_type=output |
    fstrmepsilon | fsttopsort | fstprint --acceptor --isymbols=./syms.txt
}

echo "\n Testing steps"

for s in $(seq 1 9); do
    if ls compiled/t-step$s*.fst > /dev/null; then
        printf "\nSTEP $s\n\n"
        for w in compiled/t-step$s*.fst; do
            output $w step$s.fst
            echo "----------------------------------------"
        done
    fi
done

echo "\n Testing algorithms"

echo "\n Metaphone \n"
for f in compiled/t-*in*.fst; do
    output $f metaphoneLN.fst
    echo "----------------------------------------"
done

echo "\n Invert Metaphone \n"
for f in compiled/t-*out*.fst; do
    output $f invertMetaphoneLN.fst
    echo "----------------------------------------"
done