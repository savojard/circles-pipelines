BEGIN {
  depth = 10000000000;
  i = 0;

}
{
  if (i == 1) {
    sample_depth = int($2);
    if (sample_depth < x && sample_depth >= m) {
      depth = sample_depth;
    }
  }
  if ($2 == "detail:") {
    i = 1;
  }
}
END {
  print depth;
}
