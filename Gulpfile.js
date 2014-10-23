var gulp = require('gulp')
var coffee = require('gulp-coffee')
var concat = require('gulp-concat')
var prepend = require('gulp-insert').prepend

gulp.task('build', function() {
  // Order here is important.
  files = [
    './app/assets/javascripts/assert.coffee',
    './app/assets/javascripts/action.coffee',
    './app/assets/javascripts/dispatcher.coffee',
    './app/assets/javascripts/side_effect.coffee',
    './app/assets/javascripts/store.coffee',
    './app/assets/javascripts/hippodrome.coffee'
  ]

  gulp.src(files)
      .pipe(concat('hippodrome.js'))
      .pipe(coffee())
      .pipe(prepend('//= require lodash\n\n')) // For the rails asset pipeline.
      .pipe(gulp.dest('./js'))
});
