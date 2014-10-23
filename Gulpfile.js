var gulp = require('gulp')
var coffee = require('gulp-coffee')
var concat = require('gulp-concat')
var prepend = require('gulp-insert').prepend
var shell = require('gulp-shell')

gulp.task('compile-javascript', function() {
  // Order here is important.
  files = [
    './src/setup.coffee',
    './src/assert.coffee',
    './src/action.coffee',
    './src/dispatcher.coffee',
    './src/deferred_task.coffee',
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

gulp.task('build-gem', ['compile-javascript'], shell.task([
  'rake build'
]));

gulp.task('build', ['compile-javascript', 'build-gem']);

gulp.task('release-gem', ['build'], shell.task([
  'rake release'
]));

gulp.task('publish-node', ['build'], shell.task([
  'npm publish'
]));

gulp.task('publish', ['release-gem', 'publish-node']);
