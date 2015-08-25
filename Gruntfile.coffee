# Zum Ausführen:
# "grunt" bzw. "grunt default" 
module.exports = (grunt) ->
  grunt.initConfig
    clean: ['bower_components', 'js', 'lib', 'styles', 'index.html']
    #
    # bower
    bower:
      install:
        options:
          layout: 'byComponent'
          targetDir: "lib"
          cleanTargetDir: true
          #cleanup: true # both cleanBowerDir & cleanTargetDir are set to the value of cleanup.
    #
    # jade
    jade:
      compile:
        options:
          pretty: true
        files:
          'index.html': 'jade/index.jade'
    #
    # coffeescript
    coffee:
      compile:
        files: 
          'js/app.js': 'coffee/app.coffee'
          'js/angular-pintura.js': 'coffee/angular-pintura.coffee' 
    # grunt sass
    sass:
      dist:
        expand: true
        cwd: 'sass'
        src: ['*.sass']
        dest: 'styles'
        ext: '.css'

    # connect-server
    connect:
      #uses_defaults: {}
      server:
        options: # Defaults: port = 8000, base = '.'
          livereload: true

    #
    # watch
    watch:
      jade:
        files: ['jade/*']
        tasks: ['jade']
      coffee:
        files: ['coffee/*']
        tasks: ['coffee'] 
      sass:
        files: ['sass/*.sass']
        tasks: ['sass']
      livereload:
        files: ['js/*', 'styles/*', 'index.html']
        options:
          livereload: true
          #atBegin: true
    #
    # Angualr dependency injection annotations
    ngAnnotate:
      ngp:
        files: 
          'js/angular-pintura.js': 'js/angular-pintura.js'
    #
    # Uglify
    uglify:
      ngp:
        files:
          'js/angular-pintura.min.js': 'js/angular-pintura.js'

  grunt.loadNpmTasks('grunt-bower-task')
  grunt.loadNpmTasks('grunt-contrib-jade')
  grunt.loadNpmTasks('grunt-contrib-coffee')
  grunt.loadNpmTasks('grunt-contrib-sass')
  grunt.loadNpmTasks('grunt-contrib-watch')
  grunt.loadNpmTasks('grunt-contrib-uglify')
  grunt.loadNpmTasks('grunt-contrib-clean')
  grunt.loadNpmTasks('grunt-ng-annotate')
  grunt.loadNpmTasks('grunt-contrib-connect')

  grunt.registerTask('build', ['clean', 'bower:install', 'jade', 'coffee', 'sass', 'ngAnnotate', 'uglify'])
  grunt.registerTask('default', ['connect', 'watch'])
