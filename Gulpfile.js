var gulp = require('gulp')
var coffee = require('gulp-coffee')
var concat = require('gulp-concat')
var prepend = require('gulp-insert').prepend
var shell = require('gulp-shell')
var uglify = require('gulp-uglify')
var rename = require('gulp-rename')

gulp.task('build', function() {
  // Order here is important.
  files = [
    './src/setup.coffee',
    './src/assert.coffee',
    './src/id_factory.coffee',
    './src/action.coffee',
    './src/dispatcher.coffee',
    './src/deferred_task.coffee',
    './src/store.coffee',
    './src/export.coffee'
  ]

  gulp.src(files)
      .pipe(concat('hippodrome.js'))
      .pipe(coffee())
      .pipe(gulp.dest('./dist'))
      .pipe(uglify())
      .pipe(rename('hippodrome.min.js'))
      .pipe(gulp.dest('./dist'))
});

gulp.task('test', ['build'], shell.task([
  'npm run test'
]))

gulp.task('watch', ['test'], function() {
  gulp.watch('src/**/*.coffee', ['test']);
})
