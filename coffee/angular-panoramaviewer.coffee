###*
# HTML-Wrapper für die PanoramaViewer-Module 
# Liefert einen Scope für zugehörige Module
###
panoramaViewerDirective = ->
  # controller gives the curent scope to child directives
  controllerFunc = ($scope) -> 
    ###*
    # @private
    # @property $scope.viewer
    # @type Kinetc.MBCPanoramaViewer
    ###  
    @viewer = undefined

    ###*
    # Kinetic
    # @property $scope.viewer
    # @type Kinetc.MBCPanoramaViewer
    # @return {Kinetic.MBCPanoramaViewer}
    ###  
    return (container) ->
      # create new instance of panorama viewer
      @viewer ?= new Kinetic.MBCPanoramaViewer(container)
      # return panoramaviewer instance
      return @viewer

  # directive options
  directive =
    restrict: 'E'
    transclude: true
    templateUrl: 'panoramaviewer.html'
    scope: {}
    #link: linkFunc
    controller: ['$scope', controllerFunc]
  # return directive
  return directive

###*
# Erstellt Kinetic-Stage, -Layer und -Image
# Lädt das Panoramabild (initial und bei Änderung der Bildadresse) 
###
panoramaImageDirective = ($window) -> 
  # link function
  linkFunc = (scope, el, attrs, viewer) ->
    # on change image
    _changeImage = ->
      viewer().setImageUrl(scope.src)
    # on resize
    _resize = ->
      viewer().size
        width: el[0].clientWidth
        height: el[0].clientHeight
    # init panorama viewer
    viewer(el[0])
    # event binding
    scope.$watch('src', _changeImage)
    # on resize
    angular.element($window).bind('resize', _resize)
  # directive options
  directive =
    restrict: 'E'
    require: '^mbcPanoramaViewer'
    scope: 
      src: '='
    link: 
      pre: linkFunc
  # returns directive definition
  return directive

angular.module('mbcPanoramaViewer', [])
.directive('mbcPanoramaViewer',   [panoramaViewerDirective])
.directive('mbcPanoramaImage',    ['$window', panoramaImageDirective])