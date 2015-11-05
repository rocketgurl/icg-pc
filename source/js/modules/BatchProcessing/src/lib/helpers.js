export function clamp(n, min, max) {
  if (n < min) return min;
  if (n > max) return max;
  return n;
}

export function randBetween(min, max) {
  return Math.floor(Math.random() * max) + min;
}