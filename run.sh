#!/bin/zsh

mkdir -p compiled images

# ############ Convert friendly and compile to openfst ############
for i in friendly/*.txt; do
	echo "Converting friendly: $i"
   python3 compact2fst.py  $i  > sources/$(basename $i ".formatoAmigo")
done


# ############ convert words to openfst (EDITED) ############
for f in test-strings/*.str; do
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

fstconcat compiled/step2.fst compiled/step3.fst compiled/concat.fst 

echo "Testing Concat"

./word2fst.py `cat test-strings/t-concat.str` > tests/t-concat.txt;

function concat_output {
    fstcompose $1 compiled/concat.fst | fstshortestpath | fstproject --project_type=output |
    fstrmepsilon | fsttopsort | fstprint --acceptor --isymbols=./syms.txt
}

for w in compiled/t-concat*.fst; do
    concat_output $w
    echo "----------------------------------------"
done

# ############ generate PDFs  ############
echo "Starting to generate PDFs"
for i in compiled/*.fst; do
	echo "Creating image: images/$(basename $i '.fst').pdf"
   fstdraw --portrait --isymbols=syms.txt --osymbols=syms.txt $i | dot -Tpdf > images/$(basename $i '.fst').pdf
done



# ############ tests (EDITED) ############

# echo "Testing ABCDE"

# for w in compiled/t-*.fst; do
#     fstcompose $w compiled/step3.txt.fst | fstshortestpath | fstproject --project_type=output |
#     fstrmepsilon | fsttopsort | fstprint --acceptor --isymbols=./syms.txt
# done

# echo "Testing"

# function output {
#     fstcompose $1 compiled/step$2.fst | fstshortestpath | fstproject --project_type=output |
#     fstrmepsilon | fsttopsort | fstprint --acceptor --isymbols=./syms.txt
# }

# for s in $(seq 1 9); do
#     if ls compiled/t-step$s*.fst > /dev/null; then
#         printf "\nSTEP $s\n\n"
#         for w in compiled/t-step$s*.fst; do
#             output $w $s
#             echo "----------------------------------------"
#         done
#     fi
# done

