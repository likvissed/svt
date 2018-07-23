let context = require.context("../svt", true, /\.js$/);
context.keys().forEach(function (key) {
  context(key);
});
