#!/bin/bash

# ASCII 7x5 pixel font (7 rows, 5 cols per char; row 5-6 always blank = natural gap)
declare -A CHAR_MAP

CHAR_MAP[E]="##### #.... ##### #.... ##### ..... ....."
CHAR_MAP[X]="#...# #...# .#.#. ..#.. .#.#. #...# #...#"
CHAR_MAP[T]="##### ..#.. ..#.. ..#.. ..#.. ..... ....."
CHAR_MAP[R]="####. #...# ####. #.#.. #..#. #...# #...#"
CHAR_MAP[A]=".###. #...# #...# ##### #...# #...# #...#"
CHAR_MAP[P]="####. #...# ####. #.... #.... ..... ....."
CHAR_MAP[O]=".###. #...# #...# #...# #...# #...# .###."
CHAR_MAP[L]="#.... #.... #.... #.... ##### ..... ....."

WORD="EXTRAPOLO"
COMMITS_PER_PIXEL=10
OUTPUT_FILE="extrapolo.txt"

# Each character uses 5 pixel columns + 1 blank gap = 6 cols/char.
# EXTRAPOLO (9 chars) needs pixel columns 0–52 (53 total).
# GitHub's contribution graph shows 52 complete past weeks + the current partial week,
# giving 53 visible column slots — an exact fit.
#
# START_DATE: the Sunday that begins week 0 (52 full weeks before the current week).
# This is always a Sunday and always falls within the 365-day visible window.

if [ ! -d .git ]; then
  echo "You must run this inside a Git repository."
  exit 1
fi

TODAY_DOW=$(date +%w)   # 0 = Sunday … 6 = Saturday  (Linux / GNU date)
START_DATE=$(date -d "-$((52 * 7 + TODAY_DOW)) days" +%Y-%m-%d)

echo "START_DATE: $START_DATE"
echo "Generating commits for: $WORD"

> "$OUTPUT_FILE"

for ((c = 0; c < ${#WORD}; c++)); do
  CHAR=${WORD:$c:1}
  IFS=' ' read -r -a rows <<< "${CHAR_MAP[$CHAR]}"

  for ((row = 0; row < 7; row++)); do
    line="${rows[$row]}"
    for ((col = 0; col < 5; col++)); do
      pixel="${line:$col:1}"
      if [[ "$pixel" == "#" ]]; then
        week_offset=$(( c * 6 + col ))
        day_offset=$(( week_offset * 7 + row ))
        commit_date=$(date -d "${START_DATE} + ${day_offset} days" "+%Y-%m-%dT12:00:00")

        for ((k = 0; k < COMMITS_PER_PIXEL; k++)); do
          printf "%s [%d]\n" "$commit_date" "$k" >> "$OUTPUT_FILE"
          git add "$OUTPUT_FILE"
          GIT_AUTHOR_DATE="$commit_date" GIT_COMMITTER_DATE="$commit_date" \
            git commit -q -m "pixel $c:$row,$col"
        done
      fi
    done
  done
done

echo "Done."
