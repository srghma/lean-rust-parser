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
import Lean

inductive Ident | mk (s : String) deriving Repr

mutual
  inductive Ty
    | path (id : Ident)
    | generic (t : Ty) (args : TypeArgs)
    | reference (t : Ty)
  deriving Repr

  inductive TypeArgs
    | args (items : List TypeArgItem)
  deriving Repr

  inductive TypeArgItem
    | ty (t : Ty)
    | expr (e : Expr)
    | block (b : Block)
  deriving Repr

  inductive TraitBound
    | bounds (items : List Ty)
  deriving Repr

  inductive Param
    | mk (id : Ident) (t : Ty)
  deriving Repr

  inductive Block
    | mk (stmts : List Stmt) (tail : Option Expr)
  deriving Repr

  inductive Expr
    | literal (s : String)
    | path (id : Ident)
    | call (f : Expr) (args : List Expr)
    | block (b : Block)
  deriving Repr

  inductive Stmt
    | expr (e : Expr)
    | let_ (id : Ident) (t : Option Ty) (init : Option Expr)
    | item (i : Item)
  deriving Repr

  inductive Item
    | fn_ (name : Ident) (params : List Param) (ret : Option Ty) (body : Block)
  deriving Repr
end
EOF

# ----------------------------------------------------
# File B: Proposal (Parameterized Pattern)
# ----------------------------------------------------
cat << 'EOF' > benchmark_proposal.lean
import Lean

inductive Ident | mk (s : String) deriving Repr

-- Non-recursive parameterized types defined outside the mutual block
inductive TypeArgItem (Ty Expr Block : Type)
  | ty (t : Ty)
  | expr (e : Expr)
  | block (b : Block)
  deriving Repr

inductive TypeArgs (Ty Expr Block : Type)
  | args (items : List (TypeArgItem Ty Expr Block))
  deriving Repr

inductive TraitBound (Ty : Type)
  | bounds (items : List Ty)
  deriving Repr

inductive Param (Ty : Type)
  | mk (id : Ident) (t : Ty)
  deriving Repr

inductive Block (Stmt Expr : Type)
  | mk (stmts : List Stmt) (tail : Option Expr)
  deriving Repr

-- Core mutual block reduced to only 4 tightly cyclic types
mutual
  inductive Ty
    | path (id : Ident)
    | generic (t : Ty) (args : TypeArgs Ty Expr (Block Stmt Expr))
    | reference (t : Ty)
  deriving Repr

  inductive Expr
    | literal (s : String)
    | path (id : Ident)
    | call (f : Expr) (args : List Expr)
    | block (b : Block Stmt Expr)
  deriving Repr

  inductive Stmt
    | expr (e : Expr)
    | let_ (id : Ident) (t : Option Ty) (init : Option Expr)
    | item (i : Item)
  deriving Repr

  inductive Item
    | fn_ (name : Ident) (params : List (Param Ty)) (ret : Option Ty) (body : Block Stmt Expr)
  deriving Repr
end
EOF

echo "Files successfully created:"
echo "  - benchmark_original.lean  (Monolithic Mutual)"
echo "  - benchmark_proposal.lean  (Parameterized Pattern)"
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

# Measure Proposal
echo "Compiling benchmark_proposal.lean..."
start_prop=$(get_time)
compile_file "benchmark_proposal.lean"
end_prop=$(get_time)
time_prop=$(calculate_diff "$start_prop" "$end_prop")
echo "Done. ($time_prop seconds)"
echo ""

# ----------------------------------------------------
# 3. Clean up and Print Results
# ----------------------------------------------------
rm -f benchmark_original.lean benchmark_proposal.lean

echo "=== 3. Benchmark Results ==="
echo "Original Monolithic Mutual:  $time_orig seconds"
echo "Proposal (Parameterized):    $time_prop seconds"

speedup=$(calculate_speedup "$time_orig" "$time_prop")
echo ""
echo "Speedup Ratio: ${speedup}x faster compilation time!"
