// knuth shuffle
function shuffle(_arr){
  var arr = _arr.slice(0);
  var currentIndex = arr.length;
  var tempValue, randIndex;
  while (currentIndex !== 0) {
    randIndex = Math.floor(Math.random() * currentIndex);
    currentIndex -= 1;
    tempValue = arr[currentIndex];
    arr[currentIndex] = arr[randIndex];
    arr[randIndex] = tempValue;
  }
  return arr;
};
