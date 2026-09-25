String diaryMoodLabel(double value) {
  if (value >= .8) return '明亮';
  if (value >= .6) return '平静';
  if (value >= .4) return '平常';
  if (value >= .2) return '低落';
  return '阴天';
}
