var gulp = require('gulp')
var coffee = require('gulp-coffee')
var concat = require('gulp-concat')
var prepend = require('gulp-insert').prepend

gulp.task('build', function() {
  // Order here is important.
  files = [
    './src/setup.coffee',
    './src/assert.coffee',
    './src/action.coffee',
    './src/dispatcher.coffee',
    './src/side_effect.coffee',
    './src/store.coffee',
    './src/export.coffee'
  ]

  gulp.src(files)
      .pipe(concat('hippodrome.js'))
      .pipe(coffee())
      .pipe(prepend('//= require lodash\n\n')) // For the rails asset pipeline.
      .pipe(gulp.dest('./js'))
      .pipe(gulp.dest('./app/assets/javascripts'))
});
