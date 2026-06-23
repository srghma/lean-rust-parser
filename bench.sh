#!/usr/bin/env bash

# Ensure we are inside a context where 'lean' is accessible
if ! command -v lean &> /dev/null; then
    echo "Error: 'lean' command not found. Please make sure Lean 4 is installed and in your PATH."
    exit 1
fi

# Define a robust cross-platform timer (handles macOS and Linux easily)
get_time() {
    python3 -c 'import time; print(time.time())' 2>/dev/null || date +%s
}

calculate_diff() {
    python3 -c "print(round($2 - $1, 4))" 2>/dev/null || awk "BEGIN {print $2 - $1}"
}

calculate_speedup() {
    python3 -c "print(round($1 / $2, 2))" 2>/dev/null || awk "BEGIN {print $1 / $2}"
}

echo "=== 1. Generating AST Implementations ==="

# ----------------------------------------------------
# File A: Original Monolithic Mutual Implementation
# ----------------------------------------------------
cat << 'EOF' > benchmark_original.lean
mutual
  inductive A where
    | a1 (as : List A) (bs : List B) (cs : List C) : A
    | a2 (as : Array A) (bs : Array B) (cs : Array C) : A

  inductive B where
    | b1 (as : List A) (bs : List B) (cs : List C) : B
    | b2 (as : Array A) (bs : Array B) (cs : Array C) : B

  inductive C where
    | c1 (as : List A) (bs : List B) (cs : List C) : C
    | c2 (as : Array A) (bs : Array B) (cs : Array C) : C
end
EOF

# ----------------------------------------------------
# File B: Proposal (Parameterized Pattern)
# ----------------------------------------------------
cat << 'EOF' > benchmark_proposal.lean
-- 1. Define a simple index tag
inductive Tag
  | a | b | c

-- 2. Define a single, non-mutual inductive type
inductive ABC : Tag → Type where
  -- A constructors
  | a1 (as : List (ABC .a)) (bs : List (ABC .b)) (cs : List (ABC .c)) : ABC .a
  | a2 (as : Array (ABC .a)) (bs : Array (ABC .b)) (cs : Array (ABC .c)) : ABC .a

  -- B constructors
  | b1 (as : List (ABC .a)) (bs : List (ABC .b)) (cs : List (ABC .c)) : ABC .b
  | b2 (as : Array (ABC .a)) (bs : Array (ABC .b)) (cs : Array (ABC .c)) : ABC .b

  -- C constructors
  | c1 (as : List (ABC .a)) (bs : List (ABC .b)) (cs : List (ABC .c)) : ABC .c
  | c2 (as : Array (ABC .a)) (bs : Array (ABC .b)) (cs : Array (ABC .c)) : ABC .c

-- 3. Restore the original type aliases
abbrev A := ABC .a
abbrev B := ABC .b
abbrev C := ABC .c

-- 4. Restore the original constructor namespaces
namespace A
  abbrev a1 := ABC.a1
  abbrev a2 := ABC.a2
end A

namespace B
  abbrev b1 := ABC.b1
  abbrev b2 := ABC.b2
end B

namespace C
  abbrev c1 := ABC.c1
  abbrev c2 := ABC.c2
end C
EOF

# ----------------------------------------------------
# File C: Proposal (No Custom Inductive Types Nested in Mutual)
# ----------------------------------------------------
cat << 'EOF' > benchmark_proposal_no_inductive.lean
mutual
inductive A where
  | a1 (as : ListA) (bs : ListB) (cs : ListC) : A
  | a2 (as : ArrayA) (bs : ArrayB) (cs : ArrayC) : A

inductive B where
  | b1 (as : ListA) (bs : ListB) (cs : ListC) : B
  | b2 (as : ArrayA) (bs : ArrayB) (cs : ArrayC) : B

inductive C where
  | c1 (as : ListA) (bs : ListB) (cs : ListC) : C
  | c2 (as : ArrayA) (bs : ArrayB) (cs : ArrayC) : C

-- Manually defined specialized containers
inductive ListA where | nil | cons (head : A) (tail : ListA)
inductive ListB where | nil | cons (head : B) (tail : ListB)
inductive ListC where | nil | cons (head : C) (tail : ListC)

-- Array representation using the manual list representation
inductive ArrayA where | mk (data : ListA)
inductive ArrayB where | mk (data : ListB)
inductive ArrayC where | mk (data : ListC)
end
EOF

echo "Files successfully created:"
echo "  - benchmark_original.lean              (Monolithic Mutual)"
echo "  - benchmark_proposal.lean              (Parameterized Pattern)"
echo "  - benchmark_proposal_no_inductive.lean (No Custom Inductive Nesting)"
echo ""

# Helper compilation function
compile_file() {
    local file=$1
    if command -v lake &> /dev/null; then
        lake env lean "$file"
    else
        lean "$file"
    fi
}

echo "=== 2. Running Compilation Benchmark ==="

# Measure Original
echo "Compiling benchmark_original.lean..."
start_orig=$(get_time)
compile_file "benchmark_original.lean"
end_orig=$(get_time)
time_orig=$(calculate_diff "$start_orig" "$end_orig")
echo "Done. ($time_orig seconds)"
echo ""

# Measure Proposal (Parameterized)
echo "Compiling benchmark_proposal.lean..."
start_prop=$(get_time)
compile_file "benchmark_proposal.lean"
end_prop=$(get_time)
time_prop=$(calculate_diff "$start_prop" "$end_prop")
echo "Done. ($time_prop seconds)"
echo ""

# Measure Proposal (No Custom Inductive Nesting)
echo "Compiling benchmark_proposal_no_inductive.lean..."
start_flat=$(get_time)
compile_file "benchmark_proposal_no_inductive.lean"
end_flat=$(get_time)
time_flat=$(calculate_diff "$start_flat" "$end_flat")
echo "Done. ($time_flat seconds)"
echo ""

# ----------------------------------------------------
# 3. Clean up and Print Results
# ----------------------------------------------------
rm -f benchmark_original.lean benchmark_proposal.lean benchmark_proposal_no_inductive.lean

echo "=== 3. Benchmark Results ==="
echo "1. Original Monolithic Mutual:  $time_orig seconds"
echo "2. Proposal (Parameterized):    $time_prop seconds"
echo "3. Proposal (No Nested Ind.):   $time_flat seconds"

speedup_prop=$(calculate_speedup "$time_orig" "$time_prop")
speedup_flat=$(calculate_speedup "$time_orig" "$time_flat")
echo ""
echo "Speedup Ratio (Proposal 2): ${speedup_prop}x faster!"
echo "Speedup Ratio (Proposal 3): ${speedup_flat}x faster!"
